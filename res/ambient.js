{
	"s3d": {
		"Scene": {
			"DirLight": {
				"Light": {
					"priority": 10
				}
			}
		},
		"Renderer": {
			"Lights": {
				"LightSystem": {
					"ambientLight": "#CEC4B1"
				}
			},
			"Shaders": {
				"ambient": {
					"shader shaders Composite": {
						"global_brightness": 0.02,
						"dofAmount": 4,
						"bloomAmount": 1,
						"bloomPower": 5,
						"hasFOG": true,
						"global_contrast": 1.1,
						"fogAmount": 1,
						"hasBLOOM": true,
						"hasDOF": true,
						"fogColor": "#221938",
						"dofPower": 0.5,
						"fogStart": 10,
						"global_saturation": 1.1,
						"fogPower": 1,
						"fogDensity": 0.04
					}
				}
			}
		}
	}
}