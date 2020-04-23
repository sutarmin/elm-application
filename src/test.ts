import { Elm } from "./Main";

const wait = (ms: number) => new Promise((res) => setTimeout(res, ms));

const sendAfter_ = (app: Elm.Main.App) => async (ms: number, value: object) => {
  await wait(ms);
  app.ports.receive.send(JSON.stringify(value));
};

const receiveOutcomingMessage = async (app: Elm.Main.App) =>
  new Promise((res) => {
    app.ports.send.subscribe(async (value) => {
      const parsed = JSON.parse(value);
      res(parsed);
    });
  });

const entities = [
  { id: "window1", title: "Window 1", type: "window" },
  { id: "window2", title: "Window 2", type: "window" },
  { id: "window3", title: "Window 3", type: "window" },
  { id: "screen1", title: "Screen 1", type: "screen" },
  { id: "screen2", title: "Screen 2", type: "screen" },
  { id: "screen3", title: "Screen 3", type: "screen" },
];

const webRtcEntities = entities.filter((entity) => entity.type === "screen");

export async function presenterScenarioVNC(app: Elm.Main.App) {
  const sendAfter = sendAfter_(app);
  const roleMessage = { type: "role", role: "presenter" };
  await sendAfter(500, roleMessage);

  const prefMessage = { type: "preferences", technologies: ["WebRTC", "VNC"] };
  await sendAfter(1000, prefMessage);

  await receiveOutcomingMessage(app);
  const badSST = { type: "start", answer: "error", technology: "WebRTC" };
  await sendAfter(500, badSST);

  await receiveOutcomingMessage(app);
  const goodSST = {
    type: "start",
    answer: "acknowledge",
    technology: "VNC",
    isMobile: false,
  };
  await sendAfter(500, goodSST);

  const config = { type: "config", entities };
  await sendAfter(1000, config);
}

export async function presenterScenarioWebRTC(app: Elm.Main.App) {
  const sendAfter = sendAfter_(app);
  const roleMessage = { type: "role", role: "presenter" };
  await sendAfter(500, roleMessage);

  const prefMessage = { type: "preferences", technologies: ["WebRTC", "VNC"] };
  await sendAfter(1000, prefMessage);

  await receiveOutcomingMessage(app);
  const goodSST = {
    type: "start",
    answer: "acknowledge",
    technology: "WebRTC",
  };
  await sendAfter(500, goodSST);

  const config = { type: "config", entities: webRtcEntities };
  await sendAfter(1000, config);
}

export async function presenterScenarioVNCMobile(app: Elm.Main.App) {
  const sendAfter = sendAfter_(app);
  const roleMessage = { type: "role", role: "presenter" };
  await sendAfter(500, roleMessage);

  const prefMessage = { type: "preferences", technologies: ["VNC", "WebRTC"] };
  await sendAfter(1000, prefMessage);

  await receiveOutcomingMessage(app);
  const badSST = { type: "start", answer: "error", technology: "WebRTC" };
  await sendAfter(500, badSST);

  await receiveOutcomingMessage(app);
  const goodSST = {
    type: "start",
    answer: "acknowledge",
    technology: "VNC",
    isMobile: true,
  };
  await sendAfter(500, goodSST);
}

export async function particioantScenario(app: Elm.Main.App) {
  const sendAfter = sendAfter_(app);

  const roleMessage = { type: "role", role: "participant" };
  sendAfter(500, roleMessage);
}
