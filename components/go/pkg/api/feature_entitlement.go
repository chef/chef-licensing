package api

type featureResponse struct {
	Data struct {
		Entitled   bool            `json:"entitled"`
		EntitledBy map[string]bool `json:"entitledBy"`
	} `json:"data"`
	StatusCode int `json:"status"`
}

func (c APIClient) GetFeatureByName(featureName string, keys []string) (interface{}, error) {
	params := struct {
		Keys        []string `json:"licenseIds"`
		FeatureName string   `json:"featureName"`
	}{
		Keys:        keys,
		FeatureName: featureName,
	}

	resp, err := c.doPOSTRequest("featurebyname", params)
	if err != nil {
		return nil, err
	}

	var data featureResponse
	c.decodeJSON(resp, &data)
	return data.Data, nil
}

func (c APIClient) GetFeatureByGUID(featureID string, keys []string) (interface{}, error) {
	params := struct {
		Keys      []string `json:"licenseIds"`
		FeatureID string   `json:"featureGuid"`
	}{
		Keys:      keys,
		FeatureID: featureID,
	}

	resp, err := c.doPOSTRequest("featurebyid", params)
	if err != nil {
		return nil, err
	}

	var data featureResponse
	c.decodeJSON(resp, &data)
	return data.Data, nil
}
