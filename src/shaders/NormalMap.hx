package shaders;

class NormalMap extends hxsl.Shader {

    static var SRC = {

		@global var camera : {
			var position : Vec3;
			@var var dir : Vec3;
		};

        @global var global : {
            @perObject var modelView : Mat4;
        };

        @input var input : {
            var normal : Vec3;
			//var tangent : Vec3;
        };

        @param var texture : Sampler2D;

        var calculatedUV : Vec2;
		var transformedPosition : Vec3;
        var transformedNormal : Vec3;

		@var var transformedTangent : Vec3;

		function vertex() {
			transformedTangent = vec3(1, 0, 0) * global.modelView.mat3();
		}

		function fragment() {

			var n = transformedNormal;
			var nf = unpackNormal(texture.get(calculatedUV));

			#if true

			var tanX = transformedTangent;
			tanX.x *= -1;
			var tanY = n.cross(tanX);
			transformedNormal = (nf.x * tanX - nf.y * tanY + nf.z * n).normalize();

			#else

			// http://www.thetenthplanet.de/archives/1180
			// get edge vectors of the pixel triangle
			var dp1 = dFdx( -camera.dir );
			var dp2 = dFdy( -camera.dir );
			var duv1 = dFdx( calculatedUV );
			var duv2 = dFdy( calculatedUV );

			// solve the linear system
			var dp2perp = cross( dp2, n );
			var dp1perp = cross( n, dp1 );
			var T = dp2perp * duv1.x + dp1perp * duv2.x;
			var B = dp2perp * duv1.y + dp1perp * duv2.y;

			// construct a scale-invariant frame
			var invmax = inversesqrt( max( dot(T, T), dot(B, B) ) );
			var tbn = mat3(T * invmax, B * invmax, n);

//				pixelColor = packNormal((tbn * vec3(1, 0, 0)).normalize() * );
			nf.x = -nf.x; // axis flip, right hand system
			transformedNormal = (tbn * nf).normalize();

			#end

        }

		var pixelColor : Vec4;

    };

    public function new(?texture) {
        super();
        this.texture = texture;
		h3d.Engine.getCurrent().driver.hasFeature(StandardDerivatives);
    }

}