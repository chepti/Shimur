// Service Worker להתראות Push ב־Web – Firebase Cloud Messaging
// קובץ זה חייב להיות בשורש ה־web (build/web) כדי ש־FCM יוכל לטעון אותו
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyD8Ts4gXr_KJ7cJnZ54mVb3HWsixeyhaIA",
  appId: "1:473831757405:web:996242dfb7903db7e29fb4",
  messagingSenderId: "473831757405",
  projectId: "shimur",
  authDomain: "shimur.firebaseapp.com",
  storageBucket: "shimur.firebasestorage.app",
  measurementId: "G-KGC9NVP62N",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("[firebase-messaging-sw.js] התראה ברקע:", payload);
  const notificationTitle = payload.notification?.title || "שימור המורים";
  const notificationOptions = {
    body: payload.notification?.body || "",
    icon: "/icons/Icon-192.png",
    badge: "/icons/Icon-192.png",
    tag: payload.data?.tag || "shimur-notification",
    data: payload.data || {},
    requireInteraction: false,
  };
  return self.registration.showNotification(notificationTitle, notificationOptions);
});
