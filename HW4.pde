import javax.swing.JFileChooser;
import javax.swing.filechooser.FileNameExtensionFilter;

public Vector4 renderer_size;
static public float GH_FOV = 45.0f;
static public float GH_NEAR_MIN = 1e-3f;
static public float GH_NEAR_MAX = 1e-1f;
static public float GH_FAR = 1000.0f;
static public Vector3 AMBIENT_LIGHT = new Vector3(0.3, 0.3, 0.3);

public boolean debug = false;

public float[] GH_DEPTH;
public PImage renderBuffer;

Engine engine;
Camera main_camera;
Vector3 cam_position;
Vector3 lookat;

Light basic_light;

void setup() {
    size(1000, 600);
    renderer_size = new Vector4(20, 50, 520, 550);

    lookat = new Vector3(0, 0, 0);

    // ❗ 初始化 cam_position
    cam_position = new Vector3(0, 0, -50);  // 或任何你想要的初始攝影機位置

    setDepthBuffer();

    main_camera = new Camera();
    engine = new Engine();
    engine.renderer.addGameObject(basic_light);
    engine.renderer.addGameObject(main_camera);
}


void setDepthBuffer(){
    renderBuffer = new PImage(int(renderer_size.z - renderer_size.x) , int(renderer_size.w - renderer_size.y));
    GH_DEPTH = new float[int(renderer_size.z - renderer_size.x) * int(renderer_size.w - renderer_size.y)];
    for(int i = 0 ; i < GH_DEPTH.length;i++){
        GH_DEPTH[i] = 1.0;
        renderBuffer.pixels[i] = color(1.0*250);
    }
}

void draw() {
    background(255);

    engine.run();
    cameraControl();
}

String selectFile() {
    JFileChooser fileChooser = new JFileChooser();
    fileChooser.setCurrentDirectory(new File("."));
    fileChooser.setFileSelectionMode(JFileChooser.FILES_ONLY);
    FileNameExtensionFilter filter = new FileNameExtensionFilter("Obj Files", "obj");
    fileChooser.setFileFilter(filter);

    int result = fileChooser.showOpenDialog(null);
    if (result == JFileChooser.APPROVE_OPTION) {
        String filePath = fileChooser.getSelectedFile().getAbsolutePath();
        return filePath;
    }
    return "";
}

float yaw = 0;   // 水平角度
float pitch = 0; // 垂直角度



void cameraControl() {
    float speed = 0.1f;

    if (keyPressed) {
        // 移動
        if (key == 'w') cam_position = cam_position.add(new Vector3(0, 0, -speed));
        if (key == 's') cam_position = cam_position.add(new Vector3(0, 0, speed));
        if (key == 'a') cam_position = cam_position.add(new Vector3(-speed, 0, 0));
        if (key == 'd') cam_position = cam_position.add(new Vector3(speed, 0, 0));
        if (key == 'q') cam_position = cam_position.add(new Vector3(0, speed, 0));
        if (key == 'e') cam_position = cam_position.add(new Vector3(0, -speed, 0));

    }

    // 限制 pitch 避免翻轉
    pitch = constrain(pitch, -PI/2, PI/2);

    // 如果 yaw/pitch 都是 0 → 使用 lookat (初始狀態)
    if (yaw == 0 && pitch == 0) {
        main_camera.setPositionOrientation(cam_position, lookat);
    } else {
        // 計算方向向量
        float dirX = cos(yaw) * cos(pitch);
        float dirY = sin(pitch);
        float dirZ = sin(yaw) * cos(pitch);
        Vector3 cam_target = cam_position.add(new Vector3(dirX, dirY, dirZ));

        // 更新攝影機
        main_camera.setPositionOrientation(cam_position, cam_target);
    }
}
