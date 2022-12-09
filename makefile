publish:
	docker buildx build --push --platform linux/arm/v7,linux/arm64/v8,linux/amd64 --tag matthiasmullie/periodic-rclone-sync .

test:
	docker build -t periodic-rclone-sync .
	mkdir -p /tmp/source
	echo "OK" > /tmp/source/file.txt
	rm -f /tmp/target/test.txt
	docker run --rm -d \
		--name=periodic-rclone-sync-success \
		-v /tmp/source:/source \
		-v /tmp/target:/target \
		-e INTERVAL=1 \
		-e SOURCE=/source \
		-e TARGET=/target \
		periodic-rclone-sync
	docker run --rm -d \
		--name=periodic-rclone-sync-fail \
		-v /tmp/source:/source \
		-e INTERVAL=1 \
		-e SOURCE=/source \
		-e TARGET=REMOTE:/does/not/exist \
		periodic-rclone-sync
	sleep 70
	rm -f /tmp/source/file.txt
	LOG_SUCCESS="$$(docker exec periodic-rclone-sync-success cat /var/log/sync.log)"; \
	LOG_FAIL="$$(docker exec periodic-rclone-sync-fail cat /var/log/sync.log)"; \
	docker stop periodic-rclone-sync-success; \
	docker stop periodic-rclone-sync-fail; \
	docker rmi periodic-rclone-sync; \
	CONTENTS_SUCCESS="$$(cat /tmp/target/file.txt)"; \
	rm -f /tmp/target/file.txt; \
	[ "$$( echo $$LOG_SUCCESS | grep 'periodic-rclone-sync complete' )" ] || [ "$$CONTENTS_SUCCESS" == "OK" ] || [ ! "$$( echo $$LOG_FAIL | grep 'periodic-rclone-sync complete' )" ] || exit 1
