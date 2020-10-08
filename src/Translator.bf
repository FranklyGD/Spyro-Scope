using System;

namespace SpyroScope {
	static class Translator {
		static Vector position;
		static Matrix basis;
		static float scale;

		static Vector referencePosition;
		static Matrix referenceBasis;
		static Vector offset;

		public static bool hovered { get { return axisIndex > 0; } };
		public static bool dragged { get; private set; };
		static int8 axisIndex;
		static int8 axisVisibleIndex;

		static Vector anim;

		public static Event<delegate void()> OnDragBegin ~ _.Dispose();
		public static Event<delegate void(Vector)> OnDragged ~ _.Dispose();
		public static Event<delegate void()> OnDragEnd ~ _.Dispose();

		public static void Update(Vector position, Matrix basis) {
			let viewDirection = Camera.orthographic ? Camera.basis.z : (Camera.position - Translator.position).Normalized();
			axisVisibleIndex = 0;
			if (Math.Abs(Vector.Dot(viewDirection, Translator.basis.x)) < 0.96f) {
				axisVisibleIndex |= 1;
			}
			if (Math.Abs(Vector.Dot(viewDirection, Translator.basis.y)) < 0.96f) {
				axisVisibleIndex |= 2;
			}
			if (Math.Abs(Vector.Dot(viewDirection, Translator.basis.z)) < 0.96f) {
				axisVisibleIndex |= 4;
			}
			if (Math.Abs(Vector.Dot(viewDirection, Translator.basis.x)) > 0.2f) {
				axisVisibleIndex |= 8;
			}
			if (Math.Abs(Vector.Dot(viewDirection, Translator.basis.y)) > 0.2f) {
				axisVisibleIndex |= 16;
			}
			if (Math.Abs(Vector.Dot(viewDirection, Translator.basis.z)) > 0.2f) {
				axisVisibleIndex |= 32;
			}

			if (!dragged) {
				Translator.position = position;
				Translator.basis = basis;
			}

			anim.x = Math.MoveTo(anim.x, (axisIndex & 1) > 0 ? 1 : 0, 0.2f);
			anim.y = Math.MoveTo(anim.y, (axisIndex & 2) > 0 ? 1 : 0, 0.2f);
			anim.z = Math.MoveTo(anim.z, (axisIndex & 4) > 0 ? 1 : 0, 0.2f);
		}

		public static void Draw() {
			scale = Camera.orthographic ? Camera.size : Camera.SceneToScreen(position).z;
			let squareAngle = Math.PI_f / 2;

			var axisLength = scale * 0.125f;
			var axisDiameter = scale * 0.01f;
			if (axisVisibleIndex & 1 > 0) {
				Renderer.Color xColor = (axisIndex & 1) > 0 ? .(255,128,128) : .(255,0,0);
				DrawUtilities.Arrow(position, basis.x * (axisLength + anim.x * 0.01f * scale), axisDiameter, xColor);
			}
			if (axisVisibleIndex & 2 > 0) {
				Renderer.Color yColor = (axisIndex & 2) > 0 ? .(128,255,128) : .(0,255,0);
				DrawUtilities.Arrow(position, basis.y * (axisLength + anim.y * 0.01f * scale), axisDiameter, yColor);
			}
			if (axisVisibleIndex & 4 > 0) {
				Renderer.Color zColor = (axisIndex & 4) > 0 ? .(128,128,255) : .(0,0,255);
				DrawUtilities.Arrow(position, basis.z * (axisLength + anim.z * 0.01f * scale), axisDiameter, zColor);
			}

			axisLength /= 3;
			axisDiameter *= 2f/3;
			
			if (axisVisibleIndex & 8 > 0) {
				Renderer.SetTint((axisIndex & 6) == 6 ? .(255,128,128) : .(255,64,64));
				Renderer.SetModel(position + (basis.y / 2 + basis.z) * axisLength, basis * .Euler(squareAngle, 0, 0) * .Scale(axisDiameter, axisDiameter, axisLength));
				PrimitiveShape.cylinder.QueueInstance();
				Renderer.SetModel(position + (basis.z / 2 + basis.y) * axisLength, basis * .Scale(axisDiameter, axisDiameter, axisLength));
				PrimitiveShape.cylinder.QueueInstance();
			}
			
			if (axisVisibleIndex & 16 > 0) {
				Renderer.SetTint((axisIndex & 5) == 5 ? .(128,255,128) : .(64,255,64));
				Renderer.SetModel(position + (basis.x / 2 + basis.z) * axisLength, basis * .Euler(0, squareAngle, 0) * .Scale(axisDiameter, axisDiameter, axisLength));
				PrimitiveShape.cylinder.QueueInstance();
				Renderer.SetModel(position + (basis.z / 2 + basis.x) * axisLength, basis * .Scale(axisDiameter, axisDiameter, axisLength));
				PrimitiveShape.cylinder.QueueInstance();
			}
				
			if (axisVisibleIndex & 32 > 0) {
				Renderer.SetTint((axisIndex & 3) == 3 ? .(128,128,255) : .(64,64,255));
				Renderer.SetModel(position + (basis.x / 2 + basis.y) * axisLength, basis * .Euler(0, squareAngle, 0) * .Scale(axisDiameter, axisDiameter, axisLength));
				PrimitiveShape.cylinder.QueueInstance();
				Renderer.SetModel(position + (basis.y / 2 + basis.x) * axisLength, basis * .Euler(squareAngle, 0, 0) * .Scale(axisDiameter, axisDiameter, axisLength));
				PrimitiveShape.cylinder.QueueInstance();
			}

			if (dragged) {
				if (axisIndex == 1 || axisIndex == 2 || axisIndex == 4) {
					Vector axis = ?;
					Renderer.Color4 color = ?;
					switch (axisIndex) {
						case 1: axis = referenceBasis.x; color = .(255,0,0);
						case 2: axis = referenceBasis.y; color = .(0,255,0);
						case 4: axis = referenceBasis.z; color = .(0,0,255);
					}

					let referenceToCamera = Camera.position - referencePosition;
					let tickDirection = Vector.Cross(axis, referenceToCamera.Normalized());
					let normalDirection = Vector.Cross(tickDirection, axis);

					let viewDistance = Math.Max(Math.Abs(Vector.Dot(normalDirection, Camera.position - referencePosition)), 1000);
					Renderer.DrawLine(referencePosition + axis * viewDistance * 4, referencePosition + axis * -viewDistance * 4, color, color);

					for (int i = -100; i <= 100; i++) {
						let tickPosition = referencePosition + axis * i * 100;
						let tickSize = (i % 10) == 0 ? 100 : 50;
						Renderer.DrawLine(tickPosition + tickDirection * tickSize, tickPosition - tickDirection * tickSize, color, color);
					}
				} else {
					Matrix planeBasis = ?;
					Renderer.Color4 color = ?;
					switch (axisIndex) {
						case 6: color = .(255,32,32); planeBasis = .(referenceBasis.y, referenceBasis.z, referenceBasis.x);
						case 5: color = .(32,255,32); planeBasis = .(referenceBasis.z, referenceBasis.x, referenceBasis.y);
						case 3: color = .(32,32,255); planeBasis = referenceBasis;
						case 7: color = .(64,64,64); planeBasis = Camera.basis; 
					}

					DrawUtilities.Grid(referencePosition, planeBasis, color);
				}
			}
		}

		public static void MousePress(Vector mousePosition) {
			if (hovered) {
				dragged = true;
				BeginDragged(mousePosition);
			}
		}

		public static bool MouseMove(Vector mousePosition) {
			let mouseOrigin = Camera.ScreenPointToOrigin(mousePosition);
			let mouseRay = Camera.ScreenPointToRay(mousePosition);

			if (dragged) {
				if (axisIndex == 1 || axisIndex == 2 || axisIndex == 4) {
					Vector axis = ?;
					switch (axisIndex) {
						case 1: axis = referenceBasis.x;
						case 2: axis = referenceBasis.y;
						case 4: axis = referenceBasis.z;
					}

					let planeNormal = Vector.Cross(Vector.Cross(axis, Camera.basis.z), axis);

					let intersectTime = GMath.RayPlaneIntersect(mouseOrigin, mouseRay, referencePosition, planeNormal);
					if (intersectTime > 0) {
						let planePosition = mouseOrigin + mouseRay * intersectTime - referencePosition;
						let distanceDragged = Vector.Dot(planePosition, axis);
						position = referencePosition + axis * distanceDragged - offset;
					} else {
						position = referencePosition;
					}
				} else {
					Vector planeNormal = ?;
					switch (axisIndex) {
						case 3: planeNormal = referenceBasis.z;
						case 5: planeNormal = referenceBasis.y;
						case 6: planeNormal = referenceBasis.x;
						case 7: planeNormal = Camera.basis.z; 
					}

					let intersectTime = GMath.RayPlaneIntersect(mouseOrigin, mouseRay, referencePosition, planeNormal);
					if (intersectTime > 0) {
						position = mouseOrigin + mouseRay * intersectTime - offset;
					} else {
						position = referencePosition;
					}
				}

				WhileDragged();

				return true;
			} else {
				axisIndex = 0;
				float closest = float.PositiveInfinity;

				Vector* basisAxis = &basis.x;
				for (uint8 axis < 3) {
					let planeNormal = basisAxis[axis % 3];
					
					let viewDirection = Camera.orthographic ? Camera.basis.z : (Camera.position - Translator.position).Normalized();
					if (Vector.Dot(viewDirection, planeNormal) < 0.2f) {
						continue;
					}

					let intersectTime = GMath.RayPlaneIntersect(mouseOrigin, mouseRay, position, planeNormal);
					if (intersectTime > closest) {
						continue;
					}

					int8 hoveredAxisIndex = 0;

					let firstAxisIndex = (axis + 1) % 3;
					let secondAxisIndex = (axis + 2) % 3;
					let firstPlaneAxis = basisAxis[firstAxisIndex];
					let secondPlaneAxis = basisAxis[secondAxisIndex];

					let planePosition = mouseOrigin + mouseRay * intersectTime - position;
					let firstCoordinate = Vector.Dot(planePosition, firstPlaneAxis) / scale;
					let secondCoordinate = Vector.Dot(planePosition, secondPlaneAxis) / scale;

					if (firstCoordinate > -0.01f && secondCoordinate > -0.01f) {
						if (firstCoordinate < 0.125f / 6 && secondCoordinate < 0.125f / 6) {
							hoveredAxisIndex = 7;
						} else if (firstCoordinate < 0.125f / 3 && secondCoordinate < 0.125f / 3) {
							hoveredAxisIndex = 1 << (firstAxisIndex) | 1 << (secondAxisIndex);
						} else if (firstCoordinate < 0.125f && secondCoordinate < 0.01f) {
							hoveredAxisIndex = 1 << (firstAxisIndex);
						} else if (secondCoordinate < 0.125f && firstCoordinate < 0.01f) {
							hoveredAxisIndex = 1 << (secondAxisIndex);
						}
					}

					if (hoveredAxisIndex > 0) {
						closest = intersectTime;
						axisIndex = hoveredAxisIndex;
					}
				}

				return axisIndex > 0;
			}
		}

		public static void MouseRelease() {
			if (dragged) {
				dragged = false;
				EndDragged();
			}
		}

		public static void BeginDragged(Vector mousePosition) {
			referencePosition = position;
			referenceBasis = basis;
			
			let mouseOrigin = Camera.ScreenPointToOrigin(mousePosition);
			let mouseRay = Camera.ScreenPointToRay(mousePosition);

			if (axisIndex == 1 || axisIndex == 2 || axisIndex == 4) {
				Vector axis = ?;
				switch (axisIndex) {
					case 1: axis = referenceBasis.x;
					case 2: axis = referenceBasis.y;
					case 4: axis = referenceBasis.z;
				}

				let planeNormal = Vector.Cross(Vector.Cross(axis, Camera.basis.z), axis);

				let intersectTime = GMath.RayPlaneIntersect(mouseOrigin, mouseRay, referencePosition, planeNormal);

				let planePosition = mouseOrigin + mouseRay * intersectTime - referencePosition;
				let distanceDragged = Vector.Dot(planePosition, axis);
				offset = axis * distanceDragged;
			} else {
				Vector planeNormal = ?;
				switch (axisIndex) {
					case 3: planeNormal = referenceBasis.z;
					case 5: planeNormal = referenceBasis.y;
					case 6: planeNormal = referenceBasis.x;
					case 7: planeNormal = Camera.basis.z; 
				}

				let intersectTime = GMath.RayPlaneIntersect(mouseOrigin, mouseRay, referencePosition, planeNormal);

				offset = mouseOrigin + mouseRay * intersectTime - referencePosition;
			}

			OnDragBegin();
		}

		public static void WhileDragged() {
			OnDragged(Translator.position);
		}

		public static void EndDragged() {
			OnDragEnd();
		}
	}
}
