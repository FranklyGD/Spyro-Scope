using OpenGL;
using SDL2;
using System;
using System.Collections;
using System.Diagnostics;

namespace SpyroScope {
	class WindowApp {
		SDL.Window* window;
		Renderer renderer;
		Action loop ~ delete _;
		Stopwatch stopwatch = new .() ~ delete _;

		public readonly uint32 id;
		public uint width, height;

		public bool closed { get; private set; }
		public bool drawObjects;

		static int currentObjIndex = -1;
		static int hoveredObjIndex = -1;
		static List<Moby> objectList = new .(128) ~ delete _;

		static bool cameraHijacked;
		static float cameraSpeed = 64;
		static Vector cameraMotion;
		static int cameraRollRate;

		Vector mousePosition;

		// Viewer Camera
		static bool dislodgeCamera;
		static Vector viewPosition;
		static Vector viewEulerRotation;

		static Matrix4 viewerProjection;
		static Matrix4 viewerMatrix;
		static Matrix4 uiProjection;

		// Game Camera
		static Matrix4 gameProjection = .Perspective(55f / 180 * Math.PI_f, 4f/3f, 300, 175000);

		Terrain collisionTerrain = new .() ~ delete _;

		Dictionary<uint16, MobyModelSet> modelSets = new .();
		BitmapFont font ~ delete _;
		List<(String message, DateTime time)> messageFeed = new .();
		//List<GUIElement> guiElements = new .() ~ DeleteContainerAndItems!(_);

		public this() {
			width = 750;
			height = 600;

			window = SDL.CreateWindow("Scope", .Undefined, .Undefined, (.)width, (.)height,
				.Shown | .Resizable | .InputFocus | .Utility | .OpenGL);
			renderer = new .(window);
			font = new .("images/font.png", 12, 14);

			viewerProjection = .Perspective(55f / 180 * Math.PI_f, (float)width / height, 100, 500000);
			uiProjection = .Orthogonal(width, height, -1, 1);

			id = SDL.GetWindowID(window);

			Emulator.OnSceneChanged = new => OnSceneChanged;

			// Attempt to find and bind as the window is being opened
			Emulator.FindEmulator();
			if (Emulator.emulator != .None) {
				Emulator.FindGame();
				if (Emulator.rom != .None) {
					loop = new => RunViewer;
					return;
				}
			}

			// If it failed, show initial setup screen
			loop = new => RunSetup;
			stopwatch.Start();
		}

		public ~this() {
			Emulator.UnbindToEmulator();

			for (let modelSet in modelSets.Values) {
				delete modelSet;
			}
			delete modelSets;
			delete Emulator.OnSceneChanged;
			for (let feedItem in messageFeed) {
				if (feedItem.message.IsDynAlloc) {
					delete feedItem.message;
				}
			}
			delete messageFeed;

			if (renderer != null)
				delete renderer;
			if (window != null)
				SDL.DestroyWindow(window);

			window = null;
		}

		public void Run() {
			renderer.Clear();

			loop();

			int32 majorVersion = ?;
			int32 minorVersion = ?;
			GL.glGetIntegerv(GL.GL_MAJOR_VERSION, (.)&majorVersion);
			GL.glGetIntegerv(GL.GL_MINOR_VERSION, (.)&minorVersion);
			
			let halfWidth = (float)width / 2;
			let halfHeight = (float)height / 2;

			font.Print(scope String() .. AppendF("OpenGL {}.{}", majorVersion, minorVersion), .(halfWidth - font.characterWidth * 10, halfHeight - font.characterHeight, 0), .(255,255,255,8), renderer);
			
			renderer.Draw();
			renderer.Sync();
			renderer.Display();
		}

		public void RunSetup() {
			if (Emulator.rom != .None) {
				if (stopwatch.ElapsedMilliseconds > 3000) {
					delete loop;
					loop = new => RunViewer;
					stopwatch.Stop();
				}
			} else if (stopwatch.ElapsedMilliseconds > 1000) {
				if (Emulator.emulator == .None) {
					Emulator.FindEmulator();
				} else {
					Emulator.CheckEmulatorStatus();
					if (Emulator.emulator != .None) {
						Emulator.FindGame();
					}
				}
				
				stopwatch.Restart();
			}

			renderer.SetView(.Zero, .Identity);
			renderer.SetProjection(uiProjection);
			GL.glDisable(GL.GL_DEPTH_TEST);

			DrawSetupGUI();
		}

		public void DrawSetupGUI() {
			String message = .Empty;
			if (Emulator.emulator == .None) {
				message = "WAITING FOR EMULATOR";
			} else {
				if (Emulator.rom == .None) {
					message = "WAITING FOR GAME";
				} else {
					message = Emulator.gameNames[(int)Emulator.rom];
				}
				
				let baseline = font.characterHeight;
				let emulator = Emulator.emulatorNames[(int)Emulator.emulator];
				let halfWidth = font.characterWidth * emulator.Length / 2;
				font.Print(emulator, .(-halfWidth, baseline, 0), .(255,255,255), renderer);
			}

			let baseline = -font.characterHeight / 2;
			let halfWidth = font.characterWidth * message.Length / 2;
			font.Print(message, .(-halfWidth, baseline, 0), .(255,255,255), renderer);

			if (Emulator.emulator == .None || Emulator.rom == .None) {
				let t = (float)stopwatch.ElapsedMilliseconds / 1000 * 3.14f;
				DrawUtilities.Rect(baseline - 2, baseline, -halfWidth * Math.Sin(t), halfWidth * Math.Sin(t),
					0,0,0,0, renderer.textureDefaultWhite, .(255,255,255), renderer);
			} else {
				let t = 1f - (float)stopwatch.ElapsedMilliseconds / 3000;
				DrawUtilities.Rect(baseline - 2, baseline, -halfWidth * t, halfWidth * t,
					0,0,0,0, renderer.textureDefaultWhite, .(255,255,255), renderer);
			}
		}

		public void RunViewer() {
			GL.glBindTexture(GL.GL_TEXTURE_2D, renderer.textureDefaultWhite);

			Emulator.CheckEmulatorStatus();

			if (Emulator.emulator == .None || Emulator.rom == .None) {
				delete loop;
				loop = new => RunSetup;
				stopwatch.Restart();
				return;
			}

			Emulator.FetchRAMBaseAddress();
			Emulator.FetchImportantObjects();

			UpdateView();
			
			GL.glEnable(GL.GL_DEPTH_TEST);

			collisionTerrain.Update();
			collisionTerrain.Draw(renderer);
			if (dislodgeCamera) {
				DrawGameCameraFrustrum();
			}

			Emulator.Address objectArrayPointer = ?;
			Emulator.ReadFromRAM(Emulator.objectArrayPointers[(int)Emulator.rom], &objectArrayPointer, 4);
			Emulator.Address objPointer = objectArrayPointer;

			objectList.Clear();
			for (int i < 512 /* Load object limit */) {
				Moby object = ?;
				Emulator.ReadFromRAM(objPointer, &object, sizeof(Moby));
				if (object.dataPointer == 0) {
					break;
				}

				if (object.HasModel) {
					Emulator.Address modelSetAddress = ?;
					Emulator.ReadFromRAM(Emulator.modelPointers[(int)Emulator.rom] + 4 * object.objectTypeID, &modelSetAddress, 4);

					if (modelSetAddress != 0 && (int32)modelSetAddress > 0) {
						if (!modelSets.ContainsKey(object.objectTypeID)) {
							modelSets.Add(object.objectTypeID, new .(modelSetAddress));
						}
	
						let basis = Matrix.Euler(
							-(float)object.eulerRotation.x / 0x80 * Math.PI_f,
							(float)object.eulerRotation.y / 0x80 * Math.PI_f,
							-(float)object.eulerRotation.z / 0x80 * Math.PI_f
						);
	
						renderer.SetModel(object.position, basis * 2);
						renderer.SetTint(.(255,255,255));
						modelSets[object.objectTypeID].models[object.modelID].QueueInstance(renderer);
					}
				}

				objectList.Add(object);
				if (!drawObjects) {
					object.Draw(renderer);
				}

				objPointer += 0x58;
			}

			DrawSpyroInformation();
			
			// Draw all queued instances
			PrimitiveShape.DrawInstances();

			for (let modelSet in modelSets.Values) {
				for (let model in modelSet.models) {
					model.DrawInstances();
				}
			}

			renderer.SetModel(.Zero, .Identity);
			renderer.SetTint(.(255,255,255));
			renderer.Draw();

			viewerMatrix = renderer.projection * renderer.view;

			// Setup render view for drawing GUI and overlays
			renderer.SetView(.Zero, .Identity);
			renderer.SetProjection(uiProjection);
			GL.glDisable(GL.GL_DEPTH_TEST);

			DrawViewerGUI();
		}

		public void Close() {
			closed = true;
		}

		public void OnEvent(SDL.Event event) {
			switch (event.type) {
				case .MouseButtonDown : {
					if (event.button.button == 3) {
						SDL.SetRelativeMouseMode(true);
						cameraHijacked = true;
						if (!dislodgeCamera && !Emulator.CameraMode) {
							Emulator.KillCameraUpdate();
							PushMessageToFeed("FREE CAMERA");
						}
					}
					if (event.button.button == 1) {
						currentObjIndex = hoveredObjIndex;
					}
				}
				case .MouseMotion : {
					if (cameraHijacked) {
						if (dislodgeCamera) {
							viewEulerRotation.z -= (.)event.motion.xrel * 0.001f;
							viewEulerRotation.x += (.)event.motion.yrel * 0.001f;
							viewEulerRotation.x = Math.Clamp(viewEulerRotation.x, -0.5f, 0.5f);
						} else {
							int16[3] cameraEulerRotation = ?;	
							Emulator.ReadFromRAM(Emulator.cameraEulerRotationAddress[(int)Emulator.rom], &cameraEulerRotation, 6);

							cameraEulerRotation[2] -= (.)event.motion.xrel * 2;
							cameraEulerRotation[1] += (.)event.motion.yrel * 2;
							cameraEulerRotation[1] = Math.Clamp(cameraEulerRotation[1], -0x400, 0x400);

							// Force camera view basis in game
							Emulator.cameraBasisInv = MatrixInt.Euler(0, (float)cameraEulerRotation[1] / 0x800 * Math.PI_f, (float)cameraEulerRotation[2] / 0x800 * Math.PI_f);

							Emulator.WriteToRAM(Emulator.cameraMatrixAddress[(int)Emulator.rom], &Emulator.cameraBasisInv, sizeof(MatrixInt));
							Emulator.WriteToRAM(Emulator.cameraEulerRotationAddress[(int)Emulator.rom], &cameraEulerRotation, 6);
						}
					} else {
						var mousePosX = event.motion.x - (int)width / 2;
						var mousePosY = (int)height / 2 - event.motion.y;

						mousePosition = .(mousePosX, mousePosY, 0);

						hoveredObjIndex = GetObjectIndexUnderMouse();
					}
				}
				case .MouseButtonUp : {
					if (event.button.button == 3) {	
						SDL.SetRelativeMouseMode(false);
						cameraHijacked = false;
						cameraMotion = .(0,0,0);
					}
				}
				case .MouseWheel : {
					cameraSpeed += (float)event.wheel.y;
					if (cameraSpeed < 8) {
						cameraSpeed = 8;
					}
				}
				case .KeyDown : {
					if (event.key.isRepeat == 0) {
						switch (event.key.keysym.scancode) {
							case .P : {
								if (Emulator.PausedMode) {
									Emulator.RestoreUpdate();
									PushMessageToFeed("RESUMED GAME UPDATE");
								} else {
									Emulator.KillUpdate();
									PushMessageToFeed("PAUSED GAME UPDATE");
								}
							}
							case .LCtrl : {
								cameraSpeed *= 8;
								cameraMotion *= 8;
							}
							case .M : {
								collisionTerrain.wireframe = !collisionTerrain.wireframe;
								PushMessageToFeed("TOGGLED TERRAIN WIREFRAME");
							}
							case .O : {
								drawObjects = !drawObjects;
								PushMessageToFeed("TOGGLED OBJECT ORIGINS");
							}
							case .L : {
								collisionTerrain.CycleOverlay();
								String overlayType;
								switch (collisionTerrain.overlay) {
									case .None:
										overlayType = "NONE";
									case .Flags:
										overlayType = "FLAGS";
									case .Deform:
										overlayType = "DEFORM";
								}
								PushMessageToFeed(new String() .. AppendF("TERRAIN OVERLAY [{}]", overlayType));
							}
							case .K : {
								uint health = 0;
								Emulator.WriteToRAM(Emulator.healthAddress[(int)Emulator.rom], &health, 4);
							}
							case .T : {
								if (Emulator.CameraMode) {
									Emulator.spyroPosition = viewPosition.ToVectorInt();
									Emulator.WriteToRAM(Emulator.spyroPositionPointers[(int)Emulator.rom], &Emulator.spyroPosition, sizeof(VectorInt));
									PushMessageToFeed("TELEPORTED SPYRO TO GAME CAMERA VIEW");
								}
							}
							case .C : {
								if (Emulator.CameraMode) {
									Emulator.RestoreCameraUpdate();
									PushMessageToFeed("GAME CAMERA");
								} else {
									Emulator.KillCameraUpdate();
									PushMessageToFeed("FREE CAMERA");
								}
							}
							case .V : {
								dislodgeCamera = !dislodgeCamera;
								if (dislodgeCamera) {
									PushMessageToFeed("FREE VIEW");
								} else {
									PushMessageToFeed("GAME VIEW");
								}
							}
							default : {}
						}

						if (cameraHijacked) {
							switch (event.key.keysym.scancode) {
								case .W :
									cameraMotion.z -= cameraSpeed;
								case .S :
									cameraMotion.z += cameraSpeed;
								case .A :
									cameraMotion.x -= cameraSpeed;
								case .D :
									cameraMotion.x += cameraSpeed;
								case .Space :
									cameraMotion.y += cameraSpeed;
								case .LShift :
									cameraMotion.y -= cameraSpeed;
								default :
							}
						}
					}
				}
				case .KeyUp : {
					if (event.key.keysym.scancode == .LCtrl) {
						cameraSpeed /= 8;
						cameraMotion /= 8;
					}

					if (cameraHijacked) {
						switch (event.key.keysym.scancode) {
							case .W :
								cameraMotion.z = 0;
							case .S :
								cameraMotion.z = 0;
							case .A :
								cameraMotion.x = 0;
							case .D :
								cameraMotion.x = 0;
							case .Space :
								cameraMotion.y = 0;
							case .LShift :
								cameraMotion.y = 0;
							default :
						}
					}
				}
				case .JoyDeviceAdded : {
					Console.WriteLine("Controller Connected");
				}
				case .JoyButtonDown : {
					Console.WriteLine("jButton {}", event.jbutton.button);
				}
				case .ControllerDeviceadded : {
					Console.WriteLine("Controller Connected");
				}
				case .ControllerButtondown : {
					Console.WriteLine("cButton {}", event.jbutton.button);
				}
				case .WindowEvent : {
					switch (event.window.windowEvent) {
						case .Close : {
							closed = true;
						}
						case .Resized : {
							width = (.)event.window.data1;
							height = (.)event.window.data2;
							GL.glViewport(0, 0, (.)width, (.)height);

							viewerProjection = .Perspective(55f / 180 * Math.PI_f, (float)width / height, 100, 500000);
							uiProjection = .Orthogonal(width, height, 0, 1);
						}
						default : {}
					}
				}
				default : {}
			}
		}

		void PushMessageToFeed(String message) {
			messageFeed.Add((message, .Now + TimeSpan(0, 0, 2)));
		}

		void DrawMessageFeed(Vector origin) {
			let now = DateTime.Now;
			for (let feedItem in messageFeed) {
				if (now > feedItem.time && feedItem.message.IsDynAlloc) {
					delete feedItem.message;
				}
			}
			messageFeed.RemoveAll(scope (x) => {
				return now > x.time;
			});
			for (let i < messageFeed.Count) {
				let feedItem = messageFeed[i];
				let message = feedItem.message;
				let age = feedItem.time - now;
				let fade = Math.Min(age.TotalSeconds, 1);
				let offsetOrigin = origin - .(0,(messageFeed.Count - i) * font.characterHeight,0);
				DrawUtilities.Rect(offsetOrigin.y, offsetOrigin.y + font.characterHeight, offsetOrigin.x, offsetOrigin.x + font.characterWidth * message.Length,
					0,0,0,0, renderer.textureDefaultWhite, .(0,0,0,(.)(192 * fade)), renderer);
				font.Print(message, offsetOrigin, .(255,255,255,(.)(255 * fade)), renderer);
			}
		}

		void OnSceneChanged() {
			currentObjIndex = hoveredObjIndex = -1;

			collisionTerrain.Reload();
		}

		void UpdateView() {
			if (!dislodgeCamera) {
				viewPosition = Emulator.cameraPosition;
				viewEulerRotation.x = (float)Emulator.cameraEulerRotation[1] / 0x800;
				viewEulerRotation.y = (float)Emulator.cameraEulerRotation[0] / 0x800;
				viewEulerRotation.z = (float)Emulator.cameraEulerRotation[2] / 0x800;
			}

			// Corrected view matrix for the scope
			let cameraBasis = Matrix.Euler(
				(viewEulerRotation.x - 0.5f) * Math.PI_f,
				viewEulerRotation.y  * Math.PI_f,
				(0.5f - viewEulerRotation.z) * Math.PI_f
			);

			// Move camera
			if (cameraHijacked) {
				let cameraMotionDirection = cameraBasis * cameraMotion;
				
				if (dislodgeCamera) {
					viewPosition += cameraMotionDirection;
				} else {
					let cameraNewPosition = Emulator.cameraPosition.ToVector() + cameraMotionDirection;
					Emulator.cameraPosition = cameraNewPosition.ToVectorInt();
					Emulator.MoveCameraTo(&Emulator.cameraPosition);
				}
			}

			renderer.SetView(viewPosition, cameraBasis);
			renderer.SetProjection(viewerProjection);
		}

		void DrawGameCameraFrustrum() {
			let cameraBasis = Emulator.cameraBasisInv.ToMatrixCorrected().Transpose();
			let cameraBasisCorrected = Matrix(cameraBasis.y, cameraBasis.z, -cameraBasis.x);
			renderer.DrawLine(Emulator.cameraPosition, Emulator.cameraPosition + cameraBasis * Vector(500,0,0), .(255,0,0), .(255,0,0));
			renderer.DrawLine(Emulator.cameraPosition, Emulator.cameraPosition + cameraBasis * Vector(0,500,0), .(0,255,0), .(0,255,0));
			renderer.DrawLine(Emulator.cameraPosition, Emulator.cameraPosition + cameraBasis * Vector(0,0,500), .(0,0,255), .(0,0,255));

			let projectionMatrixInv = gameProjection.Inverse();
			let viewProjectionMatrixInv = cameraBasisCorrected * projectionMatrixInv;

			let farTopLeft = (Vector)(viewProjectionMatrixInv * Vector4(-1,1,1,1)) + Emulator.cameraPosition.ToVector();
			let farTopRight = (Vector)(viewProjectionMatrixInv * Vector4(1,1,1,1)) + Emulator.cameraPosition.ToVector();
			let farBottomLeft = (Vector)(viewProjectionMatrixInv * Vector4(-1,-1,1,1)) + Emulator.cameraPosition.ToVector();
			let farBottomRight = (Vector)(viewProjectionMatrixInv * Vector4(1,-1,1,1)) + Emulator.cameraPosition.ToVector();

			let nearTopLeft = (Vector)(viewProjectionMatrixInv * Vector4(-1,1,-1,1)) + Emulator.cameraPosition.ToVector();
			let nearTopRight = (Vector)(viewProjectionMatrixInv * Vector4(1,1,-1,1)) + Emulator.cameraPosition.ToVector();
			let nearBottomLeft = (Vector)(viewProjectionMatrixInv * Vector4(-1,-1,-1,1)) + Emulator.cameraPosition.ToVector();
			let nearBottomRight = (Vector)(viewProjectionMatrixInv * Vector4(1,-1,-1,1)) + Emulator.cameraPosition.ToVector();

			renderer.DrawLine(nearTopLeft, farTopLeft , .(16,16,16), .(16,16,16));
			renderer.DrawLine(nearTopRight, farTopRight, .(16,16,16), .(16,16,16));
			renderer.DrawLine(nearBottomLeft, farBottomLeft, .(16,16,16), .(16,16,16));
			renderer.DrawLine(nearBottomRight, farBottomRight, .(16,16,16), .(16,16,16));
			
			renderer.DrawLine(nearTopLeft, nearTopRight, .(16,16,16), .(16,16,16));
			renderer.DrawLine(nearBottomLeft, nearBottomRight, .(16,16,16), .(16,16,16));
			renderer.DrawLine(nearTopLeft, nearBottomLeft, .(16,16,16), .(16,16,16));
			renderer.DrawLine(nearTopRight, nearBottomRight, .(16,16,16), .(16,16,16));

			renderer.DrawLine(farTopLeft, farTopRight, .(16,16,16), .(16,16,16));
			renderer.DrawLine(farBottomLeft, farBottomRight, .(16,16,16), .(16,16,16));
			renderer.DrawLine(farTopLeft, farBottomLeft, .(16,16,16), .(16,16,16));
			renderer.DrawLine(farTopRight, farBottomRight, .(16,16,16), .(16,16,16));
		}
		
		void DrawSpyroInformation() {
			DrawUtilities.Arrow(Emulator.spyroPosition, Emulator.spyroIntendedVelocity / 10, 25, Renderer.Color(255,255,0), renderer);
			DrawUtilities.Arrow(Emulator.spyroPosition, Emulator.spyroPhysicsVelocity / 10, 50, Renderer.Color(255,128,0), renderer);

			let viewerSpyroBasis = Emulator.spyroBasis.ToMatrixCorrected();
			renderer.DrawLine(Emulator.spyroPosition, Emulator.spyroPosition + viewerSpyroBasis * Vector(500,0,0), .(255,0,0), .(255,0,0));
			renderer.DrawLine(Emulator.spyroPosition, Emulator.spyroPosition + viewerSpyroBasis * Vector(0,500,0), .(0,255,0), .(0,255,0));
			renderer.DrawLine(Emulator.spyroPosition, Emulator.spyroPosition + viewerSpyroBasis * Vector(0,0,500), .(0,0,255), .(0,0,255));

			let radius = 0x164;
		
			DrawUtilities.WireframeSphere(Emulator.spyroPosition, viewerSpyroBasis, radius, Renderer.Color(32,32,32), renderer);
		}

		void DrawViewerGUI() {
			if (objectList.Count > 0) {
				if (currentObjIndex != -1) {
					let currentObject = objectList[currentObjIndex];
					// Begin overlays
					let test = viewerMatrix * Vector4(currentObject.position, 1);
					if (test.w > 0) { // Must be in front of view
						let depth = test.w / 300; // Divide by near plane distance for correct depth
						if (!drawObjects) {
							var onscreenOrigin = Vector(test.x * width / (test.w * 2), test.y * height / (test.w * 2), 0);
							DrawUtilities.Circle(onscreenOrigin, Matrix.Scale(400f/depth,400f/depth,400f/depth), Renderer.Color(16,16,16), renderer);

							Emulator.Address objectArrayPointer = ?;
							Emulator.ReadFromRAM(Emulator.objectArrayPointers[(int)Emulator.rom], &objectArrayPointer, 4);

							onscreenOrigin.y += 400f / depth;
							DrawUtilities.Rect(onscreenOrigin.y, onscreenOrigin.y + font.characterHeight * 2, onscreenOrigin.x, onscreenOrigin.x + font.characterWidth * 10,
								0,0,0,0, renderer.textureDefaultWhite, .(0,0,0,192), renderer);
							font.Print(scope String() .. AppendF("[{:X8}]", objectArrayPointer + currentObjIndex * sizeof(Moby)),
								onscreenOrigin, .(255,255,255), renderer);

							font.Print(scope String() .. AppendF("TYPE: {:X4}", currentObject.objectTypeID),
								onscreenOrigin + .(0,font.characterHeight,0), .(255,255,255), renderer);
						}
					}
				}
	
				if (hoveredObjIndex != -1) {
					let hoveredObject = objectList[hoveredObjIndex];
					// Begin overlays
					let test = viewerMatrix * Vector4(hoveredObject.position, 1);
					if (test.w > 0) { // Must be in front of view
						let depth = test.w / 300; // Divide by near plane distance for correct depth
						if (!drawObjects) {
							DrawUtilities.Circle(Vector(test.x * width / (test.w * 2), test.y * height / (test.w * 2), 0), Matrix.Scale(350f/depth,350f/depth,350f/depth), Renderer.Color(128,64,16), renderer);
						}
					}
				}
			}

			// Begin window relative position UI
			let halfWidth = (float)width / 2;
			let halfHeight = (float)height / 2;

			DrawMessageFeed(.(-halfWidth, halfHeight, 0));

			// Legend
			if (collisionTerrain.overlay == .Flags) {
				let leftPaddingBG = 4 - halfWidth;
				let bottomPaddingBG = 4 - halfHeight;

				// Background
				DrawUtilities.Rect(bottomPaddingBG, bottomPaddingBG + 18 * collisionTerrain.collisionTypes.Count + 6, leftPaddingBG, leftPaddingBG + 12 * 8 + 36,
					0,0,0,0, renderer.textureDefaultWhite, .(0,0,0,192), renderer);

				// Content
				for (let i < collisionTerrain.collisionTypes.Count) {
					let flag = collisionTerrain.collisionTypes[i];
					String label = ?;
					Renderer.Color color = ?;
					if (flag < 11 /*Emulator.collisionTypes.Count*/) {
						(label, color) = Emulator.collisionTypes[flag];
					} else {
						label = scope String() .. AppendF("Unknown {}", flag);
						color = .(255, 0, 255);
					}
					let conversion = scope String(label);
					conversion.ToUpper();
	
					let leftPadding = 8 - halfWidth;
					let bottomPadding = 8 - halfHeight + 18 * i;
					DrawUtilities.Rect(bottomPadding, bottomPadding + 16, leftPadding, leftPadding + 16, 0,0,0,0, renderer.textureDefaultWhite, color, renderer);

					font.Print(conversion, .(leftPadding + 24, bottomPadding + 1, 0), .(255,255,255), renderer);
				}
			}

			/*for (let element in guiElements) {
				element.Draw(.(-halfWidth, halfWidth, -halfHeight, halfHeight), renderer);
			}*/
		}

		/*Vector Scene2Screen(Vector worldPosition) {
			let viewPosition = viewerMatrix * Vector4(worldPosition, 1);

		}*/

		int GetObjectIndexUnderMouse() {
			var closestObjectIndex = -1;
			var closestDepth = float.PositiveInfinity;

			for (int objectIndex = 0; objectIndex < objectList.Count; objectIndex++) {
				let object = objectList[objectIndex];
				let viewPosition = viewerMatrix * Vector4(object.position, 1);

				if (viewPosition.w < 0 || viewPosition.w > closestDepth) {
					continue;
				}

				let screenPosition = Vector(viewPosition.x / viewPosition.w * width / 2, viewPosition.y / viewPosition.w * height / 2, 0);
				let selectSize = 400f / viewPosition.w * 300;
				if (mousePosition.x < screenPosition.x + selectSize && mousePosition.x > screenPosition.x - selectSize &&
					mousePosition.y < screenPosition.y + selectSize && mousePosition.y > screenPosition.y - selectSize) {

					closestObjectIndex = objectIndex;
					closestDepth = viewPosition.w;
				}
			}

			return closestObjectIndex;
		}
	}

	static {
		public static WindowApp windowApp;
	}
}
