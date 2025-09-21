// رابط السيرفر على Render
const SERVER_URL = "https://two0000-lxps.onrender.com";
const socket = io(SERVER_URL);

// عناصر HTML
const createBtn = document.getElementById("createBtn");
const linkDiv = document.getElementById("linkDiv");
const localVideo = document.getElementById("localVideo");
const remoteVideo = document.getElementById("remoteVideo");
const endCallBtn = document.getElementById("endCall");

let localStream;
let pc;
let roomId, token, selfId;

const ICE_CONFIG = { iceServers: [{ urls: "stun:stun.l.google.com:19302" }] };

// ---------------------- إنشاء الغرفة ----------------------
if (createBtn) {
  createBtn.onclick = async () => {
    const res = await fetch(SERVER_URL + "/create-room");
    const data = await res.json();
    roomId = data.roomId;
    token = data.token;
    linkDiv.innerHTML = `<a href="${data.link}" target="_blank">${data.link}</a>`;
    alert("انسخ الرابط وشاركه مع صديقك!");
  };
}

// ---------------------- بدء الكاميرا ----------------------
async function startLocal() {
  localStream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });
  localVideo.srcObject = localStream;
}

// ---------------------- الانضمام للغرفة ----------------------
async function joinRoom(roomIdParam, tokenParam) {
  await startLocal();
  roomId = roomIdParam;
  token = tokenParam;
  socket.emit("join-room", { roomId, token });
}

// ---------------------- إنشاء PeerConnection ----------------------
function createPC(remoteId) {
  pc = new RTCPeerConnection(ICE_CONFIG);

  localStream.getTracks().forEach(track => pc.addTrack(track, localStream));

  pc.ontrack = e => {
    if (remoteVideo) remoteVideo.srcObject = e.streams[0];
  };

  pc.onicecandidate = ev => {
    if (ev.candidate) socket.emit("candidate", { to: remoteId, candidate: ev.candidate });
  };

  return pc;
}

// ---------------------- استقبال إشارات من السيرفر ----------------------
socket.on("joined", async ({ selfId: id, others }) => {
  selfId = id;
  for (let otherId of others) {
    const pc = createPC(otherId);
    const offer = await pc.createOffer();
    await pc.setLocalDescription(offer);
    socket.emit("offer", { to: otherId, sdp: offer });
  }
});

socket.on("user-joined", async otherId => {
  createPC(otherId);
});

socket.on("offer", async ({ from, sdp }) => {
  const pc = createPC(from);
  await pc.setRemoteDescription(sdp);
  const answer = await pc.createAnswer();
  await pc.setLocalDescription(answer);
  socket.emit("answer", { to: from, sdp: answer });
});

socket.on("answer", async ({ from, sdp }) => {
  if (pc) await pc.setRemoteDescription(sdp);
});

socket.on("candidate", ({ from, candidate }) => {
  if (pc) pc.addIceCandidate(candidate).catch(console.error);
});

socket.on("room-error", msg => alert(msg));

socket.on("user-left", () => {
  if (remoteVideo) remoteVideo.srcObject = null;
  if (pc) pc.close();
});

// ---------------------- إنهاء المكالمة ----------------------
if (endCallBtn) {
  endCallBtn.onclick = () => {
    if (localStream) {
      localStream.getTracks().forEach(track => track.stop());
    }
    if (pc) pc.close();
    socket.emit("leave-room", { roomId, selfId });
    alert("تم إنهاء المكالمة");
    window.location.href = "/"; // يرجع للصفحة الرئيسية
  };
}

// ---------------------- إذا كان الرابط فيه room و token ----------------------
const params = new URLSearchParams(window.location.search);
if (params.has("t") && window.location.pathname.includes("/room/")) {
  const rid = window.location.pathname.split("/room/")[1];
  const tok = params.get("t");
  joinRoom(rid, tok);
}
