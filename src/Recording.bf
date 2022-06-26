using System;
using System.Collections;

namespace SpyroScope {
	static class Recording {
		static public bool Active { get; private set; }
		static public bool Playing { get; private set; }

		static DateTime lastTime;
		static public int CurrentFrame { get; private set; }
		
		public struct SpyroFrame {
			public Vector3Int position;
			public Vector3Int eulerRotation;
			public MatrixInt basis;
			public uint32 state;
			public AnimationState headAnimState;
			public AnimationState bodyAnimState;
			public Vector3Int targetVelocity;
			public Vector3Int velocity;
			public uint32 input;
		}

		static List<SpyroFrame> record = new .() ~ delete _;
		static public int FrameCount { get => record.Count; }
		static public SpyroFrame GetFrame(int frameIndex) => record[frameIndex];

		static public float HighestSpeed { get; private set; }

		static float TotalTime { get => (FrameCount - 1) * (1f / 30); }

		public static delegate void() RecordStep = new => AddRecordFrame ~ delete _;
		public static delegate void() ReplayStep = new => PlayFrames ~ delete _;

		public static void Record() {
			if (!Active) {
				AddRecordFrame();
				Active = true;
				Emulator.active.AddStepListener(RecordStep);
			}

			if (Playing) {
				StopReplay();
			}
		}

		public static void AddRecordFrame() {
			SpyroFrame newFrame = .{
				position = Emulator.active.SpyroPosition,
				eulerRotation = Emulator.active.SpyroEulerRotation,
				basis = Emulator.active.SpyroBasis,
				state = Emulator.active.SpyroState,
				headAnimState = Emulator.active.SpyroHeadAnimState,
				bodyAnimState = Emulator.active.SpyroBodyAnimState,
				targetVelocity = Emulator.active.SpyroIntendedVelocity,
				velocity = Emulator.active.SpyroPhysicsVelocity,
				input = Emulator.active.Input,
			};

			CurrentFrame = record.Count;
			record.Add(newFrame);

			let speed = Emulator.active.SpyroIntendedVelocity.Length();
			if (speed> HighestSpeed) {
				HighestSpeed = speed;
			}
		}

		public static void StopRecord() {
			Active = false;
			Emulator.active.RemoveStepListener(RecordStep);
		}

		public static void ClearRecord() {
			record.Clear();
		}

		public static void TrimRecordBefore(int frameIndex) {
			record.RemoveRange(0, frameIndex);
			CurrentFrame = 0;
		}

		public static void TrimRecordAfter(int frameIndex) {
			if (record.Count == 0) {
				return;
			}

			record.RemoveRange(frameIndex + 1, FrameCount - 1 - frameIndex);
		}

		public static void Replay() {
			if (!Playing && FrameCount > 0) {
				lastTime = DateTime.Now;
				
				Emulator.active.RestoreSpyroUpdate();
				Emulator.active.KillSpyroStateChange();

				Playing = true;
				
				Emulator.active.AddStepListener(ReplayStep);
			}

			if (Active) {
				StopRecord();
			}
		}

		public static void ApplyFrame(int frameIndex) {
			let frame = record[frameIndex];
			let emulator = Emulator.active;

			emulator.SpyroPosition = frame.position;
			emulator.SpyroEulerRotation = frame.eulerRotation;
			emulator.SpyroBasis = frame.basis;
			emulator.SpyroState = frame.state;
			emulator.SpyroHeadAnimState = frame.headAnimState;
			emulator.SpyroBodyAnimState = frame.bodyAnimState;
			emulator.SpyroIntendedVelocity = frame.targetVelocity;
			emulator.SpyroPhysicsVelocity = frame.velocity;

			CurrentFrame = frameIndex;
		}

		static void PlayFrames() {
			CurrentFrame = (CurrentFrame + 1) % record.Count;
			ApplyFrame(CurrentFrame);
		}

		public static void PauseReplay() {
			Emulator.active.KillSpyroUpdate();

			if (Playing) {
				Emulator.active.RemoveStepListener(ReplayStep); 
			}

			Playing = false;
		}

		public static void StopReplay() {
			Emulator.active.RestoreSpyroUpdate();
			Emulator.active.RestoreSpyroStateChange();
			
			if (Playing) {
				Emulator.active.RemoveStepListener(ReplayStep); 
			}

			Playing = false;
		}
	}
}
