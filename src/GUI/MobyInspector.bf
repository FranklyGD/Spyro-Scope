namespace SpyroScope {
	class MobyInspector : Inspector {
		Inspector.Property<uint8> nextModelProperty;
		Inspector.Property<uint8> keyframeProperty;
		Inspector.Property<uint8> nextKeyframeProperty;

		public this() : base("Object") {
			Anchor = .(0,1,0,1);
			Offset = .(4,-4,24,-4);

			AddProperty<int8>("State", 0x48).ReadOnly = true;

			AddProperty<int32>("Position", 0xc, "XYZ");
			AddProperty<int8>("Rotation", 0x44, "XYZ");

			AddProperty<uint8>("Type #ID", 0x36).ReadOnly = true;
			AddProperty<Emulator.Address>("Data", 0x0).ReadOnly = true;
			AddProperty<int8>("Held Value", 0x50);

			AddProperty<uint8>("Model/Anim", 0x3c);
			nextModelProperty = AddProperty<uint8>("Nxt Mdl/Anim", 0x3d);
			keyframeProperty = AddProperty<uint8>("Keyframe", 0x3e);
			nextKeyframeProperty = AddProperty<uint8>("Nxt Keyframe", 0x3f);

			AddProperty<uint8>("Color", 0x54, "RGBA");
			AddProperty<uint8>("LOD Distance", 0x4e).postTextInput = " x 1000";
		}

		public override void OnDataSet(Emulator.Address address, void* reference) {
			let mobyReference = (Moby*)reference;

			Emulator.Address modelSetAddress = ?;
			Emulator.active.mobyModelArrayPointer.GetAtIndex(&modelSetAddress, mobyReference.objectTypeID);

			let possiblyAnimated = mobyReference.HasModel && (int32)modelSetAddress < 0;
			nextModelProperty.ReadOnly = !possiblyAnimated;
			keyframeProperty.ReadOnly = !possiblyAnimated;
			nextKeyframeProperty.ReadOnly = !possiblyAnimated;
		}
	}
}
