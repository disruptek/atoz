
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_612659 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612659](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612659): Option[Scheme] {.used.} =
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
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateBotVersion_612997 = ref object of OpenApiRestCall_612659
proc url_CreateBotVersion_612999(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateBotVersion_612998(path: JsonNode; query: JsonNode;
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
  var valid_613125 = path.getOrDefault("name")
  valid_613125 = validateParameter(valid_613125, JString, required = true,
                                 default = nil)
  if valid_613125 != nil:
    section.add "name", valid_613125
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613126 = header.getOrDefault("X-Amz-Signature")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "X-Amz-Signature", valid_613126
  var valid_613127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Content-Sha256", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Date")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Date", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Credential")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Credential", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-Security-Token")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-Security-Token", valid_613130
  var valid_613131 = header.getOrDefault("X-Amz-Algorithm")
  valid_613131 = validateParameter(valid_613131, JString, required = false,
                                 default = nil)
  if valid_613131 != nil:
    section.add "X-Amz-Algorithm", valid_613131
  var valid_613132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613132 = validateParameter(valid_613132, JString, required = false,
                                 default = nil)
  if valid_613132 != nil:
    section.add "X-Amz-SignedHeaders", valid_613132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613156: Call_CreateBotVersion_612997; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new version of the bot based on the <code>$LATEST</code> version. If the <code>$LATEST</code> version of this resource hasn't changed since you created the last version, Amazon Lex doesn't create a new version. It returns the last created version.</p> <note> <p>You can update only the <code>$LATEST</code> version of the bot. You can't update the numbered versions that you create with the <code>CreateBotVersion</code> operation.</p> </note> <p> When you create the first version of a bot, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p> This operation requires permission for the <code>lex:CreateBotVersion</code> action. </p>
  ## 
  let valid = call_613156.validator(path, query, header, formData, body)
  let scheme = call_613156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613156.url(scheme.get, call_613156.host, call_613156.base,
                         call_613156.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613156, url, valid)

proc call*(call_613227: Call_CreateBotVersion_612997; name: string; body: JsonNode): Recallable =
  ## createBotVersion
  ## <p>Creates a new version of the bot based on the <code>$LATEST</code> version. If the <code>$LATEST</code> version of this resource hasn't changed since you created the last version, Amazon Lex doesn't create a new version. It returns the last created version.</p> <note> <p>You can update only the <code>$LATEST</code> version of the bot. You can't update the numbered versions that you create with the <code>CreateBotVersion</code> operation.</p> </note> <p> When you create the first version of a bot, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p> This operation requires permission for the <code>lex:CreateBotVersion</code> action. </p>
  ##   name: string (required)
  ##       : The name of the bot that you want to create a new version of. The name is case sensitive. 
  ##   body: JObject (required)
  var path_613228 = newJObject()
  var body_613230 = newJObject()
  add(path_613228, "name", newJString(name))
  if body != nil:
    body_613230 = body
  result = call_613227.call(path_613228, nil, nil, nil, body_613230)

var createBotVersion* = Call_CreateBotVersion_612997(name: "createBotVersion",
    meth: HttpMethod.HttpPost, host: "models.lex.amazonaws.com",
    route: "/bots/{name}/versions", validator: validate_CreateBotVersion_612998,
    base: "/", url: url_CreateBotVersion_612999,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIntentVersion_613269 = ref object of OpenApiRestCall_612659
proc url_CreateIntentVersion_613271(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateIntentVersion_613270(path: JsonNode; query: JsonNode;
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
  var valid_613272 = path.getOrDefault("name")
  valid_613272 = validateParameter(valid_613272, JString, required = true,
                                 default = nil)
  if valid_613272 != nil:
    section.add "name", valid_613272
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613273 = header.getOrDefault("X-Amz-Signature")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Signature", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Content-Sha256", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Date")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Date", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-Credential")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Credential", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-Security-Token")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Security-Token", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-Algorithm")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-Algorithm", valid_613278
  var valid_613279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613279 = validateParameter(valid_613279, JString, required = false,
                                 default = nil)
  if valid_613279 != nil:
    section.add "X-Amz-SignedHeaders", valid_613279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613281: Call_CreateIntentVersion_613269; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new version of an intent based on the <code>$LATEST</code> version of the intent. If the <code>$LATEST</code> version of this intent hasn't changed since you last updated it, Amazon Lex doesn't create a new version. It returns the last version you created.</p> <note> <p>You can update only the <code>$LATEST</code> version of the intent. You can't update the numbered versions that you create with the <code>CreateIntentVersion</code> operation.</p> </note> <p> When you create a version of an intent, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p>This operation requires permissions to perform the <code>lex:CreateIntentVersion</code> action. </p>
  ## 
  let valid = call_613281.validator(path, query, header, formData, body)
  let scheme = call_613281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613281.url(scheme.get, call_613281.host, call_613281.base,
                         call_613281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613281, url, valid)

proc call*(call_613282: Call_CreateIntentVersion_613269; name: string; body: JsonNode): Recallable =
  ## createIntentVersion
  ## <p>Creates a new version of an intent based on the <code>$LATEST</code> version of the intent. If the <code>$LATEST</code> version of this intent hasn't changed since you last updated it, Amazon Lex doesn't create a new version. It returns the last version you created.</p> <note> <p>You can update only the <code>$LATEST</code> version of the intent. You can't update the numbered versions that you create with the <code>CreateIntentVersion</code> operation.</p> </note> <p> When you create a version of an intent, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p>This operation requires permissions to perform the <code>lex:CreateIntentVersion</code> action. </p>
  ##   name: string (required)
  ##       : The name of the intent that you want to create a new version of. The name is case sensitive. 
  ##   body: JObject (required)
  var path_613283 = newJObject()
  var body_613284 = newJObject()
  add(path_613283, "name", newJString(name))
  if body != nil:
    body_613284 = body
  result = call_613282.call(path_613283, nil, nil, nil, body_613284)

var createIntentVersion* = Call_CreateIntentVersion_613269(
    name: "createIntentVersion", meth: HttpMethod.HttpPost,
    host: "models.lex.amazonaws.com", route: "/intents/{name}/versions",
    validator: validate_CreateIntentVersion_613270, base: "/",
    url: url_CreateIntentVersion_613271, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSlotTypeVersion_613285 = ref object of OpenApiRestCall_612659
proc url_CreateSlotTypeVersion_613287(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateSlotTypeVersion_613286(path: JsonNode; query: JsonNode;
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
  var valid_613288 = path.getOrDefault("name")
  valid_613288 = validateParameter(valid_613288, JString, required = true,
                                 default = nil)
  if valid_613288 != nil:
    section.add "name", valid_613288
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613289 = header.getOrDefault("X-Amz-Signature")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Signature", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-Content-Sha256", valid_613290
  var valid_613291 = header.getOrDefault("X-Amz-Date")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-Date", valid_613291
  var valid_613292 = header.getOrDefault("X-Amz-Credential")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-Credential", valid_613292
  var valid_613293 = header.getOrDefault("X-Amz-Security-Token")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-Security-Token", valid_613293
  var valid_613294 = header.getOrDefault("X-Amz-Algorithm")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "X-Amz-Algorithm", valid_613294
  var valid_613295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-SignedHeaders", valid_613295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613297: Call_CreateSlotTypeVersion_613285; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new version of a slot type based on the <code>$LATEST</code> version of the specified slot type. If the <code>$LATEST</code> version of this resource has not changed since the last version that you created, Amazon Lex doesn't create a new version. It returns the last version that you created. </p> <note> <p>You can update only the <code>$LATEST</code> version of a slot type. You can't update the numbered versions that you create with the <code>CreateSlotTypeVersion</code> operation.</p> </note> <p>When you create a version of a slot type, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p>This operation requires permissions for the <code>lex:CreateSlotTypeVersion</code> action.</p>
  ## 
  let valid = call_613297.validator(path, query, header, formData, body)
  let scheme = call_613297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613297.url(scheme.get, call_613297.host, call_613297.base,
                         call_613297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613297, url, valid)

proc call*(call_613298: Call_CreateSlotTypeVersion_613285; name: string;
          body: JsonNode): Recallable =
  ## createSlotTypeVersion
  ## <p>Creates a new version of a slot type based on the <code>$LATEST</code> version of the specified slot type. If the <code>$LATEST</code> version of this resource has not changed since the last version that you created, Amazon Lex doesn't create a new version. It returns the last version that you created. </p> <note> <p>You can update only the <code>$LATEST</code> version of a slot type. You can't update the numbered versions that you create with the <code>CreateSlotTypeVersion</code> operation.</p> </note> <p>When you create a version of a slot type, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p>This operation requires permissions for the <code>lex:CreateSlotTypeVersion</code> action.</p>
  ##   name: string (required)
  ##       : The name of the slot type that you want to create a new version for. The name is case sensitive. 
  ##   body: JObject (required)
  var path_613299 = newJObject()
  var body_613300 = newJObject()
  add(path_613299, "name", newJString(name))
  if body != nil:
    body_613300 = body
  result = call_613298.call(path_613299, nil, nil, nil, body_613300)

var createSlotTypeVersion* = Call_CreateSlotTypeVersion_613285(
    name: "createSlotTypeVersion", meth: HttpMethod.HttpPost,
    host: "models.lex.amazonaws.com", route: "/slottypes/{name}/versions",
    validator: validate_CreateSlotTypeVersion_613286, base: "/",
    url: url_CreateSlotTypeVersion_613287, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBot_613301 = ref object of OpenApiRestCall_612659
proc url_DeleteBot_613303(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBot_613302(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes all versions of the bot, including the <code>$LATEST</code> version. To delete a specific version of the bot, use the <a>DeleteBotVersion</a> operation. The <code>DeleteBot</code> operation doesn't immediately remove the bot schema. Instead, it is marked for deletion and removed later.</p> <p>Amazon Lex stores utterances indefinitely for improving the ability of your bot to respond to user inputs. These utterances are not removed when the bot is deleted. To remove the utterances, use the <a>DeleteUtterances</a> operation.</p> <p>If a bot has an alias, you can't delete it. Instead, the <code>DeleteBot</code> operation returns a <code>ResourceInUseException</code> exception that includes a reference to the alias that refers to the bot. To remove the reference to the bot, delete the alias. If you get the same exception again, delete the referring alias until the <code>DeleteBot</code> operation is successful.</p> <p>This operation requires permissions for the <code>lex:DeleteBot</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the bot. The name is case sensitive. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_613304 = path.getOrDefault("name")
  valid_613304 = validateParameter(valid_613304, JString, required = true,
                                 default = nil)
  if valid_613304 != nil:
    section.add "name", valid_613304
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613305 = header.getOrDefault("X-Amz-Signature")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-Signature", valid_613305
  var valid_613306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613306 = validateParameter(valid_613306, JString, required = false,
                                 default = nil)
  if valid_613306 != nil:
    section.add "X-Amz-Content-Sha256", valid_613306
  var valid_613307 = header.getOrDefault("X-Amz-Date")
  valid_613307 = validateParameter(valid_613307, JString, required = false,
                                 default = nil)
  if valid_613307 != nil:
    section.add "X-Amz-Date", valid_613307
  var valid_613308 = header.getOrDefault("X-Amz-Credential")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "X-Amz-Credential", valid_613308
  var valid_613309 = header.getOrDefault("X-Amz-Security-Token")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-Security-Token", valid_613309
  var valid_613310 = header.getOrDefault("X-Amz-Algorithm")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "X-Amz-Algorithm", valid_613310
  var valid_613311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "X-Amz-SignedHeaders", valid_613311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613312: Call_DeleteBot_613301; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes all versions of the bot, including the <code>$LATEST</code> version. To delete a specific version of the bot, use the <a>DeleteBotVersion</a> operation. The <code>DeleteBot</code> operation doesn't immediately remove the bot schema. Instead, it is marked for deletion and removed later.</p> <p>Amazon Lex stores utterances indefinitely for improving the ability of your bot to respond to user inputs. These utterances are not removed when the bot is deleted. To remove the utterances, use the <a>DeleteUtterances</a> operation.</p> <p>If a bot has an alias, you can't delete it. Instead, the <code>DeleteBot</code> operation returns a <code>ResourceInUseException</code> exception that includes a reference to the alias that refers to the bot. To remove the reference to the bot, delete the alias. If you get the same exception again, delete the referring alias until the <code>DeleteBot</code> operation is successful.</p> <p>This operation requires permissions for the <code>lex:DeleteBot</code> action.</p>
  ## 
  let valid = call_613312.validator(path, query, header, formData, body)
  let scheme = call_613312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613312.url(scheme.get, call_613312.host, call_613312.base,
                         call_613312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613312, url, valid)

proc call*(call_613313: Call_DeleteBot_613301; name: string): Recallable =
  ## deleteBot
  ## <p>Deletes all versions of the bot, including the <code>$LATEST</code> version. To delete a specific version of the bot, use the <a>DeleteBotVersion</a> operation. The <code>DeleteBot</code> operation doesn't immediately remove the bot schema. Instead, it is marked for deletion and removed later.</p> <p>Amazon Lex stores utterances indefinitely for improving the ability of your bot to respond to user inputs. These utterances are not removed when the bot is deleted. To remove the utterances, use the <a>DeleteUtterances</a> operation.</p> <p>If a bot has an alias, you can't delete it. Instead, the <code>DeleteBot</code> operation returns a <code>ResourceInUseException</code> exception that includes a reference to the alias that refers to the bot. To remove the reference to the bot, delete the alias. If you get the same exception again, delete the referring alias until the <code>DeleteBot</code> operation is successful.</p> <p>This operation requires permissions for the <code>lex:DeleteBot</code> action.</p>
  ##   name: string (required)
  ##       : The name of the bot. The name is case sensitive. 
  var path_613314 = newJObject()
  add(path_613314, "name", newJString(name))
  result = call_613313.call(path_613314, nil, nil, nil, nil)

var deleteBot* = Call_DeleteBot_613301(name: "deleteBot",
                                    meth: HttpMethod.HttpDelete,
                                    host: "models.lex.amazonaws.com",
                                    route: "/bots/{name}",
                                    validator: validate_DeleteBot_613302,
                                    base: "/", url: url_DeleteBot_613303,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBotAlias_613330 = ref object of OpenApiRestCall_612659
proc url_PutBotAlias_613332(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutBotAlias_613331(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an alias for the specified version of the bot or replaces an alias for the specified bot. To change the version of the bot that the alias points to, replace the alias. For more information about aliases, see <a>versioning-aliases</a>.</p> <p>This operation requires permissions for the <code>lex:PutBotAlias</code> action. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   botName: JString (required)
  ##          : The name of the bot.
  ##   name: JString (required)
  ##       : The name of the alias. The name is <i>not</i> case sensitive.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `botName` field"
  var valid_613333 = path.getOrDefault("botName")
  valid_613333 = validateParameter(valid_613333, JString, required = true,
                                 default = nil)
  if valid_613333 != nil:
    section.add "botName", valid_613333
  var valid_613334 = path.getOrDefault("name")
  valid_613334 = validateParameter(valid_613334, JString, required = true,
                                 default = nil)
  if valid_613334 != nil:
    section.add "name", valid_613334
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613335 = header.getOrDefault("X-Amz-Signature")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "X-Amz-Signature", valid_613335
  var valid_613336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "X-Amz-Content-Sha256", valid_613336
  var valid_613337 = header.getOrDefault("X-Amz-Date")
  valid_613337 = validateParameter(valid_613337, JString, required = false,
                                 default = nil)
  if valid_613337 != nil:
    section.add "X-Amz-Date", valid_613337
  var valid_613338 = header.getOrDefault("X-Amz-Credential")
  valid_613338 = validateParameter(valid_613338, JString, required = false,
                                 default = nil)
  if valid_613338 != nil:
    section.add "X-Amz-Credential", valid_613338
  var valid_613339 = header.getOrDefault("X-Amz-Security-Token")
  valid_613339 = validateParameter(valid_613339, JString, required = false,
                                 default = nil)
  if valid_613339 != nil:
    section.add "X-Amz-Security-Token", valid_613339
  var valid_613340 = header.getOrDefault("X-Amz-Algorithm")
  valid_613340 = validateParameter(valid_613340, JString, required = false,
                                 default = nil)
  if valid_613340 != nil:
    section.add "X-Amz-Algorithm", valid_613340
  var valid_613341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613341 = validateParameter(valid_613341, JString, required = false,
                                 default = nil)
  if valid_613341 != nil:
    section.add "X-Amz-SignedHeaders", valid_613341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613343: Call_PutBotAlias_613330; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an alias for the specified version of the bot or replaces an alias for the specified bot. To change the version of the bot that the alias points to, replace the alias. For more information about aliases, see <a>versioning-aliases</a>.</p> <p>This operation requires permissions for the <code>lex:PutBotAlias</code> action. </p>
  ## 
  let valid = call_613343.validator(path, query, header, formData, body)
  let scheme = call_613343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613343.url(scheme.get, call_613343.host, call_613343.base,
                         call_613343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613343, url, valid)

proc call*(call_613344: Call_PutBotAlias_613330; botName: string; name: string;
          body: JsonNode): Recallable =
  ## putBotAlias
  ## <p>Creates an alias for the specified version of the bot or replaces an alias for the specified bot. To change the version of the bot that the alias points to, replace the alias. For more information about aliases, see <a>versioning-aliases</a>.</p> <p>This operation requires permissions for the <code>lex:PutBotAlias</code> action. </p>
  ##   botName: string (required)
  ##          : The name of the bot.
  ##   name: string (required)
  ##       : The name of the alias. The name is <i>not</i> case sensitive.
  ##   body: JObject (required)
  var path_613345 = newJObject()
  var body_613346 = newJObject()
  add(path_613345, "botName", newJString(botName))
  add(path_613345, "name", newJString(name))
  if body != nil:
    body_613346 = body
  result = call_613344.call(path_613345, nil, nil, nil, body_613346)

var putBotAlias* = Call_PutBotAlias_613330(name: "putBotAlias",
                                        meth: HttpMethod.HttpPut,
                                        host: "models.lex.amazonaws.com", route: "/bots/{botName}/aliases/{name}",
                                        validator: validate_PutBotAlias_613331,
                                        base: "/", url: url_PutBotAlias_613332,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBotAlias_613315 = ref object of OpenApiRestCall_612659
proc url_GetBotAlias_613317(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBotAlias_613316(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about an Amazon Lex bot alias. For more information about aliases, see <a>versioning-aliases</a>.</p> <p>This operation requires permissions for the <code>lex:GetBotAlias</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   botName: JString (required)
  ##          : The name of the bot.
  ##   name: JString (required)
  ##       : The name of the bot alias. The name is case sensitive.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `botName` field"
  var valid_613318 = path.getOrDefault("botName")
  valid_613318 = validateParameter(valid_613318, JString, required = true,
                                 default = nil)
  if valid_613318 != nil:
    section.add "botName", valid_613318
  var valid_613319 = path.getOrDefault("name")
  valid_613319 = validateParameter(valid_613319, JString, required = true,
                                 default = nil)
  if valid_613319 != nil:
    section.add "name", valid_613319
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613320 = header.getOrDefault("X-Amz-Signature")
  valid_613320 = validateParameter(valid_613320, JString, required = false,
                                 default = nil)
  if valid_613320 != nil:
    section.add "X-Amz-Signature", valid_613320
  var valid_613321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "X-Amz-Content-Sha256", valid_613321
  var valid_613322 = header.getOrDefault("X-Amz-Date")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "X-Amz-Date", valid_613322
  var valid_613323 = header.getOrDefault("X-Amz-Credential")
  valid_613323 = validateParameter(valid_613323, JString, required = false,
                                 default = nil)
  if valid_613323 != nil:
    section.add "X-Amz-Credential", valid_613323
  var valid_613324 = header.getOrDefault("X-Amz-Security-Token")
  valid_613324 = validateParameter(valid_613324, JString, required = false,
                                 default = nil)
  if valid_613324 != nil:
    section.add "X-Amz-Security-Token", valid_613324
  var valid_613325 = header.getOrDefault("X-Amz-Algorithm")
  valid_613325 = validateParameter(valid_613325, JString, required = false,
                                 default = nil)
  if valid_613325 != nil:
    section.add "X-Amz-Algorithm", valid_613325
  var valid_613326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613326 = validateParameter(valid_613326, JString, required = false,
                                 default = nil)
  if valid_613326 != nil:
    section.add "X-Amz-SignedHeaders", valid_613326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613327: Call_GetBotAlias_613315; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about an Amazon Lex bot alias. For more information about aliases, see <a>versioning-aliases</a>.</p> <p>This operation requires permissions for the <code>lex:GetBotAlias</code> action.</p>
  ## 
  let valid = call_613327.validator(path, query, header, formData, body)
  let scheme = call_613327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613327.url(scheme.get, call_613327.host, call_613327.base,
                         call_613327.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613327, url, valid)

proc call*(call_613328: Call_GetBotAlias_613315; botName: string; name: string): Recallable =
  ## getBotAlias
  ## <p>Returns information about an Amazon Lex bot alias. For more information about aliases, see <a>versioning-aliases</a>.</p> <p>This operation requires permissions for the <code>lex:GetBotAlias</code> action.</p>
  ##   botName: string (required)
  ##          : The name of the bot.
  ##   name: string (required)
  ##       : The name of the bot alias. The name is case sensitive.
  var path_613329 = newJObject()
  add(path_613329, "botName", newJString(botName))
  add(path_613329, "name", newJString(name))
  result = call_613328.call(path_613329, nil, nil, nil, nil)

var getBotAlias* = Call_GetBotAlias_613315(name: "getBotAlias",
                                        meth: HttpMethod.HttpGet,
                                        host: "models.lex.amazonaws.com", route: "/bots/{botName}/aliases/{name}",
                                        validator: validate_GetBotAlias_613316,
                                        base: "/", url: url_GetBotAlias_613317,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBotAlias_613347 = ref object of OpenApiRestCall_612659
proc url_DeleteBotAlias_613349(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBotAlias_613348(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Deletes an alias for the specified bot. </p> <p>You can't delete an alias that is used in the association between a bot and a messaging channel. If an alias is used in a channel association, the <code>DeleteBot</code> operation returns a <code>ResourceInUseException</code> exception that includes a reference to the channel association that refers to the bot. You can remove the reference to the alias by deleting the channel association. If you get the same exception again, delete the referring association until the <code>DeleteBotAlias</code> operation is successful.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   botName: JString (required)
  ##          : The name of the bot that the alias points to.
  ##   name: JString (required)
  ##       : The name of the alias to delete. The name is case sensitive. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `botName` field"
  var valid_613350 = path.getOrDefault("botName")
  valid_613350 = validateParameter(valid_613350, JString, required = true,
                                 default = nil)
  if valid_613350 != nil:
    section.add "botName", valid_613350
  var valid_613351 = path.getOrDefault("name")
  valid_613351 = validateParameter(valid_613351, JString, required = true,
                                 default = nil)
  if valid_613351 != nil:
    section.add "name", valid_613351
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613352 = header.getOrDefault("X-Amz-Signature")
  valid_613352 = validateParameter(valid_613352, JString, required = false,
                                 default = nil)
  if valid_613352 != nil:
    section.add "X-Amz-Signature", valid_613352
  var valid_613353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "X-Amz-Content-Sha256", valid_613353
  var valid_613354 = header.getOrDefault("X-Amz-Date")
  valid_613354 = validateParameter(valid_613354, JString, required = false,
                                 default = nil)
  if valid_613354 != nil:
    section.add "X-Amz-Date", valid_613354
  var valid_613355 = header.getOrDefault("X-Amz-Credential")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "X-Amz-Credential", valid_613355
  var valid_613356 = header.getOrDefault("X-Amz-Security-Token")
  valid_613356 = validateParameter(valid_613356, JString, required = false,
                                 default = nil)
  if valid_613356 != nil:
    section.add "X-Amz-Security-Token", valid_613356
  var valid_613357 = header.getOrDefault("X-Amz-Algorithm")
  valid_613357 = validateParameter(valid_613357, JString, required = false,
                                 default = nil)
  if valid_613357 != nil:
    section.add "X-Amz-Algorithm", valid_613357
  var valid_613358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "X-Amz-SignedHeaders", valid_613358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613359: Call_DeleteBotAlias_613347; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an alias for the specified bot. </p> <p>You can't delete an alias that is used in the association between a bot and a messaging channel. If an alias is used in a channel association, the <code>DeleteBot</code> operation returns a <code>ResourceInUseException</code> exception that includes a reference to the channel association that refers to the bot. You can remove the reference to the alias by deleting the channel association. If you get the same exception again, delete the referring association until the <code>DeleteBotAlias</code> operation is successful.</p>
  ## 
  let valid = call_613359.validator(path, query, header, formData, body)
  let scheme = call_613359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613359.url(scheme.get, call_613359.host, call_613359.base,
                         call_613359.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613359, url, valid)

proc call*(call_613360: Call_DeleteBotAlias_613347; botName: string; name: string): Recallable =
  ## deleteBotAlias
  ## <p>Deletes an alias for the specified bot. </p> <p>You can't delete an alias that is used in the association between a bot and a messaging channel. If an alias is used in a channel association, the <code>DeleteBot</code> operation returns a <code>ResourceInUseException</code> exception that includes a reference to the channel association that refers to the bot. You can remove the reference to the alias by deleting the channel association. If you get the same exception again, delete the referring association until the <code>DeleteBotAlias</code> operation is successful.</p>
  ##   botName: string (required)
  ##          : The name of the bot that the alias points to.
  ##   name: string (required)
  ##       : The name of the alias to delete. The name is case sensitive. 
  var path_613361 = newJObject()
  add(path_613361, "botName", newJString(botName))
  add(path_613361, "name", newJString(name))
  result = call_613360.call(path_613361, nil, nil, nil, nil)

var deleteBotAlias* = Call_DeleteBotAlias_613347(name: "deleteBotAlias",
    meth: HttpMethod.HttpDelete, host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/aliases/{name}", validator: validate_DeleteBotAlias_613348,
    base: "/", url: url_DeleteBotAlias_613349, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBotChannelAssociation_613362 = ref object of OpenApiRestCall_612659
proc url_GetBotChannelAssociation_613364(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBotChannelAssociation_613363(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about the association between an Amazon Lex bot and a messaging platform.</p> <p>This operation requires permissions for the <code>lex:GetBotChannelAssociation</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   botName: JString (required)
  ##          : The name of the Amazon Lex bot.
  ##   name: JString (required)
  ##       : The name of the association between the bot and the channel. The name is case sensitive. 
  ##   aliasName: JString (required)
  ##            : An alias pointing to the specific version of the Amazon Lex bot to which this association is being made.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `botName` field"
  var valid_613365 = path.getOrDefault("botName")
  valid_613365 = validateParameter(valid_613365, JString, required = true,
                                 default = nil)
  if valid_613365 != nil:
    section.add "botName", valid_613365
  var valid_613366 = path.getOrDefault("name")
  valid_613366 = validateParameter(valid_613366, JString, required = true,
                                 default = nil)
  if valid_613366 != nil:
    section.add "name", valid_613366
  var valid_613367 = path.getOrDefault("aliasName")
  valid_613367 = validateParameter(valid_613367, JString, required = true,
                                 default = nil)
  if valid_613367 != nil:
    section.add "aliasName", valid_613367
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613368 = header.getOrDefault("X-Amz-Signature")
  valid_613368 = validateParameter(valid_613368, JString, required = false,
                                 default = nil)
  if valid_613368 != nil:
    section.add "X-Amz-Signature", valid_613368
  var valid_613369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613369 = validateParameter(valid_613369, JString, required = false,
                                 default = nil)
  if valid_613369 != nil:
    section.add "X-Amz-Content-Sha256", valid_613369
  var valid_613370 = header.getOrDefault("X-Amz-Date")
  valid_613370 = validateParameter(valid_613370, JString, required = false,
                                 default = nil)
  if valid_613370 != nil:
    section.add "X-Amz-Date", valid_613370
  var valid_613371 = header.getOrDefault("X-Amz-Credential")
  valid_613371 = validateParameter(valid_613371, JString, required = false,
                                 default = nil)
  if valid_613371 != nil:
    section.add "X-Amz-Credential", valid_613371
  var valid_613372 = header.getOrDefault("X-Amz-Security-Token")
  valid_613372 = validateParameter(valid_613372, JString, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "X-Amz-Security-Token", valid_613372
  var valid_613373 = header.getOrDefault("X-Amz-Algorithm")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-Algorithm", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-SignedHeaders", valid_613374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613375: Call_GetBotChannelAssociation_613362; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the association between an Amazon Lex bot and a messaging platform.</p> <p>This operation requires permissions for the <code>lex:GetBotChannelAssociation</code> action.</p>
  ## 
  let valid = call_613375.validator(path, query, header, formData, body)
  let scheme = call_613375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613375.url(scheme.get, call_613375.host, call_613375.base,
                         call_613375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613375, url, valid)

proc call*(call_613376: Call_GetBotChannelAssociation_613362; botName: string;
          name: string; aliasName: string): Recallable =
  ## getBotChannelAssociation
  ## <p>Returns information about the association between an Amazon Lex bot and a messaging platform.</p> <p>This operation requires permissions for the <code>lex:GetBotChannelAssociation</code> action.</p>
  ##   botName: string (required)
  ##          : The name of the Amazon Lex bot.
  ##   name: string (required)
  ##       : The name of the association between the bot and the channel. The name is case sensitive. 
  ##   aliasName: string (required)
  ##            : An alias pointing to the specific version of the Amazon Lex bot to which this association is being made.
  var path_613377 = newJObject()
  add(path_613377, "botName", newJString(botName))
  add(path_613377, "name", newJString(name))
  add(path_613377, "aliasName", newJString(aliasName))
  result = call_613376.call(path_613377, nil, nil, nil, nil)

var getBotChannelAssociation* = Call_GetBotChannelAssociation_613362(
    name: "getBotChannelAssociation", meth: HttpMethod.HttpGet,
    host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/aliases/{aliasName}/channels/{name}",
    validator: validate_GetBotChannelAssociation_613363, base: "/",
    url: url_GetBotChannelAssociation_613364, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBotChannelAssociation_613378 = ref object of OpenApiRestCall_612659
proc url_DeleteBotChannelAssociation_613380(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBotChannelAssociation_613379(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the association between an Amazon Lex bot and a messaging platform.</p> <p>This operation requires permission for the <code>lex:DeleteBotChannelAssociation</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   botName: JString (required)
  ##          : The name of the Amazon Lex bot.
  ##   name: JString (required)
  ##       : The name of the association. The name is case sensitive. 
  ##   aliasName: JString (required)
  ##            : An alias that points to the specific version of the Amazon Lex bot to which this association is being made.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `botName` field"
  var valid_613381 = path.getOrDefault("botName")
  valid_613381 = validateParameter(valid_613381, JString, required = true,
                                 default = nil)
  if valid_613381 != nil:
    section.add "botName", valid_613381
  var valid_613382 = path.getOrDefault("name")
  valid_613382 = validateParameter(valid_613382, JString, required = true,
                                 default = nil)
  if valid_613382 != nil:
    section.add "name", valid_613382
  var valid_613383 = path.getOrDefault("aliasName")
  valid_613383 = validateParameter(valid_613383, JString, required = true,
                                 default = nil)
  if valid_613383 != nil:
    section.add "aliasName", valid_613383
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613384 = header.getOrDefault("X-Amz-Signature")
  valid_613384 = validateParameter(valid_613384, JString, required = false,
                                 default = nil)
  if valid_613384 != nil:
    section.add "X-Amz-Signature", valid_613384
  var valid_613385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613385 = validateParameter(valid_613385, JString, required = false,
                                 default = nil)
  if valid_613385 != nil:
    section.add "X-Amz-Content-Sha256", valid_613385
  var valid_613386 = header.getOrDefault("X-Amz-Date")
  valid_613386 = validateParameter(valid_613386, JString, required = false,
                                 default = nil)
  if valid_613386 != nil:
    section.add "X-Amz-Date", valid_613386
  var valid_613387 = header.getOrDefault("X-Amz-Credential")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "X-Amz-Credential", valid_613387
  var valid_613388 = header.getOrDefault("X-Amz-Security-Token")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "X-Amz-Security-Token", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Algorithm")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Algorithm", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-SignedHeaders", valid_613390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613391: Call_DeleteBotChannelAssociation_613378; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the association between an Amazon Lex bot and a messaging platform.</p> <p>This operation requires permission for the <code>lex:DeleteBotChannelAssociation</code> action.</p>
  ## 
  let valid = call_613391.validator(path, query, header, formData, body)
  let scheme = call_613391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613391.url(scheme.get, call_613391.host, call_613391.base,
                         call_613391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613391, url, valid)

proc call*(call_613392: Call_DeleteBotChannelAssociation_613378; botName: string;
          name: string; aliasName: string): Recallable =
  ## deleteBotChannelAssociation
  ## <p>Deletes the association between an Amazon Lex bot and a messaging platform.</p> <p>This operation requires permission for the <code>lex:DeleteBotChannelAssociation</code> action.</p>
  ##   botName: string (required)
  ##          : The name of the Amazon Lex bot.
  ##   name: string (required)
  ##       : The name of the association. The name is case sensitive. 
  ##   aliasName: string (required)
  ##            : An alias that points to the specific version of the Amazon Lex bot to which this association is being made.
  var path_613393 = newJObject()
  add(path_613393, "botName", newJString(botName))
  add(path_613393, "name", newJString(name))
  add(path_613393, "aliasName", newJString(aliasName))
  result = call_613392.call(path_613393, nil, nil, nil, nil)

var deleteBotChannelAssociation* = Call_DeleteBotChannelAssociation_613378(
    name: "deleteBotChannelAssociation", meth: HttpMethod.HttpDelete,
    host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/aliases/{aliasName}/channels/{name}",
    validator: validate_DeleteBotChannelAssociation_613379, base: "/",
    url: url_DeleteBotChannelAssociation_613380,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBotVersion_613394 = ref object of OpenApiRestCall_612659
proc url_DeleteBotVersion_613396(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBotVersion_613395(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes a specific version of a bot. To delete all versions of a bot, use the <a>DeleteBot</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteBotVersion</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   version: JString (required)
  ##          : The version of the bot to delete. You cannot delete the <code>$LATEST</code> version of the bot. To delete the <code>$LATEST</code> version, use the <a>DeleteBot</a> operation.
  ##   name: JString (required)
  ##       : The name of the bot.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `version` field"
  var valid_613397 = path.getOrDefault("version")
  valid_613397 = validateParameter(valid_613397, JString, required = true,
                                 default = nil)
  if valid_613397 != nil:
    section.add "version", valid_613397
  var valid_613398 = path.getOrDefault("name")
  valid_613398 = validateParameter(valid_613398, JString, required = true,
                                 default = nil)
  if valid_613398 != nil:
    section.add "name", valid_613398
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613399 = header.getOrDefault("X-Amz-Signature")
  valid_613399 = validateParameter(valid_613399, JString, required = false,
                                 default = nil)
  if valid_613399 != nil:
    section.add "X-Amz-Signature", valid_613399
  var valid_613400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613400 = validateParameter(valid_613400, JString, required = false,
                                 default = nil)
  if valid_613400 != nil:
    section.add "X-Amz-Content-Sha256", valid_613400
  var valid_613401 = header.getOrDefault("X-Amz-Date")
  valid_613401 = validateParameter(valid_613401, JString, required = false,
                                 default = nil)
  if valid_613401 != nil:
    section.add "X-Amz-Date", valid_613401
  var valid_613402 = header.getOrDefault("X-Amz-Credential")
  valid_613402 = validateParameter(valid_613402, JString, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "X-Amz-Credential", valid_613402
  var valid_613403 = header.getOrDefault("X-Amz-Security-Token")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "X-Amz-Security-Token", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Algorithm")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Algorithm", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-SignedHeaders", valid_613405
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613406: Call_DeleteBotVersion_613394; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a specific version of a bot. To delete all versions of a bot, use the <a>DeleteBot</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteBotVersion</code> action.</p>
  ## 
  let valid = call_613406.validator(path, query, header, formData, body)
  let scheme = call_613406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613406.url(scheme.get, call_613406.host, call_613406.base,
                         call_613406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613406, url, valid)

proc call*(call_613407: Call_DeleteBotVersion_613394; version: string; name: string): Recallable =
  ## deleteBotVersion
  ## <p>Deletes a specific version of a bot. To delete all versions of a bot, use the <a>DeleteBot</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteBotVersion</code> action.</p>
  ##   version: string (required)
  ##          : The version of the bot to delete. You cannot delete the <code>$LATEST</code> version of the bot. To delete the <code>$LATEST</code> version, use the <a>DeleteBot</a> operation.
  ##   name: string (required)
  ##       : The name of the bot.
  var path_613408 = newJObject()
  add(path_613408, "version", newJString(version))
  add(path_613408, "name", newJString(name))
  result = call_613407.call(path_613408, nil, nil, nil, nil)

var deleteBotVersion* = Call_DeleteBotVersion_613394(name: "deleteBotVersion",
    meth: HttpMethod.HttpDelete, host: "models.lex.amazonaws.com",
    route: "/bots/{name}/versions/{version}",
    validator: validate_DeleteBotVersion_613395, base: "/",
    url: url_DeleteBotVersion_613396, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntent_613409 = ref object of OpenApiRestCall_612659
proc url_DeleteIntent_613411(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteIntent_613410(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613412 = path.getOrDefault("name")
  valid_613412 = validateParameter(valid_613412, JString, required = true,
                                 default = nil)
  if valid_613412 != nil:
    section.add "name", valid_613412
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613413 = header.getOrDefault("X-Amz-Signature")
  valid_613413 = validateParameter(valid_613413, JString, required = false,
                                 default = nil)
  if valid_613413 != nil:
    section.add "X-Amz-Signature", valid_613413
  var valid_613414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613414 = validateParameter(valid_613414, JString, required = false,
                                 default = nil)
  if valid_613414 != nil:
    section.add "X-Amz-Content-Sha256", valid_613414
  var valid_613415 = header.getOrDefault("X-Amz-Date")
  valid_613415 = validateParameter(valid_613415, JString, required = false,
                                 default = nil)
  if valid_613415 != nil:
    section.add "X-Amz-Date", valid_613415
  var valid_613416 = header.getOrDefault("X-Amz-Credential")
  valid_613416 = validateParameter(valid_613416, JString, required = false,
                                 default = nil)
  if valid_613416 != nil:
    section.add "X-Amz-Credential", valid_613416
  var valid_613417 = header.getOrDefault("X-Amz-Security-Token")
  valid_613417 = validateParameter(valid_613417, JString, required = false,
                                 default = nil)
  if valid_613417 != nil:
    section.add "X-Amz-Security-Token", valid_613417
  var valid_613418 = header.getOrDefault("X-Amz-Algorithm")
  valid_613418 = validateParameter(valid_613418, JString, required = false,
                                 default = nil)
  if valid_613418 != nil:
    section.add "X-Amz-Algorithm", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-SignedHeaders", valid_613419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613420: Call_DeleteIntent_613409; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes all versions of the intent, including the <code>$LATEST</code> version. To delete a specific version of the intent, use the <a>DeleteIntentVersion</a> operation.</p> <p> You can delete a version of an intent only if it is not referenced. To delete an intent that is referred to in one or more bots (see <a>how-it-works</a>), you must remove those references first. </p> <note> <p> If you get the <code>ResourceInUseException</code> exception, it provides an example reference that shows where the intent is referenced. To remove the reference to the intent, either update the bot or delete it. If you get the same exception when you attempt to delete the intent again, repeat until the intent has no references and the call to <code>DeleteIntent</code> is successful. </p> </note> <p> This operation requires permission for the <code>lex:DeleteIntent</code> action. </p>
  ## 
  let valid = call_613420.validator(path, query, header, formData, body)
  let scheme = call_613420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613420.url(scheme.get, call_613420.host, call_613420.base,
                         call_613420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613420, url, valid)

proc call*(call_613421: Call_DeleteIntent_613409; name: string): Recallable =
  ## deleteIntent
  ## <p>Deletes all versions of the intent, including the <code>$LATEST</code> version. To delete a specific version of the intent, use the <a>DeleteIntentVersion</a> operation.</p> <p> You can delete a version of an intent only if it is not referenced. To delete an intent that is referred to in one or more bots (see <a>how-it-works</a>), you must remove those references first. </p> <note> <p> If you get the <code>ResourceInUseException</code> exception, it provides an example reference that shows where the intent is referenced. To remove the reference to the intent, either update the bot or delete it. If you get the same exception when you attempt to delete the intent again, repeat until the intent has no references and the call to <code>DeleteIntent</code> is successful. </p> </note> <p> This operation requires permission for the <code>lex:DeleteIntent</code> action. </p>
  ##   name: string (required)
  ##       : The name of the intent. The name is case sensitive. 
  var path_613422 = newJObject()
  add(path_613422, "name", newJString(name))
  result = call_613421.call(path_613422, nil, nil, nil, nil)

var deleteIntent* = Call_DeleteIntent_613409(name: "deleteIntent",
    meth: HttpMethod.HttpDelete, host: "models.lex.amazonaws.com",
    route: "/intents/{name}", validator: validate_DeleteIntent_613410, base: "/",
    url: url_DeleteIntent_613411, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntent_613423 = ref object of OpenApiRestCall_612659
proc url_GetIntent_613425(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIntent_613424(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Returns information about an intent. In addition to the intent name, you must specify the intent version. </p> <p> This operation requires permissions to perform the <code>lex:GetIntent</code> action. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   version: JString (required)
  ##          : The version of the intent.
  ##   name: JString (required)
  ##       : The name of the intent. The name is case sensitive. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `version` field"
  var valid_613426 = path.getOrDefault("version")
  valid_613426 = validateParameter(valid_613426, JString, required = true,
                                 default = nil)
  if valid_613426 != nil:
    section.add "version", valid_613426
  var valid_613427 = path.getOrDefault("name")
  valid_613427 = validateParameter(valid_613427, JString, required = true,
                                 default = nil)
  if valid_613427 != nil:
    section.add "name", valid_613427
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613428 = header.getOrDefault("X-Amz-Signature")
  valid_613428 = validateParameter(valid_613428, JString, required = false,
                                 default = nil)
  if valid_613428 != nil:
    section.add "X-Amz-Signature", valid_613428
  var valid_613429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613429 = validateParameter(valid_613429, JString, required = false,
                                 default = nil)
  if valid_613429 != nil:
    section.add "X-Amz-Content-Sha256", valid_613429
  var valid_613430 = header.getOrDefault("X-Amz-Date")
  valid_613430 = validateParameter(valid_613430, JString, required = false,
                                 default = nil)
  if valid_613430 != nil:
    section.add "X-Amz-Date", valid_613430
  var valid_613431 = header.getOrDefault("X-Amz-Credential")
  valid_613431 = validateParameter(valid_613431, JString, required = false,
                                 default = nil)
  if valid_613431 != nil:
    section.add "X-Amz-Credential", valid_613431
  var valid_613432 = header.getOrDefault("X-Amz-Security-Token")
  valid_613432 = validateParameter(valid_613432, JString, required = false,
                                 default = nil)
  if valid_613432 != nil:
    section.add "X-Amz-Security-Token", valid_613432
  var valid_613433 = header.getOrDefault("X-Amz-Algorithm")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-Algorithm", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-SignedHeaders", valid_613434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613435: Call_GetIntent_613423; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns information about an intent. In addition to the intent name, you must specify the intent version. </p> <p> This operation requires permissions to perform the <code>lex:GetIntent</code> action. </p>
  ## 
  let valid = call_613435.validator(path, query, header, formData, body)
  let scheme = call_613435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613435.url(scheme.get, call_613435.host, call_613435.base,
                         call_613435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613435, url, valid)

proc call*(call_613436: Call_GetIntent_613423; version: string; name: string): Recallable =
  ## getIntent
  ## <p> Returns information about an intent. In addition to the intent name, you must specify the intent version. </p> <p> This operation requires permissions to perform the <code>lex:GetIntent</code> action. </p>
  ##   version: string (required)
  ##          : The version of the intent.
  ##   name: string (required)
  ##       : The name of the intent. The name is case sensitive. 
  var path_613437 = newJObject()
  add(path_613437, "version", newJString(version))
  add(path_613437, "name", newJString(name))
  result = call_613436.call(path_613437, nil, nil, nil, nil)

var getIntent* = Call_GetIntent_613423(name: "getIntent", meth: HttpMethod.HttpGet,
                                    host: "models.lex.amazonaws.com", route: "/intents/{name}/versions/{version}",
                                    validator: validate_GetIntent_613424,
                                    base: "/", url: url_GetIntent_613425,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntentVersion_613438 = ref object of OpenApiRestCall_612659
proc url_DeleteIntentVersion_613440(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteIntentVersion_613439(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Deletes a specific version of an intent. To delete all versions of a intent, use the <a>DeleteIntent</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteIntentVersion</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   version: JString (required)
  ##          : The version of the intent to delete. You cannot delete the <code>$LATEST</code> version of the intent. To delete the <code>$LATEST</code> version, use the <a>DeleteIntent</a> operation.
  ##   name: JString (required)
  ##       : The name of the intent.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `version` field"
  var valid_613441 = path.getOrDefault("version")
  valid_613441 = validateParameter(valid_613441, JString, required = true,
                                 default = nil)
  if valid_613441 != nil:
    section.add "version", valid_613441
  var valid_613442 = path.getOrDefault("name")
  valid_613442 = validateParameter(valid_613442, JString, required = true,
                                 default = nil)
  if valid_613442 != nil:
    section.add "name", valid_613442
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613443 = header.getOrDefault("X-Amz-Signature")
  valid_613443 = validateParameter(valid_613443, JString, required = false,
                                 default = nil)
  if valid_613443 != nil:
    section.add "X-Amz-Signature", valid_613443
  var valid_613444 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613444 = validateParameter(valid_613444, JString, required = false,
                                 default = nil)
  if valid_613444 != nil:
    section.add "X-Amz-Content-Sha256", valid_613444
  var valid_613445 = header.getOrDefault("X-Amz-Date")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "X-Amz-Date", valid_613445
  var valid_613446 = header.getOrDefault("X-Amz-Credential")
  valid_613446 = validateParameter(valid_613446, JString, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "X-Amz-Credential", valid_613446
  var valid_613447 = header.getOrDefault("X-Amz-Security-Token")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "X-Amz-Security-Token", valid_613447
  var valid_613448 = header.getOrDefault("X-Amz-Algorithm")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-Algorithm", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-SignedHeaders", valid_613449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613450: Call_DeleteIntentVersion_613438; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a specific version of an intent. To delete all versions of a intent, use the <a>DeleteIntent</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteIntentVersion</code> action.</p>
  ## 
  let valid = call_613450.validator(path, query, header, formData, body)
  let scheme = call_613450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613450.url(scheme.get, call_613450.host, call_613450.base,
                         call_613450.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613450, url, valid)

proc call*(call_613451: Call_DeleteIntentVersion_613438; version: string;
          name: string): Recallable =
  ## deleteIntentVersion
  ## <p>Deletes a specific version of an intent. To delete all versions of a intent, use the <a>DeleteIntent</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteIntentVersion</code> action.</p>
  ##   version: string (required)
  ##          : The version of the intent to delete. You cannot delete the <code>$LATEST</code> version of the intent. To delete the <code>$LATEST</code> version, use the <a>DeleteIntent</a> operation.
  ##   name: string (required)
  ##       : The name of the intent.
  var path_613452 = newJObject()
  add(path_613452, "version", newJString(version))
  add(path_613452, "name", newJString(name))
  result = call_613451.call(path_613452, nil, nil, nil, nil)

var deleteIntentVersion* = Call_DeleteIntentVersion_613438(
    name: "deleteIntentVersion", meth: HttpMethod.HttpDelete,
    host: "models.lex.amazonaws.com", route: "/intents/{name}/versions/{version}",
    validator: validate_DeleteIntentVersion_613439, base: "/",
    url: url_DeleteIntentVersion_613440, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSlotType_613453 = ref object of OpenApiRestCall_612659
proc url_DeleteSlotType_613455(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteSlotType_613454(path: JsonNode; query: JsonNode;
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
  var valid_613456 = path.getOrDefault("name")
  valid_613456 = validateParameter(valid_613456, JString, required = true,
                                 default = nil)
  if valid_613456 != nil:
    section.add "name", valid_613456
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613457 = header.getOrDefault("X-Amz-Signature")
  valid_613457 = validateParameter(valid_613457, JString, required = false,
                                 default = nil)
  if valid_613457 != nil:
    section.add "X-Amz-Signature", valid_613457
  var valid_613458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613458 = validateParameter(valid_613458, JString, required = false,
                                 default = nil)
  if valid_613458 != nil:
    section.add "X-Amz-Content-Sha256", valid_613458
  var valid_613459 = header.getOrDefault("X-Amz-Date")
  valid_613459 = validateParameter(valid_613459, JString, required = false,
                                 default = nil)
  if valid_613459 != nil:
    section.add "X-Amz-Date", valid_613459
  var valid_613460 = header.getOrDefault("X-Amz-Credential")
  valid_613460 = validateParameter(valid_613460, JString, required = false,
                                 default = nil)
  if valid_613460 != nil:
    section.add "X-Amz-Credential", valid_613460
  var valid_613461 = header.getOrDefault("X-Amz-Security-Token")
  valid_613461 = validateParameter(valid_613461, JString, required = false,
                                 default = nil)
  if valid_613461 != nil:
    section.add "X-Amz-Security-Token", valid_613461
  var valid_613462 = header.getOrDefault("X-Amz-Algorithm")
  valid_613462 = validateParameter(valid_613462, JString, required = false,
                                 default = nil)
  if valid_613462 != nil:
    section.add "X-Amz-Algorithm", valid_613462
  var valid_613463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-SignedHeaders", valid_613463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613464: Call_DeleteSlotType_613453; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes all versions of the slot type, including the <code>$LATEST</code> version. To delete a specific version of the slot type, use the <a>DeleteSlotTypeVersion</a> operation.</p> <p> You can delete a version of a slot type only if it is not referenced. To delete a slot type that is referred to in one or more intents, you must remove those references first. </p> <note> <p> If you get the <code>ResourceInUseException</code> exception, the exception provides an example reference that shows the intent where the slot type is referenced. To remove the reference to the slot type, either update the intent or delete it. If you get the same exception when you attempt to delete the slot type again, repeat until the slot type has no references and the <code>DeleteSlotType</code> call is successful. </p> </note> <p>This operation requires permission for the <code>lex:DeleteSlotType</code> action.</p>
  ## 
  let valid = call_613464.validator(path, query, header, formData, body)
  let scheme = call_613464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613464.url(scheme.get, call_613464.host, call_613464.base,
                         call_613464.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613464, url, valid)

proc call*(call_613465: Call_DeleteSlotType_613453; name: string): Recallable =
  ## deleteSlotType
  ## <p>Deletes all versions of the slot type, including the <code>$LATEST</code> version. To delete a specific version of the slot type, use the <a>DeleteSlotTypeVersion</a> operation.</p> <p> You can delete a version of a slot type only if it is not referenced. To delete a slot type that is referred to in one or more intents, you must remove those references first. </p> <note> <p> If you get the <code>ResourceInUseException</code> exception, the exception provides an example reference that shows the intent where the slot type is referenced. To remove the reference to the slot type, either update the intent or delete it. If you get the same exception when you attempt to delete the slot type again, repeat until the slot type has no references and the <code>DeleteSlotType</code> call is successful. </p> </note> <p>This operation requires permission for the <code>lex:DeleteSlotType</code> action.</p>
  ##   name: string (required)
  ##       : The name of the slot type. The name is case sensitive. 
  var path_613466 = newJObject()
  add(path_613466, "name", newJString(name))
  result = call_613465.call(path_613466, nil, nil, nil, nil)

var deleteSlotType* = Call_DeleteSlotType_613453(name: "deleteSlotType",
    meth: HttpMethod.HttpDelete, host: "models.lex.amazonaws.com",
    route: "/slottypes/{name}", validator: validate_DeleteSlotType_613454,
    base: "/", url: url_DeleteSlotType_613455, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSlotTypeVersion_613467 = ref object of OpenApiRestCall_612659
proc url_DeleteSlotTypeVersion_613469(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteSlotTypeVersion_613468(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a specific version of a slot type. To delete all versions of a slot type, use the <a>DeleteSlotType</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteSlotTypeVersion</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   version: JString (required)
  ##          : The version of the slot type to delete. You cannot delete the <code>$LATEST</code> version of the slot type. To delete the <code>$LATEST</code> version, use the <a>DeleteSlotType</a> operation.
  ##   name: JString (required)
  ##       : The name of the slot type.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `version` field"
  var valid_613470 = path.getOrDefault("version")
  valid_613470 = validateParameter(valid_613470, JString, required = true,
                                 default = nil)
  if valid_613470 != nil:
    section.add "version", valid_613470
  var valid_613471 = path.getOrDefault("name")
  valid_613471 = validateParameter(valid_613471, JString, required = true,
                                 default = nil)
  if valid_613471 != nil:
    section.add "name", valid_613471
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613472 = header.getOrDefault("X-Amz-Signature")
  valid_613472 = validateParameter(valid_613472, JString, required = false,
                                 default = nil)
  if valid_613472 != nil:
    section.add "X-Amz-Signature", valid_613472
  var valid_613473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613473 = validateParameter(valid_613473, JString, required = false,
                                 default = nil)
  if valid_613473 != nil:
    section.add "X-Amz-Content-Sha256", valid_613473
  var valid_613474 = header.getOrDefault("X-Amz-Date")
  valid_613474 = validateParameter(valid_613474, JString, required = false,
                                 default = nil)
  if valid_613474 != nil:
    section.add "X-Amz-Date", valid_613474
  var valid_613475 = header.getOrDefault("X-Amz-Credential")
  valid_613475 = validateParameter(valid_613475, JString, required = false,
                                 default = nil)
  if valid_613475 != nil:
    section.add "X-Amz-Credential", valid_613475
  var valid_613476 = header.getOrDefault("X-Amz-Security-Token")
  valid_613476 = validateParameter(valid_613476, JString, required = false,
                                 default = nil)
  if valid_613476 != nil:
    section.add "X-Amz-Security-Token", valid_613476
  var valid_613477 = header.getOrDefault("X-Amz-Algorithm")
  valid_613477 = validateParameter(valid_613477, JString, required = false,
                                 default = nil)
  if valid_613477 != nil:
    section.add "X-Amz-Algorithm", valid_613477
  var valid_613478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613478 = validateParameter(valid_613478, JString, required = false,
                                 default = nil)
  if valid_613478 != nil:
    section.add "X-Amz-SignedHeaders", valid_613478
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613479: Call_DeleteSlotTypeVersion_613467; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a specific version of a slot type. To delete all versions of a slot type, use the <a>DeleteSlotType</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteSlotTypeVersion</code> action.</p>
  ## 
  let valid = call_613479.validator(path, query, header, formData, body)
  let scheme = call_613479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613479.url(scheme.get, call_613479.host, call_613479.base,
                         call_613479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613479, url, valid)

proc call*(call_613480: Call_DeleteSlotTypeVersion_613467; version: string;
          name: string): Recallable =
  ## deleteSlotTypeVersion
  ## <p>Deletes a specific version of a slot type. To delete all versions of a slot type, use the <a>DeleteSlotType</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteSlotTypeVersion</code> action.</p>
  ##   version: string (required)
  ##          : The version of the slot type to delete. You cannot delete the <code>$LATEST</code> version of the slot type. To delete the <code>$LATEST</code> version, use the <a>DeleteSlotType</a> operation.
  ##   name: string (required)
  ##       : The name of the slot type.
  var path_613481 = newJObject()
  add(path_613481, "version", newJString(version))
  add(path_613481, "name", newJString(name))
  result = call_613480.call(path_613481, nil, nil, nil, nil)

var deleteSlotTypeVersion* = Call_DeleteSlotTypeVersion_613467(
    name: "deleteSlotTypeVersion", meth: HttpMethod.HttpDelete,
    host: "models.lex.amazonaws.com",
    route: "/slottypes/{name}/version/{version}",
    validator: validate_DeleteSlotTypeVersion_613468, base: "/",
    url: url_DeleteSlotTypeVersion_613469, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUtterances_613482 = ref object of OpenApiRestCall_612659
proc url_DeleteUtterances_613484(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteUtterances_613483(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes stored utterances.</p> <p>Amazon Lex stores the utterances that users send to your bot. Utterances are stored for 15 days for use with the <a>GetUtterancesView</a> operation, and then stored indefinitely for use in improving the ability of your bot to respond to user input.</p> <p>Use the <code>DeleteUtterances</code> operation to manually delete stored utterances for a specific user. When you use the <code>DeleteUtterances</code> operation, utterances stored for improving your bot's ability to respond to user input are deleted immediately. Utterances stored for use with the <code>GetUtterancesView</code> operation are deleted after 15 days.</p> <p>This operation requires permissions for the <code>lex:DeleteUtterances</code> action.</p>
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
  var valid_613485 = path.getOrDefault("botName")
  valid_613485 = validateParameter(valid_613485, JString, required = true,
                                 default = nil)
  if valid_613485 != nil:
    section.add "botName", valid_613485
  var valid_613486 = path.getOrDefault("userId")
  valid_613486 = validateParameter(valid_613486, JString, required = true,
                                 default = nil)
  if valid_613486 != nil:
    section.add "userId", valid_613486
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613487 = header.getOrDefault("X-Amz-Signature")
  valid_613487 = validateParameter(valid_613487, JString, required = false,
                                 default = nil)
  if valid_613487 != nil:
    section.add "X-Amz-Signature", valid_613487
  var valid_613488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613488 = validateParameter(valid_613488, JString, required = false,
                                 default = nil)
  if valid_613488 != nil:
    section.add "X-Amz-Content-Sha256", valid_613488
  var valid_613489 = header.getOrDefault("X-Amz-Date")
  valid_613489 = validateParameter(valid_613489, JString, required = false,
                                 default = nil)
  if valid_613489 != nil:
    section.add "X-Amz-Date", valid_613489
  var valid_613490 = header.getOrDefault("X-Amz-Credential")
  valid_613490 = validateParameter(valid_613490, JString, required = false,
                                 default = nil)
  if valid_613490 != nil:
    section.add "X-Amz-Credential", valid_613490
  var valid_613491 = header.getOrDefault("X-Amz-Security-Token")
  valid_613491 = validateParameter(valid_613491, JString, required = false,
                                 default = nil)
  if valid_613491 != nil:
    section.add "X-Amz-Security-Token", valid_613491
  var valid_613492 = header.getOrDefault("X-Amz-Algorithm")
  valid_613492 = validateParameter(valid_613492, JString, required = false,
                                 default = nil)
  if valid_613492 != nil:
    section.add "X-Amz-Algorithm", valid_613492
  var valid_613493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613493 = validateParameter(valid_613493, JString, required = false,
                                 default = nil)
  if valid_613493 != nil:
    section.add "X-Amz-SignedHeaders", valid_613493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613494: Call_DeleteUtterances_613482; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes stored utterances.</p> <p>Amazon Lex stores the utterances that users send to your bot. Utterances are stored for 15 days for use with the <a>GetUtterancesView</a> operation, and then stored indefinitely for use in improving the ability of your bot to respond to user input.</p> <p>Use the <code>DeleteUtterances</code> operation to manually delete stored utterances for a specific user. When you use the <code>DeleteUtterances</code> operation, utterances stored for improving your bot's ability to respond to user input are deleted immediately. Utterances stored for use with the <code>GetUtterancesView</code> operation are deleted after 15 days.</p> <p>This operation requires permissions for the <code>lex:DeleteUtterances</code> action.</p>
  ## 
  let valid = call_613494.validator(path, query, header, formData, body)
  let scheme = call_613494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613494.url(scheme.get, call_613494.host, call_613494.base,
                         call_613494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613494, url, valid)

proc call*(call_613495: Call_DeleteUtterances_613482; botName: string; userId: string): Recallable =
  ## deleteUtterances
  ## <p>Deletes stored utterances.</p> <p>Amazon Lex stores the utterances that users send to your bot. Utterances are stored for 15 days for use with the <a>GetUtterancesView</a> operation, and then stored indefinitely for use in improving the ability of your bot to respond to user input.</p> <p>Use the <code>DeleteUtterances</code> operation to manually delete stored utterances for a specific user. When you use the <code>DeleteUtterances</code> operation, utterances stored for improving your bot's ability to respond to user input are deleted immediately. Utterances stored for use with the <code>GetUtterancesView</code> operation are deleted after 15 days.</p> <p>This operation requires permissions for the <code>lex:DeleteUtterances</code> action.</p>
  ##   botName: string (required)
  ##          : The name of the bot that stored the utterances.
  ##   userId: string (required)
  ##         :  The unique identifier for the user that made the utterances. This is the user ID that was sent in the <a 
  ## href="http://docs.aws.amazon.com/lex/latest/dg/API_runtime_PostContent.html">PostContent</a> or <a 
  ## href="http://docs.aws.amazon.com/lex/latest/dg/API_runtime_PostText.html">PostText</a> operation request that contained the utterance.
  var path_613496 = newJObject()
  add(path_613496, "botName", newJString(botName))
  add(path_613496, "userId", newJString(userId))
  result = call_613495.call(path_613496, nil, nil, nil, nil)

var deleteUtterances* = Call_DeleteUtterances_613482(name: "deleteUtterances",
    meth: HttpMethod.HttpDelete, host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/utterances/{userId}",
    validator: validate_DeleteUtterances_613483, base: "/",
    url: url_DeleteUtterances_613484, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBot_613497 = ref object of OpenApiRestCall_612659
proc url_GetBot_613499(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBot_613498(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns metadata information for a specific bot. You must provide the bot name and the bot version or alias. </p> <p> This operation requires permissions for the <code>lex:GetBot</code> action. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the bot. The name is case sensitive. 
  ##   versionoralias: JString (required)
  ##                 : The version or alias of the bot.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_613500 = path.getOrDefault("name")
  valid_613500 = validateParameter(valid_613500, JString, required = true,
                                 default = nil)
  if valid_613500 != nil:
    section.add "name", valid_613500
  var valid_613501 = path.getOrDefault("versionoralias")
  valid_613501 = validateParameter(valid_613501, JString, required = true,
                                 default = nil)
  if valid_613501 != nil:
    section.add "versionoralias", valid_613501
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613502 = header.getOrDefault("X-Amz-Signature")
  valid_613502 = validateParameter(valid_613502, JString, required = false,
                                 default = nil)
  if valid_613502 != nil:
    section.add "X-Amz-Signature", valid_613502
  var valid_613503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613503 = validateParameter(valid_613503, JString, required = false,
                                 default = nil)
  if valid_613503 != nil:
    section.add "X-Amz-Content-Sha256", valid_613503
  var valid_613504 = header.getOrDefault("X-Amz-Date")
  valid_613504 = validateParameter(valid_613504, JString, required = false,
                                 default = nil)
  if valid_613504 != nil:
    section.add "X-Amz-Date", valid_613504
  var valid_613505 = header.getOrDefault("X-Amz-Credential")
  valid_613505 = validateParameter(valid_613505, JString, required = false,
                                 default = nil)
  if valid_613505 != nil:
    section.add "X-Amz-Credential", valid_613505
  var valid_613506 = header.getOrDefault("X-Amz-Security-Token")
  valid_613506 = validateParameter(valid_613506, JString, required = false,
                                 default = nil)
  if valid_613506 != nil:
    section.add "X-Amz-Security-Token", valid_613506
  var valid_613507 = header.getOrDefault("X-Amz-Algorithm")
  valid_613507 = validateParameter(valid_613507, JString, required = false,
                                 default = nil)
  if valid_613507 != nil:
    section.add "X-Amz-Algorithm", valid_613507
  var valid_613508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613508 = validateParameter(valid_613508, JString, required = false,
                                 default = nil)
  if valid_613508 != nil:
    section.add "X-Amz-SignedHeaders", valid_613508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613509: Call_GetBot_613497; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns metadata information for a specific bot. You must provide the bot name and the bot version or alias. </p> <p> This operation requires permissions for the <code>lex:GetBot</code> action. </p>
  ## 
  let valid = call_613509.validator(path, query, header, formData, body)
  let scheme = call_613509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613509.url(scheme.get, call_613509.host, call_613509.base,
                         call_613509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613509, url, valid)

proc call*(call_613510: Call_GetBot_613497; name: string; versionoralias: string): Recallable =
  ## getBot
  ## <p>Returns metadata information for a specific bot. You must provide the bot name and the bot version or alias. </p> <p> This operation requires permissions for the <code>lex:GetBot</code> action. </p>
  ##   name: string (required)
  ##       : The name of the bot. The name is case sensitive. 
  ##   versionoralias: string (required)
  ##                 : The version or alias of the bot.
  var path_613511 = newJObject()
  add(path_613511, "name", newJString(name))
  add(path_613511, "versionoralias", newJString(versionoralias))
  result = call_613510.call(path_613511, nil, nil, nil, nil)

var getBot* = Call_GetBot_613497(name: "getBot", meth: HttpMethod.HttpGet,
                              host: "models.lex.amazonaws.com",
                              route: "/bots/{name}/versions/{versionoralias}",
                              validator: validate_GetBot_613498, base: "/",
                              url: url_GetBot_613499,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBotAliases_613512 = ref object of OpenApiRestCall_612659
proc url_GetBotAliases_613514(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBotAliases_613513(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613515 = path.getOrDefault("botName")
  valid_613515 = validateParameter(valid_613515, JString, required = true,
                                 default = nil)
  if valid_613515 != nil:
    section.add "botName", valid_613515
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A pagination token for fetching the next page of aliases. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of aliases, specify the pagination token in the next request. 
  ##   nameContains: JString
  ##               : Substring to match in bot alias names. An alias will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  ##   maxResults: JInt
  ##             : The maximum number of aliases to return in the response. The default is 50. . 
  section = newJObject()
  var valid_613516 = query.getOrDefault("nextToken")
  valid_613516 = validateParameter(valid_613516, JString, required = false,
                                 default = nil)
  if valid_613516 != nil:
    section.add "nextToken", valid_613516
  var valid_613517 = query.getOrDefault("nameContains")
  valid_613517 = validateParameter(valid_613517, JString, required = false,
                                 default = nil)
  if valid_613517 != nil:
    section.add "nameContains", valid_613517
  var valid_613518 = query.getOrDefault("maxResults")
  valid_613518 = validateParameter(valid_613518, JInt, required = false, default = nil)
  if valid_613518 != nil:
    section.add "maxResults", valid_613518
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613519 = header.getOrDefault("X-Amz-Signature")
  valid_613519 = validateParameter(valid_613519, JString, required = false,
                                 default = nil)
  if valid_613519 != nil:
    section.add "X-Amz-Signature", valid_613519
  var valid_613520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613520 = validateParameter(valid_613520, JString, required = false,
                                 default = nil)
  if valid_613520 != nil:
    section.add "X-Amz-Content-Sha256", valid_613520
  var valid_613521 = header.getOrDefault("X-Amz-Date")
  valid_613521 = validateParameter(valid_613521, JString, required = false,
                                 default = nil)
  if valid_613521 != nil:
    section.add "X-Amz-Date", valid_613521
  var valid_613522 = header.getOrDefault("X-Amz-Credential")
  valid_613522 = validateParameter(valid_613522, JString, required = false,
                                 default = nil)
  if valid_613522 != nil:
    section.add "X-Amz-Credential", valid_613522
  var valid_613523 = header.getOrDefault("X-Amz-Security-Token")
  valid_613523 = validateParameter(valid_613523, JString, required = false,
                                 default = nil)
  if valid_613523 != nil:
    section.add "X-Amz-Security-Token", valid_613523
  var valid_613524 = header.getOrDefault("X-Amz-Algorithm")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "X-Amz-Algorithm", valid_613524
  var valid_613525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613525 = validateParameter(valid_613525, JString, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "X-Amz-SignedHeaders", valid_613525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613526: Call_GetBotAliases_613512; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of aliases for a specified Amazon Lex bot.</p> <p>This operation requires permissions for the <code>lex:GetBotAliases</code> action.</p>
  ## 
  let valid = call_613526.validator(path, query, header, formData, body)
  let scheme = call_613526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613526.url(scheme.get, call_613526.host, call_613526.base,
                         call_613526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613526, url, valid)

proc call*(call_613527: Call_GetBotAliases_613512; botName: string;
          nextToken: string = ""; nameContains: string = ""; maxResults: int = 0): Recallable =
  ## getBotAliases
  ## <p>Returns a list of aliases for a specified Amazon Lex bot.</p> <p>This operation requires permissions for the <code>lex:GetBotAliases</code> action.</p>
  ##   nextToken: string
  ##            : A pagination token for fetching the next page of aliases. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of aliases, specify the pagination token in the next request. 
  ##   botName: string (required)
  ##          : The name of the bot.
  ##   nameContains: string
  ##               : Substring to match in bot alias names. An alias will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  ##   maxResults: int
  ##             : The maximum number of aliases to return in the response. The default is 50. . 
  var path_613528 = newJObject()
  var query_613529 = newJObject()
  add(query_613529, "nextToken", newJString(nextToken))
  add(path_613528, "botName", newJString(botName))
  add(query_613529, "nameContains", newJString(nameContains))
  add(query_613529, "maxResults", newJInt(maxResults))
  result = call_613527.call(path_613528, query_613529, nil, nil, nil)

var getBotAliases* = Call_GetBotAliases_613512(name: "getBotAliases",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/aliases/", validator: validate_GetBotAliases_613513,
    base: "/", url: url_GetBotAliases_613514, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBotChannelAssociations_613530 = ref object of OpenApiRestCall_612659
proc url_GetBotChannelAssociations_613532(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBotChannelAssociations_613531(path: JsonNode; query: JsonNode;
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
  var valid_613533 = path.getOrDefault("botName")
  valid_613533 = validateParameter(valid_613533, JString, required = true,
                                 default = nil)
  if valid_613533 != nil:
    section.add "botName", valid_613533
  var valid_613534 = path.getOrDefault("aliasName")
  valid_613534 = validateParameter(valid_613534, JString, required = true,
                                 default = nil)
  if valid_613534 != nil:
    section.add "aliasName", valid_613534
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of associations to return in the response. The default is 50. 
  ##   nextToken: JString
  ##            : A pagination token for fetching the next page of associations. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of associations, specify the pagination token in the next request. 
  ##   nameContains: JString
  ##               : Substring to match in channel association names. An association will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz." To return all bot channel associations, use a hyphen ("-") as the <code>nameContains</code> parameter.
  section = newJObject()
  var valid_613535 = query.getOrDefault("maxResults")
  valid_613535 = validateParameter(valid_613535, JInt, required = false, default = nil)
  if valid_613535 != nil:
    section.add "maxResults", valid_613535
  var valid_613536 = query.getOrDefault("nextToken")
  valid_613536 = validateParameter(valid_613536, JString, required = false,
                                 default = nil)
  if valid_613536 != nil:
    section.add "nextToken", valid_613536
  var valid_613537 = query.getOrDefault("nameContains")
  valid_613537 = validateParameter(valid_613537, JString, required = false,
                                 default = nil)
  if valid_613537 != nil:
    section.add "nameContains", valid_613537
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613538 = header.getOrDefault("X-Amz-Signature")
  valid_613538 = validateParameter(valid_613538, JString, required = false,
                                 default = nil)
  if valid_613538 != nil:
    section.add "X-Amz-Signature", valid_613538
  var valid_613539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613539 = validateParameter(valid_613539, JString, required = false,
                                 default = nil)
  if valid_613539 != nil:
    section.add "X-Amz-Content-Sha256", valid_613539
  var valid_613540 = header.getOrDefault("X-Amz-Date")
  valid_613540 = validateParameter(valid_613540, JString, required = false,
                                 default = nil)
  if valid_613540 != nil:
    section.add "X-Amz-Date", valid_613540
  var valid_613541 = header.getOrDefault("X-Amz-Credential")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "X-Amz-Credential", valid_613541
  var valid_613542 = header.getOrDefault("X-Amz-Security-Token")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-Security-Token", valid_613542
  var valid_613543 = header.getOrDefault("X-Amz-Algorithm")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "X-Amz-Algorithm", valid_613543
  var valid_613544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "X-Amz-SignedHeaders", valid_613544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613545: Call_GetBotChannelAssociations_613530; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns a list of all of the channels associated with the specified bot. </p> <p>The <code>GetBotChannelAssociations</code> operation requires permissions for the <code>lex:GetBotChannelAssociations</code> action.</p>
  ## 
  let valid = call_613545.validator(path, query, header, formData, body)
  let scheme = call_613545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613545.url(scheme.get, call_613545.host, call_613545.base,
                         call_613545.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613545, url, valid)

proc call*(call_613546: Call_GetBotChannelAssociations_613530; botName: string;
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
  var path_613547 = newJObject()
  var query_613548 = newJObject()
  add(query_613548, "maxResults", newJInt(maxResults))
  add(query_613548, "nextToken", newJString(nextToken))
  add(path_613547, "botName", newJString(botName))
  add(query_613548, "nameContains", newJString(nameContains))
  add(path_613547, "aliasName", newJString(aliasName))
  result = call_613546.call(path_613547, query_613548, nil, nil, nil)

var getBotChannelAssociations* = Call_GetBotChannelAssociations_613530(
    name: "getBotChannelAssociations", meth: HttpMethod.HttpGet,
    host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/aliases/{aliasName}/channels/",
    validator: validate_GetBotChannelAssociations_613531, base: "/",
    url: url_GetBotChannelAssociations_613532,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBotVersions_613549 = ref object of OpenApiRestCall_612659
proc url_GetBotVersions_613551(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBotVersions_613550(path: JsonNode; query: JsonNode;
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
  var valid_613552 = path.getOrDefault("name")
  valid_613552 = validateParameter(valid_613552, JString, required = true,
                                 default = nil)
  if valid_613552 != nil:
    section.add "name", valid_613552
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A pagination token for fetching the next page of bot versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  ##   maxResults: JInt
  ##             : The maximum number of bot versions to return in the response. The default is 10.
  section = newJObject()
  var valid_613553 = query.getOrDefault("nextToken")
  valid_613553 = validateParameter(valid_613553, JString, required = false,
                                 default = nil)
  if valid_613553 != nil:
    section.add "nextToken", valid_613553
  var valid_613554 = query.getOrDefault("maxResults")
  valid_613554 = validateParameter(valid_613554, JInt, required = false, default = nil)
  if valid_613554 != nil:
    section.add "maxResults", valid_613554
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613555 = header.getOrDefault("X-Amz-Signature")
  valid_613555 = validateParameter(valid_613555, JString, required = false,
                                 default = nil)
  if valid_613555 != nil:
    section.add "X-Amz-Signature", valid_613555
  var valid_613556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "X-Amz-Content-Sha256", valid_613556
  var valid_613557 = header.getOrDefault("X-Amz-Date")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "X-Amz-Date", valid_613557
  var valid_613558 = header.getOrDefault("X-Amz-Credential")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-Credential", valid_613558
  var valid_613559 = header.getOrDefault("X-Amz-Security-Token")
  valid_613559 = validateParameter(valid_613559, JString, required = false,
                                 default = nil)
  if valid_613559 != nil:
    section.add "X-Amz-Security-Token", valid_613559
  var valid_613560 = header.getOrDefault("X-Amz-Algorithm")
  valid_613560 = validateParameter(valid_613560, JString, required = false,
                                 default = nil)
  if valid_613560 != nil:
    section.add "X-Amz-Algorithm", valid_613560
  var valid_613561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613561 = validateParameter(valid_613561, JString, required = false,
                                 default = nil)
  if valid_613561 != nil:
    section.add "X-Amz-SignedHeaders", valid_613561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613562: Call_GetBotVersions_613549; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about all of the versions of a bot.</p> <p>The <code>GetBotVersions</code> operation returns a <code>BotMetadata</code> object for each version of a bot. For example, if a bot has three numbered versions, the <code>GetBotVersions</code> operation returns four <code>BotMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetBotVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetBotVersions</code> action.</p>
  ## 
  let valid = call_613562.validator(path, query, header, formData, body)
  let scheme = call_613562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613562.url(scheme.get, call_613562.host, call_613562.base,
                         call_613562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613562, url, valid)

proc call*(call_613563: Call_GetBotVersions_613549; name: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## getBotVersions
  ## <p>Gets information about all of the versions of a bot.</p> <p>The <code>GetBotVersions</code> operation returns a <code>BotMetadata</code> object for each version of a bot. For example, if a bot has three numbered versions, the <code>GetBotVersions</code> operation returns four <code>BotMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetBotVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetBotVersions</code> action.</p>
  ##   nextToken: string
  ##            : A pagination token for fetching the next page of bot versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  ##   name: string (required)
  ##       : The name of the bot for which versions should be returned.
  ##   maxResults: int
  ##             : The maximum number of bot versions to return in the response. The default is 10.
  var path_613564 = newJObject()
  var query_613565 = newJObject()
  add(query_613565, "nextToken", newJString(nextToken))
  add(path_613564, "name", newJString(name))
  add(query_613565, "maxResults", newJInt(maxResults))
  result = call_613563.call(path_613564, query_613565, nil, nil, nil)

var getBotVersions* = Call_GetBotVersions_613549(name: "getBotVersions",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/bots/{name}/versions/", validator: validate_GetBotVersions_613550,
    base: "/", url: url_GetBotVersions_613551, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBots_613566 = ref object of OpenApiRestCall_612659
proc url_GetBots_613568(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBots_613567(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns bot information as follows: </p> <ul> <li> <p>If you provide the <code>nameContains</code> field, the response includes information for the <code>$LATEST</code> version of all bots whose name contains the specified string.</p> </li> <li> <p>If you don't specify the <code>nameContains</code> field, the operation returns information about the <code>$LATEST</code> version of all of your bots.</p> </li> </ul> <p>This operation requires permission for the <code>lex:GetBots</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A pagination token that fetches the next page of bots. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of bots, specify the pagination token in the next request. 
  ##   nameContains: JString
  ##               : Substring to match in bot names. A bot will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  ##   maxResults: JInt
  ##             : The maximum number of bots to return in the response that the request will return. The default is 10.
  section = newJObject()
  var valid_613569 = query.getOrDefault("nextToken")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "nextToken", valid_613569
  var valid_613570 = query.getOrDefault("nameContains")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "nameContains", valid_613570
  var valid_613571 = query.getOrDefault("maxResults")
  valid_613571 = validateParameter(valid_613571, JInt, required = false, default = nil)
  if valid_613571 != nil:
    section.add "maxResults", valid_613571
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613572 = header.getOrDefault("X-Amz-Signature")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "X-Amz-Signature", valid_613572
  var valid_613573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-Content-Sha256", valid_613573
  var valid_613574 = header.getOrDefault("X-Amz-Date")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-Date", valid_613574
  var valid_613575 = header.getOrDefault("X-Amz-Credential")
  valid_613575 = validateParameter(valid_613575, JString, required = false,
                                 default = nil)
  if valid_613575 != nil:
    section.add "X-Amz-Credential", valid_613575
  var valid_613576 = header.getOrDefault("X-Amz-Security-Token")
  valid_613576 = validateParameter(valid_613576, JString, required = false,
                                 default = nil)
  if valid_613576 != nil:
    section.add "X-Amz-Security-Token", valid_613576
  var valid_613577 = header.getOrDefault("X-Amz-Algorithm")
  valid_613577 = validateParameter(valid_613577, JString, required = false,
                                 default = nil)
  if valid_613577 != nil:
    section.add "X-Amz-Algorithm", valid_613577
  var valid_613578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613578 = validateParameter(valid_613578, JString, required = false,
                                 default = nil)
  if valid_613578 != nil:
    section.add "X-Amz-SignedHeaders", valid_613578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613579: Call_GetBots_613566; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns bot information as follows: </p> <ul> <li> <p>If you provide the <code>nameContains</code> field, the response includes information for the <code>$LATEST</code> version of all bots whose name contains the specified string.</p> </li> <li> <p>If you don't specify the <code>nameContains</code> field, the operation returns information about the <code>$LATEST</code> version of all of your bots.</p> </li> </ul> <p>This operation requires permission for the <code>lex:GetBots</code> action.</p>
  ## 
  let valid = call_613579.validator(path, query, header, formData, body)
  let scheme = call_613579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613579.url(scheme.get, call_613579.host, call_613579.base,
                         call_613579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613579, url, valid)

proc call*(call_613580: Call_GetBots_613566; nextToken: string = "";
          nameContains: string = ""; maxResults: int = 0): Recallable =
  ## getBots
  ## <p>Returns bot information as follows: </p> <ul> <li> <p>If you provide the <code>nameContains</code> field, the response includes information for the <code>$LATEST</code> version of all bots whose name contains the specified string.</p> </li> <li> <p>If you don't specify the <code>nameContains</code> field, the operation returns information about the <code>$LATEST</code> version of all of your bots.</p> </li> </ul> <p>This operation requires permission for the <code>lex:GetBots</code> action.</p>
  ##   nextToken: string
  ##            : A pagination token that fetches the next page of bots. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of bots, specify the pagination token in the next request. 
  ##   nameContains: string
  ##               : Substring to match in bot names. A bot will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  ##   maxResults: int
  ##             : The maximum number of bots to return in the response that the request will return. The default is 10.
  var query_613581 = newJObject()
  add(query_613581, "nextToken", newJString(nextToken))
  add(query_613581, "nameContains", newJString(nameContains))
  add(query_613581, "maxResults", newJInt(maxResults))
  result = call_613580.call(nil, query_613581, nil, nil, nil)

var getBots* = Call_GetBots_613566(name: "getBots", meth: HttpMethod.HttpGet,
                                host: "models.lex.amazonaws.com", route: "/bots/",
                                validator: validate_GetBots_613567, base: "/",
                                url: url_GetBots_613568,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBuiltinIntent_613582 = ref object of OpenApiRestCall_612659
proc url_GetBuiltinIntent_613584(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBuiltinIntent_613583(path: JsonNode; query: JsonNode;
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
  var valid_613585 = path.getOrDefault("signature")
  valid_613585 = validateParameter(valid_613585, JString, required = true,
                                 default = nil)
  if valid_613585 != nil:
    section.add "signature", valid_613585
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613586 = header.getOrDefault("X-Amz-Signature")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-Signature", valid_613586
  var valid_613587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-Content-Sha256", valid_613587
  var valid_613588 = header.getOrDefault("X-Amz-Date")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "X-Amz-Date", valid_613588
  var valid_613589 = header.getOrDefault("X-Amz-Credential")
  valid_613589 = validateParameter(valid_613589, JString, required = false,
                                 default = nil)
  if valid_613589 != nil:
    section.add "X-Amz-Credential", valid_613589
  var valid_613590 = header.getOrDefault("X-Amz-Security-Token")
  valid_613590 = validateParameter(valid_613590, JString, required = false,
                                 default = nil)
  if valid_613590 != nil:
    section.add "X-Amz-Security-Token", valid_613590
  var valid_613591 = header.getOrDefault("X-Amz-Algorithm")
  valid_613591 = validateParameter(valid_613591, JString, required = false,
                                 default = nil)
  if valid_613591 != nil:
    section.add "X-Amz-Algorithm", valid_613591
  var valid_613592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613592 = validateParameter(valid_613592, JString, required = false,
                                 default = nil)
  if valid_613592 != nil:
    section.add "X-Amz-SignedHeaders", valid_613592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613593: Call_GetBuiltinIntent_613582; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a built-in intent.</p> <p>This operation requires permission for the <code>lex:GetBuiltinIntent</code> action.</p>
  ## 
  let valid = call_613593.validator(path, query, header, formData, body)
  let scheme = call_613593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613593.url(scheme.get, call_613593.host, call_613593.base,
                         call_613593.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613593, url, valid)

proc call*(call_613594: Call_GetBuiltinIntent_613582; signature: string): Recallable =
  ## getBuiltinIntent
  ## <p>Returns information about a built-in intent.</p> <p>This operation requires permission for the <code>lex:GetBuiltinIntent</code> action.</p>
  ##   signature: string (required)
  ##            : The unique identifier for a built-in intent. To find the signature for an intent, see <a 
  ## href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/standard-intents">Standard Built-in Intents</a> in the <i>Alexa Skills Kit</i>.
  var path_613595 = newJObject()
  add(path_613595, "signature", newJString(signature))
  result = call_613594.call(path_613595, nil, nil, nil, nil)

var getBuiltinIntent* = Call_GetBuiltinIntent_613582(name: "getBuiltinIntent",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/builtins/intents/{signature}", validator: validate_GetBuiltinIntent_613583,
    base: "/", url: url_GetBuiltinIntent_613584,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBuiltinIntents_613596 = ref object of OpenApiRestCall_612659
proc url_GetBuiltinIntents_613598(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBuiltinIntents_613597(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Gets a list of built-in intents that meet the specified criteria.</p> <p>This operation requires permission for the <code>lex:GetBuiltinIntents</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A pagination token that fetches the next page of intents. If this API call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of intents, use the pagination token in the next request.
  ##   locale: JString
  ##         : A list of locales that the intent supports.
  ##   signatureContains: JString
  ##                    : Substring to match in built-in intent signatures. An intent will be returned if any part of its signature matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz." To find the signature for an intent, see <a 
  ## href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/standard-intents">Standard Built-in Intents</a> in the <i>Alexa Skills Kit</i>.
  ##   maxResults: JInt
  ##             : The maximum number of intents to return in the response. The default is 10.
  section = newJObject()
  var valid_613599 = query.getOrDefault("nextToken")
  valid_613599 = validateParameter(valid_613599, JString, required = false,
                                 default = nil)
  if valid_613599 != nil:
    section.add "nextToken", valid_613599
  var valid_613613 = query.getOrDefault("locale")
  valid_613613 = validateParameter(valid_613613, JString, required = false,
                                 default = newJString("en-US"))
  if valid_613613 != nil:
    section.add "locale", valid_613613
  var valid_613614 = query.getOrDefault("signatureContains")
  valid_613614 = validateParameter(valid_613614, JString, required = false,
                                 default = nil)
  if valid_613614 != nil:
    section.add "signatureContains", valid_613614
  var valid_613615 = query.getOrDefault("maxResults")
  valid_613615 = validateParameter(valid_613615, JInt, required = false, default = nil)
  if valid_613615 != nil:
    section.add "maxResults", valid_613615
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613616 = header.getOrDefault("X-Amz-Signature")
  valid_613616 = validateParameter(valid_613616, JString, required = false,
                                 default = nil)
  if valid_613616 != nil:
    section.add "X-Amz-Signature", valid_613616
  var valid_613617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "X-Amz-Content-Sha256", valid_613617
  var valid_613618 = header.getOrDefault("X-Amz-Date")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "X-Amz-Date", valid_613618
  var valid_613619 = header.getOrDefault("X-Amz-Credential")
  valid_613619 = validateParameter(valid_613619, JString, required = false,
                                 default = nil)
  if valid_613619 != nil:
    section.add "X-Amz-Credential", valid_613619
  var valid_613620 = header.getOrDefault("X-Amz-Security-Token")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "X-Amz-Security-Token", valid_613620
  var valid_613621 = header.getOrDefault("X-Amz-Algorithm")
  valid_613621 = validateParameter(valid_613621, JString, required = false,
                                 default = nil)
  if valid_613621 != nil:
    section.add "X-Amz-Algorithm", valid_613621
  var valid_613622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613622 = validateParameter(valid_613622, JString, required = false,
                                 default = nil)
  if valid_613622 != nil:
    section.add "X-Amz-SignedHeaders", valid_613622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613623: Call_GetBuiltinIntents_613596; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of built-in intents that meet the specified criteria.</p> <p>This operation requires permission for the <code>lex:GetBuiltinIntents</code> action.</p>
  ## 
  let valid = call_613623.validator(path, query, header, formData, body)
  let scheme = call_613623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613623.url(scheme.get, call_613623.host, call_613623.base,
                         call_613623.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613623, url, valid)

proc call*(call_613624: Call_GetBuiltinIntents_613596; nextToken: string = "";
          locale: string = "en-US"; signatureContains: string = ""; maxResults: int = 0): Recallable =
  ## getBuiltinIntents
  ## <p>Gets a list of built-in intents that meet the specified criteria.</p> <p>This operation requires permission for the <code>lex:GetBuiltinIntents</code> action.</p>
  ##   nextToken: string
  ##            : A pagination token that fetches the next page of intents. If this API call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of intents, use the pagination token in the next request.
  ##   locale: string
  ##         : A list of locales that the intent supports.
  ##   signatureContains: string
  ##                    : Substring to match in built-in intent signatures. An intent will be returned if any part of its signature matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz." To find the signature for an intent, see <a 
  ## href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/standard-intents">Standard Built-in Intents</a> in the <i>Alexa Skills Kit</i>.
  ##   maxResults: int
  ##             : The maximum number of intents to return in the response. The default is 10.
  var query_613625 = newJObject()
  add(query_613625, "nextToken", newJString(nextToken))
  add(query_613625, "locale", newJString(locale))
  add(query_613625, "signatureContains", newJString(signatureContains))
  add(query_613625, "maxResults", newJInt(maxResults))
  result = call_613624.call(nil, query_613625, nil, nil, nil)

var getBuiltinIntents* = Call_GetBuiltinIntents_613596(name: "getBuiltinIntents",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/builtins/intents/", validator: validate_GetBuiltinIntents_613597,
    base: "/", url: url_GetBuiltinIntents_613598,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBuiltinSlotTypes_613626 = ref object of OpenApiRestCall_612659
proc url_GetBuiltinSlotTypes_613628(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBuiltinSlotTypes_613627(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Gets a list of built-in slot types that meet the specified criteria.</p> <p>For a list of built-in slot types, see <a href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/slot-type-reference">Slot Type Reference</a> in the <i>Alexa Skills Kit</i>.</p> <p>This operation requires permission for the <code>lex:GetBuiltInSlotTypes</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A pagination token that fetches the next page of slot types. If the response to this API call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of slot types, specify the pagination token in the next request.
  ##   locale: JString
  ##         : A list of locales that the slot type supports.
  ##   signatureContains: JString
  ##                    : Substring to match in built-in slot type signatures. A slot type will be returned if any part of its signature matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  ##   maxResults: JInt
  ##             : The maximum number of slot types to return in the response. The default is 10.
  section = newJObject()
  var valid_613629 = query.getOrDefault("nextToken")
  valid_613629 = validateParameter(valid_613629, JString, required = false,
                                 default = nil)
  if valid_613629 != nil:
    section.add "nextToken", valid_613629
  var valid_613630 = query.getOrDefault("locale")
  valid_613630 = validateParameter(valid_613630, JString, required = false,
                                 default = newJString("en-US"))
  if valid_613630 != nil:
    section.add "locale", valid_613630
  var valid_613631 = query.getOrDefault("signatureContains")
  valid_613631 = validateParameter(valid_613631, JString, required = false,
                                 default = nil)
  if valid_613631 != nil:
    section.add "signatureContains", valid_613631
  var valid_613632 = query.getOrDefault("maxResults")
  valid_613632 = validateParameter(valid_613632, JInt, required = false, default = nil)
  if valid_613632 != nil:
    section.add "maxResults", valid_613632
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613633 = header.getOrDefault("X-Amz-Signature")
  valid_613633 = validateParameter(valid_613633, JString, required = false,
                                 default = nil)
  if valid_613633 != nil:
    section.add "X-Amz-Signature", valid_613633
  var valid_613634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613634 = validateParameter(valid_613634, JString, required = false,
                                 default = nil)
  if valid_613634 != nil:
    section.add "X-Amz-Content-Sha256", valid_613634
  var valid_613635 = header.getOrDefault("X-Amz-Date")
  valid_613635 = validateParameter(valid_613635, JString, required = false,
                                 default = nil)
  if valid_613635 != nil:
    section.add "X-Amz-Date", valid_613635
  var valid_613636 = header.getOrDefault("X-Amz-Credential")
  valid_613636 = validateParameter(valid_613636, JString, required = false,
                                 default = nil)
  if valid_613636 != nil:
    section.add "X-Amz-Credential", valid_613636
  var valid_613637 = header.getOrDefault("X-Amz-Security-Token")
  valid_613637 = validateParameter(valid_613637, JString, required = false,
                                 default = nil)
  if valid_613637 != nil:
    section.add "X-Amz-Security-Token", valid_613637
  var valid_613638 = header.getOrDefault("X-Amz-Algorithm")
  valid_613638 = validateParameter(valid_613638, JString, required = false,
                                 default = nil)
  if valid_613638 != nil:
    section.add "X-Amz-Algorithm", valid_613638
  var valid_613639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613639 = validateParameter(valid_613639, JString, required = false,
                                 default = nil)
  if valid_613639 != nil:
    section.add "X-Amz-SignedHeaders", valid_613639
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613640: Call_GetBuiltinSlotTypes_613626; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of built-in slot types that meet the specified criteria.</p> <p>For a list of built-in slot types, see <a href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/slot-type-reference">Slot Type Reference</a> in the <i>Alexa Skills Kit</i>.</p> <p>This operation requires permission for the <code>lex:GetBuiltInSlotTypes</code> action.</p>
  ## 
  let valid = call_613640.validator(path, query, header, formData, body)
  let scheme = call_613640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613640.url(scheme.get, call_613640.host, call_613640.base,
                         call_613640.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613640, url, valid)

proc call*(call_613641: Call_GetBuiltinSlotTypes_613626; nextToken: string = "";
          locale: string = "en-US"; signatureContains: string = ""; maxResults: int = 0): Recallable =
  ## getBuiltinSlotTypes
  ## <p>Gets a list of built-in slot types that meet the specified criteria.</p> <p>For a list of built-in slot types, see <a href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/slot-type-reference">Slot Type Reference</a> in the <i>Alexa Skills Kit</i>.</p> <p>This operation requires permission for the <code>lex:GetBuiltInSlotTypes</code> action.</p>
  ##   nextToken: string
  ##            : A pagination token that fetches the next page of slot types. If the response to this API call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of slot types, specify the pagination token in the next request.
  ##   locale: string
  ##         : A list of locales that the slot type supports.
  ##   signatureContains: string
  ##                    : Substring to match in built-in slot type signatures. A slot type will be returned if any part of its signature matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  ##   maxResults: int
  ##             : The maximum number of slot types to return in the response. The default is 10.
  var query_613642 = newJObject()
  add(query_613642, "nextToken", newJString(nextToken))
  add(query_613642, "locale", newJString(locale))
  add(query_613642, "signatureContains", newJString(signatureContains))
  add(query_613642, "maxResults", newJInt(maxResults))
  result = call_613641.call(nil, query_613642, nil, nil, nil)

var getBuiltinSlotTypes* = Call_GetBuiltinSlotTypes_613626(
    name: "getBuiltinSlotTypes", meth: HttpMethod.HttpGet,
    host: "models.lex.amazonaws.com", route: "/builtins/slottypes/",
    validator: validate_GetBuiltinSlotTypes_613627, base: "/",
    url: url_GetBuiltinSlotTypes_613628, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExport_613643 = ref object of OpenApiRestCall_612659
proc url_GetExport_613645(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetExport_613644(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Exports the contents of a Amazon Lex resource in a specified format. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   name: JString (required)
  ##       : The name of the bot to export.
  ##   version: JString (required)
  ##          : The version of the bot to export.
  ##   resourceType: JString (required)
  ##               : The type of resource to export. 
  ##   exportType: JString (required)
  ##             : The format of the exported data.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `name` field"
  var valid_613646 = query.getOrDefault("name")
  valid_613646 = validateParameter(valid_613646, JString, required = true,
                                 default = nil)
  if valid_613646 != nil:
    section.add "name", valid_613646
  var valid_613647 = query.getOrDefault("version")
  valid_613647 = validateParameter(valid_613647, JString, required = true,
                                 default = nil)
  if valid_613647 != nil:
    section.add "version", valid_613647
  var valid_613648 = query.getOrDefault("resourceType")
  valid_613648 = validateParameter(valid_613648, JString, required = true,
                                 default = newJString("BOT"))
  if valid_613648 != nil:
    section.add "resourceType", valid_613648
  var valid_613649 = query.getOrDefault("exportType")
  valid_613649 = validateParameter(valid_613649, JString, required = true,
                                 default = newJString("ALEXA_SKILLS_KIT"))
  if valid_613649 != nil:
    section.add "exportType", valid_613649
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613650 = header.getOrDefault("X-Amz-Signature")
  valid_613650 = validateParameter(valid_613650, JString, required = false,
                                 default = nil)
  if valid_613650 != nil:
    section.add "X-Amz-Signature", valid_613650
  var valid_613651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613651 = validateParameter(valid_613651, JString, required = false,
                                 default = nil)
  if valid_613651 != nil:
    section.add "X-Amz-Content-Sha256", valid_613651
  var valid_613652 = header.getOrDefault("X-Amz-Date")
  valid_613652 = validateParameter(valid_613652, JString, required = false,
                                 default = nil)
  if valid_613652 != nil:
    section.add "X-Amz-Date", valid_613652
  var valid_613653 = header.getOrDefault("X-Amz-Credential")
  valid_613653 = validateParameter(valid_613653, JString, required = false,
                                 default = nil)
  if valid_613653 != nil:
    section.add "X-Amz-Credential", valid_613653
  var valid_613654 = header.getOrDefault("X-Amz-Security-Token")
  valid_613654 = validateParameter(valid_613654, JString, required = false,
                                 default = nil)
  if valid_613654 != nil:
    section.add "X-Amz-Security-Token", valid_613654
  var valid_613655 = header.getOrDefault("X-Amz-Algorithm")
  valid_613655 = validateParameter(valid_613655, JString, required = false,
                                 default = nil)
  if valid_613655 != nil:
    section.add "X-Amz-Algorithm", valid_613655
  var valid_613656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613656 = validateParameter(valid_613656, JString, required = false,
                                 default = nil)
  if valid_613656 != nil:
    section.add "X-Amz-SignedHeaders", valid_613656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613657: Call_GetExport_613643; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Exports the contents of a Amazon Lex resource in a specified format. 
  ## 
  let valid = call_613657.validator(path, query, header, formData, body)
  let scheme = call_613657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613657.url(scheme.get, call_613657.host, call_613657.base,
                         call_613657.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613657, url, valid)

proc call*(call_613658: Call_GetExport_613643; name: string; version: string;
          resourceType: string = "BOT"; exportType: string = "ALEXA_SKILLS_KIT"): Recallable =
  ## getExport
  ## Exports the contents of a Amazon Lex resource in a specified format. 
  ##   name: string (required)
  ##       : The name of the bot to export.
  ##   version: string (required)
  ##          : The version of the bot to export.
  ##   resourceType: string (required)
  ##               : The type of resource to export. 
  ##   exportType: string (required)
  ##             : The format of the exported data.
  var query_613659 = newJObject()
  add(query_613659, "name", newJString(name))
  add(query_613659, "version", newJString(version))
  add(query_613659, "resourceType", newJString(resourceType))
  add(query_613659, "exportType", newJString(exportType))
  result = call_613658.call(nil, query_613659, nil, nil, nil)

var getExport* = Call_GetExport_613643(name: "getExport", meth: HttpMethod.HttpGet,
                                    host: "models.lex.amazonaws.com", route: "/exports/#name&version&resourceType&exportType",
                                    validator: validate_GetExport_613644,
                                    base: "/", url: url_GetExport_613645,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImport_613660 = ref object of OpenApiRestCall_612659
proc url_GetImport_613662(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetImport_613661(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613663 = path.getOrDefault("importId")
  valid_613663 = validateParameter(valid_613663, JString, required = true,
                                 default = nil)
  if valid_613663 != nil:
    section.add "importId", valid_613663
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613664 = header.getOrDefault("X-Amz-Signature")
  valid_613664 = validateParameter(valid_613664, JString, required = false,
                                 default = nil)
  if valid_613664 != nil:
    section.add "X-Amz-Signature", valid_613664
  var valid_613665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613665 = validateParameter(valid_613665, JString, required = false,
                                 default = nil)
  if valid_613665 != nil:
    section.add "X-Amz-Content-Sha256", valid_613665
  var valid_613666 = header.getOrDefault("X-Amz-Date")
  valid_613666 = validateParameter(valid_613666, JString, required = false,
                                 default = nil)
  if valid_613666 != nil:
    section.add "X-Amz-Date", valid_613666
  var valid_613667 = header.getOrDefault("X-Amz-Credential")
  valid_613667 = validateParameter(valid_613667, JString, required = false,
                                 default = nil)
  if valid_613667 != nil:
    section.add "X-Amz-Credential", valid_613667
  var valid_613668 = header.getOrDefault("X-Amz-Security-Token")
  valid_613668 = validateParameter(valid_613668, JString, required = false,
                                 default = nil)
  if valid_613668 != nil:
    section.add "X-Amz-Security-Token", valid_613668
  var valid_613669 = header.getOrDefault("X-Amz-Algorithm")
  valid_613669 = validateParameter(valid_613669, JString, required = false,
                                 default = nil)
  if valid_613669 != nil:
    section.add "X-Amz-Algorithm", valid_613669
  var valid_613670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613670 = validateParameter(valid_613670, JString, required = false,
                                 default = nil)
  if valid_613670 != nil:
    section.add "X-Amz-SignedHeaders", valid_613670
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613671: Call_GetImport_613660; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about an import job started with the <code>StartImport</code> operation.
  ## 
  let valid = call_613671.validator(path, query, header, formData, body)
  let scheme = call_613671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613671.url(scheme.get, call_613671.host, call_613671.base,
                         call_613671.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613671, url, valid)

proc call*(call_613672: Call_GetImport_613660; importId: string): Recallable =
  ## getImport
  ## Gets information about an import job started with the <code>StartImport</code> operation.
  ##   importId: string (required)
  ##           : The identifier of the import job information to return.
  var path_613673 = newJObject()
  add(path_613673, "importId", newJString(importId))
  result = call_613672.call(path_613673, nil, nil, nil, nil)

var getImport* = Call_GetImport_613660(name: "getImport", meth: HttpMethod.HttpGet,
                                    host: "models.lex.amazonaws.com",
                                    route: "/imports/{importId}",
                                    validator: validate_GetImport_613661,
                                    base: "/", url: url_GetImport_613662,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntentVersions_613674 = ref object of OpenApiRestCall_612659
proc url_GetIntentVersions_613676(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIntentVersions_613675(path: JsonNode; query: JsonNode;
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
  var valid_613677 = path.getOrDefault("name")
  valid_613677 = validateParameter(valid_613677, JString, required = true,
                                 default = nil)
  if valid_613677 != nil:
    section.add "name", valid_613677
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A pagination token for fetching the next page of intent versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  ##   maxResults: JInt
  ##             : The maximum number of intent versions to return in the response. The default is 10.
  section = newJObject()
  var valid_613678 = query.getOrDefault("nextToken")
  valid_613678 = validateParameter(valid_613678, JString, required = false,
                                 default = nil)
  if valid_613678 != nil:
    section.add "nextToken", valid_613678
  var valid_613679 = query.getOrDefault("maxResults")
  valid_613679 = validateParameter(valid_613679, JInt, required = false, default = nil)
  if valid_613679 != nil:
    section.add "maxResults", valid_613679
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613680 = header.getOrDefault("X-Amz-Signature")
  valid_613680 = validateParameter(valid_613680, JString, required = false,
                                 default = nil)
  if valid_613680 != nil:
    section.add "X-Amz-Signature", valid_613680
  var valid_613681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613681 = validateParameter(valid_613681, JString, required = false,
                                 default = nil)
  if valid_613681 != nil:
    section.add "X-Amz-Content-Sha256", valid_613681
  var valid_613682 = header.getOrDefault("X-Amz-Date")
  valid_613682 = validateParameter(valid_613682, JString, required = false,
                                 default = nil)
  if valid_613682 != nil:
    section.add "X-Amz-Date", valid_613682
  var valid_613683 = header.getOrDefault("X-Amz-Credential")
  valid_613683 = validateParameter(valid_613683, JString, required = false,
                                 default = nil)
  if valid_613683 != nil:
    section.add "X-Amz-Credential", valid_613683
  var valid_613684 = header.getOrDefault("X-Amz-Security-Token")
  valid_613684 = validateParameter(valid_613684, JString, required = false,
                                 default = nil)
  if valid_613684 != nil:
    section.add "X-Amz-Security-Token", valid_613684
  var valid_613685 = header.getOrDefault("X-Amz-Algorithm")
  valid_613685 = validateParameter(valid_613685, JString, required = false,
                                 default = nil)
  if valid_613685 != nil:
    section.add "X-Amz-Algorithm", valid_613685
  var valid_613686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613686 = validateParameter(valid_613686, JString, required = false,
                                 default = nil)
  if valid_613686 != nil:
    section.add "X-Amz-SignedHeaders", valid_613686
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613687: Call_GetIntentVersions_613674; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about all of the versions of an intent.</p> <p>The <code>GetIntentVersions</code> operation returns an <code>IntentMetadata</code> object for each version of an intent. For example, if an intent has three numbered versions, the <code>GetIntentVersions</code> operation returns four <code>IntentMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetIntentVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetIntentVersions</code> action.</p>
  ## 
  let valid = call_613687.validator(path, query, header, formData, body)
  let scheme = call_613687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613687.url(scheme.get, call_613687.host, call_613687.base,
                         call_613687.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613687, url, valid)

proc call*(call_613688: Call_GetIntentVersions_613674; name: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## getIntentVersions
  ## <p>Gets information about all of the versions of an intent.</p> <p>The <code>GetIntentVersions</code> operation returns an <code>IntentMetadata</code> object for each version of an intent. For example, if an intent has three numbered versions, the <code>GetIntentVersions</code> operation returns four <code>IntentMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetIntentVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetIntentVersions</code> action.</p>
  ##   nextToken: string
  ##            : A pagination token for fetching the next page of intent versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  ##   name: string (required)
  ##       : The name of the intent for which versions should be returned.
  ##   maxResults: int
  ##             : The maximum number of intent versions to return in the response. The default is 10.
  var path_613689 = newJObject()
  var query_613690 = newJObject()
  add(query_613690, "nextToken", newJString(nextToken))
  add(path_613689, "name", newJString(name))
  add(query_613690, "maxResults", newJInt(maxResults))
  result = call_613688.call(path_613689, query_613690, nil, nil, nil)

var getIntentVersions* = Call_GetIntentVersions_613674(name: "getIntentVersions",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/intents/{name}/versions/", validator: validate_GetIntentVersions_613675,
    base: "/", url: url_GetIntentVersions_613676,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntents_613691 = ref object of OpenApiRestCall_612659
proc url_GetIntents_613693(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetIntents_613692(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns intent information as follows: </p> <ul> <li> <p>If you specify the <code>nameContains</code> field, returns the <code>$LATEST</code> version of all intents that contain the specified string.</p> </li> <li> <p> If you don't specify the <code>nameContains</code> field, returns information about the <code>$LATEST</code> version of all intents. </p> </li> </ul> <p> The operation requires permission for the <code>lex:GetIntents</code> action. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A pagination token that fetches the next page of intents. If the response to this API call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of intents, specify the pagination token in the next request. 
  ##   nameContains: JString
  ##               : Substring to match in intent names. An intent will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  ##   maxResults: JInt
  ##             : The maximum number of intents to return in the response. The default is 10.
  section = newJObject()
  var valid_613694 = query.getOrDefault("nextToken")
  valid_613694 = validateParameter(valid_613694, JString, required = false,
                                 default = nil)
  if valid_613694 != nil:
    section.add "nextToken", valid_613694
  var valid_613695 = query.getOrDefault("nameContains")
  valid_613695 = validateParameter(valid_613695, JString, required = false,
                                 default = nil)
  if valid_613695 != nil:
    section.add "nameContains", valid_613695
  var valid_613696 = query.getOrDefault("maxResults")
  valid_613696 = validateParameter(valid_613696, JInt, required = false, default = nil)
  if valid_613696 != nil:
    section.add "maxResults", valid_613696
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613697 = header.getOrDefault("X-Amz-Signature")
  valid_613697 = validateParameter(valid_613697, JString, required = false,
                                 default = nil)
  if valid_613697 != nil:
    section.add "X-Amz-Signature", valid_613697
  var valid_613698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613698 = validateParameter(valid_613698, JString, required = false,
                                 default = nil)
  if valid_613698 != nil:
    section.add "X-Amz-Content-Sha256", valid_613698
  var valid_613699 = header.getOrDefault("X-Amz-Date")
  valid_613699 = validateParameter(valid_613699, JString, required = false,
                                 default = nil)
  if valid_613699 != nil:
    section.add "X-Amz-Date", valid_613699
  var valid_613700 = header.getOrDefault("X-Amz-Credential")
  valid_613700 = validateParameter(valid_613700, JString, required = false,
                                 default = nil)
  if valid_613700 != nil:
    section.add "X-Amz-Credential", valid_613700
  var valid_613701 = header.getOrDefault("X-Amz-Security-Token")
  valid_613701 = validateParameter(valid_613701, JString, required = false,
                                 default = nil)
  if valid_613701 != nil:
    section.add "X-Amz-Security-Token", valid_613701
  var valid_613702 = header.getOrDefault("X-Amz-Algorithm")
  valid_613702 = validateParameter(valid_613702, JString, required = false,
                                 default = nil)
  if valid_613702 != nil:
    section.add "X-Amz-Algorithm", valid_613702
  var valid_613703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613703 = validateParameter(valid_613703, JString, required = false,
                                 default = nil)
  if valid_613703 != nil:
    section.add "X-Amz-SignedHeaders", valid_613703
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613704: Call_GetIntents_613691; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns intent information as follows: </p> <ul> <li> <p>If you specify the <code>nameContains</code> field, returns the <code>$LATEST</code> version of all intents that contain the specified string.</p> </li> <li> <p> If you don't specify the <code>nameContains</code> field, returns information about the <code>$LATEST</code> version of all intents. </p> </li> </ul> <p> The operation requires permission for the <code>lex:GetIntents</code> action. </p>
  ## 
  let valid = call_613704.validator(path, query, header, formData, body)
  let scheme = call_613704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613704.url(scheme.get, call_613704.host, call_613704.base,
                         call_613704.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613704, url, valid)

proc call*(call_613705: Call_GetIntents_613691; nextToken: string = "";
          nameContains: string = ""; maxResults: int = 0): Recallable =
  ## getIntents
  ## <p>Returns intent information as follows: </p> <ul> <li> <p>If you specify the <code>nameContains</code> field, returns the <code>$LATEST</code> version of all intents that contain the specified string.</p> </li> <li> <p> If you don't specify the <code>nameContains</code> field, returns information about the <code>$LATEST</code> version of all intents. </p> </li> </ul> <p> The operation requires permission for the <code>lex:GetIntents</code> action. </p>
  ##   nextToken: string
  ##            : A pagination token that fetches the next page of intents. If the response to this API call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of intents, specify the pagination token in the next request. 
  ##   nameContains: string
  ##               : Substring to match in intent names. An intent will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  ##   maxResults: int
  ##             : The maximum number of intents to return in the response. The default is 10.
  var query_613706 = newJObject()
  add(query_613706, "nextToken", newJString(nextToken))
  add(query_613706, "nameContains", newJString(nameContains))
  add(query_613706, "maxResults", newJInt(maxResults))
  result = call_613705.call(nil, query_613706, nil, nil, nil)

var getIntents* = Call_GetIntents_613691(name: "getIntents",
                                      meth: HttpMethod.HttpGet,
                                      host: "models.lex.amazonaws.com",
                                      route: "/intents/",
                                      validator: validate_GetIntents_613692,
                                      base: "/", url: url_GetIntents_613693,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSlotType_613707 = ref object of OpenApiRestCall_612659
proc url_GetSlotType_613709(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSlotType_613708(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about a specific version of a slot type. In addition to specifying the slot type name, you must specify the slot type version.</p> <p>This operation requires permissions for the <code>lex:GetSlotType</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   version: JString (required)
  ##          : The version of the slot type. 
  ##   name: JString (required)
  ##       : The name of the slot type. The name is case sensitive. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `version` field"
  var valid_613710 = path.getOrDefault("version")
  valid_613710 = validateParameter(valid_613710, JString, required = true,
                                 default = nil)
  if valid_613710 != nil:
    section.add "version", valid_613710
  var valid_613711 = path.getOrDefault("name")
  valid_613711 = validateParameter(valid_613711, JString, required = true,
                                 default = nil)
  if valid_613711 != nil:
    section.add "name", valid_613711
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613712 = header.getOrDefault("X-Amz-Signature")
  valid_613712 = validateParameter(valid_613712, JString, required = false,
                                 default = nil)
  if valid_613712 != nil:
    section.add "X-Amz-Signature", valid_613712
  var valid_613713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613713 = validateParameter(valid_613713, JString, required = false,
                                 default = nil)
  if valid_613713 != nil:
    section.add "X-Amz-Content-Sha256", valid_613713
  var valid_613714 = header.getOrDefault("X-Amz-Date")
  valid_613714 = validateParameter(valid_613714, JString, required = false,
                                 default = nil)
  if valid_613714 != nil:
    section.add "X-Amz-Date", valid_613714
  var valid_613715 = header.getOrDefault("X-Amz-Credential")
  valid_613715 = validateParameter(valid_613715, JString, required = false,
                                 default = nil)
  if valid_613715 != nil:
    section.add "X-Amz-Credential", valid_613715
  var valid_613716 = header.getOrDefault("X-Amz-Security-Token")
  valid_613716 = validateParameter(valid_613716, JString, required = false,
                                 default = nil)
  if valid_613716 != nil:
    section.add "X-Amz-Security-Token", valid_613716
  var valid_613717 = header.getOrDefault("X-Amz-Algorithm")
  valid_613717 = validateParameter(valid_613717, JString, required = false,
                                 default = nil)
  if valid_613717 != nil:
    section.add "X-Amz-Algorithm", valid_613717
  var valid_613718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613718 = validateParameter(valid_613718, JString, required = false,
                                 default = nil)
  if valid_613718 != nil:
    section.add "X-Amz-SignedHeaders", valid_613718
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613719: Call_GetSlotType_613707; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a specific version of a slot type. In addition to specifying the slot type name, you must specify the slot type version.</p> <p>This operation requires permissions for the <code>lex:GetSlotType</code> action.</p>
  ## 
  let valid = call_613719.validator(path, query, header, formData, body)
  let scheme = call_613719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613719.url(scheme.get, call_613719.host, call_613719.base,
                         call_613719.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613719, url, valid)

proc call*(call_613720: Call_GetSlotType_613707; version: string; name: string): Recallable =
  ## getSlotType
  ## <p>Returns information about a specific version of a slot type. In addition to specifying the slot type name, you must specify the slot type version.</p> <p>This operation requires permissions for the <code>lex:GetSlotType</code> action.</p>
  ##   version: string (required)
  ##          : The version of the slot type. 
  ##   name: string (required)
  ##       : The name of the slot type. The name is case sensitive. 
  var path_613721 = newJObject()
  add(path_613721, "version", newJString(version))
  add(path_613721, "name", newJString(name))
  result = call_613720.call(path_613721, nil, nil, nil, nil)

var getSlotType* = Call_GetSlotType_613707(name: "getSlotType",
                                        meth: HttpMethod.HttpGet,
                                        host: "models.lex.amazonaws.com", route: "/slottypes/{name}/versions/{version}",
                                        validator: validate_GetSlotType_613708,
                                        base: "/", url: url_GetSlotType_613709,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSlotTypeVersions_613722 = ref object of OpenApiRestCall_612659
proc url_GetSlotTypeVersions_613724(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSlotTypeVersions_613723(path: JsonNode; query: JsonNode;
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
  var valid_613725 = path.getOrDefault("name")
  valid_613725 = validateParameter(valid_613725, JString, required = true,
                                 default = nil)
  if valid_613725 != nil:
    section.add "name", valid_613725
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A pagination token for fetching the next page of slot type versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  ##   maxResults: JInt
  ##             : The maximum number of slot type versions to return in the response. The default is 10.
  section = newJObject()
  var valid_613726 = query.getOrDefault("nextToken")
  valid_613726 = validateParameter(valid_613726, JString, required = false,
                                 default = nil)
  if valid_613726 != nil:
    section.add "nextToken", valid_613726
  var valid_613727 = query.getOrDefault("maxResults")
  valid_613727 = validateParameter(valid_613727, JInt, required = false, default = nil)
  if valid_613727 != nil:
    section.add "maxResults", valid_613727
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613728 = header.getOrDefault("X-Amz-Signature")
  valid_613728 = validateParameter(valid_613728, JString, required = false,
                                 default = nil)
  if valid_613728 != nil:
    section.add "X-Amz-Signature", valid_613728
  var valid_613729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613729 = validateParameter(valid_613729, JString, required = false,
                                 default = nil)
  if valid_613729 != nil:
    section.add "X-Amz-Content-Sha256", valid_613729
  var valid_613730 = header.getOrDefault("X-Amz-Date")
  valid_613730 = validateParameter(valid_613730, JString, required = false,
                                 default = nil)
  if valid_613730 != nil:
    section.add "X-Amz-Date", valid_613730
  var valid_613731 = header.getOrDefault("X-Amz-Credential")
  valid_613731 = validateParameter(valid_613731, JString, required = false,
                                 default = nil)
  if valid_613731 != nil:
    section.add "X-Amz-Credential", valid_613731
  var valid_613732 = header.getOrDefault("X-Amz-Security-Token")
  valid_613732 = validateParameter(valid_613732, JString, required = false,
                                 default = nil)
  if valid_613732 != nil:
    section.add "X-Amz-Security-Token", valid_613732
  var valid_613733 = header.getOrDefault("X-Amz-Algorithm")
  valid_613733 = validateParameter(valid_613733, JString, required = false,
                                 default = nil)
  if valid_613733 != nil:
    section.add "X-Amz-Algorithm", valid_613733
  var valid_613734 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613734 = validateParameter(valid_613734, JString, required = false,
                                 default = nil)
  if valid_613734 != nil:
    section.add "X-Amz-SignedHeaders", valid_613734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613735: Call_GetSlotTypeVersions_613722; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about all versions of a slot type.</p> <p>The <code>GetSlotTypeVersions</code> operation returns a <code>SlotTypeMetadata</code> object for each version of a slot type. For example, if a slot type has three numbered versions, the <code>GetSlotTypeVersions</code> operation returns four <code>SlotTypeMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetSlotTypeVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetSlotTypeVersions</code> action.</p>
  ## 
  let valid = call_613735.validator(path, query, header, formData, body)
  let scheme = call_613735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613735.url(scheme.get, call_613735.host, call_613735.base,
                         call_613735.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613735, url, valid)

proc call*(call_613736: Call_GetSlotTypeVersions_613722; name: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## getSlotTypeVersions
  ## <p>Gets information about all versions of a slot type.</p> <p>The <code>GetSlotTypeVersions</code> operation returns a <code>SlotTypeMetadata</code> object for each version of a slot type. For example, if a slot type has three numbered versions, the <code>GetSlotTypeVersions</code> operation returns four <code>SlotTypeMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetSlotTypeVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetSlotTypeVersions</code> action.</p>
  ##   nextToken: string
  ##            : A pagination token for fetching the next page of slot type versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  ##   name: string (required)
  ##       : The name of the slot type for which versions should be returned.
  ##   maxResults: int
  ##             : The maximum number of slot type versions to return in the response. The default is 10.
  var path_613737 = newJObject()
  var query_613738 = newJObject()
  add(query_613738, "nextToken", newJString(nextToken))
  add(path_613737, "name", newJString(name))
  add(query_613738, "maxResults", newJInt(maxResults))
  result = call_613736.call(path_613737, query_613738, nil, nil, nil)

var getSlotTypeVersions* = Call_GetSlotTypeVersions_613722(
    name: "getSlotTypeVersions", meth: HttpMethod.HttpGet,
    host: "models.lex.amazonaws.com", route: "/slottypes/{name}/versions/",
    validator: validate_GetSlotTypeVersions_613723, base: "/",
    url: url_GetSlotTypeVersions_613724, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSlotTypes_613739 = ref object of OpenApiRestCall_612659
proc url_GetSlotTypes_613741(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSlotTypes_613740(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns slot type information as follows: </p> <ul> <li> <p>If you specify the <code>nameContains</code> field, returns the <code>$LATEST</code> version of all slot types that contain the specified string.</p> </li> <li> <p> If you don't specify the <code>nameContains</code> field, returns information about the <code>$LATEST</code> version of all slot types. </p> </li> </ul> <p> The operation requires permission for the <code>lex:GetSlotTypes</code> action. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A pagination token that fetches the next page of slot types. If the response to this API call is truncated, Amazon Lex returns a pagination token in the response. To fetch next page of slot types, specify the pagination token in the next request.
  ##   nameContains: JString
  ##               : Substring to match in slot type names. A slot type will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  ##   maxResults: JInt
  ##             : The maximum number of slot types to return in the response. The default is 10.
  section = newJObject()
  var valid_613742 = query.getOrDefault("nextToken")
  valid_613742 = validateParameter(valid_613742, JString, required = false,
                                 default = nil)
  if valid_613742 != nil:
    section.add "nextToken", valid_613742
  var valid_613743 = query.getOrDefault("nameContains")
  valid_613743 = validateParameter(valid_613743, JString, required = false,
                                 default = nil)
  if valid_613743 != nil:
    section.add "nameContains", valid_613743
  var valid_613744 = query.getOrDefault("maxResults")
  valid_613744 = validateParameter(valid_613744, JInt, required = false, default = nil)
  if valid_613744 != nil:
    section.add "maxResults", valid_613744
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613745 = header.getOrDefault("X-Amz-Signature")
  valid_613745 = validateParameter(valid_613745, JString, required = false,
                                 default = nil)
  if valid_613745 != nil:
    section.add "X-Amz-Signature", valid_613745
  var valid_613746 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613746 = validateParameter(valid_613746, JString, required = false,
                                 default = nil)
  if valid_613746 != nil:
    section.add "X-Amz-Content-Sha256", valid_613746
  var valid_613747 = header.getOrDefault("X-Amz-Date")
  valid_613747 = validateParameter(valid_613747, JString, required = false,
                                 default = nil)
  if valid_613747 != nil:
    section.add "X-Amz-Date", valid_613747
  var valid_613748 = header.getOrDefault("X-Amz-Credential")
  valid_613748 = validateParameter(valid_613748, JString, required = false,
                                 default = nil)
  if valid_613748 != nil:
    section.add "X-Amz-Credential", valid_613748
  var valid_613749 = header.getOrDefault("X-Amz-Security-Token")
  valid_613749 = validateParameter(valid_613749, JString, required = false,
                                 default = nil)
  if valid_613749 != nil:
    section.add "X-Amz-Security-Token", valid_613749
  var valid_613750 = header.getOrDefault("X-Amz-Algorithm")
  valid_613750 = validateParameter(valid_613750, JString, required = false,
                                 default = nil)
  if valid_613750 != nil:
    section.add "X-Amz-Algorithm", valid_613750
  var valid_613751 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613751 = validateParameter(valid_613751, JString, required = false,
                                 default = nil)
  if valid_613751 != nil:
    section.add "X-Amz-SignedHeaders", valid_613751
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613752: Call_GetSlotTypes_613739; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns slot type information as follows: </p> <ul> <li> <p>If you specify the <code>nameContains</code> field, returns the <code>$LATEST</code> version of all slot types that contain the specified string.</p> </li> <li> <p> If you don't specify the <code>nameContains</code> field, returns information about the <code>$LATEST</code> version of all slot types. </p> </li> </ul> <p> The operation requires permission for the <code>lex:GetSlotTypes</code> action. </p>
  ## 
  let valid = call_613752.validator(path, query, header, formData, body)
  let scheme = call_613752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613752.url(scheme.get, call_613752.host, call_613752.base,
                         call_613752.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613752, url, valid)

proc call*(call_613753: Call_GetSlotTypes_613739; nextToken: string = "";
          nameContains: string = ""; maxResults: int = 0): Recallable =
  ## getSlotTypes
  ## <p>Returns slot type information as follows: </p> <ul> <li> <p>If you specify the <code>nameContains</code> field, returns the <code>$LATEST</code> version of all slot types that contain the specified string.</p> </li> <li> <p> If you don't specify the <code>nameContains</code> field, returns information about the <code>$LATEST</code> version of all slot types. </p> </li> </ul> <p> The operation requires permission for the <code>lex:GetSlotTypes</code> action. </p>
  ##   nextToken: string
  ##            : A pagination token that fetches the next page of slot types. If the response to this API call is truncated, Amazon Lex returns a pagination token in the response. To fetch next page of slot types, specify the pagination token in the next request.
  ##   nameContains: string
  ##               : Substring to match in slot type names. A slot type will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  ##   maxResults: int
  ##             : The maximum number of slot types to return in the response. The default is 10.
  var query_613754 = newJObject()
  add(query_613754, "nextToken", newJString(nextToken))
  add(query_613754, "nameContains", newJString(nameContains))
  add(query_613754, "maxResults", newJInt(maxResults))
  result = call_613753.call(nil, query_613754, nil, nil, nil)

var getSlotTypes* = Call_GetSlotTypes_613739(name: "getSlotTypes",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/slottypes/", validator: validate_GetSlotTypes_613740, base: "/",
    url: url_GetSlotTypes_613741, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUtterancesView_613755 = ref object of OpenApiRestCall_612659
proc url_GetUtterancesView_613757(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetUtterancesView_613756(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Use the <code>GetUtterancesView</code> operation to get information about the utterances that your users have made to your bot. You can use this list to tune the utterances that your bot responds to.</p> <p>For example, say that you have created a bot to order flowers. After your users have used your bot for a while, use the <code>GetUtterancesView</code> operation to see the requests that they have made and whether they have been successful. You might find that the utterance "I want flowers" is not being recognized. You could add this utterance to the <code>OrderFlowers</code> intent so that your bot recognizes that utterance.</p> <p>After you publish a new version of a bot, you can get information about the old version and the new so that you can compare the performance across the two versions. </p> <p>Utterance statistics are generated once a day. Data is available for the last 15 days. You can request information for up to 5 versions of your bot in each request. Amazon Lex returns the most frequent utterances received by the bot in the last 15 days. The response contains information about a maximum of 100 utterances for each version.</p> <p>If you set <code>childDirected</code> field to true when you created your bot, or if you opted out of participating in improving Amazon Lex, utterances are not available.</p> <p>This operation requires permissions for the <code>lex:GetUtterancesView</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   botname: JString (required)
  ##          : The name of the bot for which utterance information should be returned.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `botname` field"
  var valid_613758 = path.getOrDefault("botname")
  valid_613758 = validateParameter(valid_613758, JString, required = true,
                                 default = nil)
  if valid_613758 != nil:
    section.add "botname", valid_613758
  result.add "path", section
  ## parameters in `query` object:
  ##   status_type: JString (required)
  ##              : To return utterances that were recognized and handled, use <code>Detected</code>. To return utterances that were not recognized, use <code>Missed</code>.
  ##   bot_versions: JArray (required)
  ##               : An array of bot versions for which utterance information should be returned. The limit is 5 versions per request.
  ##   view: JString (required)
  section = newJObject()
  var valid_613759 = query.getOrDefault("status_type")
  valid_613759 = validateParameter(valid_613759, JString, required = true,
                                 default = newJString("Detected"))
  if valid_613759 != nil:
    section.add "status_type", valid_613759
  var valid_613760 = query.getOrDefault("bot_versions")
  valid_613760 = validateParameter(valid_613760, JArray, required = true, default = nil)
  if valid_613760 != nil:
    section.add "bot_versions", valid_613760
  var valid_613761 = query.getOrDefault("view")
  valid_613761 = validateParameter(valid_613761, JString, required = true,
                                 default = newJString("aggregation"))
  if valid_613761 != nil:
    section.add "view", valid_613761
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613762 = header.getOrDefault("X-Amz-Signature")
  valid_613762 = validateParameter(valid_613762, JString, required = false,
                                 default = nil)
  if valid_613762 != nil:
    section.add "X-Amz-Signature", valid_613762
  var valid_613763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613763 = validateParameter(valid_613763, JString, required = false,
                                 default = nil)
  if valid_613763 != nil:
    section.add "X-Amz-Content-Sha256", valid_613763
  var valid_613764 = header.getOrDefault("X-Amz-Date")
  valid_613764 = validateParameter(valid_613764, JString, required = false,
                                 default = nil)
  if valid_613764 != nil:
    section.add "X-Amz-Date", valid_613764
  var valid_613765 = header.getOrDefault("X-Amz-Credential")
  valid_613765 = validateParameter(valid_613765, JString, required = false,
                                 default = nil)
  if valid_613765 != nil:
    section.add "X-Amz-Credential", valid_613765
  var valid_613766 = header.getOrDefault("X-Amz-Security-Token")
  valid_613766 = validateParameter(valid_613766, JString, required = false,
                                 default = nil)
  if valid_613766 != nil:
    section.add "X-Amz-Security-Token", valid_613766
  var valid_613767 = header.getOrDefault("X-Amz-Algorithm")
  valid_613767 = validateParameter(valid_613767, JString, required = false,
                                 default = nil)
  if valid_613767 != nil:
    section.add "X-Amz-Algorithm", valid_613767
  var valid_613768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613768 = validateParameter(valid_613768, JString, required = false,
                                 default = nil)
  if valid_613768 != nil:
    section.add "X-Amz-SignedHeaders", valid_613768
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613769: Call_GetUtterancesView_613755; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use the <code>GetUtterancesView</code> operation to get information about the utterances that your users have made to your bot. You can use this list to tune the utterances that your bot responds to.</p> <p>For example, say that you have created a bot to order flowers. After your users have used your bot for a while, use the <code>GetUtterancesView</code> operation to see the requests that they have made and whether they have been successful. You might find that the utterance "I want flowers" is not being recognized. You could add this utterance to the <code>OrderFlowers</code> intent so that your bot recognizes that utterance.</p> <p>After you publish a new version of a bot, you can get information about the old version and the new so that you can compare the performance across the two versions. </p> <p>Utterance statistics are generated once a day. Data is available for the last 15 days. You can request information for up to 5 versions of your bot in each request. Amazon Lex returns the most frequent utterances received by the bot in the last 15 days. The response contains information about a maximum of 100 utterances for each version.</p> <p>If you set <code>childDirected</code> field to true when you created your bot, or if you opted out of participating in improving Amazon Lex, utterances are not available.</p> <p>This operation requires permissions for the <code>lex:GetUtterancesView</code> action.</p>
  ## 
  let valid = call_613769.validator(path, query, header, formData, body)
  let scheme = call_613769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613769.url(scheme.get, call_613769.host, call_613769.base,
                         call_613769.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613769, url, valid)

proc call*(call_613770: Call_GetUtterancesView_613755; botname: string;
          botVersions: JsonNode; statusType: string = "Detected";
          view: string = "aggregation"): Recallable =
  ## getUtterancesView
  ## <p>Use the <code>GetUtterancesView</code> operation to get information about the utterances that your users have made to your bot. You can use this list to tune the utterances that your bot responds to.</p> <p>For example, say that you have created a bot to order flowers. After your users have used your bot for a while, use the <code>GetUtterancesView</code> operation to see the requests that they have made and whether they have been successful. You might find that the utterance "I want flowers" is not being recognized. You could add this utterance to the <code>OrderFlowers</code> intent so that your bot recognizes that utterance.</p> <p>After you publish a new version of a bot, you can get information about the old version and the new so that you can compare the performance across the two versions. </p> <p>Utterance statistics are generated once a day. Data is available for the last 15 days. You can request information for up to 5 versions of your bot in each request. Amazon Lex returns the most frequent utterances received by the bot in the last 15 days. The response contains information about a maximum of 100 utterances for each version.</p> <p>If you set <code>childDirected</code> field to true when you created your bot, or if you opted out of participating in improving Amazon Lex, utterances are not available.</p> <p>This operation requires permissions for the <code>lex:GetUtterancesView</code> action.</p>
  ##   statusType: string (required)
  ##             : To return utterances that were recognized and handled, use <code>Detected</code>. To return utterances that were not recognized, use <code>Missed</code>.
  ##   botname: string (required)
  ##          : The name of the bot for which utterance information should be returned.
  ##   botVersions: JArray (required)
  ##              : An array of bot versions for which utterance information should be returned. The limit is 5 versions per request.
  ##   view: string (required)
  var path_613771 = newJObject()
  var query_613772 = newJObject()
  add(query_613772, "status_type", newJString(statusType))
  add(path_613771, "botname", newJString(botname))
  if botVersions != nil:
    query_613772.add "bot_versions", botVersions
  add(query_613772, "view", newJString(view))
  result = call_613770.call(path_613771, query_613772, nil, nil, nil)

var getUtterancesView* = Call_GetUtterancesView_613755(name: "getUtterancesView",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com", route: "/bots/{botname}/utterances#view=aggregation&bot_versions&status_type",
    validator: validate_GetUtterancesView_613756, base: "/",
    url: url_GetUtterancesView_613757, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBot_613773 = ref object of OpenApiRestCall_612659
proc url_PutBot_613775(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutBot_613774(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an Amazon Lex conversational bot or replaces an existing bot. When you create or update a bot you are only required to specify a name, a locale, and whether the bot is directed toward children under age 13. You can use this to add intents later, or to remove intents from an existing bot. When you create a bot with the minimum information, the bot is created or updated but Amazon Lex returns the <code/> response <code>FAILED</code>. You can build the bot after you add one or more intents. For more information about Amazon Lex bots, see <a>how-it-works</a>. </p> <p>If you specify the name of an existing bot, the fields in the request replace the existing values in the <code>$LATEST</code> version of the bot. Amazon Lex removes any fields that you don't provide values for in the request, except for the <code>idleTTLInSeconds</code> and <code>privacySettings</code> fields, which are set to their default values. If you don't specify values for required fields, Amazon Lex throws an exception.</p> <p>This operation requires permissions for the <code>lex:PutBot</code> action. For more information, see <a>security-iam</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the bot. The name is <i>not</i> case sensitive. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_613776 = path.getOrDefault("name")
  valid_613776 = validateParameter(valid_613776, JString, required = true,
                                 default = nil)
  if valid_613776 != nil:
    section.add "name", valid_613776
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613777 = header.getOrDefault("X-Amz-Signature")
  valid_613777 = validateParameter(valid_613777, JString, required = false,
                                 default = nil)
  if valid_613777 != nil:
    section.add "X-Amz-Signature", valid_613777
  var valid_613778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613778 = validateParameter(valid_613778, JString, required = false,
                                 default = nil)
  if valid_613778 != nil:
    section.add "X-Amz-Content-Sha256", valid_613778
  var valid_613779 = header.getOrDefault("X-Amz-Date")
  valid_613779 = validateParameter(valid_613779, JString, required = false,
                                 default = nil)
  if valid_613779 != nil:
    section.add "X-Amz-Date", valid_613779
  var valid_613780 = header.getOrDefault("X-Amz-Credential")
  valid_613780 = validateParameter(valid_613780, JString, required = false,
                                 default = nil)
  if valid_613780 != nil:
    section.add "X-Amz-Credential", valid_613780
  var valid_613781 = header.getOrDefault("X-Amz-Security-Token")
  valid_613781 = validateParameter(valid_613781, JString, required = false,
                                 default = nil)
  if valid_613781 != nil:
    section.add "X-Amz-Security-Token", valid_613781
  var valid_613782 = header.getOrDefault("X-Amz-Algorithm")
  valid_613782 = validateParameter(valid_613782, JString, required = false,
                                 default = nil)
  if valid_613782 != nil:
    section.add "X-Amz-Algorithm", valid_613782
  var valid_613783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613783 = validateParameter(valid_613783, JString, required = false,
                                 default = nil)
  if valid_613783 != nil:
    section.add "X-Amz-SignedHeaders", valid_613783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613785: Call_PutBot_613773; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon Lex conversational bot or replaces an existing bot. When you create or update a bot you are only required to specify a name, a locale, and whether the bot is directed toward children under age 13. You can use this to add intents later, or to remove intents from an existing bot. When you create a bot with the minimum information, the bot is created or updated but Amazon Lex returns the <code/> response <code>FAILED</code>. You can build the bot after you add one or more intents. For more information about Amazon Lex bots, see <a>how-it-works</a>. </p> <p>If you specify the name of an existing bot, the fields in the request replace the existing values in the <code>$LATEST</code> version of the bot. Amazon Lex removes any fields that you don't provide values for in the request, except for the <code>idleTTLInSeconds</code> and <code>privacySettings</code> fields, which are set to their default values. If you don't specify values for required fields, Amazon Lex throws an exception.</p> <p>This operation requires permissions for the <code>lex:PutBot</code> action. For more information, see <a>security-iam</a>.</p>
  ## 
  let valid = call_613785.validator(path, query, header, formData, body)
  let scheme = call_613785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613785.url(scheme.get, call_613785.host, call_613785.base,
                         call_613785.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613785, url, valid)

proc call*(call_613786: Call_PutBot_613773; name: string; body: JsonNode): Recallable =
  ## putBot
  ## <p>Creates an Amazon Lex conversational bot or replaces an existing bot. When you create or update a bot you are only required to specify a name, a locale, and whether the bot is directed toward children under age 13. You can use this to add intents later, or to remove intents from an existing bot. When you create a bot with the minimum information, the bot is created or updated but Amazon Lex returns the <code/> response <code>FAILED</code>. You can build the bot after you add one or more intents. For more information about Amazon Lex bots, see <a>how-it-works</a>. </p> <p>If you specify the name of an existing bot, the fields in the request replace the existing values in the <code>$LATEST</code> version of the bot. Amazon Lex removes any fields that you don't provide values for in the request, except for the <code>idleTTLInSeconds</code> and <code>privacySettings</code> fields, which are set to their default values. If you don't specify values for required fields, Amazon Lex throws an exception.</p> <p>This operation requires permissions for the <code>lex:PutBot</code> action. For more information, see <a>security-iam</a>.</p>
  ##   name: string (required)
  ##       : The name of the bot. The name is <i>not</i> case sensitive. 
  ##   body: JObject (required)
  var path_613787 = newJObject()
  var body_613788 = newJObject()
  add(path_613787, "name", newJString(name))
  if body != nil:
    body_613788 = body
  result = call_613786.call(path_613787, nil, nil, nil, body_613788)

var putBot* = Call_PutBot_613773(name: "putBot", meth: HttpMethod.HttpPut,
                              host: "models.lex.amazonaws.com",
                              route: "/bots/{name}/versions/$LATEST",
                              validator: validate_PutBot_613774, base: "/",
                              url: url_PutBot_613775,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutIntent_613789 = ref object of OpenApiRestCall_612659
proc url_PutIntent_613791(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutIntent_613790(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613792 = path.getOrDefault("name")
  valid_613792 = validateParameter(valid_613792, JString, required = true,
                                 default = nil)
  if valid_613792 != nil:
    section.add "name", valid_613792
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613793 = header.getOrDefault("X-Amz-Signature")
  valid_613793 = validateParameter(valid_613793, JString, required = false,
                                 default = nil)
  if valid_613793 != nil:
    section.add "X-Amz-Signature", valid_613793
  var valid_613794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613794 = validateParameter(valid_613794, JString, required = false,
                                 default = nil)
  if valid_613794 != nil:
    section.add "X-Amz-Content-Sha256", valid_613794
  var valid_613795 = header.getOrDefault("X-Amz-Date")
  valid_613795 = validateParameter(valid_613795, JString, required = false,
                                 default = nil)
  if valid_613795 != nil:
    section.add "X-Amz-Date", valid_613795
  var valid_613796 = header.getOrDefault("X-Amz-Credential")
  valid_613796 = validateParameter(valid_613796, JString, required = false,
                                 default = nil)
  if valid_613796 != nil:
    section.add "X-Amz-Credential", valid_613796
  var valid_613797 = header.getOrDefault("X-Amz-Security-Token")
  valid_613797 = validateParameter(valid_613797, JString, required = false,
                                 default = nil)
  if valid_613797 != nil:
    section.add "X-Amz-Security-Token", valid_613797
  var valid_613798 = header.getOrDefault("X-Amz-Algorithm")
  valid_613798 = validateParameter(valid_613798, JString, required = false,
                                 default = nil)
  if valid_613798 != nil:
    section.add "X-Amz-Algorithm", valid_613798
  var valid_613799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613799 = validateParameter(valid_613799, JString, required = false,
                                 default = nil)
  if valid_613799 != nil:
    section.add "X-Amz-SignedHeaders", valid_613799
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613801: Call_PutIntent_613789; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an intent or replaces an existing intent.</p> <p>To define the interaction between the user and your bot, you use one or more intents. For a pizza ordering bot, for example, you would create an <code>OrderPizza</code> intent. </p> <p>To create an intent or replace an existing intent, you must provide the following:</p> <ul> <li> <p>Intent name. For example, <code>OrderPizza</code>.</p> </li> <li> <p>Sample utterances. For example, "Can I order a pizza, please." and "I want to order a pizza."</p> </li> <li> <p>Information to be gathered. You specify slot types for the information that your bot will request from the user. You can specify standard slot types, such as a date or a time, or custom slot types such as the size and crust of a pizza.</p> </li> <li> <p>How the intent will be fulfilled. You can provide a Lambda function or configure the intent to return the intent information to the client application. If you use a Lambda function, when all of the intent information is available, Amazon Lex invokes your Lambda function. If you configure your intent to return the intent information to the client application. </p> </li> </ul> <p>You can specify other optional information in the request, such as:</p> <ul> <li> <p>A confirmation prompt to ask the user to confirm an intent. For example, "Shall I order your pizza?"</p> </li> <li> <p>A conclusion statement to send to the user after the intent has been fulfilled. For example, "I placed your pizza order."</p> </li> <li> <p>A follow-up prompt that asks the user for additional activity. For example, asking "Do you want to order a drink with your pizza?"</p> </li> </ul> <p>If you specify an existing intent name to update the intent, Amazon Lex replaces the values in the <code>$LATEST</code> version of the intent with the values in the request. Amazon Lex removes fields that you don't provide in the request. If you don't specify the required fields, Amazon Lex throws an exception. When you update the <code>$LATEST</code> version of an intent, the <code>status</code> field of any bot that uses the <code>$LATEST</code> version of the intent is set to <code>NOT_BUILT</code>.</p> <p>For more information, see <a>how-it-works</a>.</p> <p>This operation requires permissions for the <code>lex:PutIntent</code> action.</p>
  ## 
  let valid = call_613801.validator(path, query, header, formData, body)
  let scheme = call_613801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613801.url(scheme.get, call_613801.host, call_613801.base,
                         call_613801.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613801, url, valid)

proc call*(call_613802: Call_PutIntent_613789; name: string; body: JsonNode): Recallable =
  ## putIntent
  ## <p>Creates an intent or replaces an existing intent.</p> <p>To define the interaction between the user and your bot, you use one or more intents. For a pizza ordering bot, for example, you would create an <code>OrderPizza</code> intent. </p> <p>To create an intent or replace an existing intent, you must provide the following:</p> <ul> <li> <p>Intent name. For example, <code>OrderPizza</code>.</p> </li> <li> <p>Sample utterances. For example, "Can I order a pizza, please." and "I want to order a pizza."</p> </li> <li> <p>Information to be gathered. You specify slot types for the information that your bot will request from the user. You can specify standard slot types, such as a date or a time, or custom slot types such as the size and crust of a pizza.</p> </li> <li> <p>How the intent will be fulfilled. You can provide a Lambda function or configure the intent to return the intent information to the client application. If you use a Lambda function, when all of the intent information is available, Amazon Lex invokes your Lambda function. If you configure your intent to return the intent information to the client application. </p> </li> </ul> <p>You can specify other optional information in the request, such as:</p> <ul> <li> <p>A confirmation prompt to ask the user to confirm an intent. For example, "Shall I order your pizza?"</p> </li> <li> <p>A conclusion statement to send to the user after the intent has been fulfilled. For example, "I placed your pizza order."</p> </li> <li> <p>A follow-up prompt that asks the user for additional activity. For example, asking "Do you want to order a drink with your pizza?"</p> </li> </ul> <p>If you specify an existing intent name to update the intent, Amazon Lex replaces the values in the <code>$LATEST</code> version of the intent with the values in the request. Amazon Lex removes fields that you don't provide in the request. If you don't specify the required fields, Amazon Lex throws an exception. When you update the <code>$LATEST</code> version of an intent, the <code>status</code> field of any bot that uses the <code>$LATEST</code> version of the intent is set to <code>NOT_BUILT</code>.</p> <p>For more information, see <a>how-it-works</a>.</p> <p>This operation requires permissions for the <code>lex:PutIntent</code> action.</p>
  ##   name: string (required)
  ##       : <p>The name of the intent. The name is <i>not</i> case sensitive. </p> <p>The name can't match a built-in intent name, or a built-in intent name with "AMAZON." removed. For example, because there is a built-in intent called <code>AMAZON.HelpIntent</code>, you can't create a custom intent called <code>HelpIntent</code>.</p> <p>For a list of built-in intents, see <a 
  ## href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/standard-intents">Standard Built-in Intents</a> in the <i>Alexa Skills Kit</i>.</p>
  ##   body: JObject (required)
  var path_613803 = newJObject()
  var body_613804 = newJObject()
  add(path_613803, "name", newJString(name))
  if body != nil:
    body_613804 = body
  result = call_613802.call(path_613803, nil, nil, nil, body_613804)

var putIntent* = Call_PutIntent_613789(name: "putIntent", meth: HttpMethod.HttpPut,
                                    host: "models.lex.amazonaws.com",
                                    route: "/intents/{name}/versions/$LATEST",
                                    validator: validate_PutIntent_613790,
                                    base: "/", url: url_PutIntent_613791,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSlotType_613805 = ref object of OpenApiRestCall_612659
proc url_PutSlotType_613807(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutSlotType_613806(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613808 = path.getOrDefault("name")
  valid_613808 = validateParameter(valid_613808, JString, required = true,
                                 default = nil)
  if valid_613808 != nil:
    section.add "name", valid_613808
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613809 = header.getOrDefault("X-Amz-Signature")
  valid_613809 = validateParameter(valid_613809, JString, required = false,
                                 default = nil)
  if valid_613809 != nil:
    section.add "X-Amz-Signature", valid_613809
  var valid_613810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613810 = validateParameter(valid_613810, JString, required = false,
                                 default = nil)
  if valid_613810 != nil:
    section.add "X-Amz-Content-Sha256", valid_613810
  var valid_613811 = header.getOrDefault("X-Amz-Date")
  valid_613811 = validateParameter(valid_613811, JString, required = false,
                                 default = nil)
  if valid_613811 != nil:
    section.add "X-Amz-Date", valid_613811
  var valid_613812 = header.getOrDefault("X-Amz-Credential")
  valid_613812 = validateParameter(valid_613812, JString, required = false,
                                 default = nil)
  if valid_613812 != nil:
    section.add "X-Amz-Credential", valid_613812
  var valid_613813 = header.getOrDefault("X-Amz-Security-Token")
  valid_613813 = validateParameter(valid_613813, JString, required = false,
                                 default = nil)
  if valid_613813 != nil:
    section.add "X-Amz-Security-Token", valid_613813
  var valid_613814 = header.getOrDefault("X-Amz-Algorithm")
  valid_613814 = validateParameter(valid_613814, JString, required = false,
                                 default = nil)
  if valid_613814 != nil:
    section.add "X-Amz-Algorithm", valid_613814
  var valid_613815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613815 = validateParameter(valid_613815, JString, required = false,
                                 default = nil)
  if valid_613815 != nil:
    section.add "X-Amz-SignedHeaders", valid_613815
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613817: Call_PutSlotType_613805; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a custom slot type or replaces an existing custom slot type.</p> <p>To create a custom slot type, specify a name for the slot type and a set of enumeration values, which are the values that a slot of this type can assume. For more information, see <a>how-it-works</a>.</p> <p>If you specify the name of an existing slot type, the fields in the request replace the existing values in the <code>$LATEST</code> version of the slot type. Amazon Lex removes the fields that you don't provide in the request. If you don't specify required fields, Amazon Lex throws an exception. When you update the <code>$LATEST</code> version of a slot type, if a bot uses the <code>$LATEST</code> version of an intent that contains the slot type, the bot's <code>status</code> field is set to <code>NOT_BUILT</code>.</p> <p>This operation requires permissions for the <code>lex:PutSlotType</code> action.</p>
  ## 
  let valid = call_613817.validator(path, query, header, formData, body)
  let scheme = call_613817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613817.url(scheme.get, call_613817.host, call_613817.base,
                         call_613817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613817, url, valid)

proc call*(call_613818: Call_PutSlotType_613805; name: string; body: JsonNode): Recallable =
  ## putSlotType
  ## <p>Creates a custom slot type or replaces an existing custom slot type.</p> <p>To create a custom slot type, specify a name for the slot type and a set of enumeration values, which are the values that a slot of this type can assume. For more information, see <a>how-it-works</a>.</p> <p>If you specify the name of an existing slot type, the fields in the request replace the existing values in the <code>$LATEST</code> version of the slot type. Amazon Lex removes the fields that you don't provide in the request. If you don't specify required fields, Amazon Lex throws an exception. When you update the <code>$LATEST</code> version of a slot type, if a bot uses the <code>$LATEST</code> version of an intent that contains the slot type, the bot's <code>status</code> field is set to <code>NOT_BUILT</code>.</p> <p>This operation requires permissions for the <code>lex:PutSlotType</code> action.</p>
  ##   name: string (required)
  ##       : <p>The name of the slot type. The name is <i>not</i> case sensitive. </p> <p>The name can't match a built-in slot type name, or a built-in slot type name with "AMAZON." removed. For example, because there is a built-in slot type called <code>AMAZON.DATE</code>, you can't create a custom slot type called <code>DATE</code>.</p> <p>For a list of built-in slot types, see <a 
  ## href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/slot-type-reference">Slot Type Reference</a> in the <i>Alexa Skills Kit</i>.</p>
  ##   body: JObject (required)
  var path_613819 = newJObject()
  var body_613820 = newJObject()
  add(path_613819, "name", newJString(name))
  if body != nil:
    body_613820 = body
  result = call_613818.call(path_613819, nil, nil, nil, body_613820)

var putSlotType* = Call_PutSlotType_613805(name: "putSlotType",
                                        meth: HttpMethod.HttpPut,
                                        host: "models.lex.amazonaws.com", route: "/slottypes/{name}/versions/$LATEST",
                                        validator: validate_PutSlotType_613806,
                                        base: "/", url: url_PutSlotType_613807,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImport_613821 = ref object of OpenApiRestCall_612659
proc url_StartImport_613823(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartImport_613822(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613824 = header.getOrDefault("X-Amz-Signature")
  valid_613824 = validateParameter(valid_613824, JString, required = false,
                                 default = nil)
  if valid_613824 != nil:
    section.add "X-Amz-Signature", valid_613824
  var valid_613825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613825 = validateParameter(valid_613825, JString, required = false,
                                 default = nil)
  if valid_613825 != nil:
    section.add "X-Amz-Content-Sha256", valid_613825
  var valid_613826 = header.getOrDefault("X-Amz-Date")
  valid_613826 = validateParameter(valid_613826, JString, required = false,
                                 default = nil)
  if valid_613826 != nil:
    section.add "X-Amz-Date", valid_613826
  var valid_613827 = header.getOrDefault("X-Amz-Credential")
  valid_613827 = validateParameter(valid_613827, JString, required = false,
                                 default = nil)
  if valid_613827 != nil:
    section.add "X-Amz-Credential", valid_613827
  var valid_613828 = header.getOrDefault("X-Amz-Security-Token")
  valid_613828 = validateParameter(valid_613828, JString, required = false,
                                 default = nil)
  if valid_613828 != nil:
    section.add "X-Amz-Security-Token", valid_613828
  var valid_613829 = header.getOrDefault("X-Amz-Algorithm")
  valid_613829 = validateParameter(valid_613829, JString, required = false,
                                 default = nil)
  if valid_613829 != nil:
    section.add "X-Amz-Algorithm", valid_613829
  var valid_613830 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613830 = validateParameter(valid_613830, JString, required = false,
                                 default = nil)
  if valid_613830 != nil:
    section.add "X-Amz-SignedHeaders", valid_613830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613832: Call_StartImport_613821; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a job to import a resource to Amazon Lex.
  ## 
  let valid = call_613832.validator(path, query, header, formData, body)
  let scheme = call_613832.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613832.url(scheme.get, call_613832.host, call_613832.base,
                         call_613832.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613832, url, valid)

proc call*(call_613833: Call_StartImport_613821; body: JsonNode): Recallable =
  ## startImport
  ## Starts a job to import a resource to Amazon Lex.
  ##   body: JObject (required)
  var body_613834 = newJObject()
  if body != nil:
    body_613834 = body
  result = call_613833.call(nil, nil, nil, nil, body_613834)

var startImport* = Call_StartImport_613821(name: "startImport",
                                        meth: HttpMethod.HttpPost,
                                        host: "models.lex.amazonaws.com",
                                        route: "/imports/",
                                        validator: validate_StartImport_613822,
                                        base: "/", url: url_StartImport_613823,
                                        schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
