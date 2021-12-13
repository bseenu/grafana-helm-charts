{{/*
Pod template used in Daemonset and Deployment
*/}}
{{- define "promtail.podTemplate" }}
    metadata:
      labels:
        {{- include "promtail.selectorLabels" . | nindent 8 }}
        {{- with .Values.podLabels }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
      annotations:
        checksum/config: {{ include (print .Template.BasePath "/secret.yaml") . | sha256sum }}
        {{- with .Values.podAnnotations }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
    spec:
      serviceAccountName: {{ include "promtail.serviceAccountName" . }}
      {{- with .Values.priorityClassName }}
      priorityClassName: {{ . }}
      {{- end }}
      {{- if .Values.initContainer.enabled }}
      initContainers:
        - name: init
          image: "{{ .Values.initContainer.image.registry }}/{{ .Values.initContainer.image.repository }}:{{ .Values.initContainer.image.tag }}"
          imagePullPolicy: {{ .Values.initContainer.image.pullPolicy }}
          command:
            - sh
            - -c
            - sysctl -w fs.inotify.max_user_instances={{ .Values.initContainer.fsInotifyMaxUserInstances }}
          securityContext:
            privileged: true
      {{- end }}
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      containers:
        - name: promtail
          image: "{{ .Values.image.registry }}/{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          args:
            - "-config.file=/etc/promtail/promtail.yaml"
            {{- with .Values.extraArgs }}
            {{- toYaml . | nindent 12 }}
            {{- end }}
          volumeMounts:
            - name: config
              mountPath: /etc/promtail
            - name: run
              mountPath: /run/promtail
            {{- with .Values.defaultVolumeMounts }}
            {{- toYaml . | nindent 12 }}
            {{- end }}
            {{- with .Values.extraVolumeMounts }}
            {{- toYaml . | nindent 12 }}
            {{- end }}
          env:
            - name: HOSTNAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
          {{- with .Values.extraEnv }}
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.extraEnvFrom }}
          envFrom:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          ports:
            - name: http-metrics
              containerPort: {{ .Values.config.serverPort }}
              protocol: TCP
            {{- range $key, $values := .Values.extraPorts }}
            - name: {{ .name | default $key }}
              containerPort: {{ $values.containerPort }}
              protocol: {{ $values.protocol | default "TCP" }}
            {{- end }}
          securityContext:
            {{- toYaml .Values.containerSecurityContext | nindent 12 }}
          {{- with .Values.livenessProbe }}
          livenessProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.readinessProbe }}
          readinessProbe:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      volumes:
        - name: config
          secret:
            secretName: {{ include "promtail.fullname" . }}
        - name: run
          hostPath:
            path: /run/promtail
        {{- with .Values.defaultVolumes }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
        {{- with .Values.extraVolumes }}
        {{- toYaml . | nindent 8 }}
        {{- end }}
{{- end }}
