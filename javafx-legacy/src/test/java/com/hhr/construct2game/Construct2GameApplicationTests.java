package com.hhr.construct2game;

import com.hhr.construct2game.util.ResourcesPathUtil;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class Construct2GameApplicationTests {

	@Test
	void gameResourcesAreAvailable() {
		assertNotNull(ResourcesPathUtil.getPathOfUrl("/fxml/main.fxml"));
		assertNotNull(ResourcesPathUtil.getPathOfUrl("/construct2Game/index.html"));
		assertDoesNotThrow(() -> ResourcesPathUtil.getPathOfString("/construct2Game/icon-256.png"));
	}
}
