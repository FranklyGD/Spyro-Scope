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

		static uint32 currentObjPointer = 0;
		static VectorInt originalPos;

		static bool cameraHijacked;
		static float cameraSpeed = 64;
		static Vector cameraMotion;
		static int cameraRollRate;

		public this() {
			int32 w = 500, h = 400;

			window = SDL.CreateWindow("Scope", .Undefined, .Undefined, w, h,
				.Shown | .Resizable | .InputFocus | .Utility | .OpenGL);
			renderer = new .(window);
			renderer.SetPerspectiveProjection(55f, (float)w / h, 100, 1000000);

			id = SDL.GetWindowID(window);

			Emulator.BindToEmulator();
		}

		public ~this() {
			Emulator.UnbindToEmulator();

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

			renderer.SetView(Emulator.cameraPosition, Emulator.cameraBasis.ToMatrixCorrected().Inverse());

			renderer.PushTriangle(Emulator.spyroPosition + .(10,10,0), Emulator.spyroPosition + .(-10,-10,0), Emulator.spyroPosition + Emulator.spyroBasis.Inverse().ToMatrixCorrected().x * 1000,
				.(255,64,64), .(255,64,64), .(255,64,64));
			renderer.PushTriangle(Emulator.spyroPosition + .(10,10,0), Emulator.spyroPosition + .(-10,-10,0), Emulator.spyroPosition + Emulator.spyroBasis.Inverse().ToMatrixCorrected().y * 1000,
				.(64,255,64), .(64,255,64), .(64,255,64));
			renderer.PushTriangle(Emulator.spyroPosition + .(10,10,0), Emulator.spyroPosition + .(-10,-10,0), Emulator.spyroPosition + Emulator.spyroBasis.Inverse().ToMatrixCorrected().z * 1000,
				.(64,64,255), .(64,64,255), .(64,64,255));
			renderer.PushTriangle(Emulator.spyroPosition + .(-10,-10,0), Emulator.spyroPosition + .(10,10,0), Emulator.spyroPosition + Emulator.spyroBasis.Inverse().ToMatrixCorrected().x * 1000,
				.(255,64,64), .(255,64,64), .(255,64,64));
			renderer.PushTriangle(Emulator.spyroPosition + .(-10,-10,0), Emulator.spyroPosition + .(10,10,0), Emulator.spyroPosition + Emulator.spyroBasis.Inverse().ToMatrixCorrected().y * 1000,
				.(64,255,64), .(64,255,64), .(64,255,64));
			renderer.PushTriangle(Emulator.spyroPosition + .(-10,-10,0), Emulator.spyroPosition + .(10,10,0), Emulator.spyroPosition + Emulator.spyroBasis.Inverse().ToMatrixCorrected().z * 1000,
				.(64,64,255), .(64,64,255), .(64,64,255));

			// Draw collision mesh
			for (int triangleIndex < Emulator.collisionTriangles.Count) {
				let triangle = Emulator.collisionTriangles[triangleIndex];

				let unpackedTriangle = triangle.Unpack();
				var color = (Emulator.specialTerrainBeginIndex > (uint)triangleIndex) ? Renderer.Color(255,64,64) : Renderer.Color(255,255,255);
				if (Emulator.collidingTriangle == triangleIndex) {
					color = .(64,64,255);
				}

				renderer.PushTriangle(
					unpackedTriangle[0], unpackedTriangle[1], unpackedTriangle[2],
					color, color, color
				);
			}

			// Object picker
			uint32 closestObjPointer = 0;
			VectorInt closestObjPosition = ?;
			VectorInt closestObjDirection = ?;
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

				let objDirection = object.position - Emulator.cameraPosition;
				let distance = objDirection.Length();
				if (distance < closestDistance && distance > 512) {
					closestObjPointer = objPointer;
					closestObjPosition = object.position;
					closestObjDirection = objDirection;
					closestDistance = distance;
				}

				if (object.draw) {
					renderer.PushTriangle(
						object.position + .(200,0,0), object.position + .(-200,0,0), object.position + .(0,0,200),
						.(255,0,255), .(255,0,255), .(255,0,255)
					);
					renderer.PushTriangle(
						object.position + .(-200,0,0), object.position + .(200,0,0), object.position + .(0,0,200),
						.(255,0,255), .(255,0,255), .(255,0,255)
					);
				}

				renderer.PushTriangle(
					object.position + .(100,0,0), object.position + .(-100,0,0), object.position + .(0,0,100),
					.(0,255,255), .(0,255,255), .(0,255,255)
				);
				renderer.PushTriangle(
					object.position + .(-100,0,0), object.position + .(100,0,0), object.position + .(0,0,100),
					.(0,255,255), .(0,255,255), .(0,255,255)
				);

				if (object.objectTypeID == 0x0400) { // Whirlwind
					WhirlwindData whirlwind = ?;
					Emulator.ReadFromRAM(object.dataPointer, &whirlwind, sizeof(WhirlwindData));
					whirlwind.Draw(renderer, object);
				}

				objPointer += 0x58;
			}
			renderer.Draw();
		
			// Use nearest object and inspect
			if (currentObjPointer != closestObjPointer) {
				if (currentObjPointer != 0) {
					Emulator.WriteToRAM(currentObjPointer + 0xc, &originalPos, sizeof(VectorInt));
				}
				originalPos = closestObjPosition;
				currentObjPointer = closestObjPointer;
			}

			closestObjPosition = originalPos + VectorInt(0, 0, (int32)(0x200 * Math.Sin((float)DateTime.Now.Millisecond / 314)));
			Emulator.WriteToRAM(closestObjPointer + 0xc, &closestObjPosition, sizeof(VectorInt));

			uint16 type = ?;
			Emulator.ReadFromRAM(closestObjPointer + 0x36, &type, sizeof(uint16));

			Console.WriteLine("Direction to nearest obj [{:X8}] of type {:X} is: {}", closestObjPointer, type, closestObjDirection);
			/*if (Emulator.collidingTriangle != -1) {
				Console.WriteLine("Current Triangle Flag 0x{:X2}", Emulator.collisionFlags[Emulator.collidingTriangle]);
			}*/

			// Move camera
			var cameraBasis = Emulator.cameraBasis.ToMatrixCorrected();

			if (cameraHijacked) {
				let cameraMotionDirection = cameraBasis * cameraMotion;
				let cameraNewPosition = Emulator.cameraPosition.ToVector() + cameraMotionDirection;
				Emulator.cameraPosition = cameraNewPosition.ToVectorInt();

				Emulator.MoveCameraTo(&Emulator.cameraPosition);
			}

			renderer.Sync();
			renderer.Display();
		}

		public void Close() {
			closed = true;
		}

		public void OnEvent(SDL.Event event) {
			switch (event.type) {
				case .MouseButtonDown : {
					//Console.WriteLine("MB {}", event.button.button);
					if (event.button.button == 3) {
						SDL.SetRelativeMouseMode(true);
						cameraHijacked = true;
						Emulator.KillCameraUpdate();
					}
				}
				case .MouseMotion : {
					if (cameraHijacked) {
						int16 cameraPitch = ?;	
						Emulator.ReadFromRAM(Emulator.cameraRotationPitchAddress[(int)Emulator.rom], &cameraPitch, 2);
						int16 cameraYaw = ?;	
						Emulator.ReadFromRAM(Emulator.cameraRotationYawAddress[(int)Emulator.rom], &cameraYaw, 2);
	
						cameraYaw -= (.)event.motion.xrel * 2;
						cameraPitch += (.)event.motion.yrel * 2;

						cameraPitch = Math.Clamp(cameraPitch, -0x400, 0x400);
						
						Emulator.WriteToRAM(Emulator.cameraRotationPitchAddress[(int)Emulator.rom], &cameraPitch, 2);
						Emulator.WriteToRAM(Emulator.cameraRotationYawAddress[(int)Emulator.rom], &cameraYaw, 2);
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
					//Console.WriteLine("Key {}", event.key.keysym.unicode);
					if (event.key.isRepeat == 0) {
						if (event.key.keysym.scancode == .P) {
							Emulator.TogglePaused();
						}

						if (event.key.keysym.scancode == .T && Emulator.cameraMode) {
							Emulator.spyroPosition = Emulator.cameraPosition;
							Emulator.WriteToRAM(Emulator.spyroPositionPointers[(int)Emulator.rom], &Emulator.spyroPosition, sizeof(VectorInt));
						}
						if (event.key.keysym.scancode == .C) {
							Emulator.ToggleCameraMode();
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

		/*mixin DrawAxis(Vector position, Matrix basis) {
			SDL.SetRenderDrawColor(renderer, 255,64,64,255);
			SDL.RenderDrawLine(renderer, (.)position.x, (.)position.y, (.)(position.x + basis.x.x * 32), (.)(position.y - basis.x.y * 32));  
			SDL.SetRenderDrawColor(renderer, 64,255,64,255);
			SDL.RenderDrawLine(renderer, (.)position.x, (.)position.y, (.)(position.x - basis.y.x * 32), (.)(position.y + basis.y.y * 32));	  
			SDL.SetRenderDrawColor(renderer, 64,64,255,255);
			SDL.RenderDrawLine(renderer, (.)position.x, (.)position.y, (.)(position.x + basis.z.x * 32), (.)(position.y - basis.z.y * 32));
		}*/


	}

	static {
		public static WindowApp windowApp;
	}
}
