using System;
using System.Collections;

namespace SpyroScope {
	class DropdownList : Button {
		int value;
		public int Value {
			get => value;
			set {
				SetItem(value);
			    this.value = value;
			}
		}
		GUIElement dropdown;
		public Event<delegate void(int)> OnItemSelect ~ _.Dispose();

		public this() : base() {
			dropdown = new .();
			dropdown.visible = false;

			OnActuated.Add(new => ToggleDropdown);
		}

		protected override void Unselected() {
			base.Unselected();

			dropdown.visible = false;
		}

		public void AddItem(String label) {
			let index = dropdown.children.Count;
			GUIElement.PushParent(dropdown);

			Button option = new .();
			option.Anchor = .(0,1,0,0);
			option.Offset = .(0,0,index * Offset.Height,(index + 1) * Offset.Height);
			option.text = label;
			option.OnActuated.Add(new () => { SelectItem(index); });
			
			GUIElement.PopParent();
		}

		void ToggleDropdown() {
			dropdown.visible = !dropdown.visible;
			if (dropdown.visible) {
				dropdown.Parent(null);
				dropdown.Offset = .(drawn.left, drawn.right, drawn.bottom, drawn.bottom + dropdown.children.Count * Offset.Height);
			}
		}

		public void SelectItem(int index) {
			SetItem(index);
			OnItemSelect(index);
			dropdown.visible = false;
		}

		void SetItem(int index) {
			text = ((Button)dropdown.children[index]).text;
		}
	}
}
