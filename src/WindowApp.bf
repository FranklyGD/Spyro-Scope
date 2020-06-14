using OpenGL;
using SDL2;
using System;
using System.Collections;

namespace SpyroScope {
	class WindowApp {
		SDL.Window* window;
		Renderer renderer;

		public readonly uint32 id;
		public uint width, height;

		public bool closed { get; private set; }
		public bool drawMapWireframe;

		static int currentObjIndex, hoveredObjIndex;
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

		StaticMesh collisionMesh ~ delete _;

		//List<GUIElement> guiElements = new .() ~ DeleteContainerAndItems!(_);

		public this() {
			width = 750;
			height = 600;

			window = SDL.CreateWindow("Scope", .Undefined, .Undefined, (.)width, (.)height,
				.Shown | .Resizable | .InputFocus | .Utility | .OpenGL);
			renderer = new .(window);

			viewerProjection = .Perspective(55f / 180 * Math.PI_f, (float)width / height, 100, 500000);
			uiProjection = .Orthogonal(width, height, 0, 1);

			id = SDL.GetWindowID(window);

			Emulator.OnSceneChanged = new => OnSceneChanged;

			Emulator.BindToEmulator();
		}

		public ~this() {
			Emulator.UnbindToEmulator();
			
			delete Emulator.OnSceneChanged;

			if (renderer != null)
				delete renderer;
			if (window != null)
				SDL.DestroyWindow(window);

			window = null;
		}

		public void Run() {
			renderer.Clear();

			Emulator.CheckEmulatorStatus();

			if (Emulator.emulator == .None) {
				Close();
				return;
			}

			Emulator.FetchRAMBaseAddress();
			Emulator.FetchImportantObjects();

			UpdateView();
			
			GL.glEnable(GL.GL_DEPTH_TEST);

			DrawCollisionMesh();
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

				objectList.Add(object);
				object.Draw(renderer);

				objPointer += 0x58;
			}

			DrawSpyroInformation();
			
			renderer.SetModel(.Zero, .Identity);
			renderer.SetTint(.(255,255,255));
			renderer.Draw();

			viewerMatrix = renderer.projection * renderer.view;

			// Setup render view for drawing GUI and overlays
			renderer.SetView(.Zero, .Identity);
			renderer.SetProjection(uiProjection);
			GL.glDisable(GL.GL_DEPTH_TEST);

			DrawGUI();

			renderer.Draw();
			renderer.Sync();
			renderer.Display();
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
						if (!dislodgeCamera) {
							Emulator.KillCameraUpdate();
						}
					}
					if (event.button.button == 1) {
						currentObjIndex = hoveredObjIndex;

						if (currentObjIndex != -1) {
							Emulator.Address objectArrayPointer = ?;
							Emulator.ReadFromRAM(Emulator.objectArrayPointers[(int)Emulator.rom], &objectArrayPointer, 4);

							Console.WriteLine("Selected object [{:X8}] of type {:X}", objectArrayPointer + currentObjIndex * sizeof(Moby), objectList[currentObjIndex].objectTypeID);
						}
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
						if (event.key.keysym.scancode == .P) {
							Emulator.TogglePaused();
						}
						if (event.key.keysym.scancode == .LCtrl) {
							cameraSpeed *= 8;
							cameraMotion *= 8;
						}
						if (event.key.keysym.scancode == .M) {
							drawMapWireframe = !drawMapWireframe;
						}
						if (event.key.keysym.scancode == .K) {
							uint health = 0;
							Emulator.WriteToRAM(Emulator.fuckSparx[(int)Emulator.rom], &health, 4);
						}
						if (event.key.keysym.scancode == .T && Emulator.cameraMode) {
							Emulator.spyroPosition = viewPosition.ToVectorInt();
							Emulator.WriteToRAM(Emulator.spyroPositionPointers[(int)Emulator.rom], &Emulator.spyroPosition, sizeof(VectorInt));
						}
						if (event.key.keysym.scancode == .C) {
							Emulator.ToggleCameraMode();
						}
						if (event.key.keysym.scancode == .V) {
							dislodgeCamera = !dislodgeCamera;
						}
						if (cameraHijacked) {
							if (event.key.keysym.scancode == .W) {
								cameraMotion.z -= cameraSpeed;
							}
							if (event.key.keysym.scancode == .S) {
								cameraMotion.z += cameraSpeed;
							}
							if (event.key.keysym.scancode == .A) {
								cameraMotion.x -= cameraSpeed;
							}
							if (event.key.keysym.scancode == .D) {
								cameraMotion.x += cameraSpeed;
							}
							if (event.key.keysym.scancode == .Space) {
								cameraMotion.y += cameraSpeed;
							}
							if (event.key.keysym.scancode == .LShift) {
								cameraMotion.y -= cameraSpeed;
							}

							

							//int16 cameraRoll = ?;	
							//Emulator.ReadFromRAM(Emulator.cameraRotationRollAddress[(int)Emulator.rom], &cameraRoll, 2);

							/*if (event.key.keysym.scancode == .Q) {
								if (cameraRollRate != 0) {
									cameraRoll = cameraRollRate = 0;
								} else {
									cameraRollRate = 8;
								}
							}
							if (event.key.keysym.scancode == .E) {
								if (cameraRollRate != 0) {
									cameraRoll = cameraRollRate = 0;
								} else {
									cameraRollRate = -8;
								}
							}*/
							
							//Emulator.WriteToRAM(Emulator.cameraRotationRollAddress[(int)Emulator.rom], &cameraRoll, 2);
						}
					}
				}
				case .KeyUp : {
					//Console.WriteLine("Key {}", event.key.keysym.unicode);
					if (event.key.keysym.scancode == .LCtrl) {
						cameraSpeed /= 8;
						cameraMotion /= 8;
					}

					if (cameraHijacked) {
						if (event.key.keysym.scancode == .W) {
							cameraMotion.z = 0;
						}
						if (event.key.keysym.scancode == .S) {
							cameraMotion.z = 0;
						}
						if (event.key.keysym.scancode == .A) {
							cameraMotion.x = 0;
						}
						if (event.key.keysym.scancode == .D) {
							cameraMotion.x = 0;
						}
						if (event.key.keysym.scancode == .Space) {
							cameraMotion.y = 0;
						}
						if (event.key.keysym.scancode == .LShift) {
							cameraMotion.y = 0;
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

		void OnSceneChanged() {
			currentObjIndex = -1;

			let vertexCount = Emulator.collisionTriangles.Count * 3;
			Vector[] vertices = new .[vertexCount];
			Vector[] normals = new .[vertexCount];
			Renderer.Color[] colors = new .[vertexCount];

			for (int triangleIndex < Emulator.collisionTriangles.Count) {
				let triangle = Emulator.collisionTriangles[triangleIndex];

				let unpackedTriangle = triangle.Unpack();
				
				let normal = Vector.Cross(unpackedTriangle[2] - unpackedTriangle[0], unpackedTriangle[1] - unpackedTriangle[0]);
				let color = (Emulator.specialTerrainBeginIndex > (uint)triangleIndex) ? Renderer.Color(255,64,64) : Renderer.Color(255,255,255);

				for (int vi < 3) {
					let i = triangleIndex * 3 + vi;
					vertices[i] = unpackedTriangle[vi];
					normals[i] = normal;
					colors[i] = color;
				}
			}

			delete collisionMesh;
			collisionMesh = new .(vertices, normals, colors);
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

		void DrawCollisionMesh() {
			renderer.SetModel(.Zero, .Identity);
			renderer.SetTint(.(255,255,255));
			renderer.BeginSolid();

			if (!drawMapWireframe) {
				collisionMesh.Draw();
				renderer.SetTint(.(128,128,128));
			}

			renderer.BeginWireframe();
			collisionMesh.Draw();

			// Restore polygon mode to default
			renderer.BeginSolid();
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
			DrawUtilities.Arrow!(Emulator.spyroPosition, Emulator.spyroVelocity / 10, 25, Renderer.Color(255,255,0), renderer);
			DrawUtilities.Arrow!(Emulator.spyroPosition, Emulator.spyroPhysics / 10, 50, Renderer.Color(255,128,0), renderer);

			let viewerSpyroBasis = Emulator.spyroBasis.ToMatrix();
			renderer.DrawLine(Emulator.cameraPosition, Emulator.cameraPosition + viewerSpyroBasis * Vector(500,0,0), .(255,0,0), .(255,0,0));
			renderer.DrawLine(Emulator.cameraPosition, Emulator.cameraPosition + viewerSpyroBasis * Vector(0,500,0), .(0,255,0), .(0,255,0));
			renderer.DrawLine(Emulator.cameraPosition, Emulator.cameraPosition + viewerSpyroBasis * Vector(0,0,500), .(0,0,255), .(0,0,255));
		}

		void DrawGUI() {
			if (currentObjIndex != -1) {
				let currentObject = objectList[currentObjIndex];
				// Begin overlays
				let test = viewerMatrix * Vector4(currentObject.position, 1);
				if (test.w > 0) { // Must be in front of view
					let depth = test.w / 300; // Divide by near plane distance for correct depth
					DrawUtilities.Circle!(Vector(test.x * width / (test.w * 2), test.y * height / (test.w * 2), 0), Matrix.Scale(400f/depth,400f/depth,400f/depth), Renderer.Color(16,16,16), renderer);
				}
			}

			if (hoveredObjIndex != -1) {
				let hoveredObject = objectList[hoveredObjIndex];
				// Begin overlays
				let test = viewerMatrix * Vector4(hoveredObject.position, 1);
				if (test.w > 0) { // Must be in front of view
					let depth = test.w / 300; // Divide by near plane distance for correct depth
					DrawUtilities.Circle!(Vector(test.x * width / (test.w * 2), test.y * height / (test.w * 2), 0), Matrix.Scale(350f/depth,350f/depth,350f/depth), Renderer.Color(128,64,16), renderer);
				}
			}

			/*let halfWidth = (float)width / 2;
			let halfHeight = (float)height / 2;
			for (let element in guiElements) {
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
