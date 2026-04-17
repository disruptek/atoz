# atoz build tool — convert openapi yaml specs to json, then generate nim
#
# usage:
#   elle build.lisp                    # full build (yaml→json, json→nim)
#   elle build.lisp yaml               # yaml→json only
#   elle build.lisp nim                # json→nim only
#   elle build.lisp nim sqs            # json→nim for one service

(def yaml (import "plugin/yaml"))

(def home    (get (sys/env) "HOME"))
(def src-dir (or (get (sys/env) "OPENAPI_DIR")
                 (string home "/git/openapi-directory/APIs/amazonaws.com")))
(def json-dir  (string home "/git/atoz/json"))
(def nim-dir   (string home "/git/atoz/src/atoz"))
(def nim-bin   (string home "/nims/bin/nim"))
(def atoz-src  (string home "/git/atoz/generator/atoz.nim"))
(def atoz-root (string home "/git/atoz"))

# ── helpers ──────────────────────────────────────────────────────────────────

(defn dir? [path]
  (and (file/exists? path) (get (file/stat path) :is-dir)))

(defn ensure-dir [path]
  (when (not (file/exists? path))
    (ensure-dir path)))

(defn sanitize [s]
  (-> s
    (string/replace "/" "_")
    (string/replace "-" "_")
    (string/replace "." "_")))

(defn strip-dashes [s]
  (string/replace s "-" ""))

(defn mtime [path]
  (try (get (file/stat path) :modified)
    (catch _ 0)))

# ── yaml → json ─────────────────────────────────────────────────────────────

(defn find-specs []
  (def results @[])
  (each service (sort (file/ls src-dir))
    (def spath (string src-dir "/" service))
    (when (dir? spath)
      (each version (sort (file/ls spath))
        (def ypath (string spath "/" version "/openapi.yaml"))
        (when (file/exists? ypath)
          (push results {:service service :version version :yaml ypath})))))
  (freeze results))

(defn json-path [spec]
  (string json-dir "/" (sanitize (get spec :service))
          "/" (strip-dashes (get spec :version)) ".json"))

(defn convert-one [spec]
  (def target (json-path spec))
  (if (> (mtime target) (mtime (get spec :yaml)))
    :skip
    (begin
      (ensure-dir (string json-dir "/" (sanitize (get spec :service))))
      (file/write target (json/serialize (yaml:parse (file/read (get spec :yaml)))))
      (println "  " (sanitize (get spec :service)) " " (strip-dashes (get spec :version)))
      :ok)))

(defn convert-all []
  (def specs (find-specs))
  (println (length specs) " specs found")
  (var converted 0)
  (each spec specs
    (when (= (convert-one spec) :ok)
      (assign converted (+ converted 1))))
  (println converted " converted, " (- (length specs) converted) " up-to-date"))

# ── json → nim ──────────────────────────────────────────────────────────────

(defn find-jsons [filt]
  (def results @[])
  (each dir (sort (file/ls json-dir))
    (def dpath (string json-dir "/" dir))
    (when (dir? dpath)
      (when (or (nil? filt) (= dir filt))
        (each file (file/ls dpath)
          (when (string/ends-with? file ".json")
            (push results {:service dir
                           :version (string/replace file ".json" "")
                           :json    (string dpath "/" file)}))))))
  (freeze results))

(defn build-one [spec]
  (def jp  (get spec :json))
  (def ser (get spec :service))
  (def ver (get spec :version))
  (def out (string nim-dir "/" ser "_" ver ".nim"))
  (if (> (mtime out) (mtime jp))
    :skip
    (begin
      (ensure-dir nim-dir)
      (def env (merge (sys/env) {"OPENAPIIN" jp "OPENAPIOUT" out}))
      (def result (subprocess/system nim-bin
        ["c" (string "--path=" atoz-root)
         "--define:openapiOmitAllDocs"
         "--maxLoopIterationsVM:100000000"
         "--define:ssl" "--hints:off" "--warnings:off"
         "-f" atoz-src]
        {:env env}))


      (if (= (get result :exit) 0)
        (begin (println "  OK " ser " " ver) :ok)
        (begin (println "  FAIL " ser " " ver) :fail)))))

(defn build-all [filt]
  (def specs (find-jsons filt))
  (println (length specs) " specs to build")
  (var ok 0) (var fail 0) (var skip 0)
  (each spec specs
    (def r (build-one spec))
    (cond
      ((= r :ok)   (assign ok   (+ ok 1)))
      ((= r :fail) (assign fail (+ fail 1)))
      (true        (assign skip (+ skip 1)))))
  (println ok " built, " fail " failed, " skip " skipped"))

# ── main ─────────────────────────────────────────────────────────────────────

(def args (sys/args))
(def cmd  (if (> (length args) 0) (first args) "all"))
(def filt (if (> (length args) 1) (first (rest args)) nil))

(cond
  ((= cmd "yaml") (convert-all))
  ((= cmd "nim")  (build-all filt))
  ((= cmd "all")  (begin (convert-all) (build-all filt)))
  (true           (begin (println "usage: elle build.lisp [yaml|nim|all] [service]")
                         (sys/exit 1))))
