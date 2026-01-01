public class Camera extends GameObject {
    Matrix4 projection = new Matrix4();
    Matrix4 worldView = new Matrix4();
    int wid;
    int hei;
    float near;
    float far;

    Camera() {
        wid = 256;
        hei = 256;
        worldView.makeIdentity();
        projection.makeIdentity();
        transform.position = new Vector3(0, 0, -50);
        name = "Camera";
    }

    Matrix4 inverseProjection() {
        Matrix4 invProjection = Matrix4.Zero();
        float a = projection.m[0];
        float b = projection.m[5];
        float c = projection.m[10];
        float d = projection.m[11];
        float e = projection.m[14];
        invProjection.m[0] = 1.0f / a;
        invProjection.m[5] = 1.0f / b;
        invProjection.m[11] = 1.0f / e;
        invProjection.m[14] = 1.0f / d;
        invProjection.m[15] = -c / (d * e);
        return invProjection;
    }

    Matrix4 Matrix() {
        return projection.mult(worldView);
    }

    void setSize(int w, int h, float n, float f) {
        wid = w;
        hei = h;
        near = n;
        far = f;
    
        float aspect = (float) w / (float) h;
        float fovRad = radians(GH_FOV); // 假設 GH_FOV 是角度
        float t = (float) Math.tan(fovRad / 2.0);
    
        projection = Matrix4.Zero();
    
        // 第一列
        projection.m[0] = 1.0f / (aspect * t);
        projection.m[1] = 0;
        projection.m[2] = 0;
        projection.m[3] = 0;
    
        // 第二列
        projection.m[4] = 0;
        projection.m[5] = 1.0f / t;
        projection.m[6] = 0;
        projection.m[7] = 0;
    
        // 第三列
        projection.m[8]  = 0;
        projection.m[9]  = 0;
        projection.m[10] = (f + n) / (n - f);
        projection.m[11] = (2 * f * n) / (n - f);
    
        // 第四列
        projection.m[12] = 0;
        projection.m[13] = 0;
        projection.m[14] = -1;
        projection.m[15] = 0;
    }

    void setPositionOrientation(Vector3 pos, float rotX, float rotY) {
        worldView = Matrix4.RotX(rotX).mult(Matrix4.RotY(rotY)).mult(Matrix4.Trans(pos.mult(-1)));
    }

    void setPositionOrientation() {
        worldView = Matrix4.RotX(transform.rotation.x).mult(Matrix4.RotY(transform.rotation.y))
                .mult(Matrix4.Trans(transform.position.mult(-1)));
    }

    void setPositionOrientation(Vector3 pos, Vector3 lookat) {
    
        if (pos == null || lookat == null) {
            println("ERROR: pos or lookat is null");
            return;
        }
    
        Vector3 up = Vector3.UnitY();
    
        Vector3 z = Vector3.sub(pos, lookat);
        z.normalize();
    
        Vector3 x = Vector3.cross(up, z);
        x.normalize();
    
        Vector3 y = Vector3.cross(z, x);
        y.normalize();
    
        worldView = new Matrix4();
        worldView.makeIdentity();   // 確保 m 已存在
    
        worldView.m[0] = x.x();
        worldView.m[1] = x.y();
        worldView.m[2] = x.z();
        worldView.m[3] = -Vector3.dot(x, pos);
    
        worldView.m[4] = y.x();
        worldView.m[5] = y.y();
        worldView.m[6] = y.z();
        worldView.m[7] = -Vector3.dot(y, pos);
    
        worldView.m[8]  = z.x();
        worldView.m[9]  = z.y();
        worldView.m[10] = z.z();
        worldView.m[11] = -Vector3.dot(z, pos);
    
        worldView.m[12] = 0;
        worldView.m[13] = 0;
        worldView.m[14] = 0;
        worldView.m[15] = 1;
    }

}
