# Barycentric Coordinates
```
util::barycentric(Vector3 P, Vector4[] verts)
```
## 功能：
計算螢幕座標下某一點 P 相對於三角形三個頂點的 重心座標 (α, β, γ)，並進行 透視校正，返回校正後的三個權重。

## 操作思路：

1.齊次座標轉換

將三個頂點 verts[0..2] 轉換為 3D 向量 (A, B, C)，用於 2D 平面計算。

2.計算 2D 重心座標

使用三角形面積公式計算 α、β、γ。

這些值代表 P 在三角形中的相對位置。

3.透視校正

由於頂點在投影後有不同的 w 值，直接線性插值會產生失真。

將 α、β、γ 分別除以對應頂點的 w 值，再重新正規化。

4.返回結果

返回校正後的 {α_p, β_p, γ_p}，可用於正確插值頂點屬性。

```
float[] barycentric(Vector3 P, Vector4[] verts) {
    // 將三個頂點的齊次座標轉換成三維座標 (去掉 w)
    Vector3 A = verts[0].homogenized();
    Vector3 B = verts[1].homogenized();
    Vector3 C = verts[2].homogenized();

    // 保留原始的齊次座標 (含 w)，用於透視校正
    Vector4 AW = verts[0];
    Vector4 BW = verts[1];
    Vector4 CW = verts[2];

    // Step 1: 在 2D 平面上計算原始重心座標 (未校正)
    // 使用三角形面積公式計算 α、β、γ
    float denom = (B.y - C.y) * (A.x - C.x) + (C.x - B.x) * (A.y - C.y);
    float alpha = ((B.y - C.y) * (P.x - C.x) + (C.x - B.x) * (P.y - C.y)) / denom;
    float beta  = ((C.y - A.y) * (P.x - C.x) + (A.x - C.x) * (P.y - C.y)) / denom;
    float gamma = 1.0f - alpha - beta; // 保證三者和為 1

    // Step 2: 透視校正 (Perspective correction)
    // 取出三個頂點的 w 值
    float wA = AW.w;
    float wB = BW.w;
    float wC = CW.w;

    // 將重心座標除以對應的 w 值
    float alpha_p = alpha / wA;
    float beta_p  = beta  / wB;
    float gamma_p = gamma / wC;

    // 重新正規化，保證三者和為 1
    float sum = alpha_p + beta_p + gamma_p;
    alpha_p /= sum;
    beta_p  /= sum;
    gamma_p /= sum;

    // 返回校正後的重心座標 (α, β, γ)
    return new float[]{ alpha_p, beta_p, gamma_p };
}

```

# Phong Shading
```
Material::PhongMaterial
ColorShader::PhongVertexShader
ColorShader::PhongFragmentShader
```
## 功能：
適合需要真實光照效果的場景，例如：球體、曲面模型。
與 Flat Shading 相比，Phong Shading 能正確呈現高光區域，避免失真。

## 結構：

1.PhongVertexShader

功能：處理頂點座標與法線，並輸出到光柵化階段。

主要步驟：

使用 MVP 矩陣將頂點投影到螢幕座標 (gl_Position)。

使用模型矩陣 M 將頂點轉換到世界座標 (w_position)。

使用模型矩陣 M 將法線轉換到世界空間 (w_normal)。

輸出：三組 varying → gl_Position、世界座標、世界法線。

```
public class PhongVertexShader extends VertexShader {
    @Override
    Vector4[][] main(Object[] attribute, Object[] uniform) {
        // 取得頂點位置與法線
        Vector3[] aVertexPosition = (Vector3[]) attribute[0];
        Vector3[] aVertexNormal   = (Vector3[]) attribute[1];
        Matrix4 MVP = (Matrix4) uniform[0]; // 模型-視圖-投影矩陣
        Matrix4 M   = (Matrix4) uniform[1]; // 模型矩陣 (世界座標轉換)

        // 準備輸出陣列
        Vector4[] gl_Position = new Vector4[3]; // 投影後座標
        Vector4[] w_position  = new Vector4[3]; // 世界座標
        Vector4[] w_normal    = new Vector4[3]; // 世界法線

        for (int i = 0; i < gl_Position.length; i++) {
            // 投影到螢幕座標 (裁剪空間)
            gl_Position[i] = MVP.mult(aVertexPosition[i].getVector4(1.0));

            // 世界座標 (乘上模型矩陣)
            w_position[i] = M.mult(aVertexPosition[i].getVector4(1.0));

            // 世界法線 (w=0，避免平移影響)
            w_normal[i] = M.mult(aVertexNormal[i].getVector4(0.0));
        }

        // 返回 varying：投影座標、世界座標、世界法線
        return new Vector4[][] { gl_Position, w_position, w_normal };
    }
}

```

2.PhongFragmentShader

功能：在片元着色器中逐像素計算光照。

輸入：varying 包含片元位置、世界座標、世界法線、材質顏色 (albedo)、材質係數 (Kd, Ks, m)。

主要步驟：

法線正規化。

計算光源方向 L、視線方向 V。

計算反射方向 R = 2(N·L)N - L。

計算光照分量：

環境光 (Ambient)：albedo * Ka (此處固定 0.3)。

漫反射 (Diffuse)：albedo * Kd * max(N·L, 0)。

鏡面反射 (Specular)：lightColor * Ks * (max(R·V, 0))^m。

將三者相加得到最終顏色。

輸出：Vector4(finalColor, 1.0)。

```
public class PhongFragmentShader extends FragmentShader {
    @Override
    Vector4 main(Object[] varying) {
        // 從 varying 取得插值後的資料
        Vector3 position   = (Vector3) varying[0]; // 屏幕座標
        Vector3 w_position = (Vector3) varying[1]; // 世界座標
        Vector3 w_normal   = (Vector3) varying[2]; // 世界法線
        Vector3 albedo     = (Vector3) varying[3]; // 材質顏色
        Vector3 kdksm      = (Vector3) varying[4]; // Kd, Ks, m

        Light light = basic_light; // 場景光源
        Camera cam  = main_camera; // 主相機

        // 法線正規化
        Vector3 N = w_normal.unit_vector();

        // 光源方向 (點光源：光源位置 - 片元位置)
        Vector3 L = light.transform.position.sub(w_position).unit_vector();

        // 視線方向 (相機位置 - 片元位置)
        Vector3 V = cam.transform.position.sub(w_position).unit_vector();

        // 反射方向 R = 2(N·L)N - L
        Vector3 R = N.mult(2 * Vector3.dot(N, L)).sub(L).unit_vector();

        // 光源顏色與強度
        Vector3 lightColor = light.light_color;
        float intensity = light.intensity;

        // 環境光 (Ka 固定 0.3)
        Vector3 ambient = albedo.mult(0.3f);

        // 漫反射 (Kd * max(N·L, 0))
        float diff = Math.max(Vector3.dot(N, L), 0.0f);
        Vector3 diffuse = albedo.mult(kdksm.x * diff).mult(intensity);

        // 鏡面反射 (Ks * (R·V)^m)
        float spec = (float) Math.pow(Math.max(Vector3.dot(R, V), 0.0f), kdksm.z);
        Vector3 specular = lightColor.mult(kdksm.y * spec).mult(intensity);

        // 最終顏色 = 環境光 + 漫反射 + 鏡面反射
        Vector3 finalColor = ambient.add(diffuse).add(specular);

        // 返回 RGBA 顏色 (alpha=1.0)
        return new Vector4(finalColor.x(), finalColor.y(), finalColor.z(), 1.0f);
    }
}

```

3.PhongMaterial

功能：封裝 Phong 着色器，並提供材質參數。

材質參數：

Ka = (0.3, 0.3, 0.3) → 環境光係數。

Kd = 0.5 → 漫反射係數。

Ks = 0.5 → 鏡面反射係數。

m = 20 → 高光指數 (shininess)。

主要方法：

vertexShader：呼叫 PhongVertexShader，傳入頂點位置與法線。

fragmentShader：呼叫 PhongFragmentShader，傳入插值後的座標、法線、材質顏色與光照參數。



```
public class PhongMaterial extends Material {
    // 材質參數
    Vector3 Ka = new Vector3(0.3, 0.3, 0.3); // 環境光係數
    float Kd = 0.5; // 漫反射係數
    float Ks = 0.5; // 鏡面反射係數
    float m = 20;   // 高光指數 (shininess)

    PhongMaterial() {
        // 綁定 Phong 着色器
        shader = new Shader(new PhongVertexShader(), new PhongFragmentShader());
    }

    @Override
    Vector4[][] vertexShader(Triangle triangle, Matrix4 M) {
        // 計算 MVP 矩陣
        Matrix4 MVP = main_camera.Matrix().mult(M);
        Vector3[] position = triangle.verts;  // 三角形頂點位置
        Vector3[] normal   = triangle.normal; // 三角形頂點法線

        // 呼叫頂點着色器
        Vector4[][] r = shader.vertex.main(
            new Object[] { position, normal },
            new Object[] { MVP, M }
        );
        return r;
    }

    @Override
    Vector4 fragmentShader(Vector3 position, Vector4[] varing) {
        // 呼叫片元着色器，傳入插值後的座標、法線、材質顏色與光照參數
        return shader.fragment.main(
            new Object[] { position, varing[0].xyz(), varing[1].xyz(), albedo, new Vector3(Kd, Ks, m) }
        );
    }
}

```

<img width="1243" height="784" alt="image" src="https://github.com/user-attachments/assets/e5147634-30ca-49cd-8a58-8b97318e5d96" />
