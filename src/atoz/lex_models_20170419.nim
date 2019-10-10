
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Lex Model Building Service
## version: 2017-04-19
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon Lex Build-Time Actions</fullname> <p> Amazon Lex is an AWS service for building conversational voice and text interfaces. Use these actions to create, update, and delete conversational bots for new and existing client applications. </p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/lex/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_602467 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602467](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602467): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "models.lex.ap-northeast-1.amazonaws.com", "ap-southeast-1": "models.lex.ap-southeast-1.amazonaws.com",
                           "us-west-2": "models.lex.us-west-2.amazonaws.com",
                           "eu-west-2": "models.lex.eu-west-2.amazonaws.com", "ap-northeast-3": "models.lex.ap-northeast-3.amazonaws.com", "eu-central-1": "models.lex.eu-central-1.amazonaws.com",
                           "us-east-2": "models.lex.us-east-2.amazonaws.com",
                           "us-east-1": "models.lex.us-east-1.amazonaws.com", "cn-northwest-1": "models.lex.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "models.lex.ap-south-1.amazonaws.com",
                           "eu-north-1": "models.lex.eu-north-1.amazonaws.com", "ap-northeast-2": "models.lex.ap-northeast-2.amazonaws.com",
                           "us-west-1": "models.lex.us-west-1.amazonaws.com", "us-gov-east-1": "models.lex.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "models.lex.eu-west-3.amazonaws.com", "cn-north-1": "models.lex.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "models.lex.sa-east-1.amazonaws.com",
                           "eu-west-1": "models.lex.eu-west-1.amazonaws.com", "us-gov-west-1": "models.lex.us-gov-west-1.amazonaws.com", "ap-southeast-2": "models.lex.ap-southeast-2.amazonaws.com", "ca-central-1": "models.lex.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "models.lex.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "models.lex.ap-southeast-1.amazonaws.com",
      "us-west-2": "models.lex.us-west-2.amazonaws.com",
      "eu-west-2": "models.lex.eu-west-2.amazonaws.com",
      "ap-northeast-3": "models.lex.ap-northeast-3.amazonaws.com",
      "eu-central-1": "models.lex.eu-central-1.amazonaws.com",
      "us-east-2": "models.lex.us-east-2.amazonaws.com",
      "us-east-1": "models.lex.us-east-1.amazonaws.com",
      "cn-northwest-1": "models.lex.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "models.lex.ap-south-1.amazonaws.com",
      "eu-north-1": "models.lex.eu-north-1.amazonaws.com",
      "ap-northeast-2": "models.lex.ap-northeast-2.amazonaws.com",
      "us-west-1": "models.lex.us-west-1.amazonaws.com",
      "us-gov-east-1": "models.lex.us-gov-east-1.amazonaws.com",
      "eu-west-3": "models.lex.eu-west-3.amazonaws.com",
      "cn-north-1": "models.lex.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "models.lex.sa-east-1.amazonaws.com",
      "eu-west-1": "models.lex.eu-west-1.amazonaws.com",
      "us-gov-west-1": "models.lex.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "models.lex.ap-southeast-2.amazonaws.com",
      "ca-central-1": "models.lex.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "lex-models"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateBotVersion_602804 = ref object of OpenApiRestCall_602467
proc url_CreateBotVersion_602806(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/bots/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateBotVersion_602805(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Creates a new version of the bot based on the <code>$LATEST</code> version. If the <code>$LATEST</code> version of this resource hasn't changed since you created the last version, Amazon Lex doesn't create a new version. It returns the last created version.</p> <note> <p>You can update only the <code>$LATEST</code> version of the bot. You can't update the numbered versions that you create with the <code>CreateBotVersion</code> operation.</p> </note> <p> When you create the first version of a bot, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p> This operation requires permission for the <code>lex:CreateBotVersion</code> action. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the bot that you want to create a new version of. The name is case sensitive. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_602932 = path.getOrDefault("name")
  valid_602932 = validateParameter(valid_602932, JString, required = true,
                                 default = nil)
  if valid_602932 != nil:
    section.add "name", valid_602932
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602933 = header.getOrDefault("X-Amz-Date")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Date", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Security-Token")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Security-Token", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Content-Sha256", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-Algorithm")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-Algorithm", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Signature")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Signature", valid_602937
  var valid_602938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602938 = validateParameter(valid_602938, JString, required = false,
                                 default = nil)
  if valid_602938 != nil:
    section.add "X-Amz-SignedHeaders", valid_602938
  var valid_602939 = header.getOrDefault("X-Amz-Credential")
  valid_602939 = validateParameter(valid_602939, JString, required = false,
                                 default = nil)
  if valid_602939 != nil:
    section.add "X-Amz-Credential", valid_602939
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602963: Call_CreateBotVersion_602804; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new version of the bot based on the <code>$LATEST</code> version. If the <code>$LATEST</code> version of this resource hasn't changed since you created the last version, Amazon Lex doesn't create a new version. It returns the last created version.</p> <note> <p>You can update only the <code>$LATEST</code> version of the bot. You can't update the numbered versions that you create with the <code>CreateBotVersion</code> operation.</p> </note> <p> When you create the first version of a bot, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p> This operation requires permission for the <code>lex:CreateBotVersion</code> action. </p>
  ## 
  let valid = call_602963.validator(path, query, header, formData, body)
  let scheme = call_602963.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602963.url(scheme.get, call_602963.host, call_602963.base,
                         call_602963.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602963, url, valid)

proc call*(call_603034: Call_CreateBotVersion_602804; name: string; body: JsonNode): Recallable =
  ## createBotVersion
  ## <p>Creates a new version of the bot based on the <code>$LATEST</code> version. If the <code>$LATEST</code> version of this resource hasn't changed since you created the last version, Amazon Lex doesn't create a new version. It returns the last created version.</p> <note> <p>You can update only the <code>$LATEST</code> version of the bot. You can't update the numbered versions that you create with the <code>CreateBotVersion</code> operation.</p> </note> <p> When you create the first version of a bot, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p> This operation requires permission for the <code>lex:CreateBotVersion</code> action. </p>
  ##   name: string (required)
  ##       : The name of the bot that you want to create a new version of. The name is case sensitive. 
  ##   body: JObject (required)
  var path_603035 = newJObject()
  var body_603037 = newJObject()
  add(path_603035, "name", newJString(name))
  if body != nil:
    body_603037 = body
  result = call_603034.call(path_603035, nil, nil, nil, body_603037)

var createBotVersion* = Call_CreateBotVersion_602804(name: "createBotVersion",
    meth: HttpMethod.HttpPost, host: "models.lex.amazonaws.com",
    route: "/bots/{name}/versions", validator: validate_CreateBotVersion_602805,
    base: "/", url: url_CreateBotVersion_602806,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIntentVersion_603076 = ref object of OpenApiRestCall_602467
proc url_CreateIntentVersion_603078(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/intents/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateIntentVersion_603077(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Creates a new version of an intent based on the <code>$LATEST</code> version of the intent. If the <code>$LATEST</code> version of this intent hasn't changed since you last updated it, Amazon Lex doesn't create a new version. It returns the last version you created.</p> <note> <p>You can update only the <code>$LATEST</code> version of the intent. You can't update the numbered versions that you create with the <code>CreateIntentVersion</code> operation.</p> </note> <p> When you create a version of an intent, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p>This operation requires permissions to perform the <code>lex:CreateIntentVersion</code> action. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the intent that you want to create a new version of. The name is case sensitive. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_603079 = path.getOrDefault("name")
  valid_603079 = validateParameter(valid_603079, JString, required = true,
                                 default = nil)
  if valid_603079 != nil:
    section.add "name", valid_603079
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603080 = header.getOrDefault("X-Amz-Date")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Date", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-Security-Token")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Security-Token", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Content-Sha256", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-Algorithm")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Algorithm", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-Signature")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Signature", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-SignedHeaders", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-Credential")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-Credential", valid_603086
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603088: Call_CreateIntentVersion_603076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new version of an intent based on the <code>$LATEST</code> version of the intent. If the <code>$LATEST</code> version of this intent hasn't changed since you last updated it, Amazon Lex doesn't create a new version. It returns the last version you created.</p> <note> <p>You can update only the <code>$LATEST</code> version of the intent. You can't update the numbered versions that you create with the <code>CreateIntentVersion</code> operation.</p> </note> <p> When you create a version of an intent, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p>This operation requires permissions to perform the <code>lex:CreateIntentVersion</code> action. </p>
  ## 
  let valid = call_603088.validator(path, query, header, formData, body)
  let scheme = call_603088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603088.url(scheme.get, call_603088.host, call_603088.base,
                         call_603088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603088, url, valid)

proc call*(call_603089: Call_CreateIntentVersion_603076; name: string; body: JsonNode): Recallable =
  ## createIntentVersion
  ## <p>Creates a new version of an intent based on the <code>$LATEST</code> version of the intent. If the <code>$LATEST</code> version of this intent hasn't changed since you last updated it, Amazon Lex doesn't create a new version. It returns the last version you created.</p> <note> <p>You can update only the <code>$LATEST</code> version of the intent. You can't update the numbered versions that you create with the <code>CreateIntentVersion</code> operation.</p> </note> <p> When you create a version of an intent, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p>This operation requires permissions to perform the <code>lex:CreateIntentVersion</code> action. </p>
  ##   name: string (required)
  ##       : The name of the intent that you want to create a new version of. The name is case sensitive. 
  ##   body: JObject (required)
  var path_603090 = newJObject()
  var body_603091 = newJObject()
  add(path_603090, "name", newJString(name))
  if body != nil:
    body_603091 = body
  result = call_603089.call(path_603090, nil, nil, nil, body_603091)

var createIntentVersion* = Call_CreateIntentVersion_603076(
    name: "createIntentVersion", meth: HttpMethod.HttpPost,
    host: "models.lex.amazonaws.com", route: "/intents/{name}/versions",
    validator: validate_CreateIntentVersion_603077, base: "/",
    url: url_CreateIntentVersion_603078, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSlotTypeVersion_603092 = ref object of OpenApiRestCall_602467
proc url_CreateSlotTypeVersion_603094(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/slottypes/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_CreateSlotTypeVersion_603093(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new version of a slot type based on the <code>$LATEST</code> version of the specified slot type. If the <code>$LATEST</code> version of this resource has not changed since the last version that you created, Amazon Lex doesn't create a new version. It returns the last version that you created. </p> <note> <p>You can update only the <code>$LATEST</code> version of a slot type. You can't update the numbered versions that you create with the <code>CreateSlotTypeVersion</code> operation.</p> </note> <p>When you create a version of a slot type, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p>This operation requires permissions for the <code>lex:CreateSlotTypeVersion</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the slot type that you want to create a new version for. The name is case sensitive. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_603095 = path.getOrDefault("name")
  valid_603095 = validateParameter(valid_603095, JString, required = true,
                                 default = nil)
  if valid_603095 != nil:
    section.add "name", valid_603095
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603096 = header.getOrDefault("X-Amz-Date")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-Date", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Security-Token")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Security-Token", valid_603097
  var valid_603098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-Content-Sha256", valid_603098
  var valid_603099 = header.getOrDefault("X-Amz-Algorithm")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-Algorithm", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-Signature")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Signature", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-SignedHeaders", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-Credential")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Credential", valid_603102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603104: Call_CreateSlotTypeVersion_603092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new version of a slot type based on the <code>$LATEST</code> version of the specified slot type. If the <code>$LATEST</code> version of this resource has not changed since the last version that you created, Amazon Lex doesn't create a new version. It returns the last version that you created. </p> <note> <p>You can update only the <code>$LATEST</code> version of a slot type. You can't update the numbered versions that you create with the <code>CreateSlotTypeVersion</code> operation.</p> </note> <p>When you create a version of a slot type, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p>This operation requires permissions for the <code>lex:CreateSlotTypeVersion</code> action.</p>
  ## 
  let valid = call_603104.validator(path, query, header, formData, body)
  let scheme = call_603104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603104.url(scheme.get, call_603104.host, call_603104.base,
                         call_603104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603104, url, valid)

proc call*(call_603105: Call_CreateSlotTypeVersion_603092; name: string;
          body: JsonNode): Recallable =
  ## createSlotTypeVersion
  ## <p>Creates a new version of a slot type based on the <code>$LATEST</code> version of the specified slot type. If the <code>$LATEST</code> version of this resource has not changed since the last version that you created, Amazon Lex doesn't create a new version. It returns the last version that you created. </p> <note> <p>You can update only the <code>$LATEST</code> version of a slot type. You can't update the numbered versions that you create with the <code>CreateSlotTypeVersion</code> operation.</p> </note> <p>When you create a version of a slot type, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p>This operation requires permissions for the <code>lex:CreateSlotTypeVersion</code> action.</p>
  ##   name: string (required)
  ##       : The name of the slot type that you want to create a new version for. The name is case sensitive. 
  ##   body: JObject (required)
  var path_603106 = newJObject()
  var body_603107 = newJObject()
  add(path_603106, "name", newJString(name))
  if body != nil:
    body_603107 = body
  result = call_603105.call(path_603106, nil, nil, nil, body_603107)

var createSlotTypeVersion* = Call_CreateSlotTypeVersion_603092(
    name: "createSlotTypeVersion", meth: HttpMethod.HttpPost,
    host: "models.lex.amazonaws.com", route: "/slottypes/{name}/versions",
    validator: validate_CreateSlotTypeVersion_603093, base: "/",
    url: url_CreateSlotTypeVersion_603094, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBot_603108 = ref object of OpenApiRestCall_602467
proc url_DeleteBot_603110(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/bots/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteBot_603109(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes all versions of the bot, including the <code>$LATEST</code> version. To delete a specific version of the bot, use the <a>DeleteBotVersion</a> operation.</p> <p>If a bot has an alias, you can't delete it. Instead, the <code>DeleteBot</code> operation returns a <code>ResourceInUseException</code> exception that includes a reference to the alias that refers to the bot. To remove the reference to the bot, delete the alias. If you get the same exception again, delete the referring alias until the <code>DeleteBot</code> operation is successful.</p> <p>This operation requires permissions for the <code>lex:DeleteBot</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the bot. The name is case sensitive. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_603111 = path.getOrDefault("name")
  valid_603111 = validateParameter(valid_603111, JString, required = true,
                                 default = nil)
  if valid_603111 != nil:
    section.add "name", valid_603111
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603112 = header.getOrDefault("X-Amz-Date")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Date", valid_603112
  var valid_603113 = header.getOrDefault("X-Amz-Security-Token")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "X-Amz-Security-Token", valid_603113
  var valid_603114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "X-Amz-Content-Sha256", valid_603114
  var valid_603115 = header.getOrDefault("X-Amz-Algorithm")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "X-Amz-Algorithm", valid_603115
  var valid_603116 = header.getOrDefault("X-Amz-Signature")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-Signature", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-SignedHeaders", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-Credential")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-Credential", valid_603118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603119: Call_DeleteBot_603108; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes all versions of the bot, including the <code>$LATEST</code> version. To delete a specific version of the bot, use the <a>DeleteBotVersion</a> operation.</p> <p>If a bot has an alias, you can't delete it. Instead, the <code>DeleteBot</code> operation returns a <code>ResourceInUseException</code> exception that includes a reference to the alias that refers to the bot. To remove the reference to the bot, delete the alias. If you get the same exception again, delete the referring alias until the <code>DeleteBot</code> operation is successful.</p> <p>This operation requires permissions for the <code>lex:DeleteBot</code> action.</p>
  ## 
  let valid = call_603119.validator(path, query, header, formData, body)
  let scheme = call_603119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603119.url(scheme.get, call_603119.host, call_603119.base,
                         call_603119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603119, url, valid)

proc call*(call_603120: Call_DeleteBot_603108; name: string): Recallable =
  ## deleteBot
  ## <p>Deletes all versions of the bot, including the <code>$LATEST</code> version. To delete a specific version of the bot, use the <a>DeleteBotVersion</a> operation.</p> <p>If a bot has an alias, you can't delete it. Instead, the <code>DeleteBot</code> operation returns a <code>ResourceInUseException</code> exception that includes a reference to the alias that refers to the bot. To remove the reference to the bot, delete the alias. If you get the same exception again, delete the referring alias until the <code>DeleteBot</code> operation is successful.</p> <p>This operation requires permissions for the <code>lex:DeleteBot</code> action.</p>
  ##   name: string (required)
  ##       : The name of the bot. The name is case sensitive. 
  var path_603121 = newJObject()
  add(path_603121, "name", newJString(name))
  result = call_603120.call(path_603121, nil, nil, nil, nil)

var deleteBot* = Call_DeleteBot_603108(name: "deleteBot",
                                    meth: HttpMethod.HttpDelete,
                                    host: "models.lex.amazonaws.com",
                                    route: "/bots/{name}",
                                    validator: validate_DeleteBot_603109,
                                    base: "/", url: url_DeleteBot_603110,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBotAlias_603137 = ref object of OpenApiRestCall_602467
proc url_PutBotAlias_603139(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "botName" in path, "`botName` is a required path parameter"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/bots/"),
               (kind: VariableSegment, value: "botName"),
               (kind: ConstantSegment, value: "/aliases/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutBotAlias_603138(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an alias for the specified version of the bot or replaces an alias for the specified bot. To change the version of the bot that the alias points to, replace the alias. For more information about aliases, see <a>versioning-aliases</a>.</p> <p>This operation requires permissions for the <code>lex:PutBotAlias</code> action. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the alias. The name is <i>not</i> case sensitive.
  ##   botName: JString (required)
  ##          : The name of the bot.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_603140 = path.getOrDefault("name")
  valid_603140 = validateParameter(valid_603140, JString, required = true,
                                 default = nil)
  if valid_603140 != nil:
    section.add "name", valid_603140
  var valid_603141 = path.getOrDefault("botName")
  valid_603141 = validateParameter(valid_603141, JString, required = true,
                                 default = nil)
  if valid_603141 != nil:
    section.add "botName", valid_603141
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603142 = header.getOrDefault("X-Amz-Date")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Date", valid_603142
  var valid_603143 = header.getOrDefault("X-Amz-Security-Token")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "X-Amz-Security-Token", valid_603143
  var valid_603144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "X-Amz-Content-Sha256", valid_603144
  var valid_603145 = header.getOrDefault("X-Amz-Algorithm")
  valid_603145 = validateParameter(valid_603145, JString, required = false,
                                 default = nil)
  if valid_603145 != nil:
    section.add "X-Amz-Algorithm", valid_603145
  var valid_603146 = header.getOrDefault("X-Amz-Signature")
  valid_603146 = validateParameter(valid_603146, JString, required = false,
                                 default = nil)
  if valid_603146 != nil:
    section.add "X-Amz-Signature", valid_603146
  var valid_603147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "X-Amz-SignedHeaders", valid_603147
  var valid_603148 = header.getOrDefault("X-Amz-Credential")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-Credential", valid_603148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603150: Call_PutBotAlias_603137; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an alias for the specified version of the bot or replaces an alias for the specified bot. To change the version of the bot that the alias points to, replace the alias. For more information about aliases, see <a>versioning-aliases</a>.</p> <p>This operation requires permissions for the <code>lex:PutBotAlias</code> action. </p>
  ## 
  let valid = call_603150.validator(path, query, header, formData, body)
  let scheme = call_603150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603150.url(scheme.get, call_603150.host, call_603150.base,
                         call_603150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603150, url, valid)

proc call*(call_603151: Call_PutBotAlias_603137; name: string; botName: string;
          body: JsonNode): Recallable =
  ## putBotAlias
  ## <p>Creates an alias for the specified version of the bot or replaces an alias for the specified bot. To change the version of the bot that the alias points to, replace the alias. For more information about aliases, see <a>versioning-aliases</a>.</p> <p>This operation requires permissions for the <code>lex:PutBotAlias</code> action. </p>
  ##   name: string (required)
  ##       : The name of the alias. The name is <i>not</i> case sensitive.
  ##   botName: string (required)
  ##          : The name of the bot.
  ##   body: JObject (required)
  var path_603152 = newJObject()
  var body_603153 = newJObject()
  add(path_603152, "name", newJString(name))
  add(path_603152, "botName", newJString(botName))
  if body != nil:
    body_603153 = body
  result = call_603151.call(path_603152, nil, nil, nil, body_603153)

var putBotAlias* = Call_PutBotAlias_603137(name: "putBotAlias",
                                        meth: HttpMethod.HttpPut,
                                        host: "models.lex.amazonaws.com", route: "/bots/{botName}/aliases/{name}",
                                        validator: validate_PutBotAlias_603138,
                                        base: "/", url: url_PutBotAlias_603139,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBotAlias_603122 = ref object of OpenApiRestCall_602467
proc url_GetBotAlias_603124(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "botName" in path, "`botName` is a required path parameter"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/bots/"),
               (kind: VariableSegment, value: "botName"),
               (kind: ConstantSegment, value: "/aliases/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBotAlias_603123(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about an Amazon Lex bot alias. For more information about aliases, see <a>versioning-aliases</a>.</p> <p>This operation requires permissions for the <code>lex:GetBotAlias</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the bot alias. The name is case sensitive.
  ##   botName: JString (required)
  ##          : The name of the bot.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_603125 = path.getOrDefault("name")
  valid_603125 = validateParameter(valid_603125, JString, required = true,
                                 default = nil)
  if valid_603125 != nil:
    section.add "name", valid_603125
  var valid_603126 = path.getOrDefault("botName")
  valid_603126 = validateParameter(valid_603126, JString, required = true,
                                 default = nil)
  if valid_603126 != nil:
    section.add "botName", valid_603126
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603127 = header.getOrDefault("X-Amz-Date")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Date", valid_603127
  var valid_603128 = header.getOrDefault("X-Amz-Security-Token")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "X-Amz-Security-Token", valid_603128
  var valid_603129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603129 = validateParameter(valid_603129, JString, required = false,
                                 default = nil)
  if valid_603129 != nil:
    section.add "X-Amz-Content-Sha256", valid_603129
  var valid_603130 = header.getOrDefault("X-Amz-Algorithm")
  valid_603130 = validateParameter(valid_603130, JString, required = false,
                                 default = nil)
  if valid_603130 != nil:
    section.add "X-Amz-Algorithm", valid_603130
  var valid_603131 = header.getOrDefault("X-Amz-Signature")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "X-Amz-Signature", valid_603131
  var valid_603132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-SignedHeaders", valid_603132
  var valid_603133 = header.getOrDefault("X-Amz-Credential")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Credential", valid_603133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603134: Call_GetBotAlias_603122; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about an Amazon Lex bot alias. For more information about aliases, see <a>versioning-aliases</a>.</p> <p>This operation requires permissions for the <code>lex:GetBotAlias</code> action.</p>
  ## 
  let valid = call_603134.validator(path, query, header, formData, body)
  let scheme = call_603134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603134.url(scheme.get, call_603134.host, call_603134.base,
                         call_603134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603134, url, valid)

proc call*(call_603135: Call_GetBotAlias_603122; name: string; botName: string): Recallable =
  ## getBotAlias
  ## <p>Returns information about an Amazon Lex bot alias. For more information about aliases, see <a>versioning-aliases</a>.</p> <p>This operation requires permissions for the <code>lex:GetBotAlias</code> action.</p>
  ##   name: string (required)
  ##       : The name of the bot alias. The name is case sensitive.
  ##   botName: string (required)
  ##          : The name of the bot.
  var path_603136 = newJObject()
  add(path_603136, "name", newJString(name))
  add(path_603136, "botName", newJString(botName))
  result = call_603135.call(path_603136, nil, nil, nil, nil)

var getBotAlias* = Call_GetBotAlias_603122(name: "getBotAlias",
                                        meth: HttpMethod.HttpGet,
                                        host: "models.lex.amazonaws.com", route: "/bots/{botName}/aliases/{name}",
                                        validator: validate_GetBotAlias_603123,
                                        base: "/", url: url_GetBotAlias_603124,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBotAlias_603154 = ref object of OpenApiRestCall_602467
proc url_DeleteBotAlias_603156(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "botName" in path, "`botName` is a required path parameter"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/bots/"),
               (kind: VariableSegment, value: "botName"),
               (kind: ConstantSegment, value: "/aliases/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteBotAlias_603155(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Deletes an alias for the specified bot. </p> <p>You can't delete an alias that is used in the association between a bot and a messaging channel. If an alias is used in a channel association, the <code>DeleteBot</code> operation returns a <code>ResourceInUseException</code> exception that includes a reference to the channel association that refers to the bot. You can remove the reference to the alias by deleting the channel association. If you get the same exception again, delete the referring association until the <code>DeleteBotAlias</code> operation is successful.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the alias to delete. The name is case sensitive. 
  ##   botName: JString (required)
  ##          : The name of the bot that the alias points to.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_603157 = path.getOrDefault("name")
  valid_603157 = validateParameter(valid_603157, JString, required = true,
                                 default = nil)
  if valid_603157 != nil:
    section.add "name", valid_603157
  var valid_603158 = path.getOrDefault("botName")
  valid_603158 = validateParameter(valid_603158, JString, required = true,
                                 default = nil)
  if valid_603158 != nil:
    section.add "botName", valid_603158
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603159 = header.getOrDefault("X-Amz-Date")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "X-Amz-Date", valid_603159
  var valid_603160 = header.getOrDefault("X-Amz-Security-Token")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "X-Amz-Security-Token", valid_603160
  var valid_603161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "X-Amz-Content-Sha256", valid_603161
  var valid_603162 = header.getOrDefault("X-Amz-Algorithm")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "X-Amz-Algorithm", valid_603162
  var valid_603163 = header.getOrDefault("X-Amz-Signature")
  valid_603163 = validateParameter(valid_603163, JString, required = false,
                                 default = nil)
  if valid_603163 != nil:
    section.add "X-Amz-Signature", valid_603163
  var valid_603164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "X-Amz-SignedHeaders", valid_603164
  var valid_603165 = header.getOrDefault("X-Amz-Credential")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Credential", valid_603165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603166: Call_DeleteBotAlias_603154; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an alias for the specified bot. </p> <p>You can't delete an alias that is used in the association between a bot and a messaging channel. If an alias is used in a channel association, the <code>DeleteBot</code> operation returns a <code>ResourceInUseException</code> exception that includes a reference to the channel association that refers to the bot. You can remove the reference to the alias by deleting the channel association. If you get the same exception again, delete the referring association until the <code>DeleteBotAlias</code> operation is successful.</p>
  ## 
  let valid = call_603166.validator(path, query, header, formData, body)
  let scheme = call_603166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603166.url(scheme.get, call_603166.host, call_603166.base,
                         call_603166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603166, url, valid)

proc call*(call_603167: Call_DeleteBotAlias_603154; name: string; botName: string): Recallable =
  ## deleteBotAlias
  ## <p>Deletes an alias for the specified bot. </p> <p>You can't delete an alias that is used in the association between a bot and a messaging channel. If an alias is used in a channel association, the <code>DeleteBot</code> operation returns a <code>ResourceInUseException</code> exception that includes a reference to the channel association that refers to the bot. You can remove the reference to the alias by deleting the channel association. If you get the same exception again, delete the referring association until the <code>DeleteBotAlias</code> operation is successful.</p>
  ##   name: string (required)
  ##       : The name of the alias to delete. The name is case sensitive. 
  ##   botName: string (required)
  ##          : The name of the bot that the alias points to.
  var path_603168 = newJObject()
  add(path_603168, "name", newJString(name))
  add(path_603168, "botName", newJString(botName))
  result = call_603167.call(path_603168, nil, nil, nil, nil)

var deleteBotAlias* = Call_DeleteBotAlias_603154(name: "deleteBotAlias",
    meth: HttpMethod.HttpDelete, host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/aliases/{name}", validator: validate_DeleteBotAlias_603155,
    base: "/", url: url_DeleteBotAlias_603156, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBotChannelAssociation_603169 = ref object of OpenApiRestCall_602467
proc url_GetBotChannelAssociation_603171(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "botName" in path, "`botName` is a required path parameter"
  assert "aliasName" in path, "`aliasName` is a required path parameter"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/bots/"),
               (kind: VariableSegment, value: "botName"),
               (kind: ConstantSegment, value: "/aliases/"),
               (kind: VariableSegment, value: "aliasName"),
               (kind: ConstantSegment, value: "/channels/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBotChannelAssociation_603170(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about the association between an Amazon Lex bot and a messaging platform.</p> <p>This operation requires permissions for the <code>lex:GetBotChannelAssociation</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the association between the bot and the channel. The name is case sensitive. 
  ##   botName: JString (required)
  ##          : The name of the Amazon Lex bot.
  ##   aliasName: JString (required)
  ##            : An alias pointing to the specific version of the Amazon Lex bot to which this association is being made.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_603172 = path.getOrDefault("name")
  valid_603172 = validateParameter(valid_603172, JString, required = true,
                                 default = nil)
  if valid_603172 != nil:
    section.add "name", valid_603172
  var valid_603173 = path.getOrDefault("botName")
  valid_603173 = validateParameter(valid_603173, JString, required = true,
                                 default = nil)
  if valid_603173 != nil:
    section.add "botName", valid_603173
  var valid_603174 = path.getOrDefault("aliasName")
  valid_603174 = validateParameter(valid_603174, JString, required = true,
                                 default = nil)
  if valid_603174 != nil:
    section.add "aliasName", valid_603174
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603175 = header.getOrDefault("X-Amz-Date")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-Date", valid_603175
  var valid_603176 = header.getOrDefault("X-Amz-Security-Token")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-Security-Token", valid_603176
  var valid_603177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-Content-Sha256", valid_603177
  var valid_603178 = header.getOrDefault("X-Amz-Algorithm")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "X-Amz-Algorithm", valid_603178
  var valid_603179 = header.getOrDefault("X-Amz-Signature")
  valid_603179 = validateParameter(valid_603179, JString, required = false,
                                 default = nil)
  if valid_603179 != nil:
    section.add "X-Amz-Signature", valid_603179
  var valid_603180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-SignedHeaders", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Credential")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Credential", valid_603181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603182: Call_GetBotChannelAssociation_603169; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the association between an Amazon Lex bot and a messaging platform.</p> <p>This operation requires permissions for the <code>lex:GetBotChannelAssociation</code> action.</p>
  ## 
  let valid = call_603182.validator(path, query, header, formData, body)
  let scheme = call_603182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603182.url(scheme.get, call_603182.host, call_603182.base,
                         call_603182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603182, url, valid)

proc call*(call_603183: Call_GetBotChannelAssociation_603169; name: string;
          botName: string; aliasName: string): Recallable =
  ## getBotChannelAssociation
  ## <p>Returns information about the association between an Amazon Lex bot and a messaging platform.</p> <p>This operation requires permissions for the <code>lex:GetBotChannelAssociation</code> action.</p>
  ##   name: string (required)
  ##       : The name of the association between the bot and the channel. The name is case sensitive. 
  ##   botName: string (required)
  ##          : The name of the Amazon Lex bot.
  ##   aliasName: string (required)
  ##            : An alias pointing to the specific version of the Amazon Lex bot to which this association is being made.
  var path_603184 = newJObject()
  add(path_603184, "name", newJString(name))
  add(path_603184, "botName", newJString(botName))
  add(path_603184, "aliasName", newJString(aliasName))
  result = call_603183.call(path_603184, nil, nil, nil, nil)

var getBotChannelAssociation* = Call_GetBotChannelAssociation_603169(
    name: "getBotChannelAssociation", meth: HttpMethod.HttpGet,
    host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/aliases/{aliasName}/channels/{name}",
    validator: validate_GetBotChannelAssociation_603170, base: "/",
    url: url_GetBotChannelAssociation_603171, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBotChannelAssociation_603185 = ref object of OpenApiRestCall_602467
proc url_DeleteBotChannelAssociation_603187(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "botName" in path, "`botName` is a required path parameter"
  assert "aliasName" in path, "`aliasName` is a required path parameter"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/bots/"),
               (kind: VariableSegment, value: "botName"),
               (kind: ConstantSegment, value: "/aliases/"),
               (kind: VariableSegment, value: "aliasName"),
               (kind: ConstantSegment, value: "/channels/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteBotChannelAssociation_603186(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the association between an Amazon Lex bot and a messaging platform.</p> <p>This operation requires permission for the <code>lex:DeleteBotChannelAssociation</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the association. The name is case sensitive. 
  ##   botName: JString (required)
  ##          : The name of the Amazon Lex bot.
  ##   aliasName: JString (required)
  ##            : An alias that points to the specific version of the Amazon Lex bot to which this association is being made.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_603188 = path.getOrDefault("name")
  valid_603188 = validateParameter(valid_603188, JString, required = true,
                                 default = nil)
  if valid_603188 != nil:
    section.add "name", valid_603188
  var valid_603189 = path.getOrDefault("botName")
  valid_603189 = validateParameter(valid_603189, JString, required = true,
                                 default = nil)
  if valid_603189 != nil:
    section.add "botName", valid_603189
  var valid_603190 = path.getOrDefault("aliasName")
  valid_603190 = validateParameter(valid_603190, JString, required = true,
                                 default = nil)
  if valid_603190 != nil:
    section.add "aliasName", valid_603190
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603191 = header.getOrDefault("X-Amz-Date")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-Date", valid_603191
  var valid_603192 = header.getOrDefault("X-Amz-Security-Token")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-Security-Token", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-Content-Sha256", valid_603193
  var valid_603194 = header.getOrDefault("X-Amz-Algorithm")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "X-Amz-Algorithm", valid_603194
  var valid_603195 = header.getOrDefault("X-Amz-Signature")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Signature", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-SignedHeaders", valid_603196
  var valid_603197 = header.getOrDefault("X-Amz-Credential")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-Credential", valid_603197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603198: Call_DeleteBotChannelAssociation_603185; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the association between an Amazon Lex bot and a messaging platform.</p> <p>This operation requires permission for the <code>lex:DeleteBotChannelAssociation</code> action.</p>
  ## 
  let valid = call_603198.validator(path, query, header, formData, body)
  let scheme = call_603198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603198.url(scheme.get, call_603198.host, call_603198.base,
                         call_603198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603198, url, valid)

proc call*(call_603199: Call_DeleteBotChannelAssociation_603185; name: string;
          botName: string; aliasName: string): Recallable =
  ## deleteBotChannelAssociation
  ## <p>Deletes the association between an Amazon Lex bot and a messaging platform.</p> <p>This operation requires permission for the <code>lex:DeleteBotChannelAssociation</code> action.</p>
  ##   name: string (required)
  ##       : The name of the association. The name is case sensitive. 
  ##   botName: string (required)
  ##          : The name of the Amazon Lex bot.
  ##   aliasName: string (required)
  ##            : An alias that points to the specific version of the Amazon Lex bot to which this association is being made.
  var path_603200 = newJObject()
  add(path_603200, "name", newJString(name))
  add(path_603200, "botName", newJString(botName))
  add(path_603200, "aliasName", newJString(aliasName))
  result = call_603199.call(path_603200, nil, nil, nil, nil)

var deleteBotChannelAssociation* = Call_DeleteBotChannelAssociation_603185(
    name: "deleteBotChannelAssociation", meth: HttpMethod.HttpDelete,
    host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/aliases/{aliasName}/channels/{name}",
    validator: validate_DeleteBotChannelAssociation_603186, base: "/",
    url: url_DeleteBotChannelAssociation_603187,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBotVersion_603201 = ref object of OpenApiRestCall_602467
proc url_DeleteBotVersion_603203(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  assert "version" in path, "`version` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/bots/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "version")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteBotVersion_603202(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes a specific version of a bot. To delete all versions of a bot, use the <a>DeleteBot</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteBotVersion</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the bot.
  ##   version: JString (required)
  ##          : The version of the bot to delete. You cannot delete the <code>$LATEST</code> version of the bot. To delete the <code>$LATEST</code> version, use the <a>DeleteBot</a> operation.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_603204 = path.getOrDefault("name")
  valid_603204 = validateParameter(valid_603204, JString, required = true,
                                 default = nil)
  if valid_603204 != nil:
    section.add "name", valid_603204
  var valid_603205 = path.getOrDefault("version")
  valid_603205 = validateParameter(valid_603205, JString, required = true,
                                 default = nil)
  if valid_603205 != nil:
    section.add "version", valid_603205
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603206 = header.getOrDefault("X-Amz-Date")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Date", valid_603206
  var valid_603207 = header.getOrDefault("X-Amz-Security-Token")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-Security-Token", valid_603207
  var valid_603208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-Content-Sha256", valid_603208
  var valid_603209 = header.getOrDefault("X-Amz-Algorithm")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "X-Amz-Algorithm", valid_603209
  var valid_603210 = header.getOrDefault("X-Amz-Signature")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Signature", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-SignedHeaders", valid_603211
  var valid_603212 = header.getOrDefault("X-Amz-Credential")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "X-Amz-Credential", valid_603212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603213: Call_DeleteBotVersion_603201; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a specific version of a bot. To delete all versions of a bot, use the <a>DeleteBot</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteBotVersion</code> action.</p>
  ## 
  let valid = call_603213.validator(path, query, header, formData, body)
  let scheme = call_603213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603213.url(scheme.get, call_603213.host, call_603213.base,
                         call_603213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603213, url, valid)

proc call*(call_603214: Call_DeleteBotVersion_603201; name: string; version: string): Recallable =
  ## deleteBotVersion
  ## <p>Deletes a specific version of a bot. To delete all versions of a bot, use the <a>DeleteBot</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteBotVersion</code> action.</p>
  ##   name: string (required)
  ##       : The name of the bot.
  ##   version: string (required)
  ##          : The version of the bot to delete. You cannot delete the <code>$LATEST</code> version of the bot. To delete the <code>$LATEST</code> version, use the <a>DeleteBot</a> operation.
  var path_603215 = newJObject()
  add(path_603215, "name", newJString(name))
  add(path_603215, "version", newJString(version))
  result = call_603214.call(path_603215, nil, nil, nil, nil)

var deleteBotVersion* = Call_DeleteBotVersion_603201(name: "deleteBotVersion",
    meth: HttpMethod.HttpDelete, host: "models.lex.amazonaws.com",
    route: "/bots/{name}/versions/{version}",
    validator: validate_DeleteBotVersion_603202, base: "/",
    url: url_DeleteBotVersion_603203, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntent_603216 = ref object of OpenApiRestCall_602467
proc url_DeleteIntent_603218(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/intents/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteIntent_603217(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes all versions of the intent, including the <code>$LATEST</code> version. To delete a specific version of the intent, use the <a>DeleteIntentVersion</a> operation.</p> <p> You can delete a version of an intent only if it is not referenced. To delete an intent that is referred to in one or more bots (see <a>how-it-works</a>), you must remove those references first. </p> <note> <p> If you get the <code>ResourceInUseException</code> exception, it provides an example reference that shows where the intent is referenced. To remove the reference to the intent, either update the bot or delete it. If you get the same exception when you attempt to delete the intent again, repeat until the intent has no references and the call to <code>DeleteIntent</code> is successful. </p> </note> <p> This operation requires permission for the <code>lex:DeleteIntent</code> action. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the intent. The name is case sensitive. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_603219 = path.getOrDefault("name")
  valid_603219 = validateParameter(valid_603219, JString, required = true,
                                 default = nil)
  if valid_603219 != nil:
    section.add "name", valid_603219
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603220 = header.getOrDefault("X-Amz-Date")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Date", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-Security-Token")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-Security-Token", valid_603221
  var valid_603222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-Content-Sha256", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-Algorithm")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-Algorithm", valid_603223
  var valid_603224 = header.getOrDefault("X-Amz-Signature")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "X-Amz-Signature", valid_603224
  var valid_603225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-SignedHeaders", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Credential")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Credential", valid_603226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603227: Call_DeleteIntent_603216; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes all versions of the intent, including the <code>$LATEST</code> version. To delete a specific version of the intent, use the <a>DeleteIntentVersion</a> operation.</p> <p> You can delete a version of an intent only if it is not referenced. To delete an intent that is referred to in one or more bots (see <a>how-it-works</a>), you must remove those references first. </p> <note> <p> If you get the <code>ResourceInUseException</code> exception, it provides an example reference that shows where the intent is referenced. To remove the reference to the intent, either update the bot or delete it. If you get the same exception when you attempt to delete the intent again, repeat until the intent has no references and the call to <code>DeleteIntent</code> is successful. </p> </note> <p> This operation requires permission for the <code>lex:DeleteIntent</code> action. </p>
  ## 
  let valid = call_603227.validator(path, query, header, formData, body)
  let scheme = call_603227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603227.url(scheme.get, call_603227.host, call_603227.base,
                         call_603227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603227, url, valid)

proc call*(call_603228: Call_DeleteIntent_603216; name: string): Recallable =
  ## deleteIntent
  ## <p>Deletes all versions of the intent, including the <code>$LATEST</code> version. To delete a specific version of the intent, use the <a>DeleteIntentVersion</a> operation.</p> <p> You can delete a version of an intent only if it is not referenced. To delete an intent that is referred to in one or more bots (see <a>how-it-works</a>), you must remove those references first. </p> <note> <p> If you get the <code>ResourceInUseException</code> exception, it provides an example reference that shows where the intent is referenced. To remove the reference to the intent, either update the bot or delete it. If you get the same exception when you attempt to delete the intent again, repeat until the intent has no references and the call to <code>DeleteIntent</code> is successful. </p> </note> <p> This operation requires permission for the <code>lex:DeleteIntent</code> action. </p>
  ##   name: string (required)
  ##       : The name of the intent. The name is case sensitive. 
  var path_603229 = newJObject()
  add(path_603229, "name", newJString(name))
  result = call_603228.call(path_603229, nil, nil, nil, nil)

var deleteIntent* = Call_DeleteIntent_603216(name: "deleteIntent",
    meth: HttpMethod.HttpDelete, host: "models.lex.amazonaws.com",
    route: "/intents/{name}", validator: validate_DeleteIntent_603217, base: "/",
    url: url_DeleteIntent_603218, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntent_603230 = ref object of OpenApiRestCall_602467
proc url_GetIntent_603232(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  assert "version" in path, "`version` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/intents/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "version")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetIntent_603231(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Returns information about an intent. In addition to the intent name, you must specify the intent version. </p> <p> This operation requires permissions to perform the <code>lex:GetIntent</code> action. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the intent. The name is case sensitive. 
  ##   version: JString (required)
  ##          : The version of the intent.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_603233 = path.getOrDefault("name")
  valid_603233 = validateParameter(valid_603233, JString, required = true,
                                 default = nil)
  if valid_603233 != nil:
    section.add "name", valid_603233
  var valid_603234 = path.getOrDefault("version")
  valid_603234 = validateParameter(valid_603234, JString, required = true,
                                 default = nil)
  if valid_603234 != nil:
    section.add "version", valid_603234
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603235 = header.getOrDefault("X-Amz-Date")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-Date", valid_603235
  var valid_603236 = header.getOrDefault("X-Amz-Security-Token")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-Security-Token", valid_603236
  var valid_603237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-Content-Sha256", valid_603237
  var valid_603238 = header.getOrDefault("X-Amz-Algorithm")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "X-Amz-Algorithm", valid_603238
  var valid_603239 = header.getOrDefault("X-Amz-Signature")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-Signature", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-SignedHeaders", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Credential")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Credential", valid_603241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603242: Call_GetIntent_603230; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns information about an intent. In addition to the intent name, you must specify the intent version. </p> <p> This operation requires permissions to perform the <code>lex:GetIntent</code> action. </p>
  ## 
  let valid = call_603242.validator(path, query, header, formData, body)
  let scheme = call_603242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603242.url(scheme.get, call_603242.host, call_603242.base,
                         call_603242.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603242, url, valid)

proc call*(call_603243: Call_GetIntent_603230; name: string; version: string): Recallable =
  ## getIntent
  ## <p> Returns information about an intent. In addition to the intent name, you must specify the intent version. </p> <p> This operation requires permissions to perform the <code>lex:GetIntent</code> action. </p>
  ##   name: string (required)
  ##       : The name of the intent. The name is case sensitive. 
  ##   version: string (required)
  ##          : The version of the intent.
  var path_603244 = newJObject()
  add(path_603244, "name", newJString(name))
  add(path_603244, "version", newJString(version))
  result = call_603243.call(path_603244, nil, nil, nil, nil)

var getIntent* = Call_GetIntent_603230(name: "getIntent", meth: HttpMethod.HttpGet,
                                    host: "models.lex.amazonaws.com", route: "/intents/{name}/versions/{version}",
                                    validator: validate_GetIntent_603231,
                                    base: "/", url: url_GetIntent_603232,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntentVersion_603245 = ref object of OpenApiRestCall_602467
proc url_DeleteIntentVersion_603247(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  assert "version" in path, "`version` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/intents/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "version")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteIntentVersion_603246(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Deletes a specific version of an intent. To delete all versions of a intent, use the <a>DeleteIntent</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteIntentVersion</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the intent.
  ##   version: JString (required)
  ##          : The version of the intent to delete. You cannot delete the <code>$LATEST</code> version of the intent. To delete the <code>$LATEST</code> version, use the <a>DeleteIntent</a> operation.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_603248 = path.getOrDefault("name")
  valid_603248 = validateParameter(valid_603248, JString, required = true,
                                 default = nil)
  if valid_603248 != nil:
    section.add "name", valid_603248
  var valid_603249 = path.getOrDefault("version")
  valid_603249 = validateParameter(valid_603249, JString, required = true,
                                 default = nil)
  if valid_603249 != nil:
    section.add "version", valid_603249
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603250 = header.getOrDefault("X-Amz-Date")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "X-Amz-Date", valid_603250
  var valid_603251 = header.getOrDefault("X-Amz-Security-Token")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "X-Amz-Security-Token", valid_603251
  var valid_603252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "X-Amz-Content-Sha256", valid_603252
  var valid_603253 = header.getOrDefault("X-Amz-Algorithm")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "X-Amz-Algorithm", valid_603253
  var valid_603254 = header.getOrDefault("X-Amz-Signature")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-Signature", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-SignedHeaders", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Credential")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Credential", valid_603256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603257: Call_DeleteIntentVersion_603245; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a specific version of an intent. To delete all versions of a intent, use the <a>DeleteIntent</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteIntentVersion</code> action.</p>
  ## 
  let valid = call_603257.validator(path, query, header, formData, body)
  let scheme = call_603257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603257.url(scheme.get, call_603257.host, call_603257.base,
                         call_603257.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603257, url, valid)

proc call*(call_603258: Call_DeleteIntentVersion_603245; name: string;
          version: string): Recallable =
  ## deleteIntentVersion
  ## <p>Deletes a specific version of an intent. To delete all versions of a intent, use the <a>DeleteIntent</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteIntentVersion</code> action.</p>
  ##   name: string (required)
  ##       : The name of the intent.
  ##   version: string (required)
  ##          : The version of the intent to delete. You cannot delete the <code>$LATEST</code> version of the intent. To delete the <code>$LATEST</code> version, use the <a>DeleteIntent</a> operation.
  var path_603259 = newJObject()
  add(path_603259, "name", newJString(name))
  add(path_603259, "version", newJString(version))
  result = call_603258.call(path_603259, nil, nil, nil, nil)

var deleteIntentVersion* = Call_DeleteIntentVersion_603245(
    name: "deleteIntentVersion", meth: HttpMethod.HttpDelete,
    host: "models.lex.amazonaws.com", route: "/intents/{name}/versions/{version}",
    validator: validate_DeleteIntentVersion_603246, base: "/",
    url: url_DeleteIntentVersion_603247, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSlotType_603260 = ref object of OpenApiRestCall_602467
proc url_DeleteSlotType_603262(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/slottypes/"),
               (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteSlotType_603261(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Deletes all versions of the slot type, including the <code>$LATEST</code> version. To delete a specific version of the slot type, use the <a>DeleteSlotTypeVersion</a> operation.</p> <p> You can delete a version of a slot type only if it is not referenced. To delete a slot type that is referred to in one or more intents, you must remove those references first. </p> <note> <p> If you get the <code>ResourceInUseException</code> exception, the exception provides an example reference that shows the intent where the slot type is referenced. To remove the reference to the slot type, either update the intent or delete it. If you get the same exception when you attempt to delete the slot type again, repeat until the slot type has no references and the <code>DeleteSlotType</code> call is successful. </p> </note> <p>This operation requires permission for the <code>lex:DeleteSlotType</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the slot type. The name is case sensitive. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_603263 = path.getOrDefault("name")
  valid_603263 = validateParameter(valid_603263, JString, required = true,
                                 default = nil)
  if valid_603263 != nil:
    section.add "name", valid_603263
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603264 = header.getOrDefault("X-Amz-Date")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-Date", valid_603264
  var valid_603265 = header.getOrDefault("X-Amz-Security-Token")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-Security-Token", valid_603265
  var valid_603266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "X-Amz-Content-Sha256", valid_603266
  var valid_603267 = header.getOrDefault("X-Amz-Algorithm")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Algorithm", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-Signature")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Signature", valid_603268
  var valid_603269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "X-Amz-SignedHeaders", valid_603269
  var valid_603270 = header.getOrDefault("X-Amz-Credential")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Credential", valid_603270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603271: Call_DeleteSlotType_603260; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes all versions of the slot type, including the <code>$LATEST</code> version. To delete a specific version of the slot type, use the <a>DeleteSlotTypeVersion</a> operation.</p> <p> You can delete a version of a slot type only if it is not referenced. To delete a slot type that is referred to in one or more intents, you must remove those references first. </p> <note> <p> If you get the <code>ResourceInUseException</code> exception, the exception provides an example reference that shows the intent where the slot type is referenced. To remove the reference to the slot type, either update the intent or delete it. If you get the same exception when you attempt to delete the slot type again, repeat until the slot type has no references and the <code>DeleteSlotType</code> call is successful. </p> </note> <p>This operation requires permission for the <code>lex:DeleteSlotType</code> action.</p>
  ## 
  let valid = call_603271.validator(path, query, header, formData, body)
  let scheme = call_603271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603271.url(scheme.get, call_603271.host, call_603271.base,
                         call_603271.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603271, url, valid)

proc call*(call_603272: Call_DeleteSlotType_603260; name: string): Recallable =
  ## deleteSlotType
  ## <p>Deletes all versions of the slot type, including the <code>$LATEST</code> version. To delete a specific version of the slot type, use the <a>DeleteSlotTypeVersion</a> operation.</p> <p> You can delete a version of a slot type only if it is not referenced. To delete a slot type that is referred to in one or more intents, you must remove those references first. </p> <note> <p> If you get the <code>ResourceInUseException</code> exception, the exception provides an example reference that shows the intent where the slot type is referenced. To remove the reference to the slot type, either update the intent or delete it. If you get the same exception when you attempt to delete the slot type again, repeat until the slot type has no references and the <code>DeleteSlotType</code> call is successful. </p> </note> <p>This operation requires permission for the <code>lex:DeleteSlotType</code> action.</p>
  ##   name: string (required)
  ##       : The name of the slot type. The name is case sensitive. 
  var path_603273 = newJObject()
  add(path_603273, "name", newJString(name))
  result = call_603272.call(path_603273, nil, nil, nil, nil)

var deleteSlotType* = Call_DeleteSlotType_603260(name: "deleteSlotType",
    meth: HttpMethod.HttpDelete, host: "models.lex.amazonaws.com",
    route: "/slottypes/{name}", validator: validate_DeleteSlotType_603261,
    base: "/", url: url_DeleteSlotType_603262, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSlotTypeVersion_603274 = ref object of OpenApiRestCall_602467
proc url_DeleteSlotTypeVersion_603276(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  assert "version" in path, "`version` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/slottypes/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/version/"),
               (kind: VariableSegment, value: "version")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteSlotTypeVersion_603275(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a specific version of a slot type. To delete all versions of a slot type, use the <a>DeleteSlotType</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteSlotTypeVersion</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the slot type.
  ##   version: JString (required)
  ##          : The version of the slot type to delete. You cannot delete the <code>$LATEST</code> version of the slot type. To delete the <code>$LATEST</code> version, use the <a>DeleteSlotType</a> operation.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_603277 = path.getOrDefault("name")
  valid_603277 = validateParameter(valid_603277, JString, required = true,
                                 default = nil)
  if valid_603277 != nil:
    section.add "name", valid_603277
  var valid_603278 = path.getOrDefault("version")
  valid_603278 = validateParameter(valid_603278, JString, required = true,
                                 default = nil)
  if valid_603278 != nil:
    section.add "version", valid_603278
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603279 = header.getOrDefault("X-Amz-Date")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "X-Amz-Date", valid_603279
  var valid_603280 = header.getOrDefault("X-Amz-Security-Token")
  valid_603280 = validateParameter(valid_603280, JString, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "X-Amz-Security-Token", valid_603280
  var valid_603281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "X-Amz-Content-Sha256", valid_603281
  var valid_603282 = header.getOrDefault("X-Amz-Algorithm")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Algorithm", valid_603282
  var valid_603283 = header.getOrDefault("X-Amz-Signature")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-Signature", valid_603283
  var valid_603284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "X-Amz-SignedHeaders", valid_603284
  var valid_603285 = header.getOrDefault("X-Amz-Credential")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Credential", valid_603285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603286: Call_DeleteSlotTypeVersion_603274; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a specific version of a slot type. To delete all versions of a slot type, use the <a>DeleteSlotType</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteSlotTypeVersion</code> action.</p>
  ## 
  let valid = call_603286.validator(path, query, header, formData, body)
  let scheme = call_603286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603286.url(scheme.get, call_603286.host, call_603286.base,
                         call_603286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603286, url, valid)

proc call*(call_603287: Call_DeleteSlotTypeVersion_603274; name: string;
          version: string): Recallable =
  ## deleteSlotTypeVersion
  ## <p>Deletes a specific version of a slot type. To delete all versions of a slot type, use the <a>DeleteSlotType</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteSlotTypeVersion</code> action.</p>
  ##   name: string (required)
  ##       : The name of the slot type.
  ##   version: string (required)
  ##          : The version of the slot type to delete. You cannot delete the <code>$LATEST</code> version of the slot type. To delete the <code>$LATEST</code> version, use the <a>DeleteSlotType</a> operation.
  var path_603288 = newJObject()
  add(path_603288, "name", newJString(name))
  add(path_603288, "version", newJString(version))
  result = call_603287.call(path_603288, nil, nil, nil, nil)

var deleteSlotTypeVersion* = Call_DeleteSlotTypeVersion_603274(
    name: "deleteSlotTypeVersion", meth: HttpMethod.HttpDelete,
    host: "models.lex.amazonaws.com",
    route: "/slottypes/{name}/version/{version}",
    validator: validate_DeleteSlotTypeVersion_603275, base: "/",
    url: url_DeleteSlotTypeVersion_603276, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUtterances_603289 = ref object of OpenApiRestCall_602467
proc url_DeleteUtterances_603291(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "botName" in path, "`botName` is a required path parameter"
  assert "userId" in path, "`userId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/bots/"),
               (kind: VariableSegment, value: "botName"),
               (kind: ConstantSegment, value: "/utterances/"),
               (kind: VariableSegment, value: "userId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_DeleteUtterances_603290(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes stored utterances.</p> <p>Amazon Lex stores the utterances that users send to your bot. Utterances are stored for 15 days for use with the <a>GetUtterancesView</a> operation, and then stored indefinitely for use in improving the ability of your bot to respond to user input.</p> <p>Use the <code>DeleteStoredUtterances</code> operation to manually delete stored utterances for a specific user.</p> <p>This operation requires permissions for the <code>lex:DeleteUtterances</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   botName: JString (required)
  ##          : The name of the bot that stored the utterances.
  ##   userId: JString (required)
  ##         :  The unique identifier for the user that made the utterances. This is the user ID that was sent in the <a 
  ## href="http://docs.aws.amazon.com/lex/latest/dg/API_runtime_PostContent.html">PostContent</a> or <a 
  ## href="http://docs.aws.amazon.com/lex/latest/dg/API_runtime_PostText.html">PostText</a> operation request that contained the utterance.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `botName` field"
  var valid_603292 = path.getOrDefault("botName")
  valid_603292 = validateParameter(valid_603292, JString, required = true,
                                 default = nil)
  if valid_603292 != nil:
    section.add "botName", valid_603292
  var valid_603293 = path.getOrDefault("userId")
  valid_603293 = validateParameter(valid_603293, JString, required = true,
                                 default = nil)
  if valid_603293 != nil:
    section.add "userId", valid_603293
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603294 = header.getOrDefault("X-Amz-Date")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "X-Amz-Date", valid_603294
  var valid_603295 = header.getOrDefault("X-Amz-Security-Token")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "X-Amz-Security-Token", valid_603295
  var valid_603296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "X-Amz-Content-Sha256", valid_603296
  var valid_603297 = header.getOrDefault("X-Amz-Algorithm")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-Algorithm", valid_603297
  var valid_603298 = header.getOrDefault("X-Amz-Signature")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "X-Amz-Signature", valid_603298
  var valid_603299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603299 = validateParameter(valid_603299, JString, required = false,
                                 default = nil)
  if valid_603299 != nil:
    section.add "X-Amz-SignedHeaders", valid_603299
  var valid_603300 = header.getOrDefault("X-Amz-Credential")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Credential", valid_603300
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603301: Call_DeleteUtterances_603289; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes stored utterances.</p> <p>Amazon Lex stores the utterances that users send to your bot. Utterances are stored for 15 days for use with the <a>GetUtterancesView</a> operation, and then stored indefinitely for use in improving the ability of your bot to respond to user input.</p> <p>Use the <code>DeleteStoredUtterances</code> operation to manually delete stored utterances for a specific user.</p> <p>This operation requires permissions for the <code>lex:DeleteUtterances</code> action.</p>
  ## 
  let valid = call_603301.validator(path, query, header, formData, body)
  let scheme = call_603301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603301.url(scheme.get, call_603301.host, call_603301.base,
                         call_603301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603301, url, valid)

proc call*(call_603302: Call_DeleteUtterances_603289; botName: string; userId: string): Recallable =
  ## deleteUtterances
  ## <p>Deletes stored utterances.</p> <p>Amazon Lex stores the utterances that users send to your bot. Utterances are stored for 15 days for use with the <a>GetUtterancesView</a> operation, and then stored indefinitely for use in improving the ability of your bot to respond to user input.</p> <p>Use the <code>DeleteStoredUtterances</code> operation to manually delete stored utterances for a specific user.</p> <p>This operation requires permissions for the <code>lex:DeleteUtterances</code> action.</p>
  ##   botName: string (required)
  ##          : The name of the bot that stored the utterances.
  ##   userId: string (required)
  ##         :  The unique identifier for the user that made the utterances. This is the user ID that was sent in the <a 
  ## href="http://docs.aws.amazon.com/lex/latest/dg/API_runtime_PostContent.html">PostContent</a> or <a 
  ## href="http://docs.aws.amazon.com/lex/latest/dg/API_runtime_PostText.html">PostText</a> operation request that contained the utterance.
  var path_603303 = newJObject()
  add(path_603303, "botName", newJString(botName))
  add(path_603303, "userId", newJString(userId))
  result = call_603302.call(path_603303, nil, nil, nil, nil)

var deleteUtterances* = Call_DeleteUtterances_603289(name: "deleteUtterances",
    meth: HttpMethod.HttpDelete, host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/utterances/{userId}",
    validator: validate_DeleteUtterances_603290, base: "/",
    url: url_DeleteUtterances_603291, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBot_603304 = ref object of OpenApiRestCall_602467
proc url_GetBot_603306(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  assert "versionoralias" in path, "`versionoralias` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/bots/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "versionoralias")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBot_603305(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns metadata information for a specific bot. You must provide the bot name and the bot version or alias. </p> <p> This operation requires permissions for the <code>lex:GetBot</code> action. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   versionoralias: JString (required)
  ##                 : The version or alias of the bot.
  ##   name: JString (required)
  ##       : The name of the bot. The name is case sensitive. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `versionoralias` field"
  var valid_603307 = path.getOrDefault("versionoralias")
  valid_603307 = validateParameter(valid_603307, JString, required = true,
                                 default = nil)
  if valid_603307 != nil:
    section.add "versionoralias", valid_603307
  var valid_603308 = path.getOrDefault("name")
  valid_603308 = validateParameter(valid_603308, JString, required = true,
                                 default = nil)
  if valid_603308 != nil:
    section.add "name", valid_603308
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603309 = header.getOrDefault("X-Amz-Date")
  valid_603309 = validateParameter(valid_603309, JString, required = false,
                                 default = nil)
  if valid_603309 != nil:
    section.add "X-Amz-Date", valid_603309
  var valid_603310 = header.getOrDefault("X-Amz-Security-Token")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "X-Amz-Security-Token", valid_603310
  var valid_603311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603311 = validateParameter(valid_603311, JString, required = false,
                                 default = nil)
  if valid_603311 != nil:
    section.add "X-Amz-Content-Sha256", valid_603311
  var valid_603312 = header.getOrDefault("X-Amz-Algorithm")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "X-Amz-Algorithm", valid_603312
  var valid_603313 = header.getOrDefault("X-Amz-Signature")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "X-Amz-Signature", valid_603313
  var valid_603314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603314 = validateParameter(valid_603314, JString, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "X-Amz-SignedHeaders", valid_603314
  var valid_603315 = header.getOrDefault("X-Amz-Credential")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Credential", valid_603315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603316: Call_GetBot_603304; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns metadata information for a specific bot. You must provide the bot name and the bot version or alias. </p> <p> This operation requires permissions for the <code>lex:GetBot</code> action. </p>
  ## 
  let valid = call_603316.validator(path, query, header, formData, body)
  let scheme = call_603316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603316.url(scheme.get, call_603316.host, call_603316.base,
                         call_603316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603316, url, valid)

proc call*(call_603317: Call_GetBot_603304; versionoralias: string; name: string): Recallable =
  ## getBot
  ## <p>Returns metadata information for a specific bot. You must provide the bot name and the bot version or alias. </p> <p> This operation requires permissions for the <code>lex:GetBot</code> action. </p>
  ##   versionoralias: string (required)
  ##                 : The version or alias of the bot.
  ##   name: string (required)
  ##       : The name of the bot. The name is case sensitive. 
  var path_603318 = newJObject()
  add(path_603318, "versionoralias", newJString(versionoralias))
  add(path_603318, "name", newJString(name))
  result = call_603317.call(path_603318, nil, nil, nil, nil)

var getBot* = Call_GetBot_603304(name: "getBot", meth: HttpMethod.HttpGet,
                              host: "models.lex.amazonaws.com",
                              route: "/bots/{name}/versions/{versionoralias}",
                              validator: validate_GetBot_603305, base: "/",
                              url: url_GetBot_603306,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBotAliases_603319 = ref object of OpenApiRestCall_602467
proc url_GetBotAliases_603321(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "botName" in path, "`botName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/bots/"),
               (kind: VariableSegment, value: "botName"),
               (kind: ConstantSegment, value: "/aliases/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBotAliases_603320(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of aliases for a specified Amazon Lex bot.</p> <p>This operation requires permissions for the <code>lex:GetBotAliases</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   botName: JString (required)
  ##          : The name of the bot.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `botName` field"
  var valid_603322 = path.getOrDefault("botName")
  valid_603322 = validateParameter(valid_603322, JString, required = true,
                                 default = nil)
  if valid_603322 != nil:
    section.add "botName", valid_603322
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of aliases to return in the response. The default is 50. . 
  ##   nextToken: JString
  ##            : A pagination token for fetching the next page of aliases. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of aliases, specify the pagination token in the next request. 
  ##   nameContains: JString
  ##               : Substring to match in bot alias names. An alias will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  section = newJObject()
  var valid_603323 = query.getOrDefault("maxResults")
  valid_603323 = validateParameter(valid_603323, JInt, required = false, default = nil)
  if valid_603323 != nil:
    section.add "maxResults", valid_603323
  var valid_603324 = query.getOrDefault("nextToken")
  valid_603324 = validateParameter(valid_603324, JString, required = false,
                                 default = nil)
  if valid_603324 != nil:
    section.add "nextToken", valid_603324
  var valid_603325 = query.getOrDefault("nameContains")
  valid_603325 = validateParameter(valid_603325, JString, required = false,
                                 default = nil)
  if valid_603325 != nil:
    section.add "nameContains", valid_603325
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603326 = header.getOrDefault("X-Amz-Date")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "X-Amz-Date", valid_603326
  var valid_603327 = header.getOrDefault("X-Amz-Security-Token")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "X-Amz-Security-Token", valid_603327
  var valid_603328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "X-Amz-Content-Sha256", valid_603328
  var valid_603329 = header.getOrDefault("X-Amz-Algorithm")
  valid_603329 = validateParameter(valid_603329, JString, required = false,
                                 default = nil)
  if valid_603329 != nil:
    section.add "X-Amz-Algorithm", valid_603329
  var valid_603330 = header.getOrDefault("X-Amz-Signature")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Signature", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-SignedHeaders", valid_603331
  var valid_603332 = header.getOrDefault("X-Amz-Credential")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "X-Amz-Credential", valid_603332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603333: Call_GetBotAliases_603319; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of aliases for a specified Amazon Lex bot.</p> <p>This operation requires permissions for the <code>lex:GetBotAliases</code> action.</p>
  ## 
  let valid = call_603333.validator(path, query, header, formData, body)
  let scheme = call_603333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603333.url(scheme.get, call_603333.host, call_603333.base,
                         call_603333.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603333, url, valid)

proc call*(call_603334: Call_GetBotAliases_603319; botName: string;
          maxResults: int = 0; nextToken: string = ""; nameContains: string = ""): Recallable =
  ## getBotAliases
  ## <p>Returns a list of aliases for a specified Amazon Lex bot.</p> <p>This operation requires permissions for the <code>lex:GetBotAliases</code> action.</p>
  ##   maxResults: int
  ##             : The maximum number of aliases to return in the response. The default is 50. . 
  ##   nextToken: string
  ##            : A pagination token for fetching the next page of aliases. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of aliases, specify the pagination token in the next request. 
  ##   botName: string (required)
  ##          : The name of the bot.
  ##   nameContains: string
  ##               : Substring to match in bot alias names. An alias will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  var path_603335 = newJObject()
  var query_603336 = newJObject()
  add(query_603336, "maxResults", newJInt(maxResults))
  add(query_603336, "nextToken", newJString(nextToken))
  add(path_603335, "botName", newJString(botName))
  add(query_603336, "nameContains", newJString(nameContains))
  result = call_603334.call(path_603335, query_603336, nil, nil, nil)

var getBotAliases* = Call_GetBotAliases_603319(name: "getBotAliases",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/aliases/", validator: validate_GetBotAliases_603320,
    base: "/", url: url_GetBotAliases_603321, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBotChannelAssociations_603337 = ref object of OpenApiRestCall_602467
proc url_GetBotChannelAssociations_603339(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "botName" in path, "`botName` is a required path parameter"
  assert "aliasName" in path, "`aliasName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/bots/"),
               (kind: VariableSegment, value: "botName"),
               (kind: ConstantSegment, value: "/aliases/"),
               (kind: VariableSegment, value: "aliasName"),
               (kind: ConstantSegment, value: "/channels/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBotChannelAssociations_603338(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Returns a list of all of the channels associated with the specified bot. </p> <p>The <code>GetBotChannelAssociations</code> operation requires permissions for the <code>lex:GetBotChannelAssociations</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   botName: JString (required)
  ##          : The name of the Amazon Lex bot in the association.
  ##   aliasName: JString (required)
  ##            : An alias pointing to the specific version of the Amazon Lex bot to which this association is being made.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `botName` field"
  var valid_603340 = path.getOrDefault("botName")
  valid_603340 = validateParameter(valid_603340, JString, required = true,
                                 default = nil)
  if valid_603340 != nil:
    section.add "botName", valid_603340
  var valid_603341 = path.getOrDefault("aliasName")
  valid_603341 = validateParameter(valid_603341, JString, required = true,
                                 default = nil)
  if valid_603341 != nil:
    section.add "aliasName", valid_603341
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of associations to return in the response. The default is 50. 
  ##   nextToken: JString
  ##            : A pagination token for fetching the next page of associations. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of associations, specify the pagination token in the next request. 
  ##   nameContains: JString
  ##               : Substring to match in channel association names. An association will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz." To return all bot channel associations, use a hyphen ("-") as the <code>nameContains</code> parameter.
  section = newJObject()
  var valid_603342 = query.getOrDefault("maxResults")
  valid_603342 = validateParameter(valid_603342, JInt, required = false, default = nil)
  if valid_603342 != nil:
    section.add "maxResults", valid_603342
  var valid_603343 = query.getOrDefault("nextToken")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "nextToken", valid_603343
  var valid_603344 = query.getOrDefault("nameContains")
  valid_603344 = validateParameter(valid_603344, JString, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "nameContains", valid_603344
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603345 = header.getOrDefault("X-Amz-Date")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Date", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-Security-Token")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-Security-Token", valid_603346
  var valid_603347 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603347 = validateParameter(valid_603347, JString, required = false,
                                 default = nil)
  if valid_603347 != nil:
    section.add "X-Amz-Content-Sha256", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-Algorithm")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-Algorithm", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-Signature")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Signature", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-SignedHeaders", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-Credential")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-Credential", valid_603351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603352: Call_GetBotChannelAssociations_603337; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns a list of all of the channels associated with the specified bot. </p> <p>The <code>GetBotChannelAssociations</code> operation requires permissions for the <code>lex:GetBotChannelAssociations</code> action.</p>
  ## 
  let valid = call_603352.validator(path, query, header, formData, body)
  let scheme = call_603352.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603352.url(scheme.get, call_603352.host, call_603352.base,
                         call_603352.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603352, url, valid)

proc call*(call_603353: Call_GetBotChannelAssociations_603337; botName: string;
          aliasName: string; maxResults: int = 0; nextToken: string = "";
          nameContains: string = ""): Recallable =
  ## getBotChannelAssociations
  ## <p> Returns a list of all of the channels associated with the specified bot. </p> <p>The <code>GetBotChannelAssociations</code> operation requires permissions for the <code>lex:GetBotChannelAssociations</code> action.</p>
  ##   maxResults: int
  ##             : The maximum number of associations to return in the response. The default is 50. 
  ##   nextToken: string
  ##            : A pagination token for fetching the next page of associations. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of associations, specify the pagination token in the next request. 
  ##   botName: string (required)
  ##          : The name of the Amazon Lex bot in the association.
  ##   nameContains: string
  ##               : Substring to match in channel association names. An association will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz." To return all bot channel associations, use a hyphen ("-") as the <code>nameContains</code> parameter.
  ##   aliasName: string (required)
  ##            : An alias pointing to the specific version of the Amazon Lex bot to which this association is being made.
  var path_603354 = newJObject()
  var query_603355 = newJObject()
  add(query_603355, "maxResults", newJInt(maxResults))
  add(query_603355, "nextToken", newJString(nextToken))
  add(path_603354, "botName", newJString(botName))
  add(query_603355, "nameContains", newJString(nameContains))
  add(path_603354, "aliasName", newJString(aliasName))
  result = call_603353.call(path_603354, query_603355, nil, nil, nil)

var getBotChannelAssociations* = Call_GetBotChannelAssociations_603337(
    name: "getBotChannelAssociations", meth: HttpMethod.HttpGet,
    host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/aliases/{aliasName}/channels/",
    validator: validate_GetBotChannelAssociations_603338, base: "/",
    url: url_GetBotChannelAssociations_603339,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBotVersions_603356 = ref object of OpenApiRestCall_602467
proc url_GetBotVersions_603358(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/bots/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/versions/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBotVersions_603357(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Gets information about all of the versions of a bot.</p> <p>The <code>GetBotVersions</code> operation returns a <code>BotMetadata</code> object for each version of a bot. For example, if a bot has three numbered versions, the <code>GetBotVersions</code> operation returns four <code>BotMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetBotVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetBotVersions</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the bot for which versions should be returned.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_603359 = path.getOrDefault("name")
  valid_603359 = validateParameter(valid_603359, JString, required = true,
                                 default = nil)
  if valid_603359 != nil:
    section.add "name", valid_603359
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of bot versions to return in the response. The default is 10.
  ##   nextToken: JString
  ##            : A pagination token for fetching the next page of bot versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  section = newJObject()
  var valid_603360 = query.getOrDefault("maxResults")
  valid_603360 = validateParameter(valid_603360, JInt, required = false, default = nil)
  if valid_603360 != nil:
    section.add "maxResults", valid_603360
  var valid_603361 = query.getOrDefault("nextToken")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "nextToken", valid_603361
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603362 = header.getOrDefault("X-Amz-Date")
  valid_603362 = validateParameter(valid_603362, JString, required = false,
                                 default = nil)
  if valid_603362 != nil:
    section.add "X-Amz-Date", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-Security-Token")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-Security-Token", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Content-Sha256", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Algorithm")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Algorithm", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-Signature")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-Signature", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-SignedHeaders", valid_603367
  var valid_603368 = header.getOrDefault("X-Amz-Credential")
  valid_603368 = validateParameter(valid_603368, JString, required = false,
                                 default = nil)
  if valid_603368 != nil:
    section.add "X-Amz-Credential", valid_603368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603369: Call_GetBotVersions_603356; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about all of the versions of a bot.</p> <p>The <code>GetBotVersions</code> operation returns a <code>BotMetadata</code> object for each version of a bot. For example, if a bot has three numbered versions, the <code>GetBotVersions</code> operation returns four <code>BotMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetBotVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetBotVersions</code> action.</p>
  ## 
  let valid = call_603369.validator(path, query, header, formData, body)
  let scheme = call_603369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603369.url(scheme.get, call_603369.host, call_603369.base,
                         call_603369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603369, url, valid)

proc call*(call_603370: Call_GetBotVersions_603356; name: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## getBotVersions
  ## <p>Gets information about all of the versions of a bot.</p> <p>The <code>GetBotVersions</code> operation returns a <code>BotMetadata</code> object for each version of a bot. For example, if a bot has three numbered versions, the <code>GetBotVersions</code> operation returns four <code>BotMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetBotVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetBotVersions</code> action.</p>
  ##   name: string (required)
  ##       : The name of the bot for which versions should be returned.
  ##   maxResults: int
  ##             : The maximum number of bot versions to return in the response. The default is 10.
  ##   nextToken: string
  ##            : A pagination token for fetching the next page of bot versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  var path_603371 = newJObject()
  var query_603372 = newJObject()
  add(path_603371, "name", newJString(name))
  add(query_603372, "maxResults", newJInt(maxResults))
  add(query_603372, "nextToken", newJString(nextToken))
  result = call_603370.call(path_603371, query_603372, nil, nil, nil)

var getBotVersions* = Call_GetBotVersions_603356(name: "getBotVersions",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/bots/{name}/versions/", validator: validate_GetBotVersions_603357,
    base: "/", url: url_GetBotVersions_603358, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBots_603373 = ref object of OpenApiRestCall_602467
proc url_GetBots_603375(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetBots_603374(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns bot information as follows: </p> <ul> <li> <p>If you provide the <code>nameContains</code> field, the response includes information for the <code>$LATEST</code> version of all bots whose name contains the specified string.</p> </li> <li> <p>If you don't specify the <code>nameContains</code> field, the operation returns information about the <code>$LATEST</code> version of all of your bots.</p> </li> </ul> <p>This operation requires permission for the <code>lex:GetBots</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of bots to return in the response that the request will return. The default is 10.
  ##   nextToken: JString
  ##            : A pagination token that fetches the next page of bots. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of bots, specify the pagination token in the next request. 
  ##   nameContains: JString
  ##               : Substring to match in bot names. A bot will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  section = newJObject()
  var valid_603376 = query.getOrDefault("maxResults")
  valid_603376 = validateParameter(valid_603376, JInt, required = false, default = nil)
  if valid_603376 != nil:
    section.add "maxResults", valid_603376
  var valid_603377 = query.getOrDefault("nextToken")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "nextToken", valid_603377
  var valid_603378 = query.getOrDefault("nameContains")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "nameContains", valid_603378
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603379 = header.getOrDefault("X-Amz-Date")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Date", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-Security-Token")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-Security-Token", valid_603380
  var valid_603381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "X-Amz-Content-Sha256", valid_603381
  var valid_603382 = header.getOrDefault("X-Amz-Algorithm")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-Algorithm", valid_603382
  var valid_603383 = header.getOrDefault("X-Amz-Signature")
  valid_603383 = validateParameter(valid_603383, JString, required = false,
                                 default = nil)
  if valid_603383 != nil:
    section.add "X-Amz-Signature", valid_603383
  var valid_603384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603384 = validateParameter(valid_603384, JString, required = false,
                                 default = nil)
  if valid_603384 != nil:
    section.add "X-Amz-SignedHeaders", valid_603384
  var valid_603385 = header.getOrDefault("X-Amz-Credential")
  valid_603385 = validateParameter(valid_603385, JString, required = false,
                                 default = nil)
  if valid_603385 != nil:
    section.add "X-Amz-Credential", valid_603385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603386: Call_GetBots_603373; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns bot information as follows: </p> <ul> <li> <p>If you provide the <code>nameContains</code> field, the response includes information for the <code>$LATEST</code> version of all bots whose name contains the specified string.</p> </li> <li> <p>If you don't specify the <code>nameContains</code> field, the operation returns information about the <code>$LATEST</code> version of all of your bots.</p> </li> </ul> <p>This operation requires permission for the <code>lex:GetBots</code> action.</p>
  ## 
  let valid = call_603386.validator(path, query, header, formData, body)
  let scheme = call_603386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603386.url(scheme.get, call_603386.host, call_603386.base,
                         call_603386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603386, url, valid)

proc call*(call_603387: Call_GetBots_603373; maxResults: int = 0;
          nextToken: string = ""; nameContains: string = ""): Recallable =
  ## getBots
  ## <p>Returns bot information as follows: </p> <ul> <li> <p>If you provide the <code>nameContains</code> field, the response includes information for the <code>$LATEST</code> version of all bots whose name contains the specified string.</p> </li> <li> <p>If you don't specify the <code>nameContains</code> field, the operation returns information about the <code>$LATEST</code> version of all of your bots.</p> </li> </ul> <p>This operation requires permission for the <code>lex:GetBots</code> action.</p>
  ##   maxResults: int
  ##             : The maximum number of bots to return in the response that the request will return. The default is 10.
  ##   nextToken: string
  ##            : A pagination token that fetches the next page of bots. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of bots, specify the pagination token in the next request. 
  ##   nameContains: string
  ##               : Substring to match in bot names. A bot will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  var query_603388 = newJObject()
  add(query_603388, "maxResults", newJInt(maxResults))
  add(query_603388, "nextToken", newJString(nextToken))
  add(query_603388, "nameContains", newJString(nameContains))
  result = call_603387.call(nil, query_603388, nil, nil, nil)

var getBots* = Call_GetBots_603373(name: "getBots", meth: HttpMethod.HttpGet,
                                host: "models.lex.amazonaws.com", route: "/bots/",
                                validator: validate_GetBots_603374, base: "/",
                                url: url_GetBots_603375,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBuiltinIntent_603389 = ref object of OpenApiRestCall_602467
proc url_GetBuiltinIntent_603391(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "signature" in path, "`signature` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/builtins/intents/"),
               (kind: VariableSegment, value: "signature")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetBuiltinIntent_603390(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Returns information about a built-in intent.</p> <p>This operation requires permission for the <code>lex:GetBuiltinIntent</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   signature: JString (required)
  ##            : The unique identifier for a built-in intent. To find the signature for an intent, see <a 
  ## href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/standard-intents">Standard Built-in Intents</a> in the <i>Alexa Skills Kit</i>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `signature` field"
  var valid_603392 = path.getOrDefault("signature")
  valid_603392 = validateParameter(valid_603392, JString, required = true,
                                 default = nil)
  if valid_603392 != nil:
    section.add "signature", valid_603392
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603393 = header.getOrDefault("X-Amz-Date")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Date", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-Security-Token")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-Security-Token", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Content-Sha256", valid_603395
  var valid_603396 = header.getOrDefault("X-Amz-Algorithm")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-Algorithm", valid_603396
  var valid_603397 = header.getOrDefault("X-Amz-Signature")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-Signature", valid_603397
  var valid_603398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603398 = validateParameter(valid_603398, JString, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "X-Amz-SignedHeaders", valid_603398
  var valid_603399 = header.getOrDefault("X-Amz-Credential")
  valid_603399 = validateParameter(valid_603399, JString, required = false,
                                 default = nil)
  if valid_603399 != nil:
    section.add "X-Amz-Credential", valid_603399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603400: Call_GetBuiltinIntent_603389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a built-in intent.</p> <p>This operation requires permission for the <code>lex:GetBuiltinIntent</code> action.</p>
  ## 
  let valid = call_603400.validator(path, query, header, formData, body)
  let scheme = call_603400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603400.url(scheme.get, call_603400.host, call_603400.base,
                         call_603400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603400, url, valid)

proc call*(call_603401: Call_GetBuiltinIntent_603389; signature: string): Recallable =
  ## getBuiltinIntent
  ## <p>Returns information about a built-in intent.</p> <p>This operation requires permission for the <code>lex:GetBuiltinIntent</code> action.</p>
  ##   signature: string (required)
  ##            : The unique identifier for a built-in intent. To find the signature for an intent, see <a 
  ## href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/standard-intents">Standard Built-in Intents</a> in the <i>Alexa Skills Kit</i>.
  var path_603402 = newJObject()
  add(path_603402, "signature", newJString(signature))
  result = call_603401.call(path_603402, nil, nil, nil, nil)

var getBuiltinIntent* = Call_GetBuiltinIntent_603389(name: "getBuiltinIntent",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/builtins/intents/{signature}", validator: validate_GetBuiltinIntent_603390,
    base: "/", url: url_GetBuiltinIntent_603391,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBuiltinIntents_603403 = ref object of OpenApiRestCall_602467
proc url_GetBuiltinIntents_603405(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetBuiltinIntents_603404(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Gets a list of built-in intents that meet the specified criteria.</p> <p>This operation requires permission for the <code>lex:GetBuiltinIntents</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   locale: JString
  ##         : A list of locales that the intent supports.
  ##   maxResults: JInt
  ##             : The maximum number of intents to return in the response. The default is 10.
  ##   nextToken: JString
  ##            : A pagination token that fetches the next page of intents. If this API call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of intents, use the pagination token in the next request.
  ##   signatureContains: JString
  ##                    : Substring to match in built-in intent signatures. An intent will be returned if any part of its signature matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz." To find the signature for an intent, see <a 
  ## href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/standard-intents">Standard Built-in Intents</a> in the <i>Alexa Skills Kit</i>.
  section = newJObject()
  var valid_603419 = query.getOrDefault("locale")
  valid_603419 = validateParameter(valid_603419, JString, required = false,
                                 default = newJString("en-US"))
  if valid_603419 != nil:
    section.add "locale", valid_603419
  var valid_603420 = query.getOrDefault("maxResults")
  valid_603420 = validateParameter(valid_603420, JInt, required = false, default = nil)
  if valid_603420 != nil:
    section.add "maxResults", valid_603420
  var valid_603421 = query.getOrDefault("nextToken")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "nextToken", valid_603421
  var valid_603422 = query.getOrDefault("signatureContains")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "signatureContains", valid_603422
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603423 = header.getOrDefault("X-Amz-Date")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Date", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Security-Token")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Security-Token", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Content-Sha256", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-Algorithm")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-Algorithm", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-Signature")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-Signature", valid_603427
  var valid_603428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-SignedHeaders", valid_603428
  var valid_603429 = header.getOrDefault("X-Amz-Credential")
  valid_603429 = validateParameter(valid_603429, JString, required = false,
                                 default = nil)
  if valid_603429 != nil:
    section.add "X-Amz-Credential", valid_603429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603430: Call_GetBuiltinIntents_603403; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of built-in intents that meet the specified criteria.</p> <p>This operation requires permission for the <code>lex:GetBuiltinIntents</code> action.</p>
  ## 
  let valid = call_603430.validator(path, query, header, formData, body)
  let scheme = call_603430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603430.url(scheme.get, call_603430.host, call_603430.base,
                         call_603430.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603430, url, valid)

proc call*(call_603431: Call_GetBuiltinIntents_603403; locale: string = "en-US";
          maxResults: int = 0; nextToken: string = ""; signatureContains: string = ""): Recallable =
  ## getBuiltinIntents
  ## <p>Gets a list of built-in intents that meet the specified criteria.</p> <p>This operation requires permission for the <code>lex:GetBuiltinIntents</code> action.</p>
  ##   locale: string
  ##         : A list of locales that the intent supports.
  ##   maxResults: int
  ##             : The maximum number of intents to return in the response. The default is 10.
  ##   nextToken: string
  ##            : A pagination token that fetches the next page of intents. If this API call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of intents, use the pagination token in the next request.
  ##   signatureContains: string
  ##                    : Substring to match in built-in intent signatures. An intent will be returned if any part of its signature matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz." To find the signature for an intent, see <a 
  ## href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/standard-intents">Standard Built-in Intents</a> in the <i>Alexa Skills Kit</i>.
  var query_603432 = newJObject()
  add(query_603432, "locale", newJString(locale))
  add(query_603432, "maxResults", newJInt(maxResults))
  add(query_603432, "nextToken", newJString(nextToken))
  add(query_603432, "signatureContains", newJString(signatureContains))
  result = call_603431.call(nil, query_603432, nil, nil, nil)

var getBuiltinIntents* = Call_GetBuiltinIntents_603403(name: "getBuiltinIntents",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/builtins/intents/", validator: validate_GetBuiltinIntents_603404,
    base: "/", url: url_GetBuiltinIntents_603405,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBuiltinSlotTypes_603433 = ref object of OpenApiRestCall_602467
proc url_GetBuiltinSlotTypes_603435(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetBuiltinSlotTypes_603434(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Gets a list of built-in slot types that meet the specified criteria.</p> <p>For a list of built-in slot types, see <a href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/slot-type-reference">Slot Type Reference</a> in the <i>Alexa Skills Kit</i>.</p> <p>This operation requires permission for the <code>lex:GetBuiltInSlotTypes</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   locale: JString
  ##         : A list of locales that the slot type supports.
  ##   maxResults: JInt
  ##             : The maximum number of slot types to return in the response. The default is 10.
  ##   nextToken: JString
  ##            : A pagination token that fetches the next page of slot types. If the response to this API call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of slot types, specify the pagination token in the next request.
  ##   signatureContains: JString
  ##                    : Substring to match in built-in slot type signatures. A slot type will be returned if any part of its signature matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  section = newJObject()
  var valid_603436 = query.getOrDefault("locale")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = newJString("en-US"))
  if valid_603436 != nil:
    section.add "locale", valid_603436
  var valid_603437 = query.getOrDefault("maxResults")
  valid_603437 = validateParameter(valid_603437, JInt, required = false, default = nil)
  if valid_603437 != nil:
    section.add "maxResults", valid_603437
  var valid_603438 = query.getOrDefault("nextToken")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "nextToken", valid_603438
  var valid_603439 = query.getOrDefault("signatureContains")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "signatureContains", valid_603439
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603440 = header.getOrDefault("X-Amz-Date")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Date", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-Security-Token")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-Security-Token", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Content-Sha256", valid_603442
  var valid_603443 = header.getOrDefault("X-Amz-Algorithm")
  valid_603443 = validateParameter(valid_603443, JString, required = false,
                                 default = nil)
  if valid_603443 != nil:
    section.add "X-Amz-Algorithm", valid_603443
  var valid_603444 = header.getOrDefault("X-Amz-Signature")
  valid_603444 = validateParameter(valid_603444, JString, required = false,
                                 default = nil)
  if valid_603444 != nil:
    section.add "X-Amz-Signature", valid_603444
  var valid_603445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603445 = validateParameter(valid_603445, JString, required = false,
                                 default = nil)
  if valid_603445 != nil:
    section.add "X-Amz-SignedHeaders", valid_603445
  var valid_603446 = header.getOrDefault("X-Amz-Credential")
  valid_603446 = validateParameter(valid_603446, JString, required = false,
                                 default = nil)
  if valid_603446 != nil:
    section.add "X-Amz-Credential", valid_603446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603447: Call_GetBuiltinSlotTypes_603433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of built-in slot types that meet the specified criteria.</p> <p>For a list of built-in slot types, see <a href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/slot-type-reference">Slot Type Reference</a> in the <i>Alexa Skills Kit</i>.</p> <p>This operation requires permission for the <code>lex:GetBuiltInSlotTypes</code> action.</p>
  ## 
  let valid = call_603447.validator(path, query, header, formData, body)
  let scheme = call_603447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603447.url(scheme.get, call_603447.host, call_603447.base,
                         call_603447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603447, url, valid)

proc call*(call_603448: Call_GetBuiltinSlotTypes_603433; locale: string = "en-US";
          maxResults: int = 0; nextToken: string = ""; signatureContains: string = ""): Recallable =
  ## getBuiltinSlotTypes
  ## <p>Gets a list of built-in slot types that meet the specified criteria.</p> <p>For a list of built-in slot types, see <a href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/slot-type-reference">Slot Type Reference</a> in the <i>Alexa Skills Kit</i>.</p> <p>This operation requires permission for the <code>lex:GetBuiltInSlotTypes</code> action.</p>
  ##   locale: string
  ##         : A list of locales that the slot type supports.
  ##   maxResults: int
  ##             : The maximum number of slot types to return in the response. The default is 10.
  ##   nextToken: string
  ##            : A pagination token that fetches the next page of slot types. If the response to this API call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of slot types, specify the pagination token in the next request.
  ##   signatureContains: string
  ##                    : Substring to match in built-in slot type signatures. A slot type will be returned if any part of its signature matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  var query_603449 = newJObject()
  add(query_603449, "locale", newJString(locale))
  add(query_603449, "maxResults", newJInt(maxResults))
  add(query_603449, "nextToken", newJString(nextToken))
  add(query_603449, "signatureContains", newJString(signatureContains))
  result = call_603448.call(nil, query_603449, nil, nil, nil)

var getBuiltinSlotTypes* = Call_GetBuiltinSlotTypes_603433(
    name: "getBuiltinSlotTypes", meth: HttpMethod.HttpGet,
    host: "models.lex.amazonaws.com", route: "/builtins/slottypes/",
    validator: validate_GetBuiltinSlotTypes_603434, base: "/",
    url: url_GetBuiltinSlotTypes_603435, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExport_603450 = ref object of OpenApiRestCall_602467
proc url_GetExport_603452(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetExport_603451(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Exports the contents of a Amazon Lex resource in a specified format. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   exportType: JString (required)
  ##             : The format of the exported data.
  ##   name: JString (required)
  ##       : The name of the bot to export.
  ##   version: JString (required)
  ##          : The version of the bot to export.
  ##   resourceType: JString (required)
  ##               : The type of resource to export. 
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `exportType` field"
  var valid_603453 = query.getOrDefault("exportType")
  valid_603453 = validateParameter(valid_603453, JString, required = true,
                                 default = newJString("ALEXA_SKILLS_KIT"))
  if valid_603453 != nil:
    section.add "exportType", valid_603453
  var valid_603454 = query.getOrDefault("name")
  valid_603454 = validateParameter(valid_603454, JString, required = true,
                                 default = nil)
  if valid_603454 != nil:
    section.add "name", valid_603454
  var valid_603455 = query.getOrDefault("version")
  valid_603455 = validateParameter(valid_603455, JString, required = true,
                                 default = nil)
  if valid_603455 != nil:
    section.add "version", valid_603455
  var valid_603456 = query.getOrDefault("resourceType")
  valid_603456 = validateParameter(valid_603456, JString, required = true,
                                 default = newJString("BOT"))
  if valid_603456 != nil:
    section.add "resourceType", valid_603456
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603457 = header.getOrDefault("X-Amz-Date")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Date", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-Security-Token")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-Security-Token", valid_603458
  var valid_603459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-Content-Sha256", valid_603459
  var valid_603460 = header.getOrDefault("X-Amz-Algorithm")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "X-Amz-Algorithm", valid_603460
  var valid_603461 = header.getOrDefault("X-Amz-Signature")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "X-Amz-Signature", valid_603461
  var valid_603462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603462 = validateParameter(valid_603462, JString, required = false,
                                 default = nil)
  if valid_603462 != nil:
    section.add "X-Amz-SignedHeaders", valid_603462
  var valid_603463 = header.getOrDefault("X-Amz-Credential")
  valid_603463 = validateParameter(valid_603463, JString, required = false,
                                 default = nil)
  if valid_603463 != nil:
    section.add "X-Amz-Credential", valid_603463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603464: Call_GetExport_603450; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Exports the contents of a Amazon Lex resource in a specified format. 
  ## 
  let valid = call_603464.validator(path, query, header, formData, body)
  let scheme = call_603464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603464.url(scheme.get, call_603464.host, call_603464.base,
                         call_603464.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603464, url, valid)

proc call*(call_603465: Call_GetExport_603450; name: string; version: string;
          exportType: string = "ALEXA_SKILLS_KIT"; resourceType: string = "BOT"): Recallable =
  ## getExport
  ## Exports the contents of a Amazon Lex resource in a specified format. 
  ##   exportType: string (required)
  ##             : The format of the exported data.
  ##   name: string (required)
  ##       : The name of the bot to export.
  ##   version: string (required)
  ##          : The version of the bot to export.
  ##   resourceType: string (required)
  ##               : The type of resource to export. 
  var query_603466 = newJObject()
  add(query_603466, "exportType", newJString(exportType))
  add(query_603466, "name", newJString(name))
  add(query_603466, "version", newJString(version))
  add(query_603466, "resourceType", newJString(resourceType))
  result = call_603465.call(nil, query_603466, nil, nil, nil)

var getExport* = Call_GetExport_603450(name: "getExport", meth: HttpMethod.HttpGet,
                                    host: "models.lex.amazonaws.com", route: "/exports/#name&version&resourceType&exportType",
                                    validator: validate_GetExport_603451,
                                    base: "/", url: url_GetExport_603452,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImport_603467 = ref object of OpenApiRestCall_602467
proc url_GetImport_603469(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "importId" in path, "`importId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/imports/"),
               (kind: VariableSegment, value: "importId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetImport_603468(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about an import job started with the <code>StartImport</code> operation.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   importId: JString (required)
  ##           : The identifier of the import job information to return.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `importId` field"
  var valid_603470 = path.getOrDefault("importId")
  valid_603470 = validateParameter(valid_603470, JString, required = true,
                                 default = nil)
  if valid_603470 != nil:
    section.add "importId", valid_603470
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603471 = header.getOrDefault("X-Amz-Date")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-Date", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-Security-Token")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Security-Token", valid_603472
  var valid_603473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "X-Amz-Content-Sha256", valid_603473
  var valid_603474 = header.getOrDefault("X-Amz-Algorithm")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "X-Amz-Algorithm", valid_603474
  var valid_603475 = header.getOrDefault("X-Amz-Signature")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "X-Amz-Signature", valid_603475
  var valid_603476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "X-Amz-SignedHeaders", valid_603476
  var valid_603477 = header.getOrDefault("X-Amz-Credential")
  valid_603477 = validateParameter(valid_603477, JString, required = false,
                                 default = nil)
  if valid_603477 != nil:
    section.add "X-Amz-Credential", valid_603477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603478: Call_GetImport_603467; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about an import job started with the <code>StartImport</code> operation.
  ## 
  let valid = call_603478.validator(path, query, header, formData, body)
  let scheme = call_603478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603478.url(scheme.get, call_603478.host, call_603478.base,
                         call_603478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603478, url, valid)

proc call*(call_603479: Call_GetImport_603467; importId: string): Recallable =
  ## getImport
  ## Gets information about an import job started with the <code>StartImport</code> operation.
  ##   importId: string (required)
  ##           : The identifier of the import job information to return.
  var path_603480 = newJObject()
  add(path_603480, "importId", newJString(importId))
  result = call_603479.call(path_603480, nil, nil, nil, nil)

var getImport* = Call_GetImport_603467(name: "getImport", meth: HttpMethod.HttpGet,
                                    host: "models.lex.amazonaws.com",
                                    route: "/imports/{importId}",
                                    validator: validate_GetImport_603468,
                                    base: "/", url: url_GetImport_603469,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntentVersions_603481 = ref object of OpenApiRestCall_602467
proc url_GetIntentVersions_603483(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/intents/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/versions/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetIntentVersions_603482(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Gets information about all of the versions of an intent.</p> <p>The <code>GetIntentVersions</code> operation returns an <code>IntentMetadata</code> object for each version of an intent. For example, if an intent has three numbered versions, the <code>GetIntentVersions</code> operation returns four <code>IntentMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetIntentVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetIntentVersions</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the intent for which versions should be returned.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_603484 = path.getOrDefault("name")
  valid_603484 = validateParameter(valid_603484, JString, required = true,
                                 default = nil)
  if valid_603484 != nil:
    section.add "name", valid_603484
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of intent versions to return in the response. The default is 10.
  ##   nextToken: JString
  ##            : A pagination token for fetching the next page of intent versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  section = newJObject()
  var valid_603485 = query.getOrDefault("maxResults")
  valid_603485 = validateParameter(valid_603485, JInt, required = false, default = nil)
  if valid_603485 != nil:
    section.add "maxResults", valid_603485
  var valid_603486 = query.getOrDefault("nextToken")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "nextToken", valid_603486
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603487 = header.getOrDefault("X-Amz-Date")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Date", valid_603487
  var valid_603488 = header.getOrDefault("X-Amz-Security-Token")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "X-Amz-Security-Token", valid_603488
  var valid_603489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603489 = validateParameter(valid_603489, JString, required = false,
                                 default = nil)
  if valid_603489 != nil:
    section.add "X-Amz-Content-Sha256", valid_603489
  var valid_603490 = header.getOrDefault("X-Amz-Algorithm")
  valid_603490 = validateParameter(valid_603490, JString, required = false,
                                 default = nil)
  if valid_603490 != nil:
    section.add "X-Amz-Algorithm", valid_603490
  var valid_603491 = header.getOrDefault("X-Amz-Signature")
  valid_603491 = validateParameter(valid_603491, JString, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "X-Amz-Signature", valid_603491
  var valid_603492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603492 = validateParameter(valid_603492, JString, required = false,
                                 default = nil)
  if valid_603492 != nil:
    section.add "X-Amz-SignedHeaders", valid_603492
  var valid_603493 = header.getOrDefault("X-Amz-Credential")
  valid_603493 = validateParameter(valid_603493, JString, required = false,
                                 default = nil)
  if valid_603493 != nil:
    section.add "X-Amz-Credential", valid_603493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603494: Call_GetIntentVersions_603481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about all of the versions of an intent.</p> <p>The <code>GetIntentVersions</code> operation returns an <code>IntentMetadata</code> object for each version of an intent. For example, if an intent has three numbered versions, the <code>GetIntentVersions</code> operation returns four <code>IntentMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetIntentVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetIntentVersions</code> action.</p>
  ## 
  let valid = call_603494.validator(path, query, header, formData, body)
  let scheme = call_603494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603494.url(scheme.get, call_603494.host, call_603494.base,
                         call_603494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603494, url, valid)

proc call*(call_603495: Call_GetIntentVersions_603481; name: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## getIntentVersions
  ## <p>Gets information about all of the versions of an intent.</p> <p>The <code>GetIntentVersions</code> operation returns an <code>IntentMetadata</code> object for each version of an intent. For example, if an intent has three numbered versions, the <code>GetIntentVersions</code> operation returns four <code>IntentMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetIntentVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetIntentVersions</code> action.</p>
  ##   name: string (required)
  ##       : The name of the intent for which versions should be returned.
  ##   maxResults: int
  ##             : The maximum number of intent versions to return in the response. The default is 10.
  ##   nextToken: string
  ##            : A pagination token for fetching the next page of intent versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  var path_603496 = newJObject()
  var query_603497 = newJObject()
  add(path_603496, "name", newJString(name))
  add(query_603497, "maxResults", newJInt(maxResults))
  add(query_603497, "nextToken", newJString(nextToken))
  result = call_603495.call(path_603496, query_603497, nil, nil, nil)

var getIntentVersions* = Call_GetIntentVersions_603481(name: "getIntentVersions",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/intents/{name}/versions/", validator: validate_GetIntentVersions_603482,
    base: "/", url: url_GetIntentVersions_603483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntents_603498 = ref object of OpenApiRestCall_602467
proc url_GetIntents_603500(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetIntents_603499(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns intent information as follows: </p> <ul> <li> <p>If you specify the <code>nameContains</code> field, returns the <code>$LATEST</code> version of all intents that contain the specified string.</p> </li> <li> <p> If you don't specify the <code>nameContains</code> field, returns information about the <code>$LATEST</code> version of all intents. </p> </li> </ul> <p> The operation requires permission for the <code>lex:GetIntents</code> action. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of intents to return in the response. The default is 10.
  ##   nextToken: JString
  ##            : A pagination token that fetches the next page of intents. If the response to this API call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of intents, specify the pagination token in the next request. 
  ##   nameContains: JString
  ##               : Substring to match in intent names. An intent will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  section = newJObject()
  var valid_603501 = query.getOrDefault("maxResults")
  valid_603501 = validateParameter(valid_603501, JInt, required = false, default = nil)
  if valid_603501 != nil:
    section.add "maxResults", valid_603501
  var valid_603502 = query.getOrDefault("nextToken")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "nextToken", valid_603502
  var valid_603503 = query.getOrDefault("nameContains")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "nameContains", valid_603503
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603504 = header.getOrDefault("X-Amz-Date")
  valid_603504 = validateParameter(valid_603504, JString, required = false,
                                 default = nil)
  if valid_603504 != nil:
    section.add "X-Amz-Date", valid_603504
  var valid_603505 = header.getOrDefault("X-Amz-Security-Token")
  valid_603505 = validateParameter(valid_603505, JString, required = false,
                                 default = nil)
  if valid_603505 != nil:
    section.add "X-Amz-Security-Token", valid_603505
  var valid_603506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603506 = validateParameter(valid_603506, JString, required = false,
                                 default = nil)
  if valid_603506 != nil:
    section.add "X-Amz-Content-Sha256", valid_603506
  var valid_603507 = header.getOrDefault("X-Amz-Algorithm")
  valid_603507 = validateParameter(valid_603507, JString, required = false,
                                 default = nil)
  if valid_603507 != nil:
    section.add "X-Amz-Algorithm", valid_603507
  var valid_603508 = header.getOrDefault("X-Amz-Signature")
  valid_603508 = validateParameter(valid_603508, JString, required = false,
                                 default = nil)
  if valid_603508 != nil:
    section.add "X-Amz-Signature", valid_603508
  var valid_603509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603509 = validateParameter(valid_603509, JString, required = false,
                                 default = nil)
  if valid_603509 != nil:
    section.add "X-Amz-SignedHeaders", valid_603509
  var valid_603510 = header.getOrDefault("X-Amz-Credential")
  valid_603510 = validateParameter(valid_603510, JString, required = false,
                                 default = nil)
  if valid_603510 != nil:
    section.add "X-Amz-Credential", valid_603510
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603511: Call_GetIntents_603498; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns intent information as follows: </p> <ul> <li> <p>If you specify the <code>nameContains</code> field, returns the <code>$LATEST</code> version of all intents that contain the specified string.</p> </li> <li> <p> If you don't specify the <code>nameContains</code> field, returns information about the <code>$LATEST</code> version of all intents. </p> </li> </ul> <p> The operation requires permission for the <code>lex:GetIntents</code> action. </p>
  ## 
  let valid = call_603511.validator(path, query, header, formData, body)
  let scheme = call_603511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603511.url(scheme.get, call_603511.host, call_603511.base,
                         call_603511.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603511, url, valid)

proc call*(call_603512: Call_GetIntents_603498; maxResults: int = 0;
          nextToken: string = ""; nameContains: string = ""): Recallable =
  ## getIntents
  ## <p>Returns intent information as follows: </p> <ul> <li> <p>If you specify the <code>nameContains</code> field, returns the <code>$LATEST</code> version of all intents that contain the specified string.</p> </li> <li> <p> If you don't specify the <code>nameContains</code> field, returns information about the <code>$LATEST</code> version of all intents. </p> </li> </ul> <p> The operation requires permission for the <code>lex:GetIntents</code> action. </p>
  ##   maxResults: int
  ##             : The maximum number of intents to return in the response. The default is 10.
  ##   nextToken: string
  ##            : A pagination token that fetches the next page of intents. If the response to this API call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of intents, specify the pagination token in the next request. 
  ##   nameContains: string
  ##               : Substring to match in intent names. An intent will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  var query_603513 = newJObject()
  add(query_603513, "maxResults", newJInt(maxResults))
  add(query_603513, "nextToken", newJString(nextToken))
  add(query_603513, "nameContains", newJString(nameContains))
  result = call_603512.call(nil, query_603513, nil, nil, nil)

var getIntents* = Call_GetIntents_603498(name: "getIntents",
                                      meth: HttpMethod.HttpGet,
                                      host: "models.lex.amazonaws.com",
                                      route: "/intents/",
                                      validator: validate_GetIntents_603499,
                                      base: "/", url: url_GetIntents_603500,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSlotType_603514 = ref object of OpenApiRestCall_602467
proc url_GetSlotType_603516(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  assert "version" in path, "`version` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/slottypes/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "version")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetSlotType_603515(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about a specific version of a slot type. In addition to specifying the slot type name, you must specify the slot type version.</p> <p>This operation requires permissions for the <code>lex:GetSlotType</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the slot type. The name is case sensitive. 
  ##   version: JString (required)
  ##          : The version of the slot type. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_603517 = path.getOrDefault("name")
  valid_603517 = validateParameter(valid_603517, JString, required = true,
                                 default = nil)
  if valid_603517 != nil:
    section.add "name", valid_603517
  var valid_603518 = path.getOrDefault("version")
  valid_603518 = validateParameter(valid_603518, JString, required = true,
                                 default = nil)
  if valid_603518 != nil:
    section.add "version", valid_603518
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603519 = header.getOrDefault("X-Amz-Date")
  valid_603519 = validateParameter(valid_603519, JString, required = false,
                                 default = nil)
  if valid_603519 != nil:
    section.add "X-Amz-Date", valid_603519
  var valid_603520 = header.getOrDefault("X-Amz-Security-Token")
  valid_603520 = validateParameter(valid_603520, JString, required = false,
                                 default = nil)
  if valid_603520 != nil:
    section.add "X-Amz-Security-Token", valid_603520
  var valid_603521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603521 = validateParameter(valid_603521, JString, required = false,
                                 default = nil)
  if valid_603521 != nil:
    section.add "X-Amz-Content-Sha256", valid_603521
  var valid_603522 = header.getOrDefault("X-Amz-Algorithm")
  valid_603522 = validateParameter(valid_603522, JString, required = false,
                                 default = nil)
  if valid_603522 != nil:
    section.add "X-Amz-Algorithm", valid_603522
  var valid_603523 = header.getOrDefault("X-Amz-Signature")
  valid_603523 = validateParameter(valid_603523, JString, required = false,
                                 default = nil)
  if valid_603523 != nil:
    section.add "X-Amz-Signature", valid_603523
  var valid_603524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603524 = validateParameter(valid_603524, JString, required = false,
                                 default = nil)
  if valid_603524 != nil:
    section.add "X-Amz-SignedHeaders", valid_603524
  var valid_603525 = header.getOrDefault("X-Amz-Credential")
  valid_603525 = validateParameter(valid_603525, JString, required = false,
                                 default = nil)
  if valid_603525 != nil:
    section.add "X-Amz-Credential", valid_603525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603526: Call_GetSlotType_603514; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a specific version of a slot type. In addition to specifying the slot type name, you must specify the slot type version.</p> <p>This operation requires permissions for the <code>lex:GetSlotType</code> action.</p>
  ## 
  let valid = call_603526.validator(path, query, header, formData, body)
  let scheme = call_603526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603526.url(scheme.get, call_603526.host, call_603526.base,
                         call_603526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603526, url, valid)

proc call*(call_603527: Call_GetSlotType_603514; name: string; version: string): Recallable =
  ## getSlotType
  ## <p>Returns information about a specific version of a slot type. In addition to specifying the slot type name, you must specify the slot type version.</p> <p>This operation requires permissions for the <code>lex:GetSlotType</code> action.</p>
  ##   name: string (required)
  ##       : The name of the slot type. The name is case sensitive. 
  ##   version: string (required)
  ##          : The version of the slot type. 
  var path_603528 = newJObject()
  add(path_603528, "name", newJString(name))
  add(path_603528, "version", newJString(version))
  result = call_603527.call(path_603528, nil, nil, nil, nil)

var getSlotType* = Call_GetSlotType_603514(name: "getSlotType",
                                        meth: HttpMethod.HttpGet,
                                        host: "models.lex.amazonaws.com", route: "/slottypes/{name}/versions/{version}",
                                        validator: validate_GetSlotType_603515,
                                        base: "/", url: url_GetSlotType_603516,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSlotTypeVersions_603529 = ref object of OpenApiRestCall_602467
proc url_GetSlotTypeVersions_603531(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/slottypes/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/versions/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetSlotTypeVersions_603530(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Gets information about all versions of a slot type.</p> <p>The <code>GetSlotTypeVersions</code> operation returns a <code>SlotTypeMetadata</code> object for each version of a slot type. For example, if a slot type has three numbered versions, the <code>GetSlotTypeVersions</code> operation returns four <code>SlotTypeMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetSlotTypeVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetSlotTypeVersions</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the slot type for which versions should be returned.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_603532 = path.getOrDefault("name")
  valid_603532 = validateParameter(valid_603532, JString, required = true,
                                 default = nil)
  if valid_603532 != nil:
    section.add "name", valid_603532
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of slot type versions to return in the response. The default is 10.
  ##   nextToken: JString
  ##            : A pagination token for fetching the next page of slot type versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  section = newJObject()
  var valid_603533 = query.getOrDefault("maxResults")
  valid_603533 = validateParameter(valid_603533, JInt, required = false, default = nil)
  if valid_603533 != nil:
    section.add "maxResults", valid_603533
  var valid_603534 = query.getOrDefault("nextToken")
  valid_603534 = validateParameter(valid_603534, JString, required = false,
                                 default = nil)
  if valid_603534 != nil:
    section.add "nextToken", valid_603534
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603535 = header.getOrDefault("X-Amz-Date")
  valid_603535 = validateParameter(valid_603535, JString, required = false,
                                 default = nil)
  if valid_603535 != nil:
    section.add "X-Amz-Date", valid_603535
  var valid_603536 = header.getOrDefault("X-Amz-Security-Token")
  valid_603536 = validateParameter(valid_603536, JString, required = false,
                                 default = nil)
  if valid_603536 != nil:
    section.add "X-Amz-Security-Token", valid_603536
  var valid_603537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603537 = validateParameter(valid_603537, JString, required = false,
                                 default = nil)
  if valid_603537 != nil:
    section.add "X-Amz-Content-Sha256", valid_603537
  var valid_603538 = header.getOrDefault("X-Amz-Algorithm")
  valid_603538 = validateParameter(valid_603538, JString, required = false,
                                 default = nil)
  if valid_603538 != nil:
    section.add "X-Amz-Algorithm", valid_603538
  var valid_603539 = header.getOrDefault("X-Amz-Signature")
  valid_603539 = validateParameter(valid_603539, JString, required = false,
                                 default = nil)
  if valid_603539 != nil:
    section.add "X-Amz-Signature", valid_603539
  var valid_603540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603540 = validateParameter(valid_603540, JString, required = false,
                                 default = nil)
  if valid_603540 != nil:
    section.add "X-Amz-SignedHeaders", valid_603540
  var valid_603541 = header.getOrDefault("X-Amz-Credential")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Credential", valid_603541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603542: Call_GetSlotTypeVersions_603529; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about all versions of a slot type.</p> <p>The <code>GetSlotTypeVersions</code> operation returns a <code>SlotTypeMetadata</code> object for each version of a slot type. For example, if a slot type has three numbered versions, the <code>GetSlotTypeVersions</code> operation returns four <code>SlotTypeMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetSlotTypeVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetSlotTypeVersions</code> action.</p>
  ## 
  let valid = call_603542.validator(path, query, header, formData, body)
  let scheme = call_603542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603542.url(scheme.get, call_603542.host, call_603542.base,
                         call_603542.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603542, url, valid)

proc call*(call_603543: Call_GetSlotTypeVersions_603529; name: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## getSlotTypeVersions
  ## <p>Gets information about all versions of a slot type.</p> <p>The <code>GetSlotTypeVersions</code> operation returns a <code>SlotTypeMetadata</code> object for each version of a slot type. For example, if a slot type has three numbered versions, the <code>GetSlotTypeVersions</code> operation returns four <code>SlotTypeMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetSlotTypeVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetSlotTypeVersions</code> action.</p>
  ##   name: string (required)
  ##       : The name of the slot type for which versions should be returned.
  ##   maxResults: int
  ##             : The maximum number of slot type versions to return in the response. The default is 10.
  ##   nextToken: string
  ##            : A pagination token for fetching the next page of slot type versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  var path_603544 = newJObject()
  var query_603545 = newJObject()
  add(path_603544, "name", newJString(name))
  add(query_603545, "maxResults", newJInt(maxResults))
  add(query_603545, "nextToken", newJString(nextToken))
  result = call_603543.call(path_603544, query_603545, nil, nil, nil)

var getSlotTypeVersions* = Call_GetSlotTypeVersions_603529(
    name: "getSlotTypeVersions", meth: HttpMethod.HttpGet,
    host: "models.lex.amazonaws.com", route: "/slottypes/{name}/versions/",
    validator: validate_GetSlotTypeVersions_603530, base: "/",
    url: url_GetSlotTypeVersions_603531, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSlotTypes_603546 = ref object of OpenApiRestCall_602467
proc url_GetSlotTypes_603548(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSlotTypes_603547(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns slot type information as follows: </p> <ul> <li> <p>If you specify the <code>nameContains</code> field, returns the <code>$LATEST</code> version of all slot types that contain the specified string.</p> </li> <li> <p> If you don't specify the <code>nameContains</code> field, returns information about the <code>$LATEST</code> version of all slot types. </p> </li> </ul> <p> The operation requires permission for the <code>lex:GetSlotTypes</code> action. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of slot types to return in the response. The default is 10.
  ##   nextToken: JString
  ##            : A pagination token that fetches the next page of slot types. If the response to this API call is truncated, Amazon Lex returns a pagination token in the response. To fetch next page of slot types, specify the pagination token in the next request.
  ##   nameContains: JString
  ##               : Substring to match in slot type names. A slot type will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  section = newJObject()
  var valid_603549 = query.getOrDefault("maxResults")
  valid_603549 = validateParameter(valid_603549, JInt, required = false, default = nil)
  if valid_603549 != nil:
    section.add "maxResults", valid_603549
  var valid_603550 = query.getOrDefault("nextToken")
  valid_603550 = validateParameter(valid_603550, JString, required = false,
                                 default = nil)
  if valid_603550 != nil:
    section.add "nextToken", valid_603550
  var valid_603551 = query.getOrDefault("nameContains")
  valid_603551 = validateParameter(valid_603551, JString, required = false,
                                 default = nil)
  if valid_603551 != nil:
    section.add "nameContains", valid_603551
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603552 = header.getOrDefault("X-Amz-Date")
  valid_603552 = validateParameter(valid_603552, JString, required = false,
                                 default = nil)
  if valid_603552 != nil:
    section.add "X-Amz-Date", valid_603552
  var valid_603553 = header.getOrDefault("X-Amz-Security-Token")
  valid_603553 = validateParameter(valid_603553, JString, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "X-Amz-Security-Token", valid_603553
  var valid_603554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603554 = validateParameter(valid_603554, JString, required = false,
                                 default = nil)
  if valid_603554 != nil:
    section.add "X-Amz-Content-Sha256", valid_603554
  var valid_603555 = header.getOrDefault("X-Amz-Algorithm")
  valid_603555 = validateParameter(valid_603555, JString, required = false,
                                 default = nil)
  if valid_603555 != nil:
    section.add "X-Amz-Algorithm", valid_603555
  var valid_603556 = header.getOrDefault("X-Amz-Signature")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "X-Amz-Signature", valid_603556
  var valid_603557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603557 = validateParameter(valid_603557, JString, required = false,
                                 default = nil)
  if valid_603557 != nil:
    section.add "X-Amz-SignedHeaders", valid_603557
  var valid_603558 = header.getOrDefault("X-Amz-Credential")
  valid_603558 = validateParameter(valid_603558, JString, required = false,
                                 default = nil)
  if valid_603558 != nil:
    section.add "X-Amz-Credential", valid_603558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603559: Call_GetSlotTypes_603546; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns slot type information as follows: </p> <ul> <li> <p>If you specify the <code>nameContains</code> field, returns the <code>$LATEST</code> version of all slot types that contain the specified string.</p> </li> <li> <p> If you don't specify the <code>nameContains</code> field, returns information about the <code>$LATEST</code> version of all slot types. </p> </li> </ul> <p> The operation requires permission for the <code>lex:GetSlotTypes</code> action. </p>
  ## 
  let valid = call_603559.validator(path, query, header, formData, body)
  let scheme = call_603559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603559.url(scheme.get, call_603559.host, call_603559.base,
                         call_603559.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603559, url, valid)

proc call*(call_603560: Call_GetSlotTypes_603546; maxResults: int = 0;
          nextToken: string = ""; nameContains: string = ""): Recallable =
  ## getSlotTypes
  ## <p>Returns slot type information as follows: </p> <ul> <li> <p>If you specify the <code>nameContains</code> field, returns the <code>$LATEST</code> version of all slot types that contain the specified string.</p> </li> <li> <p> If you don't specify the <code>nameContains</code> field, returns information about the <code>$LATEST</code> version of all slot types. </p> </li> </ul> <p> The operation requires permission for the <code>lex:GetSlotTypes</code> action. </p>
  ##   maxResults: int
  ##             : The maximum number of slot types to return in the response. The default is 10.
  ##   nextToken: string
  ##            : A pagination token that fetches the next page of slot types. If the response to this API call is truncated, Amazon Lex returns a pagination token in the response. To fetch next page of slot types, specify the pagination token in the next request.
  ##   nameContains: string
  ##               : Substring to match in slot type names. A slot type will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  var query_603561 = newJObject()
  add(query_603561, "maxResults", newJInt(maxResults))
  add(query_603561, "nextToken", newJString(nextToken))
  add(query_603561, "nameContains", newJString(nameContains))
  result = call_603560.call(nil, query_603561, nil, nil, nil)

var getSlotTypes* = Call_GetSlotTypes_603546(name: "getSlotTypes",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/slottypes/", validator: validate_GetSlotTypes_603547, base: "/",
    url: url_GetSlotTypes_603548, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUtterancesView_603562 = ref object of OpenApiRestCall_602467
proc url_GetUtterancesView_603564(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "botname" in path, "`botname` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/bots/"),
               (kind: VariableSegment, value: "botname"), (kind: ConstantSegment,
        value: "/utterances#view=aggregation&bot_versions&status_type")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_GetUtterancesView_603563(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Use the <code>GetUtterancesView</code> operation to get information about the utterances that your users have made to your bot. You can use this list to tune the utterances that your bot responds to.</p> <p>For example, say that you have created a bot to order flowers. After your users have used your bot for a while, use the <code>GetUtterancesView</code> operation to see the requests that they have made and whether they have been successful. You might find that the utterance "I want flowers" is not being recognized. You could add this utterance to the <code>OrderFlowers</code> intent so that your bot recognizes that utterance.</p> <p>After you publish a new version of a bot, you can get information about the old version and the new so that you can compare the performance across the two versions. </p> <note> <p>Utterance statistics are generated once a day. Data is available for the last 15 days. You can request information for up to 5 versions in each request. The response contains information about a maximum of 100 utterances for each version.</p> </note> <p>This operation requires permissions for the <code>lex:GetUtterancesView</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   botname: JString (required)
  ##          : The name of the bot for which utterance information should be returned.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `botname` field"
  var valid_603565 = path.getOrDefault("botname")
  valid_603565 = validateParameter(valid_603565, JString, required = true,
                                 default = nil)
  if valid_603565 != nil:
    section.add "botname", valid_603565
  result.add "path", section
  ## parameters in `query` object:
  ##   view: JString (required)
  ##   status_type: JString (required)
  ##              : To return utterances that were recognized and handled, use<code>Detected</code>. To return utterances that were not recognized, use <code>Missed</code>.
  ##   bot_versions: JArray (required)
  ##               : An array of bot versions for which utterance information should be returned. The limit is 5 versions per request.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `view` field"
  var valid_603566 = query.getOrDefault("view")
  valid_603566 = validateParameter(valid_603566, JString, required = true,
                                 default = newJString("aggregation"))
  if valid_603566 != nil:
    section.add "view", valid_603566
  var valid_603567 = query.getOrDefault("status_type")
  valid_603567 = validateParameter(valid_603567, JString, required = true,
                                 default = newJString("Detected"))
  if valid_603567 != nil:
    section.add "status_type", valid_603567
  var valid_603568 = query.getOrDefault("bot_versions")
  valid_603568 = validateParameter(valid_603568, JArray, required = true, default = nil)
  if valid_603568 != nil:
    section.add "bot_versions", valid_603568
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603569 = header.getOrDefault("X-Amz-Date")
  valid_603569 = validateParameter(valid_603569, JString, required = false,
                                 default = nil)
  if valid_603569 != nil:
    section.add "X-Amz-Date", valid_603569
  var valid_603570 = header.getOrDefault("X-Amz-Security-Token")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = nil)
  if valid_603570 != nil:
    section.add "X-Amz-Security-Token", valid_603570
  var valid_603571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-Content-Sha256", valid_603571
  var valid_603572 = header.getOrDefault("X-Amz-Algorithm")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "X-Amz-Algorithm", valid_603572
  var valid_603573 = header.getOrDefault("X-Amz-Signature")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-Signature", valid_603573
  var valid_603574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-SignedHeaders", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-Credential")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-Credential", valid_603575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603576: Call_GetUtterancesView_603562; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use the <code>GetUtterancesView</code> operation to get information about the utterances that your users have made to your bot. You can use this list to tune the utterances that your bot responds to.</p> <p>For example, say that you have created a bot to order flowers. After your users have used your bot for a while, use the <code>GetUtterancesView</code> operation to see the requests that they have made and whether they have been successful. You might find that the utterance "I want flowers" is not being recognized. You could add this utterance to the <code>OrderFlowers</code> intent so that your bot recognizes that utterance.</p> <p>After you publish a new version of a bot, you can get information about the old version and the new so that you can compare the performance across the two versions. </p> <note> <p>Utterance statistics are generated once a day. Data is available for the last 15 days. You can request information for up to 5 versions in each request. The response contains information about a maximum of 100 utterances for each version.</p> </note> <p>This operation requires permissions for the <code>lex:GetUtterancesView</code> action.</p>
  ## 
  let valid = call_603576.validator(path, query, header, formData, body)
  let scheme = call_603576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603576.url(scheme.get, call_603576.host, call_603576.base,
                         call_603576.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603576, url, valid)

proc call*(call_603577: Call_GetUtterancesView_603562; botVersions: JsonNode;
          botname: string; view: string = "aggregation";
          statusType: string = "Detected"): Recallable =
  ## getUtterancesView
  ## <p>Use the <code>GetUtterancesView</code> operation to get information about the utterances that your users have made to your bot. You can use this list to tune the utterances that your bot responds to.</p> <p>For example, say that you have created a bot to order flowers. After your users have used your bot for a while, use the <code>GetUtterancesView</code> operation to see the requests that they have made and whether they have been successful. You might find that the utterance "I want flowers" is not being recognized. You could add this utterance to the <code>OrderFlowers</code> intent so that your bot recognizes that utterance.</p> <p>After you publish a new version of a bot, you can get information about the old version and the new so that you can compare the performance across the two versions. </p> <note> <p>Utterance statistics are generated once a day. Data is available for the last 15 days. You can request information for up to 5 versions in each request. The response contains information about a maximum of 100 utterances for each version.</p> </note> <p>This operation requires permissions for the <code>lex:GetUtterancesView</code> action.</p>
  ##   view: string (required)
  ##   statusType: string (required)
  ##             : To return utterances that were recognized and handled, use<code>Detected</code>. To return utterances that were not recognized, use <code>Missed</code>.
  ##   botVersions: JArray (required)
  ##              : An array of bot versions for which utterance information should be returned. The limit is 5 versions per request.
  ##   botname: string (required)
  ##          : The name of the bot for which utterance information should be returned.
  var path_603578 = newJObject()
  var query_603579 = newJObject()
  add(query_603579, "view", newJString(view))
  add(query_603579, "status_type", newJString(statusType))
  if botVersions != nil:
    query_603579.add "bot_versions", botVersions
  add(path_603578, "botname", newJString(botname))
  result = call_603577.call(path_603578, query_603579, nil, nil, nil)

var getUtterancesView* = Call_GetUtterancesView_603562(name: "getUtterancesView",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com", route: "/bots/{botname}/utterances#view=aggregation&bot_versions&status_type",
    validator: validate_GetUtterancesView_603563, base: "/",
    url: url_GetUtterancesView_603564, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBot_603580 = ref object of OpenApiRestCall_602467
proc url_PutBot_603582(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/bots/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/versions/$LATEST")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutBot_603581(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an Amazon Lex conversational bot or replaces an existing bot. When you create or update a bot you are only required to specify a name, a locale, and whether the bot is directed toward children under age 13. You can use this to add intents later, or to remove intents from an existing bot. When you create a bot with the minimum information, the bot is created or updated but Amazon Lex returns the <code/> response <code>FAILED</code>. You can build the bot after you add one or more intents. For more information about Amazon Lex bots, see <a>how-it-works</a>. </p> <p>If you specify the name of an existing bot, the fields in the request replace the existing values in the <code>$LATEST</code> version of the bot. Amazon Lex removes any fields that you don't provide values for in the request, except for the <code>idleTTLInSeconds</code> and <code>privacySettings</code> fields, which are set to their default values. If you don't specify values for required fields, Amazon Lex throws an exception.</p> <p>This operation requires permissions for the <code>lex:PutBot</code> action. For more information, see <a>auth-and-access-control</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the bot. The name is <i>not</i> case sensitive. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_603583 = path.getOrDefault("name")
  valid_603583 = validateParameter(valid_603583, JString, required = true,
                                 default = nil)
  if valid_603583 != nil:
    section.add "name", valid_603583
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603584 = header.getOrDefault("X-Amz-Date")
  valid_603584 = validateParameter(valid_603584, JString, required = false,
                                 default = nil)
  if valid_603584 != nil:
    section.add "X-Amz-Date", valid_603584
  var valid_603585 = header.getOrDefault("X-Amz-Security-Token")
  valid_603585 = validateParameter(valid_603585, JString, required = false,
                                 default = nil)
  if valid_603585 != nil:
    section.add "X-Amz-Security-Token", valid_603585
  var valid_603586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Content-Sha256", valid_603586
  var valid_603587 = header.getOrDefault("X-Amz-Algorithm")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-Algorithm", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-Signature")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-Signature", valid_603588
  var valid_603589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-SignedHeaders", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-Credential")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Credential", valid_603590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603592: Call_PutBot_603580; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon Lex conversational bot or replaces an existing bot. When you create or update a bot you are only required to specify a name, a locale, and whether the bot is directed toward children under age 13. You can use this to add intents later, or to remove intents from an existing bot. When you create a bot with the minimum information, the bot is created or updated but Amazon Lex returns the <code/> response <code>FAILED</code>. You can build the bot after you add one or more intents. For more information about Amazon Lex bots, see <a>how-it-works</a>. </p> <p>If you specify the name of an existing bot, the fields in the request replace the existing values in the <code>$LATEST</code> version of the bot. Amazon Lex removes any fields that you don't provide values for in the request, except for the <code>idleTTLInSeconds</code> and <code>privacySettings</code> fields, which are set to their default values. If you don't specify values for required fields, Amazon Lex throws an exception.</p> <p>This operation requires permissions for the <code>lex:PutBot</code> action. For more information, see <a>auth-and-access-control</a>.</p>
  ## 
  let valid = call_603592.validator(path, query, header, formData, body)
  let scheme = call_603592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603592.url(scheme.get, call_603592.host, call_603592.base,
                         call_603592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603592, url, valid)

proc call*(call_603593: Call_PutBot_603580; name: string; body: JsonNode): Recallable =
  ## putBot
  ## <p>Creates an Amazon Lex conversational bot or replaces an existing bot. When you create or update a bot you are only required to specify a name, a locale, and whether the bot is directed toward children under age 13. You can use this to add intents later, or to remove intents from an existing bot. When you create a bot with the minimum information, the bot is created or updated but Amazon Lex returns the <code/> response <code>FAILED</code>. You can build the bot after you add one or more intents. For more information about Amazon Lex bots, see <a>how-it-works</a>. </p> <p>If you specify the name of an existing bot, the fields in the request replace the existing values in the <code>$LATEST</code> version of the bot. Amazon Lex removes any fields that you don't provide values for in the request, except for the <code>idleTTLInSeconds</code> and <code>privacySettings</code> fields, which are set to their default values. If you don't specify values for required fields, Amazon Lex throws an exception.</p> <p>This operation requires permissions for the <code>lex:PutBot</code> action. For more information, see <a>auth-and-access-control</a>.</p>
  ##   name: string (required)
  ##       : The name of the bot. The name is <i>not</i> case sensitive. 
  ##   body: JObject (required)
  var path_603594 = newJObject()
  var body_603595 = newJObject()
  add(path_603594, "name", newJString(name))
  if body != nil:
    body_603595 = body
  result = call_603593.call(path_603594, nil, nil, nil, body_603595)

var putBot* = Call_PutBot_603580(name: "putBot", meth: HttpMethod.HttpPut,
                              host: "models.lex.amazonaws.com",
                              route: "/bots/{name}/versions/$LATEST",
                              validator: validate_PutBot_603581, base: "/",
                              url: url_PutBot_603582,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutIntent_603596 = ref object of OpenApiRestCall_602467
proc url_PutIntent_603598(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/intents/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/versions/$LATEST")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutIntent_603597(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an intent or replaces an existing intent.</p> <p>To define the interaction between the user and your bot, you use one or more intents. For a pizza ordering bot, for example, you would create an <code>OrderPizza</code> intent. </p> <p>To create an intent or replace an existing intent, you must provide the following:</p> <ul> <li> <p>Intent name. For example, <code>OrderPizza</code>.</p> </li> <li> <p>Sample utterances. For example, "Can I order a pizza, please." and "I want to order a pizza."</p> </li> <li> <p>Information to be gathered. You specify slot types for the information that your bot will request from the user. You can specify standard slot types, such as a date or a time, or custom slot types such as the size and crust of a pizza.</p> </li> <li> <p>How the intent will be fulfilled. You can provide a Lambda function or configure the intent to return the intent information to the client application. If you use a Lambda function, when all of the intent information is available, Amazon Lex invokes your Lambda function. If you configure your intent to return the intent information to the client application. </p> </li> </ul> <p>You can specify other optional information in the request, such as:</p> <ul> <li> <p>A confirmation prompt to ask the user to confirm an intent. For example, "Shall I order your pizza?"</p> </li> <li> <p>A conclusion statement to send to the user after the intent has been fulfilled. For example, "I placed your pizza order."</p> </li> <li> <p>A follow-up prompt that asks the user for additional activity. For example, asking "Do you want to order a drink with your pizza?"</p> </li> </ul> <p>If you specify an existing intent name to update the intent, Amazon Lex replaces the values in the <code>$LATEST</code> version of the intent with the values in the request. Amazon Lex removes fields that you don't provide in the request. If you don't specify the required fields, Amazon Lex throws an exception. When you update the <code>$LATEST</code> version of an intent, the <code>status</code> field of any bot that uses the <code>$LATEST</code> version of the intent is set to <code>NOT_BUILT</code>.</p> <p>For more information, see <a>how-it-works</a>.</p> <p>This operation requires permissions for the <code>lex:PutIntent</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : <p>The name of the intent. The name is <i>not</i> case sensitive. </p> <p>The name can't match a built-in intent name, or a built-in intent name with "AMAZON." removed. For example, because there is a built-in intent called <code>AMAZON.HelpIntent</code>, you can't create a custom intent called <code>HelpIntent</code>.</p> <p>For a list of built-in intents, see <a 
  ## href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/standard-intents">Standard Built-in Intents</a> in the <i>Alexa Skills Kit</i>.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_603599 = path.getOrDefault("name")
  valid_603599 = validateParameter(valid_603599, JString, required = true,
                                 default = nil)
  if valid_603599 != nil:
    section.add "name", valid_603599
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603600 = header.getOrDefault("X-Amz-Date")
  valid_603600 = validateParameter(valid_603600, JString, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "X-Amz-Date", valid_603600
  var valid_603601 = header.getOrDefault("X-Amz-Security-Token")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "X-Amz-Security-Token", valid_603601
  var valid_603602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "X-Amz-Content-Sha256", valid_603602
  var valid_603603 = header.getOrDefault("X-Amz-Algorithm")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "X-Amz-Algorithm", valid_603603
  var valid_603604 = header.getOrDefault("X-Amz-Signature")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "X-Amz-Signature", valid_603604
  var valid_603605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-SignedHeaders", valid_603605
  var valid_603606 = header.getOrDefault("X-Amz-Credential")
  valid_603606 = validateParameter(valid_603606, JString, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "X-Amz-Credential", valid_603606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603608: Call_PutIntent_603596; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an intent or replaces an existing intent.</p> <p>To define the interaction between the user and your bot, you use one or more intents. For a pizza ordering bot, for example, you would create an <code>OrderPizza</code> intent. </p> <p>To create an intent or replace an existing intent, you must provide the following:</p> <ul> <li> <p>Intent name. For example, <code>OrderPizza</code>.</p> </li> <li> <p>Sample utterances. For example, "Can I order a pizza, please." and "I want to order a pizza."</p> </li> <li> <p>Information to be gathered. You specify slot types for the information that your bot will request from the user. You can specify standard slot types, such as a date or a time, or custom slot types such as the size and crust of a pizza.</p> </li> <li> <p>How the intent will be fulfilled. You can provide a Lambda function or configure the intent to return the intent information to the client application. If you use a Lambda function, when all of the intent information is available, Amazon Lex invokes your Lambda function. If you configure your intent to return the intent information to the client application. </p> </li> </ul> <p>You can specify other optional information in the request, such as:</p> <ul> <li> <p>A confirmation prompt to ask the user to confirm an intent. For example, "Shall I order your pizza?"</p> </li> <li> <p>A conclusion statement to send to the user after the intent has been fulfilled. For example, "I placed your pizza order."</p> </li> <li> <p>A follow-up prompt that asks the user for additional activity. For example, asking "Do you want to order a drink with your pizza?"</p> </li> </ul> <p>If you specify an existing intent name to update the intent, Amazon Lex replaces the values in the <code>$LATEST</code> version of the intent with the values in the request. Amazon Lex removes fields that you don't provide in the request. If you don't specify the required fields, Amazon Lex throws an exception. When you update the <code>$LATEST</code> version of an intent, the <code>status</code> field of any bot that uses the <code>$LATEST</code> version of the intent is set to <code>NOT_BUILT</code>.</p> <p>For more information, see <a>how-it-works</a>.</p> <p>This operation requires permissions for the <code>lex:PutIntent</code> action.</p>
  ## 
  let valid = call_603608.validator(path, query, header, formData, body)
  let scheme = call_603608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603608.url(scheme.get, call_603608.host, call_603608.base,
                         call_603608.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603608, url, valid)

proc call*(call_603609: Call_PutIntent_603596; name: string; body: JsonNode): Recallable =
  ## putIntent
  ## <p>Creates an intent or replaces an existing intent.</p> <p>To define the interaction between the user and your bot, you use one or more intents. For a pizza ordering bot, for example, you would create an <code>OrderPizza</code> intent. </p> <p>To create an intent or replace an existing intent, you must provide the following:</p> <ul> <li> <p>Intent name. For example, <code>OrderPizza</code>.</p> </li> <li> <p>Sample utterances. For example, "Can I order a pizza, please." and "I want to order a pizza."</p> </li> <li> <p>Information to be gathered. You specify slot types for the information that your bot will request from the user. You can specify standard slot types, such as a date or a time, or custom slot types such as the size and crust of a pizza.</p> </li> <li> <p>How the intent will be fulfilled. You can provide a Lambda function or configure the intent to return the intent information to the client application. If you use a Lambda function, when all of the intent information is available, Amazon Lex invokes your Lambda function. If you configure your intent to return the intent information to the client application. </p> </li> </ul> <p>You can specify other optional information in the request, such as:</p> <ul> <li> <p>A confirmation prompt to ask the user to confirm an intent. For example, "Shall I order your pizza?"</p> </li> <li> <p>A conclusion statement to send to the user after the intent has been fulfilled. For example, "I placed your pizza order."</p> </li> <li> <p>A follow-up prompt that asks the user for additional activity. For example, asking "Do you want to order a drink with your pizza?"</p> </li> </ul> <p>If you specify an existing intent name to update the intent, Amazon Lex replaces the values in the <code>$LATEST</code> version of the intent with the values in the request. Amazon Lex removes fields that you don't provide in the request. If you don't specify the required fields, Amazon Lex throws an exception. When you update the <code>$LATEST</code> version of an intent, the <code>status</code> field of any bot that uses the <code>$LATEST</code> version of the intent is set to <code>NOT_BUILT</code>.</p> <p>For more information, see <a>how-it-works</a>.</p> <p>This operation requires permissions for the <code>lex:PutIntent</code> action.</p>
  ##   name: string (required)
  ##       : <p>The name of the intent. The name is <i>not</i> case sensitive. </p> <p>The name can't match a built-in intent name, or a built-in intent name with "AMAZON." removed. For example, because there is a built-in intent called <code>AMAZON.HelpIntent</code>, you can't create a custom intent called <code>HelpIntent</code>.</p> <p>For a list of built-in intents, see <a 
  ## href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/standard-intents">Standard Built-in Intents</a> in the <i>Alexa Skills Kit</i>.</p>
  ##   body: JObject (required)
  var path_603610 = newJObject()
  var body_603611 = newJObject()
  add(path_603610, "name", newJString(name))
  if body != nil:
    body_603611 = body
  result = call_603609.call(path_603610, nil, nil, nil, body_603611)

var putIntent* = Call_PutIntent_603596(name: "putIntent", meth: HttpMethod.HttpPut,
                                    host: "models.lex.amazonaws.com",
                                    route: "/intents/{name}/versions/$LATEST",
                                    validator: validate_PutIntent_603597,
                                    base: "/", url: url_PutIntent_603598,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSlotType_603612 = ref object of OpenApiRestCall_602467
proc url_PutSlotType_603614(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/slottypes/"),
               (kind: VariableSegment, value: "name"),
               (kind: ConstantSegment, value: "/versions/$LATEST")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_PutSlotType_603613(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a custom slot type or replaces an existing custom slot type.</p> <p>To create a custom slot type, specify a name for the slot type and a set of enumeration values, which are the values that a slot of this type can assume. For more information, see <a>how-it-works</a>.</p> <p>If you specify the name of an existing slot type, the fields in the request replace the existing values in the <code>$LATEST</code> version of the slot type. Amazon Lex removes the fields that you don't provide in the request. If you don't specify required fields, Amazon Lex throws an exception. When you update the <code>$LATEST</code> version of a slot type, if a bot uses the <code>$LATEST</code> version of an intent that contains the slot type, the bot's <code>status</code> field is set to <code>NOT_BUILT</code>.</p> <p>This operation requires permissions for the <code>lex:PutSlotType</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : <p>The name of the slot type. The name is <i>not</i> case sensitive. </p> <p>The name can't match a built-in slot type name, or a built-in slot type name with "AMAZON." removed. For example, because there is a built-in slot type called <code>AMAZON.DATE</code>, you can't create a custom slot type called <code>DATE</code>.</p> <p>For a list of built-in slot types, see <a 
  ## href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/slot-type-reference">Slot Type Reference</a> in the <i>Alexa Skills Kit</i>.</p>
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_603615 = path.getOrDefault("name")
  valid_603615 = validateParameter(valid_603615, JString, required = true,
                                 default = nil)
  if valid_603615 != nil:
    section.add "name", valid_603615
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603616 = header.getOrDefault("X-Amz-Date")
  valid_603616 = validateParameter(valid_603616, JString, required = false,
                                 default = nil)
  if valid_603616 != nil:
    section.add "X-Amz-Date", valid_603616
  var valid_603617 = header.getOrDefault("X-Amz-Security-Token")
  valid_603617 = validateParameter(valid_603617, JString, required = false,
                                 default = nil)
  if valid_603617 != nil:
    section.add "X-Amz-Security-Token", valid_603617
  var valid_603618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "X-Amz-Content-Sha256", valid_603618
  var valid_603619 = header.getOrDefault("X-Amz-Algorithm")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-Algorithm", valid_603619
  var valid_603620 = header.getOrDefault("X-Amz-Signature")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-Signature", valid_603620
  var valid_603621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "X-Amz-SignedHeaders", valid_603621
  var valid_603622 = header.getOrDefault("X-Amz-Credential")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "X-Amz-Credential", valid_603622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603624: Call_PutSlotType_603612; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a custom slot type or replaces an existing custom slot type.</p> <p>To create a custom slot type, specify a name for the slot type and a set of enumeration values, which are the values that a slot of this type can assume. For more information, see <a>how-it-works</a>.</p> <p>If you specify the name of an existing slot type, the fields in the request replace the existing values in the <code>$LATEST</code> version of the slot type. Amazon Lex removes the fields that you don't provide in the request. If you don't specify required fields, Amazon Lex throws an exception. When you update the <code>$LATEST</code> version of a slot type, if a bot uses the <code>$LATEST</code> version of an intent that contains the slot type, the bot's <code>status</code> field is set to <code>NOT_BUILT</code>.</p> <p>This operation requires permissions for the <code>lex:PutSlotType</code> action.</p>
  ## 
  let valid = call_603624.validator(path, query, header, formData, body)
  let scheme = call_603624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603624.url(scheme.get, call_603624.host, call_603624.base,
                         call_603624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603624, url, valid)

proc call*(call_603625: Call_PutSlotType_603612; name: string; body: JsonNode): Recallable =
  ## putSlotType
  ## <p>Creates a custom slot type or replaces an existing custom slot type.</p> <p>To create a custom slot type, specify a name for the slot type and a set of enumeration values, which are the values that a slot of this type can assume. For more information, see <a>how-it-works</a>.</p> <p>If you specify the name of an existing slot type, the fields in the request replace the existing values in the <code>$LATEST</code> version of the slot type. Amazon Lex removes the fields that you don't provide in the request. If you don't specify required fields, Amazon Lex throws an exception. When you update the <code>$LATEST</code> version of a slot type, if a bot uses the <code>$LATEST</code> version of an intent that contains the slot type, the bot's <code>status</code> field is set to <code>NOT_BUILT</code>.</p> <p>This operation requires permissions for the <code>lex:PutSlotType</code> action.</p>
  ##   name: string (required)
  ##       : <p>The name of the slot type. The name is <i>not</i> case sensitive. </p> <p>The name can't match a built-in slot type name, or a built-in slot type name with "AMAZON." removed. For example, because there is a built-in slot type called <code>AMAZON.DATE</code>, you can't create a custom slot type called <code>DATE</code>.</p> <p>For a list of built-in slot types, see <a 
  ## href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/slot-type-reference">Slot Type Reference</a> in the <i>Alexa Skills Kit</i>.</p>
  ##   body: JObject (required)
  var path_603626 = newJObject()
  var body_603627 = newJObject()
  add(path_603626, "name", newJString(name))
  if body != nil:
    body_603627 = body
  result = call_603625.call(path_603626, nil, nil, nil, body_603627)

var putSlotType* = Call_PutSlotType_603612(name: "putSlotType",
                                        meth: HttpMethod.HttpPut,
                                        host: "models.lex.amazonaws.com", route: "/slottypes/{name}/versions/$LATEST",
                                        validator: validate_PutSlotType_603613,
                                        base: "/", url: url_PutSlotType_603614,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImport_603628 = ref object of OpenApiRestCall_602467
proc url_StartImport_603630(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartImport_603629(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts a job to import a resource to Amazon Lex.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603631 = header.getOrDefault("X-Amz-Date")
  valid_603631 = validateParameter(valid_603631, JString, required = false,
                                 default = nil)
  if valid_603631 != nil:
    section.add "X-Amz-Date", valid_603631
  var valid_603632 = header.getOrDefault("X-Amz-Security-Token")
  valid_603632 = validateParameter(valid_603632, JString, required = false,
                                 default = nil)
  if valid_603632 != nil:
    section.add "X-Amz-Security-Token", valid_603632
  var valid_603633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603633 = validateParameter(valid_603633, JString, required = false,
                                 default = nil)
  if valid_603633 != nil:
    section.add "X-Amz-Content-Sha256", valid_603633
  var valid_603634 = header.getOrDefault("X-Amz-Algorithm")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "X-Amz-Algorithm", valid_603634
  var valid_603635 = header.getOrDefault("X-Amz-Signature")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "X-Amz-Signature", valid_603635
  var valid_603636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603636 = validateParameter(valid_603636, JString, required = false,
                                 default = nil)
  if valid_603636 != nil:
    section.add "X-Amz-SignedHeaders", valid_603636
  var valid_603637 = header.getOrDefault("X-Amz-Credential")
  valid_603637 = validateParameter(valid_603637, JString, required = false,
                                 default = nil)
  if valid_603637 != nil:
    section.add "X-Amz-Credential", valid_603637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603639: Call_StartImport_603628; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a job to import a resource to Amazon Lex.
  ## 
  let valid = call_603639.validator(path, query, header, formData, body)
  let scheme = call_603639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603639.url(scheme.get, call_603639.host, call_603639.base,
                         call_603639.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603639, url, valid)

proc call*(call_603640: Call_StartImport_603628; body: JsonNode): Recallable =
  ## startImport
  ## Starts a job to import a resource to Amazon Lex.
  ##   body: JObject (required)
  var body_603641 = newJObject()
  if body != nil:
    body_603641 = body
  result = call_603640.call(nil, nil, nil, nil, body_603641)

var startImport* = Call_StartImport_603628(name: "startImport",
                                        meth: HttpMethod.HttpPost,
                                        host: "models.lex.amazonaws.com",
                                        route: "/imports/",
                                        validator: validate_StartImport_603629,
                                        base: "/", url: url_StartImport_603630,
                                        schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
