using System;
using System.Collections;

namespace SpyroScope {
	class Inspector : GUIElement {
		StringView label;
		Input input;
		Emulator.Address dataAddress;
		void* dataReference;

		List<GUIElement> properties = new .() ~ delete _;
		int nextPropertyPos = 1;

		GUIElement area;
		int labelWidth = 150;

		public this(StringView label) : base() {
			this.label = label;

			GUIElement.PushParent(this);

			input = new Input();
			input.anchor = .(0,1,0,0);
			input.offset = .(labelWidth,0,0,WindowApp.bitmapFont.characterHeight);
			input.enabled = false;
			input.preText = "0x";

			area = new GUIElement();
			area.anchor = .(0,1,0,1);
			area.offset = .(WindowApp.bitmapFont.characterWidth, 0, WindowApp.bitmapFont.characterHeight, 0);

			GUIElement.PopParent();
		}

		public override void Draw(Rect parentRect) {
			base.Draw(parentRect);

			WindowApp.bitmapFont.Print(label, .(drawn.left, drawn.top + 3), .(255,255,255));
		}

		public Property<T> AddProperty<T>(StringView label, int offset, StringView components) where T : struct {
			GUIElement.PushParent(area);

			let property = new Property<T>(this, label, offset, components);

			property.anchor = .(0,1,0,0);
			if (components.Length > 1) {
				property.offset = .(0, 0, 0, WindowApp.bitmapFont.characterHeight * 2);
				property.offset.Shift(0, nextPropertyPos);
				nextPropertyPos += WindowApp.bitmapFont.characterHeight * 2;
			} else {
				property.offset = .(0, 0, 0, WindowApp.bitmapFont.characterHeight);
				property.offset.Shift(0, nextPropertyPos);
				nextPropertyPos += WindowApp.bitmapFont.characterHeight;
			}

			properties.Add(property);
			
			GUIElement.PopParent();

			return property;
		}

		public Property<T> AddProperty<T>(StringView label, int offset) where T : struct {
			return AddProperty<T>(label, offset, .());
		}

		public void SetData(Emulator.Address address, void* reference) {
			dataAddress = address;
			dataReference = reference;

			input.SetValidText(scope String() .. AppendF("{}", address));
		}

		public class Property<T> : GUIElement where T : struct {
			public readonly Inspector inspector;

			StringView label;
			StringView components;
			readonly Renderer.Color[3] componentColors = .(.(255,192,192), .(192,255,192), .(192,192,255));
			Input[] inputs ~ delete _;
			int dataOffset;

			public bool ReadOnly {
				get => !inputs[0].enabled;
				set { for (let input in inputs) input.enabled = !value; }
			}

			public StringView preTextInput {
				get => inputs[0].preText;
				set { for (let input in inputs) input.preText = value; }
			}

			public StringView postTextInput {
				get => inputs[0].postText;
				set { for (let input in inputs) input.postText = value; }
			}

			public this(Inspector inspector, StringView label, int offset, StringView components) : base() {
				this.inspector = inspector;
				this.label = label;
				this.components = components;
				dataOffset = offset;

				GUIElement.PushParent(this);

				if (components.Length > 1) {
					let area = new GUIElement();

					GUIElement.PushParent(area);

					area.anchor = .(0,1,0.5f,1);
					area.offset = .(WindowApp.bitmapFont.characterWidth,0,0,0);

					inputs = new Input[components.Length];
					for (let i < components.Length) {
						let input = new Input();
						inputs[i] = input;
		
						input.anchor = .((float)i / components.Length, (float)(i + 1) / components.Length,0,1);
						input.offset = .(WindowApp.bitmapFont.characterWidth + 2,-2,0,0);
		
						input.OnValidate = new => ValidateNumber;
						input.OnXcrement = new => XcrementNumber;
						input.OnSubmit.Add(new (text) => {
							if (Float.Parse(text) case .Ok(var val)) {
								var castedVal = (int)val;
								ModifyData((.)&castedVal);
							}
						});

						if (i < 3) {
							input.normalColor = componentColors[i];
						}
					}
					
					GUIElement.PopParent();
				} else {
					inputs = new Input[1];
					let input = new Input();
					inputs[0] = input;
	
					input.anchor = .(0,1,0,1);
					input.offset = .(inspector.labelWidth,0,1,-1);
	
					input.OnValidate = new => ValidateNumber;
					input.OnXcrement = new => XcrementNumber;
					input.OnSubmit.Add(new (text) => {
						if (Float.Parse(text) case .Ok(var val)) {
							var castedVal = (int)val;
							ModifyData((.)&castedVal);
						}
					});

					if (typeof(T) == typeof(Emulator.Address)) {
						input.preText = "0x";
					}
				}

				GUIElement.PopParent();
			}

			protected override void Update() {
				if (inspector.dataAddress.IsNull) {
					return;
				}

				for (let i < inputs.Count) {
					T value = ?;
					Emulator.ReadFromRAM(inspector.dataAddress + dataOffset + i * sizeof(T), &value, sizeof(T));
					inputs[i].SetValidText(scope String() .. AppendF("{}", value));
				}
			}

			public override void Draw(Rect parentRect) {
				base.Draw(parentRect);

				WindowApp.bitmapFont.Print(label, .(drawn.left, drawn.top + 3), .(255,255,255));
				
				for (let i < components.Length) {
					WindowApp.bitmapFont.Print(.(components, i, 1), .(Math.Round(Math.Lerp(drawn.left+WindowApp.bitmapFont.characterWidth, drawn.right, (float)i / components.Length)), WindowApp.bitmapFont.characterHeight + drawn.top + 3), .(255,255,255));
				}
			}

			static bool ValidateNumber(String text) {
				return Float.Parse(text) case .Ok;
			}

			public static void XcrementNumber(String text, int delta) {
				if (Float.Parse(text) case .Ok(let val)) {
					text .. Clear().AppendF("{}", (int)val + delta);
				}
			}

			void ModifyData(T* val) {
				// Write to emulator
				Emulator.WriteToRAM(inspector.dataAddress + dataOffset, val, sizeof(T));

				// Write to cached data
				int8* data = (.)inspector.dataReference;
				*(T*)(data + dataOffset) = *val;
			}
		}
	}
}
