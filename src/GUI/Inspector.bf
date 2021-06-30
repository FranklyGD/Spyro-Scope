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

		protected Panel area;
		int labelWidth = 150;

		public this(StringView label) : base() {
			this.label = label;

			GUIElement.PushParent(this);

			input = new Input();
			input.Anchor = .(0,1,0,0);
			input.Offset = .(labelWidth,0,0,WindowApp.bitmapFont.height);
			input.Enabled = false;
			input.preText = "0x";

			area = new Panel();
			area.Anchor = .(0,1,0,0);
			area.Offset = .(WindowApp.bitmapFont.characterWidth, 0, WindowApp.bitmapFont.height, WindowApp.bitmapFont.height);
			area.texture = GUIElement.bgOutlineTexture;
			area.tint = .(128,128,128);

			GUIElement.PopParent();
		}

		public override void Draw() {
			base.Draw();

			WindowApp.bitmapFont.Print(label, .(drawn.left, drawn.top + 3), .(255,255,255));
		}

		public Property<T> AddProperty<T>(StringView label, int offset, StringView components) where T : struct {
			GUIElement.PushParent(area);

			let property = new Property<T>(this, label, offset, components);

			property.Anchor = .(0,1,0,0);
			if (components.Length > 1) {
				property.Offset = .(0, -2, 0, WindowApp.bitmapFont.height * 2);
				property.Offset.Shift(0, nextPropertyPos);
				nextPropertyPos += WindowApp.bitmapFont.height * 2;
			} else {
				property.Offset = .(0, -2, 0, WindowApp.bitmapFont.height);
				property.Offset.Shift(0, nextPropertyPos);
				nextPropertyPos += WindowApp.bitmapFont.height;
			}

			properties.Add(property);
			
			GUIElement.PopParent();

			area.Offset.bottom = nextPropertyPos + WindowApp.bitmapFont.height + 1;

			return property;
		}

		public PropertyBits AddProperty(StringView label, int offset, int startBit, int bitLength = 1) {
			GUIElement.PushParent(area);

			let property = new PropertyBits(this, label, offset, startBit, bitLength);

			property.Anchor = .(0,1,0,0);

			property.Offset = .(0, -2, 0, WindowApp.bitmapFont.height);
			property.Offset.Shift(0, nextPropertyPos);
			nextPropertyPos += WindowApp.bitmapFont.height;

			properties.Add(property);
			
			GUIElement.PopParent();

			area.Offset.bottom = area.Offset.top + nextPropertyPos + 1;

			return property;
		}

		public Property<T> AddProperty<T>(StringView label, int offset) where T : struct {
			return AddProperty<T>(label, offset, .());
		}

		public void SetData(Emulator.Address address, void* reference) {
			dataAddress = address;
			dataReference = reference;

			input.SetValidText(scope String() .. AppendF("{}", address));
			if (reference != null) {
				OnDataSet(address, reference);
			}
		}

		/// Executed when the inspector is set to look at new address for data
		public virtual void OnDataSet(Emulator.Address address, void* reference) {}
		/// Executed when a property in the inspector modified data in the emulator
		public virtual void OnDataModified(Emulator.Address address, void* reference) {}

		public class Property : GUIElement {
			public readonly Inspector inspector;
			protected StringView label;
			protected int dataOffset;

			public virtual bool ReadOnly { get => false; set {} }

			protected this(Inspector inspector, StringView label, int offset) {
				this.inspector = inspector;
				this.label = label;
				dataOffset = offset;
			}

			protected static bool ValidateNumber(String text) {
				return Float.Parse(text) case .Ok;
			}

			protected static void XcrementNumber(String text, int delta) {
				if (Float.Parse(text) case .Ok(let val)) {
					text .. Clear().AppendF("{}", (int)val + delta);
				}
			}
		}

		public class Property<T> : Property where T : struct {
			StringView components;
			readonly Renderer.Color[3] componentColors = .(.(255,192,192), .(192,255,192), .(192,192,255));
			Input[] inputs ~ delete _;

			public override bool ReadOnly {
				get => !inputs[0].Enabled;
				set { for (let input in inputs) input.Enabled = !value; }
			}

			public StringView preTextInput {
				get => inputs[0].preText;
				set { for (let input in inputs) input.preText = value; }
			}

			public StringView postTextInput {
				get => inputs[0].postText;
				set { for (let input in inputs) input.postText = value; }
			}

			public this(Inspector inspector, StringView label, int offset, StringView components) : base(inspector, label, offset) {
				this.components = components;

				GUIElement.PushParent(this);

				if (components.Length > 1) {
					let area = new GUIElement();

					GUIElement.PushParent(area);

					area.Anchor = .(0,1,0.5f,1);
					area.Offset = .(WindowApp.bitmapFont.characterWidth,0,0,0);

					inputs = new Input[components.Length];
					for (let i < components.Length) {
						let input = new Input();
						inputs[i] = input;
		
						input.Anchor = .((float)i / components.Length, (float)(i + 1) / components.Length,0,1);
						input.Offset = .(WindowApp.bitmapFont.characterWidth + 2,0,0,0);
		
						input.OnValidate = new => ValidateNumber;
						input.OnXcrement = new => XcrementNumber;
						input.OnSubmit.Add(new (text) => {
							if (Float.Parse(text) case .Ok(var val)) {
								var castedVal = (int)val;
								ModifyData((.)&castedVal, i);
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
	
					input.Anchor = .(0,1,0,1);
					input.Offset = .(inspector.labelWidth,0,1,-1);
	
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
					Emulator.active.ReadFromRAM(inspector.dataAddress + dataOffset + i * sizeof(T), &value, sizeof(T));
					inputs[i].SetValidText(scope String() .. AppendF("{}", value));
				}
			}

			public override void Draw() {
				base.Draw();

				WindowApp.bitmapFont.Print(label, .(drawn.left, drawn.top + 3), .(255,255,255));
				
				for (let i < components.Length) {
					WindowApp.bitmapFont.Print(.(components, i, 1), .(Math.Round(Math.Lerp(drawn.left+WindowApp.bitmapFont.characterWidth, drawn.right, (float)i / components.Length)), WindowApp.bitmapFont.height + drawn.top + 3), .(255,255,255));
				}
			}

			void ModifyData(T* val, int index = 0) {
				// Write to emulator
				Emulator.active.WriteToRAM(inspector.dataAddress + dataOffset + index * sizeof(T), val, sizeof(T));

				// Write to cached data
				int8* dataReference = (.)inspector.dataReference;
				*(T*)(dataReference + dataOffset + index * sizeof(T)) = *val;

				inspector.OnDataModified(inspector.dataAddress, inspector.dataReference);
			}
		}

		public class PropertyBits : Property {
			GUIElement input;
			int start, length;

			public this(Inspector inspector, StringView label, int offset, int startBit, int bitLength) : base(inspector, label, offset) {
				start = startBit;
				length = bitLength;

				GUIElement.PushParent(this);

				if (bitLength == 1) {
					Toggle toggle = new .();
					input = toggle;
					
					toggle.Anchor = .(0,0,0.5f,0.5f);
					toggle.Offset = .(inspector.labelWidth,inspector.labelWidth + 16,-8,8);

					toggle.OnToggled.Add(new (tvalue) => {
						ModifyData((.)tvalue);
					});
				} else {
					Input tinput = new .();
					input = tinput;

					tinput.Anchor = .(0,1,0,1);
					tinput.Offset = .(inspector.labelWidth,0,1,-1);

					tinput.OnValidate = new => ValidateNumber;
					tinput.OnXcrement = new => XcrementNumber;
					tinput.OnSubmit.Add(new (text) => {
						if (Float.Parse(text) case .Ok(var val)) {
							var castedVal = (int)val;
							
							ModifyData((.)castedVal);
						}
					});
				}

				GUIElement.PopParent();
			}

			protected override void Update() {
				if (inspector.dataAddress.IsNull) {
					return;
				}

				uint32 value = ?;
				if (length == 1) {
					Emulator.active.ReadFromRAM(inspector.dataAddress + dataOffset, &value, 1);
					((Toggle)input).value = BitEdit.Get!(value, 1 << start) > 0;
				} else {
					Emulator.active.ReadFromRAM(inspector.dataAddress + dataOffset, &value, 4);
					int mask = -1;
					mask = mask ^ (mask << length);
					((Input)input).SetValidText(scope String() .. AppendF("{}", BitEdit.Get!(value >> start, mask)));
				}
			}

			public override void Draw() {
				base.Draw();

				WindowApp.bitmapFont.Print(label, .(drawn.left, drawn.top + 3), .(255,255,255));
			}

			void ModifyData(int val) {
				// Get from cached data
				let dataReference = (int*)((int8*)inspector.dataReference + dataOffset);
				int value = *dataReference;

				// Change only the relevant bits
				int32 mask = (-1 ^ (-1 << length)) << start;
				BitEdit.Set!(value, val << start, mask);

				// Write to emulator
				Emulator.active.WriteToRAM(inspector.dataAddress + dataOffset, &value, 4);

				// Write to cached data
				*dataReference = value;

				inspector.OnDataModified(inspector.dataAddress, inspector.dataReference);
			}
		}
	}
}
