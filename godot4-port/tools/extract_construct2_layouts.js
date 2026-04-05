#!/usr/bin/env node

const fs = require("fs");
const path = require("path");

const REPO_ROOT = path.resolve(__dirname, "..", "..");
const SOURCE_DATA_PATH = path.join(
  REPO_ROOT,
  "wails3-go",
  "frontend",
  "public",
  "game",
  "data.js",
);
const OUTPUT_PATH = path.join(
  REPO_ROOT,
  "godot4-port",
  "data",
  "construct2_export.json",
);

const STAGE_NAMES = ["Layout 1", "Layout 2", "Layout 3", "Layout 4", "Layout 5"];
const MENU_LAYOUT_NAMES = ["Layout Start", "Layout GameShows", "Layout CheckpointChoice"];
const REGULAR_ENEMY_IDS = new Set([8, 19, 22, 25, 78]);
const OPTIONAL_REPLY_ID = 97;
const OPTIONAL_REPLY_PLATFORM_ID = 98;
const COLLIDER_IDS = new Set([1, 42, 43, 44]);
const ONE_WAY_COLLIDER_IDS = new Set([1, 42]);
const DIRECT_PLATFORM_IDS = new Set([98]);
const TURN_MARKER_IDS = new Map([
  [9, "right"],
  [10, "left"],
]);
const NON_VISUAL_IDS = new Set([
  0, 2, 4, 6, 9, 10, 11, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27,
  29, 53, 72, 73, 74, 78, 79, 80, 81, 85, 88, 89, 97,
]);
const ANIMATED_OBJECT_IDS = new Set([2, 8, 19, 22, 25, 29, 53, 71, 72, 73, 74, 78, 81, 85, 97]);

function readProject() {
  const raw = fs.readFileSync(SOURCE_DATA_PATH, "utf8").replace(/^\uFEFF/, "");
  return JSON.parse(raw).project;
}

function normalizeValue(value) {
  if (Array.isArray(value) && value.length === 1) {
    return normalizeValue(value[0]);
  }

  if (typeof value === "string") {
    let next = value;
    while (
      next.length >= 2 &&
      ((next.startsWith('"') && next.endsWith('"')) ||
        (next.startsWith("'") && next.endsWith("'")))
    ) {
      next = next.slice(1, -1);
    }
    return next;
  }

  if (Array.isArray(value)) {
    return value.map(normalizeValue);
  }

  return value;
}

function getObjectAsset(objectDef) {
  if (Array.isArray(objectDef[6])) {
    return objectDef[6][0];
  }

  if (
    Array.isArray(objectDef[7]) &&
    Array.isArray(objectDef[7][0]) &&
    Array.isArray(objectDef[7][0][7]) &&
    Array.isArray(objectDef[7][0][7][0])
  ) {
    return objectDef[7][0][7][0][0];
  }

  return "";
}

function extractAnimations(objectDef) {
  if (!Array.isArray(objectDef[7])) {
    return {};
  }

  const animations = {};

  for (const animationDef of objectDef[7]) {
    const animationName = animationDef[0];
    const speed = animationDef[1];
    const loop = Boolean(animationDef[2]);
    const frameDefs = Array.isArray(animationDef[7]) ? animationDef[7] : [];

    animations[animationName] = {
      speed,
      loop,
      frames: frameDefs.map((frameDef) => ({
        asset: frameDef[0],
        region: [frameDef[2], frameDef[3], frameDef[4], frameDef[5]],
        size: [frameDef[4], frameDef[5]],
        origin: [frameDef[7], frameDef[8]],
      })),
    };
  }

  return animations;
}

function rectFromInstance(instance) {
  const transform = instance[0];
  const x = transform[0];
  const y = transform[1];
  const width = transform[3];
  const height = transform[4];
  const originX = transform[8];
  const originY = transform[9];
  const left = x - width * originX;
  const top = y - height * originY;

  return {
    x,
    y,
    width,
    height,
    originX,
    originY,
    left,
    top,
    right: left + width,
    bottom: top + height,
  };
}

function instanceIntersectsLayout(instance, layoutWidth, layoutHeight) {
  const rect = rectFromInstance(instance);
  return rect.right > 0 && rect.bottom > 0 && rect.left < layoutWidth && rect.top < layoutHeight;
}

function getFrameIndex(instance) {
  const extra = instance[5];
  if (Array.isArray(extra) && extra.length >= 3 && Number.isFinite(extra[2])) {
    return extra[2];
  }
  return 0;
}

function getAnimationName(instance) {
  const extra = instance[5];
  if (Array.isArray(extra) && typeof extra[1] === "string") {
    return extra[1];
  }
  return "Default";
}

function buildVisualEntry(instance, objectDef, layerName) {
	const rect = rectFromInstance(instance);
	return {
    object_id: instance[1],
    layer: layerName,
    asset: getObjectAsset(objectDef),
    position: [rect.x, rect.y],
    top_left: [rect.left, rect.top],
    size: [rect.width, rect.height],
    animation: getAnimationName(instance),
    frame: getFrameIndex(instance),
	};
}

function buildMenuEntry(instance, objectDef, layerName) {
  const rect = rectFromInstance(instance);
  return {
    object_id: instance[1],
    layer: layerName,
    asset: getObjectAsset(objectDef),
    position: [rect.x, rect.y],
    top_left: [rect.left, rect.top],
    size: [rect.width, rect.height],
    origin: [rect.originX, rect.originY],
    animation: getAnimationName(instance),
    frame: getFrameIndex(instance),
  };
}

function buildColliderEntry(instance, objectDef) {
  const rect = rectFromInstance(instance);
  return {
    object_id: instance[1],
    asset: getObjectAsset(objectDef),
    mode: ONE_WAY_COLLIDER_IDS.has(instance[1]) ? "one_way" : "solid",
    top_left: [rect.left, rect.top],
    size: [rect.width, rect.height],
  };
}

function buildEnemyEntry(instance, role) {
  const rect = rectFromInstance(instance);
  const vars = Array.isArray(instance[3]) ? instance[3].map(normalizeValue) : [];

  return {
    object_id: instance[1],
    role,
    position: [rect.x, rect.y],
    size: [rect.width, rect.height],
    vars,
  };
}

function buildTurnMarkerEntry(instance) {
  const rect = rectFromInstance(instance);
  return {
    object_id: instance[1],
    direction: TURN_MARKER_IDS.get(instance[1]) || "right",
    position: [rect.x, rect.y],
    top_left: [rect.left, rect.top],
    size: [rect.width, rect.height],
    rect: {
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
    },
  };
}

function objectRole(objectId) {
  switch (objectId) {
    case 8:
      return "thief_1";
    case 19:
      return "thief_2";
    case 22:
      return "thief_3";
    case 25:
      return "thief_4";
    case 78:
      return "boss";
    case 97:
      return "reply";
    default:
      return "unknown";
  }
}

function pairReplyPlatforms(replyEnemies, replyPlatforms) {
  return replyEnemies.map((enemy) => {
    let bestPlatform = null;
    let bestDistance = Number.POSITIVE_INFINITY;

    for (const platform of replyPlatforms) {
      const distance = Math.abs(platform.position[0] - enemy.position[0]);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestPlatform = platform;
      }
    }

    return {
      ...enemy,
      platform: bestPlatform,
    };
  });
}

function buildStage(layout, objectDefs) {
  const name = layout[0];
  const width = layout[1];
  const height = layout[2];
  const allEntries = layout[6].flatMap((layer) =>
    (layer[14] || []).map((instance) => ({
      layer: layer[0],
      instance,
    })),
  );

  const visibleEntries = allEntries.filter(({ instance }) =>
    instanceIntersectsLayout(instance, width, height),
  );

  const playerSpawnSource = visibleEntries.find(({ instance }) => instance[1] === 0);
  const portalSource = visibleEntries.find(({ instance }) => instance[1] === 29);

  const visuals = [];
  const colliders = [];
  const turnMarkers = [];
  const regularEnemies = [];
  const replyEnemies = [];
  const replyPlatforms = [];

  for (const entry of visibleEntries) {
    const objectId = entry.instance[1];
    const objectDef = objectDefs[objectId];

    if (!objectDef) {
      continue;
    }

    if (COLLIDER_IDS.has(objectId)) {
      colliders.push(buildColliderEntry(entry.instance, objectDef));
      continue;
    }

    if (TURN_MARKER_IDS.has(objectId)) {
      turnMarkers.push(buildTurnMarkerEntry(entry.instance));
      continue;
    }

    if (DIRECT_PLATFORM_IDS.has(objectId)) {
      const rect = rectFromInstance(entry.instance);
      replyPlatforms.push({
        object_id: objectId,
        position: [rect.x, rect.y],
        top_left: [rect.left, rect.top],
        size: [rect.width, rect.height],
        asset: getObjectAsset(objectDef),
      });
      continue;
    }

    if (REGULAR_ENEMY_IDS.has(objectId)) {
      regularEnemies.push(buildEnemyEntry(entry.instance, objectRole(objectId)));
      continue;
    }

    if (objectId === OPTIONAL_REPLY_ID) {
      replyEnemies.push(buildEnemyEntry(entry.instance, objectRole(objectId)));
      continue;
    }

    if (
      (entry.layer === "BK" || entry.layer === "Ground") &&
      !NON_VISUAL_IDS.has(objectId)
    ) {
      visuals.push(buildVisualEntry(entry.instance, objectDef, entry.layer));
    }
  }

  if (!playerSpawnSource) {
    throw new Error(`Could not find player spawn in ${name}`);
  }

  if (!portalSource) {
    throw new Error(`Could not find portal in ${name}`);
  }

  return {
    name,
    width,
    height,
    player_spawn: rectFromInstance(playerSpawnSource.instance),
    portal: {
      object_id: 29,
      position: [portalSource.instance[0][0], portalSource.instance[0][1]],
      rect: rectFromInstance(portalSource.instance),
    },
    visuals,
    colliders,
    turn_markers: turnMarkers,
    regular_enemies: regularEnemies,
    reply_enemies: pairReplyPlatforms(replyEnemies, replyPlatforms),
  };
}

function buildMenuLayout(layout, objectDefs) {
  const width = layout[1];
  const height = layout[2];
  const elements = layout[6].flatMap((layer) =>
    (layer[14] || [])
      .filter((instance) => instanceIntersectsLayout(instance, width, height))
      .map((instance) => {
        const objectDef = objectDefs[instance[1]];
        if (!objectDef) {
          return null;
        }
        return buildMenuEntry(instance, objectDef, layer[0]);
      })
      .filter(Boolean),
  );

  const background = elements.find((entry) =>
    entry.layer === "BK" &&
    entry.top_left[0] === 0 &&
    entry.top_left[1] === 0 &&
    entry.size[0] === width &&
    entry.size[1] === height &&
    entry.asset
  );

  return {
    name: layout[0],
    width,
    height,
    background_asset: background ? background.asset : "",
    elements,
  };
}

function buildExport() {
  const project = readProject();
  const objectDefs = project[3];
  const layouts = project[5];

  const objects = {};
  objectDefs.forEach((objectDef, index) => {
    const asset = getObjectAsset(objectDef);
    const animations = ANIMATED_OBJECT_IDS.has(index) ? extractAnimations(objectDef) : {};
    objects[index] = {
      id: index,
      name: objectDef[0],
      kind: objectDef[1],
      asset,
      animations,
    };
  });

  const stages = {};
  for (const stageName of STAGE_NAMES) {
    const layout = layouts.find((candidate) => candidate[0] === stageName);
    if (!layout) {
      throw new Error(`Missing stage layout: ${stageName}`);
    }
    stages[stageName] = buildStage(layout, objectDefs);
  }

  const menuLayouts = {};
  for (const layoutName of MENU_LAYOUT_NAMES) {
    const layout = layouts.find((candidate) => candidate[0] === layoutName);
    if (!layout) {
      throw new Error(`Missing menu layout: ${layoutName}`);
    }
    menuLayouts[layoutName] = buildMenuLayout(layout, objectDefs);
  }

  return {
    viewport: {
      width: project[10],
      height: project[11],
    },
    stage_order: STAGE_NAMES,
    menu_assets: {
      start_background: "images/bkofstart.png",
      guide_background: "images/bkgameshows.png",
      music: "",
      win_banner: "images/textofwin.png",
    },
    menu_layouts: menuLayouts,
    objects,
    stages,
  };
}

function main() {
  const exportData = buildExport();
  fs.writeFileSync(OUTPUT_PATH, `${JSON.stringify(exportData, null, 2)}\n`, "utf8");

  const summary = exportData.stage_order
    .map((stageName) => {
      const stage = exportData.stages[stageName];
      return `${stageName}: ${stage.regular_enemies.length} regular, ${stage.reply_enemies.length} optional`;
    })
    .join("\n");

  console.log(`Wrote ${path.relative(REPO_ROOT, OUTPUT_PATH)}`);
  console.log(summary);
}

main();
