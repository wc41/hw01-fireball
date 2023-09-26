import {vec3, vec4} from 'gl-matrix';
const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import Cube from './geometry/Cube';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 5,
  'Load Scene': loadScene, // A function pointer, essentially
  color: [98,3,3,1],
  FBMspeed: 0.0033,
  PulseSpeed: 0.13,
  FBMfrequency: 6.0,
  'FBMgain': 0.65,
  perlinFactor: 0.09,
  'reset': reset,
  'supercore (party inside)': exploding,
  'blue guy': littleguy,
  'oppenheimer': oppenheimer
};
function reset() {
  controls['tesselations'] = 5;
  controls['color'] = [98,3,3,1];
  controls['FBMspeed'] = 0.0033;
  controls['PulseSpeed'] = 0.13;
  controls['FBMfrequency'] = 6.0;
  controls['FBMgain'] = 0.66;
  controls['perlinFactor'] = 0.09;
}
function exploding() {
  controls['tesselations'] = 7;
  controls['color'] = [91, 0, 0, 1];
  controls['FBMspeed'] = 0.013;
  controls['PulseSpeed'] = 0.24;
  controls['FBMfrequency'] = 15;
  controls['FBMgain'] = 0.67;
  controls['perlinFactor'] = 0.22;
}
function littleguy() {
  controls['tesselations'] = 3;
  controls['color'] = [49, 24, 130, 1];
  controls['FBMspeed'] = 0.002;
  controls['PulseSpeed'] = 0.18;
  controls['FBMfrequency'] = 5.4;
  controls['FBMgain'] = 0.54;
  controls['perlinFactor'] = 0.0;
}
function oppenheimer() {
  controls['tesselations'] = 6;
  controls['color'] = [101, 1, 1, 1];
  controls['FBMspeed'] = 0.0044;
  controls['PulseSpeed'] = 0.0;
  controls['FBMfrequency'] = 3.3;
  controls['FBMgain'] = 0.53;
  controls['perlinFactor'] = 0.0;
}

let icosphere: Icosphere;
let square: Square;
let cube: Cube;
let prevTesselations: number = 5;
let tickCount: GLint = 0;

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
  cube = new Cube(vec3.fromValues(0, 0, 0));
  cube.create();
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'tesselations', 0, 8).step(1);
  gui.add(controls, 'Load Scene');
  gui.add(controls, 'FBMgain', 0.2, 0.74).step(0.01);
  gui.add(controls, 'FBMspeed', 0, 0.013).step(0.0001);
  gui.add(controls, 'FBMfrequency', 0, 15).step(0.1);
  gui.add(controls, 'perlinFactor', 0, 0.5).step(0.01);
  gui.add(controls, 'PulseSpeed', 0, 0.4).step(0.01);
  gui.addColor(controls, 'color');
  gui.add(controls, "reset");
  gui.add(controls, "oppenheimer"); 
  gui.add(controls, "supercore (party inside)");
  gui.add(controls, "blue guy"); 

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  const lambert = new ShaderProgram([

    // new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    // new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),

    // new Shader(gl.VERTEX_SHADER, require('./shaders/special-vert.glsl')), 
    // new Shader(gl.FRAGMENT_SHADER, require('./shaders/perlin-frag.glsl')),

    new Shader(gl.VERTEX_SHADER, require('./shaders/fireball-vert.glsl')), 
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/fireball-frag.glsl')),

  ]);

  const flat = new ShaderProgram([

    // new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    // new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),

    // new Shader(gl.VERTEX_SHADER, require('./shaders/special-vert.glsl')), 
    // new Shader(gl.FRAGMENT_SHADER, require('./shaders/perlin-frag.glsl')),

    new Shader(gl.VERTEX_SHADER, require('./shaders/flat-vert.glsl')), 
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/flat-frag.glsl')),

  ]);

  // This function will be called every frame
  function tick() {
    let fbmGain = controls.FBMgain;

    let freq = controls.FBMfrequency;
    let speed = controls.FBMspeed;
    let perlinFactor = controls.perlinFactor;
    let pulseFreq = controls.PulseSpeed;

    tickCount++;
    camera.update();
    stats.begin(); 
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
    }

    // background
    gl.disable(gl.DEPTH_TEST);
    renderer.render(camera, flat, [
      // icosphere,
      // cube, 
      square,
      ],
      vec4.fromValues(controls.color[0] / 255, controls.color[1] / 255, controls.color[2] / 255, controls.color[3]),
      tickCount,
      perlinFactor,
      speed,
      pulseFreq,
      freq,
      fbmGain);
    gl.enable(gl.DEPTH_TEST);

    renderer.render(camera, lambert, [
      icosphere,
      // cube, 
      // square,
      ],
      vec4.fromValues(controls.color[0] / 255, controls.color[1] / 255, controls.color[2] / 255, controls.color[3]),
      tickCount,
      perlinFactor,
      speed,
      pulseFreq,
      freq,
      fbmGain);
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();
