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

export async function presenterScenario(app: Elm.Main.App) {
  const sendAfter = sendAfter_(app);
  const roleMessage = { type: "role", role: "presenter" };
  await sendAfter(500, roleMessage);

  const prefMessage = { type: "preferences", technologies: ["VNC", "WebRTC"] };
  await sendAfter(1000, prefMessage);

  await receiveOutcomingMessage(app);
  const badSST = { type: "start", answer: "error" };
  await sendAfter(500, badSST);

  await receiveOutcomingMessage(app);
  const goodSST = { type: "start", answer: "acknowledge", isMobile: false };
  await sendAfter(500, goodSST);

  const config = { type: "config", entities };
  await sendAfter(1000, config);
}

export async function particioantScenario(app: Elm.Main.App) {
  const sendAfter = sendAfter_(app);

  const roleMessage = { type: "role", role: "participant" };
  sendAfter(500, roleMessage);
}
