public void CGLine(float x1, float y1, float x2, float y2) {
    stroke(0);
    line(x1, y1, x2, y2);
}

public boolean outOfBoundary(float x, float y) {
    if (x < 0 || x >= width || y < 0 || y >= height)
        return true;
    return false;
}

public void drawPoint(float x, float y, color c) {
    int index = (int) y * width + (int) x;
    if (outOfBoundary(x, y))
        return;
    pixels[index] = c;
}

public float distance(Vector3 a, Vector3 b) {
    Vector3 c = a.sub(b);
    return sqrt(Vector3.dot(c, c));
}

boolean pnpoly(float x, float y, Vector3[] vertexes) {
    boolean inside = false;
    int n = vertexes.length;

    for (int i = 0, j = n - 1; i < n; j = i++) {
        float xi = vertexes[i].x();
        float yi = vertexes[i].y();
        float xj = vertexes[j].x();
        float yj = vertexes[j].y();

        // 避免除以零，加一個小 epsilon
        float denom = (yj - yi);
        if (Math.abs(denom) < 1e-6f) continue; // 水平邊直接跳過

        boolean intersect = ((yi > y) != (yj > y)) &&
                            (x < (xj - xi) * (y - yi) / denom + xi);

        if (intersect) inside = !inside;
    }

    return inside;
}

public Vector3[] findBoundBox(Vector3[] v) {
    
    
    // TODO HW2 
    // You need to find the bounding box of the vertices v.
    // r1 -------
    //   |   /\  |
    //   |  /  \ |
    //   | /____\|
    //    ------- r2

    if (v == null || v.length == 0) {
        return new Vector3[]{ new Vector3(0,0,0), new Vector3(0,0,0) };
    }

    float minX = v[0].x();
    float maxX = v[0].x();
    float minY = v[0].y();
    float maxY = v[0].y();

    for (int i = 1; i < v.length; i++) {
        float x = v[i].x();
        float y = v[i].y();

        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
    }

    return new Vector3[]{
        new Vector3(minX, minY, 0),   // 左下角
        new Vector3(maxX, maxY, 0)    // 右上角
    };

}

public Vector3[] Sutherland_Hodgman_algorithm(Vector3[] points, Vector3[] boundary) {
    ArrayList<Vector3> input = new ArrayList<Vector3>();
    for (int i = 0; i < points.length; i++) {
        input.add(points[i]);
    }

    // 逐邊界裁切
    for (int j = 0; j < boundary.length; j++) {
        ArrayList<Vector3> output = new ArrayList<Vector3>();
        Vector3 A = boundary[j];
        Vector3 B = boundary[(j + 1) % boundary.length];

        for (int i = 0; i < input.size(); i++) {
            Vector3 P = input.get(i);
            Vector3 Q = input.get((i + 1) % input.size());

            boolean Pin = inside(P, A, B);
            boolean Qin = inside(Q, A, B);

            if (Pin && Qin) {
                // P、Q 都在內部 → 保留 Q
                output.add(Q);
            } else if (Pin && !Qin) {
                // P 在內、Q 在外 → 加入交點
                output.add(intersection(P, Q, A, B));
            } else if (!Pin && Qin) {
                // P 在外、Q 在內 → 加入交點與 Q
                output.add(intersection(P, Q, A, B));
                output.add(Q);
            }
            // P、Q 都在外 → 不加
        }
        input = output;
        if (input.isEmpty()) break;
    }

    Vector3[] result = new Vector3[input.size()];
    for (int i = 0; i < input.size(); i++) {
        result[i] = input.get(i);
    }
    return result;
}

// 判斷點是否在邊界內側
private boolean inside(Vector3 p, Vector3 a, Vector3 b) {
    // (b - a) × (p - a) 的 z > 0 表示 p 在邊界內側
    return ((b.x() - a.x()) * (p.y() - a.y()) -
        (b.y() - a.y()) * (p.x() - a.x())) < 0;

}


// 計算線段 PQ 與邊界 AB 的交點
private Vector3 intersection(Vector3 p, Vector3 q, Vector3 a, Vector3 b) {
    float A1 = q.y() - p.y();
    float B1 = p.x() - q.x();
    float C1 = A1 * p.x() + B1 * p.y();

    float A2 = b.y() - a.y();
    float B2 = a.x() - b.x();
    float C2 = A2 * a.x() + B2 * a.y();

    float det = A1 * B2 - A2 * B1;
    if (abs(det) < 1e-6) {
        return p; // 平行，直接回傳 P
    }
    float x = (B2 * C1 - B1 * C2) / det;
    float y = (A1 * C2 - A2 * C1) / det;
    return new Vector3(x, y, 0);
}

public float getDepth(float x, float y, Vector3[] vertex) {
    Vector3 v0 = vertex[0];
    Vector3 v1 = vertex[1];
    Vector3 v2 = vertex[2];

    // 計算重心座標
    float denom = (v1.y() - v2.y()) * (v0.x() - v2.x()) + 
                  (v2.x() - v1.x()) * (v0.y() - v2.y());

    float alpha = ((v1.y() - v2.y()) * (x - v2.x()) + 
                   (v2.x() - v1.x()) * (y - v2.y())) / denom;

    float beta  = ((v2.y() - v0.y()) * (x - v2.x()) + 
                   (v0.x() - v2.x()) * (y - v2.y())) / denom;

    float gamma = 1.0f - alpha - beta;

    // 用重心座標插值 z
    float z = alpha * v0.z() + beta * v1.z() + gamma * v2.z();

    return z;
}

float[] barycentric(Vector3 P, Vector4[] verts) {
    Vector3 A = verts[0].homogenized();
    Vector3 B = verts[1].homogenized();
    Vector3 C = verts[2].homogenized();

    Vector4 AW = verts[0];
    Vector4 BW = verts[1];
    Vector4 CW = verts[2];

    // Step 1: Raw barycentrics in 2D
    float denom = (B.y - C.y) * (A.x - C.x) + (C.x - B.x) * (A.y - C.y);
    float alpha = ((B.y - C.y) * (P.x - C.x) + (C.x - B.x) * (P.y - C.y)) / denom;
    float beta  = ((C.y - A.y) * (P.x - C.x) + (A.x - C.x) * (P.y - C.y)) / denom;
    float gamma = 1.0f - alpha - beta;

    // Step 2: Perspective correction
    float wA = AW.w;
    float wB = BW.w;
    float wC = CW.w;

    float alpha_p = alpha / wA;
    float beta_p  = beta  / wB;
    float gamma_p = gamma / wC;

    float sum = alpha_p + beta_p + gamma_p;

    alpha_p /= sum;
    beta_p  /= sum;
    gamma_p /= sum;

    return new float[]{ alpha_p, beta_p, gamma_p };
}


Vector3 interpolation(float[] abg, Vector3[] v) {
    return v[0].mult(abg[0]).add(v[1].mult(abg[1])).add(v[2].mult(abg[2]));
}

Vector4 interpolation(float[] abg, Vector4[] v) {
    return v[0].mult(abg[0]).add(v[1].mult(abg[1])).add(v[2].mult(abg[2]));
}

float interpolation(float[] abg, float[] v) {
    return v[0] * abg[0] + v[1] * abg[1] + v[2] * abg[2];
}
