using System;
using System.Collections;

namespace SpyroScope {
	class Inspector : GUIElement {
		StringView label;
		Input input;
		Emulator.Address dataAddress;
		void* dataReference;

		List<GUIElement> properties = new .() ~ delete _;
		int nextPropertyPos = 2;

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
			area.Offset = .(WindowApp.bitmapFont.characterWidth, 0, WindowApp.bitmapFont.height + 1, WindowApp.bitmapFont.height + 2);
			area.texture = GUIElement.bgOutlineTexture;
			area.tint = .(128,128,128);

			GUIElement.PopParent();
		}

		public override void Draw() {
			base.Draw();

			WindowApp.bitmapFont.Print(label, .(drawn.left, drawn.top + 4), .(255,255,255));
		}

		public int AddProperty<T>(StringView label, int offset, StringView components) where T : struct, INumeric {
			int propertyIndex = properties.Count;

			GUIElement.PushParent(area);

			if (components.Length > 1) {
				let propertyLabel = new Property(this, label, offset);
				properties.Add(propertyLabel);
				
				propertyLabel.Anchor = .(0,1,0,0);

				propertyLabel.Offset = .(2, -2, 0, WindowApp.bitmapFont.height);
				propertyLabel.Offset.Shift(0, nextPropertyPos);
				nextPropertyPos += WindowApp.bitmapFont.height;
				
				let componentArea = new Panel();
				GUIElement.PushParent(componentArea);
				
				componentArea.Anchor = .(0,1,0,0);
				
				componentArea.Offset = .(WindowApp.bitmapFont.characterWidth + 1, -2, -2, WindowApp.bitmapFont.height + 2);
				componentArea.Offset.Shift(0, nextPropertyPos);

				componentArea.texture = GUIElement.bgOutlineTexture;
				componentArea.tint = .(128,128,128);

				for (let i < components.Length) {
					let property = new Property<T>(this, .(components, i, 1), WindowApp.bitmapFont.characterWidth, offset + sizeof(T) * i);

					property.Anchor = .((float)i / components.Length, (float)(i + 1) / components.Length,0,1);

					property.Offset = .(2, -2, 2, -2);

					if (i < 3) {
						const Renderer.Color[3] componentColors = .(.(255,192,192), .(192,255,192), .(192,192,255));
						property.Color = componentColors[i];
					}

					properties.Add(property);
				}
				GUIElement.PopParent();
				
				nextPropertyPos += WindowApp.bitmapFont.height + 2;
			} else {
				let property = new Property<T>(this, label, labelWidth, offset);

				property.Anchor = .(0,1,0,0);

				property.Offset = .(2, -2, 0, WindowApp.bitmapFont.height);
				property.Offset.Shift(0, nextPropertyPos);
				nextPropertyPos += WindowApp.bitmapFont.height + 1;

				if (typeof(T) == typeof(Emulator.Address)) {
					property.InputPretext = "0x";
				}
				
				properties.Add(property);
			}
			
			GUIElement.PopParent();

			area.Offset.bottom = nextPropertyPos + WindowApp.bitmapFont.height + 3;

			return propertyIndex;
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

		public Property<T> AddProperty<T>(StringView label, int offset) where T : struct, INumeric {
			return (.)properties[AddProperty<T>(label, offset, .())];
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

			public this(Inspector inspector, StringView label, int offset) {
				this.inspector = inspector;
				this.label = label;
				dataOffset = offset;
			}

			public override void Draw() {
				base.Draw();

				WindowApp.bitmapFont.Print(label, .(drawn.left, drawn.top + 2), .(255,255,255));
			}
		}

		public class NumericProperty : Property {
			protected int start, count, mask;

			public int Value {
				get {
					// Get from cached data
					let dataReference = (int*)((int8*)inspector.dataReference + dataOffset);
					int referenceValue = *dataReference;

					return referenceValue >> start & mask;
				}

				set {
					// Get from cached data
					let dataReference = (int*)((int8*)inspector.dataReference + dataOffset);
					int referenceValue = *dataReference;

					// Change only the relevant bits
					int mask = this.mask << start;
					BitEdit.Set!(referenceValue, value << start, mask);

					// Write to emulator
					Emulator.active.WriteToRAM(inspector.dataAddress + dataOffset, &referenceValue, 4);

					// Write to cached data
					*dataReference = referenceValue;
					inspector.OnDataModified(inspector.dataAddress, inspector.dataReference);
				}
			}

			public this(Inspector inspector, StringView label, int offset, int startingBit, int bitCount) : base(inspector, label, offset) {
				start = startingBit;
				count = bitCount;
				mask = -1 ^ (-1 << bitCount);
			}

			protected bool ValidateNumber(String text) {
				if (Float.Parse(text) case .Ok(let val)) {
			        text .. Clear().AppendF("{}", BitEdit.Get!((int)val, mask));
					return true;
				}
				return false;
			}

			protected void XcrementNumber(String text, int delta) {
				if (Float.Parse(text) case .Ok(let val)) {
					text .. Clear().AppendF("{}", BitEdit.Get!((int)val + delta, mask));
				}
			}
		}

		public class Property<T> : NumericProperty where T : struct, INumeric {
			Input input;

			public override bool ReadOnly {
				get => !input.Enabled;
				set => input.Enabled = !value;
			}

			public Renderer.Color4 Color {
				get => input.normalColor;
				set => input.normalColor = value;
			}

			public StringView InputPretext {
				get => input.preText;
				set => input.preText = value;
			}

			public StringView postTextInput {
				get => input.postText;
				set => input.postText = value;
			}

			public this(Inspector inspector, StringView label, int labelWidth, int offset) : base(inspector, label, offset, 0, sizeof(T) * 8) {
				GUIElement.PushParent(this);

				input = new Input();

				input.Anchor = .(0,1,0,1);
				input.Offset = .(labelWidth,0,0,0);

				input.OnValidate = new => ValidateNumber;
				input.OnXcrement = new => XcrementNumber;
				input.OnSubmit.Add(new (text) => {
				    if (Float.Parse(text) case .Ok(var val)) {
						int castedVal = (.)val;
				        ModifyData((.)&castedVal);
				    }
				});

				GUIElement.PopParent();
			}

			protected override void Update() {
				if (inspector.dataAddress.IsNull) {
					return;
				}

				T value = ?;
				Emulator.active.ReadFromRAM(inspector.dataAddress + dataOffset, &value, sizeof(T));
				input.SetValidText(scope String() .. AppendF("{}", value));
			}

			void ModifyData(T* val) {
				// Write to emulator
				Emulator.active.WriteToRAM(inspector.dataAddress + dataOffset, val, sizeof(T));

				// Write to cached data
				T* dataReference = (.)((int8*)inspector.dataReference + dataOffset);
				*dataReference = *val;

				inspector.OnDataModified(inspector.dataAddress, inspector.dataReference);
			}
		}

		public class PropertyBits : NumericProperty {
			GUIInteractable interactable;

			public override bool ReadOnly {
				get => !interactable.Enabled;
				set => interactable.Enabled = !value;
			}

			public this(Inspector inspector, StringView label, int offset, int startBit, int bitLength) : base(inspector, label, offset, startBit, bitLength) {
				GUIElement.PushParent(this);

				if (bitLength == 1) {
					Toggle toggle = new .();
					interactable = toggle;
					
					toggle.Anchor = .(0,0,0.5f,0.5f);
					toggle.Offset = .(inspector.labelWidth,inspector.labelWidth + 16,-8,8);

					toggle.OnToggled.Add(new (tvalue) => {
						Value = (int)tvalue;
					});
				} else {
					Input input = new .();
					interactable = input;

					input.Anchor = .(0,1,0,1);
					input.Offset = .(inspector.labelWidth,0,1,-1);

					input.OnValidate = new => ValidateNumber;
					input.OnXcrement = new => XcrementNumber;
					input.OnSubmit.Add(new (text) => {
						if (Float.Parse(text) case .Ok(var val)) {
							Value = (int)val;
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
				if (count == 1) {
					Emulator.active.ReadFromRAM(inspector.dataAddress + dataOffset, &value, 1);
					((Toggle)interactable).value = BitEdit.Get!(value, 1 << start) > 0;
				} else {
					Emulator.active.ReadFromRAM(inspector.dataAddress + dataOffset, &value, 4);
					((Input)interactable).SetValidText(scope String() .. AppendF("{}", BitEdit.Get!(value >> start, mask)));
				}
			}
		}
	}
}
