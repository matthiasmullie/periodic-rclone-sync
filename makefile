publish:
	docker buildx build --push --platform linux/arm/v7,linux/arm64/v8,linux/amd64 --tag matthiasmullie/periodic-rclone-sync .

test:
	mkdir -p /tmp/source
	echo "OK" > /tmp/source/file.txt
	rm -f /tmp/target/test.txt
	docker build -t periodic-rclone-sync .
	docker run --rm -d \
		--name=periodic-rclone-sync \
		-v /tmp/source:/source \
		-v /tmp/target:/target \
		-e INTERVAL=1 \
		-e SOURCE=/source \
		-e TARGET=/target \
		periodic-rclone-sync
	sleep 70
	rm -f /tmp/source/file.txt
	docker stop periodic-rclone-sync
	docker rmi periodic-rclone-sync
	RESPONSE="$$(cat /tmp/target/file.txt)"; \
	rm -f /tmp/target/file.txt; \
	test "$$RESPONSE" = "OK"
