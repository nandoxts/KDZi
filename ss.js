// ==UserScript==
// @name         36
// @namespace    http://tampermonkey.net/
// @version      2025-01-07
// @description  try to take over the world!
// @author       You
// @match        https://agarz.com/es
// @match        https://agarz.com
// @icon         https://www.google.com/s2/favicons?sz=64&domain=agarz.com
// @grant        none
// ==/UserScript==

function limpiarFormGroups() {
  // Seleccionar todos los .form-group
  const formGroups = document.querySelectorAll(".form-group");

  formGroups.forEach((group) => {
    // Si el .form-group contiene el botón con id="playBtn"
    if (group.querySelector("#playBtn")) {
      // Asignar el id="btn-control-pro" a ese .form-group
      group.id = "btn-control-pro";

      // Seleccionar todos los hijos directos del .form-group
      const children = Array.from(group.children);

      // Crear un nuevo div contenedor para los botones
      const newDiv = document.createElement("div");
      newDiv.style.display = "flex";
      newDiv.style.gap = "6px";

      children.forEach((child) => {
        // Si el hijo no es un botón permitido, eliminarlo
        if (
          !(
            child.matches("#playBtn") ||
            child.matches("#spectateBtn") ||
            child.matches("#replayBtn") ||
            child.tagName === "BUTTON"
          )
        ) {
          child.remove();
        }
      });

      // Mover los botones específicos al nuevo div
      const spectateBtn = group.querySelector("#spectateBtn");
      const replayBtn = group.querySelector("#replayBtn");

      if (spectateBtn && replayBtn) {
        newDiv.appendChild(spectateBtn);
        newDiv.appendChild(replayBtn);
        group.appendChild(newDiv); // Añadir el nuevo div al .form-group
      }
    }
  });
}

// Llamar a la función cuando desees limpiar
limpiarFormGroups();

var a9 = document.getElementsByClassName("form-group");
for (var aa = 0; aa < a9.length; aa++) {
  var ab = a9[aa].querySelector("#nick");
  if (ab) {
    var ac = a9[aa].querySelector('a[role="button"]');
    ac && (ac.style.display = "none");
    var ad = document.getElementById("myTeam"),
      ae = document.getElementById("skinFavori");
    ad && ae && ae.parentNode.insertBefore(ad, ae);
    break;
  }
}
// Remplazar imgBanner con nuevo contenido
var af = document.getElementById("imgBanner");
if (af && af.tagName === "IMG") {
  af.src = "https://i.ibb.co/8gvk9HwY/image-3.png";
}

// Modificar contenido de botones con íconos y texto estilizado
document.getElementById("playBtn").innerHTML = " │ 𝐎𝐘𝐍𝐀 │";
document.getElementById("spectateBtn").innerHTML = "│ 𝐈̇𝐙𝐋𝐄 │";
document.getElementById("replayBtn").innerHTML = "│ 𝐓𝐄𝐊𝐑𝐀𝐑 │";

// Crear y agregar un nuevo elemento de estilo
var ag = document.createElement("style");
ag.innerHTML = `
#imgBanner {
    width: 350px;
    filter: brightness(1.6);
}
/* Modo Claro */
body {
    background-color: white;
    color: black;
    height: 100%;
    display: flex;
}

/* Estilo del contenedor principal */
#btn-control-pro {
    margin: 15px 0;
    display: flex;
    flex-direction: column;
    gap: 6px;
}

/* Estilo del contenedor de botones secundarios */
#btn-secondary-group {
    display: flex;
    gap: 6px;
}

/* Checkbox estilizado */
input[type="checkbox"] {
    appearance: none;
    -webkit-appearance: none;
    -moz-appearance: none;
    width: 13px;
    height: 13px;
    border: 1.5px solid #00d8ff; /* Celeste Neón */
    border-radius: 3px;
    background-color: white;
    cursor: pointer;
    transition: background-color 0.3s, border-color 0.3s, box-shadow 0.3s;
    position: relative;
    margin-right: 5px;
}

#yesno_settings {
    margin: 6px;
    text-transform: capitalize;
    font-size: 14px;
    font-weight: 400;
    text-align: center;
    display: flex;
    flex-wrap: wrap;
    flex-direction: row;
    justify-content: flex-start;
}
input[type="checkbox"]:checked {
    background-color: #00d8ff; /* Celeste Neón */
    border-color: #00d8ff;
    box-shadow: 0 0 3px #00d8ff;
}

/* Checkmark */
input[type="checkbox"]:checked::after {
    content: "";
    position: absolute;
    top: 1.5px;
    left: 3px;
    width: 3px;
    height: 6px;
    border: solid white;
    border-width: 0 1px 1px 0;
    transform: rotate(45deg);
}

/* Modo Oscuro */
@media (prefers-color-scheme: dark) {
    body {
        background-color: #1e1e1e00;
        color: white;
    }

    input[type="checkbox"] {
        border-color: #007aff; /* Azul Eléctrico */
        background-color: #1e1e1e;
    }

    input[type="checkbox"]:checked {
        background-color: #007aff; /* Azul Eléctrico */
        border-color: #007aff;
        box-shadow: 0 0 3px #007aff;
    }
}



#helloDialog a{
    color: rgb(255 255 255)!important;
    text-decoration: none!important;
}


    #imgBannerText {
        font-size: 60px;
        font-family: emoji;
        font-weight: bold;
    }


    #txtSkin {
        width: 50% !important;
    }

    #myTeam {
        width: 30% !important;
        float: left;
        margin: 0;
    }



#chat-help {
	display: none;
	background-color: #333;
	color: #fff;
	padding: 10px;
	border-radius: 5px;
	right: 0px;
	position: absolute;
	overflow: auto;
	right: -400px;
	top: -300px;
	border-radius: 5px;
	width: 400px;
	height: 300px;
	opacity: .9;
}

#chat-help p {
	font-weight: bold;
}

#chat-help table {
	width: 100%;
	border-collapse: collapse;
}

#chat-help colgroup col {
	width: 100px;
	/* Primer columna con ancho fijo */
}

#chat-help td {
	padding: 5px;
	border: 1px solid #444;
}

#chat-help kbd {
	background-color: #444;
	color: #fff;
	padding: 2px 4px;
	border-radius: 3px;
}

.chat-help-icon {
	position: absolute;
	right: 10px;
	top: 50%;
	transform: translateY(-50%);
	cursor: pointer;
	color: gray;
}
    #helloDialog > div:nth-child(10) > div:nth-child(1) {
        display: none;
    }

    /* ❌ Hide Elements */
    #instructions, #address, #settings > div:nth-child(2) {
        display: none;
    }

    /* 🌟 Buttons Styling */
    .btn-warning {
        background-color: #000000;
        border-color: #000000;
        border-radius: 15px;
    }

    .btn-warning.active,
    .btn-warning.focus,
    .btn-warning:active,
    .btn-warning:focus,
    .btn-warning:hover,
    .open > .dropdown-toggle.btn-warning {
        background-color: #00c718;
        border-color: #00c718;
    }

    .btn-primary {
        background-color: #000000;
        border-color: #000000;
    }

    .btn-primary.active,
    .btn-primary.focus,
    .btn-primary:active,
    .btn-primary:focus,
    .btn-primary:hover,
    .open > .dropdown-toggle.btn-primary {
        background-color: #ff0000;
        border-color: #ff0000;
    }

    .btn-play {
        border-radius: 15px;
    }
`;
document.head.appendChild(ag);

document.head.appendChild(ag);

if ($("#instructions").length) {
  $("#instructions").remove();
}
if ($("#helloDialog > div:nth-child(3)").length) {
  $("#helloDialog > div:nth-child(3)").remove();
}
if ($("#idTwitch").length) {
  $("#idTwitch").remove();
}
chatManager.CHAT_FONTSIZE = 15;
chatManager.CHAT_FONT = "15px 'Poppins', sans-serif";
chatManager.CHAT_FONT_BOLD = "bold 15px 'Poppins', sans-serif";
chatManager.BG_ALPHA = 0;
ColorManager.Current.Chat_BG = "#0000";
chatManager.CHAT_PADDING_X = 8;
chatManager.CHAT_PADDING_Y = 4;
ColorManager.Current.Chat_Default = "#eee";
ColorManager.Current.Chat_Text = "#fff";

function agregarCheckboxesConId(container, ids) {
  ids.forEach((id) => {
    const label = document.createElement("label");
    const input = document.createElement("input");
    input.type = "checkbox";
    input.id = id;
    label.appendChild(input);
    label.appendChild(document.createTextNode(" " + id));
    container.appendChild(label);

    // Salto de línea para que cada checkbox esté en una línea distinta
    container.appendChild(document.createElement("br"));
  });
}
const yesnoSettings = document.getElementById("yesno_settings");
agregarCheckboxesConId(yesnoSettings, [
  "mostrar-id",
  "mostrar-top-1",
  "mostrar-skor-sala",
]);
function extraerUID(skinName) {
  if (typeof skinName !== "string") {
    return "0";
  }
  const match = skinName.match(/^uid(\d+)_/);
  return match ? match[1] : "0";
}

Cell.prototype.drawOneCell_player_ctx = function () {
  if (options.get("transparentRender") === true) {
    ctx.globalAlpha = 0.6;
  } else {
    ctx.globalAlpha = 1;
  }

  // Si existen datos de “tailDbg” (para depuración), se dibujan pequeños círculos blancos.
  if (this.tailDbg.length > 0) {
    ctx.strokeStyle = "#FFFFFF";
    ctx.lineWidth = 1;
    for (let i = 0; i < this.tailDbg.length; i++) {
      ctx.fillStyle = "rgba(255,255,255)";
      ctx.beginPath();
      ctx.arc(this.tailDbg[i].x, this.tailDbg[i].y, 5, 0, 2 * Math.PI, false);
      ctx.stroke();
    }
  }

  // Si existen datos de “nodeDbg” (para depuración), se dibujan círculos con otro color (aquí se deja el color en el ejemplo original)
  if (this.nodeDbg.length > 0) {
    ctx.strokeStyle = "#FFFFFF"; // En el código ofuscado aparece otro valor; se puede ajustar
    ctx.lineWidth = 1;
    for (let i = 0; i < this.nodeDbg.length; i++) {
      ctx.beginPath();
      ctx.arc(this.nodeDbg[i].x, this.nodeDbg[i].y, 6, 0, 2 * Math.PI, false);
      ctx.stroke();
    }
  }
  ctx.fillStyle = this.color;
  this.drawSimple(ctx);
  ctx.fill();

  // Si corresponde dibujar una “skin” encima
  if (this.isDrawSkin()) {
    const skinName = this.skinName;
    const skinUrl = `//cdn.agarz.com/${skinName.endsWith(".png") ? skinName : skinName + ".png"}`;

    if (!skins[skinName]) {
      skins[skinName] = new Image();
      skins[skinName].src = skinUrl;
      skins[skinName].onload = () => (skinsLoaded[skinName] = true);
    }

    if (skinsLoaded[skinName]) {
      ctx.save();
      ctx.beginPath();
      ctx.arc(this.x_draw, this.y_draw, this.size_draw, 0, 2 * Math.PI);
      ctx.clip();
      ctx.drawImage(
        skins[skinName],
        this.x_draw - this.size_draw,
        this.y_draw - this.size_draw,
        this.size_draw * 2,
        this.size_draw * 2,
      );
      ctx.restore();

      const info = playerInfoList[this.pID];

      if (info?.uid === record_uid && record_uid !== 0) {
        ctx.drawImage(
          crownImage,
          this.x_draw - this.size_draw * 0.5,
          this.y_draw - this.size_draw * 2,
          this.size_draw,
          this.size_draw,
        );
      }
    }
  }

  ctx.globalAlpha = 1;

  // Solo se dibuja el UID si el checkbox "mostrar-id" está activo
  if (document.getElementById("mostrar-id").checked) {
    let uidText = extraerUID(this.skinName);
    if (uidText !== "0") {
      ctx.save();
      let uidFontSize = this.getNameSize() * 0.8;
      ctx.font = uidFontSize + "px Ubuntu";
      let uidWidth = ctx.measureText(uidText).width;
      let uidX = this.x_draw - uidWidth * 0.5;

      // Crea un efecto pulsante (glow) sutil
      let time = performance.now();
      let pulse = (Math.sin(time / 200) + 1) / 2; // Valor entre 0 y 1
      ctx.shadowColor = "#FF00FF";
      ctx.shadowBlur = 5 + pulse * 10;
      ctx.fillStyle = "#FF00FF";
      let uidY = this.y_draw - this.getNameSize() * 1.7;
      ctx.fillText(uidText, uidX, uidY);
      ctx.restore();
    }
  }

  // Se define el color del texto en función del jugador y datos del leaderboard
  let textColor;
  if (this.pID === playerId) {
    textColor = "#FFFFFF"; // Blanco para ti
  } else {
    let leaderboardEntry = getLeaderboardExt(this.pID);
    if (leaderboardEntry == null) {
      textColor = "#FFFFFF"; // Valor por defecto, blanco, si no hay datos
    } else {
      if (leaderboardEntry.sameTeam == 1) {
        textColor = "#FFFF00"; // Amarillo para el equipo
      } else if (leaderboardEntry.sameClan == 1) {
        textColor = "#00FF00"; // Verde para el clan
      } else {
        textColor = "#FFFFFF"; // Blanco por defecto si no se cumple nada
      }
    }
  }
  ctx.fillStyle = textColor;

  // Dibuja el nombre, si corresponde
  if (this.isDrawName()) {
    ctx.font = this.getNameSize() + "px Ubuntu";
    this.calcNameWidth(ctx);
    let textWidth = ctx.measureText(this.name).width;
    let nameX = this.x_draw - textWidth * 0.5;
    ctx.fillText(this.name, nameX, this.y_draw);
  }

  // Dibuja el clan, si corresponde
  if (this.isDrawClan()) {
    let clanName = this.getClanName();
    let clanFontSize = Math.floor(this.getNameSize() * 0.5);
    ctx.font = clanFontSize + "px Ubuntu";
    let clanWidth = ctx.measureText(clanName).width;
    let clanX = this.x_draw - clanWidth * 0.5;
    ctx.fillText(clanName, clanX, this.y_draw - clanFontSize * 2);
  }

  // Dibuja la puntuación, si corresponde
  if (this.isDrawScore()) {
    ctx.font = this.getNameSize() + "px Ubuntu";
    let scoreText = formatValue(parseFloat(this.getScore())); // Formatea el puntaje con separadores de miles
    let scoreWidth = ctx.measureText(scoreText).width;
    let scoreX = this.x_draw - scoreWidth * 0.5; // Centra el texto correctamente
    ctx.fillText(scoreText, scoreX, this.y_draw + this.getNameSize());
  }
};

// Crear y agregar el contenedor principal al documento
const controlPanel = document.createElement("div");
controlPanel.id = "controlPanel";
controlPanel.class = "card bg-dark text-white p-3 shadow-lg";
document.body.appendChild(controlPanel);

// Agregar controles de opacidad
controlPanel.innerHTML = `
  <div class="card-body text-white">
    <div class="mb-3">
      <label for="opacityControl" class="label-xts-pro">
        Opacity <span id="opacityValue" class="badge bg-primary">0.015</span>
      </label>
      <input
        type="range"
        id="opacityControl"
        class="custom-range"
        min="0.010"
        max="1"
        step="0.01"
        value="0.015"
      />
    </div>
    <div class="mb-3">
      <label for="borderControl" class="label-xts-pro">
        Grosor <span id="borderValue" class="badge bg-primary">2.0</span>
      </label>
      <input
        type="range"
        id="borderControl"
        class="custom-range"
        min="0"
        max="4.0"
        step="0.1"
        value="2.0"
      />
    </div>
    <div class="mb-3">
      <div class="d-flex gap-2">
        <button id="teamButton" class="btn-xts"><i class="fas fa-users"></i></button>
        <button id="clanButton" class="btn-xts"><i class="fas fa-shield-alt"></i></button>
      </div>
    </div>
  </div>
`;

// Variables para controlar los
let showTeamScore = false;
let showClanScore = false;
let borderControlFactor = 2.0;
let dynamicOpacity = 0.01; // Inicialmente la opacidad por defecto
let transparentRender = false; // Esto debe estar activado o desactivado en tu código según necesites
let controlPanelVisible = false;
const opacityControl = document.getElementById("opacityControl");
const borderControl = document.getElementById("borderControl");
const opacityValue = document.getElementById("opacityValue");
const borderValue = document.getElementById("borderValue");

function updateRangeProgress(element) {
  const value =
    ((element.value - element.min) / (element.max - element.min)) * 100;
  element.style.background = `linear-gradient(90deg, #0d6efd ${value}%, #ddd ${value}%)`;
}

updateRangeProgress(opacityControl);
updateRangeProgress(borderControl);
// Eventos para actualizar las opciones
opacityControl.addEventListener("input", () => {
  let maxOpacity = transparentRender ? 0.6 : 1; // Limite superior dependiendo de `transparentRender`
  dynamicOpacity = parseFloat(opacityControl.value);

  if (dynamicOpacity > maxOpacity) dynamicOpacity = maxOpacity;

  opacityValue.textContent = dynamicOpacity.toFixed(3);
  updateRangeProgress(opacityControl);
});

borderControl.addEventListener("input", () => {
  borderControlFactor = parseFloat(borderControl.value);
  borderValue.textContent = borderControlFactor.toFixed(1);
  updateRangeProgress(borderControl);
});
function updateToggleButton(id, active) {
  const btn = document.getElementById(id);
  if (active) {
    btn.classList.add("active");
  } else {
    btn.classList.remove("active");
  }
}

document.getElementById("teamButton").addEventListener("click", () => {
  showTeamScore = !showTeamScore;
  updateToggleButton("teamButton", showTeamScore);
});

document.getElementById("clanButton").addEventListener("click", () => {
  showClanScore = !showClanScore;
  updateToggleButton("clanButton", showClanScore);
});

window.getBoardArea = () => {
  const xMin = Math.min(leftPos, rightPos);
  const xMax = Math.max(leftPos, rightPos);
  const xMid = (xMin + xMax) / 2;

  const yMin = Math.min(topPos, bottomPos);
  const yMax = Math.max(topPos, bottomPos);
  const yMid = (yMin + yMax) / 2;

  const isInside = (x, y) => x >= xMin && x <= xMax && y >= yMin && y <= yMax;

  return {
    x_min: xMin,
    x_mid: xMid,
    x_max: xMax,
    y_min: yMin,
    y_mid: yMid,
    y_max: yMax,
    width: xMax - xMin,
    height: yMax - yMin,
    center: { x: xMid, y: yMid },
    isInside,
  };
};

let isTransparentMode = false;

var selectedEnemyPID = null;

window.tryClickChangeSpectator = function (mouseX, mouseY) {
  try {
    if (playMode !== PLAYMODE_SPECTATE) {
      console.warn("Sólo puedes cambiar de espectador en modo SPECTATE.");
      return;
    }

    const cellList = cellManager.getCellList();
    if (!Array.isArray(cellList)) {
      console.error("La lista de celdas no es válida.");
      return;
    }

    const gameCoords = cameraManager.convertPixelToGame(mouseX, mouseY);
    if (
      !gameCoords ||
      typeof gameCoords.x !== "number" ||
      typeof gameCoords.y !== "number"
    ) {
      console.error("No se pudieron convertir las coordenadas.");
      return;
    }

    let closestSize = Number.MAX_SAFE_INTEGER;
    let closestPID = null;

    for (let cell of cellList) {
      if (cell.cellType !== CELLTYPE_PLAYER) continue;

      const dx = cell.x_draw - gameCoords.x;
      const dy = cell.y_draw - gameCoords.y;
      const dist = Math.hypot(dx, dy);

      // me quedo con el jugador más cercano cuyo tamaño sea menor que closestSize
      if (dist < cell.size_draw && cell.size_draw < closestSize) {
        closestSize = cell.size_draw;
        closestPID = cell.pID;
      }
    }

    if (closestPID !== null) {
      spectatorId = closestPID;
      selectedEnemyPID = closestPID;
      setSpectator(spectatorId);
    }
  } catch (error) {
    console.error("Ocurrió un error al intentar cambiar el espectador:", error);
  }
};

function toggleDrawOptions() {
  try {
    if (isTransparentMode) {
      if (options.get("showScore") === false) {
        options.set("showScore", true); // Cambia el valor de 'showScore' a true
      }
      if (options.get("drawEdge") === false) {
        options.set("drawEdge", true); // Cambia el valor de 'showScore' a true
      }

      Cell.prototype.isDrawScore = function () {
        return options.get("showScore") === true || this.pID === playerId;
      };
      Cell.prototype.isDrawSkin = function () {
        return (
          options.get("showSkin") &&
          this.skinName !== "" &&
          this.skinName != null
        );
      };

      Cell.prototype.isDrawName = function () {
        return (options.get("showName") && this.name) || this.pID === playerId;
      };

      Cell.prototype.drawOneCell_player_ctx = function () {
        try {
          if (options.get("transparentRender") === true) {
            ctx.globalAlpha = 0.6;
          } else {
            ctx.globalAlpha = 1;
          }

          // Si existen datos de “tailDbg” (para depuración), se dibujan pequeños círculos blancos.
          if (this.tailDbg.length > 0) {
            ctx.strokeStyle = "#FFFFFF";
            ctx.lineWidth = 1;
            for (let i = 0; i < this.tailDbg.length; i++) {
              ctx.fillStyle = "rgba(255,255,255)";
              ctx.beginPath();
              ctx.arc(
                this.tailDbg[i].x,
                this.tailDbg[i].y,
                5,
                0,
                2 * Math.PI,
                false,
              );
              ctx.stroke();
            }
          }

          // Si existen datos de “nodeDbg” (para depuración), se dibujan círculos con otro color (aquí se deja el color en el ejemplo original)
          if (this.nodeDbg.length > 0) {
            ctx.strokeStyle = "#FFFFFF"; // En el código ofuscado aparece otro valor; se puede ajustar
            ctx.lineWidth = 1;
            for (let i = 0; i < this.nodeDbg.length; i++) {
              ctx.beginPath();
              ctx.arc(
                this.nodeDbg[i].x,
                this.nodeDbg[i].y,
                6,
                0,
                2 * Math.PI,
                false,
              );
              ctx.stroke();
            }
          }

          ctx.fillStyle = this.color;
          this.drawSimple(ctx);
          ctx.fill();

          // Si corresponde dibujar una “skin” encima
          if (this.isDrawSkin()) {
            const skinName = this.skinName;
            const skinUrl = `//cdn.agarz.com/${skinName.endsWith(".png") ? skinName : skinName + ".png"}`;

            if (!skins[skinName]) {
              skins[skinName] = new Image();
              skins[skinName].src = skinUrl;
              skins[skinName].onload = () => (skinsLoaded[skinName] = true);
            }

            if (skinsLoaded[skinName]) {
              ctx.save();
              ctx.beginPath();
              ctx.arc(this.x_draw, this.y_draw, this.size_draw, 0, 2 * Math.PI);
              ctx.clip();
              ctx.drawImage(
                skins[skinName],
                this.x_draw - this.size_draw,
                this.y_draw - this.size_draw,
                this.size_draw * 2,
                this.size_draw * 2,
              );
              ctx.restore();

              const info = playerInfoList[this.pID];

              if (info?.uid === record_uid && record_uid !== 0) {
                ctx.drawImage(
                  crownImage,
                  this.x_draw - this.size_draw * 0.5,
                  this.y_draw - this.size_draw * 2,
                  this.size_draw,
                  this.size_draw,
                );
              }
            }
          }

          ctx.globalAlpha = 1;

          // Solo se dibuja el UID si el checkbox "mostrar-id" está activo
          if (document.getElementById("mostrar-id").checked) {
            let uidText = extraerUID(this.skinName);
            if (uidText !== "0") {
              ctx.save();
              let uidFontSize = this.getNameSize() * 0.8;
              ctx.font = uidFontSize + "px Ubuntu";
              let uidWidth = ctx.measureText(uidText).width;
              let uidX = this.x_draw - uidWidth * 0.5;

              // Crea un efecto pulsante (glow) sutil
              let time = performance.now();
              let pulse = (Math.sin(time / 200) + 1) / 2; // Valor entre 0 y 1
              ctx.shadowColor = "#FF00FF";
              ctx.shadowBlur = 5 + pulse * 10;
              ctx.fillStyle = "#FF00FF";
              let uidY = this.y_draw - this.getNameSize() * 1.7;
              ctx.fillText(uidText, uidX, uidY);
              ctx.restore();
            }
          }

          let textColor;
          if (this.pID === playerId) {
            textColor = "#FFFFFF"; // Blanco para ti
          } else {
            let leaderboardEntry = getLeaderboardExt(this.pID);
            if (leaderboardEntry == null) {
              textColor = "#FFFFFF"; // Valor por defecto, blanco, si no hay datos
            } else {
              if (leaderboardEntry.sameTeam == 1) {
                textColor = "#FFFF00"; // Amarillo para el equipo
              } else if (leaderboardEntry.sameClan == 1) {
                textColor = "#00FF00"; // Verde para el clan
              } else {
                textColor = "#FFFFFF"; // Blanco por defecto si no se cumple nada
              }
            }
          }
          ctx.fillStyle = textColor;

          // Dibuja el nombre, si corresponde
          if (this.isDrawName()) {
            ctx.font = this.getNameSize() + "px Ubuntu";
            this.calcNameWidth(ctx);
            let textWidth = ctx.measureText(this.name).width;
            let nameX = this.x_draw - textWidth * 0.5;
            ctx.fillText(this.name, nameX, this.y_draw);
          }
          // Dibuja el clan, si corresponde
          if (this.isDrawClan()) {
            let clanName = this.getClanName();
            let clanFontSize = Math.floor(this.getNameSize() * 0.5);
            ctx.font = clanFontSize + "px Ubuntu";
            let clanWidth = ctx.measureText(clanName).width;
            let clanX = this.x_draw - clanWidth * 0.5;
            ctx.fillText(clanName, clanX, this.y_draw - clanFontSize * 2);
          }

          // Dibuja la puntuación, si corresponde
          if (this.isDrawScore()) {
            ctx.font = this.getNameSize() + "px Ubuntu";
            let scoreText = formatValue(parseFloat(this.getScore()));
            let scoreWidth = ctx.measureText(scoreText).width;
            let scoreX = this.x_draw - scoreWidth * 0.5; // Centra el texto correctamente
            ctx.fillText(scoreText, scoreX, this.y_draw + this.getNameSize());
          }
        } catch (error) {}
      };
    } else {
      if (options.get("showScore") === true) {
        options.set("showScore", false); // Cambia el valor de 'showScore' a true
      }
      if (options.get("drawEdge") === true) {
        options.set("drawEdge", false); // Cambia el valor de 'showScore' a true
      }

      Cell.prototype.isDrawScore = function () {
        const leaderboardEntry = getLeaderboardExt(this.pID);

        // Siempre mostramos el score del enemigo seleccionado o del propio jugador
        if (this.pID === selectedEnemyPID || this.pID === playerId) {
          return true;
        }

        // Mostrar siempre si está activado el "showScore" global
        if (options.get("showScore") === true) {
          return true;
        }

        // Mostrar si es del mismo team y el toggle está activo
        if (
          showTeamScore &&
          leaderboardEntry &&
          leaderboardEntry.sameTeam === 1
        ) {
          return true;
        }

        // Mostrar si es del mismo clan y el toggle está activo
        if (
          showClanScore &&
          leaderboardEntry &&
          leaderboardEntry.sameClan === 1
        ) {
          return true;
        }

        return false;
      };

      function mostrarJugadorClickPro(mouseX, mouseY) {
        try {
          if (playMode !== PLAYMODE_PLAY) {
            console.warn(
              "No se puede seleccionar jugador: no estás en modo de juego.",
            );
            return null;
          }

          const cellList = cellManager.getCellList();
          if (!Array.isArray(cellList)) {
            console.error("Error: la lista de celdas no es válida.");
            return null;
          }

          const gameCoords = cameraManager.convertPixelToGame(mouseX, mouseY);
          if (
            !gameCoords ||
            typeof gameCoords.x !== "number" ||
            typeof gameCoords.y !== "number"
          ) {
            console.error(
              "Error: no se pudieron convertir las coordenadas del mouse.",
            );
            return null;
          }

          let closestPlayer = null;
          let closestDistance = Infinity;

          for (let i = 0; i < cellList.length; i++) {
            const cell = cellList[i];

            if (cell.cellType === CELLTYPE_PLAYER) {
              const dx = cell.x_draw - gameCoords.x;
              const dy = cell.y_draw - gameCoords.y;
              const distance = Math.sqrt(dx * dx + dy * dy);

              // Si el clic está dentro del rango del jugador y es el más cercano hasta ahora
              if (distance < cell.size_draw && distance < closestDistance) {
                closestPlayer = cell;
                closestDistance = distance;
              }
            }
          }

          if (closestPlayer) {
            selectedEnemyPID = closestPlayer.pID;
            return closestPlayer.pID;
          } else {
            console.warn(
              "No se encontró ningún jugador en la posición del clic.",
            );
            return null;
          }
        } catch (error) {
          console.error(
            "Ocurrió un error al intentar seleccionar un jugador:",
            error,
          );
          return null;
        }
      }

      document.addEventListener("click", function (event) {
        var mouseX = event.clientX;
        var mouseY = event.clientY;
        mostrarJugadorClickPro(mouseX, mouseY);
      });

      Cell.prototype.isDrawSkin = function () {
        const leaderboardEntry = getLeaderboardExt(this.pID);

        // No dibujar si no hay skin
        if (!this.skinName) {
          return false;
        }

        // Siempre el propio jugador o si el toggle global está activo
        if (this.pID === playerId || options.get("showSkin") === true) {
          return true;
        }

        // Mostrar si es del mismo team y el toggle de team está activo
        if (
          showTeamScore &&
          leaderboardEntry &&
          leaderboardEntry.sameTeam === 1
        ) {
          return true;
        }

        // Mostrar si es del mismo clan y el toggle de clan está activo
        if (
          showClanScore &&
          leaderboardEntry &&
          leaderboardEntry.sameClan === 1
        ) {
          return true;
        }

        return false;
      };

      Cell.prototype.isDrawName = function () {
        const leaderboardEntry = getLeaderboardExt(this.pID);

        // Siempre propio jugador o enemigo seleccionado
        if (this.pID === playerId || this.pID === selectedEnemyPID) {
          return true;
        }

        // Mostrar si es del mismo team y el toggle de team está activo
        if (
          showTeamScore &&
          leaderboardEntry &&
          leaderboardEntry.sameTeam === 1
        ) {
          return true;
        }

        // Mostrar si es del mismo clan y el toggle de clan está activo
        if (
          showClanScore &&
          leaderboardEntry &&
          leaderboardEntry.sameClan === 1
        ) {
          return true;
        }

        return false;
      };

      let lastPrinted = 0;
      Cell.prototype.drawOneCell_player_ctx = function () {
        try {
          const leaderboardEntry = getLeaderboardExt(this.pID);

          // 1) Chequea siempre propio jugador y enemigo seleccionado
          const isOwn = this.pID === playerId;
          const isTarget = this.pID === selectedEnemyPID;

          // 2) Sólo compañ[email protected]/clanmates si los toggles están activos
          const isTeamMate =
            showTeamScore &&
            leaderboardEntry &&
            leaderboardEntry.sameTeam === 1;
          const isClanMate =
            showClanScore &&
            leaderboardEntry &&
            leaderboardEntry.sameClan === 1;

          const isPlayerOrAlly = isOwn || isTarget || isTeamMate || isClanMate;

          const transparentRender = options.get("transparentRender");

          // Aplicación de Opacidad
          if (isPlayerOrAlly) {
            // aliados siempre con alta opacidad (0.8 si transparentRender, sino 1)
            ctx.globalAlpha = transparentRender ? 0.8 : 1;
          } else {
            // enemigos con la opacidad dinámica del slider
            ctx.globalAlpha = dynamicOpacity;
          }

          // Dibuja tailDbg (debug)
          if (this.tailDbg.length > 0) {
            ctx.strokeStyle = "#FFFFFF";
            ctx.lineWidth = 1;
            for (let i = 0; i < this.tailDbg.length; i++) {
              ctx.fillStyle = "rgba(255,255,255)";
              ctx.beginPath();
              ctx.arc(
                this.tailDbg[i].x,
                this.tailDbg[i].y,
                5,
                0,
                2 * Math.PI,
                false,
              );
              ctx.stroke();
            }
          }

          // Dibuja nodeDbg (debug)
          if (this.nodeDbg.length > 0) {
            ctx.strokeStyle = "#FFFFFF";
            ctx.lineWidth = 1;
            for (let i = 0; i < this.nodeDbg.length; i++) {
              ctx.beginPath();
              ctx.arc(
                this.nodeDbg[i].x,
                this.nodeDbg[i].y,
                6,
                0,
                2 * Math.PI,
                false,
              );
              ctx.stroke();
            }
          }

          ctx.fillStyle = this.color;
          this.drawSimple(ctx);
          ctx.fill();

          // Si corresponde dibujar una “skin” encima
          if (this.isDrawSkin()) {
            const skinName = this.skinName;
            const skinUrl = `//cdn.agarz.com/${skinName.endsWith(".png") ? skinName : skinName + ".png"}`;

            if (!skins[skinName]) {
              skins[skinName] = new Image();
              skins[skinName].src = skinUrl;
              skins[skinName].onload = () => (skinsLoaded[skinName] = true);
            }

            if (skinsLoaded[skinName]) {
              ctx.save();
              ctx.beginPath();
              ctx.arc(this.x_draw, this.y_draw, this.size_draw, 0, 2 * Math.PI);
              ctx.clip();
              ctx.drawImage(
                skins[skinName],
                this.x_draw - this.size_draw,
                this.y_draw - this.size_draw,
                this.size_draw * 2,
                this.size_draw * 2,
              );
              ctx.restore();

              const info = playerInfoList[this.pID];

              if (info?.uid === record_uid && record_uid !== 0) {
                ctx.drawImage(
                  crownImage,
                  this.x_draw - this.size_draw * 0.5,
                  this.y_draw - this.size_draw * 2,
                  this.size_draw,
                  this.size_draw,
                );
              }
            }
          }

          // Restauramos la opacidad por si se cambió antes
          ctx.globalAlpha = 1;

          let lineWidth = Math.min(
            210,
            Math.max(0, this.size_draw * 0.1 * borderControlFactor),
          );

          let strokeColor = "#FFFFFF";
          let threshold = 216000;

          if (
            document.getElementById("vsffa") &&
            document.getElementById("vsffa").selected
          ) {
            threshold = 176000;
          } else if (
            document.getElementById("tffa1") &&
            document.getElementById("tffa1").selected
          ) {
            threshold = 246000;
          }
          let baseLineWidth = Math.min(
            210,
            Math.max(0, this.size_draw * 0.1 * borderControlFactor),
          );

          // 2) Solo dibujar borde si cumple alguna de esas tres condiciones
          if (isOwn || isTeamMate || isClanMate || isTarget) {
            // Caso: Celda del jugador
            if (isOwn) {
              strokeColor = "#FFFFFF";
              lineWidth = baseLineWidth;

              if (this.getScore() > threshold) {
                // pulso rojo
                const time = Date.now();
                const pulse = (Math.sin(time / 200) + 1) / 2;
                lineWidth = baseLineWidth + pulse * 80;
                strokeColor = "rgba(255,0,0,1)";

                ctx.save();
                ctx.shadowColor = strokeColor;
                ctx.shadowBlur = 20 + pulse * 30;
                ctx.strokeStyle = strokeColor;
                ctx.lineWidth = lineWidth;
                ctx.beginPath();
                ctx.arc(
                  this.x_draw,
                  this.y_draw,
                  this.size_draw - lineWidth / 2,
                  0,
                  2 * Math.PI,
                );
                ctx.stroke();
                ctx.restore();
              } else {
                // borde normal
                ctx.save();
                ctx.strokeStyle = strokeColor;
                ctx.lineWidth = lineWidth;
                ctx.beginPath();
                ctx.arc(
                  this.x_draw,
                  this.y_draw,
                  this.size_draw - lineWidth / 2,
                  0,
                  2 * Math.PI,
                );
                ctx.stroke();
                ctx.restore();
              }
            } else if (isTarget) {
              strokeColor = "#FFFFFF";
              ctx.save();
              ctx.strokeStyle = strokeColor;
              ctx.lineWidth = baseLineWidth;
              ctx.beginPath();
              ctx.arc(
                this.x_draw,
                this.y_draw,
                this.size_draw - baseLineWidth / 2,
                0,
                2 * Math.PI,
              );
              ctx.stroke();
              ctx.restore();
            }
            // Caso: Teammate (pero no clanmate)
            else if (isTeamMate) {
              strokeColor = ColorManager.Current.Name_SameTeamOnMap;
              ctx.save();
              ctx.strokeStyle = strokeColor;
              ctx.lineWidth = baseLineWidth;
              ctx.beginPath();
              ctx.arc(
                this.x_draw,
                this.y_draw,
                this.size_draw - baseLineWidth / 2,
                0,
                2 * Math.PI,
              );
              ctx.stroke();
              ctx.restore();
            }
            // Caso: Clanmate
            else if (isClanMate) {
              strokeColor = ColorManager.Current.Name_SameClanOnList;
              ctx.save();
              ctx.strokeStyle = strokeColor;
              ctx.lineWidth = baseLineWidth;
              ctx.beginPath();
              ctx.arc(
                this.x_draw,
                this.y_draw,
                this.size_draw - baseLineWidth / 2,
                0,
                2 * Math.PI,
              );
              ctx.stroke();
              ctx.restore();
            }
          }

          let textColor;
          if (this.pID === playerId) {
            textColor = "#FFFFFF"; // Blanco para ti
          } else {
            let leaderboardEntry = getLeaderboardExt(this.pID);
            if (leaderboardEntry == null) {
              textColor = "#FFFFFF"; // Valor por defecto, blanco, si no hay datos
            } else {
              if (leaderboardEntry.sameTeam == 1) {
                textColor = "#FFFF00"; // Amarillo para el equipo
              } else if (leaderboardEntry.sameClan == 1) {
                textColor = "#00FF00"; // Verde para el clan
              } else {
                textColor = "#FFFFFF"; // Blanco por defecto si no se cumple nada
              }
            }
          }
          ctx.fillStyle = textColor;

          if (this.isDrawName()) {
            ctx.font = this.getNameSize() + "px Ubuntu";
            this.calcNameWidth(ctx);
            let textWidth = ctx.measureText(this.name).width;
            let nameX = this.x_draw - textWidth * 0.5;
            ctx.fillText(this.name, nameX, this.y_draw);
          }
          if (this.isDrawClan()) {
            let clanName = this.getClanName();
            let clanFontSize = Math.floor(this.getNameSize() * 0.5);
            ctx.font = clanFontSize + "px Ubuntu";
            let clanWidth = ctx.measureText(clanName).width;
            let clanX = this.x_draw - clanWidth * 0.5;
            ctx.fillText(clanName, clanX, this.y_draw - clanFontSize * 2);
          }
          if (this.isDrawScore()) {
            ctx.font = this.getNameSize() + "px Ubuntu";
            let scoreText = formatValue(parseFloat(this.getScore()));
            let scoreWidth = ctx.measureText(scoreText).width;
            let scoreX = this.x_draw - scoreWidth * 0.5;
            ctx.fillText(scoreText, scoreX, this.y_draw + this.getNameSize());
          }
          if (this.isDrawUID()) {
            ctx.font = this.getNameSize() + "px Ubuntu";
            let uidText = spectatorPlayer.name;
            let uidWidth = ctx.measureText(uidText).width;
            let uidX = this.x_draw - uidWidth * 0.5;
            ctx.fillText(uidText, uidX, this.y_draw - this.getNameSize());
          }
        } catch (error) {}
      };
    }
    // Cambia el estado del modo transparente para la siguiente llamada
    isTransparentMode = !isTransparentMode;
    controlPanelVisible = !controlPanelVisible; // Cambia el estado del panel
    controlPanel.style.display = controlPanelVisible ? "block" : "none"; // Mostrar u ocultar el panel
  } catch (error) {}
}

let wasActiveEdge = false;
document.addEventListener("keydown", function (event) {
  try {
    if (
      (event.key === "O" || event.key === "o") &&
      document.activeElement.tagName !== "INPUT" &&
      document.activeElement.tagName !== "TEXTAREA"
    ) {
      setTimeout(toggleDrawOptions, 0);
    }
  } catch (error) {
    console.error("Error handling keydown event: ", error);
  }
});

$(document).ready(function () {
  $("style").each(function () {
    if (
      $(this).text().includes(".skin-popup") ||
      $(this).text().includes(".isim-popup")
    ) {
      $(this).remove();
    }
  });
});
$(document).ready(function () {
  $(".isim-link.skin-kapat").remove();
});
const emojiBtn = document.getElementById("emoji-button");

if (emojiBtn) {
  // Crear un ícono Font Awesome dinámicamente
  const icon = document.createElement("i");
  icon.classList.add("fas", "fa-laugh-beam"); // Cambia aquí la clase si quieres otro ícono
  emojiBtn.textContent = ""; // Limpiar cualquier emoji o texto anterior
  emojiBtn.appendChild(icon);
}
document.addEventListener("click", function (event) {
  const emojiList = document.querySelector(".emojiList");
  const emojiButton = document.getElementById("emoji-button");
  if (!emojiList) return;

  if (
    !emojiList.contains(event.target) &&
    !emojiButton.contains(event.target)
  ) {
    emojiList.style.display = "none";
  }
});

// Eliminar CSS innecesarios
document.querySelectorAll('link[rel="stylesheet"]').forEach((enlace) => {
  if (enlace.href.includes("css/index.css")) {
    enlace.parentElement.removeChild(enlace);
  }
});

// Agregar FontAwesome para los iconos
const linkicon = document.createElement("link");
linkicon.rel = "stylesheet";
linkicon.href =
  "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css";
document.head.appendChild(linkicon);

// Agregar Bootstrap para los iconos
const linkBootstrapIcon = document.createElement("link");
linkBootstrapIcon.rel = "stylesheet";
linkBootstrapIcon.href =
  "https://cdn.jsdelivr.net/npm/bootstrap-icons/font/bootstrap-icons.css";
document.head.appendChild(linkBootstrapIcon);

// Reemplazar versión antigua de Bootstrap con una nueva
const oldBootstrapLink = document.querySelector(
  'link[href*="maxcdn.bootstrapcdn.com/bootstrap"]',
);
if (oldBootstrapLink) {
  oldBootstrapLink.parentElement.removeChild(oldBootstrapLink);
}
// Agregar nueva versión de Bootstrap
const newBootstrapLink = document.createElement("link");
newBootstrapLink.rel = "stylesheet";
newBootstrapLink.href =
  "https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css";
document.head.appendChild(newBootstrapLink);

// Agregar Material Icons
const materialIconsLink = document.createElement("link");
materialIconsLink.rel = "stylesheet";
materialIconsLink.href =
  "https://fonts.googleapis.com/icon?family=Material+Icons";
document.head.appendChild(materialIconsLink);
// Agregar la fuente Poppins dinámicamente
const poppinsFontLink = document.createElement("link");
poppinsFontLink.rel = "stylesheet";
poppinsFontLink.href =
  "https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap";
document.head.appendChild(poppinsFontLink);

var stylemain = document.createElement("style");
stylemain.innerHTML = `
.skin-kapat {
    background-color: #c70000!important;
    color: #FFFFFF;
    position: absolute;
    right: 0;
    font-size: 20px;
}
.isim-link {
    display: inline-block;
    background-color: #4d4d4d;
    text-decoration: none;
    padding: 5px;
    margin: 5px;
    border-radius: 15px;
}
.isim-link:hover {
    background-color: #007aff!important; /* Fondo azul en hover */
    color: white;
    box-shadow: 0 6px 12px rgba(0, 0, 0, 0.2); /* Sombra más pronunciada */
    transform: translateY(-3px); /* Efecto de elevación */
}

*::-webkit-scrollbar {
  width: 5px !important;
}

/* 🔹 Pulgar sin border-radius */

*::-webkit-scrollbar-thumb {
  background-color: #666 !important;
  border-radius: 0 !important;
  border: none !important;
}

/* 🔹 Track (fondo del scrollbar) */

*::-webkit-scrollbar-track {
  background: #3b3b3bd6 !important;
}

.skin-img {
    border-radius: 50%;
    cursor: pointer;
    margin: 10px;
    transition: transform 0.3s ease;
}

.skin-img:hover {
    transform: scale(1.1); /* Efecto de aumento de tamaño al pasar el ratón */
}


.skin-popup {
    visibility: hidden;
    position: absolute;
    left: 50%;
    top: 50%;
    background-color: #000000c7;
    z-index: 300;
    transform: translate(-50%, -50%);
    text-align: center;
    height: 600px;
    overflow: auto;
    border: 1px solid #212121;
    width: 700px;
}
.skin-popup.active {
    visibility: visible;
    transform: translate(-50%, -50%) scale(1); /* Escala suave */
}

.isim-popup {
    visibility: hidden;
    position: absolute;
    left: 50%;
    top: 50%;
    background-color: #000000c7;
    z-index: 300;
    padding: 15px;
    transform: translate(-50%, -50%);
    font-size: 20px;
    text-align: center;
    border: 1px solid #212121;
}
.isim-kapat {
    background-color: #c70000 !important;
    color: #FFFFFF;
    position: absolute;
    top: -30px;
    right: 20px;
}
.isim-popup.active {
    visibility: visible;
    transform: translate(-50%, -50%) scale(1); /* Escala suave */
}

.form-control, .form-control:focus {
    outline: none;
    border-radius: 30px;
    padding: 3px 10px;
    color:white;
    background: #222222;
    border: 1px solid #757575;
    font-size:14px;
}
.form-control::placeholder {
        color: #757575;
        opacity: 1; /* Para asegurarte que se vea bien en todos los navegadores */
    }
   .label-xts-pro{ text-transform: uppercase;
    font-size: 14px;
    font-family: 'Ubuntu';}
#controlPanel {
    position: fixed;
    bottom: 0;
    left: 10px;
    width: 170px;
    margin-bottom: 550px;
    display: none;
    zoom: 88%;
    background: rgb(0 0 0 / 50%);
    padding: 8px;
    border-radius: 8px;
    box-shadow: 0 0 10px rgb(0 0 0 / 70%);
    z-index: 9999;
}

    #controlPanel .card-title {
        font-size: 1.2rem;
        margin-bottom: 1rem;
 }
/* Para asegurarte que sobrescriba Bootstrap */
.custom-range {
    appearance: none;
    appearance: none;
    width: 100%;
    height: 5px;
    border-radius: 5px;
    outline: none;
    background: linear-gradient(90deg, #0d6efd 0%, #ddd 0%);
    transition: background 0.15s;
}
 #teamButton.active{
  background: #ffea00;              /* amarillo vivo */
  color: #333;                     /* texto oscuro para contraste */
  box-shadow: 0 2px 6px rgb(255 234 0 / 60%);
  transform: translateY(-1px) scale(1.02);
}

/* Clan Button Activo */
#clanButton.active{
  background: #00e676;             /* verde luminoso */
  color: #fff;
  box-shadow: 0 2px 6px rgb(0 230 118 / 60%);
  transform: translateY(-1px) scale(1.02);
}

/* Estilo base compartido */
.btn-xts {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 10px 9px;
    font-size: 0.875rem;
    color: #848484;
    background: rgb(255 255 255 / 15%);
    border: 1px solid rgb(255 255 255 / 30%);
    border-radius: 50%;
    cursor: pointer;
    transition: background 0.4s ease-out, transform 0.4sease-out, box-shadow 0.4sease-out;
}

/* Hover genérico */
.btn-xts:hover {
  background: rgb(255 255 255 / 30%);
  transform: translateY(-1px) scale(1.02);
  box-shadow: 0 2px 6px rgb(0 0 0 / 20%);
}

/* Chrome, Safari, Edge */
.custom-range::-webkit-slider-thumb {
    -webkit-appearance: none;
    appearance: none;
    width: 16px;
    height: 16px;
    border-radius: 50%;
    background-color: #0d6efd;
    cursor: pointer;
}

/* Firefox */
.custom-range::-moz-range-thumb {
    width: 16px;
    height: 16px;
    border-radius: 50%;
    background-color: #0d6efd;
    cursor: pointer;
}

/* Internet Explorer */
.custom-range::-ms-thumb {
    width: 16px;
    height: 16px;
    border-radius: 50%;
    background-color: #0d6efd;
    cursor: pointer;
}

#controlPanel .form-range:active::-moz-range-thumb {
    transform: scale(1.2);
}



 body {
	padding: 0;
	margin: 0;
	overflow: hidden;
}

hr{
	margin:2px;
}

#canvas {
	position: absolute;
	left: 0;
	right: 0;
	top: 0;
	bottom: 0;
	width: 100%;
	height: 100%;
}

iframe{
    border: 0px;
    overflow:hidden;
}

.checkbox label {
	margin-right: 10px;
}

form {
	margin-bottom: 0px;
}

.btn-play, .btn-settings, .btn-spectate {
	display: block;
	height: 35px;
    border-radius: 30px;
    background: #636363;
    outline: none;
    border: none;
    color: white;
}

.btn-play {
	width: 100%;
	float: left;
}

.btn-settings {
	width: 13%;
	float: right;
}

.btn-spectate {
	display: block;
	float: right;
}

#adsBottom {
	position: absolute;
	left: 0;
	right: 0;
	bottom: 0;
}

#adsBottomInner {
	margin: 0px auto;
	width: 728px;
	height: 90px;
	border: 5px solid white;
	border-radius: 5px 5px 0px 0px;
	background-color: #FFFFFF;
	box-sizing: content-box;
}

.region-message {
	display: none;
	margin-bottom: 12px;
	margin-left: 6px;
	margin-right: 6px;
	text-align: center;
}

#nick, #locationKnown #region {
	width: 50%;
	float: left;
}

#spectateBtn {
	width: 50%;
	float: left;
}

#replayBtn {
	width: 50%;
	float: right;
}

#gamemode{
	width: 30%;
	float: left;
}

#settingsPopup{
	position: absolute;
	top: 50%;
	left: 50%;
	transform: translate(-50%, -50%);
	background-color:#000C;
	z-index:300;
	border:1px solid #000;
	width:380px;
	height:200px;
	display:none;
	border-radius: 10px;
	border:1px solid #FFF;
}
#settingsPopup button{
	right:0px;
	bottom:0px;
	position:absolute;
	border-radius: 0px 0px 10px 0px;
	margin:2px;
	padding:2px;
}
#yesno_settings_mobile{
	padding:2px;
}
#yesno_settings_mobile label{
	font-size:14px;
	margin:5px;
	color:#FFF;
}

#solMenuPopup{
	position: absolute;
	top: 50%;
	left: 50%;
	transform: translate(-50%, -50%);
	background-color:#000C;
	z-index:300;
	border:1px solid #000;
	display:none;
	padding:10px;
	border-radius: 10px;
	border:1px solid #FFF;
}
#solMenuPopup button{
	right:0px;
	bottom:0px;
	position:absolute;
	border-radius: 0px 0px 10px 0px;
	margin:2px;
	padding:2px;
}
#solMenuPopup a{
	display:inline-block;
	font-size:20px;
	font-weight:bold;
	padding:5px;
	color:#FFF;
	width:100%;
}

#mobilTools{
	text-align:center;
}
#mobilTools li{
	display: inline;
	color:#FFF;
	font-size:20px;
}

#helloDialog {
	width: 380px;
	background-color:#242424;
	margin: 10px auto;
	border-radius: 15px;
	padding: 25px 15px 25px 15px;
	position: absolute;
	top: 50%;
	left: 50%;
	margin-right: -50%;
	-webkit-transform: translate(-50%, -50%);
	-ms-transform: translate(-50%, -50%);
	transform: translate(-50%, -50%);
    color:white;
}

#showMessageOverlays {
	display:none;
	position:absolute;
	left:0;
	right:0;
	top:0;
	bottom:0;
	background-color:rgba(0,0,0,0.5);
	z-index:201;
}

#showMessageTxt {
	margin-bottom:10px;
}
.emojiList {
    font-size: 20px;
    position: absolute;
    background-color: #292929;
    color: #ffffff;
    display: none;
    left: 350px;
    top: -300px;
    padding: 12px;
    border-radius: 12px;
    width: 380px;
    height: 280px;
    opacity: 0.95;
    box-shadow: 0 8px 16px rgba(0, 0, 0, 0.4);
    transition: all 0.3s ease-in-out;
    backdrop-filter: blur(6px);
    overflow-y: auto;
}

.emojiList ul {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.emojiList li {
  cursor: pointer;
  font-size: 24px;
  padding: 6px;
  border-radius: 8px;
  transition: background-color 0.2s ease, transform 0.2s ease;
}

.emojiList li:hover {
  background-color: #2c2c3d;
  transform: scale(1.2);
}

/* Scrollbar moderno y oscuro */
.emojiList::-webkit-scrollbar {
  width: 0px!important;
}
.emojiList::-webkit-scrollbar-track {
  background: transparent;
}
.emojiList::-webkit-scrollbar-thumb {
  background-color: #444;
  border-radius: 10px;
}
.emoji-icon {
    font-size: 1rem;
    color: #ff9800;
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    transition: transform 0.3s ease, color 0.3s ease;
  }

  .emoji-icon:hover {
    transform: scale(1.3) rotate(10deg);
    color: #ffc107;
  }

  /* Animación opcional continua */
  .animated-icon i {
    animation: bounce 1.5s infinite;
  }

  @keyframes bounce {
    0%, 100% {
      transform: translateY(0);
    }
    50% {
      transform: translateY(-6px);
    }
  }
#showMessageDialog {
	width: 380px;
	background-color: #FFFFFF;
	margin: 10px auto;
	border-radius: 15px;
	padding: 15px 15px 15px 15px;
	position: absolute;
	top: 50%;
	left: 50%;
	margin-right: -50%;
	-webkit-transform: translate(-50%, -50%);
	-ms-transform: translate(-50%, -50%);
	transform: translate(-50%, -50%);
}

.bottomContainer {
    -webkit-transition: all .5s ease-in-out;
    -moz-transition: all .5s ease-in-out;
    -o-transition: all .5s ease-in-out;
    transition: all .5s ease-in-out;
    position: absolute;
    z-index: 1;
    bottom: 0px;
    background: rgba(0, 0, 0, 0.3);
    border: 0px;
    outline: none;
    color: #FFF;
    height: 30px;
    text-indent: 4px;
    left: 0px;
    padding-right: 10px;
    height: 48px;
    padding: 0px 15px;
    background-color: #0000;
    border-radius: 0px 20px 0px 0px;
}

.bottomContainer_mobile {
	-webkit-transition: all .5s ease-in-out;
	-moz-transition: all .5s ease-in-out;
	-o-transition: all .5s ease-in-out;
	transition: all .5s ease-in-out;
	position: absolute;
	z-index: 1;
	bottom: 0px;
	background: #000;
	border: 0px;
	outline: none;
	color: #FFF;
	height: 100px;
	text-indent: 12px;
	left: 0px;
	padding:0px;
	margin:0px;
	width:100%;
}
#chat_textbox_mobile{
	background: #222;
	width:80%;
	padding:0px;
	margin:0px;
}
#sendChatButton{
	width:15%;
	margin:0px;
	padding:0px;
	color:#000;
}

#chatInputContainer {
	display: inline-block;
}
.chat-input-container {
    position: relative;
    display: inline-block;
}
#soundContainer {
	display: inline-block;
	color:#FF0000;
}

#chat_textbox {
	-webkit-transition: all .5s ease-in-out;
	-moz-transition: all .5s ease-in-out;
	-o-transition: all .5s ease-in-out;
	transition: all .5s ease-in-out;
	/*position: absolute;*/
	z-index: 1;
	bottom: 10px;
	background: rgba(0, 0, 0, .2);
	border: 0px;
	outline: none;
	color: #FFF;
	height: 30px;
	text-indent: 12px;
	left: 10px;
	width: 300px;
}

#chat_report {
	position: absolute;
	z-index: 1;
	bottom: 10px;
	background: rgba(0, 0, 0, .5);
	border: 0px;
	outline: none;
	color: #FFF;
	height: 30px;
	left: 310px;
	width: 80px;
}

#chat_textbox:focus {
	background: rgba(0, 0, 0, .5);
}

#a300x250 {
	width: 300px;
	height: 250px;
	background-repeat: no-repeat;
	background-size: contain;
	background-position: center center;
}

#overlays{
	display:none;
	position:absolute;
	left:0;
	right:0;
	top:0;
	bottom:0;
	background-color:rgba(0,0,0,0.5);
	z-index:200;
}
#idUserContainer {
    background-color: #0000008f;
    border-radius: 10px;
    position: absolute;
    width: 260px;
    left: -265px;
    top: 252px;
    padding: 15px;
    background-color: #242424;
    font-size: 14px;
}
#idMobileDownload{
	position:absolute;
	width:156px;
	right:-156px;
	top:495px;
	background-color:#FFFFFF;
	padding:1px;
}
#idPartnerKafeler{
	position:absolute;
	width:250px;
	right:-250px;
	top:550px;
	background-color:#FFFFFF;
	padding:1px;
}
#idTwitch{
	position:absolute;
	width:380px;
	right:-385px;
	top:55px;
	background-color:#FFFFFF;
	padding:1px;
	display:table;
	padding:5px;
}
#topInfo{
	display:table;
	margin:0px auto;
	padding:0px;
}
#musabakaYazisi{
	position:absolute;
	left:0px;
	top:-20px;
	color:#FFFFFF;
	text-align:center;
	width:400px;
}

#idSolMenu {
    position: absolute;
    width: 260px;
    left: -265px;
    background-color: #242424;
    padding: 10px;
    color: white;
    top: 0px;
    font-size: 14px;
    border-radius: 10px;
}
#txtSkin{
	width:100%;
	float:left;
}

h2{
	text-align:center;
}
#divReport{
    position: absolute;
    left: 0;
    right: 0;
    top: 0;
    bottom: 0;
    background-color: rgba(255,255,255,1);
    z-index: 300;
	width:310px;
	height:160px;
	padding:5px;
	margin:300px auto;
}
#divReportErr{
	color:#FF0000;
}
#idFacebookPage{
	position:absolute;
	width: 260px;
	right:-260px;
	top:20px;
	padding:5px;
}
#idDiscord {
    background-color: #242424;
    position: absolute;
    width: 300px;
    right: -305px;
    top: 0;
    padding: 10px;
    border-radius: 10px;
    font-size: 14px;
}
#idUyari{
	background-color: rgba(255,255,255,1);
	position:absolute;
	width: 380px;
	right:-385px;
	top:90px;
	padding:5px;
	display:none;
}
#idGooglePlay{
	background-color: rgba(255,255,255,1);
	position:absolute;
	width: 165px;
	height:64px;
	right:-170px;
	top:275px;
	padding:0px;
	display:none;
}
#idYayin{
	background-color: rgba(255,255,255,1);
	position:absolute;
	width: 165px;
	right:-170px;
	top:345px;
	padding:5px;
}
#enterPriceConfirmDialog {
	z-index: 301;
	background-color: #FFFFFF;
	margin: 10px auto;
	border-radius: 15px;
	padding: 25px;
	position: absolute;
	top: 50%;
	left: 50%;
	display:none;
	transform: translate(-50%, -50%);
	font-size:20px;
}
.anyDialog {
}
.myDialog {
	z-index: 302;
	background-color: #FFFFFF;
	margin: 10px auto;
	border-radius: 15px;
	padding: 25px;
	position: absolute;
	top: 50%;
	left: 50%;
	display:none;
	transform: translate(-50%, -50%);
	font-size:20px;
	border: 5px solid #FF0000;
}
#finalList td{
	padding:5px;
	font-family: fantasy;
}
#finalLeaderboardDialog{
	z-index: 303;
	background-color: #FFFFFF;
	margin: 10px auto;
	border-radius: 15px;
	padding: 25px;
	position: absolute;
	top: 50%;
	left: 50%;
	display:none;
	transform: translate(-50%, -50%);
	font-size:20px;
	border: 5px solid #000000;
	box-shadow: inset 0px 0px 15px 0px;
}
#idAdminPanel{
	position:absolute;
	width:350px;
	right:-360px;
	top:0px;
	color:#111111;
	background-color:#00FF00;
	padding:5px;
}

.talkButton:active{
	background-color:#AA0000;
	color:#FFFFFF;
}
input:-webkit-autofill,
input:-webkit-autofill:hover,
input:-webkit-autofill:focus,
input:-webkit-autofill:active {
	-webkit-background-clip: text;
	-webkit-text-fill-color: #ffffff;
	transition: background-color 5000s ease-in-out 0s;
	font-size: 16px;
}


/*Change text in autofill textbox*/

input:-webkit-autofill {
	-webkit-text-fill-color: white !important;
}
#colorOptions{
display: block;
    background-color: rgb(36, 36, 36);
    padding: 10px;
    color: white;
    font-size: 14px;
    border-radius: 10px;

}
#customColorMenu {
    font-family: sans-serif;
    color: white;
    border-radius: 6px;
    width: 154px;
    position: absolute;
    left: -112.1%;
    top: 0px;
    font-size: 14px;
}
#toggleMenu {
    width: 100%;
    padding: 2px;
    margin-bottom: 8px;
    border: 1px solid #444;
    background-color: #242424;
    color: white;
    border-radius: 10px;
    font-family: Poppins, sans-serif;
    font-size: 13px !important;
    font-weight: bold;
    TEXT-TRANSFORM: UPPERCASE;
}
.estiloextspe{

    display: flex
;
    align-items: center;
    margin-bottom: 6px;
    font-size: 12px;
    flex-direction: column;

}
@keyframes gradientMove {
  0% {
    background-position: 0% 50%;
  }

  50% {
    background-position: 100% 50%;
  }

  100% {
    background-position: 0% 50%;
  }
}

.btnxtsproxteeq {
    background: linear-gradient(127deg, yellow, deeppink, cyan, yellow);
    color: black;
    border-radius: 30px;
    width: 50%;
    text-align: center;
    font-size: 0.69rem;
    font-weight: bold;
    border: none;
    background-size: 400% 100%;
    animation: gradientMove 13s linear infinite;
}
.xpespanxtsqw {
    width: 100%;
    display: flex;
    gap: 10px;
    align-items: center;
}
.xrseeqw {
    -webkit-appearance: none;
    -moz-appearance: none;
    appearance: none;

    width: 50%;
    height: 20px;
    border: none;
    border-radius: 8px;
    padding: 0;
    background: none;
    box-shadow: none;
    outline: none;
    cursor: pointer;
    transition: all 0.3s ease;
    border: 1px solid #3b3b3b;
}


.xrseeqw::-webkit-color-swatch-wrapper {
    padding: 0;
    border: none;
    margin: 0;
}
.xrseeqw::-webkit-color-swatch {
    border: none;
    border-radius: 8px;
    padding: 0;
    margin: 0;
}

/* Glow al hacer hover */
.xrseeqw:hover {
    box-shadow: 0 0 8px rgba(0, 255, 0, 0.6);
}

/* Efecto al hacer clic o focus */
.xrseeqw:focus {
    box-shadow: 0 0 10px rgba(255, 255, 255, 0.8);
}

/* Estilo interno de la muestra del color (solo para WebKit) */
.xrseeqw::-webkit-color-swatch-wrapper {
    padding: 0;
}
.xrseeqw::-webkit-color-swatch {
    border: none;
    border-radius: 8px;
}

.customSlider {
    vertical-align: middle;
    margin-right: 8px;
}

..sliderValue {
    display: inline-block;
    text-align: right;
    color: #0f0;

}.customSlider {
    -webkit-appearance: none;
    width: 80%;
    height: 6px;
    background: linear-gradient(to right, #0f0, #ff0, #f00);
    border-radius: 10px;
    outline: none;
    transition: background 0.3sease-in-out;
    cursor: pointer;
}
/* Thumb (el círculo que se arrastra) - Chrome, Safari, Edge */
.customSlider::-webkit-slider-thumb {
    -webkit-appearance: none;
    appearance: none;
    width: 16px;
    height: 16px;
    background: #fff;
    border: 2px solid #0f0;
    border-radius: 50%;
    box-shadow: 0 0 4px rgba(0, 255, 0, 0.5);
    transition: transform 0.2s ease;
}
.customSlider::-webkit-slider-thumb:hover {
    transform: scale(1.2);
}

/* Thumb - Firefox */
.customSlider::-moz-range-thumb {
    width: 16px;
    height: 16px;
    background: #fff;
    border: 2px solid #0f0;
    border-radius: 50%;
    box-shadow: 0 0 4px rgba(0, 255, 0, 0.5);
    transition: transform 0.2s ease;
}
.customSlider::-moz-range-thumb:hover {
    transform: scale(1.2);
}

/* Track - Firefox */
.customSlider::-moz-range-track {
    height: 6px;
    background: linear-gradient(to right, #0f0, #ff0, #f00);
    border-radius: 10px;
}

`;
document.head.appendChild(stylemain);
// Elementos del menú
const menuBtn = document.getElementById("menuBtnopen");
const menu = document.getElementById("menu");
const cerrarMenuBtn = document.getElementById("cerrarsettingsmenu");

// Elementos del settings
const settingsBtn = document.getElementById("settingsBtn");
const settingsc = document.getElementById("settings");
const cerrarBtn = document.getElementById("cerrarsettingspro");

// Función para cerrar el menú
function closeMenu() {
  if (menu.classList.contains("show")) {
    menu.classList.remove("show");
    setTimeout(() => {
      menu.style.display = "none";
    }, 300);
  }
}

// Función para cerrar settings
function closeSettings() {
  if (settingsc.classList.contains("show")) {
    settingsc.classList.remove("show");
    setTimeout(() => {
      settingsc.style.display = "none";
    }, 300);
  }
}

// Función para alternar el menú
function toggleMenu() {
  closeSettings(); // Cierra settings antes de abrir el menú
  if (menu.classList.contains("show")) {
    closeMenu();
  } else {
    menu.style.display = "block";
    setTimeout(() => {
      menu.classList.add("show");
    }, 10);
  }
}

// Función para alternar settings
function toggleSettings() {
  closeMenu(); // Cierra el menú antes de abrir settings
  if (settingsc.classList.contains("show")) {
    closeSettings();
  } else {
    settingsc.style.display = "block";
    setTimeout(() => {
      settingsc.classList.add("show");
    }, 10);
  }
}

const selectors = ["#emoji-list", ".skin-popup"];

document.querySelectorAll(selectors.join(",")).forEach((el) => {
  el.addEventListener(
    "wheel",
    function (event) {
      if (this.scrollHeight > this.clientHeight) {
        event.stopPropagation();
      }
    },
    { passive: true },
  );
});

// Valores por defecto (solo si no están definidos)
const defaultColors = {
  "--virusFillColor": "#00ff00",
  "--virusBorderColor": "#15ff00",
  colorGold: "#FFD700",
  colorPrize: "#FF69B4",
  animationSpeed: 50,
};

// Inicializar variables CSS si no existen
Object.entries(defaultColors).forEach(([key, val]) => {
  if (!localStorage.getItem(key) && key.startsWith("--")) {
    document.documentElement.style.setProperty(key, val);
  }
});

// Función para crear filas (color o slider)
function createRow(label, type = "color", min = 0, max = 100, value = 50) {
  if (type === "color") {
    return `
      <div class="estiloextspe">
        <span>${label.toUpperCase()}</span>
        <span class="xpespanxtsqw">
          <input type="color" class="xrseeqw"/>
          <button class="btnxtsproxteeq">APLICAR</button>
        </span>
      </div>
    `;
  } else if (type === "range") {
    return `
      <div class="estiloextspe">
        <span>${label.toUpperCase()}</span>
        <span class="xpespanxtsqw">
          <input type="range" id="animationSpeed" class="customSlider" min="${min}" max="${max}" value="${value}" />
          <span class="sliderValue">${value}</span>
        </span>
      </div>
    `;
  }
}

$(document).ready(function () {
  // Insertar menú
  const menuHtml = `
    <div id="customColorMenu">
      <button id="toggleMenu">Paleta</button>
      <div id="colorOptions" style="display:none">
        ${createRow("VIRUS")}
        ${createRow("VIRUS BORDE")}
        ${createRow("GOLD")}
        ${createRow("PRIZE")}
        ${createRow("Animacion", "range", 0, 100, localStorage.getItem("animationSpeed") || defaultColors.animationSpeed)}
      </div>
    </div>
  `;
  $("#helloDialog").append(menuHtml);

  // Aplicar valores guardados o por defecto a CSS, ColorManager y inputs
  function applySettings() {
    const settings = {
      "--virusFillColor":
        localStorage.getItem("virusFillColor") ||
        defaultColors["--virusFillColor"],
      "--virusBorderColor":
        localStorage.getItem("virusBorderColor") ||
        defaultColors["--virusBorderColor"],
      colorGold: localStorage.getItem("colorGold") || defaultColors.colorGold,
      colorPrize:
        localStorage.getItem("colorPrize") || defaultColors.colorPrize,
      animationSpeed:
        localStorage.getItem("animationSpeed") || defaultColors.animationSpeed,
    };

    // Aplicar CSS variables
    document.documentElement.style.setProperty(
      "--virusFillColor",
      settings["--virusFillColor"],
    );
    document.documentElement.style.setProperty(
      "--virusBorderColor",
      settings["--virusBorderColor"],
    );
    ColorManager.Current.Gold = settings.colorGold;
    ColorManager.Current.Prize = settings.colorPrize;

    // Rellenar inputs
    $('[type="color"]').each(function () {
      const label = $(this)
        .closest(".estiloextspe")
        .find("span:first")
        .text()
        .trim()
        .toUpperCase();
      switch (label) {
        case "VIRUS":
          this.value = settings["--virusFillColor"];
          break;
        case "VIRUS BORDE":
          this.value = settings["--virusBorderColor"];
          break;
        case "GOLD":
          this.value = settings.colorGold;
          break;
        case "PRIZE":
          this.value = settings.colorPrize;
          break;
      }
    });

    $("#animationSpeed").val(settings.animationSpeed);
    $("#animationSpeed").siblings(".sliderValue").text(settings.animationSpeed);
  }
  applySettings();

  // Toggle menú
  $("#toggleMenu").on("click", () => $("#colorOptions").slideToggle(300));

  // Actualizar valor y guardar al mover slider
  $(document).on("input", ".customSlider", function () {
    const val = $(this).val();
    localStorage.setItem("animationSpeed", val);
    rawSpeed = parseFloat(val);
    $(this)
      .siblings(".sliderValue")
      .fadeOut(100, function () {
        $(this).text(val).fadeIn(100);
      });
  });

  // Guardar color al pulsar "APLICAR"
  $(document).on("click", ".btnxtsproxteeq", function () {
    const $parent = $(this).closest(".estiloextspe");
    const label = $parent.find("span:first").text().trim().toUpperCase();
    const color = $parent.find('input[type="color"]').val();

    switch (label) {
      case "VIRUS":
        document.documentElement.style.setProperty("--virusFillColor", color);
        localStorage.setItem("virusFillColor", color);
        break;
      case "VIRUS BORDE":
        document.documentElement.style.setProperty("--virusBorderColor", color);
        localStorage.setItem("virusBorderColor", color);
        break;
      case "GOLD":
        ColorManager.Current.Gold = color;
        localStorage.setItem("colorGold", color);
        break;
      case "PRIZE":
        ColorManager.Current.Prize = color;
        localStorage.setItem("colorPrize", color);
        break;
    }
  });
});

Cell.prototype.drawOneCell_virus_ctx = (function () {
  const TWO_HUNDRED = 200;
  const getVar = (prop, def) =>
    getComputedStyle(document.documentElement).getPropertyValue(prop).trim() ||
    def;

  return function (ctx = window.ctx) {
    if (!ctx) return;
    if (this.size <= 0) return; // Evita dibujar si tamaño no válido

    if (options.get("transparentRende") == true) {
      ctx.globalAlpha = 0.3;
    } else {
      ctx.globalAlpha = 0.5;
    }

    const currentFps = fpsManager.fps;
    const borderColor = getVar(
      "--virusBorderColor",
      "virusBorderColor",
      "#15ff00",
    );
    const fillColor = getVar("--virusFillColor", "virusFillColor", "#00ff00");
    const shadowColor =
      getVar("--virusShadowColor", "virusShadowColor", "#00ff00") + "88";

    ctx.save();
    ctx.strokeStyle = borderColor;
    ctx.fillStyle = fillColor;
    ctx.shadowColor = shadowColor;
    ctx.shadowBlur =
      10 + Math.abs(Math.sin(performance.now() / TWO_HUNDRED)) * 10;
    ctx.beginPath();
    this.drawSimple(ctx);
    ctx.closePath();
    ctx.fill(); // <- AÑADE ESTO PARA RELLENAR CON COLOR
    ctx.lineWidth = 20;
    ctx.stroke();

    ctx.restore();
  };
})();

// rawSpeed: velocidad de animación controlada por el slider ANIMACION (0-100, default 50)
var rawSpeed = parseFloat(localStorage.getItem("animationSpeed")) || 50;

Cell.prototype.updatePos = function () {
  const speedFactor = Math.min(Math.max(rawSpeed / 25, 0.6), 4);
  var _0x391b55 = a0_0xd5638d,
    _0x32c2b = new Date()[_0x391b55(0x1ab)]() - updateNodes2_last,
    _0x4052de;
  options[_0x391b55(0x22a)](_0x391b55(0x142)) == !![]
    ? (_0x4052de = _0x32c2b / updateNodes2_span)
    : (_0x4052de = (timestamp - this["updateTime"]) / 0x78 / speedFactor);
  if (_0x4052de < 0x0) _0x4052de = 0x0;
  else _0x4052de > 0x1 && (_0x4052de = 0x1);
  ((this[_0x391b55(0xbe)] =
    _0x4052de * (this[_0x391b55(0x97)] - this[_0x391b55(0x3e4)]) +
    this[_0x391b55(0x3e4)]),
    (this[_0x391b55(0x40c)] =
      _0x4052de * (this[_0x391b55(0x22e)] - this[_0x391b55(0x1cd)]) +
      this["y_old"]),
    (this[_0x391b55(0x223)] =
      _0x4052de * (this[_0x391b55(0x2a6)] - this[_0x391b55(0x99)]) +
      this[_0x391b55(0x99)]),
    debug_pos == 0x1 &&
      this[_0x391b55(0xcc)][_0x391b55(0x422)]({
        x: this[_0x391b55(0xbe)],
        y: this["y_draw"],
        r: _0x4052de,
        s: _0x32c2b,
        ns: updateNodes2_span,
      }),
    this["tailDbg"][_0x391b55(0x3c6)] > 0x3e8 &&
      this["tailDbg"][_0x391b55(0xb9)]());
};

//color del fondo y de las celulas del juego
ColorManager.Current.Grid = "black";
var YeniRenkKodu = "black";
var Yapılmasıgereken = CanvasRenderingContext2D.prototype.fillRect;
CanvasRenderingContext2D.prototype.fillRect = function () {
  var x = arguments[0];
  var y = arguments[1];
  var w = arguments[2];
  var h = arguments[3];

  if (x == 0 && y == 0 && w == this.canvas.width && h == this.canvas.height) {
    this.fillStyle = YeniRenkKodu;
  }

  return Yapılmasıgereken.apply(this, arguments);
};

/////////////////////////////////////FUNCIONES DEL JUEGO/////////////////////////////////////
let topMessage4 = "";
let presionandoG = false;

document.addEventListener("keydown", function (e) {
  if (e.keyCode === 71 && $("input:focus").length === 0) {
    if (presionandoG) {
      detenerAutoplay();
    } else {
      iniciarAutoplay();
    }
  }
});

$("#gamemode").on("change", function () {
  if (presionandoG) {
    simularDetener();
    setTimeout(() => {
      iniciarAutoplay();
    }, 200);
  }
});

function simularDetener() {
  presionandoG = false;
}

function detenerAutoplay() {
  presionandoG = false;
  topMessage4 = "";
}

function iniciarAutoplay() {
  presionandoG = true;
  topMessage4 = "Autoplay Activado";
  onClickPlay();
}
const originalHandleWsMessage = window.handleWsMessage;

window.handleWsMessage = function (messageBuffer) {
  const opcode = messageBuffer.getUint8(0);

  if (opcode === OPCODE_S2C_SHOW_MESSAGE) {
    return;
  }

  if (opcode === OPCODE_S2C_INFO) {
    const infoType = messageBuffer.getInt32(1, true);

    if (infoType === INFO_YOU_DEAD) {
      console.log("[INFO] Moriste.");

      closeFullscreen();
      sendUint8(OPCODE_C2S_EMITFOOD_STOP);
      playMode = PLAYMODE_NONE;
      playerId = -1;
      spectatorId = -1;
      isLockMouse = 0;
      isLockFood = 0;

      if (presionandoG) {
        console.log("[Autoplay] Activado");
        onClickPlay();
      }

      return;
    }
  }

  originalHandleWsMessage(messageBuffer);
};

window.sendStart = function () {
  if (clientVersion === serverVersion) {
    sendLang();

    const token = localStorage.userToken;
    if (token != null && token.length === 32) {
      // — token válido: enviamos y salimos
      const packet = prepareData(1 + token.length * 2);
      packet.setUint8(0, OPCODE_C2S_SET_TOKEN);
      let offset = 1;
      for (let i = 0; i < token.length; i++) {
        packet.setUint16(offset, token.charCodeAt(i), true);
        offset += 2;
      }
      wsSend(packet);
      return;
    }

    // — sin token, elegimos PLAY o SPECTATE según el estado o la tecla H
    if (presionandoG) {
      // jugador quiere entrar jugando
      playMode = PLAYMODE_PLAY; // ← lo añadimos
      sendUint8(OPCODE_C2S_PLAY_AS_GUEST_REQUEST);
    } else if (playMode === PLAYMODE_SPECTATE) {
      // jugador quiere entrar en modo espectador
      playMode = PLAYMODE_SPECTATE; // ← lo añadimos
      spectatorId = -1;
      spectatorPlayer = null;
      if (isAdminSafe()) {
        sendAdminSpectate();
      } else {
        sendUint8(OPCODE_C2S_SPECTATE_REQUEST);
      }
    } else {
      // caso por defecto: sin token, sin H y no estabas ya en SPECTATE
      playMode = PLAYMODE_PLAY; // ← y aquí también
      sendUint8(OPCODE_C2S_PLAY_AS_GUEST_REQUEST);
    }
  } else if (serverVersion !== 0) {
    const errorMsg = trans[0x10a];
    showGeneralError(errorMsg, `C:${clientVersion} vs S:${serverVersion}`);
  }
};

let pendingMessages = [];

window.wsSend = function (messageObj) {
  const payload = messageObj.buffer;

  if (!ws) {
    console.error("wsSend falló: instancia de WebSocket no inicializada.");
    return;
  }

  switch (ws.readyState) {
    case WebSocket.OPEN:
      try {
        ws.send(payload);
      } catch (error) {
        console.error("Error al enviar mensaje por WebSocket:", error);
      }
      break;

    case WebSocket.CONNECTING:
      console.warn("WebSocket conectando, encolando mensaje.");
      pendingMessages.push(messageObj);
      if (!ws.__esperandoConectar) {
        ws.__esperandoConectar = true;
        ws.addEventListener(
          "open",
          () => {
            while (pendingMessages.length > 0) {
              const msg = pendingMessages.shift();
              try {
                ws.send(msg.buffer);
              } catch (error) {
                console.error("Error al enviar mensaje pendiente:", error);
              }
            }
            ws.__esperandoConectar = false;
          },
          { once: true },
        );
      }
      break;

    case WebSocket.CLOSING:
      console.warn("wsSend: WebSocket está cerrándose; mensaje no enviado.");
      break;

    case WebSocket.CLOSED:
      console.warn("wsSend: WebSocket cerrado; mensaje no enviado.");
      break;

    default:
      console.warn("wsSend: estado de WebSocket inesperado:", ws.readyState);
  }
};

window.addEventListener("keydown", keydown);
var imlost = 25,
  macrosRunning = !1,
  macroTimeouts = [];

function keydown(e) {
  if (e.keyCode === 70 && $("input:focus").length === 0) reaparecer();
  if (e.keyCode === 67 && $("input:focus").length === 0)
    macrosRunning ? stopMacros() : startMacros();
  if (e.keyCode === 66 && $("input:focus").length === 0) sabit();
  if (e.keyCode === 78 && $("input:focus").length === 0) {
    dikey();
    split();
  }
  if (e.keyCode === 77 && $("input:focus").length === 0) {
    yanlama();
    split();
  }
}

function startMacros() {
  ((macrosRunning = !0), presionarTeclasInfinitasVeces(), macroZ(), macroX());
}

function stopMacros() {
  macrosRunning = !1;
  for (var e = 0; e < macroTimeouts.length; e++) clearTimeout(macroTimeouts[e]);
  ((macroTimeouts = []),
    $("body").trigger(
      $.Event("keyup", {
        keyCode: 83,
      }),
    ),
    $("body").trigger(
      $.Event("keyup", {
        keyCode: 65,
      }),
    ),
    $("body").trigger(
      $.Event("keyup", {
        keyCode: 90,
      }),
    ),
    $("body").trigger(
      $.Event("keyup", {
        keyCode: 88,
      }),
    ));
}

function presionarTeclasInfinitasVeces() {
  intervalID = setInterval(function () {
    if (presionandoG) {
      let e = new KeyboardEvent("keydown", {
        keyCode: 65,
      });
      document.dispatchEvent(e);
      let n = new KeyboardEvent("keyup", {
        keyCode: 65,
      });
      document.dispatchEvent(n);
      let o = new KeyboardEvent("keydown", {
        keyCode: 83,
      });
      document.dispatchEvent(o);
      let t = new KeyboardEvent("keyup", {
        keyCode: 83,
      });
      document.dispatchEvent(t);
    } else clearInterval(intervalID);
  }, 100);
}

function macroZ() {
  macrosRunning &&
    $("body").trigger(
      $.Event("keydown", {
        keyCode: 90,
      }),
    );
}

function macroX() {
  macrosRunning &&
    $("body").trigger(
      $.Event("keydown", {
        keyCode: 88,
      }),
    );
}

function reaparecer() {
  wsClose();

  skipPopupOnClose = true;
  reconnect = 1;
  cellManager.drawMode = DRAWMODE_NORMAL;
  userScoreCurrent = 0;
  userScoreMax = 0;
  playMode = PLAYMODE_PLAY;

  if (autoplayActivo) {
    // Si estaba activo antes, lo reiniciamos
    setTimeout(() => iniciarAutoplay(), 100);
  }
}

function sabit() {
  let e = window.innerWidth / 2,
    n = window.innerHeight / 2,
    o = document.querySelectorAll("canvas");
  o.forEach((o) => {
    o.dispatchEvent(
      new MouseEvent("mousemove", {
        clientX: e,
        clientY: n,
      }),
    );
  });
}

function yanlama() {
  ((X = window.innerWidth / 0),
    (Y = window.innerHeight / 25),
    $("canvas").trigger(
      $.Event("mousemove", {
        clientX: X,
        clientY: Y,
      }),
    ));
}

function dikey() {
  ((X = window.innerWidth / 25),
    (Y = window.innerHeight / 0),
    $("canvas").trigger(
      $.Event("mousemove", {
        clientX: X,
        clientY: Y,
      }),
    ));
}

function split() {
  ($("body").trigger(
    $.Event("keydown", {
      keyCode: 32,
    }),
  ),
    $("body").trigger(
      $.Event("keyup", {
        keyCode: 32,
      }),
    ));
}

//draw Borde
(function () {
  var rotationAngle = 0;
  var glowIntensity = 0.5;
  var glowDirection = 1;

  window.drawBorder = function () {
    switch (renderMode) {
      case RENDERMODE_CTX:
        var centerX = (leftPos + rightPos) / 2;
        var centerY = (topPos + bottomPos) / 2;
        var maxRadius = Math.max(rightPos - leftPos, bottomPos - topPos) / 2;

        var cosA = Math.cos(rotationAngle);
        var sinA = Math.sin(rotationAngle);
        var x1 = centerX + maxRadius * cosA;
        var y1 = centerY + maxRadius * sinA;
        var x2 = centerX + maxRadius * Math.cos(rotationAngle + Math.PI);
        var y2 = centerY + maxRadius * Math.sin(rotationAngle + Math.PI);

        var gradientOffset = sinA * 0.5;

        var borderGradient = ctx.createLinearGradient(
          x1 + gradientOffset,
          y1 + gradientOffset,
          x2 - gradientOffset,
          y2 - gradientOffset,
        );

        borderGradient.addColorStop(0.0, "rgb(0, 255, 255)");
        borderGradient.addColorStop(0.17, "rgb(0, 128, 255)");
        borderGradient.addColorStop(0.33, "rgb(0, 255, 128)");
        borderGradient.addColorStop(0.5, "rgb(255, 255, 0)");
        borderGradient.addColorStop(0.67, "rgb(255, 128, 0)");
        borderGradient.addColorStop(0.77, "rgb(255, 0, 255)");
        borderGradient.addColorStop(0.87, "rgb(255, 0, 128)");

        borderGradient.addColorStop(1.0, "rgb(0, 255, 255)");
        ctx.save();
        ctx.shadowColor = `rgba(220, 220, 220, ${glowIntensity})`;
        ctx.shadowBlur = 15;
        ctx.shadowOffsetX = 0;
        ctx.shadowOffsetY = 0;
        const MAX_LINE_WIDTH = 400;
        const MIN_LINE_WIDTH = 300;
        ctx.lineWidth = Math.max(
          Math.min(70 / cameraManager.scale, MAX_LINE_WIDTH),
          MIN_LINE_WIDTH,
        );
        ctx.strokeStyle = borderGradient;
        ctx.globalAlpha = 1;
        ctx.beginPath();
        ctx.rect(leftPos, topPos, rightPos - leftPos, bottomPos - topPos);
        ctx.stroke();
        ctx.restore();
        if (cameraManager.zoom > 0.07) {
          ctx.beginPath();
          ctx.strokeStyle = "rgba(255, 255, 255, 0.3)";
          ctx.lineWidth = 1;
          for (var x = leftPos; x <= rightPos; x += 100) {
            ctx.moveTo(x, topPos);
            ctx.lineTo(x, bottomPos);
          }
          for (var y = topPos; y <= bottomPos; y += 100) {
            ctx.moveTo(leftPos, y);
            ctx.lineTo(rightPos, y);
          }
          ctx.stroke();
        }
        break;

      case RENDERMODE_GL:
        prog_background.draw();
        break;
    }

    glowIntensity += 0.01 * glowDirection;
    if (glowIntensity >= 0.5 || glowIntensity <= 0.2) {
      glowDirection *= -1;
    }

    var speedIncrement = 0.0019;
    rotationAngle += speedIncrement;
  };
})();
//funcion para guardar el estado del cehck mostrar-id el codigo en el juego
function initializeMostrarId() {
  const checkbox = document.getElementById("mostrar-id");
  const storedValue = localStorage.getItem("mostrar-id");
  if (checkbox) {
    if (storedValue === null) {
      localStorage.setItem("mostrar-id", "false");
      checkbox.checked = false;
    } else {
      checkbox.checked = storedValue === "true";
    }
  }
}
initializeMostrarId();
const checkbox = document.getElementById("mostrar-id");
if (checkbox) {
  checkbox.addEventListener("change", function () {
    localStorage.setItem("mostrar-id", this.checked.toString());
  });
}

document.addEventListener("keydown", function (event) {
  if (event.key === "Escape") {
    let dialog = document.getElementById("finalLeaderboardDialog");
    if (dialog) {
      dialog.style.display = "none";
    }
  }
});

let topMessage5 = "";
let topMessage6 = "";

function obtenerJugadorConMasMasa() {
  const celulas = cellManager.getCellList();
  if (!Array.isArray(celulas)) return null;

  const masaPorJugador = {};
  const celdasPorJugador = {};

  // ----- Recorremos todas las celdas -----
  celulas.forEach((cell) => {
    if (cell.cellType !== CELLTYPE_PLAYER) return;

    const id = String(cell.pID);
    const score = parseFloat(cell.getScore()) || 0;

    masaPorJugador[id] = (masaPorJugador[id] || 0) + score;
    (celdasPorJugador[id] = celdasPorJugador[id] || []).push(cell);
  });

  const jugadores = Object.keys(masaPorJugador);
  if (jugadores.length === 0) {
    topMessage6 = `Skor ffa: 0`;
    return null;
  }

  // ----- Calculamos la masa total de todos los jugadores -----
  const totalMasa = jugadores.reduce((sum, id) => sum + masaPorJugador[id], 0);
  topMessage6 = `Skor ffa: ${formatValue(totalMasa)}`;

  // ----- Ordenamos por masa -----
  jugadores.sort((a, b) => masaPorJugador[b] - masaPorJugador[a]);

  const topID = jugadores[0];
  const runnerUpID = jugadores[1] ?? null; // puede no existir
  const topScore = masaPorJugador[topID];
  const runnerScore = runnerUpID ? masaPorJugador[runnerUpID] : 0;

  // Ventaja relativa (se usa solo para calcular el estado)
  const ventajaPct = runnerScore
    ? ((topScore - runnerScore) / runnerScore) * 100
    : 100; // único jugador

  // Estado en función de la ventaja
  let estado = "👑 Dominando";
  if (ventajaPct < 20) estado = "🛑 Amenazado";
  else if (ventajaPct < 50) estado = "⚠️ Parejo";

  // Celda mayor (para nombre/skin)
  const topCell = celdasPorJugador[topID].reduce((maxCell, cell) =>
    (parseFloat(cell.getScore()) || 0) > (parseFloat(maxCell.getScore()) || 0)
      ? cell
      : maxCell,
  );

  const nombre = topCell.name || "Sin nombre";
  const cantidadPartes = celdasPorJugador[topID].length;

  // ----- Mensaje final SOLO con los 4 campos solicitados -----
  topMessage5 =
    `Player: ${nombre}` +
    `  |  Skor: ${formatValue(topScore)}` +
    `  |  Partes: ${cantidadPartes}`;

  // Marcar sus celdas para resaltado
  celdasPorJugador[topID].forEach((c) => (c.isTop = true));

  return {
    pID: topID,
    name: nombre,
    score: topScore,
    partes: cantidadPartes,
    estado: estado,
  };
}

const mostrartop1 = document.getElementById("mostrar-top-1");

const TP_KEY = "Mostrartop1";

// 3) Inicializamos el estado leyendo localStorage
const saved2 = localStorage.getItem(TP_KEY);
if (saved2 !== null) {
  mostrartop1.checked = saved2 === "true";
}

// 4) Al cambiar el checkbox, lo guardamos
mostrartop1.addEventListener("change", () => {
  localStorage.setItem(TP_KEY, mostrartop1.checked);
});

const mostraridsla = document.getElementById("mostrar-skor-sala");

const LS_KEY = "mostrarTotalSala";

// 3) Inicializamos el estado leyendo localStorage
const saved = localStorage.getItem(LS_KEY);
if (saved !== null) {
  mostraridsla.checked = saved === "true";
}

// 4) Al cambiar el checkbox, lo guardamos
mostraridsla.addEventListener("change", () => {
  localStorage.setItem(LS_KEY, mostraridsla.checked);
});

(function () {
  window.drawTopMessage = function () {
    try {
      obtenerJugadorConMasMasa();
      const showTotal = localStorage.getItem(LS_KEY) === "true";
      const showTop1 = localStorage.getItem(TP_KEY) === "true";
      // 1) Construimos el array inicial de mensajes
      const baseMsgs = [
        {
          text: topMessage1,
          colorFunc: getFluorescentGreen,
          position: "bottom",
        },
        { text: topMessage3, colorFunc: getFluorescentGreen, position: "top" },
        {
          text: topMessage2,
          colorFunc: getFluorescentGreen,
          position: "bottom",
        },
      ];
      if (showTop1 && topMessage5.trim()) {
        baseMsgs.push({
          text: topMessage5,
          colorFunc: getBlueGradient,
          position: "top",
        });
      }
      if (showTotal && topMessage6.trim()) {
        baseMsgs.push({
          text: topMessage6,
          colorFunc: getGoldGlow,
          position: "top",
        });
      }
      baseMsgs.push({
        text: topMessage4,
        colorFunc: getElectricBlue,
        position: "top",
      });
      const messages = baseMsgs.filter((m) => m.text && m.text.trim());
      function getGoldGlow() {
        const t = Date.now() * 0.006;
        const r = 255;
        const g = Math.floor(200 + Math.sin(t) * 40); // amarillo cálido que brilla
        const b = Math.floor(40 + Math.cos(t) * 30); // ligero tono cálido
        return `rgb(${r},${g},${b})`;
      }

      // 3) Función que dibuja todos los mensajes top y bottom, y devuelve el Y final
      function drawMessages(ctx, yTopStart, lineHeight) {
        const topMsgs = messages.filter((m) => m.position === "top");
        const bottomMsgs = messages.filter((m) => m.position === "bottom");

        // Dibuja top de arriba hacia abajo
        let y = yTopStart;
        for (const m of topMsgs) {
          drawSingle(ctx, m, y);
          y += lineHeight;
        }

        // Dibuja bottom de abajo hacia arriba
        let yBot = ctx.canvas.height - 10;
        for (let i = bottomMsgs.length - 1; i >= 0; i--) {
          drawSingle(ctx, bottomMsgs[i], yBot);
          yBot -= lineHeight;
        }

        return y;
      }

      // 4) Función auxiliar inalterada
      function drawSingle(ctx, { text, colorFunc }, y) {
        ctx.save();
        ctx.font = "17px Ubuntu";
        ctx.globalAlpha = 1;

        const width = ctx.measureText(text).width;
        const x = (ctx.canvas.width - width) / 2;

        if (colorFunc) {
          ctx.shadowBlur = 8 + Math.sin(Date.now() * 0.006) * 4;
          ctx.shadowColor = "rgba(220,220,220,0.5)";
          ctx.fillStyle = colorFunc(ctx, x, y, width);
        } else {
          ctx.fillStyle = "#39ff14";
        }

        ctx.fillText(text, x, y);
        ctx.restore();
      }

      function getRedOrangeGradient(ctx, x3, y3, width) {
        try {
          if (
            !ctx ||
            typeof x3 !== "number" ||
            typeof y3 !== "number" ||
            typeof width !== "number"
          ) {
            console.error(
              "Error en getRedOrangeGradient: parámetros inválidos",
            );
            return "#f00";
          }
          const t = Date.now() * 0.002;
          const startX = Math.max(0, x3 - 50);
          const endX = Math.min(ctx.canvas.width, x3 + width + 50);

          const gradient = ctx.createLinearGradient(startX, y3, endX, y3);
          gradient.addColorStop(0, `hsl(${(t * 40) % 360}, 100%, 60%)`);
          gradient.addColorStop(0.5, `hsl(${(t * 40 + 30) % 360}, 100%, 65%)`);
          gradient.addColorStop(1, `hsl(${(t * 40 + 60) % 360}, 100%, 70%)`);

          return gradient;
        } catch (error) {
          console.error("Error en getRedOrangeGradient:", error);
          try {
            return (
              ctx?.createLinearGradient?.(0, y3 || 0, 100, y3 || 0) || "#f00"
            );
          } catch {
            return "#f00";
          }
        }
      }

      function getBlueGradient(ctx, x3, y3, width) {
        try {
          if (
            !ctx ||
            typeof x3 !== "number" ||
            typeof y3 !== "number" ||
            typeof width !== "number"
          ) {
            console.error("Error en getBlueGradient: parámetros inválidos");
            return "#00f";
          }

          const t = Date.now() * 0.002;

          const startX = Math.max(0, x3 - 50);
          const endX = Math.min(ctx.canvas.width, x3 + width + 50);

          const gradient = ctx.createLinearGradient(startX, y3, endX, y3);
          gradient.addColorStop(0, `hsl(${(t * 120) % 360}, 100%, 65%)`);
          gradient.addColorStop(0.5, `hsl(${(t * 120 + 90) % 360}, 100%, 70%)`);
          gradient.addColorStop(1, `hsl(${(t * 120 + 180) % 360}, 100%, 65%)`);

          return gradient;
        } catch (error) {
          console.error("Error en getBlueGradient:", error);
          try {
            return (
              ctx?.createLinearGradient?.(0, y3 || 0, 100, y3 || 0) || "#00f"
            ); // Azul por defecto si falla todo
          } catch {
            return "#00f"; // Fallback final si incluso eso falla
          }
        }
      }
      function getElectricBlue() {
        try {
          const t = Date.now() * 0.006;
          const r = Math.floor(60 + Math.sin(t) * 40); // más bajo para resaltar el azul
          const g = Math.floor(180 + Math.cos(t) * 50); // un verde claro pulsante
          const b = Math.floor(255 - Math.sin(t) * 20); // mantener azul intenso
          return `rgb(${r},${g},${b})`;
        } catch (error) {
          console.error("Error en getElectricBlue:", error);
          return "rgb(0, 0, 255)"; // Valor por defecto en caso de error
        }
      }
      function getFluorescentGreen() {
        try {
          // velocidad de pulso (ajusta si lo quieres más rápido/lento)
          const t = Date.now() * 0.005;
          // lightness oscila entre 40% y 70%
          const lightness = 55 + Math.sin(t) * 15;
          // devolvemos en HSL para garantizar todo el rango de “fluor”
          return `hsl(120, 100%, ${lightness}%)`;
        } catch (error) {
          console.error("Error en getFluorescentGreen(HSL):", error);
          // Verde puro estándar si algo falla
          return "hsl(120, 100%, 55%)";
        }
      }

      const timeFactor = Date.now() * 0.002;

      // Devuelve un color dinámico basado en el tiempo (para el texto)
      function getDynamicColor() {
        const r = Math.sin(timeFactor) * 127 + 128;
        const g = Math.sin(timeFactor + 2) * 127 + 128;
        const b = Math.sin(timeFactor + 4) * 127 + 128;
        return `rgb(${r},${g},${b})`;
      }

      // Devuelve un tamaño de fuente dinámico (en píxeles)
      function getDynamicFontSize() {
        const t = Date.now() * 0.005;
        return 20 + Math.sin(t) * 1; // Resultado entre 19 y 21 aproximadamente
      }

      // Otra función de color dinámico, que se usará para la sombra
      function getDynamicShadowColor() {
        const r = Math.sin(timeFactor) * 127 + 128;
        const g = Math.sin(timeFactor + 2) * 127 + 128;
        const b = Math.sin(timeFactor + 4) * 127 + 128;
        return `rgb(${r},${g},${b})`;
      }

      switch (renderMode) {
        case RENDERMODE_CTX:
          // Dentro de tu función de dibujo:
          ctx.font = '17px "Playfair Display", serif';

          ctx.globalAlpha = 1;
          ctx.fillStyle = "#39ff14";

          const staticMessages = messages.filter((m) => m.text !== trans[308]);
          const yAfterMessages = drawMessages(ctx, 85, 26, staticMessages);
          if (countdown > 0 && countdown <= 26) {
            ctx.save();
            const bigSize = getDynamicFontSize() * 1.01;
            ctx.font = bigSize + "px Ubuntu";
            ctx.fillStyle = getDynamicColor();
            ctx.shadowBlur = 12;
            ctx.shadowColor = getDynamicShadowColor();
            const text = "ULTIMOS SEGUNDOS";
            const width = ctx.measureText(text).width;
            const x = (ctx.canvas.width - width) / 2;
            const y = yAfterMessages + 26 + 10;

            ctx.fillText(text, x, y);
            ctx.restore();
          }
          break;

        case RENDERMODE_GL:
          // Igual para GL si lo necesitas…
          break;
      }
    } catch (error) {
      console.error("Error en drawTopMessage:", error);
    }
  };
})();

window.drawAutoBigTime = function (x, y) {
  if (autoBigTime <= 0) return;

  var fontSize = 20;
  var text = trans[329] + " " + secToTime(autoBigTime);

  switch (renderMode) {
    case RENDERMODE_CTX:
      ctx.fillStyle = "#f5f500";
      ctx.font = "bold 15px 'Poppins', sans-serif";
      ctx.fillText(text, x, y);
      break;
    case RENDERMODE_GL:
      prog_font.drawText(
        x,
        y,
        ColorManager.Current_RGB_GL.AutoBig,
        1,
        fontSize,
        text,
      );
      break;
  }
};
window.drawGoldToPrize = function (x, y) {
  if (goldToPrizeTime > 0) {
    var fontSize = 20;
    var text = trans[328] + " " + secToTime(goldToPrizeTime);
    switch (renderMode) {
      case RENDERMODE_CTX:
        ctx["fillStyle"] = "#f5f500";
        ctx.font = "bold 15px 'Poppins', sans-serif";
        ctx.fillText(text, x, y);
        break;
      case RENDERMODE_GL:
        prog_font.drawText(
          x,
          y,
          ColorManager.Current_RGB_GL.GoldToPrize,
          1,
          fontSize,
          text,
        );
        break;
    }
  }
};

function drawMovePoint() {
  if (!isMobile) return;
  if (playMode != PLAYMODE_PLAY) return;

  switch (renderMode) {
    case RENDERMODE_CTX:
      let movePoint = cameraManager.getMovePoint();
      let radius = 5 / cameraManager.zoomLevel;

      ctx.globalAlpha = 1;
      ctx.fillStyle = ColorManager.Current.MovePoint;
      ctx.beginPath();
      ctx.arc(movePoint.x, movePoint.y, radius, 0, 2 * Math.PI, false);
      ctx.fill();
      break;

    case RENDERMODE_GL:
      prog_rect.draw(
        rawMouseX,
        rawMouseY,
        5,
        5,
        ColorManager.Current.MovePoint,
        1,
      );
      break;
  }
}

function drawLeaderboard() {
  let leaderboardData = leaderBoard;

  if (
    cellManager.drawMode == DRAWMODE_REPLAY_PLAY ||
    cellManager.drawMode == DRAWMODE_REPLAY_STOP
  ) {
    let replayData = cellManager.getReplayItem();
    if (replayData != null) {
      leaderboardData = replayData.leaderBoard;
    }
  }

  let fontSize = isMobile ? 12 : 13.5;
  let maxEntries = isMobile
    ? leaderboardData.length < 5
      ? leaderboardData.length
      : 5
    : leaderboardData.length;
  let boxWidth = fontSize * 13;
  let centerX = boxWidth * 0.5;
  let boxHeight = fontSize * 4 + fontSize * 1.2 * maxEntries;
  let startX = mainCanvas.width - boxWidth;
  let startY = isMobile ? (mainCanvas.width > mainCanvas.height ? 0 : 150) : 0;
  let opacity = 0.3;

  switch (renderMode) {
    case RENDERMODE_CTX:
      let previousFillStyle = ctx.fillStyle;
      ctx.globalAlpha = opacity;

      // Elimina ctx.fillRect para evitar el fondo sólido y permitir transparencia
      ctx.globalAlpha = 1;
      ctx.fillStyle = ColorManager.Current.Leaderboard_Text;
      ctx.font = fontSize + "px Ubuntu";
      ctx.fillText(
        lastWinner,
        startX + centerX - ctx.measureText(lastWinner).width / 2,
        startY + fontSize * 2,
      );

      let yOffset = 0;
      for (let i = 0; i < maxEntries; i++) {
        let entry = leaderboardData[i];
        let playerName = entry.name != null ? entry.name.trim() : "AgarZ.com";

        if (playerName === "") playerName = "AgarZ.com";

        let displayName = noRanking ? playerName : `${i + 1}. ${playerName}`;
        let textWidth = ctx.measureText(displayName).width;

        if (entry.id === spectatorId) {
          ctx.fillStyle = ColorManager.Current.Leaderboard_Spectator;
        } else if (entry.id === playerId) {
          ctx.fillStyle = ColorManager.Current.Leaderboard_Player;
        } else {
          ctx.fillStyle = ColorManager.Current.Leaderboard_Default;
          let extraInfo = getLeaderboardExt(entry.id);
          if (extraInfo != null) {
            if (extraInfo.sameTeam === 1) {
              ctx.fillStyle = ColorManager.Current.Name_SameTeamOnList;
            } else if (extraInfo.sameClan === 1) {
              ctx.fillStyle = ColorManager.Current.Name_SameClanOnList;
            }
          }
        }

        yOffset = startY + fontSize * 4 + fontSize * 1.2 * i;
        entry.draw_x = mainCanvas.width - boxWidth + centerX - textWidth / 2;
        entry.draw_y = yOffset;
        entry.draw_w = textWidth;
        entry.draw_h = fontSize;

        ctx.fillText(displayName, entry.draw_x, entry.draw_y);
      }

      if (leaderboardIndex >= maxEntries && playMode === PLAYMODE_PLAY) {
        let playerEntry = `${leaderboardIndex + 1}. ${playerName}`;
        let textWidth = ctx.measureText(playerEntry).width;
        let posX = mainCanvas.width - boxWidth + centerX - textWidth / 2;
        yOffset += fontSize;

        ctx.fillStyle = ColorManager.Current.Leaderboard_Player;
        ctx.fillText(playerEntry, posX, yOffset);
      }

      ctx.fillStyle = previousFillStyle;
      break;
    case RENDERMODE_GL:
      return;

      break;
  }
}

window.drawTimerAndRecord = function (y, fontSizex, padding) {
  try {
    var fontSize = 22;
    var countdownTime = countdown;
    if (
      cellManager.drawMode == DRAWMODE_REPLAY_PLAY ||
      cellManager.drawMode == DRAWMODE_REPLAY_STOP
    ) {
      var replayItem = cellManager.getReplayItem();
      if (replayItem != null) {
        countdownTime = replayItem.countdown;
      }
    }
    var timerText = "";
    if (typeof this.gameName !== "undefined" && this.gameName != null) {
      timerText += this.gameName + " ";
    }
    timerText += "[" + secToTime(countdownTime) + "]";
    ctx.font = fontSize + "px Ubuntu";
    var textWidth = ctx.measureText(timerText).width;
    var bgColor = "#0000";
    var textX = (mainCanvas.width - textWidth) * 0.5;
    var bgAlpha = 0.4;

    switch (renderMode) {
      case RENDERMODE_CTX:
        // Dibuja el fondo
        ctx.globalAlpha = bgAlpha;
        ctx.fillStyle = bgColor;
        ctx.fillRect(
          textX - padding,
          y,
          textWidth + padding * 2,
          fontSize + padding * 2,
        );
        ctx.globalAlpha = 1;

        // Dibuja el timer en azul claro con sombra del mismo color
        ctx.save();
        ctx.shadowColor = "#3374FF"; // Sombra en azul
        ctx.shadowBlur = 10; // Ajusta el blur según tu preferencia
        ctx.fillStyle = "#3374FF";
        ctx.fillText(timerText, textX, y + fontSize);
        ctx.restore();

        if (recordHolder.length > 0) {
          y += fontSize + 2 * padding;
          var recordWidth = ctx.measureText(recordHolder).width;
          var recordX = (mainCanvas.width - recordWidth) * 0.5;
          ctx.globalAlpha = bgAlpha;
          ctx.fillStyle = bgColor;
          ctx.fillRect(
            recordX - padding,
            y,
            recordWidth + padding * 2,
            fontSize + padding,
          );
          ctx.globalAlpha = 1;
          // Dibuja el record en amarillo medio apagado con sombra del mismo color
          ctx.save();
          ctx.shadowColor = "#FFFF00"; // Sombra en amarillo
          ctx.shadowBlur = 10; // Ajusta según prefieras
          ctx.fillStyle = "#FFFF00";
          ctx.fillText(recordHolder, recordX, y + fontSize);
          ctx.restore();
        }
        break;

      case RENDERMODE_GL:
        prog_rect.draw(
          textX - padding,
          y,
          textWidth + padding * 2,
          fontSize + padding * 2,
          ColorManager.Current_RGB_GL.TimerAndRecord_BG,
          0.2,
        );
        prog_font.drawUI(
          textX,
          y + fontSize,
          ColorManager.Current_RGB_GL.TimerAndRecord_Timer,
          1,
          fontSize,
          timerText,
        );
        if (recordHolder.length > 0) {
          y += fontSize + 2 * padding;
          var recordWidth = prog_font.getTextWidth(recordHolder) * fontSize;
          var recordX = (mainCanvas.width - recordWidth) * 0.5;
          prog_rect.draw(
            recordX - padding,
            y,
            recordWidth + padding * 2,
            fontSize + padding * 2,
            ColorManager.Current_RGB_GL.TimerAndRecord_BG,
            0.2,
          );
          prog_font.drawUI(
            recordX,
            y + fontSize,
            ColorManager.Current_RGB_GL.TimerAndRecord_Record,
            1,
            fontSize,
            recordHolder,
          );
        }
        break;
    }
  } catch (error) {}
};

function formatValue(value) {
  return value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".");
}

function drawTextWithSpacing(ctx, text, x, y, letterSpacing) {
  ctx.save();
  var letters = text.split("");
  var currentX = x;
  letters.forEach(function (letter) {
    ctx.fillText(letter, currentX, y);
    currentX += ctx.measureText(letter).width + letterSpacing;
  });
  ctx.restore();
}

window.drawLockMouse = function () {
  // Solo se dibuja si el mouse está bloqueado y estamos en modo de juego
  if (!(isLockMouse === 1 && playMode === PLAYMODE_PLAY)) {
    return;
  }

  // Calcula un valor oscilante para lograr un efecto pulsante
  const sineOffset = Math.sin(performance.now() * 0.005) * 5 + 5;
  const lineOffset = 50 + sineOffset; // Se suma a 50 para determinar el offset de la línea

  switch (renderMode) {
    case RENDERMODE_CTX:
      // Dibujo usando el contexto 2D
      ctx.save();
      ctx.globalAlpha = 1;
      ctx.shadowColor = "rgb(255, 69, 0)";
      ctx.shadowBlur = 20;
      ctx.strokeStyle = "rgb(255, 165, 0)";
      ctx.lineWidth = 50;

      // Dibuja dos líneas cruzadas en forma de "X"
      ctx.beginPath();
      ctx.moveTo(lockMouseX - lineOffset, lockMouseY - lineOffset);
      ctx.lineTo(lockMouseX + lineOffset, lockMouseY + lineOffset);
      ctx.moveTo(lockMouseX + lineOffset, lockMouseY - lineOffset);
      ctx.lineTo(lockMouseX - lineOffset, lockMouseY + lineOffset);
      ctx.stroke();

      // Dibuja líneas discontinuas desde cada célula del jugador hacia la posición de lockMouse
      ctx.lineWidth = 10;
      ctx.setLineDash([20, 10]);
      ctx.beginPath();
      for (let cell of cellManager.playerCellList) {
        ctx.moveTo(cell.x_draw, cell.y_draw);
        ctx.lineTo(lockMouseX, lockMouseY);
      }
      ctx.stroke();
      ctx.setLineDash([]); // Restablece el estilo de línea
      ctx.restore();
      break;

    case RENDERMODE_GL:
      // Dibujo usando WebGL (o una abstracción de él)
      let crossCoords = [
        lockMouseX - lineOffset,
        lockMouseY - lineOffset,
        lockMouseX + lineOffset,
        lockMouseY + lineOffset,
        lockMouseX + lineOffset,
        lockMouseY - lineOffset,
        lockMouseX - lineOffset,
        lockMouseY + lineOffset,
      ];
      prog_line.draw(
        0,
        0,
        crossCoords,
        false,
        ColorManager.Current_RGB_GL.LockMouse,
      );

      // Dibuja líneas desde cada célula del jugador hacia la posición de lockMouse
      crossCoords = [];
      for (let cell of cellManager.playerCellList) {
        crossCoords.push(cell.x_draw, cell.y_draw, lockMouseX, lockMouseY);
      }
      prog_line.draw(
        0,
        0,
        crossCoords,
        false,
        ColorManager.Current_RGB_GL.LockMouse,
      );
      break;
  }
};

let lastNameChangeTime = 0;
const minTimeBetweenChanges = 10;

function sendUserName() {
  var _0xfd1202 = _0x483156;
  var userName = document[_0xfd1202(0x3b1)](_0xfd1202(0x217))[_0xfd1202(0x23e)];
  const currentTime = new Date().getTime();
  if (
    currentTime - lastNameChangeTime >= minTimeBetweenChanges ||
    currentTime - lastNameChangeTime <= 0
  ) {
    var _0x1903a2 = prepareData(0x1 + 0x2 * userName.length);
    _0x1903a2[_0xfd1202(0x3ba)](0x0, OPCODE_C2S_SET_NAME);

    // Establecer el nombre
    for (var _0x721171 = 0x0; _0x721171 < userName.length; ++_0x721171) {
      _0x1903a2["setUint16"](
        0x1 + 0x2 * _0x721171,
        userName.charCodeAt(_0x721171),
        true,
      );
    }
    wsSend(_0x1903a2);
    lastNameChangeTime = currentTime;
  } else {
  }
}

// Alternar visibilidad con la tecla P
$(document).on("keydown", function (e) {
  if (e.key && e.key.toLowerCase() === "p") {
    // Asegurarse que e.key existe antes de usar .toLowerCase()
    const divglobal = $("#time-master");
    if (divglobal.is(":visible")) {
      divglobal.hide(); // Esconde el contenedor
    } else {
      divglobal.show(); // Muestra el contenedor
    }
  }
});

$(document).ready(function () {
  const CACHE_KEY = "tablaDatos";
  const INTERVALO_SOLICITUD = 7000;
  let temporizadorInterval = null;
  let timeoutActualizacion = null;
  let tiemposActuales = [];
  const divglobal = document.createElement("div");
  divglobal.id = "time-master";
  document.body.appendChild(divglobal);

  const style = document.createElement("style");
  style.innerHTML = `#time-master {
        position: fixed;
        top: 42vh; right: .5vw;
        display: flex; flex-direction: column;
        align-items: flex-end;
        background: rgba(0,0,0,0.5);
        padding: 8px;
        border-radius: 8px;
        box-shadow: 0 0 10px rgba(0,0,0,0.7);
        z-index: 9999;
        zoom: 88%;
        transition: opacity 0.4s ease, transform 0.3s ease;
    }
    #time-list::-webkit-scrollbar {
  width: 0 !important;
  height: 0 !important;

}
 #time-list{
     max-height: 400px;
    overflow-y: auto;
    overflow-x: hidden;
 }
    #time-master.oculto {
        opacity: 0;
        pointer-events: none;
        transform: translateX(10px);
    }
    #time-master .header {
        font-size: 13px;
        color: #ddd;
        margin-bottom: 6px;
        display: flex;
        align-items: center;
        gap: 8px;
        width: 100%;
    }
    #time-master .refresh-btn {
        background: transparent;
        border: none;
        color: #aaa;
        cursor: pointer;
        font-size: 1em;
    }
    #time-master .animated-button {
        font-size: 14px;
        border: none;
        background: #292929;
        color: white;
        padding: 5px 6px;
        margin: 2px;
        border-radius: 5px;
        cursor: pointer;
        transition: transform .2s, background .3s, opacity .2s;
        width: 130px;
        display: flex;
        align-items: center;
        gap: 6px;
    }
    #time-master .animated-button:hover {
        background: #161213;
    }

    #countdown {
        font-size: 11px;
        color: #aaa;
        margin-top: 4px;
    }
     #buscador-salas{
     }
 #buscador-salas:focus {
    border-color: #0af;
    box-shadow: 0 0 12px rgb(0 170 255 / 50%);
}
#buscador-salas {
    width: 132px;
    margin-bottom: 6px;
    padding: 6px;
    background: var(--btn-pro);
    border: 2px solid #444;
    border-radius: 10px;
    color: #fff;
    font-size: 16px;
    transition: box-shadow 0.3s ease-in-out;
    outline: none;
}`;
  document.head.appendChild(style);

  // Render inicial fijo (solo una vez)
  divglobal.innerHTML = `
        <div id="time-header" class="header">
            <span id="hora-actualizada">Actualizado: --:--</span>
            <button class="refresh-btn" title="Refrescar">
                <i class="fas fa-sync-alt"></i>
            </button>
        </div>
        <div id="time-search">
            <input type="text" id="buscador-salas" autocomplete="off" placeholder="Buscar sala...">
        </div>
        <div id="time-list"></div>
        <div id="countdown"></div>
    `;

  // Eventos fijos
  divglobal.querySelector(".refresh-btn").onclick = async () => {
    await obtenerTiempos();
    iniciarActualizaciones(INTERVALO_SOLICITUD); // Reanuda el ciclo limpio
    iniciarTemporizador(INTERVALO_SOLICITUD); // Reinicia el contador visual
  };

  document
    .getElementById("buscador-salas")
    .addEventListener("input", function () {
      const term = this.value.toLowerCase();
      const botones = divglobal.querySelectorAll(".animated-button");
      botones.forEach((btn) => {
        const texto = btn.textContent.toLowerCase();
        btn.style.display = texto.includes(term) ? "" : "none";
      });
    });

  async function obtenerTiempos() {
    try {
      const response = await fetch("https://agarz.com/tr/halloffame");
      if (!response.ok) throw new Error("Error al obtener la página");
      const html = await response.text();
      const doc = new DOMParser().parseFromString(html, "text/html");
      const filas = doc.querySelectorAll(".tr_oda");
      const tiempos = [];

      for (const fila of filas) {
        if (tiempos.length >= 12) break;
        const min = parseInt(fila.querySelector('span[id^="min_"]').innerText);
        const sec = parseInt(fila.querySelector('span[id^="sec_"]').innerText);
        let minutos = min,
          segundos = sec;
        if (segundos < 50) {
          minutos--;
          segundos += 60;
        }
        const tiempoTotal = minutos + segundos / 60;
        if (tiempoTotal >= 1 && tiempoTotal <= 10) {
          const texto = fila.querySelector("td").innerText;
          tiempos.push({ texto, tiempo: tiempoTotal.toFixed(2) });
        }
      }

      tiempos.sort((a, b) => a.tiempo - b.tiempo);
      localStorage.setItem(CACHE_KEY, JSON.stringify(tiempos));
      tiemposActuales = tiempos;
      actualizarLista(tiempos);
    } catch (err) {
      console.error(err);
    }
  }
  function actualizarEstilosFavorito() {
    actualizarLista(tiemposActuales); // re-render con íconos correctos
    iniciarTemporizador(INTERVALO_SOLICITUD);
  }

  function actualizarLista(tiempos) {
    const favorita = localStorage.getItem("salaFavorita");
    const lista = divglobal.querySelector("#time-list");
    const horaSpan = document.getElementById("hora-actualizada");

    // Actualizar hora
    const now = new Date();
    let hours = now.getHours();
    const ampm = hours >= 12 ? "PM" : "AM";
    hours = hours % 12 || 12;
    const minutes = String(now.getMinutes()).padStart(2, "0");
    horaSpan.textContent = `Actualizado: ${hours}:${minutes} ${ampm}`;

    lista.innerHTML = ""; // Limpiar antes de actualizar

    tiempos.forEach((obj, idx) => {
      const tiempoFmt = formatearTiempo(obj.tiempo);
      let rankIcon;

      if (obj.texto === favorita) {
        // Si es favorito, mostrar estrella dorada
        rankIcon = '<i class="fas fa-star" style="color: gold"></i>';
      } else {
        // Si no es favorito, mostrar icono según ranking
        rankIcon =
          idx === 0
            ? '<i class="fas fa-trophy" style="color:gold"></i>'
            : idx === 1
              ? '<i class="fas fa-medal" style="color:silver"></i>'
              : idx === 2
                ? '<i class="fas fa-medal" style="color:#cd7f32"></i>'
                : '<i class="far fa-clock"></i>';
      }

      const btn = document.createElement("button");
      btn.id = `boton_${idx + 1}`;
      btn.className = "animated-button";
      btn.innerHTML = `${rankIcon}<span>${obj.texto}</span><strong style="margin-left:auto">${tiempoFmt}</strong>`;

      if (obj.texto === favorita) {
        btn.style.border = "1px solid gold";
        btn.style.background = "#444";
      }

      btn.addEventListener("click", function () {
        entrarJuego(obj.texto);
        this.blur();
      });

      btn.addEventListener("contextmenu", function (e) {
        e.preventDefault();
        localStorage.setItem("salaFavorita", obj.texto);
        actualizarEstilosFavorito(); // actualiza estilos de botones inmediatamente
      });

      btn.addEventListener("keydown", function (e) {
        if (e.code === "Space" || e.keyCode === 32) e.preventDefault();
      });

      lista.appendChild(btn);
    });
  }

  function formatearTiempo(decimal) {
    const min = Math.floor(decimal);
    const sec = Math.round((decimal - min) * 60);
    return `${min}:${sec.toString().padStart(2, "0")}`;
  }

  function entrarJuego(salaTexto) {
    const mySelect = document.getElementById("gamemode");
    let found = false;

    let autoplayActivo = typeof presionandoG !== "undefined" && presionandoG;
    if (autoplayActivo) simularDetener();

    for (let i = 0; i < mySelect.options.length; i++) {
      if (mySelect.options[i].textContent.includes(salaTexto)) {
        mySelect.selectedIndex = i;
        mySelect.onchange();
        found = true;
        break;
      }
    }

    if (found) {
      setTimeout(() => {
        $("#playBtn").trigger("click");
        if (autoplayActivo) {
          setTimeout(() => iniciarAutoplay(), 100);
        }
      }, 700);
    } else {
      console.error("No se encontró el servidor:", salaTexto);
    }
  }
  function iniciarTemporizador(intervaloMs) {
    const display = document.getElementById("countdown");
    let segundos = intervaloMs / 1000;

    if (temporizadorInterval) clearInterval(temporizadorInterval); // Limpiar el anterior si existe

    const tick = () => {
      display.textContent = `Próxima actualización en ${segundos}s`;
      segundos--;
      if (segundos < 0) {
        segundos = intervaloMs / 1000;
      }
    };

    temporizadorInterval = setInterval(tick, 1000);
    tick();
  }
  obtenerTiempos();
  function iniciarActualizaciones(intervalo) {
    if (timeoutActualizacion) clearTimeout(timeoutActualizacion);

    timeoutActualizacion = setTimeout(async () => {
      await obtenerTiempos(); // Espera antes de continuar
      iniciarActualizaciones(intervalo); // Vuelve a iniciar el ciclo
    }, intervalo);
  }

  obtenerTiempos();
  iniciarActualizaciones(INTERVALO_SOLICITUD);
  iniciarTemporizador(INTERVALO_SOLICITUD);
});
