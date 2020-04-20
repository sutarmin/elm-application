import { Elm } from "./Main";
import { presenterScenario } from "./test";

const app = Elm.Main.init({
  node: document.querySelector("main"),
  flags: "https://test-host",
});

app.ports.listen.subscribe(async (url) => {
  console.log(`Connected to ${url}`);
  await presenterScenario(app);
});

/*

// actual WebSocket implementation

app.ports.listen.subscribe((url) => {
  const socket = new WebSocket(url);

  socket.onmessage = (event: MessageEvent) =>
    app.ports.receive.send(event.data);
});

app.ports.send.subscribe(async (value) => {
  const parsed = JSON.parse(value);
  console.log(parsed);
});

*/
