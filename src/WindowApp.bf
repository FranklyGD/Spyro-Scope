using OpenGL;
using SDL2;
using System;
using System.Collections;

namespace SpyroScope {
	class WindowApp {
		SDL.Window* window;
		Renderer renderer;

		public readonly uint32 id;

		public bool closed { get; private set; }
		public bool drawMapWireframe;

		static uint32 currentObjPointer = 0;

		static bool cameraHijacked;
		static float cameraSpeed = 64;
		static Vector cameraMotion;
		static int cameraRollRate;

		// Viewer Camera
		static bool dislodgeCamera;
		static Vector viewPosition;
		static Vector viewEulerRotation;

		// Game Camera
		static Matrix4 gameProjection = .Perspective(55, 4f/3f, 100, 175000);

		StaticMesh collisionMesh ~ delete _;

		public this() {
			int32 w = 750, h = 600;

			window = SDL.CreateWindow("Scope", .Undefined, .Undefined, w, h,
				.Shown | .Resizable | .InputFocus | .Utility | .OpenGL);
			renderer = new .(window);
			renderer.SetPerspectiveProjection(55f, (float)w / h, 100, 500000);

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
			}

			Emulator.FetchRAMBaseAddress();
			Emulator.FetchImportantObjects();

			UpdateView();

			DrawCollisionMesh();
			if (dislodgeCamera) {
				DrawGameCameraFrustrum();
			}

			// Object picker
			uint32 closestObjPointer = 0;
			Moby closestObj = ?;
			float closestDistance = float.PositiveInfinity;
			
			Emulator.Address objectArrayPointer = ?;
			// The amount originally placed in the world
			//uint32 objectArrayLength = 0;
			Emulator.ReadFromRAM(Emulator.objectArrayPointers[(int)Emulator.rom], &objectArrayPointer, 4);
			//Emulator.ReadFromRAM(objectArrayPointer - 4, &objectArrayLength, 4);

			Emulator.Address objPointer = objectArrayPointer;
			//renderer.model = .Identity;
			for (int i < 512 /*objectArrayLength*/) {
				Moby object = ?;
				Emulator.ReadFromRAM(objPointer, &object, sizeof(Moby));
				if (object.dataPointer == 0) {
					break;
				}

				object.Draw(renderer);

				let objDirection = object.position - Emulator.cameraPosition;
				let distance = objDirection.Length();
				if (distance < closestDistance) {
					closestObjPointer = objPointer;
					closestObj = object;
					closestDistance = distance;
				}

				objPointer += 0x58;
			}
		
			// Use nearest object and inspect
			if (currentObjPointer != closestObjPointer) {
				if (currentObjPointer != 0) {
				}
				currentObjPointer = closestObjPointer;

				Console.WriteLine("Nearest obj [{:X8}] of type {:X}", closestObjPointer, closestObj.objectTypeID);
			}

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
							Emulator.cameraBasis = MatrixInt.Euler(0, (float)cameraEulerRotation[1] / 0x800 * Math.PI_f, (float)cameraEulerRotation[2] / 0x800 * Math.PI_f);

							Emulator.WriteToRAM(Emulator.cameraMatrixAddress[(int)Emulator.rom], &Emulator.cameraBasis, sizeof(MatrixInt));
							Emulator.WriteToRAM(Emulator.cameraEulerRotationAddress[(int)Emulator.rom], &cameraEulerRotation, 6);
						}
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
							let newWidth = event.window.data1;
							let newHeight = event.window.data2;
							GL.glViewport(0, 0, newWidth, newHeight);

							let newAspect = (float)newWidth / newHeight;
							renderer.SetPerspectiveProjection(55f, newAspect, 100, 1000000);
						}
						default : {}
					}
				}
				default : {}
			}
		}

		void OnSceneChanged() {
			let vertexCount = Emulator.collisionTriangles.Count * 3;
			Vector[] v = new .[vertexCount];
			Vector[] n = new .[vertexCount];
			Renderer.Color[] c = new .[vertexCount];

			for (int triangleIndex < Emulator.collisionTriangles.Count) {
				let triangle = Emulator.collisionTriangles[triangleIndex];

				let unpackedTriangle = triangle.Unpack();
				
				let normal = Vector.Cross(unpackedTriangle[2] - unpackedTriangle[0], unpackedTriangle[1] - unpackedTriangle[0]);
				var color = (Emulator.specialTerrainBeginIndex > (uint)triangleIndex) ? Renderer.Color(255,64,64) : Renderer.Color(255,255,255);

				for (int vi < 3) {
					v[triangleIndex * 3 + vi] = unpackedTriangle[vi];
					n[triangleIndex * 3 + vi] = normal;
					c[triangleIndex * 3 + vi] = color;
				}
			}

			delete collisionMesh;
			collisionMesh = new .(v, n, c);
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
			let cameraBasis = Emulator.cameraBasis.ToMatrixCorrected();
			renderer.DrawLine(Emulator.cameraPosition, Emulator.cameraPosition + cameraBasis * Vector(500,0,0), .(0,255,0), .(0,255,0));
			renderer.DrawLine(Emulator.cameraPosition, Emulator.cameraPosition + cameraBasis * Vector(0,500,0), .(0,0,255), .(0,0,255));
			renderer.DrawLine(Emulator.cameraPosition, Emulator.cameraPosition + cameraBasis * Vector(0,0,500), .(255,0,0), .(255,0,0));

			let viewMatrixInv = gameProjection.Inverse();
			let viewProjectionMatrixInv = cameraBasis * viewMatrixInv;

			let topLeft = (Vector)(viewProjectionMatrixInv * Vector4(-1,1,1,1)) + Emulator.cameraPosition.ToVector();
			let topRight = (Vector)(viewProjectionMatrixInv * Vector4(1,1,1,1)) + Emulator.cameraPosition.ToVector();
			let bottomLeft = (Vector)(viewProjectionMatrixInv * Vector4(-1,-1,1,1)) + Emulator.cameraPosition.ToVector();
			let bottomRight = (Vector)(viewProjectionMatrixInv * Vector4(1,-1,1,1)) + Emulator.cameraPosition.ToVector();

			renderer.DrawLine(Emulator.cameraPosition, topLeft , .(128,128,128), .(16,16,16));
			renderer.DrawLine(Emulator.cameraPosition, topRight, .(128,128,128), .(16,16,16));
			renderer.DrawLine(Emulator.cameraPosition, bottomLeft, .(128,128,128), .(16,16,16));
			renderer.DrawLine(Emulator.cameraPosition, bottomRight, .(128,128,128), .(16,16,16));

			renderer.DrawLine(topLeft, topRight, .(16,16,16), .(16,16,16));
			renderer.DrawLine(bottomLeft, bottomRight, .(16,16,16), .(16,16,16));
			renderer.DrawLine(topLeft, bottomLeft, .(16,16,16), .(16,16,16));
			renderer.DrawLine(topRight, bottomRight, .(16,16,16), .(16,16,16));
		}
	}

	static {
		public static WindowApp windowApp;
	}
}
