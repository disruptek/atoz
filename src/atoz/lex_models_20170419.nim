
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625437): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateBotVersion_21625781 = ref object of OpenApiRestCall_21625437
proc url_CreateBotVersion_21625783(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateBotVersion_21625782(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a new version of the bot based on the <code>$LATEST</code> version. If the <code>$LATEST</code> version of this resource hasn't changed since you created the last version, Amazon Lex doesn't create a new version. It returns the last created version.</p> <note> <p>You can update only the <code>$LATEST</code> version of the bot. You can't update the numbered versions that you create with the <code>CreateBotVersion</code> operation.</p> </note> <p> When you create the first version of a bot, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p> This operation requires permission for the <code>lex:CreateBotVersion</code> action. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the bot that you want to create a new version of. The name is case sensitive. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_21625897 = path.getOrDefault("name")
  valid_21625897 = validateParameter(valid_21625897, JString, required = true,
                                   default = nil)
  if valid_21625897 != nil:
    section.add "name", valid_21625897
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
  var valid_21625898 = header.getOrDefault("X-Amz-Date")
  valid_21625898 = validateParameter(valid_21625898, JString, required = false,
                                   default = nil)
  if valid_21625898 != nil:
    section.add "X-Amz-Date", valid_21625898
  var valid_21625899 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "X-Amz-Security-Token", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Algorithm", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-Signature")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-Signature", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625903
  var valid_21625904 = header.getOrDefault("X-Amz-Credential")
  valid_21625904 = validateParameter(valid_21625904, JString, required = false,
                                   default = nil)
  if valid_21625904 != nil:
    section.add "X-Amz-Credential", valid_21625904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21625930: Call_CreateBotVersion_21625781; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new version of the bot based on the <code>$LATEST</code> version. If the <code>$LATEST</code> version of this resource hasn't changed since you created the last version, Amazon Lex doesn't create a new version. It returns the last created version.</p> <note> <p>You can update only the <code>$LATEST</code> version of the bot. You can't update the numbered versions that you create with the <code>CreateBotVersion</code> operation.</p> </note> <p> When you create the first version of a bot, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p> This operation requires permission for the <code>lex:CreateBotVersion</code> action. </p>
  ## 
  let valid = call_21625930.validator(path, query, header, formData, body, _)
  let scheme = call_21625930.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625930.makeUrl(scheme.get, call_21625930.host, call_21625930.base,
                               call_21625930.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625930, uri, valid, _)

proc call*(call_21625993: Call_CreateBotVersion_21625781; name: string;
          body: JsonNode): Recallable =
  ## createBotVersion
  ## <p>Creates a new version of the bot based on the <code>$LATEST</code> version. If the <code>$LATEST</code> version of this resource hasn't changed since you created the last version, Amazon Lex doesn't create a new version. It returns the last created version.</p> <note> <p>You can update only the <code>$LATEST</code> version of the bot. You can't update the numbered versions that you create with the <code>CreateBotVersion</code> operation.</p> </note> <p> When you create the first version of a bot, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p> This operation requires permission for the <code>lex:CreateBotVersion</code> action. </p>
  ##   name: string (required)
  ##       : The name of the bot that you want to create a new version of. The name is case sensitive. 
  ##   body: JObject (required)
  var path_21625995 = newJObject()
  var body_21625997 = newJObject()
  add(path_21625995, "name", newJString(name))
  if body != nil:
    body_21625997 = body
  result = call_21625993.call(path_21625995, nil, nil, nil, body_21625997)

var createBotVersion* = Call_CreateBotVersion_21625781(name: "createBotVersion",
    meth: HttpMethod.HttpPost, host: "models.lex.amazonaws.com",
    route: "/bots/{name}/versions", validator: validate_CreateBotVersion_21625782,
    base: "/", makeUrl: url_CreateBotVersion_21625783,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIntentVersion_21626034 = ref object of OpenApiRestCall_21625437
proc url_CreateIntentVersion_21626036(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateIntentVersion_21626035(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a new version of an intent based on the <code>$LATEST</code> version of the intent. If the <code>$LATEST</code> version of this intent hasn't changed since you last updated it, Amazon Lex doesn't create a new version. It returns the last version you created.</p> <note> <p>You can update only the <code>$LATEST</code> version of the intent. You can't update the numbered versions that you create with the <code>CreateIntentVersion</code> operation.</p> </note> <p> When you create a version of an intent, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p>This operation requires permissions to perform the <code>lex:CreateIntentVersion</code> action. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the intent that you want to create a new version of. The name is case sensitive. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_21626037 = path.getOrDefault("name")
  valid_21626037 = validateParameter(valid_21626037, JString, required = true,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "name", valid_21626037
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
  var valid_21626038 = header.getOrDefault("X-Amz-Date")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-Date", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Security-Token", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Algorithm", valid_21626041
  var valid_21626042 = header.getOrDefault("X-Amz-Signature")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "X-Amz-Signature", valid_21626042
  var valid_21626043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626043
  var valid_21626044 = header.getOrDefault("X-Amz-Credential")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "X-Amz-Credential", valid_21626044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626046: Call_CreateIntentVersion_21626034; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new version of an intent based on the <code>$LATEST</code> version of the intent. If the <code>$LATEST</code> version of this intent hasn't changed since you last updated it, Amazon Lex doesn't create a new version. It returns the last version you created.</p> <note> <p>You can update only the <code>$LATEST</code> version of the intent. You can't update the numbered versions that you create with the <code>CreateIntentVersion</code> operation.</p> </note> <p> When you create a version of an intent, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p>This operation requires permissions to perform the <code>lex:CreateIntentVersion</code> action. </p>
  ## 
  let valid = call_21626046.validator(path, query, header, formData, body, _)
  let scheme = call_21626046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626046.makeUrl(scheme.get, call_21626046.host, call_21626046.base,
                               call_21626046.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626046, uri, valid, _)

proc call*(call_21626047: Call_CreateIntentVersion_21626034; name: string;
          body: JsonNode): Recallable =
  ## createIntentVersion
  ## <p>Creates a new version of an intent based on the <code>$LATEST</code> version of the intent. If the <code>$LATEST</code> version of this intent hasn't changed since you last updated it, Amazon Lex doesn't create a new version. It returns the last version you created.</p> <note> <p>You can update only the <code>$LATEST</code> version of the intent. You can't update the numbered versions that you create with the <code>CreateIntentVersion</code> operation.</p> </note> <p> When you create a version of an intent, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p>This operation requires permissions to perform the <code>lex:CreateIntentVersion</code> action. </p>
  ##   name: string (required)
  ##       : The name of the intent that you want to create a new version of. The name is case sensitive. 
  ##   body: JObject (required)
  var path_21626048 = newJObject()
  var body_21626049 = newJObject()
  add(path_21626048, "name", newJString(name))
  if body != nil:
    body_21626049 = body
  result = call_21626047.call(path_21626048, nil, nil, nil, body_21626049)

var createIntentVersion* = Call_CreateIntentVersion_21626034(
    name: "createIntentVersion", meth: HttpMethod.HttpPost,
    host: "models.lex.amazonaws.com", route: "/intents/{name}/versions",
    validator: validate_CreateIntentVersion_21626035, base: "/",
    makeUrl: url_CreateIntentVersion_21626036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSlotTypeVersion_21626050 = ref object of OpenApiRestCall_21625437
proc url_CreateSlotTypeVersion_21626052(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateSlotTypeVersion_21626051(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a new version of a slot type based on the <code>$LATEST</code> version of the specified slot type. If the <code>$LATEST</code> version of this resource has not changed since the last version that you created, Amazon Lex doesn't create a new version. It returns the last version that you created. </p> <note> <p>You can update only the <code>$LATEST</code> version of a slot type. You can't update the numbered versions that you create with the <code>CreateSlotTypeVersion</code> operation.</p> </note> <p>When you create a version of a slot type, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p>This operation requires permissions for the <code>lex:CreateSlotTypeVersion</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the slot type that you want to create a new version for. The name is case sensitive. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_21626053 = path.getOrDefault("name")
  valid_21626053 = validateParameter(valid_21626053, JString, required = true,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "name", valid_21626053
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
  var valid_21626054 = header.getOrDefault("X-Amz-Date")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Date", valid_21626054
  var valid_21626055 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-Security-Token", valid_21626055
  var valid_21626056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626056
  var valid_21626057 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-Algorithm", valid_21626057
  var valid_21626058 = header.getOrDefault("X-Amz-Signature")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "X-Amz-Signature", valid_21626058
  var valid_21626059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626059
  var valid_21626060 = header.getOrDefault("X-Amz-Credential")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "X-Amz-Credential", valid_21626060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626062: Call_CreateSlotTypeVersion_21626050;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new version of a slot type based on the <code>$LATEST</code> version of the specified slot type. If the <code>$LATEST</code> version of this resource has not changed since the last version that you created, Amazon Lex doesn't create a new version. It returns the last version that you created. </p> <note> <p>You can update only the <code>$LATEST</code> version of a slot type. You can't update the numbered versions that you create with the <code>CreateSlotTypeVersion</code> operation.</p> </note> <p>When you create a version of a slot type, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p>This operation requires permissions for the <code>lex:CreateSlotTypeVersion</code> action.</p>
  ## 
  let valid = call_21626062.validator(path, query, header, formData, body, _)
  let scheme = call_21626062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626062.makeUrl(scheme.get, call_21626062.host, call_21626062.base,
                               call_21626062.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626062, uri, valid, _)

proc call*(call_21626063: Call_CreateSlotTypeVersion_21626050; name: string;
          body: JsonNode): Recallable =
  ## createSlotTypeVersion
  ## <p>Creates a new version of a slot type based on the <code>$LATEST</code> version of the specified slot type. If the <code>$LATEST</code> version of this resource has not changed since the last version that you created, Amazon Lex doesn't create a new version. It returns the last version that you created. </p> <note> <p>You can update only the <code>$LATEST</code> version of a slot type. You can't update the numbered versions that you create with the <code>CreateSlotTypeVersion</code> operation.</p> </note> <p>When you create a version of a slot type, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p>This operation requires permissions for the <code>lex:CreateSlotTypeVersion</code> action.</p>
  ##   name: string (required)
  ##       : The name of the slot type that you want to create a new version for. The name is case sensitive. 
  ##   body: JObject (required)
  var path_21626064 = newJObject()
  var body_21626065 = newJObject()
  add(path_21626064, "name", newJString(name))
  if body != nil:
    body_21626065 = body
  result = call_21626063.call(path_21626064, nil, nil, nil, body_21626065)

var createSlotTypeVersion* = Call_CreateSlotTypeVersion_21626050(
    name: "createSlotTypeVersion", meth: HttpMethod.HttpPost,
    host: "models.lex.amazonaws.com", route: "/slottypes/{name}/versions",
    validator: validate_CreateSlotTypeVersion_21626051, base: "/",
    makeUrl: url_CreateSlotTypeVersion_21626052,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBot_21626066 = ref object of OpenApiRestCall_21625437
proc url_DeleteBot_21626068(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBot_21626067(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes all versions of the bot, including the <code>$LATEST</code> version. To delete a specific version of the bot, use the <a>DeleteBotVersion</a> operation. The <code>DeleteBot</code> operation doesn't immediately remove the bot schema. Instead, it is marked for deletion and removed later.</p> <p>Amazon Lex stores utterances indefinitely for improving the ability of your bot to respond to user inputs. These utterances are not removed when the bot is deleted. To remove the utterances, use the <a>DeleteUtterances</a> operation.</p> <p>If a bot has an alias, you can't delete it. Instead, the <code>DeleteBot</code> operation returns a <code>ResourceInUseException</code> exception that includes a reference to the alias that refers to the bot. To remove the reference to the bot, delete the alias. If you get the same exception again, delete the referring alias until the <code>DeleteBot</code> operation is successful.</p> <p>This operation requires permissions for the <code>lex:DeleteBot</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the bot. The name is case sensitive. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_21626069 = path.getOrDefault("name")
  valid_21626069 = validateParameter(valid_21626069, JString, required = true,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "name", valid_21626069
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
  var valid_21626070 = header.getOrDefault("X-Amz-Date")
  valid_21626070 = validateParameter(valid_21626070, JString, required = false,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "X-Amz-Date", valid_21626070
  var valid_21626071 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626071 = validateParameter(valid_21626071, JString, required = false,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "X-Amz-Security-Token", valid_21626071
  var valid_21626072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626072 = validateParameter(valid_21626072, JString, required = false,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626072
  var valid_21626073 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626073 = validateParameter(valid_21626073, JString, required = false,
                                   default = nil)
  if valid_21626073 != nil:
    section.add "X-Amz-Algorithm", valid_21626073
  var valid_21626074 = header.getOrDefault("X-Amz-Signature")
  valid_21626074 = validateParameter(valid_21626074, JString, required = false,
                                   default = nil)
  if valid_21626074 != nil:
    section.add "X-Amz-Signature", valid_21626074
  var valid_21626075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = nil)
  if valid_21626075 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626075
  var valid_21626076 = header.getOrDefault("X-Amz-Credential")
  valid_21626076 = validateParameter(valid_21626076, JString, required = false,
                                   default = nil)
  if valid_21626076 != nil:
    section.add "X-Amz-Credential", valid_21626076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626077: Call_DeleteBot_21626066; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes all versions of the bot, including the <code>$LATEST</code> version. To delete a specific version of the bot, use the <a>DeleteBotVersion</a> operation. The <code>DeleteBot</code> operation doesn't immediately remove the bot schema. Instead, it is marked for deletion and removed later.</p> <p>Amazon Lex stores utterances indefinitely for improving the ability of your bot to respond to user inputs. These utterances are not removed when the bot is deleted. To remove the utterances, use the <a>DeleteUtterances</a> operation.</p> <p>If a bot has an alias, you can't delete it. Instead, the <code>DeleteBot</code> operation returns a <code>ResourceInUseException</code> exception that includes a reference to the alias that refers to the bot. To remove the reference to the bot, delete the alias. If you get the same exception again, delete the referring alias until the <code>DeleteBot</code> operation is successful.</p> <p>This operation requires permissions for the <code>lex:DeleteBot</code> action.</p>
  ## 
  let valid = call_21626077.validator(path, query, header, formData, body, _)
  let scheme = call_21626077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626077.makeUrl(scheme.get, call_21626077.host, call_21626077.base,
                               call_21626077.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626077, uri, valid, _)

proc call*(call_21626078: Call_DeleteBot_21626066; name: string): Recallable =
  ## deleteBot
  ## <p>Deletes all versions of the bot, including the <code>$LATEST</code> version. To delete a specific version of the bot, use the <a>DeleteBotVersion</a> operation. The <code>DeleteBot</code> operation doesn't immediately remove the bot schema. Instead, it is marked for deletion and removed later.</p> <p>Amazon Lex stores utterances indefinitely for improving the ability of your bot to respond to user inputs. These utterances are not removed when the bot is deleted. To remove the utterances, use the <a>DeleteUtterances</a> operation.</p> <p>If a bot has an alias, you can't delete it. Instead, the <code>DeleteBot</code> operation returns a <code>ResourceInUseException</code> exception that includes a reference to the alias that refers to the bot. To remove the reference to the bot, delete the alias. If you get the same exception again, delete the referring alias until the <code>DeleteBot</code> operation is successful.</p> <p>This operation requires permissions for the <code>lex:DeleteBot</code> action.</p>
  ##   name: string (required)
  ##       : The name of the bot. The name is case sensitive. 
  var path_21626079 = newJObject()
  add(path_21626079, "name", newJString(name))
  result = call_21626078.call(path_21626079, nil, nil, nil, nil)

var deleteBot* = Call_DeleteBot_21626066(name: "deleteBot",
                                      meth: HttpMethod.HttpDelete,
                                      host: "models.lex.amazonaws.com",
                                      route: "/bots/{name}",
                                      validator: validate_DeleteBot_21626067,
                                      base: "/", makeUrl: url_DeleteBot_21626068,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBotAlias_21626095 = ref object of OpenApiRestCall_21625437
proc url_PutBotAlias_21626097(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutBotAlias_21626096(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626098 = path.getOrDefault("name")
  valid_21626098 = validateParameter(valid_21626098, JString, required = true,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "name", valid_21626098
  var valid_21626099 = path.getOrDefault("botName")
  valid_21626099 = validateParameter(valid_21626099, JString, required = true,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "botName", valid_21626099
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
  var valid_21626100 = header.getOrDefault("X-Amz-Date")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "X-Amz-Date", valid_21626100
  var valid_21626101 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-Security-Token", valid_21626101
  var valid_21626102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626102
  var valid_21626103 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626103 = validateParameter(valid_21626103, JString, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "X-Amz-Algorithm", valid_21626103
  var valid_21626104 = header.getOrDefault("X-Amz-Signature")
  valid_21626104 = validateParameter(valid_21626104, JString, required = false,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "X-Amz-Signature", valid_21626104
  var valid_21626105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626105
  var valid_21626106 = header.getOrDefault("X-Amz-Credential")
  valid_21626106 = validateParameter(valid_21626106, JString, required = false,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "X-Amz-Credential", valid_21626106
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626108: Call_PutBotAlias_21626095; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an alias for the specified version of the bot or replaces an alias for the specified bot. To change the version of the bot that the alias points to, replace the alias. For more information about aliases, see <a>versioning-aliases</a>.</p> <p>This operation requires permissions for the <code>lex:PutBotAlias</code> action. </p>
  ## 
  let valid = call_21626108.validator(path, query, header, formData, body, _)
  let scheme = call_21626108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626108.makeUrl(scheme.get, call_21626108.host, call_21626108.base,
                               call_21626108.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626108, uri, valid, _)

proc call*(call_21626109: Call_PutBotAlias_21626095; name: string; botName: string;
          body: JsonNode): Recallable =
  ## putBotAlias
  ## <p>Creates an alias for the specified version of the bot or replaces an alias for the specified bot. To change the version of the bot that the alias points to, replace the alias. For more information about aliases, see <a>versioning-aliases</a>.</p> <p>This operation requires permissions for the <code>lex:PutBotAlias</code> action. </p>
  ##   name: string (required)
  ##       : The name of the alias. The name is <i>not</i> case sensitive.
  ##   botName: string (required)
  ##          : The name of the bot.
  ##   body: JObject (required)
  var path_21626110 = newJObject()
  var body_21626111 = newJObject()
  add(path_21626110, "name", newJString(name))
  add(path_21626110, "botName", newJString(botName))
  if body != nil:
    body_21626111 = body
  result = call_21626109.call(path_21626110, nil, nil, nil, body_21626111)

var putBotAlias* = Call_PutBotAlias_21626095(name: "putBotAlias",
    meth: HttpMethod.HttpPut, host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/aliases/{name}", validator: validate_PutBotAlias_21626096,
    base: "/", makeUrl: url_PutBotAlias_21626097,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBotAlias_21626080 = ref object of OpenApiRestCall_21625437
proc url_GetBotAlias_21626082(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBotAlias_21626081(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626083 = path.getOrDefault("name")
  valid_21626083 = validateParameter(valid_21626083, JString, required = true,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "name", valid_21626083
  var valid_21626084 = path.getOrDefault("botName")
  valid_21626084 = validateParameter(valid_21626084, JString, required = true,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "botName", valid_21626084
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
  var valid_21626085 = header.getOrDefault("X-Amz-Date")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "X-Amz-Date", valid_21626085
  var valid_21626086 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-Security-Token", valid_21626086
  var valid_21626087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626087
  var valid_21626088 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626088 = validateParameter(valid_21626088, JString, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "X-Amz-Algorithm", valid_21626088
  var valid_21626089 = header.getOrDefault("X-Amz-Signature")
  valid_21626089 = validateParameter(valid_21626089, JString, required = false,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "X-Amz-Signature", valid_21626089
  var valid_21626090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626090 = validateParameter(valid_21626090, JString, required = false,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626090
  var valid_21626091 = header.getOrDefault("X-Amz-Credential")
  valid_21626091 = validateParameter(valid_21626091, JString, required = false,
                                   default = nil)
  if valid_21626091 != nil:
    section.add "X-Amz-Credential", valid_21626091
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626092: Call_GetBotAlias_21626080; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns information about an Amazon Lex bot alias. For more information about aliases, see <a>versioning-aliases</a>.</p> <p>This operation requires permissions for the <code>lex:GetBotAlias</code> action.</p>
  ## 
  let valid = call_21626092.validator(path, query, header, formData, body, _)
  let scheme = call_21626092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626092.makeUrl(scheme.get, call_21626092.host, call_21626092.base,
                               call_21626092.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626092, uri, valid, _)

proc call*(call_21626093: Call_GetBotAlias_21626080; name: string; botName: string): Recallable =
  ## getBotAlias
  ## <p>Returns information about an Amazon Lex bot alias. For more information about aliases, see <a>versioning-aliases</a>.</p> <p>This operation requires permissions for the <code>lex:GetBotAlias</code> action.</p>
  ##   name: string (required)
  ##       : The name of the bot alias. The name is case sensitive.
  ##   botName: string (required)
  ##          : The name of the bot.
  var path_21626094 = newJObject()
  add(path_21626094, "name", newJString(name))
  add(path_21626094, "botName", newJString(botName))
  result = call_21626093.call(path_21626094, nil, nil, nil, nil)

var getBotAlias* = Call_GetBotAlias_21626080(name: "getBotAlias",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/aliases/{name}", validator: validate_GetBotAlias_21626081,
    base: "/", makeUrl: url_GetBotAlias_21626082,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBotAlias_21626112 = ref object of OpenApiRestCall_21625437
proc url_DeleteBotAlias_21626114(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBotAlias_21626113(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626115 = path.getOrDefault("name")
  valid_21626115 = validateParameter(valid_21626115, JString, required = true,
                                   default = nil)
  if valid_21626115 != nil:
    section.add "name", valid_21626115
  var valid_21626116 = path.getOrDefault("botName")
  valid_21626116 = validateParameter(valid_21626116, JString, required = true,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "botName", valid_21626116
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
  var valid_21626117 = header.getOrDefault("X-Amz-Date")
  valid_21626117 = validateParameter(valid_21626117, JString, required = false,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "X-Amz-Date", valid_21626117
  var valid_21626118 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "X-Amz-Security-Token", valid_21626118
  var valid_21626119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626119 = validateParameter(valid_21626119, JString, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626119
  var valid_21626120 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626120 = validateParameter(valid_21626120, JString, required = false,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "X-Amz-Algorithm", valid_21626120
  var valid_21626121 = header.getOrDefault("X-Amz-Signature")
  valid_21626121 = validateParameter(valid_21626121, JString, required = false,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "X-Amz-Signature", valid_21626121
  var valid_21626122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-Credential")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Credential", valid_21626123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626124: Call_DeleteBotAlias_21626112; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes an alias for the specified bot. </p> <p>You can't delete an alias that is used in the association between a bot and a messaging channel. If an alias is used in a channel association, the <code>DeleteBot</code> operation returns a <code>ResourceInUseException</code> exception that includes a reference to the channel association that refers to the bot. You can remove the reference to the alias by deleting the channel association. If you get the same exception again, delete the referring association until the <code>DeleteBotAlias</code> operation is successful.</p>
  ## 
  let valid = call_21626124.validator(path, query, header, formData, body, _)
  let scheme = call_21626124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626124.makeUrl(scheme.get, call_21626124.host, call_21626124.base,
                               call_21626124.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626124, uri, valid, _)

proc call*(call_21626125: Call_DeleteBotAlias_21626112; name: string; botName: string): Recallable =
  ## deleteBotAlias
  ## <p>Deletes an alias for the specified bot. </p> <p>You can't delete an alias that is used in the association between a bot and a messaging channel. If an alias is used in a channel association, the <code>DeleteBot</code> operation returns a <code>ResourceInUseException</code> exception that includes a reference to the channel association that refers to the bot. You can remove the reference to the alias by deleting the channel association. If you get the same exception again, delete the referring association until the <code>DeleteBotAlias</code> operation is successful.</p>
  ##   name: string (required)
  ##       : The name of the alias to delete. The name is case sensitive. 
  ##   botName: string (required)
  ##          : The name of the bot that the alias points to.
  var path_21626126 = newJObject()
  add(path_21626126, "name", newJString(name))
  add(path_21626126, "botName", newJString(botName))
  result = call_21626125.call(path_21626126, nil, nil, nil, nil)

var deleteBotAlias* = Call_DeleteBotAlias_21626112(name: "deleteBotAlias",
    meth: HttpMethod.HttpDelete, host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/aliases/{name}", validator: validate_DeleteBotAlias_21626113,
    base: "/", makeUrl: url_DeleteBotAlias_21626114,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBotChannelAssociation_21626127 = ref object of OpenApiRestCall_21625437
proc url_GetBotChannelAssociation_21626129(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBotChannelAssociation_21626128(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626130 = path.getOrDefault("name")
  valid_21626130 = validateParameter(valid_21626130, JString, required = true,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "name", valid_21626130
  var valid_21626131 = path.getOrDefault("botName")
  valid_21626131 = validateParameter(valid_21626131, JString, required = true,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "botName", valid_21626131
  var valid_21626132 = path.getOrDefault("aliasName")
  valid_21626132 = validateParameter(valid_21626132, JString, required = true,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "aliasName", valid_21626132
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
  var valid_21626133 = header.getOrDefault("X-Amz-Date")
  valid_21626133 = validateParameter(valid_21626133, JString, required = false,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "X-Amz-Date", valid_21626133
  var valid_21626134 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "X-Amz-Security-Token", valid_21626134
  var valid_21626135 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626135 = validateParameter(valid_21626135, JString, required = false,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626135
  var valid_21626136 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626136 = validateParameter(valid_21626136, JString, required = false,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "X-Amz-Algorithm", valid_21626136
  var valid_21626137 = header.getOrDefault("X-Amz-Signature")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Signature", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-Credential")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-Credential", valid_21626139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626140: Call_GetBotChannelAssociation_21626127;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns information about the association between an Amazon Lex bot and a messaging platform.</p> <p>This operation requires permissions for the <code>lex:GetBotChannelAssociation</code> action.</p>
  ## 
  let valid = call_21626140.validator(path, query, header, formData, body, _)
  let scheme = call_21626140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626140.makeUrl(scheme.get, call_21626140.host, call_21626140.base,
                               call_21626140.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626140, uri, valid, _)

proc call*(call_21626141: Call_GetBotChannelAssociation_21626127; name: string;
          botName: string; aliasName: string): Recallable =
  ## getBotChannelAssociation
  ## <p>Returns information about the association between an Amazon Lex bot and a messaging platform.</p> <p>This operation requires permissions for the <code>lex:GetBotChannelAssociation</code> action.</p>
  ##   name: string (required)
  ##       : The name of the association between the bot and the channel. The name is case sensitive. 
  ##   botName: string (required)
  ##          : The name of the Amazon Lex bot.
  ##   aliasName: string (required)
  ##            : An alias pointing to the specific version of the Amazon Lex bot to which this association is being made.
  var path_21626142 = newJObject()
  add(path_21626142, "name", newJString(name))
  add(path_21626142, "botName", newJString(botName))
  add(path_21626142, "aliasName", newJString(aliasName))
  result = call_21626141.call(path_21626142, nil, nil, nil, nil)

var getBotChannelAssociation* = Call_GetBotChannelAssociation_21626127(
    name: "getBotChannelAssociation", meth: HttpMethod.HttpGet,
    host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/aliases/{aliasName}/channels/{name}",
    validator: validate_GetBotChannelAssociation_21626128, base: "/",
    makeUrl: url_GetBotChannelAssociation_21626129,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBotChannelAssociation_21626143 = ref object of OpenApiRestCall_21625437
proc url_DeleteBotChannelAssociation_21626145(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBotChannelAssociation_21626144(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626146 = path.getOrDefault("name")
  valid_21626146 = validateParameter(valid_21626146, JString, required = true,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "name", valid_21626146
  var valid_21626147 = path.getOrDefault("botName")
  valid_21626147 = validateParameter(valid_21626147, JString, required = true,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "botName", valid_21626147
  var valid_21626148 = path.getOrDefault("aliasName")
  valid_21626148 = validateParameter(valid_21626148, JString, required = true,
                                   default = nil)
  if valid_21626148 != nil:
    section.add "aliasName", valid_21626148
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
  var valid_21626149 = header.getOrDefault("X-Amz-Date")
  valid_21626149 = validateParameter(valid_21626149, JString, required = false,
                                   default = nil)
  if valid_21626149 != nil:
    section.add "X-Amz-Date", valid_21626149
  var valid_21626150 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626150 = validateParameter(valid_21626150, JString, required = false,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "X-Amz-Security-Token", valid_21626150
  var valid_21626151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626151 = validateParameter(valid_21626151, JString, required = false,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626151
  var valid_21626152 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-Algorithm", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-Signature")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Signature", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-Credential")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Credential", valid_21626155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626156: Call_DeleteBotChannelAssociation_21626143;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the association between an Amazon Lex bot and a messaging platform.</p> <p>This operation requires permission for the <code>lex:DeleteBotChannelAssociation</code> action.</p>
  ## 
  let valid = call_21626156.validator(path, query, header, formData, body, _)
  let scheme = call_21626156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626156.makeUrl(scheme.get, call_21626156.host, call_21626156.base,
                               call_21626156.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626156, uri, valid, _)

proc call*(call_21626157: Call_DeleteBotChannelAssociation_21626143; name: string;
          botName: string; aliasName: string): Recallable =
  ## deleteBotChannelAssociation
  ## <p>Deletes the association between an Amazon Lex bot and a messaging platform.</p> <p>This operation requires permission for the <code>lex:DeleteBotChannelAssociation</code> action.</p>
  ##   name: string (required)
  ##       : The name of the association. The name is case sensitive. 
  ##   botName: string (required)
  ##          : The name of the Amazon Lex bot.
  ##   aliasName: string (required)
  ##            : An alias that points to the specific version of the Amazon Lex bot to which this association is being made.
  var path_21626158 = newJObject()
  add(path_21626158, "name", newJString(name))
  add(path_21626158, "botName", newJString(botName))
  add(path_21626158, "aliasName", newJString(aliasName))
  result = call_21626157.call(path_21626158, nil, nil, nil, nil)

var deleteBotChannelAssociation* = Call_DeleteBotChannelAssociation_21626143(
    name: "deleteBotChannelAssociation", meth: HttpMethod.HttpDelete,
    host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/aliases/{aliasName}/channels/{name}",
    validator: validate_DeleteBotChannelAssociation_21626144, base: "/",
    makeUrl: url_DeleteBotChannelAssociation_21626145,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBotVersion_21626159 = ref object of OpenApiRestCall_21625437
proc url_DeleteBotVersion_21626161(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteBotVersion_21626160(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626162 = path.getOrDefault("name")
  valid_21626162 = validateParameter(valid_21626162, JString, required = true,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "name", valid_21626162
  var valid_21626163 = path.getOrDefault("version")
  valid_21626163 = validateParameter(valid_21626163, JString, required = true,
                                   default = nil)
  if valid_21626163 != nil:
    section.add "version", valid_21626163
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
  var valid_21626164 = header.getOrDefault("X-Amz-Date")
  valid_21626164 = validateParameter(valid_21626164, JString, required = false,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "X-Amz-Date", valid_21626164
  var valid_21626165 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626165 = validateParameter(valid_21626165, JString, required = false,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "X-Amz-Security-Token", valid_21626165
  var valid_21626166 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626166
  var valid_21626167 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-Algorithm", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-Signature")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Signature", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Credential")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Credential", valid_21626170
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626171: Call_DeleteBotVersion_21626159; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a specific version of a bot. To delete all versions of a bot, use the <a>DeleteBot</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteBotVersion</code> action.</p>
  ## 
  let valid = call_21626171.validator(path, query, header, formData, body, _)
  let scheme = call_21626171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626171.makeUrl(scheme.get, call_21626171.host, call_21626171.base,
                               call_21626171.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626171, uri, valid, _)

proc call*(call_21626172: Call_DeleteBotVersion_21626159; name: string;
          version: string): Recallable =
  ## deleteBotVersion
  ## <p>Deletes a specific version of a bot. To delete all versions of a bot, use the <a>DeleteBot</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteBotVersion</code> action.</p>
  ##   name: string (required)
  ##       : The name of the bot.
  ##   version: string (required)
  ##          : The version of the bot to delete. You cannot delete the <code>$LATEST</code> version of the bot. To delete the <code>$LATEST</code> version, use the <a>DeleteBot</a> operation.
  var path_21626173 = newJObject()
  add(path_21626173, "name", newJString(name))
  add(path_21626173, "version", newJString(version))
  result = call_21626172.call(path_21626173, nil, nil, nil, nil)

var deleteBotVersion* = Call_DeleteBotVersion_21626159(name: "deleteBotVersion",
    meth: HttpMethod.HttpDelete, host: "models.lex.amazonaws.com",
    route: "/bots/{name}/versions/{version}",
    validator: validate_DeleteBotVersion_21626160, base: "/",
    makeUrl: url_DeleteBotVersion_21626161, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntent_21626174 = ref object of OpenApiRestCall_21625437
proc url_DeleteIntent_21626176(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteIntent_21626175(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Deletes all versions of the intent, including the <code>$LATEST</code> version. To delete a specific version of the intent, use the <a>DeleteIntentVersion</a> operation.</p> <p> You can delete a version of an intent only if it is not referenced. To delete an intent that is referred to in one or more bots (see <a>how-it-works</a>), you must remove those references first. </p> <note> <p> If you get the <code>ResourceInUseException</code> exception, it provides an example reference that shows where the intent is referenced. To remove the reference to the intent, either update the bot or delete it. If you get the same exception when you attempt to delete the intent again, repeat until the intent has no references and the call to <code>DeleteIntent</code> is successful. </p> </note> <p> This operation requires permission for the <code>lex:DeleteIntent</code> action. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the intent. The name is case sensitive. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_21626177 = path.getOrDefault("name")
  valid_21626177 = validateParameter(valid_21626177, JString, required = true,
                                   default = nil)
  if valid_21626177 != nil:
    section.add "name", valid_21626177
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
  var valid_21626178 = header.getOrDefault("X-Amz-Date")
  valid_21626178 = validateParameter(valid_21626178, JString, required = false,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "X-Amz-Date", valid_21626178
  var valid_21626179 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626179 = validateParameter(valid_21626179, JString, required = false,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "X-Amz-Security-Token", valid_21626179
  var valid_21626180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626180 = validateParameter(valid_21626180, JString, required = false,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626180
  var valid_21626181 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626181 = validateParameter(valid_21626181, JString, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "X-Amz-Algorithm", valid_21626181
  var valid_21626182 = header.getOrDefault("X-Amz-Signature")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-Signature", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Credential")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-Credential", valid_21626184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626185: Call_DeleteIntent_21626174; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes all versions of the intent, including the <code>$LATEST</code> version. To delete a specific version of the intent, use the <a>DeleteIntentVersion</a> operation.</p> <p> You can delete a version of an intent only if it is not referenced. To delete an intent that is referred to in one or more bots (see <a>how-it-works</a>), you must remove those references first. </p> <note> <p> If you get the <code>ResourceInUseException</code> exception, it provides an example reference that shows where the intent is referenced. To remove the reference to the intent, either update the bot or delete it. If you get the same exception when you attempt to delete the intent again, repeat until the intent has no references and the call to <code>DeleteIntent</code> is successful. </p> </note> <p> This operation requires permission for the <code>lex:DeleteIntent</code> action. </p>
  ## 
  let valid = call_21626185.validator(path, query, header, formData, body, _)
  let scheme = call_21626185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626185.makeUrl(scheme.get, call_21626185.host, call_21626185.base,
                               call_21626185.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626185, uri, valid, _)

proc call*(call_21626186: Call_DeleteIntent_21626174; name: string): Recallable =
  ## deleteIntent
  ## <p>Deletes all versions of the intent, including the <code>$LATEST</code> version. To delete a specific version of the intent, use the <a>DeleteIntentVersion</a> operation.</p> <p> You can delete a version of an intent only if it is not referenced. To delete an intent that is referred to in one or more bots (see <a>how-it-works</a>), you must remove those references first. </p> <note> <p> If you get the <code>ResourceInUseException</code> exception, it provides an example reference that shows where the intent is referenced. To remove the reference to the intent, either update the bot or delete it. If you get the same exception when you attempt to delete the intent again, repeat until the intent has no references and the call to <code>DeleteIntent</code> is successful. </p> </note> <p> This operation requires permission for the <code>lex:DeleteIntent</code> action. </p>
  ##   name: string (required)
  ##       : The name of the intent. The name is case sensitive. 
  var path_21626187 = newJObject()
  add(path_21626187, "name", newJString(name))
  result = call_21626186.call(path_21626187, nil, nil, nil, nil)

var deleteIntent* = Call_DeleteIntent_21626174(name: "deleteIntent",
    meth: HttpMethod.HttpDelete, host: "models.lex.amazonaws.com",
    route: "/intents/{name}", validator: validate_DeleteIntent_21626175, base: "/",
    makeUrl: url_DeleteIntent_21626176, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntent_21626188 = ref object of OpenApiRestCall_21625437
proc url_GetIntent_21626190(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIntent_21626189(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626191 = path.getOrDefault("name")
  valid_21626191 = validateParameter(valid_21626191, JString, required = true,
                                   default = nil)
  if valid_21626191 != nil:
    section.add "name", valid_21626191
  var valid_21626192 = path.getOrDefault("version")
  valid_21626192 = validateParameter(valid_21626192, JString, required = true,
                                   default = nil)
  if valid_21626192 != nil:
    section.add "version", valid_21626192
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
  var valid_21626193 = header.getOrDefault("X-Amz-Date")
  valid_21626193 = validateParameter(valid_21626193, JString, required = false,
                                   default = nil)
  if valid_21626193 != nil:
    section.add "X-Amz-Date", valid_21626193
  var valid_21626194 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626194 = validateParameter(valid_21626194, JString, required = false,
                                   default = nil)
  if valid_21626194 != nil:
    section.add "X-Amz-Security-Token", valid_21626194
  var valid_21626195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626195 = validateParameter(valid_21626195, JString, required = false,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626195
  var valid_21626196 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626196 = validateParameter(valid_21626196, JString, required = false,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "X-Amz-Algorithm", valid_21626196
  var valid_21626197 = header.getOrDefault("X-Amz-Signature")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Signature", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Credential")
  valid_21626199 = validateParameter(valid_21626199, JString, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "X-Amz-Credential", valid_21626199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626200: Call_GetIntent_21626188; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Returns information about an intent. In addition to the intent name, you must specify the intent version. </p> <p> This operation requires permissions to perform the <code>lex:GetIntent</code> action. </p>
  ## 
  let valid = call_21626200.validator(path, query, header, formData, body, _)
  let scheme = call_21626200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626200.makeUrl(scheme.get, call_21626200.host, call_21626200.base,
                               call_21626200.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626200, uri, valid, _)

proc call*(call_21626201: Call_GetIntent_21626188; name: string; version: string): Recallable =
  ## getIntent
  ## <p> Returns information about an intent. In addition to the intent name, you must specify the intent version. </p> <p> This operation requires permissions to perform the <code>lex:GetIntent</code> action. </p>
  ##   name: string (required)
  ##       : The name of the intent. The name is case sensitive. 
  ##   version: string (required)
  ##          : The version of the intent.
  var path_21626202 = newJObject()
  add(path_21626202, "name", newJString(name))
  add(path_21626202, "version", newJString(version))
  result = call_21626201.call(path_21626202, nil, nil, nil, nil)

var getIntent* = Call_GetIntent_21626188(name: "getIntent", meth: HttpMethod.HttpGet,
                                      host: "models.lex.amazonaws.com", route: "/intents/{name}/versions/{version}",
                                      validator: validate_GetIntent_21626189,
                                      base: "/", makeUrl: url_GetIntent_21626190,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntentVersion_21626203 = ref object of OpenApiRestCall_21625437
proc url_DeleteIntentVersion_21626205(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteIntentVersion_21626204(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626206 = path.getOrDefault("name")
  valid_21626206 = validateParameter(valid_21626206, JString, required = true,
                                   default = nil)
  if valid_21626206 != nil:
    section.add "name", valid_21626206
  var valid_21626207 = path.getOrDefault("version")
  valid_21626207 = validateParameter(valid_21626207, JString, required = true,
                                   default = nil)
  if valid_21626207 != nil:
    section.add "version", valid_21626207
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
  var valid_21626208 = header.getOrDefault("X-Amz-Date")
  valid_21626208 = validateParameter(valid_21626208, JString, required = false,
                                   default = nil)
  if valid_21626208 != nil:
    section.add "X-Amz-Date", valid_21626208
  var valid_21626209 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626209 = validateParameter(valid_21626209, JString, required = false,
                                   default = nil)
  if valid_21626209 != nil:
    section.add "X-Amz-Security-Token", valid_21626209
  var valid_21626210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626210 = validateParameter(valid_21626210, JString, required = false,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626210
  var valid_21626211 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626211 = validateParameter(valid_21626211, JString, required = false,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "X-Amz-Algorithm", valid_21626211
  var valid_21626212 = header.getOrDefault("X-Amz-Signature")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Signature", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Credential")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-Credential", valid_21626214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626215: Call_DeleteIntentVersion_21626203; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a specific version of an intent. To delete all versions of a intent, use the <a>DeleteIntent</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteIntentVersion</code> action.</p>
  ## 
  let valid = call_21626215.validator(path, query, header, formData, body, _)
  let scheme = call_21626215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626215.makeUrl(scheme.get, call_21626215.host, call_21626215.base,
                               call_21626215.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626215, uri, valid, _)

proc call*(call_21626216: Call_DeleteIntentVersion_21626203; name: string;
          version: string): Recallable =
  ## deleteIntentVersion
  ## <p>Deletes a specific version of an intent. To delete all versions of a intent, use the <a>DeleteIntent</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteIntentVersion</code> action.</p>
  ##   name: string (required)
  ##       : The name of the intent.
  ##   version: string (required)
  ##          : The version of the intent to delete. You cannot delete the <code>$LATEST</code> version of the intent. To delete the <code>$LATEST</code> version, use the <a>DeleteIntent</a> operation.
  var path_21626217 = newJObject()
  add(path_21626217, "name", newJString(name))
  add(path_21626217, "version", newJString(version))
  result = call_21626216.call(path_21626217, nil, nil, nil, nil)

var deleteIntentVersion* = Call_DeleteIntentVersion_21626203(
    name: "deleteIntentVersion", meth: HttpMethod.HttpDelete,
    host: "models.lex.amazonaws.com", route: "/intents/{name}/versions/{version}",
    validator: validate_DeleteIntentVersion_21626204, base: "/",
    makeUrl: url_DeleteIntentVersion_21626205,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSlotType_21626218 = ref object of OpenApiRestCall_21625437
proc url_DeleteSlotType_21626220(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteSlotType_21626219(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes all versions of the slot type, including the <code>$LATEST</code> version. To delete a specific version of the slot type, use the <a>DeleteSlotTypeVersion</a> operation.</p> <p> You can delete a version of a slot type only if it is not referenced. To delete a slot type that is referred to in one or more intents, you must remove those references first. </p> <note> <p> If you get the <code>ResourceInUseException</code> exception, the exception provides an example reference that shows the intent where the slot type is referenced. To remove the reference to the slot type, either update the intent or delete it. If you get the same exception when you attempt to delete the slot type again, repeat until the slot type has no references and the <code>DeleteSlotType</code> call is successful. </p> </note> <p>This operation requires permission for the <code>lex:DeleteSlotType</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the slot type. The name is case sensitive. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_21626221 = path.getOrDefault("name")
  valid_21626221 = validateParameter(valid_21626221, JString, required = true,
                                   default = nil)
  if valid_21626221 != nil:
    section.add "name", valid_21626221
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
  var valid_21626222 = header.getOrDefault("X-Amz-Date")
  valid_21626222 = validateParameter(valid_21626222, JString, required = false,
                                   default = nil)
  if valid_21626222 != nil:
    section.add "X-Amz-Date", valid_21626222
  var valid_21626223 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626223 = validateParameter(valid_21626223, JString, required = false,
                                   default = nil)
  if valid_21626223 != nil:
    section.add "X-Amz-Security-Token", valid_21626223
  var valid_21626224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626224 = validateParameter(valid_21626224, JString, required = false,
                                   default = nil)
  if valid_21626224 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626224
  var valid_21626225 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626225 = validateParameter(valid_21626225, JString, required = false,
                                   default = nil)
  if valid_21626225 != nil:
    section.add "X-Amz-Algorithm", valid_21626225
  var valid_21626226 = header.getOrDefault("X-Amz-Signature")
  valid_21626226 = validateParameter(valid_21626226, JString, required = false,
                                   default = nil)
  if valid_21626226 != nil:
    section.add "X-Amz-Signature", valid_21626226
  var valid_21626227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-Credential")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Credential", valid_21626228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626229: Call_DeleteSlotType_21626218; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes all versions of the slot type, including the <code>$LATEST</code> version. To delete a specific version of the slot type, use the <a>DeleteSlotTypeVersion</a> operation.</p> <p> You can delete a version of a slot type only if it is not referenced. To delete a slot type that is referred to in one or more intents, you must remove those references first. </p> <note> <p> If you get the <code>ResourceInUseException</code> exception, the exception provides an example reference that shows the intent where the slot type is referenced. To remove the reference to the slot type, either update the intent or delete it. If you get the same exception when you attempt to delete the slot type again, repeat until the slot type has no references and the <code>DeleteSlotType</code> call is successful. </p> </note> <p>This operation requires permission for the <code>lex:DeleteSlotType</code> action.</p>
  ## 
  let valid = call_21626229.validator(path, query, header, formData, body, _)
  let scheme = call_21626229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626229.makeUrl(scheme.get, call_21626229.host, call_21626229.base,
                               call_21626229.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626229, uri, valid, _)

proc call*(call_21626230: Call_DeleteSlotType_21626218; name: string): Recallable =
  ## deleteSlotType
  ## <p>Deletes all versions of the slot type, including the <code>$LATEST</code> version. To delete a specific version of the slot type, use the <a>DeleteSlotTypeVersion</a> operation.</p> <p> You can delete a version of a slot type only if it is not referenced. To delete a slot type that is referred to in one or more intents, you must remove those references first. </p> <note> <p> If you get the <code>ResourceInUseException</code> exception, the exception provides an example reference that shows the intent where the slot type is referenced. To remove the reference to the slot type, either update the intent or delete it. If you get the same exception when you attempt to delete the slot type again, repeat until the slot type has no references and the <code>DeleteSlotType</code> call is successful. </p> </note> <p>This operation requires permission for the <code>lex:DeleteSlotType</code> action.</p>
  ##   name: string (required)
  ##       : The name of the slot type. The name is case sensitive. 
  var path_21626231 = newJObject()
  add(path_21626231, "name", newJString(name))
  result = call_21626230.call(path_21626231, nil, nil, nil, nil)

var deleteSlotType* = Call_DeleteSlotType_21626218(name: "deleteSlotType",
    meth: HttpMethod.HttpDelete, host: "models.lex.amazonaws.com",
    route: "/slottypes/{name}", validator: validate_DeleteSlotType_21626219,
    base: "/", makeUrl: url_DeleteSlotType_21626220,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSlotTypeVersion_21626232 = ref object of OpenApiRestCall_21625437
proc url_DeleteSlotTypeVersion_21626234(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteSlotTypeVersion_21626233(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626235 = path.getOrDefault("name")
  valid_21626235 = validateParameter(valid_21626235, JString, required = true,
                                   default = nil)
  if valid_21626235 != nil:
    section.add "name", valid_21626235
  var valid_21626236 = path.getOrDefault("version")
  valid_21626236 = validateParameter(valid_21626236, JString, required = true,
                                   default = nil)
  if valid_21626236 != nil:
    section.add "version", valid_21626236
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
  var valid_21626237 = header.getOrDefault("X-Amz-Date")
  valid_21626237 = validateParameter(valid_21626237, JString, required = false,
                                   default = nil)
  if valid_21626237 != nil:
    section.add "X-Amz-Date", valid_21626237
  var valid_21626238 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626238 = validateParameter(valid_21626238, JString, required = false,
                                   default = nil)
  if valid_21626238 != nil:
    section.add "X-Amz-Security-Token", valid_21626238
  var valid_21626239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626239 = validateParameter(valid_21626239, JString, required = false,
                                   default = nil)
  if valid_21626239 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626239
  var valid_21626240 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626240 = validateParameter(valid_21626240, JString, required = false,
                                   default = nil)
  if valid_21626240 != nil:
    section.add "X-Amz-Algorithm", valid_21626240
  var valid_21626241 = header.getOrDefault("X-Amz-Signature")
  valid_21626241 = validateParameter(valid_21626241, JString, required = false,
                                   default = nil)
  if valid_21626241 != nil:
    section.add "X-Amz-Signature", valid_21626241
  var valid_21626242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626242 = validateParameter(valid_21626242, JString, required = false,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626242
  var valid_21626243 = header.getOrDefault("X-Amz-Credential")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "X-Amz-Credential", valid_21626243
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626244: Call_DeleteSlotTypeVersion_21626232;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a specific version of a slot type. To delete all versions of a slot type, use the <a>DeleteSlotType</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteSlotTypeVersion</code> action.</p>
  ## 
  let valid = call_21626244.validator(path, query, header, formData, body, _)
  let scheme = call_21626244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626244.makeUrl(scheme.get, call_21626244.host, call_21626244.base,
                               call_21626244.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626244, uri, valid, _)

proc call*(call_21626245: Call_DeleteSlotTypeVersion_21626232; name: string;
          version: string): Recallable =
  ## deleteSlotTypeVersion
  ## <p>Deletes a specific version of a slot type. To delete all versions of a slot type, use the <a>DeleteSlotType</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteSlotTypeVersion</code> action.</p>
  ##   name: string (required)
  ##       : The name of the slot type.
  ##   version: string (required)
  ##          : The version of the slot type to delete. You cannot delete the <code>$LATEST</code> version of the slot type. To delete the <code>$LATEST</code> version, use the <a>DeleteSlotType</a> operation.
  var path_21626246 = newJObject()
  add(path_21626246, "name", newJString(name))
  add(path_21626246, "version", newJString(version))
  result = call_21626245.call(path_21626246, nil, nil, nil, nil)

var deleteSlotTypeVersion* = Call_DeleteSlotTypeVersion_21626232(
    name: "deleteSlotTypeVersion", meth: HttpMethod.HttpDelete,
    host: "models.lex.amazonaws.com",
    route: "/slottypes/{name}/version/{version}",
    validator: validate_DeleteSlotTypeVersion_21626233, base: "/",
    makeUrl: url_DeleteSlotTypeVersion_21626234,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUtterances_21626247 = ref object of OpenApiRestCall_21625437
proc url_DeleteUtterances_21626249(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteUtterances_21626248(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626250 = path.getOrDefault("botName")
  valid_21626250 = validateParameter(valid_21626250, JString, required = true,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "botName", valid_21626250
  var valid_21626251 = path.getOrDefault("userId")
  valid_21626251 = validateParameter(valid_21626251, JString, required = true,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "userId", valid_21626251
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
  var valid_21626252 = header.getOrDefault("X-Amz-Date")
  valid_21626252 = validateParameter(valid_21626252, JString, required = false,
                                   default = nil)
  if valid_21626252 != nil:
    section.add "X-Amz-Date", valid_21626252
  var valid_21626253 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626253 = validateParameter(valid_21626253, JString, required = false,
                                   default = nil)
  if valid_21626253 != nil:
    section.add "X-Amz-Security-Token", valid_21626253
  var valid_21626254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626254 = validateParameter(valid_21626254, JString, required = false,
                                   default = nil)
  if valid_21626254 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626254
  var valid_21626255 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626255 = validateParameter(valid_21626255, JString, required = false,
                                   default = nil)
  if valid_21626255 != nil:
    section.add "X-Amz-Algorithm", valid_21626255
  var valid_21626256 = header.getOrDefault("X-Amz-Signature")
  valid_21626256 = validateParameter(valid_21626256, JString, required = false,
                                   default = nil)
  if valid_21626256 != nil:
    section.add "X-Amz-Signature", valid_21626256
  var valid_21626257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626257 = validateParameter(valid_21626257, JString, required = false,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626257
  var valid_21626258 = header.getOrDefault("X-Amz-Credential")
  valid_21626258 = validateParameter(valid_21626258, JString, required = false,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "X-Amz-Credential", valid_21626258
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626259: Call_DeleteUtterances_21626247; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes stored utterances.</p> <p>Amazon Lex stores the utterances that users send to your bot. Utterances are stored for 15 days for use with the <a>GetUtterancesView</a> operation, and then stored indefinitely for use in improving the ability of your bot to respond to user input.</p> <p>Use the <code>DeleteUtterances</code> operation to manually delete stored utterances for a specific user. When you use the <code>DeleteUtterances</code> operation, utterances stored for improving your bot's ability to respond to user input are deleted immediately. Utterances stored for use with the <code>GetUtterancesView</code> operation are deleted after 15 days.</p> <p>This operation requires permissions for the <code>lex:DeleteUtterances</code> action.</p>
  ## 
  let valid = call_21626259.validator(path, query, header, formData, body, _)
  let scheme = call_21626259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626259.makeUrl(scheme.get, call_21626259.host, call_21626259.base,
                               call_21626259.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626259, uri, valid, _)

proc call*(call_21626260: Call_DeleteUtterances_21626247; botName: string;
          userId: string): Recallable =
  ## deleteUtterances
  ## <p>Deletes stored utterances.</p> <p>Amazon Lex stores the utterances that users send to your bot. Utterances are stored for 15 days for use with the <a>GetUtterancesView</a> operation, and then stored indefinitely for use in improving the ability of your bot to respond to user input.</p> <p>Use the <code>DeleteUtterances</code> operation to manually delete stored utterances for a specific user. When you use the <code>DeleteUtterances</code> operation, utterances stored for improving your bot's ability to respond to user input are deleted immediately. Utterances stored for use with the <code>GetUtterancesView</code> operation are deleted after 15 days.</p> <p>This operation requires permissions for the <code>lex:DeleteUtterances</code> action.</p>
  ##   botName: string (required)
  ##          : The name of the bot that stored the utterances.
  ##   userId: string (required)
  ##         :  The unique identifier for the user that made the utterances. This is the user ID that was sent in the <a 
  ## href="http://docs.aws.amazon.com/lex/latest/dg/API_runtime_PostContent.html">PostContent</a> or <a 
  ## href="http://docs.aws.amazon.com/lex/latest/dg/API_runtime_PostText.html">PostText</a> operation request that contained the utterance.
  var path_21626261 = newJObject()
  add(path_21626261, "botName", newJString(botName))
  add(path_21626261, "userId", newJString(userId))
  result = call_21626260.call(path_21626261, nil, nil, nil, nil)

var deleteUtterances* = Call_DeleteUtterances_21626247(name: "deleteUtterances",
    meth: HttpMethod.HttpDelete, host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/utterances/{userId}",
    validator: validate_DeleteUtterances_21626248, base: "/",
    makeUrl: url_DeleteUtterances_21626249, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBot_21626262 = ref object of OpenApiRestCall_21625437
proc url_GetBot_21626264(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBot_21626263(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626265 = path.getOrDefault("versionoralias")
  valid_21626265 = validateParameter(valid_21626265, JString, required = true,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "versionoralias", valid_21626265
  var valid_21626266 = path.getOrDefault("name")
  valid_21626266 = validateParameter(valid_21626266, JString, required = true,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "name", valid_21626266
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
  var valid_21626267 = header.getOrDefault("X-Amz-Date")
  valid_21626267 = validateParameter(valid_21626267, JString, required = false,
                                   default = nil)
  if valid_21626267 != nil:
    section.add "X-Amz-Date", valid_21626267
  var valid_21626268 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626268 = validateParameter(valid_21626268, JString, required = false,
                                   default = nil)
  if valid_21626268 != nil:
    section.add "X-Amz-Security-Token", valid_21626268
  var valid_21626269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626269 = validateParameter(valid_21626269, JString, required = false,
                                   default = nil)
  if valid_21626269 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626269
  var valid_21626270 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626270 = validateParameter(valid_21626270, JString, required = false,
                                   default = nil)
  if valid_21626270 != nil:
    section.add "X-Amz-Algorithm", valid_21626270
  var valid_21626271 = header.getOrDefault("X-Amz-Signature")
  valid_21626271 = validateParameter(valid_21626271, JString, required = false,
                                   default = nil)
  if valid_21626271 != nil:
    section.add "X-Amz-Signature", valid_21626271
  var valid_21626272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626272
  var valid_21626273 = header.getOrDefault("X-Amz-Credential")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "X-Amz-Credential", valid_21626273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626274: Call_GetBot_21626262; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns metadata information for a specific bot. You must provide the bot name and the bot version or alias. </p> <p> This operation requires permissions for the <code>lex:GetBot</code> action. </p>
  ## 
  let valid = call_21626274.validator(path, query, header, formData, body, _)
  let scheme = call_21626274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626274.makeUrl(scheme.get, call_21626274.host, call_21626274.base,
                               call_21626274.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626274, uri, valid, _)

proc call*(call_21626275: Call_GetBot_21626262; versionoralias: string; name: string): Recallable =
  ## getBot
  ## <p>Returns metadata information for a specific bot. You must provide the bot name and the bot version or alias. </p> <p> This operation requires permissions for the <code>lex:GetBot</code> action. </p>
  ##   versionoralias: string (required)
  ##                 : The version or alias of the bot.
  ##   name: string (required)
  ##       : The name of the bot. The name is case sensitive. 
  var path_21626276 = newJObject()
  add(path_21626276, "versionoralias", newJString(versionoralias))
  add(path_21626276, "name", newJString(name))
  result = call_21626275.call(path_21626276, nil, nil, nil, nil)

var getBot* = Call_GetBot_21626262(name: "getBot", meth: HttpMethod.HttpGet,
                                host: "models.lex.amazonaws.com", route: "/bots/{name}/versions/{versionoralias}",
                                validator: validate_GetBot_21626263, base: "/",
                                makeUrl: url_GetBot_21626264,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBotAliases_21626277 = ref object of OpenApiRestCall_21625437
proc url_GetBotAliases_21626279(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBotAliases_21626278(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Returns a list of aliases for a specified Amazon Lex bot.</p> <p>This operation requires permissions for the <code>lex:GetBotAliases</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   botName: JString (required)
  ##          : The name of the bot.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `botName` field"
  var valid_21626280 = path.getOrDefault("botName")
  valid_21626280 = validateParameter(valid_21626280, JString, required = true,
                                   default = nil)
  if valid_21626280 != nil:
    section.add "botName", valid_21626280
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of aliases to return in the response. The default is 50. . 
  ##   nextToken: JString
  ##            : A pagination token for fetching the next page of aliases. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of aliases, specify the pagination token in the next request. 
  ##   nameContains: JString
  ##               : Substring to match in bot alias names. An alias will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  section = newJObject()
  var valid_21626281 = query.getOrDefault("maxResults")
  valid_21626281 = validateParameter(valid_21626281, JInt, required = false,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "maxResults", valid_21626281
  var valid_21626282 = query.getOrDefault("nextToken")
  valid_21626282 = validateParameter(valid_21626282, JString, required = false,
                                   default = nil)
  if valid_21626282 != nil:
    section.add "nextToken", valid_21626282
  var valid_21626283 = query.getOrDefault("nameContains")
  valid_21626283 = validateParameter(valid_21626283, JString, required = false,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "nameContains", valid_21626283
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
  var valid_21626284 = header.getOrDefault("X-Amz-Date")
  valid_21626284 = validateParameter(valid_21626284, JString, required = false,
                                   default = nil)
  if valid_21626284 != nil:
    section.add "X-Amz-Date", valid_21626284
  var valid_21626285 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626285 = validateParameter(valid_21626285, JString, required = false,
                                   default = nil)
  if valid_21626285 != nil:
    section.add "X-Amz-Security-Token", valid_21626285
  var valid_21626286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626286 = validateParameter(valid_21626286, JString, required = false,
                                   default = nil)
  if valid_21626286 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626286
  var valid_21626287 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626287 = validateParameter(valid_21626287, JString, required = false,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "X-Amz-Algorithm", valid_21626287
  var valid_21626288 = header.getOrDefault("X-Amz-Signature")
  valid_21626288 = validateParameter(valid_21626288, JString, required = false,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "X-Amz-Signature", valid_21626288
  var valid_21626289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626289 = validateParameter(valid_21626289, JString, required = false,
                                   default = nil)
  if valid_21626289 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626289
  var valid_21626290 = header.getOrDefault("X-Amz-Credential")
  valid_21626290 = validateParameter(valid_21626290, JString, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "X-Amz-Credential", valid_21626290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626291: Call_GetBotAliases_21626277; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of aliases for a specified Amazon Lex bot.</p> <p>This operation requires permissions for the <code>lex:GetBotAliases</code> action.</p>
  ## 
  let valid = call_21626291.validator(path, query, header, formData, body, _)
  let scheme = call_21626291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626291.makeUrl(scheme.get, call_21626291.host, call_21626291.base,
                               call_21626291.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626291, uri, valid, _)

proc call*(call_21626292: Call_GetBotAliases_21626277; botName: string;
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
  var path_21626293 = newJObject()
  var query_21626294 = newJObject()
  add(query_21626294, "maxResults", newJInt(maxResults))
  add(query_21626294, "nextToken", newJString(nextToken))
  add(path_21626293, "botName", newJString(botName))
  add(query_21626294, "nameContains", newJString(nameContains))
  result = call_21626292.call(path_21626293, query_21626294, nil, nil, nil)

var getBotAliases* = Call_GetBotAliases_21626277(name: "getBotAliases",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/aliases/", validator: validate_GetBotAliases_21626278,
    base: "/", makeUrl: url_GetBotAliases_21626279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBotChannelAssociations_21626296 = ref object of OpenApiRestCall_21625437
proc url_GetBotChannelAssociations_21626298(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBotChannelAssociations_21626297(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626299 = path.getOrDefault("botName")
  valid_21626299 = validateParameter(valid_21626299, JString, required = true,
                                   default = nil)
  if valid_21626299 != nil:
    section.add "botName", valid_21626299
  var valid_21626300 = path.getOrDefault("aliasName")
  valid_21626300 = validateParameter(valid_21626300, JString, required = true,
                                   default = nil)
  if valid_21626300 != nil:
    section.add "aliasName", valid_21626300
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of associations to return in the response. The default is 50. 
  ##   nextToken: JString
  ##            : A pagination token for fetching the next page of associations. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of associations, specify the pagination token in the next request. 
  ##   nameContains: JString
  ##               : Substring to match in channel association names. An association will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz." To return all bot channel associations, use a hyphen ("-") as the <code>nameContains</code> parameter.
  section = newJObject()
  var valid_21626301 = query.getOrDefault("maxResults")
  valid_21626301 = validateParameter(valid_21626301, JInt, required = false,
                                   default = nil)
  if valid_21626301 != nil:
    section.add "maxResults", valid_21626301
  var valid_21626302 = query.getOrDefault("nextToken")
  valid_21626302 = validateParameter(valid_21626302, JString, required = false,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "nextToken", valid_21626302
  var valid_21626303 = query.getOrDefault("nameContains")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "nameContains", valid_21626303
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
  var valid_21626304 = header.getOrDefault("X-Amz-Date")
  valid_21626304 = validateParameter(valid_21626304, JString, required = false,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "X-Amz-Date", valid_21626304
  var valid_21626305 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626305 = validateParameter(valid_21626305, JString, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "X-Amz-Security-Token", valid_21626305
  var valid_21626306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626306 = validateParameter(valid_21626306, JString, required = false,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626306
  var valid_21626307 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "X-Amz-Algorithm", valid_21626307
  var valid_21626308 = header.getOrDefault("X-Amz-Signature")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "X-Amz-Signature", valid_21626308
  var valid_21626309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626309
  var valid_21626310 = header.getOrDefault("X-Amz-Credential")
  valid_21626310 = validateParameter(valid_21626310, JString, required = false,
                                   default = nil)
  if valid_21626310 != nil:
    section.add "X-Amz-Credential", valid_21626310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626311: Call_GetBotChannelAssociations_21626296;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> Returns a list of all of the channels associated with the specified bot. </p> <p>The <code>GetBotChannelAssociations</code> operation requires permissions for the <code>lex:GetBotChannelAssociations</code> action.</p>
  ## 
  let valid = call_21626311.validator(path, query, header, formData, body, _)
  let scheme = call_21626311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626311.makeUrl(scheme.get, call_21626311.host, call_21626311.base,
                               call_21626311.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626311, uri, valid, _)

proc call*(call_21626312: Call_GetBotChannelAssociations_21626296; botName: string;
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
  var path_21626313 = newJObject()
  var query_21626314 = newJObject()
  add(query_21626314, "maxResults", newJInt(maxResults))
  add(query_21626314, "nextToken", newJString(nextToken))
  add(path_21626313, "botName", newJString(botName))
  add(query_21626314, "nameContains", newJString(nameContains))
  add(path_21626313, "aliasName", newJString(aliasName))
  result = call_21626312.call(path_21626313, query_21626314, nil, nil, nil)

var getBotChannelAssociations* = Call_GetBotChannelAssociations_21626296(
    name: "getBotChannelAssociations", meth: HttpMethod.HttpGet,
    host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/aliases/{aliasName}/channels/",
    validator: validate_GetBotChannelAssociations_21626297, base: "/",
    makeUrl: url_GetBotChannelAssociations_21626298,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBotVersions_21626315 = ref object of OpenApiRestCall_21625437
proc url_GetBotVersions_21626317(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBotVersions_21626316(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Gets information about all of the versions of a bot.</p> <p>The <code>GetBotVersions</code> operation returns a <code>BotMetadata</code> object for each version of a bot. For example, if a bot has three numbered versions, the <code>GetBotVersions</code> operation returns four <code>BotMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetBotVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetBotVersions</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the bot for which versions should be returned.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_21626318 = path.getOrDefault("name")
  valid_21626318 = validateParameter(valid_21626318, JString, required = true,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "name", valid_21626318
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of bot versions to return in the response. The default is 10.
  ##   nextToken: JString
  ##            : A pagination token for fetching the next page of bot versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  section = newJObject()
  var valid_21626319 = query.getOrDefault("maxResults")
  valid_21626319 = validateParameter(valid_21626319, JInt, required = false,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "maxResults", valid_21626319
  var valid_21626320 = query.getOrDefault("nextToken")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "nextToken", valid_21626320
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
  var valid_21626321 = header.getOrDefault("X-Amz-Date")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "X-Amz-Date", valid_21626321
  var valid_21626322 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "X-Amz-Security-Token", valid_21626322
  var valid_21626323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626323 = validateParameter(valid_21626323, JString, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626323
  var valid_21626324 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-Algorithm", valid_21626324
  var valid_21626325 = header.getOrDefault("X-Amz-Signature")
  valid_21626325 = validateParameter(valid_21626325, JString, required = false,
                                   default = nil)
  if valid_21626325 != nil:
    section.add "X-Amz-Signature", valid_21626325
  var valid_21626326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626326 = validateParameter(valid_21626326, JString, required = false,
                                   default = nil)
  if valid_21626326 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626326
  var valid_21626327 = header.getOrDefault("X-Amz-Credential")
  valid_21626327 = validateParameter(valid_21626327, JString, required = false,
                                   default = nil)
  if valid_21626327 != nil:
    section.add "X-Amz-Credential", valid_21626327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626328: Call_GetBotVersions_21626315; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets information about all of the versions of a bot.</p> <p>The <code>GetBotVersions</code> operation returns a <code>BotMetadata</code> object for each version of a bot. For example, if a bot has three numbered versions, the <code>GetBotVersions</code> operation returns four <code>BotMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetBotVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetBotVersions</code> action.</p>
  ## 
  let valid = call_21626328.validator(path, query, header, formData, body, _)
  let scheme = call_21626328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626328.makeUrl(scheme.get, call_21626328.host, call_21626328.base,
                               call_21626328.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626328, uri, valid, _)

proc call*(call_21626329: Call_GetBotVersions_21626315; name: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## getBotVersions
  ## <p>Gets information about all of the versions of a bot.</p> <p>The <code>GetBotVersions</code> operation returns a <code>BotMetadata</code> object for each version of a bot. For example, if a bot has three numbered versions, the <code>GetBotVersions</code> operation returns four <code>BotMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetBotVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetBotVersions</code> action.</p>
  ##   name: string (required)
  ##       : The name of the bot for which versions should be returned.
  ##   maxResults: int
  ##             : The maximum number of bot versions to return in the response. The default is 10.
  ##   nextToken: string
  ##            : A pagination token for fetching the next page of bot versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  var path_21626330 = newJObject()
  var query_21626331 = newJObject()
  add(path_21626330, "name", newJString(name))
  add(query_21626331, "maxResults", newJInt(maxResults))
  add(query_21626331, "nextToken", newJString(nextToken))
  result = call_21626329.call(path_21626330, query_21626331, nil, nil, nil)

var getBotVersions* = Call_GetBotVersions_21626315(name: "getBotVersions",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/bots/{name}/versions/", validator: validate_GetBotVersions_21626316,
    base: "/", makeUrl: url_GetBotVersions_21626317,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBots_21626332 = ref object of OpenApiRestCall_21625437
proc url_GetBots_21626334(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBots_21626333(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626335 = query.getOrDefault("maxResults")
  valid_21626335 = validateParameter(valid_21626335, JInt, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "maxResults", valid_21626335
  var valid_21626336 = query.getOrDefault("nextToken")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "nextToken", valid_21626336
  var valid_21626337 = query.getOrDefault("nameContains")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "nameContains", valid_21626337
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
  var valid_21626338 = header.getOrDefault("X-Amz-Date")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-Date", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Security-Token", valid_21626339
  var valid_21626340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626340 = validateParameter(valid_21626340, JString, required = false,
                                   default = nil)
  if valid_21626340 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626340
  var valid_21626341 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626341 = validateParameter(valid_21626341, JString, required = false,
                                   default = nil)
  if valid_21626341 != nil:
    section.add "X-Amz-Algorithm", valid_21626341
  var valid_21626342 = header.getOrDefault("X-Amz-Signature")
  valid_21626342 = validateParameter(valid_21626342, JString, required = false,
                                   default = nil)
  if valid_21626342 != nil:
    section.add "X-Amz-Signature", valid_21626342
  var valid_21626343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626343 = validateParameter(valid_21626343, JString, required = false,
                                   default = nil)
  if valid_21626343 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626343
  var valid_21626344 = header.getOrDefault("X-Amz-Credential")
  valid_21626344 = validateParameter(valid_21626344, JString, required = false,
                                   default = nil)
  if valid_21626344 != nil:
    section.add "X-Amz-Credential", valid_21626344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626345: Call_GetBots_21626332; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns bot information as follows: </p> <ul> <li> <p>If you provide the <code>nameContains</code> field, the response includes information for the <code>$LATEST</code> version of all bots whose name contains the specified string.</p> </li> <li> <p>If you don't specify the <code>nameContains</code> field, the operation returns information about the <code>$LATEST</code> version of all of your bots.</p> </li> </ul> <p>This operation requires permission for the <code>lex:GetBots</code> action.</p>
  ## 
  let valid = call_21626345.validator(path, query, header, formData, body, _)
  let scheme = call_21626345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626345.makeUrl(scheme.get, call_21626345.host, call_21626345.base,
                               call_21626345.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626345, uri, valid, _)

proc call*(call_21626346: Call_GetBots_21626332; maxResults: int = 0;
          nextToken: string = ""; nameContains: string = ""): Recallable =
  ## getBots
  ## <p>Returns bot information as follows: </p> <ul> <li> <p>If you provide the <code>nameContains</code> field, the response includes information for the <code>$LATEST</code> version of all bots whose name contains the specified string.</p> </li> <li> <p>If you don't specify the <code>nameContains</code> field, the operation returns information about the <code>$LATEST</code> version of all of your bots.</p> </li> </ul> <p>This operation requires permission for the <code>lex:GetBots</code> action.</p>
  ##   maxResults: int
  ##             : The maximum number of bots to return in the response that the request will return. The default is 10.
  ##   nextToken: string
  ##            : A pagination token that fetches the next page of bots. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of bots, specify the pagination token in the next request. 
  ##   nameContains: string
  ##               : Substring to match in bot names. A bot will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  var query_21626347 = newJObject()
  add(query_21626347, "maxResults", newJInt(maxResults))
  add(query_21626347, "nextToken", newJString(nextToken))
  add(query_21626347, "nameContains", newJString(nameContains))
  result = call_21626346.call(nil, query_21626347, nil, nil, nil)

var getBots* = Call_GetBots_21626332(name: "getBots", meth: HttpMethod.HttpGet,
                                  host: "models.lex.amazonaws.com",
                                  route: "/bots/", validator: validate_GetBots_21626333,
                                  base: "/", makeUrl: url_GetBots_21626334,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBuiltinIntent_21626348 = ref object of OpenApiRestCall_21625437
proc url_GetBuiltinIntent_21626350(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetBuiltinIntent_21626349(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626351 = path.getOrDefault("signature")
  valid_21626351 = validateParameter(valid_21626351, JString, required = true,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "signature", valid_21626351
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
  var valid_21626352 = header.getOrDefault("X-Amz-Date")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Date", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-Security-Token", valid_21626353
  var valid_21626354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626354 = validateParameter(valid_21626354, JString, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626354
  var valid_21626355 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626355 = validateParameter(valid_21626355, JString, required = false,
                                   default = nil)
  if valid_21626355 != nil:
    section.add "X-Amz-Algorithm", valid_21626355
  var valid_21626356 = header.getOrDefault("X-Amz-Signature")
  valid_21626356 = validateParameter(valid_21626356, JString, required = false,
                                   default = nil)
  if valid_21626356 != nil:
    section.add "X-Amz-Signature", valid_21626356
  var valid_21626357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626357 = validateParameter(valid_21626357, JString, required = false,
                                   default = nil)
  if valid_21626357 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626357
  var valid_21626358 = header.getOrDefault("X-Amz-Credential")
  valid_21626358 = validateParameter(valid_21626358, JString, required = false,
                                   default = nil)
  if valid_21626358 != nil:
    section.add "X-Amz-Credential", valid_21626358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626359: Call_GetBuiltinIntent_21626348; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns information about a built-in intent.</p> <p>This operation requires permission for the <code>lex:GetBuiltinIntent</code> action.</p>
  ## 
  let valid = call_21626359.validator(path, query, header, formData, body, _)
  let scheme = call_21626359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626359.makeUrl(scheme.get, call_21626359.host, call_21626359.base,
                               call_21626359.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626359, uri, valid, _)

proc call*(call_21626360: Call_GetBuiltinIntent_21626348; signature: string): Recallable =
  ## getBuiltinIntent
  ## <p>Returns information about a built-in intent.</p> <p>This operation requires permission for the <code>lex:GetBuiltinIntent</code> action.</p>
  ##   signature: string (required)
  ##            : The unique identifier for a built-in intent. To find the signature for an intent, see <a 
  ## href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/standard-intents">Standard Built-in Intents</a> in the <i>Alexa Skills Kit</i>.
  var path_21626361 = newJObject()
  add(path_21626361, "signature", newJString(signature))
  result = call_21626360.call(path_21626361, nil, nil, nil, nil)

var getBuiltinIntent* = Call_GetBuiltinIntent_21626348(name: "getBuiltinIntent",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/builtins/intents/{signature}", validator: validate_GetBuiltinIntent_21626349,
    base: "/", makeUrl: url_GetBuiltinIntent_21626350,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBuiltinIntents_21626362 = ref object of OpenApiRestCall_21625437
proc url_GetBuiltinIntents_21626364(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBuiltinIntents_21626363(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626379 = query.getOrDefault("locale")
  valid_21626379 = validateParameter(valid_21626379, JString, required = false,
                                   default = newJString("en-US"))
  if valid_21626379 != nil:
    section.add "locale", valid_21626379
  var valid_21626380 = query.getOrDefault("maxResults")
  valid_21626380 = validateParameter(valid_21626380, JInt, required = false,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "maxResults", valid_21626380
  var valid_21626381 = query.getOrDefault("nextToken")
  valid_21626381 = validateParameter(valid_21626381, JString, required = false,
                                   default = nil)
  if valid_21626381 != nil:
    section.add "nextToken", valid_21626381
  var valid_21626382 = query.getOrDefault("signatureContains")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "signatureContains", valid_21626382
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
  var valid_21626383 = header.getOrDefault("X-Amz-Date")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "X-Amz-Date", valid_21626383
  var valid_21626384 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Security-Token", valid_21626384
  var valid_21626385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626385 = validateParameter(valid_21626385, JString, required = false,
                                   default = nil)
  if valid_21626385 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626385
  var valid_21626386 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626386 = validateParameter(valid_21626386, JString, required = false,
                                   default = nil)
  if valid_21626386 != nil:
    section.add "X-Amz-Algorithm", valid_21626386
  var valid_21626387 = header.getOrDefault("X-Amz-Signature")
  valid_21626387 = validateParameter(valid_21626387, JString, required = false,
                                   default = nil)
  if valid_21626387 != nil:
    section.add "X-Amz-Signature", valid_21626387
  var valid_21626388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626388 = validateParameter(valid_21626388, JString, required = false,
                                   default = nil)
  if valid_21626388 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626388
  var valid_21626389 = header.getOrDefault("X-Amz-Credential")
  valid_21626389 = validateParameter(valid_21626389, JString, required = false,
                                   default = nil)
  if valid_21626389 != nil:
    section.add "X-Amz-Credential", valid_21626389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626390: Call_GetBuiltinIntents_21626362; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets a list of built-in intents that meet the specified criteria.</p> <p>This operation requires permission for the <code>lex:GetBuiltinIntents</code> action.</p>
  ## 
  let valid = call_21626390.validator(path, query, header, formData, body, _)
  let scheme = call_21626390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626390.makeUrl(scheme.get, call_21626390.host, call_21626390.base,
                               call_21626390.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626390, uri, valid, _)

proc call*(call_21626391: Call_GetBuiltinIntents_21626362;
          locale: string = "en-US"; maxResults: int = 0; nextToken: string = "";
          signatureContains: string = ""): Recallable =
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
  var query_21626392 = newJObject()
  add(query_21626392, "locale", newJString(locale))
  add(query_21626392, "maxResults", newJInt(maxResults))
  add(query_21626392, "nextToken", newJString(nextToken))
  add(query_21626392, "signatureContains", newJString(signatureContains))
  result = call_21626391.call(nil, query_21626392, nil, nil, nil)

var getBuiltinIntents* = Call_GetBuiltinIntents_21626362(name: "getBuiltinIntents",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/builtins/intents/", validator: validate_GetBuiltinIntents_21626363,
    base: "/", makeUrl: url_GetBuiltinIntents_21626364,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBuiltinSlotTypes_21626394 = ref object of OpenApiRestCall_21625437
proc url_GetBuiltinSlotTypes_21626396(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetBuiltinSlotTypes_21626395(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626397 = query.getOrDefault("locale")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = newJString("en-US"))
  if valid_21626397 != nil:
    section.add "locale", valid_21626397
  var valid_21626398 = query.getOrDefault("maxResults")
  valid_21626398 = validateParameter(valid_21626398, JInt, required = false,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "maxResults", valid_21626398
  var valid_21626399 = query.getOrDefault("nextToken")
  valid_21626399 = validateParameter(valid_21626399, JString, required = false,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "nextToken", valid_21626399
  var valid_21626400 = query.getOrDefault("signatureContains")
  valid_21626400 = validateParameter(valid_21626400, JString, required = false,
                                   default = nil)
  if valid_21626400 != nil:
    section.add "signatureContains", valid_21626400
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
  var valid_21626401 = header.getOrDefault("X-Amz-Date")
  valid_21626401 = validateParameter(valid_21626401, JString, required = false,
                                   default = nil)
  if valid_21626401 != nil:
    section.add "X-Amz-Date", valid_21626401
  var valid_21626402 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626402 = validateParameter(valid_21626402, JString, required = false,
                                   default = nil)
  if valid_21626402 != nil:
    section.add "X-Amz-Security-Token", valid_21626402
  var valid_21626403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626403 = validateParameter(valid_21626403, JString, required = false,
                                   default = nil)
  if valid_21626403 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626403
  var valid_21626404 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626404 = validateParameter(valid_21626404, JString, required = false,
                                   default = nil)
  if valid_21626404 != nil:
    section.add "X-Amz-Algorithm", valid_21626404
  var valid_21626405 = header.getOrDefault("X-Amz-Signature")
  valid_21626405 = validateParameter(valid_21626405, JString, required = false,
                                   default = nil)
  if valid_21626405 != nil:
    section.add "X-Amz-Signature", valid_21626405
  var valid_21626406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626406 = validateParameter(valid_21626406, JString, required = false,
                                   default = nil)
  if valid_21626406 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626406
  var valid_21626407 = header.getOrDefault("X-Amz-Credential")
  valid_21626407 = validateParameter(valid_21626407, JString, required = false,
                                   default = nil)
  if valid_21626407 != nil:
    section.add "X-Amz-Credential", valid_21626407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626408: Call_GetBuiltinSlotTypes_21626394; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets a list of built-in slot types that meet the specified criteria.</p> <p>For a list of built-in slot types, see <a href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/slot-type-reference">Slot Type Reference</a> in the <i>Alexa Skills Kit</i>.</p> <p>This operation requires permission for the <code>lex:GetBuiltInSlotTypes</code> action.</p>
  ## 
  let valid = call_21626408.validator(path, query, header, formData, body, _)
  let scheme = call_21626408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626408.makeUrl(scheme.get, call_21626408.host, call_21626408.base,
                               call_21626408.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626408, uri, valid, _)

proc call*(call_21626409: Call_GetBuiltinSlotTypes_21626394;
          locale: string = "en-US"; maxResults: int = 0; nextToken: string = "";
          signatureContains: string = ""): Recallable =
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
  var query_21626410 = newJObject()
  add(query_21626410, "locale", newJString(locale))
  add(query_21626410, "maxResults", newJInt(maxResults))
  add(query_21626410, "nextToken", newJString(nextToken))
  add(query_21626410, "signatureContains", newJString(signatureContains))
  result = call_21626409.call(nil, query_21626410, nil, nil, nil)

var getBuiltinSlotTypes* = Call_GetBuiltinSlotTypes_21626394(
    name: "getBuiltinSlotTypes", meth: HttpMethod.HttpGet,
    host: "models.lex.amazonaws.com", route: "/builtins/slottypes/",
    validator: validate_GetBuiltinSlotTypes_21626395, base: "/",
    makeUrl: url_GetBuiltinSlotTypes_21626396,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExport_21626411 = ref object of OpenApiRestCall_21625437
proc url_GetExport_21626413(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetExport_21626412(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626414 = query.getOrDefault("exportType")
  valid_21626414 = validateParameter(valid_21626414, JString, required = true,
                                   default = newJString("ALEXA_SKILLS_KIT"))
  if valid_21626414 != nil:
    section.add "exportType", valid_21626414
  var valid_21626415 = query.getOrDefault("name")
  valid_21626415 = validateParameter(valid_21626415, JString, required = true,
                                   default = nil)
  if valid_21626415 != nil:
    section.add "name", valid_21626415
  var valid_21626416 = query.getOrDefault("version")
  valid_21626416 = validateParameter(valid_21626416, JString, required = true,
                                   default = nil)
  if valid_21626416 != nil:
    section.add "version", valid_21626416
  var valid_21626417 = query.getOrDefault("resourceType")
  valid_21626417 = validateParameter(valid_21626417, JString, required = true,
                                   default = newJString("BOT"))
  if valid_21626417 != nil:
    section.add "resourceType", valid_21626417
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
  var valid_21626418 = header.getOrDefault("X-Amz-Date")
  valid_21626418 = validateParameter(valid_21626418, JString, required = false,
                                   default = nil)
  if valid_21626418 != nil:
    section.add "X-Amz-Date", valid_21626418
  var valid_21626419 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626419 = validateParameter(valid_21626419, JString, required = false,
                                   default = nil)
  if valid_21626419 != nil:
    section.add "X-Amz-Security-Token", valid_21626419
  var valid_21626420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626420 = validateParameter(valid_21626420, JString, required = false,
                                   default = nil)
  if valid_21626420 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626420
  var valid_21626421 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626421 = validateParameter(valid_21626421, JString, required = false,
                                   default = nil)
  if valid_21626421 != nil:
    section.add "X-Amz-Algorithm", valid_21626421
  var valid_21626422 = header.getOrDefault("X-Amz-Signature")
  valid_21626422 = validateParameter(valid_21626422, JString, required = false,
                                   default = nil)
  if valid_21626422 != nil:
    section.add "X-Amz-Signature", valid_21626422
  var valid_21626423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626423 = validateParameter(valid_21626423, JString, required = false,
                                   default = nil)
  if valid_21626423 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626423
  var valid_21626424 = header.getOrDefault("X-Amz-Credential")
  valid_21626424 = validateParameter(valid_21626424, JString, required = false,
                                   default = nil)
  if valid_21626424 != nil:
    section.add "X-Amz-Credential", valid_21626424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626425: Call_GetExport_21626411; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Exports the contents of a Amazon Lex resource in a specified format. 
  ## 
  let valid = call_21626425.validator(path, query, header, formData, body, _)
  let scheme = call_21626425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626425.makeUrl(scheme.get, call_21626425.host, call_21626425.base,
                               call_21626425.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626425, uri, valid, _)

proc call*(call_21626426: Call_GetExport_21626411; name: string; version: string;
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
  var query_21626427 = newJObject()
  add(query_21626427, "exportType", newJString(exportType))
  add(query_21626427, "name", newJString(name))
  add(query_21626427, "version", newJString(version))
  add(query_21626427, "resourceType", newJString(resourceType))
  result = call_21626426.call(nil, query_21626427, nil, nil, nil)

var getExport* = Call_GetExport_21626411(name: "getExport", meth: HttpMethod.HttpGet,
                                      host: "models.lex.amazonaws.com", route: "/exports/#name&version&resourceType&exportType",
                                      validator: validate_GetExport_21626412,
                                      base: "/", makeUrl: url_GetExport_21626413,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImport_21626428 = ref object of OpenApiRestCall_21625437
proc url_GetImport_21626430(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetImport_21626429(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets information about an import job started with the <code>StartImport</code> operation.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   importId: JString (required)
  ##           : The identifier of the import job information to return.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `importId` field"
  var valid_21626431 = path.getOrDefault("importId")
  valid_21626431 = validateParameter(valid_21626431, JString, required = true,
                                   default = nil)
  if valid_21626431 != nil:
    section.add "importId", valid_21626431
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
  var valid_21626432 = header.getOrDefault("X-Amz-Date")
  valid_21626432 = validateParameter(valid_21626432, JString, required = false,
                                   default = nil)
  if valid_21626432 != nil:
    section.add "X-Amz-Date", valid_21626432
  var valid_21626433 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626433 = validateParameter(valid_21626433, JString, required = false,
                                   default = nil)
  if valid_21626433 != nil:
    section.add "X-Amz-Security-Token", valid_21626433
  var valid_21626434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626434 = validateParameter(valid_21626434, JString, required = false,
                                   default = nil)
  if valid_21626434 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626434
  var valid_21626435 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626435 = validateParameter(valid_21626435, JString, required = false,
                                   default = nil)
  if valid_21626435 != nil:
    section.add "X-Amz-Algorithm", valid_21626435
  var valid_21626436 = header.getOrDefault("X-Amz-Signature")
  valid_21626436 = validateParameter(valid_21626436, JString, required = false,
                                   default = nil)
  if valid_21626436 != nil:
    section.add "X-Amz-Signature", valid_21626436
  var valid_21626437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626437 = validateParameter(valid_21626437, JString, required = false,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626437
  var valid_21626438 = header.getOrDefault("X-Amz-Credential")
  valid_21626438 = validateParameter(valid_21626438, JString, required = false,
                                   default = nil)
  if valid_21626438 != nil:
    section.add "X-Amz-Credential", valid_21626438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626439: Call_GetImport_21626428; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about an import job started with the <code>StartImport</code> operation.
  ## 
  let valid = call_21626439.validator(path, query, header, formData, body, _)
  let scheme = call_21626439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626439.makeUrl(scheme.get, call_21626439.host, call_21626439.base,
                               call_21626439.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626439, uri, valid, _)

proc call*(call_21626440: Call_GetImport_21626428; importId: string): Recallable =
  ## getImport
  ## Gets information about an import job started with the <code>StartImport</code> operation.
  ##   importId: string (required)
  ##           : The identifier of the import job information to return.
  var path_21626441 = newJObject()
  add(path_21626441, "importId", newJString(importId))
  result = call_21626440.call(path_21626441, nil, nil, nil, nil)

var getImport* = Call_GetImport_21626428(name: "getImport", meth: HttpMethod.HttpGet,
                                      host: "models.lex.amazonaws.com",
                                      route: "/imports/{importId}",
                                      validator: validate_GetImport_21626429,
                                      base: "/", makeUrl: url_GetImport_21626430,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntentVersions_21626442 = ref object of OpenApiRestCall_21625437
proc url_GetIntentVersions_21626444(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetIntentVersions_21626443(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Gets information about all of the versions of an intent.</p> <p>The <code>GetIntentVersions</code> operation returns an <code>IntentMetadata</code> object for each version of an intent. For example, if an intent has three numbered versions, the <code>GetIntentVersions</code> operation returns four <code>IntentMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetIntentVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetIntentVersions</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the intent for which versions should be returned.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_21626445 = path.getOrDefault("name")
  valid_21626445 = validateParameter(valid_21626445, JString, required = true,
                                   default = nil)
  if valid_21626445 != nil:
    section.add "name", valid_21626445
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of intent versions to return in the response. The default is 10.
  ##   nextToken: JString
  ##            : A pagination token for fetching the next page of intent versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  section = newJObject()
  var valid_21626446 = query.getOrDefault("maxResults")
  valid_21626446 = validateParameter(valid_21626446, JInt, required = false,
                                   default = nil)
  if valid_21626446 != nil:
    section.add "maxResults", valid_21626446
  var valid_21626447 = query.getOrDefault("nextToken")
  valid_21626447 = validateParameter(valid_21626447, JString, required = false,
                                   default = nil)
  if valid_21626447 != nil:
    section.add "nextToken", valid_21626447
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
  var valid_21626448 = header.getOrDefault("X-Amz-Date")
  valid_21626448 = validateParameter(valid_21626448, JString, required = false,
                                   default = nil)
  if valid_21626448 != nil:
    section.add "X-Amz-Date", valid_21626448
  var valid_21626449 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626449 = validateParameter(valid_21626449, JString, required = false,
                                   default = nil)
  if valid_21626449 != nil:
    section.add "X-Amz-Security-Token", valid_21626449
  var valid_21626450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626450 = validateParameter(valid_21626450, JString, required = false,
                                   default = nil)
  if valid_21626450 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626450
  var valid_21626451 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626451 = validateParameter(valid_21626451, JString, required = false,
                                   default = nil)
  if valid_21626451 != nil:
    section.add "X-Amz-Algorithm", valid_21626451
  var valid_21626452 = header.getOrDefault("X-Amz-Signature")
  valid_21626452 = validateParameter(valid_21626452, JString, required = false,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "X-Amz-Signature", valid_21626452
  var valid_21626453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626453 = validateParameter(valid_21626453, JString, required = false,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626453
  var valid_21626454 = header.getOrDefault("X-Amz-Credential")
  valid_21626454 = validateParameter(valid_21626454, JString, required = false,
                                   default = nil)
  if valid_21626454 != nil:
    section.add "X-Amz-Credential", valid_21626454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626455: Call_GetIntentVersions_21626442; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets information about all of the versions of an intent.</p> <p>The <code>GetIntentVersions</code> operation returns an <code>IntentMetadata</code> object for each version of an intent. For example, if an intent has three numbered versions, the <code>GetIntentVersions</code> operation returns four <code>IntentMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetIntentVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetIntentVersions</code> action.</p>
  ## 
  let valid = call_21626455.validator(path, query, header, formData, body, _)
  let scheme = call_21626455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626455.makeUrl(scheme.get, call_21626455.host, call_21626455.base,
                               call_21626455.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626455, uri, valid, _)

proc call*(call_21626456: Call_GetIntentVersions_21626442; name: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## getIntentVersions
  ## <p>Gets information about all of the versions of an intent.</p> <p>The <code>GetIntentVersions</code> operation returns an <code>IntentMetadata</code> object for each version of an intent. For example, if an intent has three numbered versions, the <code>GetIntentVersions</code> operation returns four <code>IntentMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetIntentVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetIntentVersions</code> action.</p>
  ##   name: string (required)
  ##       : The name of the intent for which versions should be returned.
  ##   maxResults: int
  ##             : The maximum number of intent versions to return in the response. The default is 10.
  ##   nextToken: string
  ##            : A pagination token for fetching the next page of intent versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  var path_21626457 = newJObject()
  var query_21626458 = newJObject()
  add(path_21626457, "name", newJString(name))
  add(query_21626458, "maxResults", newJInt(maxResults))
  add(query_21626458, "nextToken", newJString(nextToken))
  result = call_21626456.call(path_21626457, query_21626458, nil, nil, nil)

var getIntentVersions* = Call_GetIntentVersions_21626442(name: "getIntentVersions",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/intents/{name}/versions/", validator: validate_GetIntentVersions_21626443,
    base: "/", makeUrl: url_GetIntentVersions_21626444,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntents_21626459 = ref object of OpenApiRestCall_21625437
proc url_GetIntents_21626461(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetIntents_21626460(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626462 = query.getOrDefault("maxResults")
  valid_21626462 = validateParameter(valid_21626462, JInt, required = false,
                                   default = nil)
  if valid_21626462 != nil:
    section.add "maxResults", valid_21626462
  var valid_21626463 = query.getOrDefault("nextToken")
  valid_21626463 = validateParameter(valid_21626463, JString, required = false,
                                   default = nil)
  if valid_21626463 != nil:
    section.add "nextToken", valid_21626463
  var valid_21626464 = query.getOrDefault("nameContains")
  valid_21626464 = validateParameter(valid_21626464, JString, required = false,
                                   default = nil)
  if valid_21626464 != nil:
    section.add "nameContains", valid_21626464
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
  var valid_21626465 = header.getOrDefault("X-Amz-Date")
  valid_21626465 = validateParameter(valid_21626465, JString, required = false,
                                   default = nil)
  if valid_21626465 != nil:
    section.add "X-Amz-Date", valid_21626465
  var valid_21626466 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626466 = validateParameter(valid_21626466, JString, required = false,
                                   default = nil)
  if valid_21626466 != nil:
    section.add "X-Amz-Security-Token", valid_21626466
  var valid_21626467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626467 = validateParameter(valid_21626467, JString, required = false,
                                   default = nil)
  if valid_21626467 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626467
  var valid_21626468 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626468 = validateParameter(valid_21626468, JString, required = false,
                                   default = nil)
  if valid_21626468 != nil:
    section.add "X-Amz-Algorithm", valid_21626468
  var valid_21626469 = header.getOrDefault("X-Amz-Signature")
  valid_21626469 = validateParameter(valid_21626469, JString, required = false,
                                   default = nil)
  if valid_21626469 != nil:
    section.add "X-Amz-Signature", valid_21626469
  var valid_21626470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626470 = validateParameter(valid_21626470, JString, required = false,
                                   default = nil)
  if valid_21626470 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626470
  var valid_21626471 = header.getOrDefault("X-Amz-Credential")
  valid_21626471 = validateParameter(valid_21626471, JString, required = false,
                                   default = nil)
  if valid_21626471 != nil:
    section.add "X-Amz-Credential", valid_21626471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626472: Call_GetIntents_21626459; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns intent information as follows: </p> <ul> <li> <p>If you specify the <code>nameContains</code> field, returns the <code>$LATEST</code> version of all intents that contain the specified string.</p> </li> <li> <p> If you don't specify the <code>nameContains</code> field, returns information about the <code>$LATEST</code> version of all intents. </p> </li> </ul> <p> The operation requires permission for the <code>lex:GetIntents</code> action. </p>
  ## 
  let valid = call_21626472.validator(path, query, header, formData, body, _)
  let scheme = call_21626472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626472.makeUrl(scheme.get, call_21626472.host, call_21626472.base,
                               call_21626472.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626472, uri, valid, _)

proc call*(call_21626473: Call_GetIntents_21626459; maxResults: int = 0;
          nextToken: string = ""; nameContains: string = ""): Recallable =
  ## getIntents
  ## <p>Returns intent information as follows: </p> <ul> <li> <p>If you specify the <code>nameContains</code> field, returns the <code>$LATEST</code> version of all intents that contain the specified string.</p> </li> <li> <p> If you don't specify the <code>nameContains</code> field, returns information about the <code>$LATEST</code> version of all intents. </p> </li> </ul> <p> The operation requires permission for the <code>lex:GetIntents</code> action. </p>
  ##   maxResults: int
  ##             : The maximum number of intents to return in the response. The default is 10.
  ##   nextToken: string
  ##            : A pagination token that fetches the next page of intents. If the response to this API call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of intents, specify the pagination token in the next request. 
  ##   nameContains: string
  ##               : Substring to match in intent names. An intent will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  var query_21626474 = newJObject()
  add(query_21626474, "maxResults", newJInt(maxResults))
  add(query_21626474, "nextToken", newJString(nextToken))
  add(query_21626474, "nameContains", newJString(nameContains))
  result = call_21626473.call(nil, query_21626474, nil, nil, nil)

var getIntents* = Call_GetIntents_21626459(name: "getIntents",
                                        meth: HttpMethod.HttpGet,
                                        host: "models.lex.amazonaws.com",
                                        route: "/intents/",
                                        validator: validate_GetIntents_21626460,
                                        base: "/", makeUrl: url_GetIntents_21626461,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSlotType_21626475 = ref object of OpenApiRestCall_21625437
proc url_GetSlotType_21626477(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSlotType_21626476(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626478 = path.getOrDefault("name")
  valid_21626478 = validateParameter(valid_21626478, JString, required = true,
                                   default = nil)
  if valid_21626478 != nil:
    section.add "name", valid_21626478
  var valid_21626479 = path.getOrDefault("version")
  valid_21626479 = validateParameter(valid_21626479, JString, required = true,
                                   default = nil)
  if valid_21626479 != nil:
    section.add "version", valid_21626479
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
  var valid_21626480 = header.getOrDefault("X-Amz-Date")
  valid_21626480 = validateParameter(valid_21626480, JString, required = false,
                                   default = nil)
  if valid_21626480 != nil:
    section.add "X-Amz-Date", valid_21626480
  var valid_21626481 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626481 = validateParameter(valid_21626481, JString, required = false,
                                   default = nil)
  if valid_21626481 != nil:
    section.add "X-Amz-Security-Token", valid_21626481
  var valid_21626482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626482 = validateParameter(valid_21626482, JString, required = false,
                                   default = nil)
  if valid_21626482 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626482
  var valid_21626483 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626483 = validateParameter(valid_21626483, JString, required = false,
                                   default = nil)
  if valid_21626483 != nil:
    section.add "X-Amz-Algorithm", valid_21626483
  var valid_21626484 = header.getOrDefault("X-Amz-Signature")
  valid_21626484 = validateParameter(valid_21626484, JString, required = false,
                                   default = nil)
  if valid_21626484 != nil:
    section.add "X-Amz-Signature", valid_21626484
  var valid_21626485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626485 = validateParameter(valid_21626485, JString, required = false,
                                   default = nil)
  if valid_21626485 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626485
  var valid_21626486 = header.getOrDefault("X-Amz-Credential")
  valid_21626486 = validateParameter(valid_21626486, JString, required = false,
                                   default = nil)
  if valid_21626486 != nil:
    section.add "X-Amz-Credential", valid_21626486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626487: Call_GetSlotType_21626475; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns information about a specific version of a slot type. In addition to specifying the slot type name, you must specify the slot type version.</p> <p>This operation requires permissions for the <code>lex:GetSlotType</code> action.</p>
  ## 
  let valid = call_21626487.validator(path, query, header, formData, body, _)
  let scheme = call_21626487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626487.makeUrl(scheme.get, call_21626487.host, call_21626487.base,
                               call_21626487.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626487, uri, valid, _)

proc call*(call_21626488: Call_GetSlotType_21626475; name: string; version: string): Recallable =
  ## getSlotType
  ## <p>Returns information about a specific version of a slot type. In addition to specifying the slot type name, you must specify the slot type version.</p> <p>This operation requires permissions for the <code>lex:GetSlotType</code> action.</p>
  ##   name: string (required)
  ##       : The name of the slot type. The name is case sensitive. 
  ##   version: string (required)
  ##          : The version of the slot type. 
  var path_21626489 = newJObject()
  add(path_21626489, "name", newJString(name))
  add(path_21626489, "version", newJString(version))
  result = call_21626488.call(path_21626489, nil, nil, nil, nil)

var getSlotType* = Call_GetSlotType_21626475(name: "getSlotType",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/slottypes/{name}/versions/{version}",
    validator: validate_GetSlotType_21626476, base: "/", makeUrl: url_GetSlotType_21626477,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSlotTypeVersions_21626490 = ref object of OpenApiRestCall_21625437
proc url_GetSlotTypeVersions_21626492(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSlotTypeVersions_21626491(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Gets information about all versions of a slot type.</p> <p>The <code>GetSlotTypeVersions</code> operation returns a <code>SlotTypeMetadata</code> object for each version of a slot type. For example, if a slot type has three numbered versions, the <code>GetSlotTypeVersions</code> operation returns four <code>SlotTypeMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetSlotTypeVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetSlotTypeVersions</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the slot type for which versions should be returned.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_21626493 = path.getOrDefault("name")
  valid_21626493 = validateParameter(valid_21626493, JString, required = true,
                                   default = nil)
  if valid_21626493 != nil:
    section.add "name", valid_21626493
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of slot type versions to return in the response. The default is 10.
  ##   nextToken: JString
  ##            : A pagination token for fetching the next page of slot type versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  section = newJObject()
  var valid_21626494 = query.getOrDefault("maxResults")
  valid_21626494 = validateParameter(valid_21626494, JInt, required = false,
                                   default = nil)
  if valid_21626494 != nil:
    section.add "maxResults", valid_21626494
  var valid_21626495 = query.getOrDefault("nextToken")
  valid_21626495 = validateParameter(valid_21626495, JString, required = false,
                                   default = nil)
  if valid_21626495 != nil:
    section.add "nextToken", valid_21626495
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
  var valid_21626496 = header.getOrDefault("X-Amz-Date")
  valid_21626496 = validateParameter(valid_21626496, JString, required = false,
                                   default = nil)
  if valid_21626496 != nil:
    section.add "X-Amz-Date", valid_21626496
  var valid_21626497 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626497 = validateParameter(valid_21626497, JString, required = false,
                                   default = nil)
  if valid_21626497 != nil:
    section.add "X-Amz-Security-Token", valid_21626497
  var valid_21626498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626498 = validateParameter(valid_21626498, JString, required = false,
                                   default = nil)
  if valid_21626498 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626498
  var valid_21626499 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626499 = validateParameter(valid_21626499, JString, required = false,
                                   default = nil)
  if valid_21626499 != nil:
    section.add "X-Amz-Algorithm", valid_21626499
  var valid_21626500 = header.getOrDefault("X-Amz-Signature")
  valid_21626500 = validateParameter(valid_21626500, JString, required = false,
                                   default = nil)
  if valid_21626500 != nil:
    section.add "X-Amz-Signature", valid_21626500
  var valid_21626501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626501 = validateParameter(valid_21626501, JString, required = false,
                                   default = nil)
  if valid_21626501 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626501
  var valid_21626502 = header.getOrDefault("X-Amz-Credential")
  valid_21626502 = validateParameter(valid_21626502, JString, required = false,
                                   default = nil)
  if valid_21626502 != nil:
    section.add "X-Amz-Credential", valid_21626502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626503: Call_GetSlotTypeVersions_21626490; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Gets information about all versions of a slot type.</p> <p>The <code>GetSlotTypeVersions</code> operation returns a <code>SlotTypeMetadata</code> object for each version of a slot type. For example, if a slot type has three numbered versions, the <code>GetSlotTypeVersions</code> operation returns four <code>SlotTypeMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetSlotTypeVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetSlotTypeVersions</code> action.</p>
  ## 
  let valid = call_21626503.validator(path, query, header, formData, body, _)
  let scheme = call_21626503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626503.makeUrl(scheme.get, call_21626503.host, call_21626503.base,
                               call_21626503.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626503, uri, valid, _)

proc call*(call_21626504: Call_GetSlotTypeVersions_21626490; name: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## getSlotTypeVersions
  ## <p>Gets information about all versions of a slot type.</p> <p>The <code>GetSlotTypeVersions</code> operation returns a <code>SlotTypeMetadata</code> object for each version of a slot type. For example, if a slot type has three numbered versions, the <code>GetSlotTypeVersions</code> operation returns four <code>SlotTypeMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetSlotTypeVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetSlotTypeVersions</code> action.</p>
  ##   name: string (required)
  ##       : The name of the slot type for which versions should be returned.
  ##   maxResults: int
  ##             : The maximum number of slot type versions to return in the response. The default is 10.
  ##   nextToken: string
  ##            : A pagination token for fetching the next page of slot type versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  var path_21626505 = newJObject()
  var query_21626506 = newJObject()
  add(path_21626505, "name", newJString(name))
  add(query_21626506, "maxResults", newJInt(maxResults))
  add(query_21626506, "nextToken", newJString(nextToken))
  result = call_21626504.call(path_21626505, query_21626506, nil, nil, nil)

var getSlotTypeVersions* = Call_GetSlotTypeVersions_21626490(
    name: "getSlotTypeVersions", meth: HttpMethod.HttpGet,
    host: "models.lex.amazonaws.com", route: "/slottypes/{name}/versions/",
    validator: validate_GetSlotTypeVersions_21626491, base: "/",
    makeUrl: url_GetSlotTypeVersions_21626492,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSlotTypes_21626507 = ref object of OpenApiRestCall_21625437
proc url_GetSlotTypes_21626509(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSlotTypes_21626508(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626510 = query.getOrDefault("maxResults")
  valid_21626510 = validateParameter(valid_21626510, JInt, required = false,
                                   default = nil)
  if valid_21626510 != nil:
    section.add "maxResults", valid_21626510
  var valid_21626511 = query.getOrDefault("nextToken")
  valid_21626511 = validateParameter(valid_21626511, JString, required = false,
                                   default = nil)
  if valid_21626511 != nil:
    section.add "nextToken", valid_21626511
  var valid_21626512 = query.getOrDefault("nameContains")
  valid_21626512 = validateParameter(valid_21626512, JString, required = false,
                                   default = nil)
  if valid_21626512 != nil:
    section.add "nameContains", valid_21626512
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
  var valid_21626513 = header.getOrDefault("X-Amz-Date")
  valid_21626513 = validateParameter(valid_21626513, JString, required = false,
                                   default = nil)
  if valid_21626513 != nil:
    section.add "X-Amz-Date", valid_21626513
  var valid_21626514 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626514 = validateParameter(valid_21626514, JString, required = false,
                                   default = nil)
  if valid_21626514 != nil:
    section.add "X-Amz-Security-Token", valid_21626514
  var valid_21626515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626515 = validateParameter(valid_21626515, JString, required = false,
                                   default = nil)
  if valid_21626515 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626515
  var valid_21626516 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626516 = validateParameter(valid_21626516, JString, required = false,
                                   default = nil)
  if valid_21626516 != nil:
    section.add "X-Amz-Algorithm", valid_21626516
  var valid_21626517 = header.getOrDefault("X-Amz-Signature")
  valid_21626517 = validateParameter(valid_21626517, JString, required = false,
                                   default = nil)
  if valid_21626517 != nil:
    section.add "X-Amz-Signature", valid_21626517
  var valid_21626518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626518 = validateParameter(valid_21626518, JString, required = false,
                                   default = nil)
  if valid_21626518 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626518
  var valid_21626519 = header.getOrDefault("X-Amz-Credential")
  valid_21626519 = validateParameter(valid_21626519, JString, required = false,
                                   default = nil)
  if valid_21626519 != nil:
    section.add "X-Amz-Credential", valid_21626519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626520: Call_GetSlotTypes_21626507; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns slot type information as follows: </p> <ul> <li> <p>If you specify the <code>nameContains</code> field, returns the <code>$LATEST</code> version of all slot types that contain the specified string.</p> </li> <li> <p> If you don't specify the <code>nameContains</code> field, returns information about the <code>$LATEST</code> version of all slot types. </p> </li> </ul> <p> The operation requires permission for the <code>lex:GetSlotTypes</code> action. </p>
  ## 
  let valid = call_21626520.validator(path, query, header, formData, body, _)
  let scheme = call_21626520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626520.makeUrl(scheme.get, call_21626520.host, call_21626520.base,
                               call_21626520.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626520, uri, valid, _)

proc call*(call_21626521: Call_GetSlotTypes_21626507; maxResults: int = 0;
          nextToken: string = ""; nameContains: string = ""): Recallable =
  ## getSlotTypes
  ## <p>Returns slot type information as follows: </p> <ul> <li> <p>If you specify the <code>nameContains</code> field, returns the <code>$LATEST</code> version of all slot types that contain the specified string.</p> </li> <li> <p> If you don't specify the <code>nameContains</code> field, returns information about the <code>$LATEST</code> version of all slot types. </p> </li> </ul> <p> The operation requires permission for the <code>lex:GetSlotTypes</code> action. </p>
  ##   maxResults: int
  ##             : The maximum number of slot types to return in the response. The default is 10.
  ##   nextToken: string
  ##            : A pagination token that fetches the next page of slot types. If the response to this API call is truncated, Amazon Lex returns a pagination token in the response. To fetch next page of slot types, specify the pagination token in the next request.
  ##   nameContains: string
  ##               : Substring to match in slot type names. A slot type will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  var query_21626522 = newJObject()
  add(query_21626522, "maxResults", newJInt(maxResults))
  add(query_21626522, "nextToken", newJString(nextToken))
  add(query_21626522, "nameContains", newJString(nameContains))
  result = call_21626521.call(nil, query_21626522, nil, nil, nil)

var getSlotTypes* = Call_GetSlotTypes_21626507(name: "getSlotTypes",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/slottypes/", validator: validate_GetSlotTypes_21626508, base: "/",
    makeUrl: url_GetSlotTypes_21626509, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUtterancesView_21626523 = ref object of OpenApiRestCall_21625437
proc url_GetUtterancesView_21626525(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetUtterancesView_21626524(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Use the <code>GetUtterancesView</code> operation to get information about the utterances that your users have made to your bot. You can use this list to tune the utterances that your bot responds to.</p> <p>For example, say that you have created a bot to order flowers. After your users have used your bot for a while, use the <code>GetUtterancesView</code> operation to see the requests that they have made and whether they have been successful. You might find that the utterance "I want flowers" is not being recognized. You could add this utterance to the <code>OrderFlowers</code> intent so that your bot recognizes that utterance.</p> <p>After you publish a new version of a bot, you can get information about the old version and the new so that you can compare the performance across the two versions. </p> <p>Utterance statistics are generated once a day. Data is available for the last 15 days. You can request information for up to 5 versions of your bot in each request. Amazon Lex returns the most frequent utterances received by the bot in the last 15 days. The response contains information about a maximum of 100 utterances for each version.</p> <p>If you set <code>childDirected</code> field to true when you created your bot, or if you opted out of participating in improving Amazon Lex, utterances are not available.</p> <p>This operation requires permissions for the <code>lex:GetUtterancesView</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   botname: JString (required)
  ##          : The name of the bot for which utterance information should be returned.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `botname` field"
  var valid_21626526 = path.getOrDefault("botname")
  valid_21626526 = validateParameter(valid_21626526, JString, required = true,
                                   default = nil)
  if valid_21626526 != nil:
    section.add "botname", valid_21626526
  result.add "path", section
  ## parameters in `query` object:
  ##   view: JString (required)
  ##   status_type: JString (required)
  ##              : To return utterances that were recognized and handled, use <code>Detected</code>. To return utterances that were not recognized, use <code>Missed</code>.
  ##   bot_versions: JArray (required)
  ##               : An array of bot versions for which utterance information should be returned. The limit is 5 versions per request.
  section = newJObject()
  var valid_21626527 = query.getOrDefault("view")
  valid_21626527 = validateParameter(valid_21626527, JString, required = true,
                                   default = newJString("aggregation"))
  if valid_21626527 != nil:
    section.add "view", valid_21626527
  var valid_21626528 = query.getOrDefault("status_type")
  valid_21626528 = validateParameter(valid_21626528, JString, required = true,
                                   default = newJString("Detected"))
  if valid_21626528 != nil:
    section.add "status_type", valid_21626528
  var valid_21626529 = query.getOrDefault("bot_versions")
  valid_21626529 = validateParameter(valid_21626529, JArray, required = true,
                                   default = nil)
  if valid_21626529 != nil:
    section.add "bot_versions", valid_21626529
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
  var valid_21626530 = header.getOrDefault("X-Amz-Date")
  valid_21626530 = validateParameter(valid_21626530, JString, required = false,
                                   default = nil)
  if valid_21626530 != nil:
    section.add "X-Amz-Date", valid_21626530
  var valid_21626531 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626531 = validateParameter(valid_21626531, JString, required = false,
                                   default = nil)
  if valid_21626531 != nil:
    section.add "X-Amz-Security-Token", valid_21626531
  var valid_21626532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626532 = validateParameter(valid_21626532, JString, required = false,
                                   default = nil)
  if valid_21626532 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626532
  var valid_21626533 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626533 = validateParameter(valid_21626533, JString, required = false,
                                   default = nil)
  if valid_21626533 != nil:
    section.add "X-Amz-Algorithm", valid_21626533
  var valid_21626534 = header.getOrDefault("X-Amz-Signature")
  valid_21626534 = validateParameter(valid_21626534, JString, required = false,
                                   default = nil)
  if valid_21626534 != nil:
    section.add "X-Amz-Signature", valid_21626534
  var valid_21626535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626535 = validateParameter(valid_21626535, JString, required = false,
                                   default = nil)
  if valid_21626535 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626535
  var valid_21626536 = header.getOrDefault("X-Amz-Credential")
  valid_21626536 = validateParameter(valid_21626536, JString, required = false,
                                   default = nil)
  if valid_21626536 != nil:
    section.add "X-Amz-Credential", valid_21626536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626537: Call_GetUtterancesView_21626523; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Use the <code>GetUtterancesView</code> operation to get information about the utterances that your users have made to your bot. You can use this list to tune the utterances that your bot responds to.</p> <p>For example, say that you have created a bot to order flowers. After your users have used your bot for a while, use the <code>GetUtterancesView</code> operation to see the requests that they have made and whether they have been successful. You might find that the utterance "I want flowers" is not being recognized. You could add this utterance to the <code>OrderFlowers</code> intent so that your bot recognizes that utterance.</p> <p>After you publish a new version of a bot, you can get information about the old version and the new so that you can compare the performance across the two versions. </p> <p>Utterance statistics are generated once a day. Data is available for the last 15 days. You can request information for up to 5 versions of your bot in each request. Amazon Lex returns the most frequent utterances received by the bot in the last 15 days. The response contains information about a maximum of 100 utterances for each version.</p> <p>If you set <code>childDirected</code> field to true when you created your bot, or if you opted out of participating in improving Amazon Lex, utterances are not available.</p> <p>This operation requires permissions for the <code>lex:GetUtterancesView</code> action.</p>
  ## 
  let valid = call_21626537.validator(path, query, header, formData, body, _)
  let scheme = call_21626537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626537.makeUrl(scheme.get, call_21626537.host, call_21626537.base,
                               call_21626537.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626537, uri, valid, _)

proc call*(call_21626538: Call_GetUtterancesView_21626523; botVersions: JsonNode;
          botname: string; view: string = "aggregation";
          statusType: string = "Detected"): Recallable =
  ## getUtterancesView
  ## <p>Use the <code>GetUtterancesView</code> operation to get information about the utterances that your users have made to your bot. You can use this list to tune the utterances that your bot responds to.</p> <p>For example, say that you have created a bot to order flowers. After your users have used your bot for a while, use the <code>GetUtterancesView</code> operation to see the requests that they have made and whether they have been successful. You might find that the utterance "I want flowers" is not being recognized. You could add this utterance to the <code>OrderFlowers</code> intent so that your bot recognizes that utterance.</p> <p>After you publish a new version of a bot, you can get information about the old version and the new so that you can compare the performance across the two versions. </p> <p>Utterance statistics are generated once a day. Data is available for the last 15 days. You can request information for up to 5 versions of your bot in each request. Amazon Lex returns the most frequent utterances received by the bot in the last 15 days. The response contains information about a maximum of 100 utterances for each version.</p> <p>If you set <code>childDirected</code> field to true when you created your bot, or if you opted out of participating in improving Amazon Lex, utterances are not available.</p> <p>This operation requires permissions for the <code>lex:GetUtterancesView</code> action.</p>
  ##   view: string (required)
  ##   statusType: string (required)
  ##             : To return utterances that were recognized and handled, use <code>Detected</code>. To return utterances that were not recognized, use <code>Missed</code>.
  ##   botVersions: JArray (required)
  ##              : An array of bot versions for which utterance information should be returned. The limit is 5 versions per request.
  ##   botname: string (required)
  ##          : The name of the bot for which utterance information should be returned.
  var path_21626539 = newJObject()
  var query_21626540 = newJObject()
  add(query_21626540, "view", newJString(view))
  add(query_21626540, "status_type", newJString(statusType))
  if botVersions != nil:
    query_21626540.add "bot_versions", botVersions
  add(path_21626539, "botname", newJString(botname))
  result = call_21626538.call(path_21626539, query_21626540, nil, nil, nil)

var getUtterancesView* = Call_GetUtterancesView_21626523(name: "getUtterancesView",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com", route: "/bots/{botname}/utterances#view=aggregation&bot_versions&status_type",
    validator: validate_GetUtterancesView_21626524, base: "/",
    makeUrl: url_GetUtterancesView_21626525, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBot_21626541 = ref object of OpenApiRestCall_21625437
proc url_PutBot_21626543(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutBot_21626542(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates an Amazon Lex conversational bot or replaces an existing bot. When you create or update a bot you are only required to specify a name, a locale, and whether the bot is directed toward children under age 13. You can use this to add intents later, or to remove intents from an existing bot. When you create a bot with the minimum information, the bot is created or updated but Amazon Lex returns the <code/> response <code>FAILED</code>. You can build the bot after you add one or more intents. For more information about Amazon Lex bots, see <a>how-it-works</a>. </p> <p>If you specify the name of an existing bot, the fields in the request replace the existing values in the <code>$LATEST</code> version of the bot. Amazon Lex removes any fields that you don't provide values for in the request, except for the <code>idleTTLInSeconds</code> and <code>privacySettings</code> fields, which are set to their default values. If you don't specify values for required fields, Amazon Lex throws an exception.</p> <p>This operation requires permissions for the <code>lex:PutBot</code> action. For more information, see <a>security-iam</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the bot. The name is <i>not</i> case sensitive. 
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_21626544 = path.getOrDefault("name")
  valid_21626544 = validateParameter(valid_21626544, JString, required = true,
                                   default = nil)
  if valid_21626544 != nil:
    section.add "name", valid_21626544
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
  var valid_21626545 = header.getOrDefault("X-Amz-Date")
  valid_21626545 = validateParameter(valid_21626545, JString, required = false,
                                   default = nil)
  if valid_21626545 != nil:
    section.add "X-Amz-Date", valid_21626545
  var valid_21626546 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626546 = validateParameter(valid_21626546, JString, required = false,
                                   default = nil)
  if valid_21626546 != nil:
    section.add "X-Amz-Security-Token", valid_21626546
  var valid_21626547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626547 = validateParameter(valid_21626547, JString, required = false,
                                   default = nil)
  if valid_21626547 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626547
  var valid_21626548 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626548 = validateParameter(valid_21626548, JString, required = false,
                                   default = nil)
  if valid_21626548 != nil:
    section.add "X-Amz-Algorithm", valid_21626548
  var valid_21626549 = header.getOrDefault("X-Amz-Signature")
  valid_21626549 = validateParameter(valid_21626549, JString, required = false,
                                   default = nil)
  if valid_21626549 != nil:
    section.add "X-Amz-Signature", valid_21626549
  var valid_21626550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626550 = validateParameter(valid_21626550, JString, required = false,
                                   default = nil)
  if valid_21626550 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626550
  var valid_21626551 = header.getOrDefault("X-Amz-Credential")
  valid_21626551 = validateParameter(valid_21626551, JString, required = false,
                                   default = nil)
  if valid_21626551 != nil:
    section.add "X-Amz-Credential", valid_21626551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626553: Call_PutBot_21626541; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an Amazon Lex conversational bot or replaces an existing bot. When you create or update a bot you are only required to specify a name, a locale, and whether the bot is directed toward children under age 13. You can use this to add intents later, or to remove intents from an existing bot. When you create a bot with the minimum information, the bot is created or updated but Amazon Lex returns the <code/> response <code>FAILED</code>. You can build the bot after you add one or more intents. For more information about Amazon Lex bots, see <a>how-it-works</a>. </p> <p>If you specify the name of an existing bot, the fields in the request replace the existing values in the <code>$LATEST</code> version of the bot. Amazon Lex removes any fields that you don't provide values for in the request, except for the <code>idleTTLInSeconds</code> and <code>privacySettings</code> fields, which are set to their default values. If you don't specify values for required fields, Amazon Lex throws an exception.</p> <p>This operation requires permissions for the <code>lex:PutBot</code> action. For more information, see <a>security-iam</a>.</p>
  ## 
  let valid = call_21626553.validator(path, query, header, formData, body, _)
  let scheme = call_21626553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626553.makeUrl(scheme.get, call_21626553.host, call_21626553.base,
                               call_21626553.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626553, uri, valid, _)

proc call*(call_21626554: Call_PutBot_21626541; name: string; body: JsonNode): Recallable =
  ## putBot
  ## <p>Creates an Amazon Lex conversational bot or replaces an existing bot. When you create or update a bot you are only required to specify a name, a locale, and whether the bot is directed toward children under age 13. You can use this to add intents later, or to remove intents from an existing bot. When you create a bot with the minimum information, the bot is created or updated but Amazon Lex returns the <code/> response <code>FAILED</code>. You can build the bot after you add one or more intents. For more information about Amazon Lex bots, see <a>how-it-works</a>. </p> <p>If you specify the name of an existing bot, the fields in the request replace the existing values in the <code>$LATEST</code> version of the bot. Amazon Lex removes any fields that you don't provide values for in the request, except for the <code>idleTTLInSeconds</code> and <code>privacySettings</code> fields, which are set to their default values. If you don't specify values for required fields, Amazon Lex throws an exception.</p> <p>This operation requires permissions for the <code>lex:PutBot</code> action. For more information, see <a>security-iam</a>.</p>
  ##   name: string (required)
  ##       : The name of the bot. The name is <i>not</i> case sensitive. 
  ##   body: JObject (required)
  var path_21626555 = newJObject()
  var body_21626556 = newJObject()
  add(path_21626555, "name", newJString(name))
  if body != nil:
    body_21626556 = body
  result = call_21626554.call(path_21626555, nil, nil, nil, body_21626556)

var putBot* = Call_PutBot_21626541(name: "putBot", meth: HttpMethod.HttpPut,
                                host: "models.lex.amazonaws.com",
                                route: "/bots/{name}/versions/$LATEST",
                                validator: validate_PutBot_21626542, base: "/",
                                makeUrl: url_PutBot_21626543,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutIntent_21626557 = ref object of OpenApiRestCall_21625437
proc url_PutIntent_21626559(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutIntent_21626558(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626560 = path.getOrDefault("name")
  valid_21626560 = validateParameter(valid_21626560, JString, required = true,
                                   default = nil)
  if valid_21626560 != nil:
    section.add "name", valid_21626560
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
  var valid_21626561 = header.getOrDefault("X-Amz-Date")
  valid_21626561 = validateParameter(valid_21626561, JString, required = false,
                                   default = nil)
  if valid_21626561 != nil:
    section.add "X-Amz-Date", valid_21626561
  var valid_21626562 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626562 = validateParameter(valid_21626562, JString, required = false,
                                   default = nil)
  if valid_21626562 != nil:
    section.add "X-Amz-Security-Token", valid_21626562
  var valid_21626563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626563 = validateParameter(valid_21626563, JString, required = false,
                                   default = nil)
  if valid_21626563 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626563
  var valid_21626564 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626564 = validateParameter(valid_21626564, JString, required = false,
                                   default = nil)
  if valid_21626564 != nil:
    section.add "X-Amz-Algorithm", valid_21626564
  var valid_21626565 = header.getOrDefault("X-Amz-Signature")
  valid_21626565 = validateParameter(valid_21626565, JString, required = false,
                                   default = nil)
  if valid_21626565 != nil:
    section.add "X-Amz-Signature", valid_21626565
  var valid_21626566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626566 = validateParameter(valid_21626566, JString, required = false,
                                   default = nil)
  if valid_21626566 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626566
  var valid_21626567 = header.getOrDefault("X-Amz-Credential")
  valid_21626567 = validateParameter(valid_21626567, JString, required = false,
                                   default = nil)
  if valid_21626567 != nil:
    section.add "X-Amz-Credential", valid_21626567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626569: Call_PutIntent_21626557; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an intent or replaces an existing intent.</p> <p>To define the interaction between the user and your bot, you use one or more intents. For a pizza ordering bot, for example, you would create an <code>OrderPizza</code> intent. </p> <p>To create an intent or replace an existing intent, you must provide the following:</p> <ul> <li> <p>Intent name. For example, <code>OrderPizza</code>.</p> </li> <li> <p>Sample utterances. For example, "Can I order a pizza, please." and "I want to order a pizza."</p> </li> <li> <p>Information to be gathered. You specify slot types for the information that your bot will request from the user. You can specify standard slot types, such as a date or a time, or custom slot types such as the size and crust of a pizza.</p> </li> <li> <p>How the intent will be fulfilled. You can provide a Lambda function or configure the intent to return the intent information to the client application. If you use a Lambda function, when all of the intent information is available, Amazon Lex invokes your Lambda function. If you configure your intent to return the intent information to the client application. </p> </li> </ul> <p>You can specify other optional information in the request, such as:</p> <ul> <li> <p>A confirmation prompt to ask the user to confirm an intent. For example, "Shall I order your pizza?"</p> </li> <li> <p>A conclusion statement to send to the user after the intent has been fulfilled. For example, "I placed your pizza order."</p> </li> <li> <p>A follow-up prompt that asks the user for additional activity. For example, asking "Do you want to order a drink with your pizza?"</p> </li> </ul> <p>If you specify an existing intent name to update the intent, Amazon Lex replaces the values in the <code>$LATEST</code> version of the intent with the values in the request. Amazon Lex removes fields that you don't provide in the request. If you don't specify the required fields, Amazon Lex throws an exception. When you update the <code>$LATEST</code> version of an intent, the <code>status</code> field of any bot that uses the <code>$LATEST</code> version of the intent is set to <code>NOT_BUILT</code>.</p> <p>For more information, see <a>how-it-works</a>.</p> <p>This operation requires permissions for the <code>lex:PutIntent</code> action.</p>
  ## 
  let valid = call_21626569.validator(path, query, header, formData, body, _)
  let scheme = call_21626569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626569.makeUrl(scheme.get, call_21626569.host, call_21626569.base,
                               call_21626569.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626569, uri, valid, _)

proc call*(call_21626570: Call_PutIntent_21626557; name: string; body: JsonNode): Recallable =
  ## putIntent
  ## <p>Creates an intent or replaces an existing intent.</p> <p>To define the interaction between the user and your bot, you use one or more intents. For a pizza ordering bot, for example, you would create an <code>OrderPizza</code> intent. </p> <p>To create an intent or replace an existing intent, you must provide the following:</p> <ul> <li> <p>Intent name. For example, <code>OrderPizza</code>.</p> </li> <li> <p>Sample utterances. For example, "Can I order a pizza, please." and "I want to order a pizza."</p> </li> <li> <p>Information to be gathered. You specify slot types for the information that your bot will request from the user. You can specify standard slot types, such as a date or a time, or custom slot types such as the size and crust of a pizza.</p> </li> <li> <p>How the intent will be fulfilled. You can provide a Lambda function or configure the intent to return the intent information to the client application. If you use a Lambda function, when all of the intent information is available, Amazon Lex invokes your Lambda function. If you configure your intent to return the intent information to the client application. </p> </li> </ul> <p>You can specify other optional information in the request, such as:</p> <ul> <li> <p>A confirmation prompt to ask the user to confirm an intent. For example, "Shall I order your pizza?"</p> </li> <li> <p>A conclusion statement to send to the user after the intent has been fulfilled. For example, "I placed your pizza order."</p> </li> <li> <p>A follow-up prompt that asks the user for additional activity. For example, asking "Do you want to order a drink with your pizza?"</p> </li> </ul> <p>If you specify an existing intent name to update the intent, Amazon Lex replaces the values in the <code>$LATEST</code> version of the intent with the values in the request. Amazon Lex removes fields that you don't provide in the request. If you don't specify the required fields, Amazon Lex throws an exception. When you update the <code>$LATEST</code> version of an intent, the <code>status</code> field of any bot that uses the <code>$LATEST</code> version of the intent is set to <code>NOT_BUILT</code>.</p> <p>For more information, see <a>how-it-works</a>.</p> <p>This operation requires permissions for the <code>lex:PutIntent</code> action.</p>
  ##   name: string (required)
  ##       : <p>The name of the intent. The name is <i>not</i> case sensitive. </p> <p>The name can't match a built-in intent name, or a built-in intent name with "AMAZON." removed. For example, because there is a built-in intent called <code>AMAZON.HelpIntent</code>, you can't create a custom intent called <code>HelpIntent</code>.</p> <p>For a list of built-in intents, see <a 
  ## href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/standard-intents">Standard Built-in Intents</a> in the <i>Alexa Skills Kit</i>.</p>
  ##   body: JObject (required)
  var path_21626571 = newJObject()
  var body_21626572 = newJObject()
  add(path_21626571, "name", newJString(name))
  if body != nil:
    body_21626572 = body
  result = call_21626570.call(path_21626571, nil, nil, nil, body_21626572)

var putIntent* = Call_PutIntent_21626557(name: "putIntent", meth: HttpMethod.HttpPut,
                                      host: "models.lex.amazonaws.com", route: "/intents/{name}/versions/$LATEST",
                                      validator: validate_PutIntent_21626558,
                                      base: "/", makeUrl: url_PutIntent_21626559,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSlotType_21626573 = ref object of OpenApiRestCall_21625437
proc url_PutSlotType_21626575(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutSlotType_21626574(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626576 = path.getOrDefault("name")
  valid_21626576 = validateParameter(valid_21626576, JString, required = true,
                                   default = nil)
  if valid_21626576 != nil:
    section.add "name", valid_21626576
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
  var valid_21626577 = header.getOrDefault("X-Amz-Date")
  valid_21626577 = validateParameter(valid_21626577, JString, required = false,
                                   default = nil)
  if valid_21626577 != nil:
    section.add "X-Amz-Date", valid_21626577
  var valid_21626578 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626578 = validateParameter(valid_21626578, JString, required = false,
                                   default = nil)
  if valid_21626578 != nil:
    section.add "X-Amz-Security-Token", valid_21626578
  var valid_21626579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626579 = validateParameter(valid_21626579, JString, required = false,
                                   default = nil)
  if valid_21626579 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626579
  var valid_21626580 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626580 = validateParameter(valid_21626580, JString, required = false,
                                   default = nil)
  if valid_21626580 != nil:
    section.add "X-Amz-Algorithm", valid_21626580
  var valid_21626581 = header.getOrDefault("X-Amz-Signature")
  valid_21626581 = validateParameter(valid_21626581, JString, required = false,
                                   default = nil)
  if valid_21626581 != nil:
    section.add "X-Amz-Signature", valid_21626581
  var valid_21626582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626582 = validateParameter(valid_21626582, JString, required = false,
                                   default = nil)
  if valid_21626582 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626582
  var valid_21626583 = header.getOrDefault("X-Amz-Credential")
  valid_21626583 = validateParameter(valid_21626583, JString, required = false,
                                   default = nil)
  if valid_21626583 != nil:
    section.add "X-Amz-Credential", valid_21626583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626585: Call_PutSlotType_21626573; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a custom slot type or replaces an existing custom slot type.</p> <p>To create a custom slot type, specify a name for the slot type and a set of enumeration values, which are the values that a slot of this type can assume. For more information, see <a>how-it-works</a>.</p> <p>If you specify the name of an existing slot type, the fields in the request replace the existing values in the <code>$LATEST</code> version of the slot type. Amazon Lex removes the fields that you don't provide in the request. If you don't specify required fields, Amazon Lex throws an exception. When you update the <code>$LATEST</code> version of a slot type, if a bot uses the <code>$LATEST</code> version of an intent that contains the slot type, the bot's <code>status</code> field is set to <code>NOT_BUILT</code>.</p> <p>This operation requires permissions for the <code>lex:PutSlotType</code> action.</p>
  ## 
  let valid = call_21626585.validator(path, query, header, formData, body, _)
  let scheme = call_21626585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626585.makeUrl(scheme.get, call_21626585.host, call_21626585.base,
                               call_21626585.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626585, uri, valid, _)

proc call*(call_21626586: Call_PutSlotType_21626573; name: string; body: JsonNode): Recallable =
  ## putSlotType
  ## <p>Creates a custom slot type or replaces an existing custom slot type.</p> <p>To create a custom slot type, specify a name for the slot type and a set of enumeration values, which are the values that a slot of this type can assume. For more information, see <a>how-it-works</a>.</p> <p>If you specify the name of an existing slot type, the fields in the request replace the existing values in the <code>$LATEST</code> version of the slot type. Amazon Lex removes the fields that you don't provide in the request. If you don't specify required fields, Amazon Lex throws an exception. When you update the <code>$LATEST</code> version of a slot type, if a bot uses the <code>$LATEST</code> version of an intent that contains the slot type, the bot's <code>status</code> field is set to <code>NOT_BUILT</code>.</p> <p>This operation requires permissions for the <code>lex:PutSlotType</code> action.</p>
  ##   name: string (required)
  ##       : <p>The name of the slot type. The name is <i>not</i> case sensitive. </p> <p>The name can't match a built-in slot type name, or a built-in slot type name with "AMAZON." removed. For example, because there is a built-in slot type called <code>AMAZON.DATE</code>, you can't create a custom slot type called <code>DATE</code>.</p> <p>For a list of built-in slot types, see <a 
  ## href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/slot-type-reference">Slot Type Reference</a> in the <i>Alexa Skills Kit</i>.</p>
  ##   body: JObject (required)
  var path_21626587 = newJObject()
  var body_21626588 = newJObject()
  add(path_21626587, "name", newJString(name))
  if body != nil:
    body_21626588 = body
  result = call_21626586.call(path_21626587, nil, nil, nil, body_21626588)

var putSlotType* = Call_PutSlotType_21626573(name: "putSlotType",
    meth: HttpMethod.HttpPut, host: "models.lex.amazonaws.com",
    route: "/slottypes/{name}/versions/$LATEST", validator: validate_PutSlotType_21626574,
    base: "/", makeUrl: url_PutSlotType_21626575,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImport_21626589 = ref object of OpenApiRestCall_21625437
proc url_StartImport_21626591(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartImport_21626590(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626592 = header.getOrDefault("X-Amz-Date")
  valid_21626592 = validateParameter(valid_21626592, JString, required = false,
                                   default = nil)
  if valid_21626592 != nil:
    section.add "X-Amz-Date", valid_21626592
  var valid_21626593 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626593 = validateParameter(valid_21626593, JString, required = false,
                                   default = nil)
  if valid_21626593 != nil:
    section.add "X-Amz-Security-Token", valid_21626593
  var valid_21626594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626594 = validateParameter(valid_21626594, JString, required = false,
                                   default = nil)
  if valid_21626594 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626594
  var valid_21626595 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626595 = validateParameter(valid_21626595, JString, required = false,
                                   default = nil)
  if valid_21626595 != nil:
    section.add "X-Amz-Algorithm", valid_21626595
  var valid_21626596 = header.getOrDefault("X-Amz-Signature")
  valid_21626596 = validateParameter(valid_21626596, JString, required = false,
                                   default = nil)
  if valid_21626596 != nil:
    section.add "X-Amz-Signature", valid_21626596
  var valid_21626597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626597 = validateParameter(valid_21626597, JString, required = false,
                                   default = nil)
  if valid_21626597 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626597
  var valid_21626598 = header.getOrDefault("X-Amz-Credential")
  valid_21626598 = validateParameter(valid_21626598, JString, required = false,
                                   default = nil)
  if valid_21626598 != nil:
    section.add "X-Amz-Credential", valid_21626598
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626600: Call_StartImport_21626589; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts a job to import a resource to Amazon Lex.
  ## 
  let valid = call_21626600.validator(path, query, header, formData, body, _)
  let scheme = call_21626600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626600.makeUrl(scheme.get, call_21626600.host, call_21626600.base,
                               call_21626600.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626600, uri, valid, _)

proc call*(call_21626601: Call_StartImport_21626589; body: JsonNode): Recallable =
  ## startImport
  ## Starts a job to import a resource to Amazon Lex.
  ##   body: JObject (required)
  var body_21626602 = newJObject()
  if body != nil:
    body_21626602 = body
  result = call_21626601.call(nil, nil, nil, nil, body_21626602)

var startImport* = Call_StartImport_21626589(name: "startImport",
    meth: HttpMethod.HttpPost, host: "models.lex.amazonaws.com", route: "/imports/",
    validator: validate_StartImport_21626590, base: "/", makeUrl: url_StartImport_21626591,
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}