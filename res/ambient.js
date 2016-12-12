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
			"Shaders": {
				"ambient": {
					"shader shaders Composite": {
						"fogDensity": 0.04,
						"dofPower": 0.5,
						"bloomPower": 20,
						"fogStart": 10,
						"global_brightness": 0.02,
						"global_contrast": 1.1,
						"bloomAmount": 0.5,
						"hasFOG": true,
						"dofAmount": 4,
						"fogColor": "#221938",
						"fogAmount": 1,
						"fogPower": 1,
						"hasDOF": true,
						"global_saturation": 1.1
					}
				}
			},
			"Lights": {
				"LightSystem": {
					"ambientLight": "#CEC4B1"
				}
			}
		}
	}
}