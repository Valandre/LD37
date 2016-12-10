{
	"s3d": {
		"Renderer": {
			"Lights": {
				"LightSystem": {
					"ambientLight": "#CEC4B1"
				}
			},
			"Shaders": {
				"ambient": {
					"shader shaders Composite": {
						"dofPower": 0.3,
						"global_saturation": 1.1,
						"hasBLOOM": true,
						"bloomPower": 5,
						"global_brightness": 0.02,
						"fogAmount": 0.9,
						"global_contrast": 1.1,
						"fogPower": 3,
						"dofAmount": 4,
						"hasFOG": true,
						"fogColor": "#221938",
						"dofStart": 0.02,
						"fogDensity": 0.06,
						"hasDOF": true,
						"fogStart": 0.1,
						"bloomAmount": 1
					}
				}
			}
		},
		"Scene": {
			"DirLight": {
				"Light": {
					"priority": 10
				}
			}
		}
	}
}