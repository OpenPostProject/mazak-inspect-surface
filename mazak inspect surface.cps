/**
  Copyright (C) 2012-2023 by Autodesk, Inc.
  All rights reserved.

  Mazak post processor configuration.

  $Revision: 44083 865c6f1c385b9194ab63e73899f0a4787fce12a6 $
  $Date: 2023-08-14 12:16:17 $

  FORKID {62F61C65-979D-4f9f-97B0-C5F9634CC6A7}
*/

// >>>>> INCLUDED FROM generic_posts/mazak.cps
// ATTENTION: parameter F86 bit 6 must be on for G43.4

description = "Mazak";
vendor = "Mazak";
vendorUrl = "http://www.autodesk.com";
legal = "Copyright (C) 2012-2023 by Autodesk, Inc.";
certificationLevel = 2;
minimumRevision = 45917;

longDescription = "Generic milling post for Mazak.";

extension = "eia";
programNameIsInteger = true;
setCodePage("ascii");

capabilities = CAPABILITY_MILLING | CAPABILITY_MACHINE_SIMULATION;
tolerance = spatial(0.002, MM);

minimumChordLength = spatial(0.25, MM);
minimumCircularRadius = spatial(0.01, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.01);
maximumCircularSweep = toRad(180);
allowHelicalMoves = true;
allowedCircularPlanes = undefined; // allow any circular motion
probeMultipleFeatures = true;

// user-defined properties
properties = {
  preloadTool: {
    title      : "Preload tool",
    description: "Preloads the next tool at a tool change (if any).",
    group      : "preferences",
    type       : "enum",
    values     : [
      {title:"Yes", id:"true"},
      {title:"No", id:"false"},
      {title:"On tool change block", id:"toolChange"}
    ],
    value: "true",
    scope: "post"
  },
  showSequenceNumbers: {
    title      : "Use sequence numbers",
    description: "'Yes' outputs sequence numbers on each block, 'Only on tool change' outputs sequence numbers on tool change blocks only, and 'No' disables the output of sequence numbers.",
    group      : "formats",
    type       : "enum",
    values     : [
      {title:"Yes", id:"true"},
      {title:"No", id:"false"},
      {title:"Only on tool change", id:"toolChange"}
    ],
    value: "true",
    scope: "post"
  },
  sequenceNumberStart: {
    title      : "Start sequence number",
    description: "The number at which to start the sequence numbers.",
    group      : "formats",
    type       : "integer",
    value      : 10,
    scope      : "post"
  },
  sequenceNumberIncrement: {
    title      : "Sequence number increment",
    description: "The amount by which the sequence number is incremented by in each block.",
    group      : "formats",
    type       : "integer",
    value      : 5,
    scope      : "post"
  },
  optionalStop: {
    title      : "Optional stop",
    description: "Outputs optional stop code during when necessary in the code.",
    group      : "preferences",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
  separateWordsWithSpace: {
    title      : "Separate words with space",
    description: "Adds spaces between words if 'yes' is selected.",
    group      : "formats",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
  useRadius: {
    title      : "Radius arcs",
    description: "If yes is selected, arcs are outputted using radius values rather than IJK.",
    group      : "preferences",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  showNotes: {
    title      : "Show notes",
    description: "Writes operation notes as comments in the outputted code.",
    group      : "formats",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  usePitchForTapping: {
    title      : "Use pitch for tapping",
    description: "Enables the use of pitch instead of feed for the F-word in canned tapping cycles. Your CNC control must be setup for pitch mode!",
    group      : "preferences",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  useG54x4: {
    title      : "Use G54.4",
    description: "Use G54.4 workpiece error compensation for angular probing.",
    group      : "probing",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  safePositionMethod: {
    title      : "Safe Retracts",
    description: "Select your desired retract option. 'Clearance Height' retracts to the operation clearance height.",
    group      : "homePositions",
    type       : "enum",
    values     : [
      // {title: "G28", id: "G28"},
      {title:"G53", id:"G53"},
      {title:"Clearance Height", id:"clearanceHeight"}
    ],
    value: "G53",
    scope: "post"
  },
  singleResultsFile: {
    title      : "Create single results file",
    description: "Set to false if you want to store the measurement results for each probe / inspection toolpath in a separate file",
    group      : "probing",
    type       : "boolean",
    value      : true,
    scope      : "post"
  },
  useClampCodes: {
    title      : "Use clamp codes",
    description: "Specifies whether clamp codes for rotary axes should be output. For simultaneous toolpaths rotary axes will always get unclamped.",
    group      : "multiAxis",
    type       : "boolean",
    value      : false,
    scope      : "post"
  },
  useSmoothing: {
    title      : "Use smoothing",
    description: "Specifies if smoothing should be used.",
    group      : "preferences",
    type       : "enum",
    values     : [
      {title:"No", id:"-1"},
      // {title:"Automatic", id:"9999"}
      {title:"Yes", id:"1"},
    ],
    value: "-1",
    scope: "post"
  },
};

// wcs definiton
wcsDefinitions = {
  useZeroOffset: false,
  wcs          : [
    {name:"Standard", format:"G", range:[54, 59]},
    {name:"Extended", format:"G54.1 P", range:[1, 48]}
  ]
};

var gFormat = createFormat({prefix:"G", decimals:1});
var mFormat = createFormat({prefix:"M", decimals:0});
var hFormat = createFormat({prefix:"H", decimals:0});
var diameterOffsetFormat = createFormat({prefix:"D", decimals:0});
var probeWCSFormat = createFormat({decimals:0, forceDecimal:true});

var xyzFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true});
var ijkFormat = createFormat({decimals:6, forceDecimal:true}); // unitless
var rFormat = xyzFormat; // radius
var abcFormat = createFormat({decimals:3, forceDecimal:true, scale:DEG});
var feedFormat = createFormat({decimals:(unit == MM ? 2 : 3), forceDecimal:true});
var inverseTimeFormat = createFormat({decimals:3, forceDecimal:true});
var pitchFormat = createFormat({decimals:(unit == MM ? 3 : 4), forceDecimal:true});
var toolFormat = createFormat({decimals:0});
var rpmFormat = createFormat({decimals:0});
var secFormat = createFormat({decimals:3, forceDecimal:true}); // seconds - range 0.001-99999.999
var milliFormat = createFormat({decimals:0}); // milliseconds // range 1-99999999
var taperFormat = createFormat({decimals:1, scale:DEG});
var oFormat = createFormat({width:4, zeropad:true, decimals:0});

var xOutput = createOutputVariable({prefix:"X"}, xyzFormat);
var yOutput = createOutputVariable({prefix:"Y"}, xyzFormat);
var zOutput = createOutputVariable({onchange:function () {retracted = false;}, prefix:"Z"}, xyzFormat);
var toolVectorOutputI = createOutputVariable({prefix:"I", control:CONTROL_FORCE}, ijkFormat);
var toolVectorOutputJ = createOutputVariable({prefix:"J", control:CONTROL_FORCE}, ijkFormat);
var toolVectorOutputK = createOutputVariable({prefix:"K", control:CONTROL_FORCE}, ijkFormat);
var aOutput = createOutputVariable({prefix:"A"}, abcFormat);
var bOutput = createOutputVariable({prefix:"B"}, abcFormat);
var cOutput = createOutputVariable({prefix:"C"}, abcFormat);
var feedOutput = createOutputVariable({prefix:"F"}, feedFormat);
var inverseTimeOutput = createOutputVariable({prefix:"F", control:CONTROL_FORCE}, inverseTimeFormat);
var pitchOutput = createOutputVariable({prefix:"F", control:CONTROL_FORCE}, pitchFormat);
var sOutput = createOutputVariable({prefix:"S", control:CONTROL_FORCE}, rpmFormat);

// circular output
var iOutput = createOutputVariable({prefix:"I", control:CONTROL_FORCE}, xyzFormat);
var jOutput = createOutputVariable({prefix:"J", control:CONTROL_FORCE}, xyzFormat);
var kOutput = createOutputVariable({prefix:"K", control:CONTROL_FORCE}, xyzFormat);

var gMotionModal = createOutputVariable({}, gFormat); // modal group 1 // G0-G3, ...
var gPlaneModal = createOutputVariable({onchange:function () {gMotionModal.reset();}}, gFormat); // modal group 2 // G17-19
var gAbsIncModal = createOutputVariable({}, gFormat); // modal group 3 // G90-91
var gFeedModeModal = createOutputVariable({}, gFormat); // modal group 5 // G93-94
var gUnitModal = createOutputVariable({}, gFormat); // modal group 6 // G20-21
var gCycleModal = gMotionModal;
var gRetractModal = createOutputVariable({}, gFormat); // modal group 10 // G98-99
var gRotationModal = createOutputVariable({
  onchange: function () {
    if (settings.probing.probeAngleMethod == "G68") {
      probeVariables.outputRotationCodes = true;
    }
  }
}, gFormat); // modal group 16 // G68-G69
var mClampModal = createModalGroup(
  {strict:false},
  [
    [44, 43], // 4th axis clamp / unclamp
    [47, 46] // 5th axis clamp / unclamp
  ],
  mFormat
);

var settings = {
  coolant: {
    // samples:
    // {id: COOLANT_THROUGH_TOOL, on: 88, off: 89}
    // {id: COOLANT_THROUGH_TOOL, on: [8, 88], off: [9, 89]}
    // {id: COOLANT_THROUGH_TOOL, on: "M88 P3 (myComment)", off: "M89"}
    coolants: [
      {id:COOLANT_FLOOD, on:8},
      {id:COOLANT_MIST, on:7},
      {id:COOLANT_THROUGH_TOOL, on:51},
      {id:COOLANT_AIR, on:52},
      {id:COOLANT_AIR_THROUGH_TOOL, on:130},
      {id:COOLANT_SUCTION},
      {id:COOLANT_FLOOD_MIST},
      {id:COOLANT_FLOOD_THROUGH_TOOL},
      {id:COOLANT_OFF, off:9}
    ],
    singleLineCoolant: false, // specifies to output multiple coolant codes in one line rather than in separate lines
  },
  smoothing: {
    roughing              : 1, // roughing level for smoothing in automatic mode
    semi                  : 2, // semi-roughing level for smoothing in automatic mode
    semifinishing         : 3, // semi-finishing level for smoothing in automatic mode
    finishing             : 3, // finishing level for smoothing in automatic mode
    thresholdRoughing     : toPreciseUnit(0.1, MM), // operations with stock/tolerance above that threshold will use roughing level in automatic mode
    thresholdFinishing    : toPreciseUnit(0.01, MM), // operations with stock/tolerance below that threshold will use finishing level in automatic mode
    thresholdSemiFinishing: toPreciseUnit(0.01, MM), // operations with stock/tolerance above finishing and below threshold roughing that threshold will use semi finishing level in automatic mode

    differenceCriteria: "level", // options: "level", "tolerance", "both". Specifies criteria when output smoothing codes
    autoLevelCriteria : "stock", // use "stock" or "tolerance" to determine levels in automatic mode
    cancelCompensation: true // tool length compensation must be canceled prior to changing the smoothing level
  },
  retract: {
    cancelRotationOnRetracting: false, // specifies that rotations (G68) need to be canceled prior to retracting
    methodXY                  : undefined, // special condition, overwrite retract behavior per axis
    methodZ                   : undefined, // special condition, overwrite retract behavior per axis
    useZeroValues             : ["G28", "G30"] // enter property value id(s) for using "0" value instead of machineConfiguration axes home position values (ie G30 Z0)
  },
  parametricFeeds: {
    firstFeedParameter    : 100, // specifies the initial parameter number to be used for parametric feedrate output
    feedAssignmentVariable: "#", // specifies the syntax to define a parameter
    feedOutputVariable    : "F#" // specifies the syntax to output the feedrate as parameter
  },
  machineAngles: { // refer to https://cam.autodesk.com/posts/reference/classMachineConfiguration.html#a14bcc7550639c482492b4ad05b1580c8
    controllingAxis: ABC,
    type           : PREFER_PREFERENCE,
    options        : ENABLE_ALL
  },
  workPlaneMethod: {
    useTiltedWorkplane    : true, // specifies that tilted workplanes should be used (ie. G68.2, G254, PLANE SPATIAL, CYCLE800), can be overwritten by property
    eulerConvention       : EULER_ZXZ_R, // specifies the euler convention (ie EULER_XYZ_R), set to undefined to use machine angles for TWP commands ('undefined' requires machine configuration)
    eulerCalculationMethod: "standard", // ('standard' / 'machine') 'machine' adjusts euler angles to match the machines ABC orientation, machine configuration required
    cancelTiltFirst       : true, // cancel tilted workplane prior to WCS (G54-G59) blocks
    useABCPrepositioning  : false, // position ABC axes prior to tilted workplane blocks
    forceMultiAxisIndexing: false, // force multi-axis indexing for 3D programs
    optimizeType          : undefined // can be set to OPTIMIZE_NONE, OPTIMIZE_BOTH, OPTIMIZE_TABLES, OPTIMIZE_HEADS, OPTIMIZE_AXIS. 'undefined' uses legacy rotations
  },
  comments: {
    permittedCommentChars: " abcdefghijklmnopqrstuvwxyz0123456789.,=_-:#", // letters are not case sensitive, use option 'outputFormat' below. Set to 'undefined' to allow any character
    prefix               : "(", // specifies the prefix for the comment
    suffix               : ")", // specifies the suffix for the comment
    outputFormat         : "upperCase", // can be set to "upperCase", "lowerCase" and "ignoreCase". Set to "ignoreCase" to write comments without upper/lower case formatting
    maximumLineLength    : 80 // the maximum number of characters allowed in a line, set to 0 to disable comment output
  },
  probing: {
    macroCall              : gFormat.format(65), // specifies the command to call a macro
    probeAngleMethod       : "OFF", // supported options are: OFF, AXIS_ROT, G68, G54.4
    allowIndexingWCSProbing: false // specifies that probe WCS with tool orientation is supported
  },
  maximumSequenceNumber    : undefined, // the maximum sequence number (Nxxx), use 'undefined' for unlimited
  supportsToolVectorOutput : true, // default: false, specifies if the control does support tool axis vector output for multi axis toolpath
  maximumToolLengthOffset  : 512, // specifies the maximum allowed tool length offset number
  maximumToolDiameterOffset: 512 // specifies the maximum allowed tool diameter offset number
};

// collected state
var maximumCircularRadiiDifference = toPreciseUnit(0.005, MM);

function onOpen() {
  // define and enable machine configuration
  receivedMachineConfiguration = machineConfiguration.isReceived();
  if (typeof defineMachine == "function") {
    defineMachine(); // hardcoded machine configuration
  }
  activateMachine(); // enable the machine optimizations and settings

  if (getProperty("useRadius")) {
    maximumCircularSweep = toRad(90); // avoid potential center calculation errors for CNC
  }
  // initialize formats
  gRotationModal.format(69); // Default to G69 Rotation Off
  mClampModal.format(44); // Default 4th axis modal code to be clamped
  mClampModal.format(47); // Default 5th axis modal code to be clamped

  if (!getProperty("separateWordsWithSpace")) {
    setWordSeparator("");
  }

  if (programName) {
    var programId;
    try {
      programId = getAsInt(programName);
    } catch (e) {
      error(localize("Program name must be a number."));
      return;
    }
    if (!((programId >= 1) && (programId <= 99999999))) {
      error(localize("Program number is out of range."));
      return;
    }
    var o4Format = createFormat({width:4, zeropad:true, decimals:0});
    var o8Format = createFormat({width:8, zeropad:true, decimals:0});
    oFormat = (programId <= 9999) ? o4Format : o8Format;
    if (programComment) {
      writeln("O" + oFormat.format(programId) + " (" + programComment + ")");
    } else {
      writeln("O" + oFormat.format(programId));
    }
  } else {
    error(localize("Program name has not been specified."));
    return;
  }
  if (typeof inspectionWriteVariables == "function") { //Probing Surface Inspection
    inspectionWriteVariables();
  }
  writeProgramHeader();

  // absolute coordinates and feed per min
  writeBlock(gAbsIncModal.format(90), gFeedModeModal.format(94), gPlaneModal.format(17), gFormat.format(49));
  writeBlock(gUnitModal.format(unit == MM ? 21 : 20));
  validateCommonParameters();
  onCommand(COMMAND_START_CHIP_TRANSPORT);
}

/** Disables length compensation if currently active or if forced. */
var lengthCompensationActive = false;
function disableLengthCompensation(force) {
  if (lengthCompensationActive || force) {
    validate(retracted, "Cannot cancel length compensation if the machine is not fully retracted.");
    writeBlock(gFormat.format(49));
    lengthCompensationActive = false;
  }
}

function setSmoothing(mode) {
  smoothingSettings = settings.smoothing;
  if (mode == smoothing.isActive && (!mode || !smoothing.isDifferent) && !smoothing.force) {
    return; // return if smoothing is already active or is not different
  }
  if (typeof lengthCompensationActive != "undefined" && smoothingSettings.cancelCompensation) {
    validate(!lengthCompensationActive, "Length compensation is active while trying to update smoothing.");
  }

  if (mode) { // enable smoothing
    writeBlock(gFormat.format(5), "P2");
  } else { // disable smoothing
    writeBlock(gFormat.format(5), "P0");
  }
  smoothing.isActive = mode;
  smoothing.force = false;
  smoothing.isDifferent = false;
}

var currentWorkPlaneABC = undefined;

function forceWorkPlane() {
  currentWorkPlaneABC = undefined;
}

function cancelWorkPlane(force) {
  if (force) {
    gRotationModal.reset();
  }
  writeBlock(gRotationModal.format(69)); // cancel frame
  forceWorkPlane();
}

function setWorkPlane(abc) {
  if (!settings.workPlaneMethod.forceMultiAxisIndexing && is3D() && !machineConfiguration.isMultiAxisConfiguration()) {
    return; // ignore
  }

  if (!((currentWorkPlaneABC == undefined) ||
        abcFormat.areDifferent(abc.x, currentWorkPlaneABC.x) ||
        abcFormat.areDifferent(abc.y, currentWorkPlaneABC.y) ||
        abcFormat.areDifferent(abc.z, currentWorkPlaneABC.z))) {
    return; // no change
  }

  onCommand(COMMAND_UNLOCK_MULTI_AXIS);
  if (!retracted) {
    writeRetract(Z);
  }
  if (currentSection.getId() > 0 && (isTCPSupportedByOperation(getSection(currentSection.getId() - 1) || tcp.isSupportedByOperation)) && typeof disableLengthCompensation == "function") {
    disableLengthCompensation(); // cancel TCP
  }

  if (settings.workPlaneMethod.useTiltedWorkplane) {
    cancelWorkPlane();
    if (machineConfiguration.isMultiAxisConfiguration()) {
      var machineABC = abc.isNonZero() ? (currentSection.isMultiAxis() ? getCurrentDirection() : getWorkPlaneMachineABC(currentSection, false)) : abc;
      if (settings.workPlaneMethod.useABCPrepositioning || machineABC.isZero()) {
        positionABC(machineABC, false);
      } else {
        setCurrentABC(machineABC);
      }
    }
    if (abc.isNonZero() || !machineConfiguration.isMultiAxisConfiguration()) {
      gRotationModal.reset();
      writeBlock(gRotationModal.format(68.2), "X" + xyzFormat.format(0), "Y" + xyzFormat.format(0), "Z" + xyzFormat.format(0), "I" + abcFormat.format(abc.x), "J" + abcFormat.format(abc.y), "K" + abcFormat.format(abc.z)); // set frame
      var dir = "";
      if (machineConfiguration.isMultiAxisConfiguration()) {
        var preference = abcFormat.format(machineABC.getCoordinate(machineConfiguration.getAxisU().getCoordinate()));
        dir =  preference == 0 ? "" : (preference > 0 ? "P1" : "P2");
      }
      writeBlock(gFormat.format(53.1), dir); // turn machine
    }
  } else {
    positionABC(abc, true);
  }
  if (!currentSection.isMultiAxis() && !isPolarModeActive()) {
    onCommand(COMMAND_LOCK_MULTI_AXIS);
  }

  currentWorkPlaneABC = abc;
}

function onSection() {
  var forceSectionRestart = optionalSection && !currentSection.isOptional();
  optionalSection = currentSection.isOptional();
  var insertToolCall = isToolChangeNeeded("number") || forceSectionRestart;
  var newWorkOffset = isNewWorkOffset() || forceSectionRestart;
  var newWorkPlane = isNewWorkPlane() || forceSectionRestart;
  initializeSmoothing(); // initialize smoothing mode

  if (insertToolCall || newWorkOffset || newWorkPlane || smoothing.cancel) {
    if (insertToolCall && !isFirstSection()) {
      onCommand(COMMAND_STOP_SPINDLE); // stop spindle before retract during tool change
    }
    writeRetract(Z); // retract
    forceXYZ();
    if ((insertToolCall && !isFirstSection()) || smoothing.cancel) {
      disableLengthCompensation();
      setSmoothing(false);
    }
  }

  writeln("");
  writeComment(getParameter("operation-comment", ""));

  if (getProperty("showNotes")) {
    writeSectionNotes();
  }

  // tool change
  if (insertToolCall) {
    cancelWorkPlane();
  }
  writeToolCall(tool, insertToolCall);
  startSpindle(tool, insertToolCall);

  // Output modal commands here
  writeBlock(gAbsIncModal.format(90), gFeedModeModal.format(94), gPlaneModal.format(17));

  // wcs
  if (insertToolCall) { // force work offset when changing tool
    currentWorkOffset = undefined;
  }
  writeWCS(currentSection, true);

  forceXYZ();

  var abc = defineWorkPlane(currentSection, true);

  setProbeAngle(); // output probe angle rotations if required

  // set coolant after we have positioned at Z
  setCoolant(tool.coolant);

  setSmoothing(smoothing.isAllowed);

  forceAny();

  // prepositioning
  var initialPosition = getFramePosition(currentSection.getInitialPosition());
  var isRequired = insertToolCall || retracted || !lengthCompensationActive  || (!isFirstSection() && getPreviousSection().isMultiAxis());
  writeInitialPositioning(initialPosition, isRequired);

  // write parametric feedrate table
  if (typeof initializeParametricFeeds == "function") {
    initializeParametricFeeds(insertToolCall);
  }

  if (isProbeOperation()) {
    validate(settings.probing.probeAngleMethod != "G68", "You cannot probe while G68 Rotation is in effect.");
    validate(settings.probing.probeAngleMethod != "G54.4", "You cannot probe while workpiece setting error compensation G54.4 is enabled.");
    writeBlock(settings.probing.macroCall, "P" + 9832); // spin the probe on
    inspectionCreateResultsFileHeader();
  } else {
    // surface Inspection
    if (isInspectionOperation() && (typeof inspectionProcessSectionStart == "function")) {
      inspectionProcessSectionStart();
    }
  }
  retracted = false;
}

function onDwell(seconds) {
  if (seconds > 99999.999) {
    warning(localize("Dwelling time is out of range."));
  }
  seconds = clamp(0.001, seconds, 99999.999);
  writeBlock(gFeedModeModal.format(94), gFormat.format(4), "P" + milliFormat.format(seconds * 1000));
}

function onSpindleSpeed(spindleSpeed) {
  writeBlock(sOutput.format(spindleSpeed));
}

function onCycle() {
  writeBlock(gPlaneModal.format(17));
}

function getCommonCycle(x, y, z, r) {
  forceXYZ(); // force xyz on first drill hole of any cycle
  return [xOutput.format(x), yOutput.format(y),
    zOutput.format(z),
    "R" + xyzFormat.format(r)];
}

/** Output rotation offset based on angular probing cycle. */
function setProbeAngle() {
  if (probeVariables.outputRotationCodes) {
    var probeOutputWorkOffset = currentSection.probeWorkOffset;
    validate(probeOutputWorkOffset <= 6, "Angular Probing only supports work offsets 1-6.");
    if (settings.probing.probeAngleMethod == "G68" && (Vector.diff(currentSection.getGlobalInitialToolAxis(), new Vector(0, 0, 1)).length > 1e-4)) {
      error(localize("You cannot use multi axis toolpaths while G68 Rotation is in effect."));
    }
    var validateWorkOffset = false;
    switch (settings.probing.probeAngleMethod) {
    case "G54.4":
      var param = 5801 + (probeOutputWorkOffset * 10);
      writeBlock("#" + param + "=#135");
      writeBlock("#" + (param + 1) + "=#136");
      writeBlock("#" + (param + 5) + "=#144");
      writeBlock(gFormat.format(54.4), "P" + probeOutputWorkOffset);
      break;
    case "G68":
      gRotationModal.reset();
      gAbsIncModal.reset();
      var n = xyzFormat.format(0);
      writeBlock(
        gRotationModal.format(68), gAbsIncModal.format(90),
        probeVariables.compensationXY, "Z" + n, "I" + n, "J" + n, "K" + xyzFormat.format(1), "R[#144]"
      );
      validateWorkOffset = true;
      break;
    case "AXIS_ROT":
      var param = 5200 + probeOutputWorkOffset * 20 + 5;
      writeBlock("#" + param + " = " + "[#" + param + " + #144]");
      forceWorkPlane(); // force workplane to rotate ABC in order to apply rotation offsets
      currentWorkOffset = undefined; // force WCS output to make use of updated parameters
      validateWorkOffset = true;
      break;
    default:
      error(localize("Angular Probing is not supported for this machine configuration."));
      return;
    }
    if (validateWorkOffset) {
      for (var i = currentSection.getId(); i < getNumberOfSections(); ++i) {
        if (getSection(i).workOffset != currentSection.workOffset) {
          error(localize("WCS offset cannot change while using angle rotation compensation."));
          return;
        }
      }
    }
    probeVariables.outputRotationCodes = false;
  }
}

function onCyclePoint(x, y, z) {
  if (cycleType == "inspect") {
    if (typeof inspectionCycleInspect == "function") {
      inspectionCycleInspect(cycle, x, y, z);
      return;
    } else {
      cycleNotSupported();
    }
  } else if (isProbeOperation()) {
    writeProbeCycle(cycle, x, y, z);
  } else {
    if (!isSameDirection(getRotation().forward, new Vector(0, 0, 1))) {
      expandCyclePoint(x, y, z);
      return;
    }

    gRetractModal.reset();
    if (isFirstCyclePoint()) {
      repositionToCycleClearance(cycle, x, y, z);

      // return to initial Z which is clearance plane and set absolute mode

      var F = cycle.feedrate;
      var P = !cycle.dwell ? 0 : clamp(1, cycle.dwell * 1000, 99999999); // in milliseconds

      switch (cycleType) {
      case "drilling": // use G82
      case "counter-boring":
        var d0 = cycle.retract - cycle.stock;
        writeBlock(
          gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(82),
          getCommonCycle(x, y, z, cycle.retract),
          conditional(P > 0, "P" + milliFormat.format(P)),
          feedOutput.format(F),
          conditional(d0 > 0, "D" + milliFormat.format(d0))
        );
        break;
      case "chip-breaking":
        if (cycle.accumulatedDepth < cycle.depth) {
          expandCyclePoint(x, y, z);
        } else {
          var tz = cycle.incrementalDepth;
          // var d0 = (cycle.chipBreakDistance != undefined) ? cycle.chipBreakDistance : machineParameters.chipBreakingDistance;
          var k0 = cycle.retract - cycle.stock;
          // d0 not supported
          writeBlock(
            gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(73),
            getCommonCycle(x, y, z, cycle.retract),
            "Q" + xyzFormat.format(tz),
            conditional(P > 0, "P" + milliFormat.format(P)),
            feedOutput.format(F),
            // conditional(d0 > 0, "D" + xyzFormat.format(d0)), // use parameter F12
            conditional(k0 > 0, "K" + xyzFormat.format(k0))
          );
        }
        break;
      case "deep-drilling":
        var tz = cycle.incrementalDepth;
        var k0 = cycle.retract - cycle.stock;
        // d0 not supported
        if (cycle.dwell > 0) { // not supported by cycle
          expandCyclePoint(x, y, z);
        } else {
          writeBlock(
            gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(83),
            getCommonCycle(x, y, z, cycle.retract),
            "Q" + xyzFormat.format(tz),
            feedOutput.format(F),
            conditional(k0 > 0, "K" + xyzFormat.format(k0))
          );
        }
        break;
      case "tapping":
        if (getProperty("usePitchForTapping")) {
          writeBlock(
            gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format((tool.type == TOOL_TAP_LEFT_HAND) ? 74 : 84),
            getCommonCycle(x, y, z, cycle.retract),
            pitchOutput.format(tool.threadPitch)
          );
          forceFeed();
        } else {
          F = tool.getTappingFeedrate();
          writeBlock(
            gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format((tool.type == TOOL_TAP_LEFT_HAND) ? 74 : 84),
            getCommonCycle(x, y, z, cycle.retract),
            feedOutput.format(F)
          );
        }
        break;
      case "left-tapping":
        if (getProperty("usePitchForTapping")) {
          writeBlock(
            gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(74),
            getCommonCycle(x, y, z, cycle.retract),
            pitchOutput.format(tool.threadPitch)
          );
          forceFeed();
        } else {
          F = tool.getTappingFeedrate();
          writeBlock(
            gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(74),
            getCommonCycle(x, y, z, cycle.retract),
            feedOutput.format(F)
          );
        }
        break;
      case "right-tapping":
        if (getProperty("usePitchForTapping")) {
          writeBlock(
            gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(84),
            getCommonCycle(x, y, z, cycle.retract),
            pitchOutput.format(tool.threadPitch)
          );
          forceFeed();
        } else {
          F = tool.getTappingFeedrate();
          writeBlock(
            gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(84),
            getCommonCycle(x, y, z, cycle.retract),
            feedOutput.format(F)
          );
        }
        break;
      case "fine-boring":
      // TAG: add support for counterclockwise direction
        var d0 = cycle.retract - cycle.stock;
        writeBlock(
          gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(76),
          getCommonCycle(x, y, z, cycle.retract),
          conditional(P > 0, "P" + milliFormat.format(P)),
          "Q" + xyzFormat.format(cycle.shift),
          feedOutput.format(F),
          conditional(d0 > 0, "D" + xyzFormat.format(d0))
        );
        break;
      case "back-boring":
        var dx = (gPlaneModal.getCurrent() == 19) ? cycle.backBoreDistance : 0;
        var dy = (gPlaneModal.getCurrent() == 18) ? cycle.backBoreDistance : 0;
        var dz = (gPlaneModal.getCurrent() == 17) ? cycle.backBoreDistance : 0;
        writeBlock(
          gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(87),
          getCommonCycle(x - dx, y - dy, z - dz, cycle.bottom),
          feedOutput.format(F),
          conditional(P > 0, "P" + milliFormat.format(P)),
          "Q" + xyzFormat.format(cycle.shift)
        );
        break;
      case "reaming":
        var d0 = cycle.retract - cycle.stock;
        var f1 = cycle.retractFeedrate;
        writeBlock(
          gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(85),
          getCommonCycle(x, y, z, cycle.retract),
          feedOutput.format(F),
          conditional(P > 0, "P" + milliFormat.format(P)),
          conditional(f1 != F, "E" + feedFormat.format(f1)),
          conditional(d0 > 0, "D" + xyzFormat.format(d0))
        );
        break;
      case "stop-boring":
        writeBlock(
          gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(86),
          getCommonCycle(x, y, z, cycle.retract),
          feedOutput.format(F),
          conditional(P > 0, "P" + milliFormat.format(P))
        );
        break;
      case "manual-boring":
        writeBlock(
          gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(88),
          getCommonCycle(x, y, z, cycle.retract),
          feedOutput.format(F),
          conditional(P > 0, "P" + milliFormat.format(P))
        );
        break;
      case "boring":
        writeBlock(
          gRetractModal.format(98), gAbsIncModal.format(90), gCycleModal.format(89),
          getCommonCycle(x, y, z, cycle.retract),
          feedOutput.format(F),
          conditional(P > 0, "P" + milliFormat.format(P))
        );
        break;
      default:
        expandCyclePoint(x, y, z);
      }
    } else {
      if (cycleExpanded) {
        expandCyclePoint(x, y, z);
      } else {
        var _x = xOutput.format(x);
        var _y = yOutput.format(y);
        var _z = zOutput.format(z);
        if (!_x && !_y && !_z) {
          switch (gPlaneModal.getCurrent()) {
          case 17: // XY
            xOutput.reset(); // at least one axis is required
            _x = xOutput.format(x);
            break;
          case 18: // ZX
            zOutput.reset(); // at least one axis is required
            _z = zOutput.format(z);
            break;
          case 19: // YZ
            yOutput.reset(); // at least one axis is required
            _y = yOutput.format(y);
            break;
          }
        }
        writeBlock(_x, _y, _z);
      }
    }
  }
}

function onCycleEnd() {
  if (isProbeOperation()) {
    zOutput.reset();
    gMotionModal.reset();
    writeBlock(settings.probing.macroCall, "P" + 9810, zOutput.format(cycle.retract)); // protected retract move
  } else {
    if (!cycleExpanded) {
      writeBlock(gCycleModal.format(80));
      gMotionModal.reset();
    }
  }
}

function onCircular(clockwise, cx, cy, cz, x, y, z, feed) {
  if (isSpiral()) {
    var startRadius = getCircularStartRadius();
    var endRadius = getCircularRadius();
    var dr = Math.abs(endRadius - startRadius);
    if (dr > maximumCircularRadiiDifference) { // maximum limit
      linearize(tolerance); // or alternatively use other G-codes for spiral motion
      return;
    }
  }

  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation cannot be activated/deactivated for a circular move."));
    return;
  }

  var start = getCurrentPosition();

  if (isFullCircle()) {
    if (getProperty("useRadius") || isHelical()) { // radius mode does not support full arcs
      linearize(tolerance);
      return;
    }
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gPlaneModal.format(17), gMotionModal.format(clockwise ? 2 : 3), iOutput.format(cx - start.x), jOutput.format(cy - start.y), getFeed(feed));
      break;
    case PLANE_ZX:
      writeBlock(gPlaneModal.format(18), gMotionModal.format(clockwise ? 2 : 3), iOutput.format(cx - start.x), kOutput.format(cz - start.z), getFeed(feed));
      break;
    case PLANE_YZ:
      writeBlock(gPlaneModal.format(19), gMotionModal.format(clockwise ? 2 : 3), jOutput.format(cy - start.y), kOutput.format(cz - start.z), getFeed(feed));
      break;
    default:
      linearize(tolerance);
    }
  } else if (!getProperty("useRadius")) {
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gPlaneModal.format(17), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x), jOutput.format(cy - start.y), getFeed(feed));
      break;
    case PLANE_ZX:
      writeBlock(gPlaneModal.format(18), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x), kOutput.format(cz - start.z), getFeed(feed));
      break;
    case PLANE_YZ:
      writeBlock(gPlaneModal.format(19), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), jOutput.format(cy - start.y), kOutput.format(cz - start.z), getFeed(feed));
      break;
    default:
      linearize(tolerance);
    }
  } else { // use radius mode
    var r = getCircularRadius();
    if (toDeg(getCircularSweep()) > (180 + 1e-9)) {
      r = -r; // allow up to <360 deg arcs
    }
    switch (getCircularPlane()) {
    case PLANE_XY:
      writeBlock(gPlaneModal.format(17), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), "R" + rFormat.format(r), getFeed(feed));
      break;
    case PLANE_ZX:
      writeBlock(gPlaneModal.format(18), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), "R" + rFormat.format(r), getFeed(feed));
      break;
    case PLANE_YZ:
      writeBlock(gPlaneModal.format(19), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), "R" + rFormat.format(r), getFeed(feed));
      break;
    default:
      linearize(tolerance);
    }
  }
}

var mapCommand = {
  COMMAND_END                     : 2,
  COMMAND_SPINDLE_CLOCKWISE       : 3,
  COMMAND_SPINDLE_COUNTERCLOCKWISE: 4,
  COMMAND_STOP_SPINDLE            : 5,
  COMMAND_ORIENTATE_SPINDLE       : 19,
  COMMAND_LOAD_TOOL               : 6
};

function onCommand(command) {
  switch (command) {
  case COMMAND_STOP:
    writeBlock(mFormat.format(0));
    forceSpindleSpeed = true;
    forceCoolant = true;
    return;
  case COMMAND_OPTIONAL_STOP:
    writeBlock(mFormat.format(1));
    forceSpindleSpeed = true;
    forceCoolant = true;
    return;
  case COMMAND_COOLANT_ON:
    setCoolant(tool.coolant);
    return;
  case COMMAND_COOLANT_OFF:
    setCoolant(COOLANT_OFF);
    return;
  case COMMAND_START_SPINDLE:
    forceSpindleSpeed = false;
    writeBlock(sOutput.format(spindleSpeed), mFormat.format(tool.clockwise ? 3 : 4));
    return;
  case COMMAND_LOAD_TOOL:
    var nextToolCode = "";
    if (getProperty("preloadTool") != "false") {
      var preloadTool = getNextTool(tool.number != getFirstTool().number);
      if (preloadTool) {
        nextToolCode = "T" + toolFormat.format(preloadTool.number); // preload next/first tool
      } else if (getProperty("preloadTool") == "toolChange") {
        nextToolCode = "T" + toolFormat.format(0);
      }
    }
    writeToolBlock("T" + toolFormat.format(tool.number),
      conditional(getProperty("preloadTool") == "toolChange", nextToolCode),
      mFormat.format(6)
    );
    writeComment(tool.comment);
    if (getProperty("preloadTool") == "true" && nextToolCode) {
      writeBlock(nextToolCode);
    }
    return;
  case COMMAND_LOCK_MULTI_AXIS:
    if (machineConfiguration.isMultiAxisConfiguration() && (machineConfiguration.getNumberOfAxes() >= 4)) {
      writeBlock(mClampModal.format(44)); // lock 4th-axis motion
      if (machineConfiguration.getNumberOfAxes() == 5) {
        writeBlock(mClampModal.format(47)); // lock 5th-axis motion
      }
    }
    return;
  case COMMAND_UNLOCK_MULTI_AXIS:
    var outputClampCodes = getProperty("useClampCodes") || currentSection.isMultiAxis();
    if (outputClampCodes && machineConfiguration.isMultiAxisConfiguration() && (machineConfiguration.getNumberOfAxes() >= 4)) {
      writeBlock(mClampModal.format(43)); // unlock 4th-axis motion
      if (machineConfiguration.getNumberOfAxes() == 5) {
        writeBlock(mClampModal.format(46)); // unlock 5th-axis motion
      }
    }
    return;
  case COMMAND_START_CHIP_TRANSPORT:
    return;
  case COMMAND_STOP_CHIP_TRANSPORT:
    return;
  case COMMAND_BREAK_CONTROL:
    return;
  case COMMAND_TOOL_MEASURE:
    return;
  case COMMAND_PROBE_ON:
    return;
  case COMMAND_PROBE_OFF:
    return;
  }

  var stringId = getCommandStringId(command);
  var mcode = mapCommand[stringId];
  if (mcode != undefined) {
    writeBlock(mFormat.format(mcode));
  } else {
    onUnsupportedCommand(command);
  }
}

function onSectionEnd() {
  if (typeof inspectionProcessSectionEnd == "function") {
    inspectionProcessSectionEnd();
  }

  if (currentSection.isMultiAxis()) {
    writeBlock(gFeedModeModal.format(94)); // inverse time feed off
  }

  writeBlock(gPlaneModal.format(17));
  if (!isLastSection() && (getNextSection().getTool().coolant != tool.coolant)) {
    setCoolant(COOLANT_OFF);
  }
  if (((getCurrentSectionId() + 1) >= getNumberOfSections()) ||
      (tool.number != getNextSection().getTool().number)) {
    onCommand(COMMAND_BREAK_CONTROL);
  }

  if (isProbeOperation()) {
    writeBlock(settings.probing.macroCall, "P" + 9833); // spin the probe off
    if (settings.probing.probeAngleMethod != "G68") {
      setProbeAngle(); // output probe angle rotations if required
    }
  }
  forceAny();
}

// Start of onRewindMachine logic
/** Allow user to override the onRewind logic. */
function onRewindMachineEntry(_a, _b, _c) {
  return false;
}

/** Retract to safe position before indexing rotaries. */
function onMoveToSafeRetractPosition() {
  writeRetract(Z);
  // cancel TCP so that tool doesn't follow rotaries
  if (currentSection.isMultiAxis() && tcp.isSupportedByOperation) {
    disableLengthCompensation(false, "TCPC OFF");
  }
}

/** Rotate axes to new position above reentry position */
function onRotateAxes(_x, _y, _z, _a, _b, _c) {
  // position rotary axes
  xOutput.disable();
  yOutput.disable();
  zOutput.disable();
  invokeOnRapid5D(_x, _y, _z, _a, _b, _c);
  setCurrentABC(new Vector(_a, _b, _c));
  xOutput.enable();
  yOutput.enable();
  zOutput.enable();
}

/** Return from safe position after indexing rotaries. */
function onReturnFromSafeRetractPosition(_x, _y, _z) {
  // reinstate TCP / tool length compensation
  if (!lengthCompensationActive) {
    writeBlock(gFormat.format(getOffsetCode()), hFormat.format(tool.lengthOffset));
    lengthCompensationActive = true;
  }

  // position in XY
  forceXYZ();
  xOutput.reset();
  yOutput.reset();
  zOutput.disable();
  invokeOnRapid(_x, _y, _z);

  // position in Z
  zOutput.enable();
  invokeOnRapid(_x, _y, _z);
}
// End of onRewindMachine logic

function onClose() {
  optionalSection = false;
  if (isDPRNTopen) {
    writeln("DPRNT[END]");
    writeBlock("PCLOS");
    isDPRNTopen = false;
    if (typeof inspectionProcessSectionEnd == "function") {
      inspectionProcessSectionEnd();
    }
  }
  if (settings.probing.probeAngleMethod == "G68") {
    cancelWorkPlane();
  }

  writeln("");
  onCommand(COMMAND_STOP_SPINDLE);
  onCommand(COMMAND_COOLANT_OFF);
  writeRetract(Z);
  disableLengthCompensation(true);
  setSmoothing(false);
  forceWorkPlane();
  setWorkPlane(new Vector(0, 0, 0)); // reset working plane

  if (settings.probing.probeAngleMethod == "G54.4") {
    writeBlock(gFormat.format(54.4), "P0");
  }
  writeBlock(mFormat.format(30)); // program end
}

// >>>>> INCLUDED FROM include_files/commonFunctions.cpi
// internal variables, do not change
var receivedMachineConfiguration;
var tcp = {isSupportedByControl:getSetting("supportsTCP", true), isSupportedByMachine:false, isSupportedByOperation:false};
var multiAxisFeedrate;
var sequenceNumber;
var optionalSection = false;
var currentWorkOffset;
var forceSpindleSpeed = false;
var retracted = false; // specifies that the tool has been retracted to the safe plane
var operationNeedsSafeStart = false; // used to convert blocks to optional for safeStartAllOperations

function activateMachine() {
  // disable unsupported rotary axes output
  if (!machineConfiguration.isMachineCoordinate(0) && (typeof aOutput != "undefined")) {
    aOutput.disable();
  }
  if (!machineConfiguration.isMachineCoordinate(1) && (typeof bOutput != "undefined")) {
    bOutput.disable();
  }
  if (!machineConfiguration.isMachineCoordinate(2) && (typeof cOutput != "undefined")) {
    cOutput.disable();
  }

  // setup usage of useTiltedWorkplane
  settings.workPlaneMethod.useTiltedWorkplane = getProperty("useTiltedWorkplane") != undefined ? getProperty("useTiltedWorkplane") :
    getSetting("workPlaneMethod.useTiltedWorkplane", false);
  settings.workPlaneMethod.useABCPrepositioning = getProperty("useABCPrepositioning") != undefined ? getProperty("useABCPrepositioning") :
    getSetting("workPlaneMethod.useABCPrepositioning", false);

  if (!machineConfiguration.isMultiAxisConfiguration()) {
    return; // don't need to modify any settings for 3-axis machines
  }

  // identify if any of the rotary axes has TCP enabled
  var axes = [machineConfiguration.getAxisU(), machineConfiguration.getAxisV(), machineConfiguration.getAxisW()];
  tcp.isSupportedByMachine = axes.some(function(axis) {return axis.isEnabled() && axis.isTCPEnabled();}); // true if TCP is enabled on any rotary axis

  // save multi-axis feedrate settings from machine configuration
  var mode = machineConfiguration.getMultiAxisFeedrateMode();
  var type = mode == FEED_INVERSE_TIME ? machineConfiguration.getMultiAxisFeedrateInverseTimeUnits() :
    (mode == FEED_DPM ? machineConfiguration.getMultiAxisFeedrateDPMType() : DPM_STANDARD);
  multiAxisFeedrate = {
    mode     : mode,
    maximum  : machineConfiguration.getMultiAxisFeedrateMaximum(),
    type     : type,
    tolerance: mode == FEED_DPM ? machineConfiguration.getMultiAxisFeedrateOutputTolerance() : 0,
    bpwRatio : mode == FEED_DPM ? machineConfiguration.getMultiAxisFeedrateBpwRatio() : 1
  };

  // setup of retract/reconfigure  TAG: Only needed until post kernel supports these machine config settings
  if (receivedMachineConfiguration && machineConfiguration.performRewinds()) {
    safeRetractDistance = machineConfiguration.getSafeRetractDistance();
    safePlungeFeed = machineConfiguration.getSafePlungeFeedrate();
    safeRetractFeed = machineConfiguration.getSafeRetractFeedrate();
  }
  if (typeof safeRetractDistance == "number" && getProperty("safeRetractDistance") != undefined && getProperty("safeRetractDistance") != 0) {
    safeRetractDistance = getProperty("safeRetractDistance");
  }

  if (machineConfiguration.isHeadConfiguration()) {
    compensateToolLength = typeof compensateToolLength == "undefined" ? false : compensateToolLength;
  }

  if (machineConfiguration.isHeadConfiguration() && compensateToolLength) {
    for (var i = 0; i < getNumberOfSections(); ++i) {
      var section = getSection(i);
      if (section.isMultiAxis()) {
        machineConfiguration.setToolLength(getBodyLength(section.getTool())); // define the tool length for head adjustments
        section.optimizeMachineAnglesByMachine(machineConfiguration, OPTIMIZE_AXIS);
      }
    }
  } else {
    optimizeMachineAngles2(OPTIMIZE_AXIS);
  }
}

function getBodyLength(tool) {
  for (var i = 0; i < getNumberOfSections(); ++i) {
    var section = getSection(i);
    if (tool.number == section.getTool().number) {
      return section.getParameter("operation:tool_overallLength", tool.bodyLength + tool.holderLength);
    }
  }
  return tool.bodyLength + tool.holderLength;
}

function getFeed(f) {
  if (getProperty("useG95")) {
    return feedOutput.format(f / spindleSpeed); // use feed value
  }
  if (typeof activeMovements != "undefined" && activeMovements) {
    var feedContext = activeMovements[movement];
    if (feedContext != undefined) {
      if (!feedFormat.areDifferent(feedContext.feed, f)) {
        if (feedContext.id == currentFeedId) {
          return ""; // nothing has changed
        }
        forceFeed();
        currentFeedId = feedContext.id;
        return settings.parametricFeeds.feedOutputVariable + (settings.parametricFeeds.firstFeedParameter + feedContext.id);
      }
    }
    currentFeedId = undefined; // force parametric feed next time
  }
  return feedOutput.format(f); // use feed value
}

function validateCommonParameters() {
  validateToolData();
  for (var i = 0; i < getNumberOfSections(); ++i) {
    var section = getSection(i);
    if (getSection(0).workOffset == 0 && section.workOffset > 0) {
      error(localize("Using multiple work offsets is not possible if the initial work offset is 0."));
    }
    if (section.isMultiAxis()) {
      if (!section.isOptimizedForMachine() && !getSetting("supportsToolVectorOutput", false)) {
        error(localize("This postprocessor requires a machine configuration for 5-axis simultaneous toolpath."));
      }
      if (machineConfiguration.getMultiAxisFeedrateMode() == FEED_INVERSE_TIME && !getSetting("supportsInverseTimeFeed", true)) {
        error(localize("This postprocessor does not support inverse time feedrates."));
      }
    }
  }
  if (!tcp.isSupportedByControl && tcp.isSupportedByMachine) {
    error(localize("The machine configuration has TCP enabled which is not supported by this postprocessor."));
  }
  if (getProperty("safePositionMethod") == "clearanceHeight") {
    var msg = "-Attention- Property 'Safe Retracts' is set to 'Clearance Height'." + EOL +
      "Ensure the clearance height will clear the part and or fixtures." + EOL +
      "Raise the Z-axis to a safe height before starting the program.";
    warning(msg);
    writeComment(msg);
  }
}

function validateToolData() {
  var _default = 99999;
  var _maximumSpindleRPM = machineConfiguration.getMaximumSpindleSpeed() > 0 ? machineConfiguration.getMaximumSpindleSpeed() :
    settings.maximumSpindleRPM == undefined ? _default : settings.maximumSpindleRPM;
  var _maximumToolNumber = machineConfiguration.isReceived() && machineConfiguration.getNumberOfTools() > 0 ? machineConfiguration.getNumberOfTools() :
    settings.maximumToolNumber == undefined ? _default : settings.maximumToolNumber;
  var _maximumToolLengthOffset = settings.maximumToolLengthOffset == undefined ? _default : settings.maximumToolLengthOffset;
  var _maximumToolDiameterOffset = settings.maximumToolDiameterOffset == undefined ? _default : settings.maximumToolDiameterOffset;

  var header = ["Detected maximum values are out of range.", "Maximum values:"];
  var warnings = {
    toolNumber    : {msg:"Tool number value exceeds the maximum value for tool: " + EOL, max:" Tool number: " + _maximumToolNumber, values:[]},
    lengthOffset  : {msg:"Tool length offset value exceeds the maximum value for tool: " + EOL, max:" Tool length offset: " + _maximumToolLengthOffset, values:[]},
    diameterOffset: {msg:"Tool diameter offset value exceeds the maximum value for tool: " + EOL, max:" Tool diameter offset: " + _maximumToolDiameterOffset, values:[]},
    spindleSpeed  : {msg:"Spindle speed exceeds the maximum value for operation: " + EOL, max:" Spindle speed: " + _maximumSpindleRPM, values:[]}
  };

  var toolIds = [];
  for (var i = 0; i < getNumberOfSections(); ++i) {
    var section = getSection(i);
    if (toolIds.indexOf(section.getTool().getToolId()) === -1) { // loops only through sections which have a different tool ID
      var toolNumber = section.getTool().number;
      var lengthOffset = section.getTool().lengthOffset;
      var diameterOffset = section.getTool().diameterOffset;
      var comment = section.getParameter("operation-comment", "");

      if (toolNumber > _maximumToolNumber && !getProperty("toolAsName")) {
        warnings.toolNumber.values.push(SP + toolNumber + EOL);
      }
      if (lengthOffset > _maximumToolLengthOffset) {
        warnings.lengthOffset.values.push(SP + "Tool " + toolNumber + " (" + comment + "," + " Length offset: " + lengthOffset + ")" + EOL);
      }
      if (diameterOffset > _maximumToolDiameterOffset) {
        warnings.diameterOffset.values.push(SP + "Tool " + toolNumber + " (" + comment + "," + " Diameter offset: " + diameterOffset + ")" + EOL);
      }
      toolIds.push(section.getTool().getToolId());
    }
    // loop through all sections regardless of tool id for idenitfying spindle speeds

    // identify if movement ramp is used in current toolpath, use ramp spindle speed for comparisons
    var ramp = section.getMovements() & ((1 << MOVEMENT_RAMP) | (1 << MOVEMENT_RAMP_ZIG_ZAG) | (1 << MOVEMENT_RAMP_PROFILE) | (1 << MOVEMENT_RAMP_HELIX));
    var _sectionSpindleSpeed = Math.max(section.getTool().spindleRPM, ramp ? section.getTool().rampingSpindleRPM : 0, 0);
    if (_sectionSpindleSpeed > _maximumSpindleRPM) {
      warnings.spindleSpeed.values.push(SP + section.getParameter("operation-comment", "") + " (" + _sectionSpindleSpeed + " RPM" + ")" + EOL);
    }
  }

  // sort lists by tool number
  warnings.toolNumber.values.sort(function(a, b) {return a - b;});
  warnings.lengthOffset.values.sort(function(a, b) {return a.localeCompare(b);});
  warnings.diameterOffset.values.sort(function(a, b) {return a.localeCompare(b);});

  var warningMessages = [];
  for (var key in warnings) {
    if (warnings[key].values != "") {
      header.push(warnings[key].max); // add affected max values to the header
      warningMessages.push(warnings[key].msg + warnings[key].values.join(""));
    }
  }
  if (warningMessages.length != 0) {
    warningMessages.unshift(header.join(EOL) + EOL);
    warning(warningMessages.join(EOL));
  }
}

function forceFeed() {
  currentFeedId = undefined;
  feedOutput.reset();
}

/** Force output of X, Y, and Z. */
function forceXYZ() {
  xOutput.reset();
  yOutput.reset();
  zOutput.reset();
}

/** Force output of A, B, and C. */
function forceABC() {
  aOutput.reset();
  bOutput.reset();
  cOutput.reset();
}

/** Force output of X, Y, Z, A, B, C, and F on next output. */
function forceAny() {
  forceXYZ();
  forceABC();
  forceFeed();
}

/**
  Writes the specified block.
*/
function writeBlock() {
  var text = formatWords(arguments);
  if (!text) {
    return;
  }
  if ((optionalSection || skipBlocks) && !getSetting("supportsOptionalBlocks", true)) {
    error(localize("Optional blocks are not supported by this post."));
  }
  if (getProperty("showSequenceNumbers") == "true") {
    if (sequenceNumber == undefined || sequenceNumber >= settings.maximumSequenceNumber) {
      sequenceNumber = getProperty("sequenceNumberStart");
    }
    if (optionalSection || skipBlocks) {
      if (text) {
        writeWords("/", "N" + sequenceNumber, text);
      }
    } else {
      writeWords2("N" + sequenceNumber, arguments);
    }
    sequenceNumber += getProperty("sequenceNumberIncrement");
  } else {
    if (optionalSection || skipBlocks) {
      writeWords2("/", arguments);
    } else {
      writeWords(arguments);
    }
  }
}

validate(settings.comments, "Setting 'comments' is required but not defined.");
function formatComment(text) {
  var prefix = settings.comments.prefix;
  var suffix = settings.comments.suffix;
  var _permittedCommentChars = settings.comments.permittedCommentChars == undefined ? "" : settings.comments.permittedCommentChars;
  switch (settings.comments.outputFormat) {
  case "upperCase":
    text = text.toUpperCase();
    _permittedCommentChars = _permittedCommentChars.toUpperCase();
    break;
  case "lowerCase":
    text = text.toLowerCase();
    _permittedCommentChars = _permittedCommentChars.toLowerCase();
    break;
  case "ignoreCase":
    _permittedCommentChars = _permittedCommentChars.toUpperCase() + _permittedCommentChars.toLowerCase();
    break;
  default:
    error(localize("Unsupported option specified for setting 'comments.outputFormat'."));
  }
  if (_permittedCommentChars != "") {
    text = filterText(String(text), _permittedCommentChars);
  }
  text = String(text).substring(0, settings.comments.maximumLineLength - prefix.length - suffix.length);
  return text != "" ?  prefix + text + suffix : "";
}

/**
  Output a comment.
*/
function writeComment(text) {
  if (!text) {
    return;
  }
  var comments = String(text).split(EOL);
  for (comment in comments) {
    var _comment = formatComment(comments[comment]);
    if (_comment) {
      writeln(_comment);
    }
  }
}

function onComment(text) {
  writeComment(text);
}

/**
  Writes the specified block - used for tool changes only.
*/
function writeToolBlock() {
  var show = getProperty("showSequenceNumbers");
  setProperty("showSequenceNumbers", (show == "true" || show == "toolChange") ? "true" : "false");
  writeBlock(arguments);
  setProperty("showSequenceNumbers", show);
}

var skipBlocks = false;
function writeStartBlocks(isRequired, code) {
  var safeSkipBlocks = skipBlocks;
  if (!isRequired) {
    if (!getProperty("safeStartAllOperations", false)) {
      return; // when safeStartAllOperations is disabled, dont output code and return
    }
    // if values are not required, but safe start is enabled - write following blocks as optional
    skipBlocks = true;
  }
  code(); // writes out the code which is passed to this function as an argument
  skipBlocks = safeSkipBlocks; // restore skipBlocks value
}

var pendingRadiusCompensation = -1;
function onRadiusCompensation() {
  pendingRadiusCompensation = radiusCompensation;
  if (pendingRadiusCompensation >= 0 && !getSetting("supportsRadiusCompensation", true)) {
    error(localize("Radius compensation mode is not supported."));
    return;
  }
}

function onPassThrough(text) {
  var commands = String(text).split(",");
  for (text in commands) {
    writeBlock(commands[text]);
  }
}

function forceModals() {
  if (arguments.length == 0) { // reset all modal variables listed below
    if (typeof gMotionModal != "undefined") {
      gMotionModal.reset();
    }
    if (typeof gPlaneModal != "undefined") {
      gPlaneModal.reset();
    }
    if (typeof gAbsIncModal != "undefined") {
      gAbsIncModal.reset();
    }
    if (typeof gFeedModeModal != "undefined") {
      gFeedModeModal.reset();
    }
  } else {
    for (var i in arguments) {
      arguments[i].reset(); // only reset the modal variable passed to this function
    }
  }
}

/** Helper function to be able to use a default value for settings which do not exist. */
function getSetting(setting, defaultValue) {
  var result = defaultValue;
  var keys = setting.split(".");
  var obj = settings;
  for (var i in keys) {
    if (obj[keys[i]] != undefined) { // setting does exist
      result = obj[keys[i]];
      if (typeof [keys[i]] === "object") {
        obj = obj[keys[i]];
        continue;
      }
    } else { // setting does not exist, use default value
      if (defaultValue != undefined) {
        result = defaultValue;
      } else {
        error("Setting '" + keys[i] + "' has no default value and/or does not exist.");
        return undefined;
      }
    }
  }
  return result;
}

function getForwardDirection(_section) {
  var forward = undefined;
  var _optimizeType = settings.workPlaneMethod && settings.workPlaneMethod.optimizeType;
  if (_section.isMultiAxis()) {
    forward = _section.workPlane.forward;
  } else if (!getSetting("workPlaneMethod.useTiltedWorkplane", false) && machineConfiguration.isMultiAxisConfiguration()) {
    if (_optimizeType == undefined) {
      var saveRotation = getRotation();
      getWorkPlaneMachineABC(_section, true);
      forward = getRotation().forward;
      setRotation(saveRotation); // reset rotation
    } else {
      var abc = getWorkPlaneMachineABC(_section, false);
      var forceAdjustment = settings.workPlaneMethod.optimizeType == OPTIMIZE_TABLES || settings.workPlaneMethod.optimizeType == OPTIMIZE_BOTH;
      forward = machineConfiguration.getOptimizedDirection(_section.workPlane.forward, abc, false, forceAdjustment);
    }
  } else {
    forward = getRotation().forward;
  }
  return forward;
}

function getRetractParameters() {
  var words = []; // store all retracted axes in an array
  var retractAxes = new Array(false, false, false);
  var method = getProperty("safePositionMethod", "undefined");
  if (method == "clearanceHeight") {
    if (!is3D()) {
      error(localize("Safe retract option 'Clearance Height' is only supported when all operations are along the setup Z-axis."));
    }
    return undefined;
  }
  validate(settings.retract, "Setting 'retract' is required but not defined.");
  validate(arguments.length != 0, "No axis specified for getRetractParameters().");

  for (i in arguments) {
    retractAxes[arguments[i]] = true;
  }
  if ((retractAxes[0] || retractAxes[1]) && !retracted) { // retract Z first before moving to X/Y home
    error(localize("Retracting in X/Y is not possible without being retracted in Z."));
    return undefined;
  }
  // special conditions
  if (retractAxes[0] || retractAxes[1]) {
    method = getSetting("retract.methodXY", method);
  }
  if (retractAxes[2]) {
    method = getSetting("retract.methodZ", method);
  }
  // define home positions
  var useZeroValues = (settings.retract.useZeroValues && settings.retract.useZeroValues.indexOf(method) != -1);
  var _xHome = machineConfiguration.hasHomePositionX() && !useZeroValues ? machineConfiguration.getHomePositionX() : toPreciseUnit(0, MM);
  var _yHome = machineConfiguration.hasHomePositionY() && !useZeroValues ? machineConfiguration.getHomePositionY() : toPreciseUnit(0, MM);
  var _zHome = machineConfiguration.getRetractPlane() != 0 && !useZeroValues ? machineConfiguration.getRetractPlane() : toPreciseUnit(0, MM);
  for (var i = 0; i < arguments.length; ++i) {
    switch (arguments[i]) {
    case X:
      words.push("X" + xyzFormat.format(_xHome));
      xOutput.reset();
      break;
    case Y:
      words.push("Y" + xyzFormat.format(_yHome));
      yOutput.reset();
      break;
    case Z:
      words.push("Z" + xyzFormat.format(_zHome));
      zOutput.reset();
      retracted = (typeof skipBlocks == "undefined") ? true : !skipBlocks;
      break;
    default:
      error(localize("Unsupported axis specified for getRetractParameters()."));
      return undefined;
    }
  }
  return {method:method, retractAxes:retractAxes, words:words};
}

/** Returns true when subprogram logic does exist into the post. */
function subprogramsAreSupported() {
  return typeof subprogramState != "undefined";
}
// <<<<< INCLUDED FROM include_files/commonFunctions.cpi
// >>>>> INCLUDED FROM include_files/defineMachine.cpi
var compensateToolLength = false; // add the tool length to the pivot distance for nonTCP rotary heads
function defineMachine() {
  var useTCP = true;
  if (false) { // note: setup your machine here
    var aAxis = createAxis({coordinate:0, table:true, axis:[1, 0, 0], range:[-120, 120], preference:1, tcp:useTCP});
    var cAxis = createAxis({coordinate:2, table:true, axis:[0, 0, 1], range:[-360, 360], preference:0, tcp:useTCP});
    machineConfiguration = new MachineConfiguration(aAxis, cAxis);

    setMachineConfiguration(machineConfiguration);
    if (receivedMachineConfiguration) {
      warning(localize("The provided CAM machine configuration is overwritten by the postprocessor."));
      receivedMachineConfiguration = false; // CAM provided machine configuration is overwritten
    }
  }

  if (!receivedMachineConfiguration) {
    // multiaxis settings
    if (machineConfiguration.isHeadConfiguration()) {
      machineConfiguration.setVirtualTooltip(false); // translate the pivot point to the virtual tool tip for nonTCP rotary heads
    }

    // retract / reconfigure
    var performRewinds = false; // set to true to enable the rewind/reconfigure logic
    if (performRewinds) {
      machineConfiguration.enableMachineRewinds(); // enables the retract/reconfigure logic
      safeRetractDistance = (unit == IN) ? 1 : 25; // additional distance to retract out of stock, can be overridden with a property
      safeRetractFeed = (unit == IN) ? 20 : 500; // retract feed rate
      safePlungeFeed = (unit == IN) ? 10 : 250; // plunge feed rate
      machineConfiguration.setSafeRetractDistance(safeRetractDistance);
      machineConfiguration.setSafeRetractFeedrate(safeRetractFeed);
      machineConfiguration.setSafePlungeFeedrate(safePlungeFeed);
      var stockExpansion = new Vector(toPreciseUnit(0.1, IN), toPreciseUnit(0.1, IN), toPreciseUnit(0.1, IN)); // expand stock XYZ values
      machineConfiguration.setRewindStockExpansion(stockExpansion);
    }

    // multi-axis feedrates
    if (machineConfiguration.isMultiAxisConfiguration()) {
      machineConfiguration.setMultiAxisFeedrate(
        useTCP ? FEED_FPM : getProperty("useDPMFeeds") ? FEED_DPM : FEED_INVERSE_TIME,
        9999.99, // maximum output value for inverse time feed rates
        getProperty("useDPMFeeds") ? DPM_COMBINATION : INVERSE_MINUTES, // INVERSE_MINUTES/INVERSE_SECONDS or DPM_COMBINATION/DPM_STANDARD
        0.5, // tolerance to determine when the DPM feed has changed
        1.0 // ratio of rotary accuracy to linear accuracy for DPM calculations
      );
      setMachineConfiguration(machineConfiguration);
    }

    /* home positions */
    // machineConfiguration.setHomePositionX(toPreciseUnit(0, IN));
    // machineConfiguration.setHomePositionY(toPreciseUnit(0, IN));
    // machineConfiguration.setRetractPlane(toPreciseUnit(0, IN));
  }
}
// <<<<< INCLUDED FROM include_files/defineMachine.cpi
// >>>>> INCLUDED FROM include_files/defineWorkPlane.cpi
validate(settings.workPlaneMethod, "Setting 'workPlaneMethod' is required but not defined.");
function defineWorkPlane(_section, _setWorkPlane) {
  var abc = new Vector(0, 0, 0);
  if (settings.workPlaneMethod.forceMultiAxisIndexing || !is3D() || machineConfiguration.isMultiAxisConfiguration()) {
    if (isPolarModeActive()) {
      abc = getCurrentDirection();
    } else if (_section.isMultiAxis()) {
      forceWorkPlane();
      cancelTransformation();
      abc = _section.isOptimizedForMachine() ? _section.getInitialToolAxisABC() : _section.getGlobalInitialToolAxis();
    } else if (settings.workPlaneMethod.useTiltedWorkplane && settings.workPlaneMethod.eulerConvention != undefined) {
      if (settings.workPlaneMethod.eulerCalculationMethod == "machine" && machineConfiguration.isMultiAxisConfiguration()) {
        abc = machineConfiguration.getOrientation(getWorkPlaneMachineABC(_section, true)).getEuler2(settings.workPlaneMethod.eulerConvention);
      } else {
        abc = _section.workPlane.getEuler2(settings.workPlaneMethod.eulerConvention);
      }
    } else {
      abc = getWorkPlaneMachineABC(_section, true);
    }

    if (_setWorkPlane) {
      if (_section.isMultiAxis() || isPolarModeActive()) { // 4-5x simultaneous operations
        cancelWorkPlane();
        positionABC(abc, true);
      } else { // 3x and/or 3+2x operations
        setWorkPlane(abc);
      }
    }
  } else {
    var remaining = _section.workPlane;
    if (!isSameDirection(remaining.forward, new Vector(0, 0, 1))) {
      error(localize("Tool orientation is not supported."));
      return abc;
    }
    setRotation(remaining);
  }
  tcp.isSupportedByOperation = isTCPSupportedByOperation(_section);
  return abc;
}

function isTCPSupportedByOperation(_section) {
  var _tcp = _section.getOptimizedTCPMode() == OPTIMIZE_NONE;
  if (!_section.isMultiAxis() && (settings.workPlaneMethod.useTiltedWorkplane ||
    isSameDirection(machineConfiguration.getSpindleAxis(), getForwardDirection(_section)) ||
    settings.workPlaneMethod.optimizeType == OPTIMIZE_HEADS ||
    settings.workPlaneMethod.optimizeType == OPTIMIZE_TABLES ||
    settings.workPlaneMethod.optimizeType == OPTIMIZE_BOTH)) {
    _tcp = false;
  }
  return _tcp;
}
// <<<<< INCLUDED FROM include_files/defineWorkPlane.cpi
// >>>>> INCLUDED FROM include_files/getWorkPlaneMachineABC.cpi
validate(settings.machineAngles, "Setting 'machineAngles' is required but not defined.");
function getWorkPlaneMachineABC(_section, rotate) {
  var currentABC = isFirstSection() ? new Vector(0, 0, 0) : getCurrentABC();
  var abc = machineConfiguration.getABCByPreference(_section.workPlane, currentABC, settings.machineAngles.controllingAxis, settings.machineAngles.type, settings.machineAngles.options);
  if (!isSameDirection(machineConfiguration.getDirection(abc), _section.workPlane.forward)) {
    error(localize("Orientation not supported."));
  }
  if (rotate) {
    if (settings.workPlaneMethod.optimizeType == undefined || settings.workPlaneMethod.useTiltedWorkplane) { // legacy
      var useTCP = false;
      var R = machineConfiguration.getRemainingOrientation(abc, _section.workPlane);
      setRotation(useTCP ? _section.workPlane : R);
    } else {
      if (!_section.isOptimizedForMachine()) {
        machineConfiguration.setToolLength(compensateToolLength ? _section.getTool().overallLength : 0); // define the tool length for head adjustments
        _section.optimize3DPositionsByMachine(machineConfiguration, abc, settings.workPlaneMethod.optimizeType);
      }
    }
  }
  return abc;
}
// <<<<< INCLUDED FROM include_files/getWorkPlaneMachineABC.cpi
// >>>>> INCLUDED FROM include_files/coolant.cpi
var currentCoolantMode = COOLANT_OFF;
var coolantOff = undefined;
var isOptionalCoolant = false;
var forceCoolant = false;

function setCoolant(coolant) {
  var coolantCodes = getCoolantCodes(coolant);
  if (Array.isArray(coolantCodes)) {
    writeStartBlocks(!isOptionalCoolant, function () {
      if (settings.coolant.singleLineCoolant) {
        writeBlock(coolantCodes.join(getWordSeparator()));
      } else {
        for (var c in coolantCodes) {
          writeBlock(coolantCodes[c]);
        }
      }
    });
    return undefined;
  }
  return coolantCodes;
}

function getCoolantCodes(coolant, format) {
  if (!getProperty("useCoolant", true)) {
    return undefined; // coolant output is disabled by property if it exists
  }
  isOptionalCoolant = false;
  if (typeof operationNeedsSafeStart == "undefined") {
    operationNeedsSafeStart = false;
  }
  var multipleCoolantBlocks = new Array(); // create a formatted array to be passed into the outputted line
  var coolants = settings.coolant.coolants;
  if (!coolants) {
    error(localize("Coolants have not been defined."));
  }
  if (tool.type && tool.type == TOOL_PROBE) { // avoid coolant output for probing
    coolant = COOLANT_OFF;
  }
  if (coolant == currentCoolantMode) {
    if (operationNeedsSafeStart && coolant != COOLANT_OFF) {
      isOptionalCoolant = true;
    } else if (!forceCoolant || coolant == COOLANT_OFF) {
      return undefined; // coolant is already active
    }
  }
  if ((coolant != COOLANT_OFF) && (currentCoolantMode != COOLANT_OFF) && (coolantOff != undefined) && !forceCoolant && !isOptionalCoolant) {
    if (Array.isArray(coolantOff)) {
      for (var i in coolantOff) {
        multipleCoolantBlocks.push(coolantOff[i]);
      }
    } else {
      multipleCoolantBlocks.push(coolantOff);
    }
  }
  forceCoolant = false;

  var m;
  var coolantCodes = {};
  for (var c in coolants) { // find required coolant codes into the coolants array
    if (coolants[c].id == coolant) {
      coolantCodes.on = coolants[c].on;
      if (coolants[c].off != undefined) {
        coolantCodes.off = coolants[c].off;
        break;
      } else {
        for (var i in coolants) {
          if (coolants[i].id == COOLANT_OFF) {
            coolantCodes.off = coolants[i].off;
            break;
          }
        }
      }
    }
  }
  if (coolant == COOLANT_OFF) {
    m = !coolantOff ? coolantCodes.off : coolantOff; // use the default coolant off command when an 'off' value is not specified
  } else {
    coolantOff = coolantCodes.off;
    m = coolantCodes.on;
  }

  if (!m) {
    onUnsupportedCoolant(coolant);
    m = 9;
  } else {
    if (Array.isArray(m)) {
      for (var i in m) {
        multipleCoolantBlocks.push(m[i]);
      }
    } else {
      multipleCoolantBlocks.push(m);
    }
    currentCoolantMode = coolant;
    for (var i in multipleCoolantBlocks) {
      if (typeof multipleCoolantBlocks[i] == "number") {
        multipleCoolantBlocks[i] = mFormat.format(multipleCoolantBlocks[i]);
      }
    }
    if (format == undefined || format) {
      return multipleCoolantBlocks; // return the single formatted coolant value
    } else {
      return m; // return unformatted coolant value
    }
  }
  return undefined;
}
// <<<<< INCLUDED FROM include_files/coolant.cpi
// >>>>> INCLUDED FROM include_files/smoothing.cpi
// collected state below, do not edit
validate(settings.smoothing, "Setting 'smoothing' is required but not defined.");
var smoothing = {
  cancel     : false, // cancel tool length prior to update smoothing for this operation
  isActive   : false, // the current state of smoothing
  isAllowed  : false, // smoothing is allowed for this operation
  isDifferent: false, // tells if smoothing levels/tolerances/both are different between operations
  level      : -1, // the active level of smoothing
  tolerance  : -1, // the current operation tolerance
  force      : false // smoothing needs to be forced out in this operation
};

function initializeSmoothing() {
  var smoothingSettings = settings.smoothing;
  var previousLevel = smoothing.level;
  var previousTolerance = xyzFormat.getResultingValue(smoothing.tolerance);

  // format threshold parameters
  var thresholdRoughing = xyzFormat.getResultingValue(smoothingSettings.thresholdRoughing);
  var thresholdSemiFinishing = xyzFormat.getResultingValue(smoothingSettings.thresholdSemiFinishing);
  var thresholdFinishing = xyzFormat.getResultingValue(smoothingSettings.thresholdFinishing);

  // determine new smoothing levels and tolerances
  smoothing.level = parseInt(getProperty("useSmoothing"), 10);
  smoothing.level = isNaN(smoothing.level) ? -1 : smoothing.level;
  smoothing.tolerance = xyzFormat.getResultingValue(Math.max(getParameter("operation:tolerance", thresholdFinishing), 0));

  if (smoothing.level == 9999) {
    if (smoothingSettings.autoLevelCriteria == "stock") { // determine auto smoothing level based on stockToLeave
      var stockToLeave = xyzFormat.getResultingValue(getParameter("operation:stockToLeave", 0));
      var verticalStockToLeave = xyzFormat.getResultingValue(getParameter("operation:verticalStockToLeave", 0));
      if (((stockToLeave >= thresholdRoughing) && (verticalStockToLeave >= thresholdRoughing)) || getParameter("operation:strategy", "") == "face") {
        smoothing.level = smoothingSettings.roughing; // set roughing level
      } else {
        if (((stockToLeave >= thresholdSemiFinishing) && (stockToLeave < thresholdRoughing)) &&
          ((verticalStockToLeave >= thresholdSemiFinishing) && (verticalStockToLeave  < thresholdRoughing))) {
          smoothing.level = smoothingSettings.semi; // set semi level
        } else if (((stockToLeave >= thresholdFinishing) && (stockToLeave < thresholdSemiFinishing)) &&
          ((verticalStockToLeave >= thresholdFinishing) && (verticalStockToLeave  < thresholdSemiFinishing))) {
          smoothing.level = smoothingSettings.semifinishing; // set semi-finishing level
        } else {
          smoothing.level = smoothingSettings.finishing; // set finishing level
        }
      }
    } else { // detemine auto smoothing level based on operation tolerance instead of stockToLeave
      if (smoothing.tolerance >= thresholdRoughing || getParameter("operation:strategy", "") == "face") {
        smoothing.level = smoothingSettings.roughing; // set roughing level
      } else {
        if (((smoothing.tolerance >= thresholdSemiFinishing) && (smoothing.tolerance < thresholdRoughing))) {
          smoothing.level = smoothingSettings.semi; // set semi level
        } else if (((smoothing.tolerance >= thresholdFinishing) && (smoothing.tolerance < thresholdSemiFinishing))) {
          smoothing.level = smoothingSettings.semifinishing; // set semi-finishing level
        } else {
          smoothing.level = smoothingSettings.finishing; // set finishing level
        }
      }
    }
  }

  if (smoothing.level == -1) { // useSmoothing is disabled
    smoothing.isAllowed = false;
  } else { // do not output smoothing for the following operations
    smoothing.isAllowed = !(currentSection.getTool().type == TOOL_PROBE || isDrillingCycle());
  }
  if (!smoothing.isAllowed) {
    smoothing.level = -1;
    smoothing.tolerance = -1;
  }

  switch (smoothingSettings.differenceCriteria) {
  case "level":
    smoothing.isDifferent = smoothing.level != previousLevel;
    break;
  case "tolerance":
    smoothing.isDifferent = smoothing.tolerance != previousTolerance;
    break;
  case "both":
    smoothing.isDifferent = smoothing.level != previousLevel || smoothing.tolerance != previousTolerance;
    break;
  default:
    error(localize("Unsupported smoothing criteria."));
    return;
  }

  // tool length compensation needs to be canceled when smoothing state/level changes
  if (smoothingSettings.cancelCompensation) {
    smoothing.cancel = !isFirstSection() && smoothing.isDifferent;
  }
}
// <<<<< INCLUDED FROM include_files/smoothing.cpi
// >>>>> INCLUDED FROM include_files/positionABC.cpi
function positionABC(abc, force) {
  if (typeof unwindABC == "function") {
    unwindABC(abc);
  }
  if (force) {
    forceABC();
  }
  var a = machineConfiguration.isMultiAxisConfiguration() ? aOutput.format(abc.x) : toolVectorOutputI.format(abc.x);
  var b = machineConfiguration.isMultiAxisConfiguration() ? bOutput.format(abc.y) : toolVectorOutputJ.format(abc.y);
  var c = machineConfiguration.isMultiAxisConfiguration() ? cOutput.format(abc.z) : toolVectorOutputK.format(abc.z);
  if (a || b || c) {
    if (!retracted) {
      if (typeof moveToSafeRetractPosition == "function") {
        moveToSafeRetractPosition();
      } else {
        writeRetract(Z);
      }
    }
    onCommand(COMMAND_UNLOCK_MULTI_AXIS);
    gMotionModal.reset();
    writeBlock(gMotionModal.format(0), a, b, c);

    if (getCurrentSectionId() != -1) {
      setCurrentABC(abc); // required for machine simulation
    }
  }
}
// <<<<< INCLUDED FROM include_files/positionABC.cpi
// >>>>> INCLUDED FROM include_files/writeWCS.cpi
function writeWCS(section, wcsIsRequired) {
  if (section.workOffset != currentWorkOffset) {
    if (getSetting("workPlaneMethod.cancelTiltFirst", false) && wcsIsRequired) {
      cancelWorkPlane();
    }
    if (typeof forceWorkPlane == "function" && wcsIsRequired) {
      forceWorkPlane();
    }
    writeStartBlocks(wcsIsRequired, function () {
      writeBlock(section.wcs);
    });
    currentWorkOffset = section.workOffset;
  }
}
// <<<<< INCLUDED FROM include_files/writeWCS.cpi
// >>>>> INCLUDED FROM include_files/writeProgramHeader.cpi
properties.writeMachine = {
  title      : "Write machine",
  description: "Output the machine settings in the header of the program.",
  group      : "formats",
  type       : "boolean",
  value      : true,
  scope      : "post"
};
properties.writeTools = {
  title      : "Write tool list",
  description: "Output a tool list in the header of the program.",
  group      : "formats",
  type       : "boolean",
  value      : true,
  scope      : "post"
};
function writeProgramHeader() {
  // dump machine configuration
  var vendor = machineConfiguration.getVendor();
  var model = machineConfiguration.getModel();
  var mDescription = machineConfiguration.getDescription();
  if (getProperty("writeMachine") && (vendor || model || mDescription)) {
    writeComment(localize("Machine"));
    if (vendor) {
      writeComment("  " + localize("vendor") + ": " + vendor);
    }
    if (model) {
      writeComment("  " + localize("model") + ": " + model);
    }
    if (mDescription) {
      writeComment("  " + localize("description") + ": "  + mDescription);
    }
  }

  // dump tool information
  if (getProperty("writeTools")) {
    if (false) { // set to true to use the post kernel version of the tool list
      writeToolTable(TOOL_NUMBER_COL);
    } else {
      var zRanges = {};
      if (is3D()) {
        var numberOfSections = getNumberOfSections();
        for (var i = 0; i < numberOfSections; ++i) {
          var section = getSection(i);
          var zRange = section.getGlobalZRange();
          var tool = section.getTool();
          if (zRanges[tool.number]) {
            zRanges[tool.number].expandToRange(zRange);
          } else {
            zRanges[tool.number] = zRange;
          }
        }
      }
      var tools = getToolTable();
      if (tools.getNumberOfTools() > 0) {
        for (var i = 0; i < tools.getNumberOfTools(); ++i) {
          var tool = tools.getTool(i);
          var comment = "T" + toolFormat.format(tool.number) + " " +
          "D=" + xyzFormat.format(tool.diameter) + " " +
          localize("CR") + "=" + xyzFormat.format(tool.cornerRadius);
          if ((tool.taperAngle > 0) && (tool.taperAngle < Math.PI)) {
            comment += " " + localize("TAPER") + "=" + taperFormat.format(tool.taperAngle) + localize("deg");
          }
          if (zRanges[tool.number]) {
            comment += " - " + localize("ZMIN") + "=" + xyzFormat.format(zRanges[tool.number].getMinimum());
          }
          comment += " - " + getToolTypeName(tool.type);
          writeComment(comment);
        }
      }
    }
  }
}
// <<<<< INCLUDED FROM include_files/writeProgramHeader.cpi
// >>>>> INCLUDED FROM include_files/parametricFeeds.cpi
properties.useParametricFeed = {
  title      : "Parametric feed",
  description: "Specifies that the feedrates should be output using parameters.",
  group      : "preferences",
  type       : "boolean",
  value      : false,
  scope      : "post"
};
var activeMovements;
var currentFeedId;
validate(settings.parametricFeeds, "Setting 'parametricFeeds' is required but not defined.");
function initializeParametricFeeds(insertToolCall) {
  if (getProperty("useParametricFeed") && getParameter("operation-strategy") != "drill" && !currentSection.hasAnyCycle()) {
    if (!insertToolCall && activeMovements && (getCurrentSectionId() > 0) &&
      ((getPreviousSection().getPatternId() == currentSection.getPatternId()) && (currentSection.getPatternId() != 0))) {
      return; // use the current feeds
    }
  } else {
    activeMovements = undefined;
    return;
  }

  activeMovements = new Array();
  var movements = currentSection.getMovements();

  var id = 0;
  var activeFeeds = new Array();
  if (hasParameter("operation:tool_feedCutting")) {
    if (movements & ((1 << MOVEMENT_CUTTING) | (1 << MOVEMENT_LINK_TRANSITION) | (1 << MOVEMENT_EXTENDED))) {
      var feedContext = new FeedContext(id, localize("Cutting"), getParameter("operation:tool_feedCutting"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_CUTTING] = feedContext;
      if (!hasParameter("operation:tool_feedTransition")) {
        activeMovements[MOVEMENT_LINK_TRANSITION] = feedContext;
      }
      activeMovements[MOVEMENT_EXTENDED] = feedContext;
    }
    ++id;
    if (movements & (1 << MOVEMENT_PREDRILL)) {
      feedContext = new FeedContext(id, localize("Predrilling"), getParameter("operation:tool_feedCutting"));
      activeMovements[MOVEMENT_PREDRILL] = feedContext;
      activeFeeds.push(feedContext);
    }
    ++id;
  }
  if (hasParameter("operation:finishFeedrate")) {
    if (movements & (1 << MOVEMENT_FINISH_CUTTING)) {
      var feedContext = new FeedContext(id, localize("Finish"), getParameter("operation:finishFeedrate"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_FINISH_CUTTING] = feedContext;
    }
    ++id;
  } else if (hasParameter("operation:tool_feedCutting")) {
    if (movements & (1 << MOVEMENT_FINISH_CUTTING)) {
      var feedContext = new FeedContext(id, localize("Finish"), getParameter("operation:tool_feedCutting"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_FINISH_CUTTING] = feedContext;
    }
    ++id;
  }
  if (hasParameter("operation:tool_feedEntry")) {
    if (movements & (1 << MOVEMENT_LEAD_IN)) {
      var feedContext = new FeedContext(id, localize("Entry"), getParameter("operation:tool_feedEntry"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LEAD_IN] = feedContext;
    }
    ++id;
  }
  if (hasParameter("operation:tool_feedExit")) {
    if (movements & (1 << MOVEMENT_LEAD_OUT)) {
      var feedContext = new FeedContext(id, localize("Exit"), getParameter("operation:tool_feedExit"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LEAD_OUT] = feedContext;
    }
    ++id;
  }
  if (hasParameter("operation:noEngagementFeedrate")) {
    if (movements & (1 << MOVEMENT_LINK_DIRECT)) {
      var feedContext = new FeedContext(id, localize("Direct"), getParameter("operation:noEngagementFeedrate"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LINK_DIRECT] = feedContext;
    }
    ++id;
  } else if (hasParameter("operation:tool_feedCutting") &&
             hasParameter("operation:tool_feedEntry") &&
             hasParameter("operation:tool_feedExit")) {
    if (movements & (1 << MOVEMENT_LINK_DIRECT)) {
      var feedContext = new FeedContext(id, localize("Direct"), Math.max(getParameter("operation:tool_feedCutting"), getParameter("operation:tool_feedEntry"), getParameter("operation:tool_feedExit")));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LINK_DIRECT] = feedContext;
    }
    ++id;
  }
  if (hasParameter("operation:reducedFeedrate")) {
    if (movements & (1 << MOVEMENT_REDUCED)) {
      var feedContext = new FeedContext(id, localize("Reduced"), getParameter("operation:reducedFeedrate"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_REDUCED] = feedContext;
    }
    ++id;
  }
  if (hasParameter("operation:tool_feedRamp")) {
    if (movements & ((1 << MOVEMENT_RAMP) | (1 << MOVEMENT_RAMP_HELIX) | (1 << MOVEMENT_RAMP_PROFILE) | (1 << MOVEMENT_RAMP_ZIG_ZAG))) {
      var feedContext = new FeedContext(id, localize("Ramping"), getParameter("operation:tool_feedRamp"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_RAMP] = feedContext;
      activeMovements[MOVEMENT_RAMP_HELIX] = feedContext;
      activeMovements[MOVEMENT_RAMP_PROFILE] = feedContext;
      activeMovements[MOVEMENT_RAMP_ZIG_ZAG] = feedContext;
    }
    ++id;
  }
  if (hasParameter("operation:tool_feedPlunge")) {
    if (movements & (1 << MOVEMENT_PLUNGE)) {
      var feedContext = new FeedContext(id, localize("Plunge"), getParameter("operation:tool_feedPlunge"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_PLUNGE] = feedContext;
    }
    ++id;
  }
  if (true) { // high feed
    if ((movements & (1 << MOVEMENT_HIGH_FEED)) || (highFeedMapping != HIGH_FEED_NO_MAPPING)) {
      var feed;
      if (hasParameter("operation:highFeedrateMode") && getParameter("operation:highFeedrateMode") != "disabled") {
        feed = getParameter("operation:highFeedrate");
      } else {
        feed = this.highFeedrate;
      }
      var feedContext = new FeedContext(id, localize("High Feed"), feed);
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_HIGH_FEED] = feedContext;
      activeMovements[MOVEMENT_RAPID] = feedContext;
    }
    ++id;
  }
  if (hasParameter("operation:tool_feedTransition")) {
    if (movements & (1 << MOVEMENT_LINK_TRANSITION)) {
      var feedContext = new FeedContext(id, localize("Transition"), getParameter("operation:tool_feedTransition"));
      activeFeeds.push(feedContext);
      activeMovements[MOVEMENT_LINK_TRANSITION] = feedContext;
    }
    ++id;
  }

  for (var i = 0; i < activeFeeds.length; ++i) {
    var feedContext = activeFeeds[i];
    var feedDescription = typeof formatComment == "function" ? formatComment(feedContext.description) : feedContext.description;
    writeBlock(settings.parametricFeeds.feedAssignmentVariable + (settings.parametricFeeds.firstFeedParameter + feedContext.id) + "=" + feedFormat.format(feedContext.feed) + SP + feedDescription);
  }
}

function FeedContext(id, description, feed) {
  this.id = id;
  this.description = description;
  this.feed = feed;
}
// <<<<< INCLUDED FROM include_files/parametricFeeds.cpi
// >>>>> INCLUDED FROM include_files/writeToolCall.cpi
function writeToolCall(tool, insertToolCall) {
  if (typeof forceModals == "function" && (insertToolCall || getProperty("safeStartAllOperations"))) {
    forceModals();
  }
  writeStartBlocks(insertToolCall, function () {
    if (!retracted) {
      writeRetract(Z);
    }
    if (!isFirstSection() && insertToolCall) {
      if (typeof forceWorkPlane == "function") {
        forceWorkPlane();
      }
      onCommand(COMMAND_COOLANT_OFF); // turn off coolant on tool change
      if (typeof disableLengthCompensation == "function") {
        disableLengthCompensation(false);
      }
    }

    if (tool.manualToolChange) {
      onCommand(COMMAND_STOP);
      writeComment("MANUAL TOOL CHANGE TO T" + toolFormat.format(tool.number));
    } else {
      if (!isFirstSection() && getProperty("optionalStop") && insertToolCall) {
        onCommand(COMMAND_OPTIONAL_STOP);
      }
      onCommand(COMMAND_LOAD_TOOL);
    }
  });
}
// <<<<< INCLUDED FROM include_files/writeToolCall.cpi
// >>>>> INCLUDED FROM include_files/startSpindle.cpi

function startSpindle(tool, insertToolCall) {
  if (tool.type != TOOL_PROBE) {
    var spindleSpeedIsRequired = insertToolCall || forceSpindleSpeed || isFirstSection() ||
      rpmFormat.areDifferent(spindleSpeed, sOutput.getCurrent()) ||
      (tool.clockwise != getPreviousSection().getTool().clockwise);

    writeStartBlocks(spindleSpeedIsRequired, function () {
      if (spindleSpeedIsRequired || operationNeedsSafeStart) {
        onCommand(COMMAND_START_SPINDLE);
      }
    });
  }
}
// <<<<< INCLUDED FROM include_files/startSpindle.cpi

// >>>>> INCLUDED FROM include_files/writeRetract_fanuc.cpi
function writeRetract() {
  var retract = getRetractParameters.apply(this, arguments);
  if (retract && retract.words.length > 0) {
    if (typeof gRotationModal != "undefined" && gRotationModal.getCurrent() == 68 && settings.retract.cancelRotationOnRetracting) { // cancel rotation before retracting
      cancelWorkPlane(true);
    }
    switch (retract.method) {
    case "G28":
      forceModals(gMotionModal, gAbsIncModal);
      writeBlock(gFormat.format(28), gAbsIncModal.format(91), retract.words);
      writeBlock(gAbsIncModal.format(90));
      break;
    case "G30":
      forceModals(gMotionModal, gAbsIncModal);
      writeBlock(gFormat.format(30), gAbsIncModal.format(91), retract.words);
      writeBlock(gAbsIncModal.format(90));
      break;
    case "G53":
      forceModals(gMotionModal);
      writeBlock(gAbsIncModal.format(90), gFormat.format(53), gMotionModal.format(0), retract.words);
      break;
    default:
      if (typeof writeRetractCustom == "function") {
        writeRetractCustom(retract);
      } else {
        error(subst(localize("Unsupported safe position method '%1'"), retract.method));
        return;
      }
    }
  }
}
// <<<<< INCLUDED FROM include_files/writeRetract_fanuc.cpi
// >>>>> INCLUDED FROM include_files/initialPositioning_fanuc.cpi
/**
 * Writes the initial positioning procedure for a section to get to the start position of the toolpath.
 * @param {Vector} position The initial position to move to
 * @param {boolean} isRequired true: Output full positioning, false: Output full positioning in optional state or output simple positioning only
 * @param {String} codes1 Allows to add additional code to the first positioning line
 * @param {String} codes2 Allows to add additional code to the second positioning line (if applicable)
 * @example
  var myVar1 = formatWords("T" + tool.number, currentSection.wcs);
  var myVar2 = getCoolantCodes(tool.coolant);
  writeInitialPositioning(initialPosition, isRequired, myVar1, myVar2);
*/
function writeInitialPositioning(position, isRequired, codes1, codes2) {
  var motionCode = {single:0, multi:0};
  switch (highFeedMapping) {
  case HIGH_FEED_MAP_ANY:
    motionCode = {single:1, multi:1}; // map all rapid traversals to high feed
    break;
  case HIGH_FEED_MAP_MULTI:
    motionCode = {single:0, multi:1}; // map rapid traversal along more than one axis to high feed
    break;
  }
  var feed = (highFeedMapping != HIGH_FEED_NO_MAPPING) ? getFeed(highFeedrate) : "";
  var gOffset = getSetting("outputToolLengthCompensation", true) ? gFormat.format(getOffsetCode()) : "";
  var hOffset = getSetting("outputToolLengthOffset", true) ? hFormat.format(tool.lengthOffset) : "";
  var additionalCodes = [formatWords(codes1), formatWords(codes2)];

  forceModals(gMotionModal);
  writeStartBlocks(isRequired, function() {
    var modalCodes = formatWords(gAbsIncModal.format(90), gPlaneModal.format(17));
    if (typeof disableLengthCompensation == "function") {
      disableLengthCompensation(false); // cancel tool length compensation prior to enabling it, required when switching G43/G43.4 modes
    }

    // multi axis prepositioning with TWP
    if (currentSection.isMultiAxis() && getSetting("workPlaneMethod.prepositionWithTWP", true) && getSetting("workPlaneMethod.useTiltedWorkplane", false) &&
      tcp.isSupportedByOperation && getCurrentDirection().isNonZero()) {
      var W = machineConfiguration.isMultiAxisConfiguration() ? machineConfiguration.getOrientation(getCurrentDirection()) :
        Matrix.getOrientationFromDirection(getCurrentDirection());
      var prePosition = W.getTransposed().multiply(position);
      var angles = W.getEuler2(settings.workPlaneMethod.eulerConvention);
      setWorkPlane(angles);
      writeBlock(modalCodes, gMotionModal.format(motionCode.multi), xOutput.format(prePosition.x), yOutput.format(prePosition.y), feed, additionalCodes[0]);
      cancelWorkPlane();
      writeBlock(gOffset, hOffset, additionalCodes[1]); // omit Z-axis output is desired
      lengthCompensationActive = true;
      forceAny(); // required to output XYZ coordinates in the following line
    } else {
      if (machineConfiguration.isHeadConfiguration()) {
        writeBlock(modalCodes, gMotionModal.format(motionCode.multi), gOffset,
          xOutput.format(position.x), yOutput.format(position.y), zOutput.format(position.z),
          hOffset, feed, additionalCodes
        );
      } else {
        writeBlock(modalCodes, gMotionModal.format(motionCode.multi), xOutput.format(position.x), yOutput.format(position.y), feed, additionalCodes[0]);
        writeBlock(gMotionModal.format(motionCode.single), gOffset, zOutput.format(position.z), hOffset, additionalCodes[1]);
      }
      lengthCompensationActive = true;
    }
    forceModals(gMotionModal);
    if (isRequired) {
      additionalCodes = []; // clear additionalCodes buffer
    }
  });

  validate(lengthCompensationActive, "Tool length compensation is not active."); // make sure that lenght compensation is enabled
  if (!isRequired) { // simple positioning
    var modalCodes = formatWords(gAbsIncModal.format(90), gPlaneModal.format(17));
    if (!retracted && xyzFormat.getResultingValue(getCurrentPosition().z) < xyzFormat.getResultingValue(position.z)) {
      writeBlock(modalCodes, gMotionModal.format(motionCode.single), zOutput.format(position.z), feed);
    }
    forceXYZ();
    writeBlock(modalCodes, gMotionModal.format(motionCode.multi), xOutput.format(position.x), yOutput.format(position.y), feed, additionalCodes);
  }
}

Matrix.getOrientationFromDirection = function (ijk) {
  var forward = ijk;
  var unitZ = new Vector(0, 0, 1);
  var W;
  if (Math.abs(Vector.dot(forward, unitZ)) < 0.5) {
    var imX = Vector.cross(forward, unitZ).getNormalized();
    W = new Matrix(imX, Vector.cross(forward, imX), forward);
  } else {
    var imX = Vector.cross(new Vector(0, 1, 0), forward).getNormalized();
    W = new Matrix(imX, Vector.cross(forward, imX), forward);
  }
  return W;
};
// <<<<< INCLUDED FROM include_files/initialPositioning_fanuc.cpi
// >>>>> INCLUDED FROM include_files/getOffsetCode_fanuc.cpi
function getOffsetCode() {
  var offsetCode = 43;
  if (tcp.isSupportedByOperation) {
    offsetCode = machineConfiguration.isMultiAxisConfiguration() ? 43.4 : 43.5;
  }
  return offsetCode;
}
// <<<<< INCLUDED FROM include_files/getOffsetCode_fanuc.cpi
// >>>>> INCLUDED FROM include_files/onRapid_fanuc.cpi
function onRapid(_x, _y, _z) {
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  if (x || y || z) {
    if (pendingRadiusCompensation >= 0) {
      error(localize("Radius compensation mode cannot be changed at rapid traversal."));
      return;
    }
    writeBlock(gMotionModal.format(0), x, y, z);
    forceFeed();
  }
}
// <<<<< INCLUDED FROM include_files/onRapid_fanuc.cpi
// >>>>> INCLUDED FROM include_files/onLinear_fanuc.cpi
function onLinear(_x, _y, _z, feed) {
  if (pendingRadiusCompensation >= 0) {
    xOutput.reset();
    yOutput.reset();
  }
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var f = getFeed(feed);
  if (x || y || z) {
    if (pendingRadiusCompensation >= 0) {
      pendingRadiusCompensation = -1;
      var d = getSetting("outputToolDiameterOffset", true) ? diameterOffsetFormat.format(tool.diameterOffset) : "";
      writeBlock(gPlaneModal.format(17));
      switch (radiusCompensation) {
      case RADIUS_COMPENSATION_LEFT:
        writeBlock(gMotionModal.format(1), gFormat.format(41), x, y, z, d, f);
        break;
      case RADIUS_COMPENSATION_RIGHT:
        writeBlock(gMotionModal.format(1), gFormat.format(42), x, y, z, d, f);
        break;
      default:
        writeBlock(gMotionModal.format(1), gFormat.format(40), x, y, z, f);
      }
    } else {
      writeBlock(gMotionModal.format(1), x, y, z, f);
    }
  } else if (f) {
    if (getNextRecord().isMotion()) { // try not to output feed without motion
      forceFeed(); // force feed on next line
    } else {
      writeBlock(gMotionModal.format(1), f);
    }
  }
}
// <<<<< INCLUDED FROM include_files/onLinear_fanuc.cpi
// >>>>> INCLUDED FROM include_files/onRapid5D_fanuc.cpi
function onRapid5D(_x, _y, _z, _a, _b, _c) {
  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation mode cannot be changed at rapid traversal."));
    return;
  }
  if (!currentSection.isOptimizedForMachine()) {
    forceXYZ();
  }
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var a = currentSection.isOptimizedForMachine() ? aOutput.format(_a) : toolVectorOutputI.format(_a);
  var b = currentSection.isOptimizedForMachine() ? bOutput.format(_b) : toolVectorOutputJ.format(_b);
  var c = currentSection.isOptimizedForMachine() ? cOutput.format(_c) : toolVectorOutputK.format(_c);

  if (x || y || z || a || b || c) {
    writeBlock(gMotionModal.format(0), x, y, z, a, b, c);
    forceFeed();
  }
}
// <<<<< INCLUDED FROM include_files/onRapid5D_fanuc.cpi
// >>>>> INCLUDED FROM include_files/onLinear5D_fanuc.cpi
function onLinear5D(_x, _y, _z, _a, _b, _c, feed, feedMode) {
  if (pendingRadiusCompensation >= 0) {
    error(localize("Radius compensation cannot be activated/deactivated for 5-axis move."));
    return;
  }
  if (!currentSection.isOptimizedForMachine()) {
    forceXYZ();
  }
  var x = xOutput.format(_x);
  var y = yOutput.format(_y);
  var z = zOutput.format(_z);
  var a = currentSection.isOptimizedForMachine() ? aOutput.format(_a) : toolVectorOutputI.format(_a);
  var b = currentSection.isOptimizedForMachine() ? bOutput.format(_b) : toolVectorOutputJ.format(_b);
  var c = currentSection.isOptimizedForMachine() ? cOutput.format(_c) : toolVectorOutputK.format(_c);
  if (feedMode == FEED_INVERSE_TIME) {
    forceFeed();
  }
  var f = feedMode == FEED_INVERSE_TIME ? inverseTimeOutput.format(feed) : getFeed(feed);
  var fMode = feedMode == FEED_INVERSE_TIME ? 93 : getProperty("useG95") ? 95 : 94;

  if (x || y || z || a || b || c) {
    writeBlock(gFeedModeModal.format(fMode), gMotionModal.format(1), x, y, z, a, b, c, f);
  } else if (f) {
    if (getNextRecord().isMotion()) { // try not to output feed without motion
      forceFeed(); // force feed on next line
    } else {
      writeBlock(gFeedModeModal.format(fMode), gMotionModal.format(1), f);
    }
  }
}
// <<<<< INCLUDED FROM include_files/onLinear5D_fanuc.cpi
// >>>>> INCLUDED FROM include_files/commonInspectionFunctions_fanuc.cpi
var macroFormat = createFormat({prefix:(typeof inspectionVariables == "undefined" ? "#" : inspectionVariables.localVariablePrefix), decimals:0});
var macroRoundingFormat =  (unit == MM) ? "[53]" : "[44]";
var isDPRNTopen = false;
var localVariableStart = 19;
var localVariable = [
  macroFormat.format(localVariableStart + 1),
  macroFormat.format(localVariableStart + 2),
  macroFormat.format(localVariableStart + 3),
  macroFormat.format(localVariableStart + 4),
  macroFormat.format(localVariableStart + 5),
  macroFormat.format(localVariableStart + 6)
];

function defineLocalVariable(indx, value) {
  writeln(localVariable[indx - 1] + " = " + value);
}

function formatLocalVariable(prefix, indx, rnd) {
  return prefix + localVariable[indx - 1] + rnd;
}

function inspectionCreateResultsFileHeader() {
  if (isDPRNTopen) {
    if (!getProperty("singleResultsFile")) {
      writeln("DPRNT[END]");
      writeBlock("PCLOS");
      isDPRNTopen = false;
    }
  }

  if (isProbeOperation() && !printProbeResults()) {
    return; // if print results is not desired by probe/ probeWCS
  }

  if (!isDPRNTopen) {
    writeBlock("PCLOS");
    writeBlock("POPEN");
    // check for existence of none alphanumeric characters but not spaces
    var resFile;
    if (getProperty("singleResultsFile")) {
      resFile = getParameter("job-description") + "-RESULTS";
    } else {
      resFile = getParameter("operation-comment") + "-RESULTS";
    }
    resFile = resFile.replace(/:/g, "-");
    resFile = resFile.replace(/[^a-zA-Z0-9 -]/g, "");
    resFile = resFile.replace(/\s/g, "-");
    resFile = resFile.toUpperCase();
    writeln("DPRNT[START]");
    writeln("DPRNT[RESULTSFILE*" + resFile + "]");
    if (hasGlobalParameter("document-id")) {
      writeln("DPRNT[DOCUMENTID*" + getGlobalParameter("document-id").toUpperCase() + "]");
    }
    if (hasGlobalParameter("model-version")) {
      writeln("DPRNT[MODELVERSION*" + getGlobalParameter("model-version").toUpperCase() + "]");
    }
  }
  if (isProbeOperation() && printProbeResults()) {
    isDPRNTopen = true;
  }
}

function getPointNumber() {
  if (typeof inspectionWriteVariables == "function") {
    return (inspectionVariables.pointNumber);
  } else {
    return ("#122[60]");
  }
}

function inspectionWriteCADTransform() {
  var cadOrigin = currentSection.getModelOrigin();
  var cadWorkPlane = currentSection.getModelPlane().getTransposed();
  var cadEuler = cadWorkPlane.getEuler2(EULER_XYZ_S);
  defineLocalVariable(1, abcFormat.format(cadEuler.x));
  defineLocalVariable(2, abcFormat.format(cadEuler.y));
  defineLocalVariable(3, abcFormat.format(cadEuler.z));
  defineLocalVariable(4, xyzFormat.format(-cadOrigin.x));
  defineLocalVariable(5, xyzFormat.format(-cadOrigin.y));
  defineLocalVariable(6, xyzFormat.format(-cadOrigin.z));
  writeln(
    "DPRNT[G331" +
    "*N" + getPointNumber() +
    formatLocalVariable("*A", 1, macroRoundingFormat) +
    formatLocalVariable("*B", 2, macroRoundingFormat) +
    formatLocalVariable("*C", 3, macroRoundingFormat) +
    formatLocalVariable("*X", 4, macroRoundingFormat) +
    formatLocalVariable("*Y", 5, macroRoundingFormat) +
    formatLocalVariable("*Z", 6, macroRoundingFormat) +
    "]"
  );
}

function inspectionWriteWorkplaneTransform() {
  var orientation = machineConfiguration.isMultiAxisConfiguration() ? machineConfiguration.getOrientation(getCurrentDirection()) : currentSection.workPlane;
  var abc = orientation.getEuler2(EULER_XYZ_S);
  defineLocalVariable(1, abcFormat.format(abc.x));
  defineLocalVariable(2, abcFormat.format(abc.y));
  defineLocalVariable(3, abcFormat.format(abc.z));
  writeln("DPRNT[G330" +
    "*N" + getPointNumber() +
    formatLocalVariable("*A", 1, macroRoundingFormat) +
    formatLocalVariable("*B", 2, macroRoundingFormat) +
    formatLocalVariable("*C", 3, macroRoundingFormat) +
    "*X0*Y0*Z0*I0*R0]"
  );
}

function writeProbingToolpathInformation(cycleDepth) {
  defineLocalVariable(1, getParameter("autodeskcam:operation-id"));
  writeln(formatLocalVariable("DPRNT[TOOLPATHID*", 1, "[54]]"));
  if (isInspectionOperation()) {
    writeln("DPRNT[TOOLPATH*" + getParameter("operation-comment").toUpperCase().replace(/[()]/g, "") + "]");
  } else {
    defineLocalVariable(2, xyzFormat.format(cycleDepth));
    writeln(formatLocalVariable("DPRNT[CYCLEDEPTH*", 2, macroRoundingFormat + "]"));
  }
}
// <<<<< INCLUDED FROM include_files/commonInspectionFunctions_fanuc.cpi
// >>>>> INCLUDED FROM include_files/probeCycles_renishaw.cpi
validate(settings.probing, "Setting 'probing' is required but not defined.");
var probeVariables = {
  outputRotationCodes: false, // determines if it is required to output rotation codes
  compensationXY     : undefined
};
function writeProbeCycle(cycle, x, y, z, P, F) {
  if (isProbeOperation()) {
    if (!settings.workPlaneMethod.useTiltedWorkplane && !isSameDirection(currentSection.workPlane.forward, new Vector(0, 0, 1))) {
      if (!settings.probing.allowIndexingWCSProbing && currentSection.strategy == "probe") {
        error(localize("Updating WCS / work offset using probing is only supported by the CNC in the WCS frame."));
        return;
      }
    }
    if (printProbeResults()) {
      writeProbingToolpathInformation(z - cycle.depth + tool.diameter / 2);
      inspectionWriteCADTransform();
      inspectionWriteWorkplaneTransform();
      if (typeof inspectionWriteVariables == "function") {
        inspectionVariables.pointNumber += 1;
      }
    }
    protectedProbeMove(cycle, x, y, z);
  }

  var macroCall = settings.probing.macroCall;
  switch (cycleType) {
  case "probing-x":
    protectedProbeMove(cycle, x, y, z - cycle.depth);
    writeBlock(
      macroCall, "P" + 9811,
      "X" + xyzFormat.format(x + approach(cycle.approach1) * (cycle.probeClearance + tool.diameter / 2)),
      "Q" + xyzFormat.format(cycle.probeOvertravel),
      getProbingArguments(cycle, true)
    );
    break;
  case "probing-y":
    protectedProbeMove(cycle, x, y, z - cycle.depth);
    writeBlock(
      macroCall, "P" + 9811,
      "Y" + xyzFormat.format(y + approach(cycle.approach1) * (cycle.probeClearance + tool.diameter / 2)),
      "Q" + xyzFormat.format(cycle.probeOvertravel),
      getProbingArguments(cycle, true)
    );
    break;
  case "probing-z":
    protectedProbeMove(cycle, x, y, Math.min(z - cycle.depth + cycle.probeClearance, cycle.retract));
    writeBlock(
      macroCall, "P" + 9811,
      "Z" + xyzFormat.format(z - cycle.depth),
      "Q" + xyzFormat.format(cycle.probeOvertravel),
      getProbingArguments(cycle, true)
    );
    break;
  case "probing-x-wall":
    protectedProbeMove(cycle, x, y, z);
    writeBlock(
      macroCall, "P" + 9812,
      "X" + xyzFormat.format(cycle.width1),
      zOutput.format(z - cycle.depth),
      "Q" + xyzFormat.format(cycle.probeOvertravel),
      "R" + xyzFormat.format(cycle.probeClearance),
      getProbingArguments(cycle, true)
    );
    break;
  case "probing-y-wall":
    protectedProbeMove(cycle, x, y, z);
    writeBlock(
      macroCall, "P" + 9812,
      "Y" + xyzFormat.format(cycle.width1),
      zOutput.format(z - cycle.depth),
      "Q" + xyzFormat.format(cycle.probeOvertravel),
      "R" + xyzFormat.format(cycle.probeClearance),
      getProbingArguments(cycle, true)
    );
    break;
  case "probing-x-channel":
    protectedProbeMove(cycle, x, y, z - cycle.depth);
    writeBlock(
      macroCall, "P" + 9812,
      "X" + xyzFormat.format(cycle.width1),
      "Q" + xyzFormat.format(cycle.probeOvertravel),
      // not required "R" + xyzFormat.format(cycle.probeClearance),
      getProbingArguments(cycle, true)
    );
    break;
  case "probing-x-channel-with-island":
    protectedProbeMove(cycle, x, y, z);
    writeBlock(
      macroCall, "P" + 9812,
      "X" + xyzFormat.format(cycle.width1),
      zOutput.format(z - cycle.depth),
      "Q" + xyzFormat.format(cycle.probeOvertravel),
      "R" + xyzFormat.format(-cycle.probeClearance),
      getProbingArguments(cycle, true)
    );
    break;
  case "probing-y-channel":
    protectedProbeMove(cycle, x, y, z - cycle.depth);
    writeBlock(
      macroCall, "P" + 9812,
      "Y" + xyzFormat.format(cycle.width1),
      "Q" + xyzFormat.format(cycle.probeOvertravel),
      // not required "R" + xyzFormat.format(cycle.probeClearance),
      getProbingArguments(cycle, true)
    );
    break;
  case "probing-y-channel-with-island":
    protectedProbeMove(cycle, x, y, z);
    writeBlock(
      macroCall, "P" + 9812,
      "Y" + xyzFormat.format(cycle.width1),
      zOutput.format(z - cycle.depth),
      "Q" + xyzFormat.format(cycle.probeOvertravel),
      "R" + xyzFormat.format(-cycle.probeClearance),
      getProbingArguments(cycle, true)
    );
    break;
  case "probing-xy-circular-boss":
    protectedProbeMove(cycle, x, y, z);
    writeBlock(
      macroCall, "P" + 9814,
      "D" + xyzFormat.format(cycle.width1),
      "Z" + xyzFormat.format(z - cycle.depth),
      "Q" + xyzFormat.format(cycle.probeOvertravel),
      "R" + xyzFormat.format(cycle.probeClearance),
      getProbingArguments(cycle, true)
    );
    break;
  case "probing-xy-circular-partial-boss":
    protectedProbeMove(cycle, x, y, z);
    writeBlock(
      macroCall, "P" + 9823,
      "A" + xyzFormat.format(cycle.partialCircleAngleA),
      "B" + xyzFormat.format(cycle.partialCircleAngleB),
      "C" + xyzFormat.format(cycle.partialCircleAngleC),
      "D" + xyzFormat.format(cycle.width1),
      "Z" + xyzFormat.format(z - cycle.depth),
      "Q" + xyzFormat.format(cycle.probeOvertravel),
      "R" + xyzFormat.format(cycle.probeClearance),
      getProbingArguments(cycle, true)
    );
    break;
  case "probing-xy-circular-hole":
    protectedProbeMove(cycle, x, y, z - cycle.depth);
    writeBlock(
      macroCall, "P" + 9814,
      "D" + xyzFormat.format(cycle.width1),
      "Q" + xyzFormat.format(cycle.probeOvertravel),
      // not required "R" + xyzFormat.format(cycle.probeClearance),
      getProbingArguments(cycle, true)
    );
    break;
  case "probing-xy-circular-partial-hole":
    protectedProbeMove(cycle, x, y, z - cycle.depth);
    writeBlock(
      macroCall, "P" + 9823,
      "A" + xyzFormat.format(cycle.partialCircleAngleA),
      "B" + xyzFormat.format(cycle.partialCircleAngleB),
      "C" + xyzFormat.format(cycle.partialCircleAngleC),
      "D" + xyzFormat.format(cycle.width1),
      "Q" + xyzFormat.format(cycle.probeOvertravel),
      getProbingArguments(cycle, true)
    );
    break;
  case "probing-xy-circular-hole-with-island":
    protectedProbeMove(cycle, x, y, z);
    writeBlock(
      macroCall, "P" + 9814,
      "Z" + xyzFormat.format(z - cycle.depth),
      "D" + xyzFormat.format(cycle.width1),
      "Q" + xyzFormat.format(cycle.probeOvertravel),
      "R" + xyzFormat.format(-cycle.probeClearance),
      getProbingArguments(cycle, true)
    );
    break;
  case "probing-xy-circular-partial-hole-with-island":
    protectedProbeMove(cycle, x, y, z);
    writeBlock(
      macroCall, "P" + 9823,
      "Z" + xyzFormat.format(z - cycle.depth),
      "A" + xyzFormat.format(cycle.partialCircleAngleA),
      "B" + xyzFormat.format(cycle.partialCircleAngleB),
      "C" + xyzFormat.format(cycle.partialCircleAngleC),
      "D" + xyzFormat.format(cycle.width1),
      "Q" + xyzFormat.format(cycle.probeOvertravel),
      "R" + xyzFormat.format(-cycle.probeClearance),
      getProbingArguments(cycle, true)
    );
    break;
  case "probing-xy-rectangular-hole":
    protectedProbeMove(cycle, x, y, z - cycle.depth);
    writeBlock(
      macroCall, "P" + 9812,
      "X" + xyzFormat.format(cycle.width1),
      "Q" + xyzFormat.format(cycle.probeOvertravel),
      // not required "R" + xyzFormat.format(-cycle.probeClearance),
      getProbingArguments(cycle, true)
    );
    writeBlock(
      macroCall, "P" + 9812,
      "Y" + xyzFormat.format(cycle.width2),
      "Q" + xyzFormat.format(cycle.probeOvertravel),
      // not required "R" + xyzFormat.format(-cycle.probeClearance),
      getProbingArguments(cycle, true)
    );
    break;
  case "probing-xy-rectangular-boss":
    protectedProbeMove(cycle, x, y, z);
    writeBlock(
      macroCall, "P" + 9812,
      "Z" + xyzFormat.format(z - cycle.depth),
      "X" + xyzFormat.format(cycle.width1),
      "R" + xyzFormat.format(cycle.probeClearance),
      "Q" + xyzFormat.format(cycle.probeOvertravel),
      getProbingArguments(cycle, true)
    );
    writeBlock(
      macroCall, "P" + 9812,
      "Z" + xyzFormat.format(z - cycle.depth),
      "Y" + xyzFormat.format(cycle.width2),
      "R" + xyzFormat.format(cycle.probeClearance),
      "Q" + xyzFormat.format(cycle.probeOvertravel),
      getProbingArguments(cycle, true)
    );
    break;
  case "probing-xy-rectangular-hole-with-island":
    protectedProbeMove(cycle, x, y, z);
    writeBlock(
      macroCall, "P" + 9812,
      "Z" + xyzFormat.format(z - cycle.depth),
      "X" + xyzFormat.format(cycle.width1),
      "Q" + xyzFormat.format(cycle.probeOvertravel),
      "R" + xyzFormat.format(-cycle.probeClearance),
      getProbingArguments(cycle, true)
    );
    writeBlock(
      macroCall, "P" + 9812,
      "Z" + xyzFormat.format(z - cycle.depth),
      "Y" + xyzFormat.format(cycle.width2),
      "Q" + xyzFormat.format(cycle.probeOvertravel),
      "R" + xyzFormat.format(-cycle.probeClearance),
      getProbingArguments(cycle, true)
    );
    break;

  case "probing-xy-inner-corner":
    var cornerX = x + approach(cycle.approach1) * (cycle.probeClearance + tool.diameter / 2);
    var cornerY = y + approach(cycle.approach2) * (cycle.probeClearance + tool.diameter / 2);
    var cornerI = 0;
    var cornerJ = 0;
    if (cycle.probeSpacing !== undefined) {
      cornerI = cycle.probeSpacing;
      cornerJ = cycle.probeSpacing;
    }
    if ((cornerI != 0) && (cornerJ != 0)) {
      if (currentSection.strategy == "probe") {
        setProbeAngleMethod();
        probeVariables.compensationXY = "X[#135] Y[#136]";
      }
    }
    protectedProbeMove(cycle, x, y, z - cycle.depth);
    writeBlock(
      macroCall, "P" + 9815, xOutput.format(cornerX), yOutput.format(cornerY),
      conditional(cornerI != 0, "I" + xyzFormat.format(cornerI)),
      conditional(cornerJ != 0, "J" + xyzFormat.format(cornerJ)),
      "Q" + xyzFormat.format(cycle.probeOvertravel),
      getProbingArguments(cycle, true)
    );
    break;
  case "probing-xy-outer-corner":
    var cornerX = x + approach(cycle.approach1) * (cycle.probeClearance + tool.diameter / 2);
    var cornerY = y + approach(cycle.approach2) * (cycle.probeClearance + tool.diameter / 2);
    var cornerI = 0;
    var cornerJ = 0;
    if (cycle.probeSpacing !== undefined) {
      cornerI = cycle.probeSpacing;
      cornerJ = cycle.probeSpacing;
    }
    if ((cornerI != 0) && (cornerJ != 0)) {
      if (currentSection.strategy == "probe") {
        setProbeAngleMethod();
        probeVariables.compensationXY = "X[#135] Y[#136]";
      }
    }
    protectedProbeMove(cycle, x, y, z - cycle.depth);
    writeBlock(
      macroCall, "P" + 9816, xOutput.format(cornerX), yOutput.format(cornerY),
      conditional(cornerI != 0, "I" + xyzFormat.format(cornerI)),
      conditional(cornerJ != 0, "J" + xyzFormat.format(cornerJ)),
      "Q" + xyzFormat.format(cycle.probeOvertravel),
      getProbingArguments(cycle, true)
    );
    break;
  case "probing-x-plane-angle":
    protectedProbeMove(cycle, x, y, z - cycle.depth);
    writeBlock(
      macroCall, "P" + 9843,
      "X" + xyzFormat.format(x + approach(cycle.approach1) * (cycle.probeClearance + tool.diameter / 2)),
      "D" + xyzFormat.format(cycle.probeSpacing),
      "Q" + xyzFormat.format(cycle.probeOvertravel),
      "A" + xyzFormat.format(cycle.nominalAngle != undefined ? cycle.nominalAngle : 90),
      getProbingArguments(cycle, false)
    );
    if (currentSection.strategy == "probe") {
      setProbeAngleMethod();
      probeVariables.compensationXY = "X" + xyzFormat.format(0) + " Y" + xyzFormat.format(0);
    }
    break;
  case "probing-y-plane-angle":
    protectedProbeMove(cycle, x, y, z - cycle.depth);
    writeBlock(
      macroCall, "P" + 9843,
      "Y" + xyzFormat.format(y + approach(cycle.approach1) * (cycle.probeClearance + tool.diameter / 2)),
      "D" + xyzFormat.format(cycle.probeSpacing),
      "Q" + xyzFormat.format(cycle.probeOvertravel),
      "A" + xyzFormat.format(cycle.nominalAngle != undefined ? cycle.nominalAngle : 0),
      getProbingArguments(cycle, false)
    );
    if (currentSection.strategy == "probe") {
      setProbeAngleMethod();
      probeVariables.compensationXY = "X" + xyzFormat.format(0) + " Y" + xyzFormat.format(0);
    }
    break;
  case "probing-xy-pcd-hole":
    protectedProbeMove(cycle, x, y, z);
    writeBlock(
      macroCall, "P" + 9819,
      "A" + xyzFormat.format(cycle.pcdStartingAngle),
      "B" + xyzFormat.format(cycle.numberOfSubfeatures),
      "C" + xyzFormat.format(cycle.widthPCD),
      "D" + xyzFormat.format(cycle.widthFeature),
      "K" + xyzFormat.format(z - cycle.depth),
      "Q" + xyzFormat.format(cycle.probeOvertravel),
      getProbingArguments(cycle, false)
    );
    if (cycle.updateToolWear) {
      error(localize("Action -Update Tool Wear- is not supported with this cycle."));
      return;
    }
    break;
  case "probing-xy-pcd-boss":
    protectedProbeMove(cycle, x, y, z);
    writeBlock(
      macroCall, "P" + 9819,
      "A" + xyzFormat.format(cycle.pcdStartingAngle),
      "B" + xyzFormat.format(cycle.numberOfSubfeatures),
      "C" + xyzFormat.format(cycle.widthPCD),
      "D" + xyzFormat.format(cycle.widthFeature),
      "Z" + xyzFormat.format(z - cycle.depth),
      "Q" + xyzFormat.format(cycle.probeOvertravel),
      "R" + xyzFormat.format(cycle.probeClearance),
      getProbingArguments(cycle, false)
    );
    if (cycle.updateToolWear) {
      error(localize("Action -Update Tool Wear- is not supported with this cycle."));
      return;
    }
    break;
  }
}

function printProbeResults() {
  return currentSection.getParameter("printResults", 0) == 1;
}

/** Convert approach to sign. */
function approach(value) {
  validate((value == "positive") || (value == "negative"), "Invalid approach.");
  return (value == "positive") ? 1 : -1;
}
// <<<<< INCLUDED FROM include_files/probeCycles_renishaw.cpi
// >>>>> INCLUDED FROM include_files/getProbingArguments_renishaw.cpi
function getProbingArguments(cycle, updateWCS) {
  var outputWCSCode = updateWCS && currentSection.strategy == "probe";
  var probeOutputWorkOffset = currentSection.probeWorkOffset;
  if (outputWCSCode) {
    validate(probeOutputWorkOffset <= 99, "Work offset is out of range.");
    var nextWorkOffset = hasNextSection() ? getNextSection().workOffset == 0 ? 1 : getNextSection().workOffset : -1;
    if (probeOutputWorkOffset == nextWorkOffset) {
      currentWorkOffset = undefined;
    }
  }
  return [
    (cycle.angleAskewAction == "stop-message" ? "B" + xyzFormat.format(cycle.toleranceAngle ? cycle.toleranceAngle : 0) : undefined),
    ((cycle.updateToolWear && cycle.toolWearErrorCorrection < 100) ? "F" + xyzFormat.format(cycle.toolWearErrorCorrection ? cycle.toolWearErrorCorrection / 100 : 100) : undefined),
    (cycle.wrongSizeAction == "stop-message" ? "H" + xyzFormat.format(cycle.toleranceSize ? cycle.toleranceSize : 0) : undefined),
    (cycle.outOfPositionAction == "stop-message" ? "M" + xyzFormat.format(cycle.tolerancePosition ? cycle.tolerancePosition : 0) : undefined),
    ((cycle.updateToolWear && cycleType == "probing-z") ? "T" + xyzFormat.format(cycle.toolLengthOffset) : undefined),
    ((cycle.updateToolWear && cycleType !== "probing-z") ? "T" + xyzFormat.format(cycle.toolDiameterOffset) : undefined),
    (cycle.updateToolWear ? "V" + xyzFormat.format(cycle.toolWearUpdateThreshold ? cycle.toolWearUpdateThreshold : 0) : undefined),
    (cycle.printResults ? "W" + xyzFormat.format(1 + cycle.incrementComponent) : undefined), // 1 for advance feature, 2 for reset feature count and advance component number. first reported result in a program should use W2.
    conditional(outputWCSCode, "S" + probeWCSFormat.format(probeOutputWorkOffset > 6 ? (probeOutputWorkOffset - 6 + 100) : probeOutputWorkOffset))
  ];
}
// <<<<< INCLUDED FROM include_files/getProbingArguments_renishaw.cpi
// >>>>> INCLUDED FROM include_files/protectedProbeMove_renishaw.cpi
function protectedProbeMove(_cycle, x, y, z) {
  var _x = xOutput.format(x);
  var _y = yOutput.format(y);
  var _z = zOutput.format(z);
  var macroCall = settings.probing.macroCall;
  if (_z && z >= getCurrentPosition().z) {
    writeBlock(macroCall, "P" + 9810, _z, getFeed(cycle.feedrate)); // protected positioning move
  }
  if (_x || _y) {
    writeBlock(macroCall, "P" + 9810, _x, _y, getFeed(highFeedrate)); // protected positioning move
  }
  if (_z && z < getCurrentPosition().z) {
    writeBlock(macroCall, "P" + 9810, _z, getFeed(cycle.feedrate)); // protected positioning move
  }
}
// <<<<< INCLUDED FROM include_files/protectedProbeMove_renishaw.cpi
// >>>>> INCLUDED FROM include_files/setProbeAngleMethod.cpi
function setProbeAngleMethod() {
  settings.probing.probeAngleMethod = (machineConfiguration.getNumberOfAxes() < 5 || is3D()) ? (getProperty("useG54x4") ? "G54.4" : "G68") : "UNSUPPORTED";
  var axes = [machineConfiguration.getAxisU(), machineConfiguration.getAxisV(), machineConfiguration.getAxisW()];
  for (var i = 0; i < axes.length; ++i) {
    if (axes[i].isEnabled() && isSameDirection((axes[i].getAxis()).getAbsolute(), new Vector(0, 0, 1)) && axes[i].isTable()) {
      settings.probing.probeAngleMethod = "AXIS_ROT";
      break;
    }
  }
  probeVariables.outputRotationCodes = true;
}
// <<<<< INCLUDED FROM include_files/setProbeAngleMethod.cpi
// <<<<< INCLUDED FROM generic_posts/mazak.cps

capabilities |= CAPABILITY_INSPECTION;
description = "Mazak Inspect Surface";
longDescription = "Generic milling post for Mazak with inspect surface capabilities.";

// >>>>> INCLUDED FROM inspection/common/fanuc base inspection properties.cps
properties.probeCalibrationMethod = {
  title      : "Probe calibration Method",
  description: "Select the probe calibration method",
  group      : "probing",
  type       : "enum",
  values     : [
    {id:"Renishaw", title:"Renishaw"},
    {id:"Autodesk", title:"Autodesk"},
    {id:"Other", title:"Other"}
  ],
  value: "Renishaw",
  scope: "post"
};
properties.probeLocalVar = {
  title      : "Local variable start",
  description: "Specify the starting value for macro # variables that are to be used for calculations during inspection paths",
  group      : "probing",
  type       : "integer",
  value      : 100,
  scope      : "post"
};
properties.useDirectConnection = {
  title      : "Stream Measured Point Data",
  description: "Set to true to stream inspection results",
  group      : "probing",
  type       : "boolean",
  value      : false,
  scope      : "post"
};
properties.probeResultsBuffer = {
  title      : "Measurement results store start",
  description: "Specify the starting value of macro # variables where measurement results are stored",
  group      : "probing",
  type       : "integer",
  value      : 800,
  scope      : "post"
};
properties.probeNumberofPoints = {
  title      : "Measurement number of points to store",
  description: "This is the maximum number of measurement results that can be stored in the buffer",
  group      : "probing",
  type       : "integer",
  value      : 4,
  scope      : "post"
};
properties.controlConnectorVersion = {
  title      : "Results connector version",
  description: "Interface version for direct connection to read inspection results",
  group      : "probing",
  type       : "integer",
  value      : 1,
  scope      : "post"
};
properties.toolOffsetType = {
  title      : "Tool offset type",
  description: "Select the which offsets are available on the tool offset page",
  group      : "probing",
  type       : "enum",
  values     : [
    {id:"geomWear", title:"Geometry & Wear"},
    {id:"geomOnly", title:"Geometry only"}
  ],
  value: "geomOnly",
  scope: "post"
};
properties.commissioningMode = {
  title      : "Inspection Commissioning Mode",
  description: "Enables commissioning mode where M0 and messages are output at key points in the program",
  group      : "probing",
  type       : "boolean",
  value      : true,
  scope      : "post"
};
properties.probeOnCommand = {
  title      : "Probe On Command",
  description: "The command used to turn the probe on, this can be a M code or sub program call",
  group      : "probing",
  type       : "string",
  value      : "",
  scope      : "post"
};
properties.probeOffCommand = {
  title      : "Probe Off Command",
  description: "The command used to turn the probe off, this can be a M code or sub program call",
  group      : "probing",
  type       : "string",
  value      : "",
  scope      : "post"
};
properties.probeCalibratedRadius = {
  title      : "Calibrated Radius",
  description: "Macro Variable used for storing probe calibrated radi",
  group      : "probing",
  type       : "integer",
  value      : 0,
  scope      : "post"
};
properties.probeEccentricityX = {
  title      : "Eccentricity X",
  description: "Macro Variable used for storing the X eccentricity",
  group      : "probing",
  type       : "integer",
  value      : 0,
  scope      : "post"
};
properties.probeEccentricityY = {
  title      : "Eccentricity Y",
  description: "Macro Variable used for storing the Y eccentricity",
  group      : "probing",
  type       : "integer",
  value      : 0,
  scope      : "post"
};
properties.calibrationNCOutput = {
  title      : "Calibration NC Output Type",
  description: "Choose none if the NC program created is to be used for calibrating the probe",
  group      : "probing",
  type       : "enum",
  values     : [
    {id:"none", title:"none"},
    {id:"Ring Gauge", title:"Ring Gauge"}
  ],
  value: "none",
  scope: "post"
};

// inspection variables
var inspectionVariables = {
  localVariablePrefix            : "#",
  probeRadius                    : 0,
  systemVariableMeasuredX        : 5061,
  systemVariableMeasuredY        : 5062,
  systemVariableMeasuredZ        : 5063,
  pointNumber                    : 1,
  probeResultsBufferFull         : false,
  probeResultsBufferIndex        : 1,
  hasInspectionSections          : false,
  inspectionSectionCount         : 0,
  systemVariableOffsetLengthTable: 2000,
  systemVariableOffsetWearTable  : 2200,
  workpieceOffset                : "",
  alternateTriggerCheck          : false,
  toolLengthParameterCheck       : true,
  printParameterCheck            : true,
};
// <<<<< INCLUDED FROM inspection/common/fanuc base inspection properties.cps

// modify default settings
inspectionVariables.alternateTriggerCheck = false;
inspectionVariables.toolLengthParameterCheck = false;
inspectionVariables.printParameterCheck = true;

var saveShowSequenceNumbers;

// >>>>> INCLUDED FROM inspection/common/fanuc base inspection.cps
// code for inspection support

var ijkInspectionFormat = createFormat({decimals:5, forceDecimal:true});

var MEASURE_COMMAND = 31;
var LINEAR_COMMAND = 1;

function inspectionWriteVariables() {
  sequenceNumber = sequenceNumber == undefined ? getProperty("sequenceNumberStart") : sequenceNumber;
  saveShowSequenceNumbers = getProperty("showSequenceNumbers");
  // loop through all NC stream sections to check for surface inspection
  for (var i = 0; i < getNumberOfSections(); ++i) {
    var section = getSection(i);
    if (section.strategy == "inspectSurface") {
      inspectionVariables.workpieceOffset = section.workOffset;
      var count = 1;
      var localVar = getProperty("probeLocalVar");
      var prefix = inspectionVariables.localVariablePrefix;
      inspectionVariables.probeRadius = prefix + count;
      inspectionVariables.xTarget = prefix + ++count;
      inspectionVariables.yTarget = prefix + ++count;
      inspectionVariables.zTarget = prefix + ++count;
      inspectionVariables.xMeasured = prefix + ++count;
      inspectionVariables.yMeasured = prefix + ++count;
      inspectionVariables.zMeasured = prefix + ++count;
      inspectionVariables.activeToolLength = prefix + ++count;
      inspectionVariables.macroVariable1 = prefix + ++count;
      inspectionVariables.macroVariable2 = prefix + ++count;
      inspectionVariables.macroVariable3 = prefix + ++count;
      inspectionVariables.macroVariable4 = prefix + ++count;
      inspectionVariables.macroVariable5 = prefix + ++count;
      inspectionVariables.macroVariable6 = prefix + ++count;
      inspectionVariables.macroVariable7 = prefix + ++count;
      inspectionVariables.workplaneTransformA = prefix + ++count;
      inspectionVariables.workplaneTransformB = prefix + ++count;
      inspectionVariables.workplaneTransformC = prefix + ++count;
      if (getProperty("calibrationNCOutput") == "Ring Gauge") {
        inspectionVariables.measuredXStartingAddress = localVar;
        inspectionVariables.measuredYStartingAddress = localVar + 10;
        inspectionVariables.measuredZStartingAddress = localVar + 20;
        inspectionVariables.measuredIStartingAddress = localVar + 30;
        inspectionVariables.measuredJStartingAddress = localVar + 40;
        inspectionVariables.measuredKStartingAddress = localVar + 50;
      }
      inspectionValidateInspectionSettings();
      inspectionVariables.probeResultsReadPointer = prefix + (getProperty("probeResultsBuffer") + 2);
      inspectionVariables.probeResultsWritePointer = prefix + (getProperty("probeResultsBuffer") + 3);
      inspectionVariables.probeResultsCollectionActive = prefix + (getProperty("probeResultsBuffer") + 4);
      inspectionVariables.probeResultsStartAddress = getProperty("probeResultsBuffer") + 5;
      if (getProperty("commissioningMode")) {
        writeBlock("#3006=1" + formatComment("Property " + properties.commissioningMode.title + " is enabled"));
        writeComment("When the machine is measuring correctly please disable this property");
      }
      if (getProperty("useDirectConnection")) {
        // check to make sure local variables used in results buffer and inspection do not clash
        var localStart = getProperty("probeLocalVar");
        var localEnd = count;
        var bufferStart = getProperty("probeResultsBuffer");
        var bufferEnd = getProperty("probeResultsBuffer") + ((3 * getProperty("probeNumberofPoints")) + 8);
        if ((localStart >= bufferStart && localStart <= bufferEnd) ||
            (localEnd >= bufferStart && localEnd <= bufferEnd)) {
          error("Local variables defined (" + prefix + localStart + "-" + prefix + localEnd +
              ") and live probe results storage area (" + prefix + bufferStart + "-" + prefix + bufferEnd + ") overlap."
          );
        }
        writeBlock(macroFormat.format(getProperty("probeResultsBuffer")) + " = " + getProperty("controlConnectorVersion"));
        writeBlock(macroFormat.format(getProperty("probeResultsBuffer") + 1) + " = " + getProperty("probeNumberofPoints"));
        writeBlock(inspectionVariables.probeResultsReadPointer + " = 0");
        writeBlock(inspectionVariables.probeResultsWritePointer + " = 1");
        writeBlock(inspectionVariables.probeResultsCollectionActive + " = 0");
        if (getProperty("probeResultultsBuffer") == 0) {
          error("Probe Results Buffer start address cannot be zero when using a direct connection.");
        }
        inspectionWriteFusionConnectorInterface("HEADER");
      }
      inspectionVariables.hasInspectionSections = true;
      break;
    }
  }
}

function inspectionValidateInspectionSettings() {
  var errorText = "";
  if (getProperty("probeOnCommand") == "") {
    errorText += "\n-Probe On Command-";
  }
  if (getProperty("probeOffCommand") == "") {
    errorText += "\n-Probe Off Command-";
  }
  if (getProperty("probeCalibratedRadius") == 0) {
    errorText += "\n-Calibrated Radius-";
  }
  if (getProperty("probeEccentricityX") == 0) {
    errorText += "\n-Eccentricity X-";
  }
  if (getProperty("probeEccentricityY") == 0) {
    errorText += "\n-Eccentricity Y-";
  }
  if (errorText != "") {
    error(localize("The following properties need to be configured:" + errorText + "\n-Please consult the guide PDF found at https://cam.autodesk.com/hsmposts?p=fanuc_inspection for more information-"));
  }
}

function onProbe(status) {
  if (status) { // probe ON
    if (getProperty("commissioningMode")) {
      var outputType = getProperty("calibrationNCOutput") == "Ring Gauge" ? "S#1" : "";
      writeBlock(mFormat.format(19), outputType);
    }
    // writeBlock(mFormat.format(184)); // Doosan Allow G01 or G31 move without spindle speed active (M185 to activate)
    if (getProperty("probeOnCommand").trim().length != 0) {
      writeBlock(getProperty("probeOnCommand")); // Command for switching the probe on
    }
    onDwell(2);
    if (getProperty("commissioningMode")) {
      writeBlock("#3006=1" + formatComment("Ensure Probe Is Active"));
    }
  } else { // probe OFF
    if (getProperty("probeOffCommand").trim().length != 0) {
      writeBlock(getProperty("probeOffCommand")); // Command for switching the probe off
    }
    onDwell(2);
    if (getProperty("commissioningMode")) {
      writeBlock("#3006=1" + formatComment("Ensure Probe Has Deactivated"));
    }
  }
}

function inspectionCycleInspect(cycle, epx, epy, epz) {
  if (getNumberOfCyclePoints() != 3) {
    error(localize("Missing Endpoint in Inspection Cycle, check Approach and Retract heights"));
  }
  var x = xyzFormat.format(epx);
  var y = xyzFormat.format(epy);
  var z = xyzFormat.format(epz);
  forceFeed(); // ensure feed is always output - just incase.
  if (currentSection.isMultiAxis() && inspectionVariables.controllerParameterCheck) {
    forceSequenceNumbers(true);
    writeBlock(inspectionVariables.macroVariable1 + "=PRM[5400,5]");
    writeBlock("IF [" + inspectionVariables.macroVariable1 + " EQ 1] GOTO" + skipNLines(2));
    writeBlock("#3000 = 1" + formatComment("MACHINE PARAMETER 5400 BIT 5 NEEDS to BE 1 FOR MULTI-AXIS"));
    writeBlock(" ");
    forceSequenceNumbers(false);
  }
  var f;
  if (isFirstCyclePoint() || isLastCyclePoint()) {
    f = isFirstCyclePoint() ? cycle.safeFeed : cycle.linkFeed;
    inspectionCalculateTargetEndpoint(x, y, z);
    if (isFirstCyclePoint()) {
      writeComment("Approach Move");
      inspectionWriteCycleMove(f, MEASURE_COMMAND);
      inspectionProbeTriggerCheck(false); // not triggered
    } else {
      writeComment("Retract Move");
      inspectionWriteCycleMove(f, LINEAR_COMMAND);
      forceXYZ();
    }
  } else {
    f = cycle.measureFeed;
    // var f = 300;
    inspectionWriteNominalData(cycle);
    if (getProperty("useDirectConnection")) {
      inspectionWriteFusionConnectorInterface("MEASURE");
    }
    inspectionCalculateTargetEndpoint(x, y, z);
    writeComment("Measure Move");
    if (getProperty("commissioningMode") && inspectionVariables.pointNumber == 1) {
      writeBlock("#3006=1" + formatComment("Probe is about to contact part. Axes should stop on contact"));
    }
    inspectionWriteCycleMove(f, MEASURE_COMMAND);
    inspectionProbeTriggerCheck(true); // triggered
    inspectionCorrectProbeMeasurement();
    inspectionWriteMeasuredData(cycle);
  }
}

function inspectionWriteNominalData(cycle) {
  var m = getRotation();
  var v = new Vector(cycle.nominalX, cycle.nominalY, cycle.nominalZ);
  var vt = m.multiply(v);
  var pathVector = new Vector(cycle.nominalI, cycle.nominalJ, cycle.nominalK);
  var nv = m.multiply(pathVector).normalized;
  cycle.nominalX = vt.x;
  cycle.nominalY = vt.y;
  cycle.nominalZ = vt.z;
  cycle.nominalI = nv.x;
  cycle.nominalJ = nv.y;
  cycle.nominalK = nv.z;
  writeln(inspectionVariables.xTarget + "=" + xyzFormat.format(cycle.nominalX));
  writeln(inspectionVariables.yTarget + "=" + xyzFormat.format(cycle.nominalY));
  writeln(inspectionVariables.zTarget + "=" + xyzFormat.format(cycle.nominalZ));
  writeln(inspectionVariables.macroVariable1 + "=" + ijkInspectionFormat.format(cycle.nominalI));
  writeln(inspectionVariables.macroVariable2 + "=" + ijkInspectionFormat.format(cycle.nominalJ));
  writeln(inspectionVariables.macroVariable3 + "=" + ijkInspectionFormat.format(cycle.nominalK));
  writeln(inspectionVariables.macroVariable4 + "=" + xyzFormat.format(getParameter("operation:inspectSurfaceOffset")));
  writeln(inspectionVariables.macroVariable5 + "=" + xyzFormat.format(getParameter("operation:inspectUpperTolerance")));
  writeln(inspectionVariables.macroVariable6 + "=" + xyzFormat.format(getParameter("operation:inspectLowerTolerance")));

  writeln("DPRNT[G800" +
    "*N" + inspectionVariables.pointNumber + macroRoundingFormat +
    "*X" + inspectionVariables.xTarget + macroRoundingFormat +
    "*Y" + inspectionVariables.yTarget + macroRoundingFormat +
    "*Z" + inspectionVariables.zTarget + macroRoundingFormat +
    "*I" + inspectionVariables.macroVariable1 + macroRoundingFormat +
    "*J" + inspectionVariables.macroVariable2 + macroRoundingFormat +
    "*K" + inspectionVariables.macroVariable3 + macroRoundingFormat +
    "*O" + inspectionVariables.macroVariable4 + macroRoundingFormat +
    "*U" + inspectionVariables.macroVariable5 + macroRoundingFormat +
    "*L" + inspectionVariables.macroVariable6 + macroRoundingFormat +
    "]"
  );
}

function inspectionCalculateTargetEndpoint(x, y, z) {
  writeComment("CALCULATE TARGET ENDPOINT");
  writeBlock(inspectionVariables.xTarget + "=" + x + "-" + macroFormat.format(getProperty("probeEccentricityX")));
  writeBlock(inspectionVariables.yTarget + "=" + y + "-" + macroFormat.format(getProperty("probeEccentricityY")));
  writeBlock(inspectionVariables.zTarget + "=" + z + "+[" + xyzFormat.format(tool.diameter / 2) + "-" + inspectionVariables.probeRadius + "]");
}

function inspectionWriteMeasureMove(f) {
  writeBlock(gFormat.format(31),
    "X" + inspectionVariables.xTarget,
    "Y" + inspectionVariables.yTarget,
    "Z" + inspectionVariables.zTarget,
    feedOutput.format(f)
  );
}
function inspectionWriteCycleMove(feedRate, moveType) {
  writeBlock(gFormat.format(moveType),
    "X" + inspectionVariables.xTarget,
    "Y" + inspectionVariables.yTarget,
    "Z" + inspectionVariables.zTarget,
    feedOutput.format(feedRate)
  );
}

function inspectionProbeTriggerCheck(triggered) {
  var condition = !inspectionVariables.alternateTriggerCheck ? triggered ?  " GT " : " LT " : triggered ?  "#3020 EQ 1" : "#3020 EQ 0";
  var message = triggered ? "NO POINT TAKEN" : "PATH OBSTRUCTED";
  var inPositionTolerance = (unit == MM) ? 0.01 : 0.0004;
  if (!inspectionVariables.alternateTriggerCheck) {
    writeBlock(inspectionVariables.macroVariable1 + "=" + inspectionVariables.xTarget + "-" + macroFormat.format(inspectionVariables.systemVariableMeasuredX));
    writeBlock(inspectionVariables.macroVariable2 + "=" + inspectionVariables.yTarget + "-" + macroFormat.format(inspectionVariables.systemVariableMeasuredY));
    writeBlock(inspectionVariables.macroVariable3 + "=" + inspectionVariables.zTarget + "-" + macroFormat.format(inspectionVariables.systemVariableMeasuredZ) + "+" + inspectionVariables.activeToolLength);
    writeBlock(inspectionVariables.macroVariable4 + "=" +
    "[" + inspectionVariables.macroVariable1 + "*" + inspectionVariables.macroVariable1 + "]" + "+"  +
    "[" + inspectionVariables.macroVariable2 + "*" + inspectionVariables.macroVariable2 + "]" + "+"  +
    "[" + inspectionVariables.macroVariable3 + "*" + inspectionVariables.macroVariable3 + "]"
    );
  }
  forceSequenceNumbers(true);
  writeBlock("IF [" +
  conditional(!inspectionVariables.alternateTriggerCheck, inspectionVariables.macroVariable4) +
  condition +
  conditional(!inspectionVariables.alternateTriggerCheck, inPositionTolerance) +
  "] GOTO" + skipNLines(2));
  writeBlock("#3000 = 1 " + formatComment(message));
  writeBlock(" ");
  forceSequenceNumbers(false);

}

function inspectionCorrectProbeMeasurement() {
  writeComment("Correct Measurements");
  writeBlock(
    inspectionVariables.xMeasured + "=" + macroFormat.format(inspectionVariables.systemVariableMeasuredX) + "+" + macroFormat.format(getProperty("probeEccentricityX"))
  );
  writeBlock(
    inspectionVariables.yMeasured + "=" + macroFormat.format(inspectionVariables.systemVariableMeasuredY) + "+" + macroFormat.format(getProperty("probeEccentricityY"))
  );
  // need to consider probe centre tool output point in future too
  writeBlock(
    inspectionVariables.zMeasured + "=" +
    macroFormat.format(inspectionVariables.systemVariableMeasuredZ) + "-" +
    inspectionVariables.activeToolLength + "+" +
    inspectionVariables.probeRadius
  );
}

function inspectionWriteFusionConnectorInterface(ncSection) {
  if (ncSection == "MEASURE") {
    writeBlock("IF " + inspectionVariables.probeResultsCollectionActive + " NE 1 GOTO " + inspectionVariables.pointNumber);
    writeBlock("WHILE [" + inspectionVariables.probeResultsReadPointer + " EQ " + inspectionVariables.probeResultsWritePointer + "] DO 1");
    onDwell(0.5);
    writeComment("WAITING FOR FUSION CONNECTION");
    writeBlock("G53");
    writeBlock("END 1");
    writeBlock("N" + inspectionVariables.pointNumber);
  } else {
    writeBlock("WHILE [" + inspectionVariables.probeResultsCollectionActive + " NE 1] DO 1");
    onDwell(0.5);
    writeComment("WAITING FOR FUSION CONNECTION");
    writeBlock("G53");
    writeBlock("END 1");
  }
}

function inspectionCalculateDeviation(cycle) {
  //calculate the deviation and produce a warning if out of tolerance.
  //(Measured + ((vector *(-1))*calibrated radi))

  writeComment("calculate deviation");
  //compensate for tip rad in X
  writeBlock(
    inspectionVariables.macroVariable1 + "=[" +
    inspectionVariables.xMeasured + "+[[" +
    ijkFormat.format(cycle.nominalI) + "*[-1]]*" +
    inspectionVariables.probeRadius + "]]"
  );
  //compensate for tip rad in Y
  writeBlock(
    inspectionVariables.macroVariable2 + "=[" +
    inspectionVariables.yMeasured + "+[[" +
    ijkFormat.format(cycle.nominalJ) + "*[-1]]*" +
    inspectionVariables.probeRadius + "]]"
  );
  //compensate for tip rad in Z
  writeBlock(
    inspectionVariables.macroVariable3 + "=[" +
    inspectionVariables.zMeasured + "+[[" +
    ijkFormat.format(cycle.nominalK) + "*[-1]]*" +
    inspectionVariables.probeRadius + "]]"
  );
  //Calculate deviation vector (Measured x - nominal x)
  writeBlock(
    inspectionVariables.macroVariable4 + "=[" +
    inspectionVariables.macroVariable1 + "-[" +
    xyzFormat.format(cycle.nominalX) + "]]"
  );
  //Calculate deviation vector (Measured y - nominal y)
  writeBlock(
    inspectionVariables.macroVariable5 + "=[" +
    inspectionVariables.macroVariable2 + "-[" +
    xyzFormat.format(cycle.nominalY) + "]]"
  );
  //Calculate deviation vector (Measured Z - nominal Z)
  writeBlock(
    inspectionVariables.macroVariable6 + "=[" +
    inspectionVariables.macroVariable3 + "-[" +
    xyzFormat.format(cycle.nominalZ) + "]]"
  );
  //sqrt xyz.xyz this is the value of the deviation
  writeBlock(
    inspectionVariables.macroVariable7 + "=SQRT[[" +
    inspectionVariables.macroVariable4 + "*" +
    inspectionVariables.macroVariable4 + "]+[" +
    inspectionVariables.macroVariable5 + "*" +
    inspectionVariables.macroVariable5 + "]+[" +
    inspectionVariables.macroVariable6 + "*" +
    inspectionVariables.macroVariable6 + "]]"
  );
  //sign of the vector
  writeBlock(
    inspectionVariables.macroVariable1 + "=[[" +
    ijkFormat.format(cycle.nominalI) + "*" +
    inspectionVariables.macroVariable4 + "]+[" +
    ijkFormat.format(cycle.nominalJ) + "*" +
    inspectionVariables.macroVariable5 + "]+[" +
    ijkFormat.format(cycle.nominalK) + "*" +
    inspectionVariables.macroVariable6 + "]]"
  );
  //Print out deviation value
  forceSequenceNumbers(true);
  writeBlock(
    "IF [" + inspectionVariables.macroVariable1 + "GE0] GOTO" + skipNLines(3)
  );
  writeBlock(
    inspectionVariables.macroVariable4 + "=" +
    inspectionVariables.macroVariable7
  );
  writeBlock("GOTO" + skipNLines(2));
  writeBlock(
    inspectionVariables.macroVariable4 + "=[" +
    inspectionVariables.macroVariable7 + "*[-1]]"
  );
  writeBlock(" ");
  writeln(
    "DPRNT[G802" + "*N" + inspectionVariables.pointNumber +
      "*DEVIATION*" + inspectionVariables.macroVariable4 + macroRoundingFormat + "]"
  );
  //Tolerance check
  writeBlock(
    "IF [" + inspectionVariables.macroVariable4 +
     "LT" + (xyzFormat.format(getParameter("operation:inspectUpperTolerance"))) +
     "] GOTO" + skipNLines(3)
  );
  writeBlock(
    "#3006 = 1" + formatComment("Inspection point over tolerance")
  );
  writeBlock("GOTO" + skipNLines(3));
  writeBlock(
    "IF [" + inspectionVariables.macroVariable4 +
    "GT" + (xyzFormat.format(getParameter("operation:inspectLowerTolerance"))) +
    "] GOTO" + skipNLines(2)
  );
  writeBlock(
    "#3006 = 1" + formatComment("Inspection point under tolerance")
  );
  writeBlock(" ");
  forceSequenceNumbers(false);
}

function inspectionWriteMeasuredData(cycle) {
  writeln("DPRNT[G801" +
    "*N" + inspectionVariables.pointNumber +
    "*X" + inspectionVariables.xMeasured + macroRoundingFormat +
    "*Y" + inspectionVariables.yMeasured + macroRoundingFormat +
    "*Z" + inspectionVariables.zMeasured + macroRoundingFormat +
    "*R" + inspectionVariables.probeRadius + macroRoundingFormat +
    "]"
  );

  if (cycle.outOfPositionAction == "stop-message") {
    inspectionCalculateDeviation(cycle);
  }

  if (getProperty("useDirectConnection")) {
    var writeResultIndexX = inspectionVariables.probeResultsStartAddress + (3 * inspectionVariables.probeResultsBufferIndex);
    var writeResultIndexY = inspectionVariables.probeResultsStartAddress + (3 * inspectionVariables.probeResultsBufferIndex) + 1;
    var writeResultIndexZ = inspectionVariables.probeResultsStartAddress + (3 * inspectionVariables.probeResultsBufferIndex) + 2;

    writeBlock(macroFormat.format(writeResultIndexX) + " = " + inspectionVariables.xMeasured);
    writeBlock(macroFormat.format(writeResultIndexY) + " = " + inspectionVariables.yMeasured);
    writeBlock(macroFormat.format(writeResultIndexZ) + " = " + inspectionVariables.zMeasured);
    inspectionVariables.probeResultsBufferIndex += 1;
    if (inspectionVariables.probeResultsBufferIndex > getProperty("probeNumberofPoints")) {
      inspectionVariables.probeResultsBufferIndex = 0;
    }
    writeBlock(inspectionVariables.probeResultsWritePointer + " = " + inspectionVariables.probeResultsBufferIndex);
  }

  if (getProperty("commissioningMode") && (getProperty("calibrationNCOutput") == "Ring Gauge")) {
    writeBlock(macroFormat.format(inspectionVariables.measuredXStartingAddress + inspectionVariables.pointNumber) +
    "=" + inspectionVariables.xMeasured);
    writeBlock(macroFormat.format(inspectionVariables.measuredYStartingAddress + inspectionVariables.pointNumber) +
    "=" + inspectionVariables.yMeasured);
    writeBlock(macroFormat.format(inspectionVariables.measuredZStartingAddress + inspectionVariables.pointNumber) +
    "=" + inspectionVariables.zMeasured);
    writeBlock(macroFormat.format(inspectionVariables.measuredIStartingAddress + inspectionVariables.pointNumber) +
    "=" + xyzFormat.format(cycle.nominalI));
    writeBlock(macroFormat.format(inspectionVariables.measuredJStartingAddress + inspectionVariables.pointNumber) +
    "=" + xyzFormat.format(cycle.nominalJ));
    writeBlock(macroFormat.format(inspectionVariables.measuredKStartingAddress + inspectionVariables.pointNumber) +
    "=" + xyzFormat.format(cycle.nominalK));
  }
  inspectionVariables.pointNumber += 1;
}

function forceSequenceNumbers(force) {
  if (force) {
    setProperty("showSequenceNumbers", "true");
  } else {
    setProperty("showSequenceNumbers", saveShowSequenceNumbers);
  }
}

function skipNLines(n) {
  return (n * getProperty("sequenceNumberIncrement") + sequenceNumber);
}

function resultsOutputLine(n, s) {
  if (n == 0) {
    writeBlock("GOTO #1");
  } else if (n != 20)  {
    writeln("GOTO " + (20 + s));
  }
  sequenceNumber = (n == 0) ? s : n + s;
  writeBlock(" ");
}

function inspectionProcessSectionStart() {
  // only write header once if user selects a single results file
  if (!isDPRNTopen || !getProperty("singleResultsFile") || (currentSection.workOffset != inspectionVariables.workpieceOffset)) {
    inspectionCreateResultsFileHeader();
    inspectionVariables.workpieceOffset = currentSection.workOffset;
  }
  // write the toolpath name as a comment
  writeProbingToolpathInformation();
  inspectionWriteCADTransform();
  inspectionWriteWorkplaneTransform();
  inspectionVariables.inspectionSectionCount += 1;
  if (getProperty("toolOffsetType") == "geomOnly") {
    writeComment("Geometry Only");
    writeBlock(
      inspectionVariables.activeToolLength + "=" +
      inspectionVariables.localVariablePrefix + "[" +
      inspectionVariables.systemVariableOffsetLengthTable + " + " +
      macroFormat.format(4111) +
      "]"
    );
  } else {
    writeComment("Geometry and Wear");
    writeBlock(
      inspectionVariables.activeToolLength + "=" +
      inspectionVariables.localVariablePrefix + "[" +
      inspectionVariables.systemVariableOffsetLengthTable + " + " +
      macroFormat.format(4111) +
      "] + " +
      inspectionVariables.localVariablePrefix + "[" +
      inspectionVariables.systemVariableOffsetWearTable + " + " +
      macroFormat.format(4111) +
      "]"
    );
  }
  if (getProperty("probeCalibrationMethod") == "Renishaw") {
    writeBlock(inspectionVariables.probeRadius + "=[[" +
      macroFormat.format(getProperty("probeCalibratedRadius")) + " + " +
      macroFormat.format(getProperty("probeCalibratedRadius") + 1) + "]" + "/2]"
    );
  } else {
    writeBlock(inspectionVariables.probeRadius + "=" + macroFormat.format(getProperty("probeCalibratedRadius")));
  }
  if (getProperty("commissioningMode") && !isDPRNTopen) {
    writeln("DPRNT[CALIBRATED*RADIUS*" + inspectionVariables.probeRadius + macroRoundingFormat + "]");
    writeln("DPRNT[ECCENTRICITY*X****" + macroFormat.format(getProperty("probeEccentricityX")) + macroRoundingFormat + "]");
    writeln("DPRNT[ECCENTRICITY*Y****" + macroFormat.format(getProperty("probeEccentricityY")) + macroRoundingFormat + "]");
    forceSequenceNumbers(true);
    writeBlock("IF [" + inspectionVariables.probeRadius + " NE #0] GOTO" + skipNLines(2));
    writeBlock("#3000 = 1" + formatComment("PROBE NOT CALIBRATED OR PROPERTY CALIBRATED RADIUS INCORRECT"));
    writeBlock("IF [" + inspectionVariables.probeRadius + " NE 0] GOTO" + skipNLines(2));
    writeBlock("#3000 = 1" + formatComment("PROBE NOT CALIBRATED OR PROPERTY CALIBRATED RADIUS INCORRECT"));
    writeBlock("IF [" + inspectionVariables.probeRadius + " LT " + xyzFormat.format(tool.diameter / 2) + "] GOTO" + skipNLines(2));
    writeBlock("#3000 = 1" + formatComment("PROBE NOT CALIBRATED OR PROPERTY CALIBRATED RADIUS INCORRECT"));
    var maxEccentricity = (unit == MM) ? 0.2 : 0.0079;
    writeBlock("IF [ABS[" + macroFormat.format(getProperty("probeEccentricityX")) + "] LT " + maxEccentricity + "] GOTO" + skipNLines(2));
    writeBlock("#3000 = 1" + formatComment("PROBE NOT CALIBRATED OR PROPERTY ECCENTRICITY X INCORRECT"));
    writeBlock("IF [ABS[" + macroFormat.format(getProperty("probeEccentricityY")) + "] LT " + maxEccentricity + "] GOTO" + skipNLines(2));
    writeBlock("#3000 = 1" + formatComment("PROBE NOT CALIBRATED OR PROPERTY ECCENTRICITY Y INCORRECT"));
    writeBlock("IF [" + macroFormat.format(getProperty("probeEccentricityX")) + " NE #0] GOTO" + skipNLines(2));
    writeBlock("#3000 = 1" + formatComment("PROBE NOT CALIBRATED OR PROPERTY ECCENTRICITY X INCORRECT"));
    writeBlock("IF [" + macroFormat.format(getProperty("probeEccentricityY")) + " NE #0] GOTO" + skipNLines(2));
    writeBlock("#3000 = 1" + formatComment("PROBE NOT CALIBRATED OR PROPERTY ECCENTRICITY Y INCORRECT"));
    forceSequenceNumbers(false);
  }
  isDPRNTopen = true;
  if (inspectionVariables.toolLengthParameterCheck) {
    forceSequenceNumbers(true);
    writeBlock(inspectionVariables.macroVariable1 + "=PRM[6014,4]");
    writeBlock("IF [" + inspectionVariables.macroVariable1 + " EQ 0] GOTO" + skipNLines(2));
    writeBlock(inspectionVariables.activeToolLength + " = 0");
    writeBlock(" ");
    forceSequenceNumbers(false);
  }
}

function inspectionProcessSectionEnd() {
  // close inspection results file if the NC has inspection toolpaths
  if (inspectionVariables.hasInspectionSections) {
    if (getProperty("commissioningMode") && inspectionVariables.printParameterCheck) {
      forceSequenceNumbers(true);
      writeBlock(inspectionVariables.macroVariable1 + "=PRM[6019,3]");
      writeBlock("IF [" + inspectionVariables.macroVariable1 + " NE 0] GOTO" + skipNLines(2));
      writeBlock("#3006 = 1 " + formatComment("MRESULTS FILENAME IS PRNTXXXX.DAT"));
      writeBlock("IF [" + inspectionVariables.macroVariable1 + " NE 1] GOTO" + skipNLines(2));
      writeBlock("#3006 = 1 " + formatComment("MRESULTS FILENAME IS MCR_PRNT.TXT"));
      var skipValue = skipNLines(2);
      writeBlock("#1 = [PRM[20] + " + skipValue + "]");
      resultsOutputLine(0, skipValue);
      writeln("#3006=1" + formatComment("A Results file has been output to - Serial"));
      resultsOutputLine(4, skipValue);
      writeln("#3006=1" + formatComment("A Results file has been output to - Memory Card"));
      resultsOutputLine(5, skipValue);
      writeln("#3006=1" + formatComment("A Results file has been output to - Data Server"));
      resultsOutputLine(9, skipValue);
      writeln("#3006=1" + formatComment("A Results file has been output to - FTP"));
      resultsOutputLine(15, skipValue);
      writeln("#3006=1" + formatComment("A Results file has been output to - ethernet"));
      resultsOutputLine(17, skipValue);
      writeln("#3006=1" + formatComment("A Results file has been output to - USB"));
      resultsOutputLine(20, skipValue);
      forceSequenceNumbers(false);
      onCommand(COMMAND_STOP);
    }
  }
}
// <<<<< INCLUDED FROM inspection/common/fanuc base inspection.cps
