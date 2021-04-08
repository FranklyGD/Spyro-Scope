using System;
using System.Collections;

namespace SpyroScope {
	class MessageFeed : GUIElement {
		List<(String message, DateTime time)> messageFeed = new .();

		public ~this() {
			for (let feedItem in messageFeed) {
				if (feedItem.message.IsDynAlloc) {
					delete feedItem.message;
				}
			}
			delete messageFeed;
		}

		public override void Draw() {
			base.Draw();

			let now = DateTime.Now;

			messageFeed.RemoveAll(scope (x) => {
				let pendingRemove = now > x.time;
				if (pendingRemove && x.message.IsDynAlloc) {
					delete x.message;
				}
				return now > x.time;
			});

			for (let i < messageFeed.Count) {
				let feedItem = messageFeed[i];
				let message = feedItem.message;
				let age = feedItem.time - now;
				let fade = Math.Min(age.TotalSeconds, 1);
				let offsetOrigin = drawn.start + Vector2(0,(messageFeed.Count - i - 1) * WindowApp.font.height);
				DrawUtilities.Rect(offsetOrigin.y, offsetOrigin.y + WindowApp.font.height, offsetOrigin.x, offsetOrigin.x + WindowApp.font.CalculateWidth(message) + 4,
					.(0,0,0,(.)(192 * fade)));
				WindowApp.font.Print(message, offsetOrigin + .(2,0), .(255,255,255,(.)(255 * fade)));
			}
		}

		public void PushMessage(String message) {
			messageFeed.Add((message, .Now + TimeSpan(0, 0, 2)));
		}
	}
}
