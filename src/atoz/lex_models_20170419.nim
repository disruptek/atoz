
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

  OpenApiRestCall_593438 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593438](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593438): Option[Scheme] {.used.} =
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
  Call_CreateBotVersion_593775 = ref object of OpenApiRestCall_593438
proc url_CreateBotVersion_593777(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBotVersion_593776(path: JsonNode; query: JsonNode;
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
  var valid_593903 = path.getOrDefault("name")
  valid_593903 = validateParameter(valid_593903, JString, required = true,
                                 default = nil)
  if valid_593903 != nil:
    section.add "name", valid_593903
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
  var valid_593904 = header.getOrDefault("X-Amz-Date")
  valid_593904 = validateParameter(valid_593904, JString, required = false,
                                 default = nil)
  if valid_593904 != nil:
    section.add "X-Amz-Date", valid_593904
  var valid_593905 = header.getOrDefault("X-Amz-Security-Token")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "X-Amz-Security-Token", valid_593905
  var valid_593906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "X-Amz-Content-Sha256", valid_593906
  var valid_593907 = header.getOrDefault("X-Amz-Algorithm")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-Algorithm", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-Signature")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-Signature", valid_593908
  var valid_593909 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593909 = validateParameter(valid_593909, JString, required = false,
                                 default = nil)
  if valid_593909 != nil:
    section.add "X-Amz-SignedHeaders", valid_593909
  var valid_593910 = header.getOrDefault("X-Amz-Credential")
  valid_593910 = validateParameter(valid_593910, JString, required = false,
                                 default = nil)
  if valid_593910 != nil:
    section.add "X-Amz-Credential", valid_593910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593934: Call_CreateBotVersion_593775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new version of the bot based on the <code>$LATEST</code> version. If the <code>$LATEST</code> version of this resource hasn't changed since you created the last version, Amazon Lex doesn't create a new version. It returns the last created version.</p> <note> <p>You can update only the <code>$LATEST</code> version of the bot. You can't update the numbered versions that you create with the <code>CreateBotVersion</code> operation.</p> </note> <p> When you create the first version of a bot, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p> This operation requires permission for the <code>lex:CreateBotVersion</code> action. </p>
  ## 
  let valid = call_593934.validator(path, query, header, formData, body)
  let scheme = call_593934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593934.url(scheme.get, call_593934.host, call_593934.base,
                         call_593934.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593934, url, valid)

proc call*(call_594005: Call_CreateBotVersion_593775; name: string; body: JsonNode): Recallable =
  ## createBotVersion
  ## <p>Creates a new version of the bot based on the <code>$LATEST</code> version. If the <code>$LATEST</code> version of this resource hasn't changed since you created the last version, Amazon Lex doesn't create a new version. It returns the last created version.</p> <note> <p>You can update only the <code>$LATEST</code> version of the bot. You can't update the numbered versions that you create with the <code>CreateBotVersion</code> operation.</p> </note> <p> When you create the first version of a bot, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p> This operation requires permission for the <code>lex:CreateBotVersion</code> action. </p>
  ##   name: string (required)
  ##       : The name of the bot that you want to create a new version of. The name is case sensitive. 
  ##   body: JObject (required)
  var path_594006 = newJObject()
  var body_594008 = newJObject()
  add(path_594006, "name", newJString(name))
  if body != nil:
    body_594008 = body
  result = call_594005.call(path_594006, nil, nil, nil, body_594008)

var createBotVersion* = Call_CreateBotVersion_593775(name: "createBotVersion",
    meth: HttpMethod.HttpPost, host: "models.lex.amazonaws.com",
    route: "/bots/{name}/versions", validator: validate_CreateBotVersion_593776,
    base: "/", url: url_CreateBotVersion_593777,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIntentVersion_594047 = ref object of OpenApiRestCall_593438
proc url_CreateIntentVersion_594049(protocol: Scheme; host: string; base: string;
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

proc validate_CreateIntentVersion_594048(path: JsonNode; query: JsonNode;
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
  var valid_594050 = path.getOrDefault("name")
  valid_594050 = validateParameter(valid_594050, JString, required = true,
                                 default = nil)
  if valid_594050 != nil:
    section.add "name", valid_594050
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
  var valid_594051 = header.getOrDefault("X-Amz-Date")
  valid_594051 = validateParameter(valid_594051, JString, required = false,
                                 default = nil)
  if valid_594051 != nil:
    section.add "X-Amz-Date", valid_594051
  var valid_594052 = header.getOrDefault("X-Amz-Security-Token")
  valid_594052 = validateParameter(valid_594052, JString, required = false,
                                 default = nil)
  if valid_594052 != nil:
    section.add "X-Amz-Security-Token", valid_594052
  var valid_594053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Content-Sha256", valid_594053
  var valid_594054 = header.getOrDefault("X-Amz-Algorithm")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "X-Amz-Algorithm", valid_594054
  var valid_594055 = header.getOrDefault("X-Amz-Signature")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-Signature", valid_594055
  var valid_594056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-SignedHeaders", valid_594056
  var valid_594057 = header.getOrDefault("X-Amz-Credential")
  valid_594057 = validateParameter(valid_594057, JString, required = false,
                                 default = nil)
  if valid_594057 != nil:
    section.add "X-Amz-Credential", valid_594057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594059: Call_CreateIntentVersion_594047; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new version of an intent based on the <code>$LATEST</code> version of the intent. If the <code>$LATEST</code> version of this intent hasn't changed since you last updated it, Amazon Lex doesn't create a new version. It returns the last version you created.</p> <note> <p>You can update only the <code>$LATEST</code> version of the intent. You can't update the numbered versions that you create with the <code>CreateIntentVersion</code> operation.</p> </note> <p> When you create a version of an intent, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p>This operation requires permissions to perform the <code>lex:CreateIntentVersion</code> action. </p>
  ## 
  let valid = call_594059.validator(path, query, header, formData, body)
  let scheme = call_594059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594059.url(scheme.get, call_594059.host, call_594059.base,
                         call_594059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594059, url, valid)

proc call*(call_594060: Call_CreateIntentVersion_594047; name: string; body: JsonNode): Recallable =
  ## createIntentVersion
  ## <p>Creates a new version of an intent based on the <code>$LATEST</code> version of the intent. If the <code>$LATEST</code> version of this intent hasn't changed since you last updated it, Amazon Lex doesn't create a new version. It returns the last version you created.</p> <note> <p>You can update only the <code>$LATEST</code> version of the intent. You can't update the numbered versions that you create with the <code>CreateIntentVersion</code> operation.</p> </note> <p> When you create a version of an intent, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p>This operation requires permissions to perform the <code>lex:CreateIntentVersion</code> action. </p>
  ##   name: string (required)
  ##       : The name of the intent that you want to create a new version of. The name is case sensitive. 
  ##   body: JObject (required)
  var path_594061 = newJObject()
  var body_594062 = newJObject()
  add(path_594061, "name", newJString(name))
  if body != nil:
    body_594062 = body
  result = call_594060.call(path_594061, nil, nil, nil, body_594062)

var createIntentVersion* = Call_CreateIntentVersion_594047(
    name: "createIntentVersion", meth: HttpMethod.HttpPost,
    host: "models.lex.amazonaws.com", route: "/intents/{name}/versions",
    validator: validate_CreateIntentVersion_594048, base: "/",
    url: url_CreateIntentVersion_594049, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSlotTypeVersion_594063 = ref object of OpenApiRestCall_593438
proc url_CreateSlotTypeVersion_594065(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSlotTypeVersion_594064(path: JsonNode; query: JsonNode;
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
  var valid_594066 = path.getOrDefault("name")
  valid_594066 = validateParameter(valid_594066, JString, required = true,
                                 default = nil)
  if valid_594066 != nil:
    section.add "name", valid_594066
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
  var valid_594067 = header.getOrDefault("X-Amz-Date")
  valid_594067 = validateParameter(valid_594067, JString, required = false,
                                 default = nil)
  if valid_594067 != nil:
    section.add "X-Amz-Date", valid_594067
  var valid_594068 = header.getOrDefault("X-Amz-Security-Token")
  valid_594068 = validateParameter(valid_594068, JString, required = false,
                                 default = nil)
  if valid_594068 != nil:
    section.add "X-Amz-Security-Token", valid_594068
  var valid_594069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "X-Amz-Content-Sha256", valid_594069
  var valid_594070 = header.getOrDefault("X-Amz-Algorithm")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "X-Amz-Algorithm", valid_594070
  var valid_594071 = header.getOrDefault("X-Amz-Signature")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "X-Amz-Signature", valid_594071
  var valid_594072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594072 = validateParameter(valid_594072, JString, required = false,
                                 default = nil)
  if valid_594072 != nil:
    section.add "X-Amz-SignedHeaders", valid_594072
  var valid_594073 = header.getOrDefault("X-Amz-Credential")
  valid_594073 = validateParameter(valid_594073, JString, required = false,
                                 default = nil)
  if valid_594073 != nil:
    section.add "X-Amz-Credential", valid_594073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594075: Call_CreateSlotTypeVersion_594063; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new version of a slot type based on the <code>$LATEST</code> version of the specified slot type. If the <code>$LATEST</code> version of this resource has not changed since the last version that you created, Amazon Lex doesn't create a new version. It returns the last version that you created. </p> <note> <p>You can update only the <code>$LATEST</code> version of a slot type. You can't update the numbered versions that you create with the <code>CreateSlotTypeVersion</code> operation.</p> </note> <p>When you create a version of a slot type, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p>This operation requires permissions for the <code>lex:CreateSlotTypeVersion</code> action.</p>
  ## 
  let valid = call_594075.validator(path, query, header, formData, body)
  let scheme = call_594075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594075.url(scheme.get, call_594075.host, call_594075.base,
                         call_594075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594075, url, valid)

proc call*(call_594076: Call_CreateSlotTypeVersion_594063; name: string;
          body: JsonNode): Recallable =
  ## createSlotTypeVersion
  ## <p>Creates a new version of a slot type based on the <code>$LATEST</code> version of the specified slot type. If the <code>$LATEST</code> version of this resource has not changed since the last version that you created, Amazon Lex doesn't create a new version. It returns the last version that you created. </p> <note> <p>You can update only the <code>$LATEST</code> version of a slot type. You can't update the numbered versions that you create with the <code>CreateSlotTypeVersion</code> operation.</p> </note> <p>When you create a version of a slot type, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p>This operation requires permissions for the <code>lex:CreateSlotTypeVersion</code> action.</p>
  ##   name: string (required)
  ##       : The name of the slot type that you want to create a new version for. The name is case sensitive. 
  ##   body: JObject (required)
  var path_594077 = newJObject()
  var body_594078 = newJObject()
  add(path_594077, "name", newJString(name))
  if body != nil:
    body_594078 = body
  result = call_594076.call(path_594077, nil, nil, nil, body_594078)

var createSlotTypeVersion* = Call_CreateSlotTypeVersion_594063(
    name: "createSlotTypeVersion", meth: HttpMethod.HttpPost,
    host: "models.lex.amazonaws.com", route: "/slottypes/{name}/versions",
    validator: validate_CreateSlotTypeVersion_594064, base: "/",
    url: url_CreateSlotTypeVersion_594065, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBot_594079 = ref object of OpenApiRestCall_593438
proc url_DeleteBot_594081(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteBot_594080(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594082 = path.getOrDefault("name")
  valid_594082 = validateParameter(valid_594082, JString, required = true,
                                 default = nil)
  if valid_594082 != nil:
    section.add "name", valid_594082
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
  var valid_594083 = header.getOrDefault("X-Amz-Date")
  valid_594083 = validateParameter(valid_594083, JString, required = false,
                                 default = nil)
  if valid_594083 != nil:
    section.add "X-Amz-Date", valid_594083
  var valid_594084 = header.getOrDefault("X-Amz-Security-Token")
  valid_594084 = validateParameter(valid_594084, JString, required = false,
                                 default = nil)
  if valid_594084 != nil:
    section.add "X-Amz-Security-Token", valid_594084
  var valid_594085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594085 = validateParameter(valid_594085, JString, required = false,
                                 default = nil)
  if valid_594085 != nil:
    section.add "X-Amz-Content-Sha256", valid_594085
  var valid_594086 = header.getOrDefault("X-Amz-Algorithm")
  valid_594086 = validateParameter(valid_594086, JString, required = false,
                                 default = nil)
  if valid_594086 != nil:
    section.add "X-Amz-Algorithm", valid_594086
  var valid_594087 = header.getOrDefault("X-Amz-Signature")
  valid_594087 = validateParameter(valid_594087, JString, required = false,
                                 default = nil)
  if valid_594087 != nil:
    section.add "X-Amz-Signature", valid_594087
  var valid_594088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594088 = validateParameter(valid_594088, JString, required = false,
                                 default = nil)
  if valid_594088 != nil:
    section.add "X-Amz-SignedHeaders", valid_594088
  var valid_594089 = header.getOrDefault("X-Amz-Credential")
  valid_594089 = validateParameter(valid_594089, JString, required = false,
                                 default = nil)
  if valid_594089 != nil:
    section.add "X-Amz-Credential", valid_594089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594090: Call_DeleteBot_594079; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes all versions of the bot, including the <code>$LATEST</code> version. To delete a specific version of the bot, use the <a>DeleteBotVersion</a> operation.</p> <p>If a bot has an alias, you can't delete it. Instead, the <code>DeleteBot</code> operation returns a <code>ResourceInUseException</code> exception that includes a reference to the alias that refers to the bot. To remove the reference to the bot, delete the alias. If you get the same exception again, delete the referring alias until the <code>DeleteBot</code> operation is successful.</p> <p>This operation requires permissions for the <code>lex:DeleteBot</code> action.</p>
  ## 
  let valid = call_594090.validator(path, query, header, formData, body)
  let scheme = call_594090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594090.url(scheme.get, call_594090.host, call_594090.base,
                         call_594090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594090, url, valid)

proc call*(call_594091: Call_DeleteBot_594079; name: string): Recallable =
  ## deleteBot
  ## <p>Deletes all versions of the bot, including the <code>$LATEST</code> version. To delete a specific version of the bot, use the <a>DeleteBotVersion</a> operation.</p> <p>If a bot has an alias, you can't delete it. Instead, the <code>DeleteBot</code> operation returns a <code>ResourceInUseException</code> exception that includes a reference to the alias that refers to the bot. To remove the reference to the bot, delete the alias. If you get the same exception again, delete the referring alias until the <code>DeleteBot</code> operation is successful.</p> <p>This operation requires permissions for the <code>lex:DeleteBot</code> action.</p>
  ##   name: string (required)
  ##       : The name of the bot. The name is case sensitive. 
  var path_594092 = newJObject()
  add(path_594092, "name", newJString(name))
  result = call_594091.call(path_594092, nil, nil, nil, nil)

var deleteBot* = Call_DeleteBot_594079(name: "deleteBot",
                                    meth: HttpMethod.HttpDelete,
                                    host: "models.lex.amazonaws.com",
                                    route: "/bots/{name}",
                                    validator: validate_DeleteBot_594080,
                                    base: "/", url: url_DeleteBot_594081,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBotAlias_594108 = ref object of OpenApiRestCall_593438
proc url_PutBotAlias_594110(protocol: Scheme; host: string; base: string;
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

proc validate_PutBotAlias_594109(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594111 = path.getOrDefault("name")
  valid_594111 = validateParameter(valid_594111, JString, required = true,
                                 default = nil)
  if valid_594111 != nil:
    section.add "name", valid_594111
  var valid_594112 = path.getOrDefault("botName")
  valid_594112 = validateParameter(valid_594112, JString, required = true,
                                 default = nil)
  if valid_594112 != nil:
    section.add "botName", valid_594112
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
  var valid_594113 = header.getOrDefault("X-Amz-Date")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "X-Amz-Date", valid_594113
  var valid_594114 = header.getOrDefault("X-Amz-Security-Token")
  valid_594114 = validateParameter(valid_594114, JString, required = false,
                                 default = nil)
  if valid_594114 != nil:
    section.add "X-Amz-Security-Token", valid_594114
  var valid_594115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "X-Amz-Content-Sha256", valid_594115
  var valid_594116 = header.getOrDefault("X-Amz-Algorithm")
  valid_594116 = validateParameter(valid_594116, JString, required = false,
                                 default = nil)
  if valid_594116 != nil:
    section.add "X-Amz-Algorithm", valid_594116
  var valid_594117 = header.getOrDefault("X-Amz-Signature")
  valid_594117 = validateParameter(valid_594117, JString, required = false,
                                 default = nil)
  if valid_594117 != nil:
    section.add "X-Amz-Signature", valid_594117
  var valid_594118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594118 = validateParameter(valid_594118, JString, required = false,
                                 default = nil)
  if valid_594118 != nil:
    section.add "X-Amz-SignedHeaders", valid_594118
  var valid_594119 = header.getOrDefault("X-Amz-Credential")
  valid_594119 = validateParameter(valid_594119, JString, required = false,
                                 default = nil)
  if valid_594119 != nil:
    section.add "X-Amz-Credential", valid_594119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594121: Call_PutBotAlias_594108; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an alias for the specified version of the bot or replaces an alias for the specified bot. To change the version of the bot that the alias points to, replace the alias. For more information about aliases, see <a>versioning-aliases</a>.</p> <p>This operation requires permissions for the <code>lex:PutBotAlias</code> action. </p>
  ## 
  let valid = call_594121.validator(path, query, header, formData, body)
  let scheme = call_594121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594121.url(scheme.get, call_594121.host, call_594121.base,
                         call_594121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594121, url, valid)

proc call*(call_594122: Call_PutBotAlias_594108; name: string; botName: string;
          body: JsonNode): Recallable =
  ## putBotAlias
  ## <p>Creates an alias for the specified version of the bot or replaces an alias for the specified bot. To change the version of the bot that the alias points to, replace the alias. For more information about aliases, see <a>versioning-aliases</a>.</p> <p>This operation requires permissions for the <code>lex:PutBotAlias</code> action. </p>
  ##   name: string (required)
  ##       : The name of the alias. The name is <i>not</i> case sensitive.
  ##   botName: string (required)
  ##          : The name of the bot.
  ##   body: JObject (required)
  var path_594123 = newJObject()
  var body_594124 = newJObject()
  add(path_594123, "name", newJString(name))
  add(path_594123, "botName", newJString(botName))
  if body != nil:
    body_594124 = body
  result = call_594122.call(path_594123, nil, nil, nil, body_594124)

var putBotAlias* = Call_PutBotAlias_594108(name: "putBotAlias",
                                        meth: HttpMethod.HttpPut,
                                        host: "models.lex.amazonaws.com", route: "/bots/{botName}/aliases/{name}",
                                        validator: validate_PutBotAlias_594109,
                                        base: "/", url: url_PutBotAlias_594110,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBotAlias_594093 = ref object of OpenApiRestCall_593438
proc url_GetBotAlias_594095(protocol: Scheme; host: string; base: string;
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

proc validate_GetBotAlias_594094(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594096 = path.getOrDefault("name")
  valid_594096 = validateParameter(valid_594096, JString, required = true,
                                 default = nil)
  if valid_594096 != nil:
    section.add "name", valid_594096
  var valid_594097 = path.getOrDefault("botName")
  valid_594097 = validateParameter(valid_594097, JString, required = true,
                                 default = nil)
  if valid_594097 != nil:
    section.add "botName", valid_594097
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
  var valid_594098 = header.getOrDefault("X-Amz-Date")
  valid_594098 = validateParameter(valid_594098, JString, required = false,
                                 default = nil)
  if valid_594098 != nil:
    section.add "X-Amz-Date", valid_594098
  var valid_594099 = header.getOrDefault("X-Amz-Security-Token")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "X-Amz-Security-Token", valid_594099
  var valid_594100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594100 = validateParameter(valid_594100, JString, required = false,
                                 default = nil)
  if valid_594100 != nil:
    section.add "X-Amz-Content-Sha256", valid_594100
  var valid_594101 = header.getOrDefault("X-Amz-Algorithm")
  valid_594101 = validateParameter(valid_594101, JString, required = false,
                                 default = nil)
  if valid_594101 != nil:
    section.add "X-Amz-Algorithm", valid_594101
  var valid_594102 = header.getOrDefault("X-Amz-Signature")
  valid_594102 = validateParameter(valid_594102, JString, required = false,
                                 default = nil)
  if valid_594102 != nil:
    section.add "X-Amz-Signature", valid_594102
  var valid_594103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594103 = validateParameter(valid_594103, JString, required = false,
                                 default = nil)
  if valid_594103 != nil:
    section.add "X-Amz-SignedHeaders", valid_594103
  var valid_594104 = header.getOrDefault("X-Amz-Credential")
  valid_594104 = validateParameter(valid_594104, JString, required = false,
                                 default = nil)
  if valid_594104 != nil:
    section.add "X-Amz-Credential", valid_594104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594105: Call_GetBotAlias_594093; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about an Amazon Lex bot alias. For more information about aliases, see <a>versioning-aliases</a>.</p> <p>This operation requires permissions for the <code>lex:GetBotAlias</code> action.</p>
  ## 
  let valid = call_594105.validator(path, query, header, formData, body)
  let scheme = call_594105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594105.url(scheme.get, call_594105.host, call_594105.base,
                         call_594105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594105, url, valid)

proc call*(call_594106: Call_GetBotAlias_594093; name: string; botName: string): Recallable =
  ## getBotAlias
  ## <p>Returns information about an Amazon Lex bot alias. For more information about aliases, see <a>versioning-aliases</a>.</p> <p>This operation requires permissions for the <code>lex:GetBotAlias</code> action.</p>
  ##   name: string (required)
  ##       : The name of the bot alias. The name is case sensitive.
  ##   botName: string (required)
  ##          : The name of the bot.
  var path_594107 = newJObject()
  add(path_594107, "name", newJString(name))
  add(path_594107, "botName", newJString(botName))
  result = call_594106.call(path_594107, nil, nil, nil, nil)

var getBotAlias* = Call_GetBotAlias_594093(name: "getBotAlias",
                                        meth: HttpMethod.HttpGet,
                                        host: "models.lex.amazonaws.com", route: "/bots/{botName}/aliases/{name}",
                                        validator: validate_GetBotAlias_594094,
                                        base: "/", url: url_GetBotAlias_594095,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBotAlias_594125 = ref object of OpenApiRestCall_593438
proc url_DeleteBotAlias_594127(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBotAlias_594126(path: JsonNode; query: JsonNode;
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
  var valid_594128 = path.getOrDefault("name")
  valid_594128 = validateParameter(valid_594128, JString, required = true,
                                 default = nil)
  if valid_594128 != nil:
    section.add "name", valid_594128
  var valid_594129 = path.getOrDefault("botName")
  valid_594129 = validateParameter(valid_594129, JString, required = true,
                                 default = nil)
  if valid_594129 != nil:
    section.add "botName", valid_594129
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
  var valid_594130 = header.getOrDefault("X-Amz-Date")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = nil)
  if valid_594130 != nil:
    section.add "X-Amz-Date", valid_594130
  var valid_594131 = header.getOrDefault("X-Amz-Security-Token")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "X-Amz-Security-Token", valid_594131
  var valid_594132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594132 = validateParameter(valid_594132, JString, required = false,
                                 default = nil)
  if valid_594132 != nil:
    section.add "X-Amz-Content-Sha256", valid_594132
  var valid_594133 = header.getOrDefault("X-Amz-Algorithm")
  valid_594133 = validateParameter(valid_594133, JString, required = false,
                                 default = nil)
  if valid_594133 != nil:
    section.add "X-Amz-Algorithm", valid_594133
  var valid_594134 = header.getOrDefault("X-Amz-Signature")
  valid_594134 = validateParameter(valid_594134, JString, required = false,
                                 default = nil)
  if valid_594134 != nil:
    section.add "X-Amz-Signature", valid_594134
  var valid_594135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594135 = validateParameter(valid_594135, JString, required = false,
                                 default = nil)
  if valid_594135 != nil:
    section.add "X-Amz-SignedHeaders", valid_594135
  var valid_594136 = header.getOrDefault("X-Amz-Credential")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Credential", valid_594136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594137: Call_DeleteBotAlias_594125; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an alias for the specified bot. </p> <p>You can't delete an alias that is used in the association between a bot and a messaging channel. If an alias is used in a channel association, the <code>DeleteBot</code> operation returns a <code>ResourceInUseException</code> exception that includes a reference to the channel association that refers to the bot. You can remove the reference to the alias by deleting the channel association. If you get the same exception again, delete the referring association until the <code>DeleteBotAlias</code> operation is successful.</p>
  ## 
  let valid = call_594137.validator(path, query, header, formData, body)
  let scheme = call_594137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594137.url(scheme.get, call_594137.host, call_594137.base,
                         call_594137.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594137, url, valid)

proc call*(call_594138: Call_DeleteBotAlias_594125; name: string; botName: string): Recallable =
  ## deleteBotAlias
  ## <p>Deletes an alias for the specified bot. </p> <p>You can't delete an alias that is used in the association between a bot and a messaging channel. If an alias is used in a channel association, the <code>DeleteBot</code> operation returns a <code>ResourceInUseException</code> exception that includes a reference to the channel association that refers to the bot. You can remove the reference to the alias by deleting the channel association. If you get the same exception again, delete the referring association until the <code>DeleteBotAlias</code> operation is successful.</p>
  ##   name: string (required)
  ##       : The name of the alias to delete. The name is case sensitive. 
  ##   botName: string (required)
  ##          : The name of the bot that the alias points to.
  var path_594139 = newJObject()
  add(path_594139, "name", newJString(name))
  add(path_594139, "botName", newJString(botName))
  result = call_594138.call(path_594139, nil, nil, nil, nil)

var deleteBotAlias* = Call_DeleteBotAlias_594125(name: "deleteBotAlias",
    meth: HttpMethod.HttpDelete, host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/aliases/{name}", validator: validate_DeleteBotAlias_594126,
    base: "/", url: url_DeleteBotAlias_594127, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBotChannelAssociation_594140 = ref object of OpenApiRestCall_593438
proc url_GetBotChannelAssociation_594142(protocol: Scheme; host: string;
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

proc validate_GetBotChannelAssociation_594141(path: JsonNode; query: JsonNode;
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
  var valid_594143 = path.getOrDefault("name")
  valid_594143 = validateParameter(valid_594143, JString, required = true,
                                 default = nil)
  if valid_594143 != nil:
    section.add "name", valid_594143
  var valid_594144 = path.getOrDefault("botName")
  valid_594144 = validateParameter(valid_594144, JString, required = true,
                                 default = nil)
  if valid_594144 != nil:
    section.add "botName", valid_594144
  var valid_594145 = path.getOrDefault("aliasName")
  valid_594145 = validateParameter(valid_594145, JString, required = true,
                                 default = nil)
  if valid_594145 != nil:
    section.add "aliasName", valid_594145
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
  var valid_594146 = header.getOrDefault("X-Amz-Date")
  valid_594146 = validateParameter(valid_594146, JString, required = false,
                                 default = nil)
  if valid_594146 != nil:
    section.add "X-Amz-Date", valid_594146
  var valid_594147 = header.getOrDefault("X-Amz-Security-Token")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "X-Amz-Security-Token", valid_594147
  var valid_594148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594148 = validateParameter(valid_594148, JString, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "X-Amz-Content-Sha256", valid_594148
  var valid_594149 = header.getOrDefault("X-Amz-Algorithm")
  valid_594149 = validateParameter(valid_594149, JString, required = false,
                                 default = nil)
  if valid_594149 != nil:
    section.add "X-Amz-Algorithm", valid_594149
  var valid_594150 = header.getOrDefault("X-Amz-Signature")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = nil)
  if valid_594150 != nil:
    section.add "X-Amz-Signature", valid_594150
  var valid_594151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-SignedHeaders", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-Credential")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Credential", valid_594152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594153: Call_GetBotChannelAssociation_594140; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the association between an Amazon Lex bot and a messaging platform.</p> <p>This operation requires permissions for the <code>lex:GetBotChannelAssociation</code> action.</p>
  ## 
  let valid = call_594153.validator(path, query, header, formData, body)
  let scheme = call_594153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594153.url(scheme.get, call_594153.host, call_594153.base,
                         call_594153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594153, url, valid)

proc call*(call_594154: Call_GetBotChannelAssociation_594140; name: string;
          botName: string; aliasName: string): Recallable =
  ## getBotChannelAssociation
  ## <p>Returns information about the association between an Amazon Lex bot and a messaging platform.</p> <p>This operation requires permissions for the <code>lex:GetBotChannelAssociation</code> action.</p>
  ##   name: string (required)
  ##       : The name of the association between the bot and the channel. The name is case sensitive. 
  ##   botName: string (required)
  ##          : The name of the Amazon Lex bot.
  ##   aliasName: string (required)
  ##            : An alias pointing to the specific version of the Amazon Lex bot to which this association is being made.
  var path_594155 = newJObject()
  add(path_594155, "name", newJString(name))
  add(path_594155, "botName", newJString(botName))
  add(path_594155, "aliasName", newJString(aliasName))
  result = call_594154.call(path_594155, nil, nil, nil, nil)

var getBotChannelAssociation* = Call_GetBotChannelAssociation_594140(
    name: "getBotChannelAssociation", meth: HttpMethod.HttpGet,
    host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/aliases/{aliasName}/channels/{name}",
    validator: validate_GetBotChannelAssociation_594141, base: "/",
    url: url_GetBotChannelAssociation_594142, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBotChannelAssociation_594156 = ref object of OpenApiRestCall_593438
proc url_DeleteBotChannelAssociation_594158(protocol: Scheme; host: string;
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

proc validate_DeleteBotChannelAssociation_594157(path: JsonNode; query: JsonNode;
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
  var valid_594159 = path.getOrDefault("name")
  valid_594159 = validateParameter(valid_594159, JString, required = true,
                                 default = nil)
  if valid_594159 != nil:
    section.add "name", valid_594159
  var valid_594160 = path.getOrDefault("botName")
  valid_594160 = validateParameter(valid_594160, JString, required = true,
                                 default = nil)
  if valid_594160 != nil:
    section.add "botName", valid_594160
  var valid_594161 = path.getOrDefault("aliasName")
  valid_594161 = validateParameter(valid_594161, JString, required = true,
                                 default = nil)
  if valid_594161 != nil:
    section.add "aliasName", valid_594161
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
  var valid_594162 = header.getOrDefault("X-Amz-Date")
  valid_594162 = validateParameter(valid_594162, JString, required = false,
                                 default = nil)
  if valid_594162 != nil:
    section.add "X-Amz-Date", valid_594162
  var valid_594163 = header.getOrDefault("X-Amz-Security-Token")
  valid_594163 = validateParameter(valid_594163, JString, required = false,
                                 default = nil)
  if valid_594163 != nil:
    section.add "X-Amz-Security-Token", valid_594163
  var valid_594164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594164 = validateParameter(valid_594164, JString, required = false,
                                 default = nil)
  if valid_594164 != nil:
    section.add "X-Amz-Content-Sha256", valid_594164
  var valid_594165 = header.getOrDefault("X-Amz-Algorithm")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "X-Amz-Algorithm", valid_594165
  var valid_594166 = header.getOrDefault("X-Amz-Signature")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-Signature", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-SignedHeaders", valid_594167
  var valid_594168 = header.getOrDefault("X-Amz-Credential")
  valid_594168 = validateParameter(valid_594168, JString, required = false,
                                 default = nil)
  if valid_594168 != nil:
    section.add "X-Amz-Credential", valid_594168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594169: Call_DeleteBotChannelAssociation_594156; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the association between an Amazon Lex bot and a messaging platform.</p> <p>This operation requires permission for the <code>lex:DeleteBotChannelAssociation</code> action.</p>
  ## 
  let valid = call_594169.validator(path, query, header, formData, body)
  let scheme = call_594169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594169.url(scheme.get, call_594169.host, call_594169.base,
                         call_594169.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594169, url, valid)

proc call*(call_594170: Call_DeleteBotChannelAssociation_594156; name: string;
          botName: string; aliasName: string): Recallable =
  ## deleteBotChannelAssociation
  ## <p>Deletes the association between an Amazon Lex bot and a messaging platform.</p> <p>This operation requires permission for the <code>lex:DeleteBotChannelAssociation</code> action.</p>
  ##   name: string (required)
  ##       : The name of the association. The name is case sensitive. 
  ##   botName: string (required)
  ##          : The name of the Amazon Lex bot.
  ##   aliasName: string (required)
  ##            : An alias that points to the specific version of the Amazon Lex bot to which this association is being made.
  var path_594171 = newJObject()
  add(path_594171, "name", newJString(name))
  add(path_594171, "botName", newJString(botName))
  add(path_594171, "aliasName", newJString(aliasName))
  result = call_594170.call(path_594171, nil, nil, nil, nil)

var deleteBotChannelAssociation* = Call_DeleteBotChannelAssociation_594156(
    name: "deleteBotChannelAssociation", meth: HttpMethod.HttpDelete,
    host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/aliases/{aliasName}/channels/{name}",
    validator: validate_DeleteBotChannelAssociation_594157, base: "/",
    url: url_DeleteBotChannelAssociation_594158,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBotVersion_594172 = ref object of OpenApiRestCall_593438
proc url_DeleteBotVersion_594174(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBotVersion_594173(path: JsonNode; query: JsonNode;
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
  var valid_594175 = path.getOrDefault("name")
  valid_594175 = validateParameter(valid_594175, JString, required = true,
                                 default = nil)
  if valid_594175 != nil:
    section.add "name", valid_594175
  var valid_594176 = path.getOrDefault("version")
  valid_594176 = validateParameter(valid_594176, JString, required = true,
                                 default = nil)
  if valid_594176 != nil:
    section.add "version", valid_594176
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
  var valid_594177 = header.getOrDefault("X-Amz-Date")
  valid_594177 = validateParameter(valid_594177, JString, required = false,
                                 default = nil)
  if valid_594177 != nil:
    section.add "X-Amz-Date", valid_594177
  var valid_594178 = header.getOrDefault("X-Amz-Security-Token")
  valid_594178 = validateParameter(valid_594178, JString, required = false,
                                 default = nil)
  if valid_594178 != nil:
    section.add "X-Amz-Security-Token", valid_594178
  var valid_594179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594179 = validateParameter(valid_594179, JString, required = false,
                                 default = nil)
  if valid_594179 != nil:
    section.add "X-Amz-Content-Sha256", valid_594179
  var valid_594180 = header.getOrDefault("X-Amz-Algorithm")
  valid_594180 = validateParameter(valid_594180, JString, required = false,
                                 default = nil)
  if valid_594180 != nil:
    section.add "X-Amz-Algorithm", valid_594180
  var valid_594181 = header.getOrDefault("X-Amz-Signature")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-Signature", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-SignedHeaders", valid_594182
  var valid_594183 = header.getOrDefault("X-Amz-Credential")
  valid_594183 = validateParameter(valid_594183, JString, required = false,
                                 default = nil)
  if valid_594183 != nil:
    section.add "X-Amz-Credential", valid_594183
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594184: Call_DeleteBotVersion_594172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a specific version of a bot. To delete all versions of a bot, use the <a>DeleteBot</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteBotVersion</code> action.</p>
  ## 
  let valid = call_594184.validator(path, query, header, formData, body)
  let scheme = call_594184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594184.url(scheme.get, call_594184.host, call_594184.base,
                         call_594184.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594184, url, valid)

proc call*(call_594185: Call_DeleteBotVersion_594172; name: string; version: string): Recallable =
  ## deleteBotVersion
  ## <p>Deletes a specific version of a bot. To delete all versions of a bot, use the <a>DeleteBot</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteBotVersion</code> action.</p>
  ##   name: string (required)
  ##       : The name of the bot.
  ##   version: string (required)
  ##          : The version of the bot to delete. You cannot delete the <code>$LATEST</code> version of the bot. To delete the <code>$LATEST</code> version, use the <a>DeleteBot</a> operation.
  var path_594186 = newJObject()
  add(path_594186, "name", newJString(name))
  add(path_594186, "version", newJString(version))
  result = call_594185.call(path_594186, nil, nil, nil, nil)

var deleteBotVersion* = Call_DeleteBotVersion_594172(name: "deleteBotVersion",
    meth: HttpMethod.HttpDelete, host: "models.lex.amazonaws.com",
    route: "/bots/{name}/versions/{version}",
    validator: validate_DeleteBotVersion_594173, base: "/",
    url: url_DeleteBotVersion_594174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntent_594187 = ref object of OpenApiRestCall_593438
proc url_DeleteIntent_594189(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteIntent_594188(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594190 = path.getOrDefault("name")
  valid_594190 = validateParameter(valid_594190, JString, required = true,
                                 default = nil)
  if valid_594190 != nil:
    section.add "name", valid_594190
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
  var valid_594191 = header.getOrDefault("X-Amz-Date")
  valid_594191 = validateParameter(valid_594191, JString, required = false,
                                 default = nil)
  if valid_594191 != nil:
    section.add "X-Amz-Date", valid_594191
  var valid_594192 = header.getOrDefault("X-Amz-Security-Token")
  valid_594192 = validateParameter(valid_594192, JString, required = false,
                                 default = nil)
  if valid_594192 != nil:
    section.add "X-Amz-Security-Token", valid_594192
  var valid_594193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594193 = validateParameter(valid_594193, JString, required = false,
                                 default = nil)
  if valid_594193 != nil:
    section.add "X-Amz-Content-Sha256", valid_594193
  var valid_594194 = header.getOrDefault("X-Amz-Algorithm")
  valid_594194 = validateParameter(valid_594194, JString, required = false,
                                 default = nil)
  if valid_594194 != nil:
    section.add "X-Amz-Algorithm", valid_594194
  var valid_594195 = header.getOrDefault("X-Amz-Signature")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "X-Amz-Signature", valid_594195
  var valid_594196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-SignedHeaders", valid_594196
  var valid_594197 = header.getOrDefault("X-Amz-Credential")
  valid_594197 = validateParameter(valid_594197, JString, required = false,
                                 default = nil)
  if valid_594197 != nil:
    section.add "X-Amz-Credential", valid_594197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594198: Call_DeleteIntent_594187; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes all versions of the intent, including the <code>$LATEST</code> version. To delete a specific version of the intent, use the <a>DeleteIntentVersion</a> operation.</p> <p> You can delete a version of an intent only if it is not referenced. To delete an intent that is referred to in one or more bots (see <a>how-it-works</a>), you must remove those references first. </p> <note> <p> If you get the <code>ResourceInUseException</code> exception, it provides an example reference that shows where the intent is referenced. To remove the reference to the intent, either update the bot or delete it. If you get the same exception when you attempt to delete the intent again, repeat until the intent has no references and the call to <code>DeleteIntent</code> is successful. </p> </note> <p> This operation requires permission for the <code>lex:DeleteIntent</code> action. </p>
  ## 
  let valid = call_594198.validator(path, query, header, formData, body)
  let scheme = call_594198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594198.url(scheme.get, call_594198.host, call_594198.base,
                         call_594198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594198, url, valid)

proc call*(call_594199: Call_DeleteIntent_594187; name: string): Recallable =
  ## deleteIntent
  ## <p>Deletes all versions of the intent, including the <code>$LATEST</code> version. To delete a specific version of the intent, use the <a>DeleteIntentVersion</a> operation.</p> <p> You can delete a version of an intent only if it is not referenced. To delete an intent that is referred to in one or more bots (see <a>how-it-works</a>), you must remove those references first. </p> <note> <p> If you get the <code>ResourceInUseException</code> exception, it provides an example reference that shows where the intent is referenced. To remove the reference to the intent, either update the bot or delete it. If you get the same exception when you attempt to delete the intent again, repeat until the intent has no references and the call to <code>DeleteIntent</code> is successful. </p> </note> <p> This operation requires permission for the <code>lex:DeleteIntent</code> action. </p>
  ##   name: string (required)
  ##       : The name of the intent. The name is case sensitive. 
  var path_594200 = newJObject()
  add(path_594200, "name", newJString(name))
  result = call_594199.call(path_594200, nil, nil, nil, nil)

var deleteIntent* = Call_DeleteIntent_594187(name: "deleteIntent",
    meth: HttpMethod.HttpDelete, host: "models.lex.amazonaws.com",
    route: "/intents/{name}", validator: validate_DeleteIntent_594188, base: "/",
    url: url_DeleteIntent_594189, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntent_594201 = ref object of OpenApiRestCall_593438
proc url_GetIntent_594203(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetIntent_594202(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594204 = path.getOrDefault("name")
  valid_594204 = validateParameter(valid_594204, JString, required = true,
                                 default = nil)
  if valid_594204 != nil:
    section.add "name", valid_594204
  var valid_594205 = path.getOrDefault("version")
  valid_594205 = validateParameter(valid_594205, JString, required = true,
                                 default = nil)
  if valid_594205 != nil:
    section.add "version", valid_594205
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
  var valid_594206 = header.getOrDefault("X-Amz-Date")
  valid_594206 = validateParameter(valid_594206, JString, required = false,
                                 default = nil)
  if valid_594206 != nil:
    section.add "X-Amz-Date", valid_594206
  var valid_594207 = header.getOrDefault("X-Amz-Security-Token")
  valid_594207 = validateParameter(valid_594207, JString, required = false,
                                 default = nil)
  if valid_594207 != nil:
    section.add "X-Amz-Security-Token", valid_594207
  var valid_594208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594208 = validateParameter(valid_594208, JString, required = false,
                                 default = nil)
  if valid_594208 != nil:
    section.add "X-Amz-Content-Sha256", valid_594208
  var valid_594209 = header.getOrDefault("X-Amz-Algorithm")
  valid_594209 = validateParameter(valid_594209, JString, required = false,
                                 default = nil)
  if valid_594209 != nil:
    section.add "X-Amz-Algorithm", valid_594209
  var valid_594210 = header.getOrDefault("X-Amz-Signature")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "X-Amz-Signature", valid_594210
  var valid_594211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-SignedHeaders", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-Credential")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Credential", valid_594212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594213: Call_GetIntent_594201; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns information about an intent. In addition to the intent name, you must specify the intent version. </p> <p> This operation requires permissions to perform the <code>lex:GetIntent</code> action. </p>
  ## 
  let valid = call_594213.validator(path, query, header, formData, body)
  let scheme = call_594213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594213.url(scheme.get, call_594213.host, call_594213.base,
                         call_594213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594213, url, valid)

proc call*(call_594214: Call_GetIntent_594201; name: string; version: string): Recallable =
  ## getIntent
  ## <p> Returns information about an intent. In addition to the intent name, you must specify the intent version. </p> <p> This operation requires permissions to perform the <code>lex:GetIntent</code> action. </p>
  ##   name: string (required)
  ##       : The name of the intent. The name is case sensitive. 
  ##   version: string (required)
  ##          : The version of the intent.
  var path_594215 = newJObject()
  add(path_594215, "name", newJString(name))
  add(path_594215, "version", newJString(version))
  result = call_594214.call(path_594215, nil, nil, nil, nil)

var getIntent* = Call_GetIntent_594201(name: "getIntent", meth: HttpMethod.HttpGet,
                                    host: "models.lex.amazonaws.com", route: "/intents/{name}/versions/{version}",
                                    validator: validate_GetIntent_594202,
                                    base: "/", url: url_GetIntent_594203,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntentVersion_594216 = ref object of OpenApiRestCall_593438
proc url_DeleteIntentVersion_594218(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteIntentVersion_594217(path: JsonNode; query: JsonNode;
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
  var valid_594219 = path.getOrDefault("name")
  valid_594219 = validateParameter(valid_594219, JString, required = true,
                                 default = nil)
  if valid_594219 != nil:
    section.add "name", valid_594219
  var valid_594220 = path.getOrDefault("version")
  valid_594220 = validateParameter(valid_594220, JString, required = true,
                                 default = nil)
  if valid_594220 != nil:
    section.add "version", valid_594220
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
  var valid_594221 = header.getOrDefault("X-Amz-Date")
  valid_594221 = validateParameter(valid_594221, JString, required = false,
                                 default = nil)
  if valid_594221 != nil:
    section.add "X-Amz-Date", valid_594221
  var valid_594222 = header.getOrDefault("X-Amz-Security-Token")
  valid_594222 = validateParameter(valid_594222, JString, required = false,
                                 default = nil)
  if valid_594222 != nil:
    section.add "X-Amz-Security-Token", valid_594222
  var valid_594223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594223 = validateParameter(valid_594223, JString, required = false,
                                 default = nil)
  if valid_594223 != nil:
    section.add "X-Amz-Content-Sha256", valid_594223
  var valid_594224 = header.getOrDefault("X-Amz-Algorithm")
  valid_594224 = validateParameter(valid_594224, JString, required = false,
                                 default = nil)
  if valid_594224 != nil:
    section.add "X-Amz-Algorithm", valid_594224
  var valid_594225 = header.getOrDefault("X-Amz-Signature")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "X-Amz-Signature", valid_594225
  var valid_594226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-SignedHeaders", valid_594226
  var valid_594227 = header.getOrDefault("X-Amz-Credential")
  valid_594227 = validateParameter(valid_594227, JString, required = false,
                                 default = nil)
  if valid_594227 != nil:
    section.add "X-Amz-Credential", valid_594227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594228: Call_DeleteIntentVersion_594216; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a specific version of an intent. To delete all versions of a intent, use the <a>DeleteIntent</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteIntentVersion</code> action.</p>
  ## 
  let valid = call_594228.validator(path, query, header, formData, body)
  let scheme = call_594228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594228.url(scheme.get, call_594228.host, call_594228.base,
                         call_594228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594228, url, valid)

proc call*(call_594229: Call_DeleteIntentVersion_594216; name: string;
          version: string): Recallable =
  ## deleteIntentVersion
  ## <p>Deletes a specific version of an intent. To delete all versions of a intent, use the <a>DeleteIntent</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteIntentVersion</code> action.</p>
  ##   name: string (required)
  ##       : The name of the intent.
  ##   version: string (required)
  ##          : The version of the intent to delete. You cannot delete the <code>$LATEST</code> version of the intent. To delete the <code>$LATEST</code> version, use the <a>DeleteIntent</a> operation.
  var path_594230 = newJObject()
  add(path_594230, "name", newJString(name))
  add(path_594230, "version", newJString(version))
  result = call_594229.call(path_594230, nil, nil, nil, nil)

var deleteIntentVersion* = Call_DeleteIntentVersion_594216(
    name: "deleteIntentVersion", meth: HttpMethod.HttpDelete,
    host: "models.lex.amazonaws.com", route: "/intents/{name}/versions/{version}",
    validator: validate_DeleteIntentVersion_594217, base: "/",
    url: url_DeleteIntentVersion_594218, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSlotType_594231 = ref object of OpenApiRestCall_593438
proc url_DeleteSlotType_594233(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSlotType_594232(path: JsonNode; query: JsonNode;
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
  var valid_594234 = path.getOrDefault("name")
  valid_594234 = validateParameter(valid_594234, JString, required = true,
                                 default = nil)
  if valid_594234 != nil:
    section.add "name", valid_594234
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
  var valid_594235 = header.getOrDefault("X-Amz-Date")
  valid_594235 = validateParameter(valid_594235, JString, required = false,
                                 default = nil)
  if valid_594235 != nil:
    section.add "X-Amz-Date", valid_594235
  var valid_594236 = header.getOrDefault("X-Amz-Security-Token")
  valid_594236 = validateParameter(valid_594236, JString, required = false,
                                 default = nil)
  if valid_594236 != nil:
    section.add "X-Amz-Security-Token", valid_594236
  var valid_594237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594237 = validateParameter(valid_594237, JString, required = false,
                                 default = nil)
  if valid_594237 != nil:
    section.add "X-Amz-Content-Sha256", valid_594237
  var valid_594238 = header.getOrDefault("X-Amz-Algorithm")
  valid_594238 = validateParameter(valid_594238, JString, required = false,
                                 default = nil)
  if valid_594238 != nil:
    section.add "X-Amz-Algorithm", valid_594238
  var valid_594239 = header.getOrDefault("X-Amz-Signature")
  valid_594239 = validateParameter(valid_594239, JString, required = false,
                                 default = nil)
  if valid_594239 != nil:
    section.add "X-Amz-Signature", valid_594239
  var valid_594240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594240 = validateParameter(valid_594240, JString, required = false,
                                 default = nil)
  if valid_594240 != nil:
    section.add "X-Amz-SignedHeaders", valid_594240
  var valid_594241 = header.getOrDefault("X-Amz-Credential")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-Credential", valid_594241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594242: Call_DeleteSlotType_594231; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes all versions of the slot type, including the <code>$LATEST</code> version. To delete a specific version of the slot type, use the <a>DeleteSlotTypeVersion</a> operation.</p> <p> You can delete a version of a slot type only if it is not referenced. To delete a slot type that is referred to in one or more intents, you must remove those references first. </p> <note> <p> If you get the <code>ResourceInUseException</code> exception, the exception provides an example reference that shows the intent where the slot type is referenced. To remove the reference to the slot type, either update the intent or delete it. If you get the same exception when you attempt to delete the slot type again, repeat until the slot type has no references and the <code>DeleteSlotType</code> call is successful. </p> </note> <p>This operation requires permission for the <code>lex:DeleteSlotType</code> action.</p>
  ## 
  let valid = call_594242.validator(path, query, header, formData, body)
  let scheme = call_594242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594242.url(scheme.get, call_594242.host, call_594242.base,
                         call_594242.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594242, url, valid)

proc call*(call_594243: Call_DeleteSlotType_594231; name: string): Recallable =
  ## deleteSlotType
  ## <p>Deletes all versions of the slot type, including the <code>$LATEST</code> version. To delete a specific version of the slot type, use the <a>DeleteSlotTypeVersion</a> operation.</p> <p> You can delete a version of a slot type only if it is not referenced. To delete a slot type that is referred to in one or more intents, you must remove those references first. </p> <note> <p> If you get the <code>ResourceInUseException</code> exception, the exception provides an example reference that shows the intent where the slot type is referenced. To remove the reference to the slot type, either update the intent or delete it. If you get the same exception when you attempt to delete the slot type again, repeat until the slot type has no references and the <code>DeleteSlotType</code> call is successful. </p> </note> <p>This operation requires permission for the <code>lex:DeleteSlotType</code> action.</p>
  ##   name: string (required)
  ##       : The name of the slot type. The name is case sensitive. 
  var path_594244 = newJObject()
  add(path_594244, "name", newJString(name))
  result = call_594243.call(path_594244, nil, nil, nil, nil)

var deleteSlotType* = Call_DeleteSlotType_594231(name: "deleteSlotType",
    meth: HttpMethod.HttpDelete, host: "models.lex.amazonaws.com",
    route: "/slottypes/{name}", validator: validate_DeleteSlotType_594232,
    base: "/", url: url_DeleteSlotType_594233, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSlotTypeVersion_594245 = ref object of OpenApiRestCall_593438
proc url_DeleteSlotTypeVersion_594247(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSlotTypeVersion_594246(path: JsonNode; query: JsonNode;
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
  var valid_594248 = path.getOrDefault("name")
  valid_594248 = validateParameter(valid_594248, JString, required = true,
                                 default = nil)
  if valid_594248 != nil:
    section.add "name", valid_594248
  var valid_594249 = path.getOrDefault("version")
  valid_594249 = validateParameter(valid_594249, JString, required = true,
                                 default = nil)
  if valid_594249 != nil:
    section.add "version", valid_594249
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
  var valid_594250 = header.getOrDefault("X-Amz-Date")
  valid_594250 = validateParameter(valid_594250, JString, required = false,
                                 default = nil)
  if valid_594250 != nil:
    section.add "X-Amz-Date", valid_594250
  var valid_594251 = header.getOrDefault("X-Amz-Security-Token")
  valid_594251 = validateParameter(valid_594251, JString, required = false,
                                 default = nil)
  if valid_594251 != nil:
    section.add "X-Amz-Security-Token", valid_594251
  var valid_594252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594252 = validateParameter(valid_594252, JString, required = false,
                                 default = nil)
  if valid_594252 != nil:
    section.add "X-Amz-Content-Sha256", valid_594252
  var valid_594253 = header.getOrDefault("X-Amz-Algorithm")
  valid_594253 = validateParameter(valid_594253, JString, required = false,
                                 default = nil)
  if valid_594253 != nil:
    section.add "X-Amz-Algorithm", valid_594253
  var valid_594254 = header.getOrDefault("X-Amz-Signature")
  valid_594254 = validateParameter(valid_594254, JString, required = false,
                                 default = nil)
  if valid_594254 != nil:
    section.add "X-Amz-Signature", valid_594254
  var valid_594255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594255 = validateParameter(valid_594255, JString, required = false,
                                 default = nil)
  if valid_594255 != nil:
    section.add "X-Amz-SignedHeaders", valid_594255
  var valid_594256 = header.getOrDefault("X-Amz-Credential")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Credential", valid_594256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594257: Call_DeleteSlotTypeVersion_594245; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a specific version of a slot type. To delete all versions of a slot type, use the <a>DeleteSlotType</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteSlotTypeVersion</code> action.</p>
  ## 
  let valid = call_594257.validator(path, query, header, formData, body)
  let scheme = call_594257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594257.url(scheme.get, call_594257.host, call_594257.base,
                         call_594257.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594257, url, valid)

proc call*(call_594258: Call_DeleteSlotTypeVersion_594245; name: string;
          version: string): Recallable =
  ## deleteSlotTypeVersion
  ## <p>Deletes a specific version of a slot type. To delete all versions of a slot type, use the <a>DeleteSlotType</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteSlotTypeVersion</code> action.</p>
  ##   name: string (required)
  ##       : The name of the slot type.
  ##   version: string (required)
  ##          : The version of the slot type to delete. You cannot delete the <code>$LATEST</code> version of the slot type. To delete the <code>$LATEST</code> version, use the <a>DeleteSlotType</a> operation.
  var path_594259 = newJObject()
  add(path_594259, "name", newJString(name))
  add(path_594259, "version", newJString(version))
  result = call_594258.call(path_594259, nil, nil, nil, nil)

var deleteSlotTypeVersion* = Call_DeleteSlotTypeVersion_594245(
    name: "deleteSlotTypeVersion", meth: HttpMethod.HttpDelete,
    host: "models.lex.amazonaws.com",
    route: "/slottypes/{name}/version/{version}",
    validator: validate_DeleteSlotTypeVersion_594246, base: "/",
    url: url_DeleteSlotTypeVersion_594247, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUtterances_594260 = ref object of OpenApiRestCall_593438
proc url_DeleteUtterances_594262(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUtterances_594261(path: JsonNode; query: JsonNode;
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
  var valid_594263 = path.getOrDefault("botName")
  valid_594263 = validateParameter(valid_594263, JString, required = true,
                                 default = nil)
  if valid_594263 != nil:
    section.add "botName", valid_594263
  var valid_594264 = path.getOrDefault("userId")
  valid_594264 = validateParameter(valid_594264, JString, required = true,
                                 default = nil)
  if valid_594264 != nil:
    section.add "userId", valid_594264
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
  var valid_594265 = header.getOrDefault("X-Amz-Date")
  valid_594265 = validateParameter(valid_594265, JString, required = false,
                                 default = nil)
  if valid_594265 != nil:
    section.add "X-Amz-Date", valid_594265
  var valid_594266 = header.getOrDefault("X-Amz-Security-Token")
  valid_594266 = validateParameter(valid_594266, JString, required = false,
                                 default = nil)
  if valid_594266 != nil:
    section.add "X-Amz-Security-Token", valid_594266
  var valid_594267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594267 = validateParameter(valid_594267, JString, required = false,
                                 default = nil)
  if valid_594267 != nil:
    section.add "X-Amz-Content-Sha256", valid_594267
  var valid_594268 = header.getOrDefault("X-Amz-Algorithm")
  valid_594268 = validateParameter(valid_594268, JString, required = false,
                                 default = nil)
  if valid_594268 != nil:
    section.add "X-Amz-Algorithm", valid_594268
  var valid_594269 = header.getOrDefault("X-Amz-Signature")
  valid_594269 = validateParameter(valid_594269, JString, required = false,
                                 default = nil)
  if valid_594269 != nil:
    section.add "X-Amz-Signature", valid_594269
  var valid_594270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594270 = validateParameter(valid_594270, JString, required = false,
                                 default = nil)
  if valid_594270 != nil:
    section.add "X-Amz-SignedHeaders", valid_594270
  var valid_594271 = header.getOrDefault("X-Amz-Credential")
  valid_594271 = validateParameter(valid_594271, JString, required = false,
                                 default = nil)
  if valid_594271 != nil:
    section.add "X-Amz-Credential", valid_594271
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594272: Call_DeleteUtterances_594260; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes stored utterances.</p> <p>Amazon Lex stores the utterances that users send to your bot. Utterances are stored for 15 days for use with the <a>GetUtterancesView</a> operation, and then stored indefinitely for use in improving the ability of your bot to respond to user input.</p> <p>Use the <code>DeleteStoredUtterances</code> operation to manually delete stored utterances for a specific user.</p> <p>This operation requires permissions for the <code>lex:DeleteUtterances</code> action.</p>
  ## 
  let valid = call_594272.validator(path, query, header, formData, body)
  let scheme = call_594272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594272.url(scheme.get, call_594272.host, call_594272.base,
                         call_594272.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594272, url, valid)

proc call*(call_594273: Call_DeleteUtterances_594260; botName: string; userId: string): Recallable =
  ## deleteUtterances
  ## <p>Deletes stored utterances.</p> <p>Amazon Lex stores the utterances that users send to your bot. Utterances are stored for 15 days for use with the <a>GetUtterancesView</a> operation, and then stored indefinitely for use in improving the ability of your bot to respond to user input.</p> <p>Use the <code>DeleteStoredUtterances</code> operation to manually delete stored utterances for a specific user.</p> <p>This operation requires permissions for the <code>lex:DeleteUtterances</code> action.</p>
  ##   botName: string (required)
  ##          : The name of the bot that stored the utterances.
  ##   userId: string (required)
  ##         :  The unique identifier for the user that made the utterances. This is the user ID that was sent in the <a 
  ## href="http://docs.aws.amazon.com/lex/latest/dg/API_runtime_PostContent.html">PostContent</a> or <a 
  ## href="http://docs.aws.amazon.com/lex/latest/dg/API_runtime_PostText.html">PostText</a> operation request that contained the utterance.
  var path_594274 = newJObject()
  add(path_594274, "botName", newJString(botName))
  add(path_594274, "userId", newJString(userId))
  result = call_594273.call(path_594274, nil, nil, nil, nil)

var deleteUtterances* = Call_DeleteUtterances_594260(name: "deleteUtterances",
    meth: HttpMethod.HttpDelete, host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/utterances/{userId}",
    validator: validate_DeleteUtterances_594261, base: "/",
    url: url_DeleteUtterances_594262, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBot_594275 = ref object of OpenApiRestCall_593438
proc url_GetBot_594277(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetBot_594276(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594278 = path.getOrDefault("versionoralias")
  valid_594278 = validateParameter(valid_594278, JString, required = true,
                                 default = nil)
  if valid_594278 != nil:
    section.add "versionoralias", valid_594278
  var valid_594279 = path.getOrDefault("name")
  valid_594279 = validateParameter(valid_594279, JString, required = true,
                                 default = nil)
  if valid_594279 != nil:
    section.add "name", valid_594279
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
  var valid_594280 = header.getOrDefault("X-Amz-Date")
  valid_594280 = validateParameter(valid_594280, JString, required = false,
                                 default = nil)
  if valid_594280 != nil:
    section.add "X-Amz-Date", valid_594280
  var valid_594281 = header.getOrDefault("X-Amz-Security-Token")
  valid_594281 = validateParameter(valid_594281, JString, required = false,
                                 default = nil)
  if valid_594281 != nil:
    section.add "X-Amz-Security-Token", valid_594281
  var valid_594282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594282 = validateParameter(valid_594282, JString, required = false,
                                 default = nil)
  if valid_594282 != nil:
    section.add "X-Amz-Content-Sha256", valid_594282
  var valid_594283 = header.getOrDefault("X-Amz-Algorithm")
  valid_594283 = validateParameter(valid_594283, JString, required = false,
                                 default = nil)
  if valid_594283 != nil:
    section.add "X-Amz-Algorithm", valid_594283
  var valid_594284 = header.getOrDefault("X-Amz-Signature")
  valid_594284 = validateParameter(valid_594284, JString, required = false,
                                 default = nil)
  if valid_594284 != nil:
    section.add "X-Amz-Signature", valid_594284
  var valid_594285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594285 = validateParameter(valid_594285, JString, required = false,
                                 default = nil)
  if valid_594285 != nil:
    section.add "X-Amz-SignedHeaders", valid_594285
  var valid_594286 = header.getOrDefault("X-Amz-Credential")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "X-Amz-Credential", valid_594286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594287: Call_GetBot_594275; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns metadata information for a specific bot. You must provide the bot name and the bot version or alias. </p> <p> This operation requires permissions for the <code>lex:GetBot</code> action. </p>
  ## 
  let valid = call_594287.validator(path, query, header, formData, body)
  let scheme = call_594287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594287.url(scheme.get, call_594287.host, call_594287.base,
                         call_594287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594287, url, valid)

proc call*(call_594288: Call_GetBot_594275; versionoralias: string; name: string): Recallable =
  ## getBot
  ## <p>Returns metadata information for a specific bot. You must provide the bot name and the bot version or alias. </p> <p> This operation requires permissions for the <code>lex:GetBot</code> action. </p>
  ##   versionoralias: string (required)
  ##                 : The version or alias of the bot.
  ##   name: string (required)
  ##       : The name of the bot. The name is case sensitive. 
  var path_594289 = newJObject()
  add(path_594289, "versionoralias", newJString(versionoralias))
  add(path_594289, "name", newJString(name))
  result = call_594288.call(path_594289, nil, nil, nil, nil)

var getBot* = Call_GetBot_594275(name: "getBot", meth: HttpMethod.HttpGet,
                              host: "models.lex.amazonaws.com",
                              route: "/bots/{name}/versions/{versionoralias}",
                              validator: validate_GetBot_594276, base: "/",
                              url: url_GetBot_594277,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBotAliases_594290 = ref object of OpenApiRestCall_593438
proc url_GetBotAliases_594292(protocol: Scheme; host: string; base: string;
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

proc validate_GetBotAliases_594291(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594293 = path.getOrDefault("botName")
  valid_594293 = validateParameter(valid_594293, JString, required = true,
                                 default = nil)
  if valid_594293 != nil:
    section.add "botName", valid_594293
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of aliases to return in the response. The default is 50. . 
  ##   nextToken: JString
  ##            : A pagination token for fetching the next page of aliases. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of aliases, specify the pagination token in the next request. 
  ##   nameContains: JString
  ##               : Substring to match in bot alias names. An alias will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  section = newJObject()
  var valid_594294 = query.getOrDefault("maxResults")
  valid_594294 = validateParameter(valid_594294, JInt, required = false, default = nil)
  if valid_594294 != nil:
    section.add "maxResults", valid_594294
  var valid_594295 = query.getOrDefault("nextToken")
  valid_594295 = validateParameter(valid_594295, JString, required = false,
                                 default = nil)
  if valid_594295 != nil:
    section.add "nextToken", valid_594295
  var valid_594296 = query.getOrDefault("nameContains")
  valid_594296 = validateParameter(valid_594296, JString, required = false,
                                 default = nil)
  if valid_594296 != nil:
    section.add "nameContains", valid_594296
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
  var valid_594297 = header.getOrDefault("X-Amz-Date")
  valid_594297 = validateParameter(valid_594297, JString, required = false,
                                 default = nil)
  if valid_594297 != nil:
    section.add "X-Amz-Date", valid_594297
  var valid_594298 = header.getOrDefault("X-Amz-Security-Token")
  valid_594298 = validateParameter(valid_594298, JString, required = false,
                                 default = nil)
  if valid_594298 != nil:
    section.add "X-Amz-Security-Token", valid_594298
  var valid_594299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594299 = validateParameter(valid_594299, JString, required = false,
                                 default = nil)
  if valid_594299 != nil:
    section.add "X-Amz-Content-Sha256", valid_594299
  var valid_594300 = header.getOrDefault("X-Amz-Algorithm")
  valid_594300 = validateParameter(valid_594300, JString, required = false,
                                 default = nil)
  if valid_594300 != nil:
    section.add "X-Amz-Algorithm", valid_594300
  var valid_594301 = header.getOrDefault("X-Amz-Signature")
  valid_594301 = validateParameter(valid_594301, JString, required = false,
                                 default = nil)
  if valid_594301 != nil:
    section.add "X-Amz-Signature", valid_594301
  var valid_594302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594302 = validateParameter(valid_594302, JString, required = false,
                                 default = nil)
  if valid_594302 != nil:
    section.add "X-Amz-SignedHeaders", valid_594302
  var valid_594303 = header.getOrDefault("X-Amz-Credential")
  valid_594303 = validateParameter(valid_594303, JString, required = false,
                                 default = nil)
  if valid_594303 != nil:
    section.add "X-Amz-Credential", valid_594303
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594304: Call_GetBotAliases_594290; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of aliases for a specified Amazon Lex bot.</p> <p>This operation requires permissions for the <code>lex:GetBotAliases</code> action.</p>
  ## 
  let valid = call_594304.validator(path, query, header, formData, body)
  let scheme = call_594304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594304.url(scheme.get, call_594304.host, call_594304.base,
                         call_594304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594304, url, valid)

proc call*(call_594305: Call_GetBotAliases_594290; botName: string;
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
  var path_594306 = newJObject()
  var query_594307 = newJObject()
  add(query_594307, "maxResults", newJInt(maxResults))
  add(query_594307, "nextToken", newJString(nextToken))
  add(path_594306, "botName", newJString(botName))
  add(query_594307, "nameContains", newJString(nameContains))
  result = call_594305.call(path_594306, query_594307, nil, nil, nil)

var getBotAliases* = Call_GetBotAliases_594290(name: "getBotAliases",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/aliases/", validator: validate_GetBotAliases_594291,
    base: "/", url: url_GetBotAliases_594292, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBotChannelAssociations_594308 = ref object of OpenApiRestCall_593438
proc url_GetBotChannelAssociations_594310(protocol: Scheme; host: string;
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

proc validate_GetBotChannelAssociations_594309(path: JsonNode; query: JsonNode;
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
  var valid_594311 = path.getOrDefault("botName")
  valid_594311 = validateParameter(valid_594311, JString, required = true,
                                 default = nil)
  if valid_594311 != nil:
    section.add "botName", valid_594311
  var valid_594312 = path.getOrDefault("aliasName")
  valid_594312 = validateParameter(valid_594312, JString, required = true,
                                 default = nil)
  if valid_594312 != nil:
    section.add "aliasName", valid_594312
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of associations to return in the response. The default is 50. 
  ##   nextToken: JString
  ##            : A pagination token for fetching the next page of associations. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of associations, specify the pagination token in the next request. 
  ##   nameContains: JString
  ##               : Substring to match in channel association names. An association will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz." To return all bot channel associations, use a hyphen ("-") as the <code>nameContains</code> parameter.
  section = newJObject()
  var valid_594313 = query.getOrDefault("maxResults")
  valid_594313 = validateParameter(valid_594313, JInt, required = false, default = nil)
  if valid_594313 != nil:
    section.add "maxResults", valid_594313
  var valid_594314 = query.getOrDefault("nextToken")
  valid_594314 = validateParameter(valid_594314, JString, required = false,
                                 default = nil)
  if valid_594314 != nil:
    section.add "nextToken", valid_594314
  var valid_594315 = query.getOrDefault("nameContains")
  valid_594315 = validateParameter(valid_594315, JString, required = false,
                                 default = nil)
  if valid_594315 != nil:
    section.add "nameContains", valid_594315
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
  var valid_594316 = header.getOrDefault("X-Amz-Date")
  valid_594316 = validateParameter(valid_594316, JString, required = false,
                                 default = nil)
  if valid_594316 != nil:
    section.add "X-Amz-Date", valid_594316
  var valid_594317 = header.getOrDefault("X-Amz-Security-Token")
  valid_594317 = validateParameter(valid_594317, JString, required = false,
                                 default = nil)
  if valid_594317 != nil:
    section.add "X-Amz-Security-Token", valid_594317
  var valid_594318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594318 = validateParameter(valid_594318, JString, required = false,
                                 default = nil)
  if valid_594318 != nil:
    section.add "X-Amz-Content-Sha256", valid_594318
  var valid_594319 = header.getOrDefault("X-Amz-Algorithm")
  valid_594319 = validateParameter(valid_594319, JString, required = false,
                                 default = nil)
  if valid_594319 != nil:
    section.add "X-Amz-Algorithm", valid_594319
  var valid_594320 = header.getOrDefault("X-Amz-Signature")
  valid_594320 = validateParameter(valid_594320, JString, required = false,
                                 default = nil)
  if valid_594320 != nil:
    section.add "X-Amz-Signature", valid_594320
  var valid_594321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594321 = validateParameter(valid_594321, JString, required = false,
                                 default = nil)
  if valid_594321 != nil:
    section.add "X-Amz-SignedHeaders", valid_594321
  var valid_594322 = header.getOrDefault("X-Amz-Credential")
  valid_594322 = validateParameter(valid_594322, JString, required = false,
                                 default = nil)
  if valid_594322 != nil:
    section.add "X-Amz-Credential", valid_594322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594323: Call_GetBotChannelAssociations_594308; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns a list of all of the channels associated with the specified bot. </p> <p>The <code>GetBotChannelAssociations</code> operation requires permissions for the <code>lex:GetBotChannelAssociations</code> action.</p>
  ## 
  let valid = call_594323.validator(path, query, header, formData, body)
  let scheme = call_594323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594323.url(scheme.get, call_594323.host, call_594323.base,
                         call_594323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594323, url, valid)

proc call*(call_594324: Call_GetBotChannelAssociations_594308; botName: string;
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
  var path_594325 = newJObject()
  var query_594326 = newJObject()
  add(query_594326, "maxResults", newJInt(maxResults))
  add(query_594326, "nextToken", newJString(nextToken))
  add(path_594325, "botName", newJString(botName))
  add(query_594326, "nameContains", newJString(nameContains))
  add(path_594325, "aliasName", newJString(aliasName))
  result = call_594324.call(path_594325, query_594326, nil, nil, nil)

var getBotChannelAssociations* = Call_GetBotChannelAssociations_594308(
    name: "getBotChannelAssociations", meth: HttpMethod.HttpGet,
    host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/aliases/{aliasName}/channels/",
    validator: validate_GetBotChannelAssociations_594309, base: "/",
    url: url_GetBotChannelAssociations_594310,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBotVersions_594327 = ref object of OpenApiRestCall_593438
proc url_GetBotVersions_594329(protocol: Scheme; host: string; base: string;
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

proc validate_GetBotVersions_594328(path: JsonNode; query: JsonNode;
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
  var valid_594330 = path.getOrDefault("name")
  valid_594330 = validateParameter(valid_594330, JString, required = true,
                                 default = nil)
  if valid_594330 != nil:
    section.add "name", valid_594330
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of bot versions to return in the response. The default is 10.
  ##   nextToken: JString
  ##            : A pagination token for fetching the next page of bot versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  section = newJObject()
  var valid_594331 = query.getOrDefault("maxResults")
  valid_594331 = validateParameter(valid_594331, JInt, required = false, default = nil)
  if valid_594331 != nil:
    section.add "maxResults", valid_594331
  var valid_594332 = query.getOrDefault("nextToken")
  valid_594332 = validateParameter(valid_594332, JString, required = false,
                                 default = nil)
  if valid_594332 != nil:
    section.add "nextToken", valid_594332
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
  var valid_594333 = header.getOrDefault("X-Amz-Date")
  valid_594333 = validateParameter(valid_594333, JString, required = false,
                                 default = nil)
  if valid_594333 != nil:
    section.add "X-Amz-Date", valid_594333
  var valid_594334 = header.getOrDefault("X-Amz-Security-Token")
  valid_594334 = validateParameter(valid_594334, JString, required = false,
                                 default = nil)
  if valid_594334 != nil:
    section.add "X-Amz-Security-Token", valid_594334
  var valid_594335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594335 = validateParameter(valid_594335, JString, required = false,
                                 default = nil)
  if valid_594335 != nil:
    section.add "X-Amz-Content-Sha256", valid_594335
  var valid_594336 = header.getOrDefault("X-Amz-Algorithm")
  valid_594336 = validateParameter(valid_594336, JString, required = false,
                                 default = nil)
  if valid_594336 != nil:
    section.add "X-Amz-Algorithm", valid_594336
  var valid_594337 = header.getOrDefault("X-Amz-Signature")
  valid_594337 = validateParameter(valid_594337, JString, required = false,
                                 default = nil)
  if valid_594337 != nil:
    section.add "X-Amz-Signature", valid_594337
  var valid_594338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594338 = validateParameter(valid_594338, JString, required = false,
                                 default = nil)
  if valid_594338 != nil:
    section.add "X-Amz-SignedHeaders", valid_594338
  var valid_594339 = header.getOrDefault("X-Amz-Credential")
  valid_594339 = validateParameter(valid_594339, JString, required = false,
                                 default = nil)
  if valid_594339 != nil:
    section.add "X-Amz-Credential", valid_594339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594340: Call_GetBotVersions_594327; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about all of the versions of a bot.</p> <p>The <code>GetBotVersions</code> operation returns a <code>BotMetadata</code> object for each version of a bot. For example, if a bot has three numbered versions, the <code>GetBotVersions</code> operation returns four <code>BotMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetBotVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetBotVersions</code> action.</p>
  ## 
  let valid = call_594340.validator(path, query, header, formData, body)
  let scheme = call_594340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594340.url(scheme.get, call_594340.host, call_594340.base,
                         call_594340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594340, url, valid)

proc call*(call_594341: Call_GetBotVersions_594327; name: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## getBotVersions
  ## <p>Gets information about all of the versions of a bot.</p> <p>The <code>GetBotVersions</code> operation returns a <code>BotMetadata</code> object for each version of a bot. For example, if a bot has three numbered versions, the <code>GetBotVersions</code> operation returns four <code>BotMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetBotVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetBotVersions</code> action.</p>
  ##   name: string (required)
  ##       : The name of the bot for which versions should be returned.
  ##   maxResults: int
  ##             : The maximum number of bot versions to return in the response. The default is 10.
  ##   nextToken: string
  ##            : A pagination token for fetching the next page of bot versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  var path_594342 = newJObject()
  var query_594343 = newJObject()
  add(path_594342, "name", newJString(name))
  add(query_594343, "maxResults", newJInt(maxResults))
  add(query_594343, "nextToken", newJString(nextToken))
  result = call_594341.call(path_594342, query_594343, nil, nil, nil)

var getBotVersions* = Call_GetBotVersions_594327(name: "getBotVersions",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/bots/{name}/versions/", validator: validate_GetBotVersions_594328,
    base: "/", url: url_GetBotVersions_594329, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBots_594344 = ref object of OpenApiRestCall_593438
proc url_GetBots_594346(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetBots_594345(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594347 = query.getOrDefault("maxResults")
  valid_594347 = validateParameter(valid_594347, JInt, required = false, default = nil)
  if valid_594347 != nil:
    section.add "maxResults", valid_594347
  var valid_594348 = query.getOrDefault("nextToken")
  valid_594348 = validateParameter(valid_594348, JString, required = false,
                                 default = nil)
  if valid_594348 != nil:
    section.add "nextToken", valid_594348
  var valid_594349 = query.getOrDefault("nameContains")
  valid_594349 = validateParameter(valid_594349, JString, required = false,
                                 default = nil)
  if valid_594349 != nil:
    section.add "nameContains", valid_594349
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
  var valid_594350 = header.getOrDefault("X-Amz-Date")
  valid_594350 = validateParameter(valid_594350, JString, required = false,
                                 default = nil)
  if valid_594350 != nil:
    section.add "X-Amz-Date", valid_594350
  var valid_594351 = header.getOrDefault("X-Amz-Security-Token")
  valid_594351 = validateParameter(valid_594351, JString, required = false,
                                 default = nil)
  if valid_594351 != nil:
    section.add "X-Amz-Security-Token", valid_594351
  var valid_594352 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594352 = validateParameter(valid_594352, JString, required = false,
                                 default = nil)
  if valid_594352 != nil:
    section.add "X-Amz-Content-Sha256", valid_594352
  var valid_594353 = header.getOrDefault("X-Amz-Algorithm")
  valid_594353 = validateParameter(valid_594353, JString, required = false,
                                 default = nil)
  if valid_594353 != nil:
    section.add "X-Amz-Algorithm", valid_594353
  var valid_594354 = header.getOrDefault("X-Amz-Signature")
  valid_594354 = validateParameter(valid_594354, JString, required = false,
                                 default = nil)
  if valid_594354 != nil:
    section.add "X-Amz-Signature", valid_594354
  var valid_594355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594355 = validateParameter(valid_594355, JString, required = false,
                                 default = nil)
  if valid_594355 != nil:
    section.add "X-Amz-SignedHeaders", valid_594355
  var valid_594356 = header.getOrDefault("X-Amz-Credential")
  valid_594356 = validateParameter(valid_594356, JString, required = false,
                                 default = nil)
  if valid_594356 != nil:
    section.add "X-Amz-Credential", valid_594356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594357: Call_GetBots_594344; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns bot information as follows: </p> <ul> <li> <p>If you provide the <code>nameContains</code> field, the response includes information for the <code>$LATEST</code> version of all bots whose name contains the specified string.</p> </li> <li> <p>If you don't specify the <code>nameContains</code> field, the operation returns information about the <code>$LATEST</code> version of all of your bots.</p> </li> </ul> <p>This operation requires permission for the <code>lex:GetBots</code> action.</p>
  ## 
  let valid = call_594357.validator(path, query, header, formData, body)
  let scheme = call_594357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594357.url(scheme.get, call_594357.host, call_594357.base,
                         call_594357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594357, url, valid)

proc call*(call_594358: Call_GetBots_594344; maxResults: int = 0;
          nextToken: string = ""; nameContains: string = ""): Recallable =
  ## getBots
  ## <p>Returns bot information as follows: </p> <ul> <li> <p>If you provide the <code>nameContains</code> field, the response includes information for the <code>$LATEST</code> version of all bots whose name contains the specified string.</p> </li> <li> <p>If you don't specify the <code>nameContains</code> field, the operation returns information about the <code>$LATEST</code> version of all of your bots.</p> </li> </ul> <p>This operation requires permission for the <code>lex:GetBots</code> action.</p>
  ##   maxResults: int
  ##             : The maximum number of bots to return in the response that the request will return. The default is 10.
  ##   nextToken: string
  ##            : A pagination token that fetches the next page of bots. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of bots, specify the pagination token in the next request. 
  ##   nameContains: string
  ##               : Substring to match in bot names. A bot will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  var query_594359 = newJObject()
  add(query_594359, "maxResults", newJInt(maxResults))
  add(query_594359, "nextToken", newJString(nextToken))
  add(query_594359, "nameContains", newJString(nameContains))
  result = call_594358.call(nil, query_594359, nil, nil, nil)

var getBots* = Call_GetBots_594344(name: "getBots", meth: HttpMethod.HttpGet,
                                host: "models.lex.amazonaws.com", route: "/bots/",
                                validator: validate_GetBots_594345, base: "/",
                                url: url_GetBots_594346,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBuiltinIntent_594360 = ref object of OpenApiRestCall_593438
proc url_GetBuiltinIntent_594362(protocol: Scheme; host: string; base: string;
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

proc validate_GetBuiltinIntent_594361(path: JsonNode; query: JsonNode;
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
  var valid_594363 = path.getOrDefault("signature")
  valid_594363 = validateParameter(valid_594363, JString, required = true,
                                 default = nil)
  if valid_594363 != nil:
    section.add "signature", valid_594363
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
  var valid_594364 = header.getOrDefault("X-Amz-Date")
  valid_594364 = validateParameter(valid_594364, JString, required = false,
                                 default = nil)
  if valid_594364 != nil:
    section.add "X-Amz-Date", valid_594364
  var valid_594365 = header.getOrDefault("X-Amz-Security-Token")
  valid_594365 = validateParameter(valid_594365, JString, required = false,
                                 default = nil)
  if valid_594365 != nil:
    section.add "X-Amz-Security-Token", valid_594365
  var valid_594366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594366 = validateParameter(valid_594366, JString, required = false,
                                 default = nil)
  if valid_594366 != nil:
    section.add "X-Amz-Content-Sha256", valid_594366
  var valid_594367 = header.getOrDefault("X-Amz-Algorithm")
  valid_594367 = validateParameter(valid_594367, JString, required = false,
                                 default = nil)
  if valid_594367 != nil:
    section.add "X-Amz-Algorithm", valid_594367
  var valid_594368 = header.getOrDefault("X-Amz-Signature")
  valid_594368 = validateParameter(valid_594368, JString, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "X-Amz-Signature", valid_594368
  var valid_594369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594369 = validateParameter(valid_594369, JString, required = false,
                                 default = nil)
  if valid_594369 != nil:
    section.add "X-Amz-SignedHeaders", valid_594369
  var valid_594370 = header.getOrDefault("X-Amz-Credential")
  valid_594370 = validateParameter(valid_594370, JString, required = false,
                                 default = nil)
  if valid_594370 != nil:
    section.add "X-Amz-Credential", valid_594370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594371: Call_GetBuiltinIntent_594360; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a built-in intent.</p> <p>This operation requires permission for the <code>lex:GetBuiltinIntent</code> action.</p>
  ## 
  let valid = call_594371.validator(path, query, header, formData, body)
  let scheme = call_594371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594371.url(scheme.get, call_594371.host, call_594371.base,
                         call_594371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594371, url, valid)

proc call*(call_594372: Call_GetBuiltinIntent_594360; signature: string): Recallable =
  ## getBuiltinIntent
  ## <p>Returns information about a built-in intent.</p> <p>This operation requires permission for the <code>lex:GetBuiltinIntent</code> action.</p>
  ##   signature: string (required)
  ##            : The unique identifier for a built-in intent. To find the signature for an intent, see <a 
  ## href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/standard-intents">Standard Built-in Intents</a> in the <i>Alexa Skills Kit</i>.
  var path_594373 = newJObject()
  add(path_594373, "signature", newJString(signature))
  result = call_594372.call(path_594373, nil, nil, nil, nil)

var getBuiltinIntent* = Call_GetBuiltinIntent_594360(name: "getBuiltinIntent",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/builtins/intents/{signature}", validator: validate_GetBuiltinIntent_594361,
    base: "/", url: url_GetBuiltinIntent_594362,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBuiltinIntents_594374 = ref object of OpenApiRestCall_593438
proc url_GetBuiltinIntents_594376(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetBuiltinIntents_594375(path: JsonNode; query: JsonNode;
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
  var valid_594390 = query.getOrDefault("locale")
  valid_594390 = validateParameter(valid_594390, JString, required = false,
                                 default = newJString("en-US"))
  if valid_594390 != nil:
    section.add "locale", valid_594390
  var valid_594391 = query.getOrDefault("maxResults")
  valid_594391 = validateParameter(valid_594391, JInt, required = false, default = nil)
  if valid_594391 != nil:
    section.add "maxResults", valid_594391
  var valid_594392 = query.getOrDefault("nextToken")
  valid_594392 = validateParameter(valid_594392, JString, required = false,
                                 default = nil)
  if valid_594392 != nil:
    section.add "nextToken", valid_594392
  var valid_594393 = query.getOrDefault("signatureContains")
  valid_594393 = validateParameter(valid_594393, JString, required = false,
                                 default = nil)
  if valid_594393 != nil:
    section.add "signatureContains", valid_594393
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
  var valid_594394 = header.getOrDefault("X-Amz-Date")
  valid_594394 = validateParameter(valid_594394, JString, required = false,
                                 default = nil)
  if valid_594394 != nil:
    section.add "X-Amz-Date", valid_594394
  var valid_594395 = header.getOrDefault("X-Amz-Security-Token")
  valid_594395 = validateParameter(valid_594395, JString, required = false,
                                 default = nil)
  if valid_594395 != nil:
    section.add "X-Amz-Security-Token", valid_594395
  var valid_594396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594396 = validateParameter(valid_594396, JString, required = false,
                                 default = nil)
  if valid_594396 != nil:
    section.add "X-Amz-Content-Sha256", valid_594396
  var valid_594397 = header.getOrDefault("X-Amz-Algorithm")
  valid_594397 = validateParameter(valid_594397, JString, required = false,
                                 default = nil)
  if valid_594397 != nil:
    section.add "X-Amz-Algorithm", valid_594397
  var valid_594398 = header.getOrDefault("X-Amz-Signature")
  valid_594398 = validateParameter(valid_594398, JString, required = false,
                                 default = nil)
  if valid_594398 != nil:
    section.add "X-Amz-Signature", valid_594398
  var valid_594399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594399 = validateParameter(valid_594399, JString, required = false,
                                 default = nil)
  if valid_594399 != nil:
    section.add "X-Amz-SignedHeaders", valid_594399
  var valid_594400 = header.getOrDefault("X-Amz-Credential")
  valid_594400 = validateParameter(valid_594400, JString, required = false,
                                 default = nil)
  if valid_594400 != nil:
    section.add "X-Amz-Credential", valid_594400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594401: Call_GetBuiltinIntents_594374; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of built-in intents that meet the specified criteria.</p> <p>This operation requires permission for the <code>lex:GetBuiltinIntents</code> action.</p>
  ## 
  let valid = call_594401.validator(path, query, header, formData, body)
  let scheme = call_594401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594401.url(scheme.get, call_594401.host, call_594401.base,
                         call_594401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594401, url, valid)

proc call*(call_594402: Call_GetBuiltinIntents_594374; locale: string = "en-US";
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
  var query_594403 = newJObject()
  add(query_594403, "locale", newJString(locale))
  add(query_594403, "maxResults", newJInt(maxResults))
  add(query_594403, "nextToken", newJString(nextToken))
  add(query_594403, "signatureContains", newJString(signatureContains))
  result = call_594402.call(nil, query_594403, nil, nil, nil)

var getBuiltinIntents* = Call_GetBuiltinIntents_594374(name: "getBuiltinIntents",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/builtins/intents/", validator: validate_GetBuiltinIntents_594375,
    base: "/", url: url_GetBuiltinIntents_594376,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBuiltinSlotTypes_594404 = ref object of OpenApiRestCall_593438
proc url_GetBuiltinSlotTypes_594406(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetBuiltinSlotTypes_594405(path: JsonNode; query: JsonNode;
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
  var valid_594407 = query.getOrDefault("locale")
  valid_594407 = validateParameter(valid_594407, JString, required = false,
                                 default = newJString("en-US"))
  if valid_594407 != nil:
    section.add "locale", valid_594407
  var valid_594408 = query.getOrDefault("maxResults")
  valid_594408 = validateParameter(valid_594408, JInt, required = false, default = nil)
  if valid_594408 != nil:
    section.add "maxResults", valid_594408
  var valid_594409 = query.getOrDefault("nextToken")
  valid_594409 = validateParameter(valid_594409, JString, required = false,
                                 default = nil)
  if valid_594409 != nil:
    section.add "nextToken", valid_594409
  var valid_594410 = query.getOrDefault("signatureContains")
  valid_594410 = validateParameter(valid_594410, JString, required = false,
                                 default = nil)
  if valid_594410 != nil:
    section.add "signatureContains", valid_594410
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
  var valid_594411 = header.getOrDefault("X-Amz-Date")
  valid_594411 = validateParameter(valid_594411, JString, required = false,
                                 default = nil)
  if valid_594411 != nil:
    section.add "X-Amz-Date", valid_594411
  var valid_594412 = header.getOrDefault("X-Amz-Security-Token")
  valid_594412 = validateParameter(valid_594412, JString, required = false,
                                 default = nil)
  if valid_594412 != nil:
    section.add "X-Amz-Security-Token", valid_594412
  var valid_594413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594413 = validateParameter(valid_594413, JString, required = false,
                                 default = nil)
  if valid_594413 != nil:
    section.add "X-Amz-Content-Sha256", valid_594413
  var valid_594414 = header.getOrDefault("X-Amz-Algorithm")
  valid_594414 = validateParameter(valid_594414, JString, required = false,
                                 default = nil)
  if valid_594414 != nil:
    section.add "X-Amz-Algorithm", valid_594414
  var valid_594415 = header.getOrDefault("X-Amz-Signature")
  valid_594415 = validateParameter(valid_594415, JString, required = false,
                                 default = nil)
  if valid_594415 != nil:
    section.add "X-Amz-Signature", valid_594415
  var valid_594416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594416 = validateParameter(valid_594416, JString, required = false,
                                 default = nil)
  if valid_594416 != nil:
    section.add "X-Amz-SignedHeaders", valid_594416
  var valid_594417 = header.getOrDefault("X-Amz-Credential")
  valid_594417 = validateParameter(valid_594417, JString, required = false,
                                 default = nil)
  if valid_594417 != nil:
    section.add "X-Amz-Credential", valid_594417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594418: Call_GetBuiltinSlotTypes_594404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of built-in slot types that meet the specified criteria.</p> <p>For a list of built-in slot types, see <a href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/slot-type-reference">Slot Type Reference</a> in the <i>Alexa Skills Kit</i>.</p> <p>This operation requires permission for the <code>lex:GetBuiltInSlotTypes</code> action.</p>
  ## 
  let valid = call_594418.validator(path, query, header, formData, body)
  let scheme = call_594418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594418.url(scheme.get, call_594418.host, call_594418.base,
                         call_594418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594418, url, valid)

proc call*(call_594419: Call_GetBuiltinSlotTypes_594404; locale: string = "en-US";
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
  var query_594420 = newJObject()
  add(query_594420, "locale", newJString(locale))
  add(query_594420, "maxResults", newJInt(maxResults))
  add(query_594420, "nextToken", newJString(nextToken))
  add(query_594420, "signatureContains", newJString(signatureContains))
  result = call_594419.call(nil, query_594420, nil, nil, nil)

var getBuiltinSlotTypes* = Call_GetBuiltinSlotTypes_594404(
    name: "getBuiltinSlotTypes", meth: HttpMethod.HttpGet,
    host: "models.lex.amazonaws.com", route: "/builtins/slottypes/",
    validator: validate_GetBuiltinSlotTypes_594405, base: "/",
    url: url_GetBuiltinSlotTypes_594406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExport_594421 = ref object of OpenApiRestCall_593438
proc url_GetExport_594423(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetExport_594422(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594424 = query.getOrDefault("exportType")
  valid_594424 = validateParameter(valid_594424, JString, required = true,
                                 default = newJString("ALEXA_SKILLS_KIT"))
  if valid_594424 != nil:
    section.add "exportType", valid_594424
  var valid_594425 = query.getOrDefault("name")
  valid_594425 = validateParameter(valid_594425, JString, required = true,
                                 default = nil)
  if valid_594425 != nil:
    section.add "name", valid_594425
  var valid_594426 = query.getOrDefault("version")
  valid_594426 = validateParameter(valid_594426, JString, required = true,
                                 default = nil)
  if valid_594426 != nil:
    section.add "version", valid_594426
  var valid_594427 = query.getOrDefault("resourceType")
  valid_594427 = validateParameter(valid_594427, JString, required = true,
                                 default = newJString("BOT"))
  if valid_594427 != nil:
    section.add "resourceType", valid_594427
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
  var valid_594428 = header.getOrDefault("X-Amz-Date")
  valid_594428 = validateParameter(valid_594428, JString, required = false,
                                 default = nil)
  if valid_594428 != nil:
    section.add "X-Amz-Date", valid_594428
  var valid_594429 = header.getOrDefault("X-Amz-Security-Token")
  valid_594429 = validateParameter(valid_594429, JString, required = false,
                                 default = nil)
  if valid_594429 != nil:
    section.add "X-Amz-Security-Token", valid_594429
  var valid_594430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594430 = validateParameter(valid_594430, JString, required = false,
                                 default = nil)
  if valid_594430 != nil:
    section.add "X-Amz-Content-Sha256", valid_594430
  var valid_594431 = header.getOrDefault("X-Amz-Algorithm")
  valid_594431 = validateParameter(valid_594431, JString, required = false,
                                 default = nil)
  if valid_594431 != nil:
    section.add "X-Amz-Algorithm", valid_594431
  var valid_594432 = header.getOrDefault("X-Amz-Signature")
  valid_594432 = validateParameter(valid_594432, JString, required = false,
                                 default = nil)
  if valid_594432 != nil:
    section.add "X-Amz-Signature", valid_594432
  var valid_594433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594433 = validateParameter(valid_594433, JString, required = false,
                                 default = nil)
  if valid_594433 != nil:
    section.add "X-Amz-SignedHeaders", valid_594433
  var valid_594434 = header.getOrDefault("X-Amz-Credential")
  valid_594434 = validateParameter(valid_594434, JString, required = false,
                                 default = nil)
  if valid_594434 != nil:
    section.add "X-Amz-Credential", valid_594434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594435: Call_GetExport_594421; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Exports the contents of a Amazon Lex resource in a specified format. 
  ## 
  let valid = call_594435.validator(path, query, header, formData, body)
  let scheme = call_594435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594435.url(scheme.get, call_594435.host, call_594435.base,
                         call_594435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594435, url, valid)

proc call*(call_594436: Call_GetExport_594421; name: string; version: string;
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
  var query_594437 = newJObject()
  add(query_594437, "exportType", newJString(exportType))
  add(query_594437, "name", newJString(name))
  add(query_594437, "version", newJString(version))
  add(query_594437, "resourceType", newJString(resourceType))
  result = call_594436.call(nil, query_594437, nil, nil, nil)

var getExport* = Call_GetExport_594421(name: "getExport", meth: HttpMethod.HttpGet,
                                    host: "models.lex.amazonaws.com", route: "/exports/#name&version&resourceType&exportType",
                                    validator: validate_GetExport_594422,
                                    base: "/", url: url_GetExport_594423,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImport_594438 = ref object of OpenApiRestCall_593438
proc url_GetImport_594440(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetImport_594439(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594441 = path.getOrDefault("importId")
  valid_594441 = validateParameter(valid_594441, JString, required = true,
                                 default = nil)
  if valid_594441 != nil:
    section.add "importId", valid_594441
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
  var valid_594442 = header.getOrDefault("X-Amz-Date")
  valid_594442 = validateParameter(valid_594442, JString, required = false,
                                 default = nil)
  if valid_594442 != nil:
    section.add "X-Amz-Date", valid_594442
  var valid_594443 = header.getOrDefault("X-Amz-Security-Token")
  valid_594443 = validateParameter(valid_594443, JString, required = false,
                                 default = nil)
  if valid_594443 != nil:
    section.add "X-Amz-Security-Token", valid_594443
  var valid_594444 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594444 = validateParameter(valid_594444, JString, required = false,
                                 default = nil)
  if valid_594444 != nil:
    section.add "X-Amz-Content-Sha256", valid_594444
  var valid_594445 = header.getOrDefault("X-Amz-Algorithm")
  valid_594445 = validateParameter(valid_594445, JString, required = false,
                                 default = nil)
  if valid_594445 != nil:
    section.add "X-Amz-Algorithm", valid_594445
  var valid_594446 = header.getOrDefault("X-Amz-Signature")
  valid_594446 = validateParameter(valid_594446, JString, required = false,
                                 default = nil)
  if valid_594446 != nil:
    section.add "X-Amz-Signature", valid_594446
  var valid_594447 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594447 = validateParameter(valid_594447, JString, required = false,
                                 default = nil)
  if valid_594447 != nil:
    section.add "X-Amz-SignedHeaders", valid_594447
  var valid_594448 = header.getOrDefault("X-Amz-Credential")
  valid_594448 = validateParameter(valid_594448, JString, required = false,
                                 default = nil)
  if valid_594448 != nil:
    section.add "X-Amz-Credential", valid_594448
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594449: Call_GetImport_594438; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about an import job started with the <code>StartImport</code> operation.
  ## 
  let valid = call_594449.validator(path, query, header, formData, body)
  let scheme = call_594449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594449.url(scheme.get, call_594449.host, call_594449.base,
                         call_594449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594449, url, valid)

proc call*(call_594450: Call_GetImport_594438; importId: string): Recallable =
  ## getImport
  ## Gets information about an import job started with the <code>StartImport</code> operation.
  ##   importId: string (required)
  ##           : The identifier of the import job information to return.
  var path_594451 = newJObject()
  add(path_594451, "importId", newJString(importId))
  result = call_594450.call(path_594451, nil, nil, nil, nil)

var getImport* = Call_GetImport_594438(name: "getImport", meth: HttpMethod.HttpGet,
                                    host: "models.lex.amazonaws.com",
                                    route: "/imports/{importId}",
                                    validator: validate_GetImport_594439,
                                    base: "/", url: url_GetImport_594440,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntentVersions_594452 = ref object of OpenApiRestCall_593438
proc url_GetIntentVersions_594454(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntentVersions_594453(path: JsonNode; query: JsonNode;
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
  var valid_594455 = path.getOrDefault("name")
  valid_594455 = validateParameter(valid_594455, JString, required = true,
                                 default = nil)
  if valid_594455 != nil:
    section.add "name", valid_594455
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of intent versions to return in the response. The default is 10.
  ##   nextToken: JString
  ##            : A pagination token for fetching the next page of intent versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  section = newJObject()
  var valid_594456 = query.getOrDefault("maxResults")
  valid_594456 = validateParameter(valid_594456, JInt, required = false, default = nil)
  if valid_594456 != nil:
    section.add "maxResults", valid_594456
  var valid_594457 = query.getOrDefault("nextToken")
  valid_594457 = validateParameter(valid_594457, JString, required = false,
                                 default = nil)
  if valid_594457 != nil:
    section.add "nextToken", valid_594457
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
  var valid_594458 = header.getOrDefault("X-Amz-Date")
  valid_594458 = validateParameter(valid_594458, JString, required = false,
                                 default = nil)
  if valid_594458 != nil:
    section.add "X-Amz-Date", valid_594458
  var valid_594459 = header.getOrDefault("X-Amz-Security-Token")
  valid_594459 = validateParameter(valid_594459, JString, required = false,
                                 default = nil)
  if valid_594459 != nil:
    section.add "X-Amz-Security-Token", valid_594459
  var valid_594460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594460 = validateParameter(valid_594460, JString, required = false,
                                 default = nil)
  if valid_594460 != nil:
    section.add "X-Amz-Content-Sha256", valid_594460
  var valid_594461 = header.getOrDefault("X-Amz-Algorithm")
  valid_594461 = validateParameter(valid_594461, JString, required = false,
                                 default = nil)
  if valid_594461 != nil:
    section.add "X-Amz-Algorithm", valid_594461
  var valid_594462 = header.getOrDefault("X-Amz-Signature")
  valid_594462 = validateParameter(valid_594462, JString, required = false,
                                 default = nil)
  if valid_594462 != nil:
    section.add "X-Amz-Signature", valid_594462
  var valid_594463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594463 = validateParameter(valid_594463, JString, required = false,
                                 default = nil)
  if valid_594463 != nil:
    section.add "X-Amz-SignedHeaders", valid_594463
  var valid_594464 = header.getOrDefault("X-Amz-Credential")
  valid_594464 = validateParameter(valid_594464, JString, required = false,
                                 default = nil)
  if valid_594464 != nil:
    section.add "X-Amz-Credential", valid_594464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594465: Call_GetIntentVersions_594452; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about all of the versions of an intent.</p> <p>The <code>GetIntentVersions</code> operation returns an <code>IntentMetadata</code> object for each version of an intent. For example, if an intent has three numbered versions, the <code>GetIntentVersions</code> operation returns four <code>IntentMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetIntentVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetIntentVersions</code> action.</p>
  ## 
  let valid = call_594465.validator(path, query, header, formData, body)
  let scheme = call_594465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594465.url(scheme.get, call_594465.host, call_594465.base,
                         call_594465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594465, url, valid)

proc call*(call_594466: Call_GetIntentVersions_594452; name: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## getIntentVersions
  ## <p>Gets information about all of the versions of an intent.</p> <p>The <code>GetIntentVersions</code> operation returns an <code>IntentMetadata</code> object for each version of an intent. For example, if an intent has three numbered versions, the <code>GetIntentVersions</code> operation returns four <code>IntentMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetIntentVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetIntentVersions</code> action.</p>
  ##   name: string (required)
  ##       : The name of the intent for which versions should be returned.
  ##   maxResults: int
  ##             : The maximum number of intent versions to return in the response. The default is 10.
  ##   nextToken: string
  ##            : A pagination token for fetching the next page of intent versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  var path_594467 = newJObject()
  var query_594468 = newJObject()
  add(path_594467, "name", newJString(name))
  add(query_594468, "maxResults", newJInt(maxResults))
  add(query_594468, "nextToken", newJString(nextToken))
  result = call_594466.call(path_594467, query_594468, nil, nil, nil)

var getIntentVersions* = Call_GetIntentVersions_594452(name: "getIntentVersions",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/intents/{name}/versions/", validator: validate_GetIntentVersions_594453,
    base: "/", url: url_GetIntentVersions_594454,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntents_594469 = ref object of OpenApiRestCall_593438
proc url_GetIntents_594471(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetIntents_594470(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594472 = query.getOrDefault("maxResults")
  valid_594472 = validateParameter(valid_594472, JInt, required = false, default = nil)
  if valid_594472 != nil:
    section.add "maxResults", valid_594472
  var valid_594473 = query.getOrDefault("nextToken")
  valid_594473 = validateParameter(valid_594473, JString, required = false,
                                 default = nil)
  if valid_594473 != nil:
    section.add "nextToken", valid_594473
  var valid_594474 = query.getOrDefault("nameContains")
  valid_594474 = validateParameter(valid_594474, JString, required = false,
                                 default = nil)
  if valid_594474 != nil:
    section.add "nameContains", valid_594474
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
  var valid_594475 = header.getOrDefault("X-Amz-Date")
  valid_594475 = validateParameter(valid_594475, JString, required = false,
                                 default = nil)
  if valid_594475 != nil:
    section.add "X-Amz-Date", valid_594475
  var valid_594476 = header.getOrDefault("X-Amz-Security-Token")
  valid_594476 = validateParameter(valid_594476, JString, required = false,
                                 default = nil)
  if valid_594476 != nil:
    section.add "X-Amz-Security-Token", valid_594476
  var valid_594477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594477 = validateParameter(valid_594477, JString, required = false,
                                 default = nil)
  if valid_594477 != nil:
    section.add "X-Amz-Content-Sha256", valid_594477
  var valid_594478 = header.getOrDefault("X-Amz-Algorithm")
  valid_594478 = validateParameter(valid_594478, JString, required = false,
                                 default = nil)
  if valid_594478 != nil:
    section.add "X-Amz-Algorithm", valid_594478
  var valid_594479 = header.getOrDefault("X-Amz-Signature")
  valid_594479 = validateParameter(valid_594479, JString, required = false,
                                 default = nil)
  if valid_594479 != nil:
    section.add "X-Amz-Signature", valid_594479
  var valid_594480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594480 = validateParameter(valid_594480, JString, required = false,
                                 default = nil)
  if valid_594480 != nil:
    section.add "X-Amz-SignedHeaders", valid_594480
  var valid_594481 = header.getOrDefault("X-Amz-Credential")
  valid_594481 = validateParameter(valid_594481, JString, required = false,
                                 default = nil)
  if valid_594481 != nil:
    section.add "X-Amz-Credential", valid_594481
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594482: Call_GetIntents_594469; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns intent information as follows: </p> <ul> <li> <p>If you specify the <code>nameContains</code> field, returns the <code>$LATEST</code> version of all intents that contain the specified string.</p> </li> <li> <p> If you don't specify the <code>nameContains</code> field, returns information about the <code>$LATEST</code> version of all intents. </p> </li> </ul> <p> The operation requires permission for the <code>lex:GetIntents</code> action. </p>
  ## 
  let valid = call_594482.validator(path, query, header, formData, body)
  let scheme = call_594482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594482.url(scheme.get, call_594482.host, call_594482.base,
                         call_594482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594482, url, valid)

proc call*(call_594483: Call_GetIntents_594469; maxResults: int = 0;
          nextToken: string = ""; nameContains: string = ""): Recallable =
  ## getIntents
  ## <p>Returns intent information as follows: </p> <ul> <li> <p>If you specify the <code>nameContains</code> field, returns the <code>$LATEST</code> version of all intents that contain the specified string.</p> </li> <li> <p> If you don't specify the <code>nameContains</code> field, returns information about the <code>$LATEST</code> version of all intents. </p> </li> </ul> <p> The operation requires permission for the <code>lex:GetIntents</code> action. </p>
  ##   maxResults: int
  ##             : The maximum number of intents to return in the response. The default is 10.
  ##   nextToken: string
  ##            : A pagination token that fetches the next page of intents. If the response to this API call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of intents, specify the pagination token in the next request. 
  ##   nameContains: string
  ##               : Substring to match in intent names. An intent will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  var query_594484 = newJObject()
  add(query_594484, "maxResults", newJInt(maxResults))
  add(query_594484, "nextToken", newJString(nextToken))
  add(query_594484, "nameContains", newJString(nameContains))
  result = call_594483.call(nil, query_594484, nil, nil, nil)

var getIntents* = Call_GetIntents_594469(name: "getIntents",
                                      meth: HttpMethod.HttpGet,
                                      host: "models.lex.amazonaws.com",
                                      route: "/intents/",
                                      validator: validate_GetIntents_594470,
                                      base: "/", url: url_GetIntents_594471,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSlotType_594485 = ref object of OpenApiRestCall_593438
proc url_GetSlotType_594487(protocol: Scheme; host: string; base: string;
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

proc validate_GetSlotType_594486(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594488 = path.getOrDefault("name")
  valid_594488 = validateParameter(valid_594488, JString, required = true,
                                 default = nil)
  if valid_594488 != nil:
    section.add "name", valid_594488
  var valid_594489 = path.getOrDefault("version")
  valid_594489 = validateParameter(valid_594489, JString, required = true,
                                 default = nil)
  if valid_594489 != nil:
    section.add "version", valid_594489
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
  var valid_594490 = header.getOrDefault("X-Amz-Date")
  valid_594490 = validateParameter(valid_594490, JString, required = false,
                                 default = nil)
  if valid_594490 != nil:
    section.add "X-Amz-Date", valid_594490
  var valid_594491 = header.getOrDefault("X-Amz-Security-Token")
  valid_594491 = validateParameter(valid_594491, JString, required = false,
                                 default = nil)
  if valid_594491 != nil:
    section.add "X-Amz-Security-Token", valid_594491
  var valid_594492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594492 = validateParameter(valid_594492, JString, required = false,
                                 default = nil)
  if valid_594492 != nil:
    section.add "X-Amz-Content-Sha256", valid_594492
  var valid_594493 = header.getOrDefault("X-Amz-Algorithm")
  valid_594493 = validateParameter(valid_594493, JString, required = false,
                                 default = nil)
  if valid_594493 != nil:
    section.add "X-Amz-Algorithm", valid_594493
  var valid_594494 = header.getOrDefault("X-Amz-Signature")
  valid_594494 = validateParameter(valid_594494, JString, required = false,
                                 default = nil)
  if valid_594494 != nil:
    section.add "X-Amz-Signature", valid_594494
  var valid_594495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594495 = validateParameter(valid_594495, JString, required = false,
                                 default = nil)
  if valid_594495 != nil:
    section.add "X-Amz-SignedHeaders", valid_594495
  var valid_594496 = header.getOrDefault("X-Amz-Credential")
  valid_594496 = validateParameter(valid_594496, JString, required = false,
                                 default = nil)
  if valid_594496 != nil:
    section.add "X-Amz-Credential", valid_594496
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594497: Call_GetSlotType_594485; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a specific version of a slot type. In addition to specifying the slot type name, you must specify the slot type version.</p> <p>This operation requires permissions for the <code>lex:GetSlotType</code> action.</p>
  ## 
  let valid = call_594497.validator(path, query, header, formData, body)
  let scheme = call_594497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594497.url(scheme.get, call_594497.host, call_594497.base,
                         call_594497.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594497, url, valid)

proc call*(call_594498: Call_GetSlotType_594485; name: string; version: string): Recallable =
  ## getSlotType
  ## <p>Returns information about a specific version of a slot type. In addition to specifying the slot type name, you must specify the slot type version.</p> <p>This operation requires permissions for the <code>lex:GetSlotType</code> action.</p>
  ##   name: string (required)
  ##       : The name of the slot type. The name is case sensitive. 
  ##   version: string (required)
  ##          : The version of the slot type. 
  var path_594499 = newJObject()
  add(path_594499, "name", newJString(name))
  add(path_594499, "version", newJString(version))
  result = call_594498.call(path_594499, nil, nil, nil, nil)

var getSlotType* = Call_GetSlotType_594485(name: "getSlotType",
                                        meth: HttpMethod.HttpGet,
                                        host: "models.lex.amazonaws.com", route: "/slottypes/{name}/versions/{version}",
                                        validator: validate_GetSlotType_594486,
                                        base: "/", url: url_GetSlotType_594487,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSlotTypeVersions_594500 = ref object of OpenApiRestCall_593438
proc url_GetSlotTypeVersions_594502(protocol: Scheme; host: string; base: string;
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

proc validate_GetSlotTypeVersions_594501(path: JsonNode; query: JsonNode;
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
  var valid_594503 = path.getOrDefault("name")
  valid_594503 = validateParameter(valid_594503, JString, required = true,
                                 default = nil)
  if valid_594503 != nil:
    section.add "name", valid_594503
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of slot type versions to return in the response. The default is 10.
  ##   nextToken: JString
  ##            : A pagination token for fetching the next page of slot type versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  section = newJObject()
  var valid_594504 = query.getOrDefault("maxResults")
  valid_594504 = validateParameter(valid_594504, JInt, required = false, default = nil)
  if valid_594504 != nil:
    section.add "maxResults", valid_594504
  var valid_594505 = query.getOrDefault("nextToken")
  valid_594505 = validateParameter(valid_594505, JString, required = false,
                                 default = nil)
  if valid_594505 != nil:
    section.add "nextToken", valid_594505
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
  var valid_594506 = header.getOrDefault("X-Amz-Date")
  valid_594506 = validateParameter(valid_594506, JString, required = false,
                                 default = nil)
  if valid_594506 != nil:
    section.add "X-Amz-Date", valid_594506
  var valid_594507 = header.getOrDefault("X-Amz-Security-Token")
  valid_594507 = validateParameter(valid_594507, JString, required = false,
                                 default = nil)
  if valid_594507 != nil:
    section.add "X-Amz-Security-Token", valid_594507
  var valid_594508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594508 = validateParameter(valid_594508, JString, required = false,
                                 default = nil)
  if valid_594508 != nil:
    section.add "X-Amz-Content-Sha256", valid_594508
  var valid_594509 = header.getOrDefault("X-Amz-Algorithm")
  valid_594509 = validateParameter(valid_594509, JString, required = false,
                                 default = nil)
  if valid_594509 != nil:
    section.add "X-Amz-Algorithm", valid_594509
  var valid_594510 = header.getOrDefault("X-Amz-Signature")
  valid_594510 = validateParameter(valid_594510, JString, required = false,
                                 default = nil)
  if valid_594510 != nil:
    section.add "X-Amz-Signature", valid_594510
  var valid_594511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594511 = validateParameter(valid_594511, JString, required = false,
                                 default = nil)
  if valid_594511 != nil:
    section.add "X-Amz-SignedHeaders", valid_594511
  var valid_594512 = header.getOrDefault("X-Amz-Credential")
  valid_594512 = validateParameter(valid_594512, JString, required = false,
                                 default = nil)
  if valid_594512 != nil:
    section.add "X-Amz-Credential", valid_594512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594513: Call_GetSlotTypeVersions_594500; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about all versions of a slot type.</p> <p>The <code>GetSlotTypeVersions</code> operation returns a <code>SlotTypeMetadata</code> object for each version of a slot type. For example, if a slot type has three numbered versions, the <code>GetSlotTypeVersions</code> operation returns four <code>SlotTypeMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetSlotTypeVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetSlotTypeVersions</code> action.</p>
  ## 
  let valid = call_594513.validator(path, query, header, formData, body)
  let scheme = call_594513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594513.url(scheme.get, call_594513.host, call_594513.base,
                         call_594513.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594513, url, valid)

proc call*(call_594514: Call_GetSlotTypeVersions_594500; name: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## getSlotTypeVersions
  ## <p>Gets information about all versions of a slot type.</p> <p>The <code>GetSlotTypeVersions</code> operation returns a <code>SlotTypeMetadata</code> object for each version of a slot type. For example, if a slot type has three numbered versions, the <code>GetSlotTypeVersions</code> operation returns four <code>SlotTypeMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetSlotTypeVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetSlotTypeVersions</code> action.</p>
  ##   name: string (required)
  ##       : The name of the slot type for which versions should be returned.
  ##   maxResults: int
  ##             : The maximum number of slot type versions to return in the response. The default is 10.
  ##   nextToken: string
  ##            : A pagination token for fetching the next page of slot type versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  var path_594515 = newJObject()
  var query_594516 = newJObject()
  add(path_594515, "name", newJString(name))
  add(query_594516, "maxResults", newJInt(maxResults))
  add(query_594516, "nextToken", newJString(nextToken))
  result = call_594514.call(path_594515, query_594516, nil, nil, nil)

var getSlotTypeVersions* = Call_GetSlotTypeVersions_594500(
    name: "getSlotTypeVersions", meth: HttpMethod.HttpGet,
    host: "models.lex.amazonaws.com", route: "/slottypes/{name}/versions/",
    validator: validate_GetSlotTypeVersions_594501, base: "/",
    url: url_GetSlotTypeVersions_594502, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSlotTypes_594517 = ref object of OpenApiRestCall_593438
proc url_GetSlotTypes_594519(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetSlotTypes_594518(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594520 = query.getOrDefault("maxResults")
  valid_594520 = validateParameter(valid_594520, JInt, required = false, default = nil)
  if valid_594520 != nil:
    section.add "maxResults", valid_594520
  var valid_594521 = query.getOrDefault("nextToken")
  valid_594521 = validateParameter(valid_594521, JString, required = false,
                                 default = nil)
  if valid_594521 != nil:
    section.add "nextToken", valid_594521
  var valid_594522 = query.getOrDefault("nameContains")
  valid_594522 = validateParameter(valid_594522, JString, required = false,
                                 default = nil)
  if valid_594522 != nil:
    section.add "nameContains", valid_594522
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
  var valid_594523 = header.getOrDefault("X-Amz-Date")
  valid_594523 = validateParameter(valid_594523, JString, required = false,
                                 default = nil)
  if valid_594523 != nil:
    section.add "X-Amz-Date", valid_594523
  var valid_594524 = header.getOrDefault("X-Amz-Security-Token")
  valid_594524 = validateParameter(valid_594524, JString, required = false,
                                 default = nil)
  if valid_594524 != nil:
    section.add "X-Amz-Security-Token", valid_594524
  var valid_594525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594525 = validateParameter(valid_594525, JString, required = false,
                                 default = nil)
  if valid_594525 != nil:
    section.add "X-Amz-Content-Sha256", valid_594525
  var valid_594526 = header.getOrDefault("X-Amz-Algorithm")
  valid_594526 = validateParameter(valid_594526, JString, required = false,
                                 default = nil)
  if valid_594526 != nil:
    section.add "X-Amz-Algorithm", valid_594526
  var valid_594527 = header.getOrDefault("X-Amz-Signature")
  valid_594527 = validateParameter(valid_594527, JString, required = false,
                                 default = nil)
  if valid_594527 != nil:
    section.add "X-Amz-Signature", valid_594527
  var valid_594528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594528 = validateParameter(valid_594528, JString, required = false,
                                 default = nil)
  if valid_594528 != nil:
    section.add "X-Amz-SignedHeaders", valid_594528
  var valid_594529 = header.getOrDefault("X-Amz-Credential")
  valid_594529 = validateParameter(valid_594529, JString, required = false,
                                 default = nil)
  if valid_594529 != nil:
    section.add "X-Amz-Credential", valid_594529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594530: Call_GetSlotTypes_594517; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns slot type information as follows: </p> <ul> <li> <p>If you specify the <code>nameContains</code> field, returns the <code>$LATEST</code> version of all slot types that contain the specified string.</p> </li> <li> <p> If you don't specify the <code>nameContains</code> field, returns information about the <code>$LATEST</code> version of all slot types. </p> </li> </ul> <p> The operation requires permission for the <code>lex:GetSlotTypes</code> action. </p>
  ## 
  let valid = call_594530.validator(path, query, header, formData, body)
  let scheme = call_594530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594530.url(scheme.get, call_594530.host, call_594530.base,
                         call_594530.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594530, url, valid)

proc call*(call_594531: Call_GetSlotTypes_594517; maxResults: int = 0;
          nextToken: string = ""; nameContains: string = ""): Recallable =
  ## getSlotTypes
  ## <p>Returns slot type information as follows: </p> <ul> <li> <p>If you specify the <code>nameContains</code> field, returns the <code>$LATEST</code> version of all slot types that contain the specified string.</p> </li> <li> <p> If you don't specify the <code>nameContains</code> field, returns information about the <code>$LATEST</code> version of all slot types. </p> </li> </ul> <p> The operation requires permission for the <code>lex:GetSlotTypes</code> action. </p>
  ##   maxResults: int
  ##             : The maximum number of slot types to return in the response. The default is 10.
  ##   nextToken: string
  ##            : A pagination token that fetches the next page of slot types. If the response to this API call is truncated, Amazon Lex returns a pagination token in the response. To fetch next page of slot types, specify the pagination token in the next request.
  ##   nameContains: string
  ##               : Substring to match in slot type names. A slot type will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  var query_594532 = newJObject()
  add(query_594532, "maxResults", newJInt(maxResults))
  add(query_594532, "nextToken", newJString(nextToken))
  add(query_594532, "nameContains", newJString(nameContains))
  result = call_594531.call(nil, query_594532, nil, nil, nil)

var getSlotTypes* = Call_GetSlotTypes_594517(name: "getSlotTypes",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/slottypes/", validator: validate_GetSlotTypes_594518, base: "/",
    url: url_GetSlotTypes_594519, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUtterancesView_594533 = ref object of OpenApiRestCall_593438
proc url_GetUtterancesView_594535(protocol: Scheme; host: string; base: string;
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

proc validate_GetUtterancesView_594534(path: JsonNode; query: JsonNode;
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
  var valid_594536 = path.getOrDefault("botname")
  valid_594536 = validateParameter(valid_594536, JString, required = true,
                                 default = nil)
  if valid_594536 != nil:
    section.add "botname", valid_594536
  result.add "path", section
  ## parameters in `query` object:
  ##   view: JString (required)
  ##   status_type: JString (required)
  ##              : To return utterances that were recognized and handled, use<code>Detected</code>. To return utterances that were not recognized, use <code>Missed</code>.
  ##   bot_versions: JArray (required)
  ##               : An array of bot versions for which utterance information should be returned. The limit is 5 versions per request.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `view` field"
  var valid_594537 = query.getOrDefault("view")
  valid_594537 = validateParameter(valid_594537, JString, required = true,
                                 default = newJString("aggregation"))
  if valid_594537 != nil:
    section.add "view", valid_594537
  var valid_594538 = query.getOrDefault("status_type")
  valid_594538 = validateParameter(valid_594538, JString, required = true,
                                 default = newJString("Detected"))
  if valid_594538 != nil:
    section.add "status_type", valid_594538
  var valid_594539 = query.getOrDefault("bot_versions")
  valid_594539 = validateParameter(valid_594539, JArray, required = true, default = nil)
  if valid_594539 != nil:
    section.add "bot_versions", valid_594539
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
  var valid_594540 = header.getOrDefault("X-Amz-Date")
  valid_594540 = validateParameter(valid_594540, JString, required = false,
                                 default = nil)
  if valid_594540 != nil:
    section.add "X-Amz-Date", valid_594540
  var valid_594541 = header.getOrDefault("X-Amz-Security-Token")
  valid_594541 = validateParameter(valid_594541, JString, required = false,
                                 default = nil)
  if valid_594541 != nil:
    section.add "X-Amz-Security-Token", valid_594541
  var valid_594542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594542 = validateParameter(valid_594542, JString, required = false,
                                 default = nil)
  if valid_594542 != nil:
    section.add "X-Amz-Content-Sha256", valid_594542
  var valid_594543 = header.getOrDefault("X-Amz-Algorithm")
  valid_594543 = validateParameter(valid_594543, JString, required = false,
                                 default = nil)
  if valid_594543 != nil:
    section.add "X-Amz-Algorithm", valid_594543
  var valid_594544 = header.getOrDefault("X-Amz-Signature")
  valid_594544 = validateParameter(valid_594544, JString, required = false,
                                 default = nil)
  if valid_594544 != nil:
    section.add "X-Amz-Signature", valid_594544
  var valid_594545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594545 = validateParameter(valid_594545, JString, required = false,
                                 default = nil)
  if valid_594545 != nil:
    section.add "X-Amz-SignedHeaders", valid_594545
  var valid_594546 = header.getOrDefault("X-Amz-Credential")
  valid_594546 = validateParameter(valid_594546, JString, required = false,
                                 default = nil)
  if valid_594546 != nil:
    section.add "X-Amz-Credential", valid_594546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594547: Call_GetUtterancesView_594533; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use the <code>GetUtterancesView</code> operation to get information about the utterances that your users have made to your bot. You can use this list to tune the utterances that your bot responds to.</p> <p>For example, say that you have created a bot to order flowers. After your users have used your bot for a while, use the <code>GetUtterancesView</code> operation to see the requests that they have made and whether they have been successful. You might find that the utterance "I want flowers" is not being recognized. You could add this utterance to the <code>OrderFlowers</code> intent so that your bot recognizes that utterance.</p> <p>After you publish a new version of a bot, you can get information about the old version and the new so that you can compare the performance across the two versions. </p> <note> <p>Utterance statistics are generated once a day. Data is available for the last 15 days. You can request information for up to 5 versions in each request. The response contains information about a maximum of 100 utterances for each version.</p> </note> <p>This operation requires permissions for the <code>lex:GetUtterancesView</code> action.</p>
  ## 
  let valid = call_594547.validator(path, query, header, formData, body)
  let scheme = call_594547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594547.url(scheme.get, call_594547.host, call_594547.base,
                         call_594547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594547, url, valid)

proc call*(call_594548: Call_GetUtterancesView_594533; botVersions: JsonNode;
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
  var path_594549 = newJObject()
  var query_594550 = newJObject()
  add(query_594550, "view", newJString(view))
  add(query_594550, "status_type", newJString(statusType))
  if botVersions != nil:
    query_594550.add "bot_versions", botVersions
  add(path_594549, "botname", newJString(botname))
  result = call_594548.call(path_594549, query_594550, nil, nil, nil)

var getUtterancesView* = Call_GetUtterancesView_594533(name: "getUtterancesView",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com", route: "/bots/{botname}/utterances#view=aggregation&bot_versions&status_type",
    validator: validate_GetUtterancesView_594534, base: "/",
    url: url_GetUtterancesView_594535, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBot_594551 = ref object of OpenApiRestCall_593438
proc url_PutBot_594553(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutBot_594552(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594554 = path.getOrDefault("name")
  valid_594554 = validateParameter(valid_594554, JString, required = true,
                                 default = nil)
  if valid_594554 != nil:
    section.add "name", valid_594554
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
  var valid_594555 = header.getOrDefault("X-Amz-Date")
  valid_594555 = validateParameter(valid_594555, JString, required = false,
                                 default = nil)
  if valid_594555 != nil:
    section.add "X-Amz-Date", valid_594555
  var valid_594556 = header.getOrDefault("X-Amz-Security-Token")
  valid_594556 = validateParameter(valid_594556, JString, required = false,
                                 default = nil)
  if valid_594556 != nil:
    section.add "X-Amz-Security-Token", valid_594556
  var valid_594557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594557 = validateParameter(valid_594557, JString, required = false,
                                 default = nil)
  if valid_594557 != nil:
    section.add "X-Amz-Content-Sha256", valid_594557
  var valid_594558 = header.getOrDefault("X-Amz-Algorithm")
  valid_594558 = validateParameter(valid_594558, JString, required = false,
                                 default = nil)
  if valid_594558 != nil:
    section.add "X-Amz-Algorithm", valid_594558
  var valid_594559 = header.getOrDefault("X-Amz-Signature")
  valid_594559 = validateParameter(valid_594559, JString, required = false,
                                 default = nil)
  if valid_594559 != nil:
    section.add "X-Amz-Signature", valid_594559
  var valid_594560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594560 = validateParameter(valid_594560, JString, required = false,
                                 default = nil)
  if valid_594560 != nil:
    section.add "X-Amz-SignedHeaders", valid_594560
  var valid_594561 = header.getOrDefault("X-Amz-Credential")
  valid_594561 = validateParameter(valid_594561, JString, required = false,
                                 default = nil)
  if valid_594561 != nil:
    section.add "X-Amz-Credential", valid_594561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594563: Call_PutBot_594551; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon Lex conversational bot or replaces an existing bot. When you create or update a bot you are only required to specify a name, a locale, and whether the bot is directed toward children under age 13. You can use this to add intents later, or to remove intents from an existing bot. When you create a bot with the minimum information, the bot is created or updated but Amazon Lex returns the <code/> response <code>FAILED</code>. You can build the bot after you add one or more intents. For more information about Amazon Lex bots, see <a>how-it-works</a>. </p> <p>If you specify the name of an existing bot, the fields in the request replace the existing values in the <code>$LATEST</code> version of the bot. Amazon Lex removes any fields that you don't provide values for in the request, except for the <code>idleTTLInSeconds</code> and <code>privacySettings</code> fields, which are set to their default values. If you don't specify values for required fields, Amazon Lex throws an exception.</p> <p>This operation requires permissions for the <code>lex:PutBot</code> action. For more information, see <a>auth-and-access-control</a>.</p>
  ## 
  let valid = call_594563.validator(path, query, header, formData, body)
  let scheme = call_594563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594563.url(scheme.get, call_594563.host, call_594563.base,
                         call_594563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594563, url, valid)

proc call*(call_594564: Call_PutBot_594551; name: string; body: JsonNode): Recallable =
  ## putBot
  ## <p>Creates an Amazon Lex conversational bot or replaces an existing bot. When you create or update a bot you are only required to specify a name, a locale, and whether the bot is directed toward children under age 13. You can use this to add intents later, or to remove intents from an existing bot. When you create a bot with the minimum information, the bot is created or updated but Amazon Lex returns the <code/> response <code>FAILED</code>. You can build the bot after you add one or more intents. For more information about Amazon Lex bots, see <a>how-it-works</a>. </p> <p>If you specify the name of an existing bot, the fields in the request replace the existing values in the <code>$LATEST</code> version of the bot. Amazon Lex removes any fields that you don't provide values for in the request, except for the <code>idleTTLInSeconds</code> and <code>privacySettings</code> fields, which are set to their default values. If you don't specify values for required fields, Amazon Lex throws an exception.</p> <p>This operation requires permissions for the <code>lex:PutBot</code> action. For more information, see <a>auth-and-access-control</a>.</p>
  ##   name: string (required)
  ##       : The name of the bot. The name is <i>not</i> case sensitive. 
  ##   body: JObject (required)
  var path_594565 = newJObject()
  var body_594566 = newJObject()
  add(path_594565, "name", newJString(name))
  if body != nil:
    body_594566 = body
  result = call_594564.call(path_594565, nil, nil, nil, body_594566)

var putBot* = Call_PutBot_594551(name: "putBot", meth: HttpMethod.HttpPut,
                              host: "models.lex.amazonaws.com",
                              route: "/bots/{name}/versions/$LATEST",
                              validator: validate_PutBot_594552, base: "/",
                              url: url_PutBot_594553,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutIntent_594567 = ref object of OpenApiRestCall_593438
proc url_PutIntent_594569(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutIntent_594568(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594570 = path.getOrDefault("name")
  valid_594570 = validateParameter(valid_594570, JString, required = true,
                                 default = nil)
  if valid_594570 != nil:
    section.add "name", valid_594570
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
  var valid_594571 = header.getOrDefault("X-Amz-Date")
  valid_594571 = validateParameter(valid_594571, JString, required = false,
                                 default = nil)
  if valid_594571 != nil:
    section.add "X-Amz-Date", valid_594571
  var valid_594572 = header.getOrDefault("X-Amz-Security-Token")
  valid_594572 = validateParameter(valid_594572, JString, required = false,
                                 default = nil)
  if valid_594572 != nil:
    section.add "X-Amz-Security-Token", valid_594572
  var valid_594573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594573 = validateParameter(valid_594573, JString, required = false,
                                 default = nil)
  if valid_594573 != nil:
    section.add "X-Amz-Content-Sha256", valid_594573
  var valid_594574 = header.getOrDefault("X-Amz-Algorithm")
  valid_594574 = validateParameter(valid_594574, JString, required = false,
                                 default = nil)
  if valid_594574 != nil:
    section.add "X-Amz-Algorithm", valid_594574
  var valid_594575 = header.getOrDefault("X-Amz-Signature")
  valid_594575 = validateParameter(valid_594575, JString, required = false,
                                 default = nil)
  if valid_594575 != nil:
    section.add "X-Amz-Signature", valid_594575
  var valid_594576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594576 = validateParameter(valid_594576, JString, required = false,
                                 default = nil)
  if valid_594576 != nil:
    section.add "X-Amz-SignedHeaders", valid_594576
  var valid_594577 = header.getOrDefault("X-Amz-Credential")
  valid_594577 = validateParameter(valid_594577, JString, required = false,
                                 default = nil)
  if valid_594577 != nil:
    section.add "X-Amz-Credential", valid_594577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594579: Call_PutIntent_594567; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an intent or replaces an existing intent.</p> <p>To define the interaction between the user and your bot, you use one or more intents. For a pizza ordering bot, for example, you would create an <code>OrderPizza</code> intent. </p> <p>To create an intent or replace an existing intent, you must provide the following:</p> <ul> <li> <p>Intent name. For example, <code>OrderPizza</code>.</p> </li> <li> <p>Sample utterances. For example, "Can I order a pizza, please." and "I want to order a pizza."</p> </li> <li> <p>Information to be gathered. You specify slot types for the information that your bot will request from the user. You can specify standard slot types, such as a date or a time, or custom slot types such as the size and crust of a pizza.</p> </li> <li> <p>How the intent will be fulfilled. You can provide a Lambda function or configure the intent to return the intent information to the client application. If you use a Lambda function, when all of the intent information is available, Amazon Lex invokes your Lambda function. If you configure your intent to return the intent information to the client application. </p> </li> </ul> <p>You can specify other optional information in the request, such as:</p> <ul> <li> <p>A confirmation prompt to ask the user to confirm an intent. For example, "Shall I order your pizza?"</p> </li> <li> <p>A conclusion statement to send to the user after the intent has been fulfilled. For example, "I placed your pizza order."</p> </li> <li> <p>A follow-up prompt that asks the user for additional activity. For example, asking "Do you want to order a drink with your pizza?"</p> </li> </ul> <p>If you specify an existing intent name to update the intent, Amazon Lex replaces the values in the <code>$LATEST</code> version of the intent with the values in the request. Amazon Lex removes fields that you don't provide in the request. If you don't specify the required fields, Amazon Lex throws an exception. When you update the <code>$LATEST</code> version of an intent, the <code>status</code> field of any bot that uses the <code>$LATEST</code> version of the intent is set to <code>NOT_BUILT</code>.</p> <p>For more information, see <a>how-it-works</a>.</p> <p>This operation requires permissions for the <code>lex:PutIntent</code> action.</p>
  ## 
  let valid = call_594579.validator(path, query, header, formData, body)
  let scheme = call_594579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594579.url(scheme.get, call_594579.host, call_594579.base,
                         call_594579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594579, url, valid)

proc call*(call_594580: Call_PutIntent_594567; name: string; body: JsonNode): Recallable =
  ## putIntent
  ## <p>Creates an intent or replaces an existing intent.</p> <p>To define the interaction between the user and your bot, you use one or more intents. For a pizza ordering bot, for example, you would create an <code>OrderPizza</code> intent. </p> <p>To create an intent or replace an existing intent, you must provide the following:</p> <ul> <li> <p>Intent name. For example, <code>OrderPizza</code>.</p> </li> <li> <p>Sample utterances. For example, "Can I order a pizza, please." and "I want to order a pizza."</p> </li> <li> <p>Information to be gathered. You specify slot types for the information that your bot will request from the user. You can specify standard slot types, such as a date or a time, or custom slot types such as the size and crust of a pizza.</p> </li> <li> <p>How the intent will be fulfilled. You can provide a Lambda function or configure the intent to return the intent information to the client application. If you use a Lambda function, when all of the intent information is available, Amazon Lex invokes your Lambda function. If you configure your intent to return the intent information to the client application. </p> </li> </ul> <p>You can specify other optional information in the request, such as:</p> <ul> <li> <p>A confirmation prompt to ask the user to confirm an intent. For example, "Shall I order your pizza?"</p> </li> <li> <p>A conclusion statement to send to the user after the intent has been fulfilled. For example, "I placed your pizza order."</p> </li> <li> <p>A follow-up prompt that asks the user for additional activity. For example, asking "Do you want to order a drink with your pizza?"</p> </li> </ul> <p>If you specify an existing intent name to update the intent, Amazon Lex replaces the values in the <code>$LATEST</code> version of the intent with the values in the request. Amazon Lex removes fields that you don't provide in the request. If you don't specify the required fields, Amazon Lex throws an exception. When you update the <code>$LATEST</code> version of an intent, the <code>status</code> field of any bot that uses the <code>$LATEST</code> version of the intent is set to <code>NOT_BUILT</code>.</p> <p>For more information, see <a>how-it-works</a>.</p> <p>This operation requires permissions for the <code>lex:PutIntent</code> action.</p>
  ##   name: string (required)
  ##       : <p>The name of the intent. The name is <i>not</i> case sensitive. </p> <p>The name can't match a built-in intent name, or a built-in intent name with "AMAZON." removed. For example, because there is a built-in intent called <code>AMAZON.HelpIntent</code>, you can't create a custom intent called <code>HelpIntent</code>.</p> <p>For a list of built-in intents, see <a 
  ## href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/standard-intents">Standard Built-in Intents</a> in the <i>Alexa Skills Kit</i>.</p>
  ##   body: JObject (required)
  var path_594581 = newJObject()
  var body_594582 = newJObject()
  add(path_594581, "name", newJString(name))
  if body != nil:
    body_594582 = body
  result = call_594580.call(path_594581, nil, nil, nil, body_594582)

var putIntent* = Call_PutIntent_594567(name: "putIntent", meth: HttpMethod.HttpPut,
                                    host: "models.lex.amazonaws.com",
                                    route: "/intents/{name}/versions/$LATEST",
                                    validator: validate_PutIntent_594568,
                                    base: "/", url: url_PutIntent_594569,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSlotType_594583 = ref object of OpenApiRestCall_593438
proc url_PutSlotType_594585(protocol: Scheme; host: string; base: string;
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

proc validate_PutSlotType_594584(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594586 = path.getOrDefault("name")
  valid_594586 = validateParameter(valid_594586, JString, required = true,
                                 default = nil)
  if valid_594586 != nil:
    section.add "name", valid_594586
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
  var valid_594587 = header.getOrDefault("X-Amz-Date")
  valid_594587 = validateParameter(valid_594587, JString, required = false,
                                 default = nil)
  if valid_594587 != nil:
    section.add "X-Amz-Date", valid_594587
  var valid_594588 = header.getOrDefault("X-Amz-Security-Token")
  valid_594588 = validateParameter(valid_594588, JString, required = false,
                                 default = nil)
  if valid_594588 != nil:
    section.add "X-Amz-Security-Token", valid_594588
  var valid_594589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594589 = validateParameter(valid_594589, JString, required = false,
                                 default = nil)
  if valid_594589 != nil:
    section.add "X-Amz-Content-Sha256", valid_594589
  var valid_594590 = header.getOrDefault("X-Amz-Algorithm")
  valid_594590 = validateParameter(valid_594590, JString, required = false,
                                 default = nil)
  if valid_594590 != nil:
    section.add "X-Amz-Algorithm", valid_594590
  var valid_594591 = header.getOrDefault("X-Amz-Signature")
  valid_594591 = validateParameter(valid_594591, JString, required = false,
                                 default = nil)
  if valid_594591 != nil:
    section.add "X-Amz-Signature", valid_594591
  var valid_594592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594592 = validateParameter(valid_594592, JString, required = false,
                                 default = nil)
  if valid_594592 != nil:
    section.add "X-Amz-SignedHeaders", valid_594592
  var valid_594593 = header.getOrDefault("X-Amz-Credential")
  valid_594593 = validateParameter(valid_594593, JString, required = false,
                                 default = nil)
  if valid_594593 != nil:
    section.add "X-Amz-Credential", valid_594593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594595: Call_PutSlotType_594583; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a custom slot type or replaces an existing custom slot type.</p> <p>To create a custom slot type, specify a name for the slot type and a set of enumeration values, which are the values that a slot of this type can assume. For more information, see <a>how-it-works</a>.</p> <p>If you specify the name of an existing slot type, the fields in the request replace the existing values in the <code>$LATEST</code> version of the slot type. Amazon Lex removes the fields that you don't provide in the request. If you don't specify required fields, Amazon Lex throws an exception. When you update the <code>$LATEST</code> version of a slot type, if a bot uses the <code>$LATEST</code> version of an intent that contains the slot type, the bot's <code>status</code> field is set to <code>NOT_BUILT</code>.</p> <p>This operation requires permissions for the <code>lex:PutSlotType</code> action.</p>
  ## 
  let valid = call_594595.validator(path, query, header, formData, body)
  let scheme = call_594595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594595.url(scheme.get, call_594595.host, call_594595.base,
                         call_594595.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594595, url, valid)

proc call*(call_594596: Call_PutSlotType_594583; name: string; body: JsonNode): Recallable =
  ## putSlotType
  ## <p>Creates a custom slot type or replaces an existing custom slot type.</p> <p>To create a custom slot type, specify a name for the slot type and a set of enumeration values, which are the values that a slot of this type can assume. For more information, see <a>how-it-works</a>.</p> <p>If you specify the name of an existing slot type, the fields in the request replace the existing values in the <code>$LATEST</code> version of the slot type. Amazon Lex removes the fields that you don't provide in the request. If you don't specify required fields, Amazon Lex throws an exception. When you update the <code>$LATEST</code> version of a slot type, if a bot uses the <code>$LATEST</code> version of an intent that contains the slot type, the bot's <code>status</code> field is set to <code>NOT_BUILT</code>.</p> <p>This operation requires permissions for the <code>lex:PutSlotType</code> action.</p>
  ##   name: string (required)
  ##       : <p>The name of the slot type. The name is <i>not</i> case sensitive. </p> <p>The name can't match a built-in slot type name, or a built-in slot type name with "AMAZON." removed. For example, because there is a built-in slot type called <code>AMAZON.DATE</code>, you can't create a custom slot type called <code>DATE</code>.</p> <p>For a list of built-in slot types, see <a 
  ## href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/slot-type-reference">Slot Type Reference</a> in the <i>Alexa Skills Kit</i>.</p>
  ##   body: JObject (required)
  var path_594597 = newJObject()
  var body_594598 = newJObject()
  add(path_594597, "name", newJString(name))
  if body != nil:
    body_594598 = body
  result = call_594596.call(path_594597, nil, nil, nil, body_594598)

var putSlotType* = Call_PutSlotType_594583(name: "putSlotType",
                                        meth: HttpMethod.HttpPut,
                                        host: "models.lex.amazonaws.com", route: "/slottypes/{name}/versions/$LATEST",
                                        validator: validate_PutSlotType_594584,
                                        base: "/", url: url_PutSlotType_594585,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImport_594599 = ref object of OpenApiRestCall_593438
proc url_StartImport_594601(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartImport_594600(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594602 = header.getOrDefault("X-Amz-Date")
  valid_594602 = validateParameter(valid_594602, JString, required = false,
                                 default = nil)
  if valid_594602 != nil:
    section.add "X-Amz-Date", valid_594602
  var valid_594603 = header.getOrDefault("X-Amz-Security-Token")
  valid_594603 = validateParameter(valid_594603, JString, required = false,
                                 default = nil)
  if valid_594603 != nil:
    section.add "X-Amz-Security-Token", valid_594603
  var valid_594604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594604 = validateParameter(valid_594604, JString, required = false,
                                 default = nil)
  if valid_594604 != nil:
    section.add "X-Amz-Content-Sha256", valid_594604
  var valid_594605 = header.getOrDefault("X-Amz-Algorithm")
  valid_594605 = validateParameter(valid_594605, JString, required = false,
                                 default = nil)
  if valid_594605 != nil:
    section.add "X-Amz-Algorithm", valid_594605
  var valid_594606 = header.getOrDefault("X-Amz-Signature")
  valid_594606 = validateParameter(valid_594606, JString, required = false,
                                 default = nil)
  if valid_594606 != nil:
    section.add "X-Amz-Signature", valid_594606
  var valid_594607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594607 = validateParameter(valid_594607, JString, required = false,
                                 default = nil)
  if valid_594607 != nil:
    section.add "X-Amz-SignedHeaders", valid_594607
  var valid_594608 = header.getOrDefault("X-Amz-Credential")
  valid_594608 = validateParameter(valid_594608, JString, required = false,
                                 default = nil)
  if valid_594608 != nil:
    section.add "X-Amz-Credential", valid_594608
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594610: Call_StartImport_594599; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a job to import a resource to Amazon Lex.
  ## 
  let valid = call_594610.validator(path, query, header, formData, body)
  let scheme = call_594610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594610.url(scheme.get, call_594610.host, call_594610.base,
                         call_594610.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594610, url, valid)

proc call*(call_594611: Call_StartImport_594599; body: JsonNode): Recallable =
  ## startImport
  ## Starts a job to import a resource to Amazon Lex.
  ##   body: JObject (required)
  var body_594612 = newJObject()
  if body != nil:
    body_594612 = body
  result = call_594611.call(nil, nil, nil, nil, body_594612)

var startImport* = Call_StartImport_594599(name: "startImport",
                                        meth: HttpMethod.HttpPost,
                                        host: "models.lex.amazonaws.com",
                                        route: "/imports/",
                                        validator: validate_StartImport_594600,
                                        base: "/", url: url_StartImport_594601,
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
