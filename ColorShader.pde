public class PhongVertexShader extends VertexShader {
    @Override
    Vector4[][] main(Object[] attribute, Object[] uniform) {
        Vector3[] aVertexPosition = (Vector3[]) attribute[0];
        Vector3[] aVertexNormal   = (Vector3[]) attribute[1];
        Matrix4 MVP = (Matrix4) uniform[0];
        Matrix4 M   = (Matrix4) uniform[1];

        Vector4[] gl_Position = new Vector4[3];
        Vector4[] w_position  = new Vector4[3];
        Vector4[] w_normal    = new Vector4[3];

        for (int i = 0; i < gl_Position.length; i++) {
            // 投影到屏幕
            gl_Position[i] = MVP.mult(aVertexPosition[i].getVector4(1.0));

            // 世界座標
            w_position[i] = M.mult(aVertexPosition[i].getVector4(1.0));

            // 世界法線
            w_normal[i] = M.mult(aVertexNormal[i].getVector4(0.0));
        }

        // 返回 varying：gl_Position, 世界座標, 世界法線
        return new Vector4[][] { gl_Position, w_position, w_normal };
    }
}

public class PhongFragmentShader extends FragmentShader {
    @Override
    Vector4 main(Object[] varying) {
        // 從 varying 取得資料
        Vector3 position   = (Vector3) varying[0]; // 屏幕座標
        Vector3 w_position = (Vector3) varying[1]; // 世界座標
        Vector3 w_normal   = (Vector3) varying[2]; // 世界法線
        Vector3 albedo     = (Vector3) varying[3]; // 物體顏色
        Vector3 kdksm      = (Vector3) varying[4]; // Kd, Ks, m

        Light light = basic_light;
        Camera cam  = main_camera;

        // 法線正規化
        Vector3 N = w_normal.unit_vector();

        // 光源方向 (點光源：光源位置 - 片段位置)
        Vector3 L = light.transform.position.sub(w_position).unit_vector();

        // 視線方向 (從片段指向相機)
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

        // 最終顏色
        Vector3 finalColor = ambient.add(diffuse).add(specular);

        return new Vector4(finalColor.x(), finalColor.y(), finalColor.z(), 1.0f);
    }
}

public class FlatVertexShader extends VertexShader {
    Vector4[][] main(Object[] attribute, Object[] uniform) {
        Vector3[] aVertexPosition = (Vector3[]) attribute[0];
        Matrix4 MVP = (Matrix4) uniform[0];
        Vector4[] gl_Position = new Vector4[3];

        // TODO HW4
        // Here you have to complete Flat shading.
        // We have instantiated the relevant Material, and you may be missing some
        // variables.
        // Please refer to the templates of Phong Material and Phong Shader to complete
        // this part.

        // Note: Here the first variable must return the position of the vertex.
        // Subsequent variables will be interpolated and passed to the fragment shader.
        // The return value must be a Vector4.

        for (int i = 0; i < gl_Position.length; i++) {
            gl_Position[i] = MVP.mult(aVertexPosition[i].getVector4(1.0));
        }

        Vector4[][] result = { gl_Position };

        return result;
    }
}

public class FlatFragmentShader extends FragmentShader {
    Vector4 main(Object[] varying) {
        Vector3 position = (Vector3) varying[0];
        // TODO HW4
        // Here you have to complete Flat shading.
        // We have instantiated the relevant Material, and you may be missing some
        // variables.
        // Please refer to the templates of Phong Material and Phong Shader to complete
        // this part.

        // Note : In the fragment shader, the first 'varying' variable must be its
        // screen position.
        // Subsequent variables will be received in order from the vertex shader.
        // Additional variables needed will be passed by the material later.

        return new Vector4(0.0, 0.0, 0.0, 1.0);
    }
}

public class GouraudVertexShader extends VertexShader {
    Vector4[][] main(Object[] attribute, Object[] uniform) {
        Vector3[] aVertexPosition = (Vector3[]) attribute[0];
        Matrix4 MVP = (Matrix4) uniform[0];

        Vector4[] gl_Position = new Vector4[3];

        // TODO HW4
        // Here you have to complete Gouraud shading.
        // We have instantiated the relevant Material, and you may be missing some
        // variables.
        // Please refer to the templates of Phong Material and Phong Shader to complete
        // this part.

        // Note: Here the first variable must return the position of the vertex.
        // Subsequent variables will be interpolated and passed to the fragment shader.
        // The return value must be a Vector4.

        for (int i = 0; i < gl_Position.length; i++) {
            gl_Position[i] = MVP.mult(aVertexPosition[i].getVector4(1.0));

        }

        Vector4[][] result = { gl_Position };

        return result;
    }
}

public class GouraudFragmentShader extends FragmentShader {
    Vector4 main(Object[] varying) {
        Vector3 position = (Vector3) varying[0];

        // TODO HW4
        // Here you have to complete Gouraud shading.
        // We have instantiated the relevant Material, and you may be missing some
        // variables.
        // Please refer to the templates of Phong Material and Phong Shader to complete
        // this part.

        // Note : In the fragment shader, the first 'varying' variable must be its
        // screen position.
        // Subsequent variables will be received in order from the vertex shader.
        // Additional variables needed will be passed by the material later.

        return new Vector4(0.0, 0.0, 0.0, 1.0);
    }
}
