using SDL2;
using System;
using System.Collections;

namespace SpyroScope {
	class ViewerState : WindowState {
		bool dislodgeCamera;
		bool cameraHijacked;
		float cameraSpeed = 64;
		Vector cameraMotion;
		Vector viewEulerRotation;

		bool drawObjects;

		int currentObjIndex = -1;
		int hoveredObjIndex = -1;
		List<Moby> objectList = new .(128) ~ delete _;

		Terrain collisionTerrain = new .() ~ delete _;
		bool drawLimits = true;

		Dictionary<uint16, MobyModelSet> modelSets = new .();

		Vector mousePosition;

		List<(String message, DateTime time)> messageFeed = new .();
		//List<GUIElement> guiElements = new .() ~ DeleteContainerAndItems!(_);

		public ~this () {
			for (let modelSet in modelSets.Values) {
				delete modelSet;
			}
			delete modelSets;
			for (let feedItem in messageFeed) {
				if (feedItem.message.IsDynAlloc) {
					delete feedItem.message;
				}
			}
			delete messageFeed;
		}

		public override void Enter() {
			Emulator.OnSceneChanged = new => OnSceneChanged;
		}

		public override void Exit() {
			delete Emulator.OnSceneChanged;
		}

		public override void Update() {
			Emulator.CheckEmulatorStatus();

			if (Emulator.emulator == .None || Emulator.rom == .None) {
				windowApp.GoToState!<SetupState>();
			}

			Emulator.FetchRAMBaseAddress();
			Emulator.FetchImportantObjects();

			collisionTerrain.Update();

			UpdateView();
		}

		public override void DrawView(Renderer renderer) {
			collisionTerrain.Draw(renderer);
			if (dislodgeCamera) {
				DrawGameCameraFrustrum();
			}

			Emulator.Address objectArrayAddress = ?;
			Emulator.objectArrayPointers[(int)Emulator.rom].Read(&objectArrayAddress);
			Emulator.Address objPointer = objectArrayAddress;

			objectList.Clear();
			for (int i < 512 /* Load object limit */) {
				Moby object = ?;
				Emulator.ReadFromRAM(objPointer, &object, sizeof(Moby));
				if (object.dataPointer.IsNull) {
					break;
				}

				if (object.HasModel) {
					if (modelSets.ContainsKey(object.objectTypeID)) {
						let basis = Matrix.Euler(
							-(float)object.eulerRotation.x / 0x80 * Math.PI_f,
							(float)object.eulerRotation.y / 0x80 * Math.PI_f,
							-(float)object.eulerRotation.z / 0x80 * Math.PI_f
						);

						renderer.SetModel(object.position, basis * 2);
						renderer.SetTint(.(255,255,255));
						modelSets[object.objectTypeID].models[object.modelID].QueueInstance(renderer);
					} else {
						Emulator.Address modelSetAddress = ?;
						Emulator.ReadFromRAM(Emulator.modelPointers[(int)Emulator.rom] + 4 * object.objectTypeID, &modelSetAddress, 4);

						if (modelSetAddress != 0 && (int32)modelSetAddress > 0) {
							modelSets.Add(object.objectTypeID, new .(modelSetAddress));
						}
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

			if (drawLimits) {
				uint32 currentWorldId = ?;
				Emulator.currentWorldIdAddress[(int)Emulator.rom].Read(&currentWorldId);

				uint32 deathHeight;
				if (Emulator.rom == .YearOfTheDragon) {
					uint32 currentSubWorldId = ?;
					Emulator.currentSubWorldIdAddress.Read(&currentSubWorldId);

					deathHeight = Emulator.deathPlaneHeights[currentWorldId * 4 + currentSubWorldId];
				} else {
					deathHeight = Emulator.deathPlaneHeights[currentWorldId];
				}

				if (Camera.position.z > deathHeight) {
					DrawUtilities.Grid(.(0,0,deathHeight), .Identity, .(255,64,32), renderer);
				}
				
				let flightHeight = Emulator.maxFreeflightHeights[currentWorldId];
				if (Camera.position.z < flightHeight) {
					DrawUtilities.Grid(.(0,0,flightHeight), .Identity, .(32,64,255), renderer);
				}
			}

			renderer.SetModel(.Zero, .Identity);
			renderer.SetTint(.(255,255,255));
			renderer.Draw();
		}

		public override void DrawGUI(Renderer renderer) {
			if (objectList.Count > 0) {
				if (currentObjIndex != -1) {
					let currentObject = objectList[currentObjIndex];
					// Begin overlays
					let screenPosition = Camera.SceneToScreen(currentObject.position);
					if (!drawObjects && screenPosition.z > 0) { // Must be in front of view
						var onscreenOrigin = screenPosition;
						let screenSize = Camera.SceneSizeToScreenSize(200, screenPosition.z);
						onscreenOrigin.z = 0;
						DrawUtilities.Circle(onscreenOrigin, Matrix.Scale(screenSize,screenSize,screenSize), Renderer.Color(16,16,16), renderer);

						Emulator.Address objectArrayPointer = ?;
						Emulator.ReadFromRAM(Emulator.objectArrayPointers[(int)Emulator.rom], &objectArrayPointer, 4);

						onscreenOrigin.y += screenSize;
						DrawUtilities.Rect(onscreenOrigin.y, onscreenOrigin.y + WindowApp.bitmapFont.characterHeight * 2 + 6, onscreenOrigin.x, onscreenOrigin.x + WindowApp.bitmapFont.characterWidth * 10,
							0,0,0,0, Renderer.textureDefaultWhite, .(0,0,0,192), renderer);

						WindowApp.bitmapFont.Print(scope String() .. AppendF("[{}]", objectArrayPointer + currentObjIndex * sizeof(Moby)),
							onscreenOrigin, .(255,255,255), renderer);
						WindowApp.bitmapFont.Print(scope String() .. AppendF("TYPE: {:X4}", currentObject.objectTypeID),
							onscreenOrigin + .(0,WindowApp.bitmapFont.characterHeight,0), .(255,255,255), renderer);
					}
				}

				if (hoveredObjIndex != -1) {
					let hoveredObject = objectList[hoveredObjIndex];
					// Begin overlays
					var screenPosition = Camera.SceneToScreen(hoveredObject.position);
					if (screenPosition.z > 0) { // Must be in front of view
						let screenSize = Camera.SceneSizeToScreenSize(150, screenPosition.z);
						screenPosition.z = 0;
						if (!drawObjects) {
							DrawUtilities.Circle(screenPosition, Matrix.Scale(screenSize,screenSize,screenSize), Renderer.Color(128,64,16), renderer);
						}
					}
				}
			}

			// Begin window relative position UI
			let halfWidth = (float)WindowApp.width / 2;
			let halfHeight = (float)WindowApp.height / 2;

			DrawMessageFeed(.(-halfWidth, halfHeight, 0));

			// Legend
			if (collisionTerrain.overlay == .Flags) {
				let leftPaddingBG = 4 - halfWidth;
				let bottomPaddingBG = 4 - halfHeight;

				// Background
				DrawUtilities.Rect(bottomPaddingBG, bottomPaddingBG + 18 * collisionTerrain.collisionTypes.Count + 6, leftPaddingBG, leftPaddingBG + 12 * 8 + 36,
					0,0,0,0, Renderer.textureDefaultWhite, .(0,0,0,192), renderer);

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

					let leftPadding = 8 - halfWidth;
					let bottomPadding = 8 - halfHeight + 18 * i;
					DrawUtilities.Rect(bottomPadding, bottomPadding + 16, leftPadding, leftPadding + 16, 0,0,0,0, Renderer.textureDefaultWhite, color, renderer);

					WindowApp.bitmapFont.Print(label, .(leftPadding + 24, bottomPadding + 1 - 6, 0), .(255,255,255), renderer);
				}
			}

			/*for (let element in guiElements) {
				element.Draw(.(-halfWidth, halfWidth, -halfHeight, halfHeight), renderer);
			}*/
		}

		public override bool OnEvent(SDL2.SDL.Event event) {
			switch (event.type) {
				case .MouseButtonDown : {
					if (event.button.button == 3) {
						SDL.SetRelativeMouseMode(true);
						cameraHijacked = true;
						if (!dislodgeCamera && !Emulator.CameraMode) {
							Emulator.KillCameraUpdate();
							PushMessageToFeed("Free Camera");
						}
					}
					if (event.button.button == 1) {
						currentObjIndex = hoveredObjIndex;
					
						Emulator.Address objectArrayPointer = ?;
						Emulator.ReadFromRAM(Emulator.objectArrayPointers[(int)Emulator.rom], &objectArrayPointer, 4);
	
						SDL.SetClipboardText(scope String() .. AppendF("{}", objectArrayPointer + currentObjIndex * sizeof(Moby)));
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
							Emulator.cameraEulerRotationAddress[(int)Emulator.rom].Read(&cameraEulerRotation);
	
							cameraEulerRotation[2] -= (.)event.motion.xrel * 2;
							cameraEulerRotation[1] += (.)event.motion.yrel * 2;
							cameraEulerRotation[1] = Math.Clamp(cameraEulerRotation[1], -0x400, 0x400);
	
							// Force camera view basis in game
							Emulator.cameraBasisInv = MatrixInt.Euler(0, (float)cameraEulerRotation[1] / 0x800 * Math.PI_f, (float)cameraEulerRotation[2] / 0x800 * Math.PI_f);
	
							Emulator.cameraMatrixAddress[(int)Emulator.rom].Write(&Emulator.cameraBasisInv);
							Emulator.cameraEulerRotationAddress[(int)Emulator.rom].Write(&cameraEulerRotation);
						}
					} else {
						var mousePosX = event.motion.x - (int)WindowApp.width / 2;
						var mousePosY = (int)WindowApp.height / 2 - event.motion.y;
	
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
									PushMessageToFeed("Resumed Game Update");
								} else {
									Emulator.KillUpdate();
									PushMessageToFeed("Paused Game Update");
								}
							}
							case .LCtrl : {
								cameraSpeed *= 8;
								cameraMotion *= 8;
							}
							case .M : {
								collisionTerrain.wireframe = !collisionTerrain.wireframe;
								PushMessageToFeed("Toggled Terrain Wireframe");
							}
							case .O : {
								drawObjects = !drawObjects;
								PushMessageToFeed("Toggled Object Origins");
							}
							case .L : {
								collisionTerrain.CycleOverlay();
								String overlayType;
								switch (collisionTerrain.overlay) {
									case .None:
										overlayType = "None";
									case .Flags:
										overlayType = "Flags";
									case .Deform:
										overlayType = "Deform";
									case .Water:
										overlayType = "Water";
								}
								PushMessageToFeed(new String() .. AppendF("Terrain Overlay [{}]", overlayType));
							}
							case .K : {
								uint32 health = 0;
								Emulator.healthAddresses[(int)Emulator.rom].Write(&health);
							}
							case .T : {
								if (Emulator.CameraMode) {
									Emulator.spyroPosition = Camera.position.ToVectorInt();
									Emulator.spyroPositionAddresses[(int)Emulator.rom].Write(&Emulator.spyroPosition);
									PushMessageToFeed("Teleported Spyro to Game Camera");
								}
							}
							case .C : {
								if (Emulator.CameraMode) {
									Emulator.RestoreCameraUpdate();
									PushMessageToFeed("Game Camera");
								} else {
									Emulator.KillCameraUpdate();
									PushMessageToFeed("Free Camera");
								}
							}
							case .V : {
								dislodgeCamera = !dislodgeCamera;
								if (dislodgeCamera) {
									PushMessageToFeed("Free View");
								} else {
									PushMessageToFeed("Game View");
								}
							}
							case .H : {
								drawLimits = !drawLimits;
								PushMessageToFeed("Toggled Height Limits");
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
				default : return false;
			}

			return true;
		}

		void UpdateView() {
			if (!dislodgeCamera) {
				Camera.position = Emulator.cameraPosition;
				viewEulerRotation.x = (float)Emulator.cameraEulerRotation[1] / 0x800;
				viewEulerRotation.y = (float)Emulator.cameraEulerRotation[0] / 0x800;
				viewEulerRotation.z = (float)Emulator.cameraEulerRotation[2] / 0x800;
			}

			viewEulerRotation.z = Math.Repeat(viewEulerRotation.z + 1, 2) - 1;

			// Corrected view matrix for the scope
			Camera.basis = Matrix.Euler(
				(viewEulerRotation.x - 0.5f) * Math.PI_f,
				viewEulerRotation.y  * Math.PI_f,
				(0.5f - viewEulerRotation.z) * Math.PI_f
			);

			// Move camera
			if (cameraHijacked) {
				let cameraMotionDirection = Camera.basis  * cameraMotion;
				
				if (dislodgeCamera) {
					Camera.position += cameraMotionDirection;
				} else {
					let cameraNewPosition = Emulator.cameraPosition.ToVector() + cameraMotionDirection;
					Emulator.cameraPosition = cameraNewPosition.ToVectorInt();
					Emulator.MoveCameraTo(&Emulator.cameraPosition);
				}
			}
		}

		void OnSceneChanged() {
			currentObjIndex = hoveredObjIndex = -1;

			collisionTerrain.Reload();
		}

		void PushMessageToFeed(String message) {
			messageFeed.Add((message, .Now + TimeSpan(0, 0, 2)));
		}

		
		void DrawGameCameraFrustrum() {
			let cameraBasis = Emulator.cameraBasisInv.ToMatrixCorrected().Transpose();
			let cameraBasisCorrected = Matrix(cameraBasis.y, cameraBasis.z, -cameraBasis.x);
			let renderer = WindowApp.renderer;

			renderer.DrawLine(Emulator.cameraPosition, Emulator.cameraPosition + cameraBasis * Vector(500,0,0), .(255,0,0), .(255,0,0));
			renderer.DrawLine(Emulator.cameraPosition, Emulator.cameraPosition + cameraBasis * Vector(0,500,0), .(0,255,0), .(0,255,0));
			renderer.DrawLine(Emulator.cameraPosition, Emulator.cameraPosition + cameraBasis * Vector(0,0,500), .(0,0,255), .(0,0,255));

			let projectionMatrixInv = WindowApp.gameProjection.Inverse();
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
			let renderer = WindowApp.renderer;
			DrawUtilities.Arrow(Emulator.spyroPosition, Emulator.spyroIntendedVelocity / 10, 25, Renderer.Color(255,255,0), renderer);
			DrawUtilities.Arrow(Emulator.spyroPosition, Emulator.spyroPhysicsVelocity / 10, 50, Renderer.Color(255,128,0), renderer);

			let viewerSpyroBasis = Emulator.spyroBasis.ToMatrixCorrected();
			renderer.DrawLine(Emulator.spyroPosition, Emulator.spyroPosition + viewerSpyroBasis * Vector(500,0,0), .(255,0,0), .(255,0,0));
			renderer.DrawLine(Emulator.spyroPosition, Emulator.spyroPosition + viewerSpyroBasis * Vector(0,500,0), .(0,255,0), .(0,255,0));
			renderer.DrawLine(Emulator.spyroPosition, Emulator.spyroPosition + viewerSpyroBasis * Vector(0,0,500), .(0,0,255), .(0,0,255));

			let radius = 0x164;

			DrawUtilities.WireframeSphere(Emulator.spyroPosition, viewerSpyroBasis, radius, Renderer.Color(32,32,32), renderer);
		}

		void DrawMessageFeed(Vector origin) {
			let now = DateTime.Now;

			messageFeed.RemoveAll(scope (x) => {
				let pendingRemove = now > x.time;
				if (pendingRemove && x.message.IsDynAlloc) {
					delete x.message;
				}
				return now > x.time;
			});

			for (let i < messageFeed.Count) {
				let feedItem = messageFeed[i];
				let message = feedItem.message;
				let age = feedItem.time - now;
				let fade = Math.Min(age.TotalSeconds, 1);
				let offsetOrigin = origin - .(0,(messageFeed.Count - i) * WindowApp.font.height,0);
				DrawUtilities.Rect(offsetOrigin.y, offsetOrigin.y + WindowApp.font.height, offsetOrigin.x, offsetOrigin.x + WindowApp.font.CalculateWidth(message) + 4,
					0,0,0,0, Renderer.textureDefaultWhite, .(0,0,0,(.)(192 * fade)), WindowApp.renderer);
				WindowApp.font.Print(message, offsetOrigin + .(2,4,0), .(255,255,255,(.)(255 * fade)),  WindowApp.renderer);
			}
		}

		int GetObjectIndexUnderMouse() {
			var closestObjectIndex = -1;
			var closestDepth = float.PositiveInfinity;

			for (int objectIndex = 0; objectIndex < objectList.Count; objectIndex++) {
				let object = objectList[objectIndex];
				
				let screenPosition = Camera.SceneToScreen(object.position);

				if (screenPosition.z == 0) {
					continue;
				}

				let selectSize = Camera.SceneSizeToScreenSize(200, screenPosition.z);
				if (mousePosition.x < screenPosition.x + selectSize && mousePosition.x > screenPosition.x - selectSize &&
					mousePosition.y < screenPosition.y + selectSize && mousePosition.y > screenPosition.y - selectSize) {

					closestObjectIndex = objectIndex;
					closestDepth = screenPosition.z;
				}
			}

			return closestObjectIndex;
		}
	}
}
