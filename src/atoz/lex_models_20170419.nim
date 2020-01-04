
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

  OpenApiRestCall_601390 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601390](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601390): Option[Scheme] {.used.} =
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
  Call_CreateBotVersion_601728 = ref object of OpenApiRestCall_601390
proc url_CreateBotVersion_601730(protocol: Scheme; host: string; base: string;
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

proc validate_CreateBotVersion_601729(path: JsonNode; query: JsonNode;
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
  var valid_601856 = path.getOrDefault("name")
  valid_601856 = validateParameter(valid_601856, JString, required = true,
                                 default = nil)
  if valid_601856 != nil:
    section.add "name", valid_601856
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
  var valid_601857 = header.getOrDefault("X-Amz-Signature")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Signature", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Content-Sha256", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Date")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Date", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-Credential")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Credential", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Security-Token")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Security-Token", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-Algorithm")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-Algorithm", valid_601862
  var valid_601863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "X-Amz-SignedHeaders", valid_601863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601887: Call_CreateBotVersion_601728; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new version of the bot based on the <code>$LATEST</code> version. If the <code>$LATEST</code> version of this resource hasn't changed since you created the last version, Amazon Lex doesn't create a new version. It returns the last created version.</p> <note> <p>You can update only the <code>$LATEST</code> version of the bot. You can't update the numbered versions that you create with the <code>CreateBotVersion</code> operation.</p> </note> <p> When you create the first version of a bot, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p> This operation requires permission for the <code>lex:CreateBotVersion</code> action. </p>
  ## 
  let valid = call_601887.validator(path, query, header, formData, body)
  let scheme = call_601887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601887.url(scheme.get, call_601887.host, call_601887.base,
                         call_601887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601887, url, valid)

proc call*(call_601958: Call_CreateBotVersion_601728; name: string; body: JsonNode): Recallable =
  ## createBotVersion
  ## <p>Creates a new version of the bot based on the <code>$LATEST</code> version. If the <code>$LATEST</code> version of this resource hasn't changed since you created the last version, Amazon Lex doesn't create a new version. It returns the last created version.</p> <note> <p>You can update only the <code>$LATEST</code> version of the bot. You can't update the numbered versions that you create with the <code>CreateBotVersion</code> operation.</p> </note> <p> When you create the first version of a bot, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p> This operation requires permission for the <code>lex:CreateBotVersion</code> action. </p>
  ##   name: string (required)
  ##       : The name of the bot that you want to create a new version of. The name is case sensitive. 
  ##   body: JObject (required)
  var path_601959 = newJObject()
  var body_601961 = newJObject()
  add(path_601959, "name", newJString(name))
  if body != nil:
    body_601961 = body
  result = call_601958.call(path_601959, nil, nil, nil, body_601961)

var createBotVersion* = Call_CreateBotVersion_601728(name: "createBotVersion",
    meth: HttpMethod.HttpPost, host: "models.lex.amazonaws.com",
    route: "/bots/{name}/versions", validator: validate_CreateBotVersion_601729,
    base: "/", url: url_CreateBotVersion_601730,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIntentVersion_602000 = ref object of OpenApiRestCall_601390
proc url_CreateIntentVersion_602002(protocol: Scheme; host: string; base: string;
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

proc validate_CreateIntentVersion_602001(path: JsonNode; query: JsonNode;
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
  var valid_602003 = path.getOrDefault("name")
  valid_602003 = validateParameter(valid_602003, JString, required = true,
                                 default = nil)
  if valid_602003 != nil:
    section.add "name", valid_602003
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
  var valid_602004 = header.getOrDefault("X-Amz-Signature")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Signature", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Content-Sha256", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Date")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Date", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-Credential")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Credential", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-Security-Token")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Security-Token", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-Algorithm")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Algorithm", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-SignedHeaders", valid_602010
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602012: Call_CreateIntentVersion_602000; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new version of an intent based on the <code>$LATEST</code> version of the intent. If the <code>$LATEST</code> version of this intent hasn't changed since you last updated it, Amazon Lex doesn't create a new version. It returns the last version you created.</p> <note> <p>You can update only the <code>$LATEST</code> version of the intent. You can't update the numbered versions that you create with the <code>CreateIntentVersion</code> operation.</p> </note> <p> When you create a version of an intent, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p>This operation requires permissions to perform the <code>lex:CreateIntentVersion</code> action. </p>
  ## 
  let valid = call_602012.validator(path, query, header, formData, body)
  let scheme = call_602012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602012.url(scheme.get, call_602012.host, call_602012.base,
                         call_602012.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602012, url, valid)

proc call*(call_602013: Call_CreateIntentVersion_602000; name: string; body: JsonNode): Recallable =
  ## createIntentVersion
  ## <p>Creates a new version of an intent based on the <code>$LATEST</code> version of the intent. If the <code>$LATEST</code> version of this intent hasn't changed since you last updated it, Amazon Lex doesn't create a new version. It returns the last version you created.</p> <note> <p>You can update only the <code>$LATEST</code> version of the intent. You can't update the numbered versions that you create with the <code>CreateIntentVersion</code> operation.</p> </note> <p> When you create a version of an intent, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p>This operation requires permissions to perform the <code>lex:CreateIntentVersion</code> action. </p>
  ##   name: string (required)
  ##       : The name of the intent that you want to create a new version of. The name is case sensitive. 
  ##   body: JObject (required)
  var path_602014 = newJObject()
  var body_602015 = newJObject()
  add(path_602014, "name", newJString(name))
  if body != nil:
    body_602015 = body
  result = call_602013.call(path_602014, nil, nil, nil, body_602015)

var createIntentVersion* = Call_CreateIntentVersion_602000(
    name: "createIntentVersion", meth: HttpMethod.HttpPost,
    host: "models.lex.amazonaws.com", route: "/intents/{name}/versions",
    validator: validate_CreateIntentVersion_602001, base: "/",
    url: url_CreateIntentVersion_602002, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSlotTypeVersion_602016 = ref object of OpenApiRestCall_601390
proc url_CreateSlotTypeVersion_602018(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSlotTypeVersion_602017(path: JsonNode; query: JsonNode;
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
  var valid_602019 = path.getOrDefault("name")
  valid_602019 = validateParameter(valid_602019, JString, required = true,
                                 default = nil)
  if valid_602019 != nil:
    section.add "name", valid_602019
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
  var valid_602020 = header.getOrDefault("X-Amz-Signature")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Signature", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Content-Sha256", valid_602021
  var valid_602022 = header.getOrDefault("X-Amz-Date")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-Date", valid_602022
  var valid_602023 = header.getOrDefault("X-Amz-Credential")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-Credential", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-Security-Token")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Security-Token", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Algorithm")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Algorithm", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-SignedHeaders", valid_602026
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602028: Call_CreateSlotTypeVersion_602016; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new version of a slot type based on the <code>$LATEST</code> version of the specified slot type. If the <code>$LATEST</code> version of this resource has not changed since the last version that you created, Amazon Lex doesn't create a new version. It returns the last version that you created. </p> <note> <p>You can update only the <code>$LATEST</code> version of a slot type. You can't update the numbered versions that you create with the <code>CreateSlotTypeVersion</code> operation.</p> </note> <p>When you create a version of a slot type, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p>This operation requires permissions for the <code>lex:CreateSlotTypeVersion</code> action.</p>
  ## 
  let valid = call_602028.validator(path, query, header, formData, body)
  let scheme = call_602028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602028.url(scheme.get, call_602028.host, call_602028.base,
                         call_602028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602028, url, valid)

proc call*(call_602029: Call_CreateSlotTypeVersion_602016; name: string;
          body: JsonNode): Recallable =
  ## createSlotTypeVersion
  ## <p>Creates a new version of a slot type based on the <code>$LATEST</code> version of the specified slot type. If the <code>$LATEST</code> version of this resource has not changed since the last version that you created, Amazon Lex doesn't create a new version. It returns the last version that you created. </p> <note> <p>You can update only the <code>$LATEST</code> version of a slot type. You can't update the numbered versions that you create with the <code>CreateSlotTypeVersion</code> operation.</p> </note> <p>When you create a version of a slot type, Amazon Lex sets the version to 1. Subsequent versions increment by 1. For more information, see <a>versioning-intro</a>. </p> <p>This operation requires permissions for the <code>lex:CreateSlotTypeVersion</code> action.</p>
  ##   name: string (required)
  ##       : The name of the slot type that you want to create a new version for. The name is case sensitive. 
  ##   body: JObject (required)
  var path_602030 = newJObject()
  var body_602031 = newJObject()
  add(path_602030, "name", newJString(name))
  if body != nil:
    body_602031 = body
  result = call_602029.call(path_602030, nil, nil, nil, body_602031)

var createSlotTypeVersion* = Call_CreateSlotTypeVersion_602016(
    name: "createSlotTypeVersion", meth: HttpMethod.HttpPost,
    host: "models.lex.amazonaws.com", route: "/slottypes/{name}/versions",
    validator: validate_CreateSlotTypeVersion_602017, base: "/",
    url: url_CreateSlotTypeVersion_602018, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBot_602032 = ref object of OpenApiRestCall_601390
proc url_DeleteBot_602034(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteBot_602033(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602035 = path.getOrDefault("name")
  valid_602035 = validateParameter(valid_602035, JString, required = true,
                                 default = nil)
  if valid_602035 != nil:
    section.add "name", valid_602035
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
  var valid_602036 = header.getOrDefault("X-Amz-Signature")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-Signature", valid_602036
  var valid_602037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-Content-Sha256", valid_602037
  var valid_602038 = header.getOrDefault("X-Amz-Date")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-Date", valid_602038
  var valid_602039 = header.getOrDefault("X-Amz-Credential")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-Credential", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-Security-Token")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-Security-Token", valid_602040
  var valid_602041 = header.getOrDefault("X-Amz-Algorithm")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Algorithm", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-SignedHeaders", valid_602042
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602043: Call_DeleteBot_602032; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes all versions of the bot, including the <code>$LATEST</code> version. To delete a specific version of the bot, use the <a>DeleteBotVersion</a> operation. The <code>DeleteBot</code> operation doesn't immediately remove the bot schema. Instead, it is marked for deletion and removed later.</p> <p>Amazon Lex stores utterances indefinitely for improving the ability of your bot to respond to user inputs. These utterances are not removed when the bot is deleted. To remove the utterances, use the <a>DeleteUtterances</a> operation.</p> <p>If a bot has an alias, you can't delete it. Instead, the <code>DeleteBot</code> operation returns a <code>ResourceInUseException</code> exception that includes a reference to the alias that refers to the bot. To remove the reference to the bot, delete the alias. If you get the same exception again, delete the referring alias until the <code>DeleteBot</code> operation is successful.</p> <p>This operation requires permissions for the <code>lex:DeleteBot</code> action.</p>
  ## 
  let valid = call_602043.validator(path, query, header, formData, body)
  let scheme = call_602043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602043.url(scheme.get, call_602043.host, call_602043.base,
                         call_602043.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602043, url, valid)

proc call*(call_602044: Call_DeleteBot_602032; name: string): Recallable =
  ## deleteBot
  ## <p>Deletes all versions of the bot, including the <code>$LATEST</code> version. To delete a specific version of the bot, use the <a>DeleteBotVersion</a> operation. The <code>DeleteBot</code> operation doesn't immediately remove the bot schema. Instead, it is marked for deletion and removed later.</p> <p>Amazon Lex stores utterances indefinitely for improving the ability of your bot to respond to user inputs. These utterances are not removed when the bot is deleted. To remove the utterances, use the <a>DeleteUtterances</a> operation.</p> <p>If a bot has an alias, you can't delete it. Instead, the <code>DeleteBot</code> operation returns a <code>ResourceInUseException</code> exception that includes a reference to the alias that refers to the bot. To remove the reference to the bot, delete the alias. If you get the same exception again, delete the referring alias until the <code>DeleteBot</code> operation is successful.</p> <p>This operation requires permissions for the <code>lex:DeleteBot</code> action.</p>
  ##   name: string (required)
  ##       : The name of the bot. The name is case sensitive. 
  var path_602045 = newJObject()
  add(path_602045, "name", newJString(name))
  result = call_602044.call(path_602045, nil, nil, nil, nil)

var deleteBot* = Call_DeleteBot_602032(name: "deleteBot",
                                    meth: HttpMethod.HttpDelete,
                                    host: "models.lex.amazonaws.com",
                                    route: "/bots/{name}",
                                    validator: validate_DeleteBot_602033,
                                    base: "/", url: url_DeleteBot_602034,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBotAlias_602061 = ref object of OpenApiRestCall_601390
proc url_PutBotAlias_602063(protocol: Scheme; host: string; base: string;
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

proc validate_PutBotAlias_602062(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602064 = path.getOrDefault("botName")
  valid_602064 = validateParameter(valid_602064, JString, required = true,
                                 default = nil)
  if valid_602064 != nil:
    section.add "botName", valid_602064
  var valid_602065 = path.getOrDefault("name")
  valid_602065 = validateParameter(valid_602065, JString, required = true,
                                 default = nil)
  if valid_602065 != nil:
    section.add "name", valid_602065
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
  var valid_602066 = header.getOrDefault("X-Amz-Signature")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-Signature", valid_602066
  var valid_602067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-Content-Sha256", valid_602067
  var valid_602068 = header.getOrDefault("X-Amz-Date")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "X-Amz-Date", valid_602068
  var valid_602069 = header.getOrDefault("X-Amz-Credential")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "X-Amz-Credential", valid_602069
  var valid_602070 = header.getOrDefault("X-Amz-Security-Token")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "X-Amz-Security-Token", valid_602070
  var valid_602071 = header.getOrDefault("X-Amz-Algorithm")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-Algorithm", valid_602071
  var valid_602072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-SignedHeaders", valid_602072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602074: Call_PutBotAlias_602061; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an alias for the specified version of the bot or replaces an alias for the specified bot. To change the version of the bot that the alias points to, replace the alias. For more information about aliases, see <a>versioning-aliases</a>.</p> <p>This operation requires permissions for the <code>lex:PutBotAlias</code> action. </p>
  ## 
  let valid = call_602074.validator(path, query, header, formData, body)
  let scheme = call_602074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602074.url(scheme.get, call_602074.host, call_602074.base,
                         call_602074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602074, url, valid)

proc call*(call_602075: Call_PutBotAlias_602061; botName: string; name: string;
          body: JsonNode): Recallable =
  ## putBotAlias
  ## <p>Creates an alias for the specified version of the bot or replaces an alias for the specified bot. To change the version of the bot that the alias points to, replace the alias. For more information about aliases, see <a>versioning-aliases</a>.</p> <p>This operation requires permissions for the <code>lex:PutBotAlias</code> action. </p>
  ##   botName: string (required)
  ##          : The name of the bot.
  ##   name: string (required)
  ##       : The name of the alias. The name is <i>not</i> case sensitive.
  ##   body: JObject (required)
  var path_602076 = newJObject()
  var body_602077 = newJObject()
  add(path_602076, "botName", newJString(botName))
  add(path_602076, "name", newJString(name))
  if body != nil:
    body_602077 = body
  result = call_602075.call(path_602076, nil, nil, nil, body_602077)

var putBotAlias* = Call_PutBotAlias_602061(name: "putBotAlias",
                                        meth: HttpMethod.HttpPut,
                                        host: "models.lex.amazonaws.com", route: "/bots/{botName}/aliases/{name}",
                                        validator: validate_PutBotAlias_602062,
                                        base: "/", url: url_PutBotAlias_602063,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBotAlias_602046 = ref object of OpenApiRestCall_601390
proc url_GetBotAlias_602048(protocol: Scheme; host: string; base: string;
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

proc validate_GetBotAlias_602047(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602049 = path.getOrDefault("botName")
  valid_602049 = validateParameter(valid_602049, JString, required = true,
                                 default = nil)
  if valid_602049 != nil:
    section.add "botName", valid_602049
  var valid_602050 = path.getOrDefault("name")
  valid_602050 = validateParameter(valid_602050, JString, required = true,
                                 default = nil)
  if valid_602050 != nil:
    section.add "name", valid_602050
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
  var valid_602051 = header.getOrDefault("X-Amz-Signature")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Signature", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-Content-Sha256", valid_602052
  var valid_602053 = header.getOrDefault("X-Amz-Date")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-Date", valid_602053
  var valid_602054 = header.getOrDefault("X-Amz-Credential")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "X-Amz-Credential", valid_602054
  var valid_602055 = header.getOrDefault("X-Amz-Security-Token")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "X-Amz-Security-Token", valid_602055
  var valid_602056 = header.getOrDefault("X-Amz-Algorithm")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "X-Amz-Algorithm", valid_602056
  var valid_602057 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602057 = validateParameter(valid_602057, JString, required = false,
                                 default = nil)
  if valid_602057 != nil:
    section.add "X-Amz-SignedHeaders", valid_602057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602058: Call_GetBotAlias_602046; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about an Amazon Lex bot alias. For more information about aliases, see <a>versioning-aliases</a>.</p> <p>This operation requires permissions for the <code>lex:GetBotAlias</code> action.</p>
  ## 
  let valid = call_602058.validator(path, query, header, formData, body)
  let scheme = call_602058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602058.url(scheme.get, call_602058.host, call_602058.base,
                         call_602058.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602058, url, valid)

proc call*(call_602059: Call_GetBotAlias_602046; botName: string; name: string): Recallable =
  ## getBotAlias
  ## <p>Returns information about an Amazon Lex bot alias. For more information about aliases, see <a>versioning-aliases</a>.</p> <p>This operation requires permissions for the <code>lex:GetBotAlias</code> action.</p>
  ##   botName: string (required)
  ##          : The name of the bot.
  ##   name: string (required)
  ##       : The name of the bot alias. The name is case sensitive.
  var path_602060 = newJObject()
  add(path_602060, "botName", newJString(botName))
  add(path_602060, "name", newJString(name))
  result = call_602059.call(path_602060, nil, nil, nil, nil)

var getBotAlias* = Call_GetBotAlias_602046(name: "getBotAlias",
                                        meth: HttpMethod.HttpGet,
                                        host: "models.lex.amazonaws.com", route: "/bots/{botName}/aliases/{name}",
                                        validator: validate_GetBotAlias_602047,
                                        base: "/", url: url_GetBotAlias_602048,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBotAlias_602078 = ref object of OpenApiRestCall_601390
proc url_DeleteBotAlias_602080(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBotAlias_602079(path: JsonNode; query: JsonNode;
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
  var valid_602081 = path.getOrDefault("botName")
  valid_602081 = validateParameter(valid_602081, JString, required = true,
                                 default = nil)
  if valid_602081 != nil:
    section.add "botName", valid_602081
  var valid_602082 = path.getOrDefault("name")
  valid_602082 = validateParameter(valid_602082, JString, required = true,
                                 default = nil)
  if valid_602082 != nil:
    section.add "name", valid_602082
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
  var valid_602083 = header.getOrDefault("X-Amz-Signature")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "X-Amz-Signature", valid_602083
  var valid_602084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "X-Amz-Content-Sha256", valid_602084
  var valid_602085 = header.getOrDefault("X-Amz-Date")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "X-Amz-Date", valid_602085
  var valid_602086 = header.getOrDefault("X-Amz-Credential")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "X-Amz-Credential", valid_602086
  var valid_602087 = header.getOrDefault("X-Amz-Security-Token")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-Security-Token", valid_602087
  var valid_602088 = header.getOrDefault("X-Amz-Algorithm")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "X-Amz-Algorithm", valid_602088
  var valid_602089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "X-Amz-SignedHeaders", valid_602089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602090: Call_DeleteBotAlias_602078; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an alias for the specified bot. </p> <p>You can't delete an alias that is used in the association between a bot and a messaging channel. If an alias is used in a channel association, the <code>DeleteBot</code> operation returns a <code>ResourceInUseException</code> exception that includes a reference to the channel association that refers to the bot. You can remove the reference to the alias by deleting the channel association. If you get the same exception again, delete the referring association until the <code>DeleteBotAlias</code> operation is successful.</p>
  ## 
  let valid = call_602090.validator(path, query, header, formData, body)
  let scheme = call_602090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602090.url(scheme.get, call_602090.host, call_602090.base,
                         call_602090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602090, url, valid)

proc call*(call_602091: Call_DeleteBotAlias_602078; botName: string; name: string): Recallable =
  ## deleteBotAlias
  ## <p>Deletes an alias for the specified bot. </p> <p>You can't delete an alias that is used in the association between a bot and a messaging channel. If an alias is used in a channel association, the <code>DeleteBot</code> operation returns a <code>ResourceInUseException</code> exception that includes a reference to the channel association that refers to the bot. You can remove the reference to the alias by deleting the channel association. If you get the same exception again, delete the referring association until the <code>DeleteBotAlias</code> operation is successful.</p>
  ##   botName: string (required)
  ##          : The name of the bot that the alias points to.
  ##   name: string (required)
  ##       : The name of the alias to delete. The name is case sensitive. 
  var path_602092 = newJObject()
  add(path_602092, "botName", newJString(botName))
  add(path_602092, "name", newJString(name))
  result = call_602091.call(path_602092, nil, nil, nil, nil)

var deleteBotAlias* = Call_DeleteBotAlias_602078(name: "deleteBotAlias",
    meth: HttpMethod.HttpDelete, host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/aliases/{name}", validator: validate_DeleteBotAlias_602079,
    base: "/", url: url_DeleteBotAlias_602080, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBotChannelAssociation_602093 = ref object of OpenApiRestCall_601390
proc url_GetBotChannelAssociation_602095(protocol: Scheme; host: string;
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

proc validate_GetBotChannelAssociation_602094(path: JsonNode; query: JsonNode;
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
  var valid_602096 = path.getOrDefault("botName")
  valid_602096 = validateParameter(valid_602096, JString, required = true,
                                 default = nil)
  if valid_602096 != nil:
    section.add "botName", valid_602096
  var valid_602097 = path.getOrDefault("name")
  valid_602097 = validateParameter(valid_602097, JString, required = true,
                                 default = nil)
  if valid_602097 != nil:
    section.add "name", valid_602097
  var valid_602098 = path.getOrDefault("aliasName")
  valid_602098 = validateParameter(valid_602098, JString, required = true,
                                 default = nil)
  if valid_602098 != nil:
    section.add "aliasName", valid_602098
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
  var valid_602099 = header.getOrDefault("X-Amz-Signature")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "X-Amz-Signature", valid_602099
  var valid_602100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602100 = validateParameter(valid_602100, JString, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "X-Amz-Content-Sha256", valid_602100
  var valid_602101 = header.getOrDefault("X-Amz-Date")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "X-Amz-Date", valid_602101
  var valid_602102 = header.getOrDefault("X-Amz-Credential")
  valid_602102 = validateParameter(valid_602102, JString, required = false,
                                 default = nil)
  if valid_602102 != nil:
    section.add "X-Amz-Credential", valid_602102
  var valid_602103 = header.getOrDefault("X-Amz-Security-Token")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "X-Amz-Security-Token", valid_602103
  var valid_602104 = header.getOrDefault("X-Amz-Algorithm")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "X-Amz-Algorithm", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-SignedHeaders", valid_602105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602106: Call_GetBotChannelAssociation_602093; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about the association between an Amazon Lex bot and a messaging platform.</p> <p>This operation requires permissions for the <code>lex:GetBotChannelAssociation</code> action.</p>
  ## 
  let valid = call_602106.validator(path, query, header, formData, body)
  let scheme = call_602106.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602106.url(scheme.get, call_602106.host, call_602106.base,
                         call_602106.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602106, url, valid)

proc call*(call_602107: Call_GetBotChannelAssociation_602093; botName: string;
          name: string; aliasName: string): Recallable =
  ## getBotChannelAssociation
  ## <p>Returns information about the association between an Amazon Lex bot and a messaging platform.</p> <p>This operation requires permissions for the <code>lex:GetBotChannelAssociation</code> action.</p>
  ##   botName: string (required)
  ##          : The name of the Amazon Lex bot.
  ##   name: string (required)
  ##       : The name of the association between the bot and the channel. The name is case sensitive. 
  ##   aliasName: string (required)
  ##            : An alias pointing to the specific version of the Amazon Lex bot to which this association is being made.
  var path_602108 = newJObject()
  add(path_602108, "botName", newJString(botName))
  add(path_602108, "name", newJString(name))
  add(path_602108, "aliasName", newJString(aliasName))
  result = call_602107.call(path_602108, nil, nil, nil, nil)

var getBotChannelAssociation* = Call_GetBotChannelAssociation_602093(
    name: "getBotChannelAssociation", meth: HttpMethod.HttpGet,
    host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/aliases/{aliasName}/channels/{name}",
    validator: validate_GetBotChannelAssociation_602094, base: "/",
    url: url_GetBotChannelAssociation_602095, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBotChannelAssociation_602109 = ref object of OpenApiRestCall_601390
proc url_DeleteBotChannelAssociation_602111(protocol: Scheme; host: string;
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

proc validate_DeleteBotChannelAssociation_602110(path: JsonNode; query: JsonNode;
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
  var valid_602112 = path.getOrDefault("botName")
  valid_602112 = validateParameter(valid_602112, JString, required = true,
                                 default = nil)
  if valid_602112 != nil:
    section.add "botName", valid_602112
  var valid_602113 = path.getOrDefault("name")
  valid_602113 = validateParameter(valid_602113, JString, required = true,
                                 default = nil)
  if valid_602113 != nil:
    section.add "name", valid_602113
  var valid_602114 = path.getOrDefault("aliasName")
  valid_602114 = validateParameter(valid_602114, JString, required = true,
                                 default = nil)
  if valid_602114 != nil:
    section.add "aliasName", valid_602114
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
  var valid_602115 = header.getOrDefault("X-Amz-Signature")
  valid_602115 = validateParameter(valid_602115, JString, required = false,
                                 default = nil)
  if valid_602115 != nil:
    section.add "X-Amz-Signature", valid_602115
  var valid_602116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602116 = validateParameter(valid_602116, JString, required = false,
                                 default = nil)
  if valid_602116 != nil:
    section.add "X-Amz-Content-Sha256", valid_602116
  var valid_602117 = header.getOrDefault("X-Amz-Date")
  valid_602117 = validateParameter(valid_602117, JString, required = false,
                                 default = nil)
  if valid_602117 != nil:
    section.add "X-Amz-Date", valid_602117
  var valid_602118 = header.getOrDefault("X-Amz-Credential")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "X-Amz-Credential", valid_602118
  var valid_602119 = header.getOrDefault("X-Amz-Security-Token")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "X-Amz-Security-Token", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-Algorithm")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Algorithm", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-SignedHeaders", valid_602121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602122: Call_DeleteBotChannelAssociation_602109; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the association between an Amazon Lex bot and a messaging platform.</p> <p>This operation requires permission for the <code>lex:DeleteBotChannelAssociation</code> action.</p>
  ## 
  let valid = call_602122.validator(path, query, header, formData, body)
  let scheme = call_602122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602122.url(scheme.get, call_602122.host, call_602122.base,
                         call_602122.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602122, url, valid)

proc call*(call_602123: Call_DeleteBotChannelAssociation_602109; botName: string;
          name: string; aliasName: string): Recallable =
  ## deleteBotChannelAssociation
  ## <p>Deletes the association between an Amazon Lex bot and a messaging platform.</p> <p>This operation requires permission for the <code>lex:DeleteBotChannelAssociation</code> action.</p>
  ##   botName: string (required)
  ##          : The name of the Amazon Lex bot.
  ##   name: string (required)
  ##       : The name of the association. The name is case sensitive. 
  ##   aliasName: string (required)
  ##            : An alias that points to the specific version of the Amazon Lex bot to which this association is being made.
  var path_602124 = newJObject()
  add(path_602124, "botName", newJString(botName))
  add(path_602124, "name", newJString(name))
  add(path_602124, "aliasName", newJString(aliasName))
  result = call_602123.call(path_602124, nil, nil, nil, nil)

var deleteBotChannelAssociation* = Call_DeleteBotChannelAssociation_602109(
    name: "deleteBotChannelAssociation", meth: HttpMethod.HttpDelete,
    host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/aliases/{aliasName}/channels/{name}",
    validator: validate_DeleteBotChannelAssociation_602110, base: "/",
    url: url_DeleteBotChannelAssociation_602111,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteBotVersion_602125 = ref object of OpenApiRestCall_601390
proc url_DeleteBotVersion_602127(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteBotVersion_602126(path: JsonNode; query: JsonNode;
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
  var valid_602128 = path.getOrDefault("version")
  valid_602128 = validateParameter(valid_602128, JString, required = true,
                                 default = nil)
  if valid_602128 != nil:
    section.add "version", valid_602128
  var valid_602129 = path.getOrDefault("name")
  valid_602129 = validateParameter(valid_602129, JString, required = true,
                                 default = nil)
  if valid_602129 != nil:
    section.add "name", valid_602129
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
  var valid_602130 = header.getOrDefault("X-Amz-Signature")
  valid_602130 = validateParameter(valid_602130, JString, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "X-Amz-Signature", valid_602130
  var valid_602131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "X-Amz-Content-Sha256", valid_602131
  var valid_602132 = header.getOrDefault("X-Amz-Date")
  valid_602132 = validateParameter(valid_602132, JString, required = false,
                                 default = nil)
  if valid_602132 != nil:
    section.add "X-Amz-Date", valid_602132
  var valid_602133 = header.getOrDefault("X-Amz-Credential")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "X-Amz-Credential", valid_602133
  var valid_602134 = header.getOrDefault("X-Amz-Security-Token")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "X-Amz-Security-Token", valid_602134
  var valid_602135 = header.getOrDefault("X-Amz-Algorithm")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-Algorithm", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-SignedHeaders", valid_602136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602137: Call_DeleteBotVersion_602125; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a specific version of a bot. To delete all versions of a bot, use the <a>DeleteBot</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteBotVersion</code> action.</p>
  ## 
  let valid = call_602137.validator(path, query, header, formData, body)
  let scheme = call_602137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602137.url(scheme.get, call_602137.host, call_602137.base,
                         call_602137.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602137, url, valid)

proc call*(call_602138: Call_DeleteBotVersion_602125; version: string; name: string): Recallable =
  ## deleteBotVersion
  ## <p>Deletes a specific version of a bot. To delete all versions of a bot, use the <a>DeleteBot</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteBotVersion</code> action.</p>
  ##   version: string (required)
  ##          : The version of the bot to delete. You cannot delete the <code>$LATEST</code> version of the bot. To delete the <code>$LATEST</code> version, use the <a>DeleteBot</a> operation.
  ##   name: string (required)
  ##       : The name of the bot.
  var path_602139 = newJObject()
  add(path_602139, "version", newJString(version))
  add(path_602139, "name", newJString(name))
  result = call_602138.call(path_602139, nil, nil, nil, nil)

var deleteBotVersion* = Call_DeleteBotVersion_602125(name: "deleteBotVersion",
    meth: HttpMethod.HttpDelete, host: "models.lex.amazonaws.com",
    route: "/bots/{name}/versions/{version}",
    validator: validate_DeleteBotVersion_602126, base: "/",
    url: url_DeleteBotVersion_602127, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntent_602140 = ref object of OpenApiRestCall_601390
proc url_DeleteIntent_602142(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteIntent_602141(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602143 = path.getOrDefault("name")
  valid_602143 = validateParameter(valid_602143, JString, required = true,
                                 default = nil)
  if valid_602143 != nil:
    section.add "name", valid_602143
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
  var valid_602144 = header.getOrDefault("X-Amz-Signature")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Signature", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-Content-Sha256", valid_602145
  var valid_602146 = header.getOrDefault("X-Amz-Date")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-Date", valid_602146
  var valid_602147 = header.getOrDefault("X-Amz-Credential")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-Credential", valid_602147
  var valid_602148 = header.getOrDefault("X-Amz-Security-Token")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "X-Amz-Security-Token", valid_602148
  var valid_602149 = header.getOrDefault("X-Amz-Algorithm")
  valid_602149 = validateParameter(valid_602149, JString, required = false,
                                 default = nil)
  if valid_602149 != nil:
    section.add "X-Amz-Algorithm", valid_602149
  var valid_602150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-SignedHeaders", valid_602150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602151: Call_DeleteIntent_602140; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes all versions of the intent, including the <code>$LATEST</code> version. To delete a specific version of the intent, use the <a>DeleteIntentVersion</a> operation.</p> <p> You can delete a version of an intent only if it is not referenced. To delete an intent that is referred to in one or more bots (see <a>how-it-works</a>), you must remove those references first. </p> <note> <p> If you get the <code>ResourceInUseException</code> exception, it provides an example reference that shows where the intent is referenced. To remove the reference to the intent, either update the bot or delete it. If you get the same exception when you attempt to delete the intent again, repeat until the intent has no references and the call to <code>DeleteIntent</code> is successful. </p> </note> <p> This operation requires permission for the <code>lex:DeleteIntent</code> action. </p>
  ## 
  let valid = call_602151.validator(path, query, header, formData, body)
  let scheme = call_602151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602151.url(scheme.get, call_602151.host, call_602151.base,
                         call_602151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602151, url, valid)

proc call*(call_602152: Call_DeleteIntent_602140; name: string): Recallable =
  ## deleteIntent
  ## <p>Deletes all versions of the intent, including the <code>$LATEST</code> version. To delete a specific version of the intent, use the <a>DeleteIntentVersion</a> operation.</p> <p> You can delete a version of an intent only if it is not referenced. To delete an intent that is referred to in one or more bots (see <a>how-it-works</a>), you must remove those references first. </p> <note> <p> If you get the <code>ResourceInUseException</code> exception, it provides an example reference that shows where the intent is referenced. To remove the reference to the intent, either update the bot or delete it. If you get the same exception when you attempt to delete the intent again, repeat until the intent has no references and the call to <code>DeleteIntent</code> is successful. </p> </note> <p> This operation requires permission for the <code>lex:DeleteIntent</code> action. </p>
  ##   name: string (required)
  ##       : The name of the intent. The name is case sensitive. 
  var path_602153 = newJObject()
  add(path_602153, "name", newJString(name))
  result = call_602152.call(path_602153, nil, nil, nil, nil)

var deleteIntent* = Call_DeleteIntent_602140(name: "deleteIntent",
    meth: HttpMethod.HttpDelete, host: "models.lex.amazonaws.com",
    route: "/intents/{name}", validator: validate_DeleteIntent_602141, base: "/",
    url: url_DeleteIntent_602142, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntent_602154 = ref object of OpenApiRestCall_601390
proc url_GetIntent_602156(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetIntent_602155(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602157 = path.getOrDefault("version")
  valid_602157 = validateParameter(valid_602157, JString, required = true,
                                 default = nil)
  if valid_602157 != nil:
    section.add "version", valid_602157
  var valid_602158 = path.getOrDefault("name")
  valid_602158 = validateParameter(valid_602158, JString, required = true,
                                 default = nil)
  if valid_602158 != nil:
    section.add "name", valid_602158
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
  var valid_602159 = header.getOrDefault("X-Amz-Signature")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-Signature", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-Content-Sha256", valid_602160
  var valid_602161 = header.getOrDefault("X-Amz-Date")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-Date", valid_602161
  var valid_602162 = header.getOrDefault("X-Amz-Credential")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-Credential", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-Security-Token")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-Security-Token", valid_602163
  var valid_602164 = header.getOrDefault("X-Amz-Algorithm")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = nil)
  if valid_602164 != nil:
    section.add "X-Amz-Algorithm", valid_602164
  var valid_602165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-SignedHeaders", valid_602165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602166: Call_GetIntent_602154; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns information about an intent. In addition to the intent name, you must specify the intent version. </p> <p> This operation requires permissions to perform the <code>lex:GetIntent</code> action. </p>
  ## 
  let valid = call_602166.validator(path, query, header, formData, body)
  let scheme = call_602166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602166.url(scheme.get, call_602166.host, call_602166.base,
                         call_602166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602166, url, valid)

proc call*(call_602167: Call_GetIntent_602154; version: string; name: string): Recallable =
  ## getIntent
  ## <p> Returns information about an intent. In addition to the intent name, you must specify the intent version. </p> <p> This operation requires permissions to perform the <code>lex:GetIntent</code> action. </p>
  ##   version: string (required)
  ##          : The version of the intent.
  ##   name: string (required)
  ##       : The name of the intent. The name is case sensitive. 
  var path_602168 = newJObject()
  add(path_602168, "version", newJString(version))
  add(path_602168, "name", newJString(name))
  result = call_602167.call(path_602168, nil, nil, nil, nil)

var getIntent* = Call_GetIntent_602154(name: "getIntent", meth: HttpMethod.HttpGet,
                                    host: "models.lex.amazonaws.com", route: "/intents/{name}/versions/{version}",
                                    validator: validate_GetIntent_602155,
                                    base: "/", url: url_GetIntent_602156,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIntentVersion_602169 = ref object of OpenApiRestCall_601390
proc url_DeleteIntentVersion_602171(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteIntentVersion_602170(path: JsonNode; query: JsonNode;
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
  var valid_602172 = path.getOrDefault("version")
  valid_602172 = validateParameter(valid_602172, JString, required = true,
                                 default = nil)
  if valid_602172 != nil:
    section.add "version", valid_602172
  var valid_602173 = path.getOrDefault("name")
  valid_602173 = validateParameter(valid_602173, JString, required = true,
                                 default = nil)
  if valid_602173 != nil:
    section.add "name", valid_602173
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
  var valid_602174 = header.getOrDefault("X-Amz-Signature")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "X-Amz-Signature", valid_602174
  var valid_602175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "X-Amz-Content-Sha256", valid_602175
  var valid_602176 = header.getOrDefault("X-Amz-Date")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "X-Amz-Date", valid_602176
  var valid_602177 = header.getOrDefault("X-Amz-Credential")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-Credential", valid_602177
  var valid_602178 = header.getOrDefault("X-Amz-Security-Token")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Security-Token", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-Algorithm")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Algorithm", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-SignedHeaders", valid_602180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602181: Call_DeleteIntentVersion_602169; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a specific version of an intent. To delete all versions of a intent, use the <a>DeleteIntent</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteIntentVersion</code> action.</p>
  ## 
  let valid = call_602181.validator(path, query, header, formData, body)
  let scheme = call_602181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602181.url(scheme.get, call_602181.host, call_602181.base,
                         call_602181.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602181, url, valid)

proc call*(call_602182: Call_DeleteIntentVersion_602169; version: string;
          name: string): Recallable =
  ## deleteIntentVersion
  ## <p>Deletes a specific version of an intent. To delete all versions of a intent, use the <a>DeleteIntent</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteIntentVersion</code> action.</p>
  ##   version: string (required)
  ##          : The version of the intent to delete. You cannot delete the <code>$LATEST</code> version of the intent. To delete the <code>$LATEST</code> version, use the <a>DeleteIntent</a> operation.
  ##   name: string (required)
  ##       : The name of the intent.
  var path_602183 = newJObject()
  add(path_602183, "version", newJString(version))
  add(path_602183, "name", newJString(name))
  result = call_602182.call(path_602183, nil, nil, nil, nil)

var deleteIntentVersion* = Call_DeleteIntentVersion_602169(
    name: "deleteIntentVersion", meth: HttpMethod.HttpDelete,
    host: "models.lex.amazonaws.com", route: "/intents/{name}/versions/{version}",
    validator: validate_DeleteIntentVersion_602170, base: "/",
    url: url_DeleteIntentVersion_602171, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSlotType_602184 = ref object of OpenApiRestCall_601390
proc url_DeleteSlotType_602186(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSlotType_602185(path: JsonNode; query: JsonNode;
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
  var valid_602187 = path.getOrDefault("name")
  valid_602187 = validateParameter(valid_602187, JString, required = true,
                                 default = nil)
  if valid_602187 != nil:
    section.add "name", valid_602187
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
  var valid_602188 = header.getOrDefault("X-Amz-Signature")
  valid_602188 = validateParameter(valid_602188, JString, required = false,
                                 default = nil)
  if valid_602188 != nil:
    section.add "X-Amz-Signature", valid_602188
  var valid_602189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "X-Amz-Content-Sha256", valid_602189
  var valid_602190 = header.getOrDefault("X-Amz-Date")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "X-Amz-Date", valid_602190
  var valid_602191 = header.getOrDefault("X-Amz-Credential")
  valid_602191 = validateParameter(valid_602191, JString, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "X-Amz-Credential", valid_602191
  var valid_602192 = header.getOrDefault("X-Amz-Security-Token")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-Security-Token", valid_602192
  var valid_602193 = header.getOrDefault("X-Amz-Algorithm")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-Algorithm", valid_602193
  var valid_602194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-SignedHeaders", valid_602194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602195: Call_DeleteSlotType_602184; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes all versions of the slot type, including the <code>$LATEST</code> version. To delete a specific version of the slot type, use the <a>DeleteSlotTypeVersion</a> operation.</p> <p> You can delete a version of a slot type only if it is not referenced. To delete a slot type that is referred to in one or more intents, you must remove those references first. </p> <note> <p> If you get the <code>ResourceInUseException</code> exception, the exception provides an example reference that shows the intent where the slot type is referenced. To remove the reference to the slot type, either update the intent or delete it. If you get the same exception when you attempt to delete the slot type again, repeat until the slot type has no references and the <code>DeleteSlotType</code> call is successful. </p> </note> <p>This operation requires permission for the <code>lex:DeleteSlotType</code> action.</p>
  ## 
  let valid = call_602195.validator(path, query, header, formData, body)
  let scheme = call_602195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602195.url(scheme.get, call_602195.host, call_602195.base,
                         call_602195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602195, url, valid)

proc call*(call_602196: Call_DeleteSlotType_602184; name: string): Recallable =
  ## deleteSlotType
  ## <p>Deletes all versions of the slot type, including the <code>$LATEST</code> version. To delete a specific version of the slot type, use the <a>DeleteSlotTypeVersion</a> operation.</p> <p> You can delete a version of a slot type only if it is not referenced. To delete a slot type that is referred to in one or more intents, you must remove those references first. </p> <note> <p> If you get the <code>ResourceInUseException</code> exception, the exception provides an example reference that shows the intent where the slot type is referenced. To remove the reference to the slot type, either update the intent or delete it. If you get the same exception when you attempt to delete the slot type again, repeat until the slot type has no references and the <code>DeleteSlotType</code> call is successful. </p> </note> <p>This operation requires permission for the <code>lex:DeleteSlotType</code> action.</p>
  ##   name: string (required)
  ##       : The name of the slot type. The name is case sensitive. 
  var path_602197 = newJObject()
  add(path_602197, "name", newJString(name))
  result = call_602196.call(path_602197, nil, nil, nil, nil)

var deleteSlotType* = Call_DeleteSlotType_602184(name: "deleteSlotType",
    meth: HttpMethod.HttpDelete, host: "models.lex.amazonaws.com",
    route: "/slottypes/{name}", validator: validate_DeleteSlotType_602185,
    base: "/", url: url_DeleteSlotType_602186, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSlotTypeVersion_602198 = ref object of OpenApiRestCall_601390
proc url_DeleteSlotTypeVersion_602200(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSlotTypeVersion_602199(path: JsonNode; query: JsonNode;
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
  var valid_602201 = path.getOrDefault("version")
  valid_602201 = validateParameter(valid_602201, JString, required = true,
                                 default = nil)
  if valid_602201 != nil:
    section.add "version", valid_602201
  var valid_602202 = path.getOrDefault("name")
  valid_602202 = validateParameter(valid_602202, JString, required = true,
                                 default = nil)
  if valid_602202 != nil:
    section.add "name", valid_602202
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
  var valid_602203 = header.getOrDefault("X-Amz-Signature")
  valid_602203 = validateParameter(valid_602203, JString, required = false,
                                 default = nil)
  if valid_602203 != nil:
    section.add "X-Amz-Signature", valid_602203
  var valid_602204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602204 = validateParameter(valid_602204, JString, required = false,
                                 default = nil)
  if valid_602204 != nil:
    section.add "X-Amz-Content-Sha256", valid_602204
  var valid_602205 = header.getOrDefault("X-Amz-Date")
  valid_602205 = validateParameter(valid_602205, JString, required = false,
                                 default = nil)
  if valid_602205 != nil:
    section.add "X-Amz-Date", valid_602205
  var valid_602206 = header.getOrDefault("X-Amz-Credential")
  valid_602206 = validateParameter(valid_602206, JString, required = false,
                                 default = nil)
  if valid_602206 != nil:
    section.add "X-Amz-Credential", valid_602206
  var valid_602207 = header.getOrDefault("X-Amz-Security-Token")
  valid_602207 = validateParameter(valid_602207, JString, required = false,
                                 default = nil)
  if valid_602207 != nil:
    section.add "X-Amz-Security-Token", valid_602207
  var valid_602208 = header.getOrDefault("X-Amz-Algorithm")
  valid_602208 = validateParameter(valid_602208, JString, required = false,
                                 default = nil)
  if valid_602208 != nil:
    section.add "X-Amz-Algorithm", valid_602208
  var valid_602209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602209 = validateParameter(valid_602209, JString, required = false,
                                 default = nil)
  if valid_602209 != nil:
    section.add "X-Amz-SignedHeaders", valid_602209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602210: Call_DeleteSlotTypeVersion_602198; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a specific version of a slot type. To delete all versions of a slot type, use the <a>DeleteSlotType</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteSlotTypeVersion</code> action.</p>
  ## 
  let valid = call_602210.validator(path, query, header, formData, body)
  let scheme = call_602210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602210.url(scheme.get, call_602210.host, call_602210.base,
                         call_602210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602210, url, valid)

proc call*(call_602211: Call_DeleteSlotTypeVersion_602198; version: string;
          name: string): Recallable =
  ## deleteSlotTypeVersion
  ## <p>Deletes a specific version of a slot type. To delete all versions of a slot type, use the <a>DeleteSlotType</a> operation. </p> <p>This operation requires permissions for the <code>lex:DeleteSlotTypeVersion</code> action.</p>
  ##   version: string (required)
  ##          : The version of the slot type to delete. You cannot delete the <code>$LATEST</code> version of the slot type. To delete the <code>$LATEST</code> version, use the <a>DeleteSlotType</a> operation.
  ##   name: string (required)
  ##       : The name of the slot type.
  var path_602212 = newJObject()
  add(path_602212, "version", newJString(version))
  add(path_602212, "name", newJString(name))
  result = call_602211.call(path_602212, nil, nil, nil, nil)

var deleteSlotTypeVersion* = Call_DeleteSlotTypeVersion_602198(
    name: "deleteSlotTypeVersion", meth: HttpMethod.HttpDelete,
    host: "models.lex.amazonaws.com",
    route: "/slottypes/{name}/version/{version}",
    validator: validate_DeleteSlotTypeVersion_602199, base: "/",
    url: url_DeleteSlotTypeVersion_602200, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUtterances_602213 = ref object of OpenApiRestCall_601390
proc url_DeleteUtterances_602215(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUtterances_602214(path: JsonNode; query: JsonNode;
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
  var valid_602216 = path.getOrDefault("botName")
  valid_602216 = validateParameter(valid_602216, JString, required = true,
                                 default = nil)
  if valid_602216 != nil:
    section.add "botName", valid_602216
  var valid_602217 = path.getOrDefault("userId")
  valid_602217 = validateParameter(valid_602217, JString, required = true,
                                 default = nil)
  if valid_602217 != nil:
    section.add "userId", valid_602217
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
  var valid_602218 = header.getOrDefault("X-Amz-Signature")
  valid_602218 = validateParameter(valid_602218, JString, required = false,
                                 default = nil)
  if valid_602218 != nil:
    section.add "X-Amz-Signature", valid_602218
  var valid_602219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602219 = validateParameter(valid_602219, JString, required = false,
                                 default = nil)
  if valid_602219 != nil:
    section.add "X-Amz-Content-Sha256", valid_602219
  var valid_602220 = header.getOrDefault("X-Amz-Date")
  valid_602220 = validateParameter(valid_602220, JString, required = false,
                                 default = nil)
  if valid_602220 != nil:
    section.add "X-Amz-Date", valid_602220
  var valid_602221 = header.getOrDefault("X-Amz-Credential")
  valid_602221 = validateParameter(valid_602221, JString, required = false,
                                 default = nil)
  if valid_602221 != nil:
    section.add "X-Amz-Credential", valid_602221
  var valid_602222 = header.getOrDefault("X-Amz-Security-Token")
  valid_602222 = validateParameter(valid_602222, JString, required = false,
                                 default = nil)
  if valid_602222 != nil:
    section.add "X-Amz-Security-Token", valid_602222
  var valid_602223 = header.getOrDefault("X-Amz-Algorithm")
  valid_602223 = validateParameter(valid_602223, JString, required = false,
                                 default = nil)
  if valid_602223 != nil:
    section.add "X-Amz-Algorithm", valid_602223
  var valid_602224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602224 = validateParameter(valid_602224, JString, required = false,
                                 default = nil)
  if valid_602224 != nil:
    section.add "X-Amz-SignedHeaders", valid_602224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602225: Call_DeleteUtterances_602213; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes stored utterances.</p> <p>Amazon Lex stores the utterances that users send to your bot. Utterances are stored for 15 days for use with the <a>GetUtterancesView</a> operation, and then stored indefinitely for use in improving the ability of your bot to respond to user input.</p> <p>Use the <code>DeleteUtterances</code> operation to manually delete stored utterances for a specific user. When you use the <code>DeleteUtterances</code> operation, utterances stored for improving your bot's ability to respond to user input are deleted immediately. Utterances stored for use with the <code>GetUtterancesView</code> operation are deleted after 15 days.</p> <p>This operation requires permissions for the <code>lex:DeleteUtterances</code> action.</p>
  ## 
  let valid = call_602225.validator(path, query, header, formData, body)
  let scheme = call_602225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602225.url(scheme.get, call_602225.host, call_602225.base,
                         call_602225.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602225, url, valid)

proc call*(call_602226: Call_DeleteUtterances_602213; botName: string; userId: string): Recallable =
  ## deleteUtterances
  ## <p>Deletes stored utterances.</p> <p>Amazon Lex stores the utterances that users send to your bot. Utterances are stored for 15 days for use with the <a>GetUtterancesView</a> operation, and then stored indefinitely for use in improving the ability of your bot to respond to user input.</p> <p>Use the <code>DeleteUtterances</code> operation to manually delete stored utterances for a specific user. When you use the <code>DeleteUtterances</code> operation, utterances stored for improving your bot's ability to respond to user input are deleted immediately. Utterances stored for use with the <code>GetUtterancesView</code> operation are deleted after 15 days.</p> <p>This operation requires permissions for the <code>lex:DeleteUtterances</code> action.</p>
  ##   botName: string (required)
  ##          : The name of the bot that stored the utterances.
  ##   userId: string (required)
  ##         :  The unique identifier for the user that made the utterances. This is the user ID that was sent in the <a 
  ## href="http://docs.aws.amazon.com/lex/latest/dg/API_runtime_PostContent.html">PostContent</a> or <a 
  ## href="http://docs.aws.amazon.com/lex/latest/dg/API_runtime_PostText.html">PostText</a> operation request that contained the utterance.
  var path_602227 = newJObject()
  add(path_602227, "botName", newJString(botName))
  add(path_602227, "userId", newJString(userId))
  result = call_602226.call(path_602227, nil, nil, nil, nil)

var deleteUtterances* = Call_DeleteUtterances_602213(name: "deleteUtterances",
    meth: HttpMethod.HttpDelete, host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/utterances/{userId}",
    validator: validate_DeleteUtterances_602214, base: "/",
    url: url_DeleteUtterances_602215, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBot_602228 = ref object of OpenApiRestCall_601390
proc url_GetBot_602230(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetBot_602229(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602231 = path.getOrDefault("name")
  valid_602231 = validateParameter(valid_602231, JString, required = true,
                                 default = nil)
  if valid_602231 != nil:
    section.add "name", valid_602231
  var valid_602232 = path.getOrDefault("versionoralias")
  valid_602232 = validateParameter(valid_602232, JString, required = true,
                                 default = nil)
  if valid_602232 != nil:
    section.add "versionoralias", valid_602232
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
  var valid_602233 = header.getOrDefault("X-Amz-Signature")
  valid_602233 = validateParameter(valid_602233, JString, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "X-Amz-Signature", valid_602233
  var valid_602234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "X-Amz-Content-Sha256", valid_602234
  var valid_602235 = header.getOrDefault("X-Amz-Date")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "X-Amz-Date", valid_602235
  var valid_602236 = header.getOrDefault("X-Amz-Credential")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "X-Amz-Credential", valid_602236
  var valid_602237 = header.getOrDefault("X-Amz-Security-Token")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "X-Amz-Security-Token", valid_602237
  var valid_602238 = header.getOrDefault("X-Amz-Algorithm")
  valid_602238 = validateParameter(valid_602238, JString, required = false,
                                 default = nil)
  if valid_602238 != nil:
    section.add "X-Amz-Algorithm", valid_602238
  var valid_602239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602239 = validateParameter(valid_602239, JString, required = false,
                                 default = nil)
  if valid_602239 != nil:
    section.add "X-Amz-SignedHeaders", valid_602239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602240: Call_GetBot_602228; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns metadata information for a specific bot. You must provide the bot name and the bot version or alias. </p> <p> This operation requires permissions for the <code>lex:GetBot</code> action. </p>
  ## 
  let valid = call_602240.validator(path, query, header, formData, body)
  let scheme = call_602240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602240.url(scheme.get, call_602240.host, call_602240.base,
                         call_602240.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602240, url, valid)

proc call*(call_602241: Call_GetBot_602228; name: string; versionoralias: string): Recallable =
  ## getBot
  ## <p>Returns metadata information for a specific bot. You must provide the bot name and the bot version or alias. </p> <p> This operation requires permissions for the <code>lex:GetBot</code> action. </p>
  ##   name: string (required)
  ##       : The name of the bot. The name is case sensitive. 
  ##   versionoralias: string (required)
  ##                 : The version or alias of the bot.
  var path_602242 = newJObject()
  add(path_602242, "name", newJString(name))
  add(path_602242, "versionoralias", newJString(versionoralias))
  result = call_602241.call(path_602242, nil, nil, nil, nil)

var getBot* = Call_GetBot_602228(name: "getBot", meth: HttpMethod.HttpGet,
                              host: "models.lex.amazonaws.com",
                              route: "/bots/{name}/versions/{versionoralias}",
                              validator: validate_GetBot_602229, base: "/",
                              url: url_GetBot_602230,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBotAliases_602243 = ref object of OpenApiRestCall_601390
proc url_GetBotAliases_602245(protocol: Scheme; host: string; base: string;
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

proc validate_GetBotAliases_602244(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602246 = path.getOrDefault("botName")
  valid_602246 = validateParameter(valid_602246, JString, required = true,
                                 default = nil)
  if valid_602246 != nil:
    section.add "botName", valid_602246
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A pagination token for fetching the next page of aliases. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of aliases, specify the pagination token in the next request. 
  ##   nameContains: JString
  ##               : Substring to match in bot alias names. An alias will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  ##   maxResults: JInt
  ##             : The maximum number of aliases to return in the response. The default is 50. . 
  section = newJObject()
  var valid_602247 = query.getOrDefault("nextToken")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "nextToken", valid_602247
  var valid_602248 = query.getOrDefault("nameContains")
  valid_602248 = validateParameter(valid_602248, JString, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "nameContains", valid_602248
  var valid_602249 = query.getOrDefault("maxResults")
  valid_602249 = validateParameter(valid_602249, JInt, required = false, default = nil)
  if valid_602249 != nil:
    section.add "maxResults", valid_602249
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
  var valid_602250 = header.getOrDefault("X-Amz-Signature")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "X-Amz-Signature", valid_602250
  var valid_602251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = nil)
  if valid_602251 != nil:
    section.add "X-Amz-Content-Sha256", valid_602251
  var valid_602252 = header.getOrDefault("X-Amz-Date")
  valid_602252 = validateParameter(valid_602252, JString, required = false,
                                 default = nil)
  if valid_602252 != nil:
    section.add "X-Amz-Date", valid_602252
  var valid_602253 = header.getOrDefault("X-Amz-Credential")
  valid_602253 = validateParameter(valid_602253, JString, required = false,
                                 default = nil)
  if valid_602253 != nil:
    section.add "X-Amz-Credential", valid_602253
  var valid_602254 = header.getOrDefault("X-Amz-Security-Token")
  valid_602254 = validateParameter(valid_602254, JString, required = false,
                                 default = nil)
  if valid_602254 != nil:
    section.add "X-Amz-Security-Token", valid_602254
  var valid_602255 = header.getOrDefault("X-Amz-Algorithm")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "X-Amz-Algorithm", valid_602255
  var valid_602256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "X-Amz-SignedHeaders", valid_602256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602257: Call_GetBotAliases_602243; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of aliases for a specified Amazon Lex bot.</p> <p>This operation requires permissions for the <code>lex:GetBotAliases</code> action.</p>
  ## 
  let valid = call_602257.validator(path, query, header, formData, body)
  let scheme = call_602257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602257.url(scheme.get, call_602257.host, call_602257.base,
                         call_602257.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602257, url, valid)

proc call*(call_602258: Call_GetBotAliases_602243; botName: string;
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
  var path_602259 = newJObject()
  var query_602260 = newJObject()
  add(query_602260, "nextToken", newJString(nextToken))
  add(path_602259, "botName", newJString(botName))
  add(query_602260, "nameContains", newJString(nameContains))
  add(query_602260, "maxResults", newJInt(maxResults))
  result = call_602258.call(path_602259, query_602260, nil, nil, nil)

var getBotAliases* = Call_GetBotAliases_602243(name: "getBotAliases",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/aliases/", validator: validate_GetBotAliases_602244,
    base: "/", url: url_GetBotAliases_602245, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBotChannelAssociations_602261 = ref object of OpenApiRestCall_601390
proc url_GetBotChannelAssociations_602263(protocol: Scheme; host: string;
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

proc validate_GetBotChannelAssociations_602262(path: JsonNode; query: JsonNode;
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
  var valid_602264 = path.getOrDefault("botName")
  valid_602264 = validateParameter(valid_602264, JString, required = true,
                                 default = nil)
  if valid_602264 != nil:
    section.add "botName", valid_602264
  var valid_602265 = path.getOrDefault("aliasName")
  valid_602265 = validateParameter(valid_602265, JString, required = true,
                                 default = nil)
  if valid_602265 != nil:
    section.add "aliasName", valid_602265
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of associations to return in the response. The default is 50. 
  ##   nextToken: JString
  ##            : A pagination token for fetching the next page of associations. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of associations, specify the pagination token in the next request. 
  ##   nameContains: JString
  ##               : Substring to match in channel association names. An association will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz." To return all bot channel associations, use a hyphen ("-") as the <code>nameContains</code> parameter.
  section = newJObject()
  var valid_602266 = query.getOrDefault("maxResults")
  valid_602266 = validateParameter(valid_602266, JInt, required = false, default = nil)
  if valid_602266 != nil:
    section.add "maxResults", valid_602266
  var valid_602267 = query.getOrDefault("nextToken")
  valid_602267 = validateParameter(valid_602267, JString, required = false,
                                 default = nil)
  if valid_602267 != nil:
    section.add "nextToken", valid_602267
  var valid_602268 = query.getOrDefault("nameContains")
  valid_602268 = validateParameter(valid_602268, JString, required = false,
                                 default = nil)
  if valid_602268 != nil:
    section.add "nameContains", valid_602268
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
  var valid_602269 = header.getOrDefault("X-Amz-Signature")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "X-Amz-Signature", valid_602269
  var valid_602270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602270 = validateParameter(valid_602270, JString, required = false,
                                 default = nil)
  if valid_602270 != nil:
    section.add "X-Amz-Content-Sha256", valid_602270
  var valid_602271 = header.getOrDefault("X-Amz-Date")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "X-Amz-Date", valid_602271
  var valid_602272 = header.getOrDefault("X-Amz-Credential")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-Credential", valid_602272
  var valid_602273 = header.getOrDefault("X-Amz-Security-Token")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "X-Amz-Security-Token", valid_602273
  var valid_602274 = header.getOrDefault("X-Amz-Algorithm")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "X-Amz-Algorithm", valid_602274
  var valid_602275 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602275 = validateParameter(valid_602275, JString, required = false,
                                 default = nil)
  if valid_602275 != nil:
    section.add "X-Amz-SignedHeaders", valid_602275
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602276: Call_GetBotChannelAssociations_602261; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns a list of all of the channels associated with the specified bot. </p> <p>The <code>GetBotChannelAssociations</code> operation requires permissions for the <code>lex:GetBotChannelAssociations</code> action.</p>
  ## 
  let valid = call_602276.validator(path, query, header, formData, body)
  let scheme = call_602276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602276.url(scheme.get, call_602276.host, call_602276.base,
                         call_602276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602276, url, valid)

proc call*(call_602277: Call_GetBotChannelAssociations_602261; botName: string;
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
  var path_602278 = newJObject()
  var query_602279 = newJObject()
  add(query_602279, "maxResults", newJInt(maxResults))
  add(query_602279, "nextToken", newJString(nextToken))
  add(path_602278, "botName", newJString(botName))
  add(query_602279, "nameContains", newJString(nameContains))
  add(path_602278, "aliasName", newJString(aliasName))
  result = call_602277.call(path_602278, query_602279, nil, nil, nil)

var getBotChannelAssociations* = Call_GetBotChannelAssociations_602261(
    name: "getBotChannelAssociations", meth: HttpMethod.HttpGet,
    host: "models.lex.amazonaws.com",
    route: "/bots/{botName}/aliases/{aliasName}/channels/",
    validator: validate_GetBotChannelAssociations_602262, base: "/",
    url: url_GetBotChannelAssociations_602263,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBotVersions_602280 = ref object of OpenApiRestCall_601390
proc url_GetBotVersions_602282(protocol: Scheme; host: string; base: string;
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

proc validate_GetBotVersions_602281(path: JsonNode; query: JsonNode;
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
  var valid_602283 = path.getOrDefault("name")
  valid_602283 = validateParameter(valid_602283, JString, required = true,
                                 default = nil)
  if valid_602283 != nil:
    section.add "name", valid_602283
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A pagination token for fetching the next page of bot versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  ##   maxResults: JInt
  ##             : The maximum number of bot versions to return in the response. The default is 10.
  section = newJObject()
  var valid_602284 = query.getOrDefault("nextToken")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "nextToken", valid_602284
  var valid_602285 = query.getOrDefault("maxResults")
  valid_602285 = validateParameter(valid_602285, JInt, required = false, default = nil)
  if valid_602285 != nil:
    section.add "maxResults", valid_602285
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
  var valid_602286 = header.getOrDefault("X-Amz-Signature")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "X-Amz-Signature", valid_602286
  var valid_602287 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "X-Amz-Content-Sha256", valid_602287
  var valid_602288 = header.getOrDefault("X-Amz-Date")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "X-Amz-Date", valid_602288
  var valid_602289 = header.getOrDefault("X-Amz-Credential")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "X-Amz-Credential", valid_602289
  var valid_602290 = header.getOrDefault("X-Amz-Security-Token")
  valid_602290 = validateParameter(valid_602290, JString, required = false,
                                 default = nil)
  if valid_602290 != nil:
    section.add "X-Amz-Security-Token", valid_602290
  var valid_602291 = header.getOrDefault("X-Amz-Algorithm")
  valid_602291 = validateParameter(valid_602291, JString, required = false,
                                 default = nil)
  if valid_602291 != nil:
    section.add "X-Amz-Algorithm", valid_602291
  var valid_602292 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602292 = validateParameter(valid_602292, JString, required = false,
                                 default = nil)
  if valid_602292 != nil:
    section.add "X-Amz-SignedHeaders", valid_602292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602293: Call_GetBotVersions_602280; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about all of the versions of a bot.</p> <p>The <code>GetBotVersions</code> operation returns a <code>BotMetadata</code> object for each version of a bot. For example, if a bot has three numbered versions, the <code>GetBotVersions</code> operation returns four <code>BotMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetBotVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetBotVersions</code> action.</p>
  ## 
  let valid = call_602293.validator(path, query, header, formData, body)
  let scheme = call_602293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602293.url(scheme.get, call_602293.host, call_602293.base,
                         call_602293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602293, url, valid)

proc call*(call_602294: Call_GetBotVersions_602280; name: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## getBotVersions
  ## <p>Gets information about all of the versions of a bot.</p> <p>The <code>GetBotVersions</code> operation returns a <code>BotMetadata</code> object for each version of a bot. For example, if a bot has three numbered versions, the <code>GetBotVersions</code> operation returns four <code>BotMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetBotVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetBotVersions</code> action.</p>
  ##   nextToken: string
  ##            : A pagination token for fetching the next page of bot versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  ##   name: string (required)
  ##       : The name of the bot for which versions should be returned.
  ##   maxResults: int
  ##             : The maximum number of bot versions to return in the response. The default is 10.
  var path_602295 = newJObject()
  var query_602296 = newJObject()
  add(query_602296, "nextToken", newJString(nextToken))
  add(path_602295, "name", newJString(name))
  add(query_602296, "maxResults", newJInt(maxResults))
  result = call_602294.call(path_602295, query_602296, nil, nil, nil)

var getBotVersions* = Call_GetBotVersions_602280(name: "getBotVersions",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/bots/{name}/versions/", validator: validate_GetBotVersions_602281,
    base: "/", url: url_GetBotVersions_602282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBots_602297 = ref object of OpenApiRestCall_601390
proc url_GetBots_602299(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetBots_602298(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602300 = query.getOrDefault("nextToken")
  valid_602300 = validateParameter(valid_602300, JString, required = false,
                                 default = nil)
  if valid_602300 != nil:
    section.add "nextToken", valid_602300
  var valid_602301 = query.getOrDefault("nameContains")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "nameContains", valid_602301
  var valid_602302 = query.getOrDefault("maxResults")
  valid_602302 = validateParameter(valid_602302, JInt, required = false, default = nil)
  if valid_602302 != nil:
    section.add "maxResults", valid_602302
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
  var valid_602303 = header.getOrDefault("X-Amz-Signature")
  valid_602303 = validateParameter(valid_602303, JString, required = false,
                                 default = nil)
  if valid_602303 != nil:
    section.add "X-Amz-Signature", valid_602303
  var valid_602304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602304 = validateParameter(valid_602304, JString, required = false,
                                 default = nil)
  if valid_602304 != nil:
    section.add "X-Amz-Content-Sha256", valid_602304
  var valid_602305 = header.getOrDefault("X-Amz-Date")
  valid_602305 = validateParameter(valid_602305, JString, required = false,
                                 default = nil)
  if valid_602305 != nil:
    section.add "X-Amz-Date", valid_602305
  var valid_602306 = header.getOrDefault("X-Amz-Credential")
  valid_602306 = validateParameter(valid_602306, JString, required = false,
                                 default = nil)
  if valid_602306 != nil:
    section.add "X-Amz-Credential", valid_602306
  var valid_602307 = header.getOrDefault("X-Amz-Security-Token")
  valid_602307 = validateParameter(valid_602307, JString, required = false,
                                 default = nil)
  if valid_602307 != nil:
    section.add "X-Amz-Security-Token", valid_602307
  var valid_602308 = header.getOrDefault("X-Amz-Algorithm")
  valid_602308 = validateParameter(valid_602308, JString, required = false,
                                 default = nil)
  if valid_602308 != nil:
    section.add "X-Amz-Algorithm", valid_602308
  var valid_602309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602309 = validateParameter(valid_602309, JString, required = false,
                                 default = nil)
  if valid_602309 != nil:
    section.add "X-Amz-SignedHeaders", valid_602309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602310: Call_GetBots_602297; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns bot information as follows: </p> <ul> <li> <p>If you provide the <code>nameContains</code> field, the response includes information for the <code>$LATEST</code> version of all bots whose name contains the specified string.</p> </li> <li> <p>If you don't specify the <code>nameContains</code> field, the operation returns information about the <code>$LATEST</code> version of all of your bots.</p> </li> </ul> <p>This operation requires permission for the <code>lex:GetBots</code> action.</p>
  ## 
  let valid = call_602310.validator(path, query, header, formData, body)
  let scheme = call_602310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602310.url(scheme.get, call_602310.host, call_602310.base,
                         call_602310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602310, url, valid)

proc call*(call_602311: Call_GetBots_602297; nextToken: string = "";
          nameContains: string = ""; maxResults: int = 0): Recallable =
  ## getBots
  ## <p>Returns bot information as follows: </p> <ul> <li> <p>If you provide the <code>nameContains</code> field, the response includes information for the <code>$LATEST</code> version of all bots whose name contains the specified string.</p> </li> <li> <p>If you don't specify the <code>nameContains</code> field, the operation returns information about the <code>$LATEST</code> version of all of your bots.</p> </li> </ul> <p>This operation requires permission for the <code>lex:GetBots</code> action.</p>
  ##   nextToken: string
  ##            : A pagination token that fetches the next page of bots. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of bots, specify the pagination token in the next request. 
  ##   nameContains: string
  ##               : Substring to match in bot names. A bot will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  ##   maxResults: int
  ##             : The maximum number of bots to return in the response that the request will return. The default is 10.
  var query_602312 = newJObject()
  add(query_602312, "nextToken", newJString(nextToken))
  add(query_602312, "nameContains", newJString(nameContains))
  add(query_602312, "maxResults", newJInt(maxResults))
  result = call_602311.call(nil, query_602312, nil, nil, nil)

var getBots* = Call_GetBots_602297(name: "getBots", meth: HttpMethod.HttpGet,
                                host: "models.lex.amazonaws.com", route: "/bots/",
                                validator: validate_GetBots_602298, base: "/",
                                url: url_GetBots_602299,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBuiltinIntent_602313 = ref object of OpenApiRestCall_601390
proc url_GetBuiltinIntent_602315(protocol: Scheme; host: string; base: string;
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

proc validate_GetBuiltinIntent_602314(path: JsonNode; query: JsonNode;
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
  var valid_602316 = path.getOrDefault("signature")
  valid_602316 = validateParameter(valid_602316, JString, required = true,
                                 default = nil)
  if valid_602316 != nil:
    section.add "signature", valid_602316
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
  var valid_602317 = header.getOrDefault("X-Amz-Signature")
  valid_602317 = validateParameter(valid_602317, JString, required = false,
                                 default = nil)
  if valid_602317 != nil:
    section.add "X-Amz-Signature", valid_602317
  var valid_602318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602318 = validateParameter(valid_602318, JString, required = false,
                                 default = nil)
  if valid_602318 != nil:
    section.add "X-Amz-Content-Sha256", valid_602318
  var valid_602319 = header.getOrDefault("X-Amz-Date")
  valid_602319 = validateParameter(valid_602319, JString, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "X-Amz-Date", valid_602319
  var valid_602320 = header.getOrDefault("X-Amz-Credential")
  valid_602320 = validateParameter(valid_602320, JString, required = false,
                                 default = nil)
  if valid_602320 != nil:
    section.add "X-Amz-Credential", valid_602320
  var valid_602321 = header.getOrDefault("X-Amz-Security-Token")
  valid_602321 = validateParameter(valid_602321, JString, required = false,
                                 default = nil)
  if valid_602321 != nil:
    section.add "X-Amz-Security-Token", valid_602321
  var valid_602322 = header.getOrDefault("X-Amz-Algorithm")
  valid_602322 = validateParameter(valid_602322, JString, required = false,
                                 default = nil)
  if valid_602322 != nil:
    section.add "X-Amz-Algorithm", valid_602322
  var valid_602323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602323 = validateParameter(valid_602323, JString, required = false,
                                 default = nil)
  if valid_602323 != nil:
    section.add "X-Amz-SignedHeaders", valid_602323
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602324: Call_GetBuiltinIntent_602313; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a built-in intent.</p> <p>This operation requires permission for the <code>lex:GetBuiltinIntent</code> action.</p>
  ## 
  let valid = call_602324.validator(path, query, header, formData, body)
  let scheme = call_602324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602324.url(scheme.get, call_602324.host, call_602324.base,
                         call_602324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602324, url, valid)

proc call*(call_602325: Call_GetBuiltinIntent_602313; signature: string): Recallable =
  ## getBuiltinIntent
  ## <p>Returns information about a built-in intent.</p> <p>This operation requires permission for the <code>lex:GetBuiltinIntent</code> action.</p>
  ##   signature: string (required)
  ##            : The unique identifier for a built-in intent. To find the signature for an intent, see <a 
  ## href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/standard-intents">Standard Built-in Intents</a> in the <i>Alexa Skills Kit</i>.
  var path_602326 = newJObject()
  add(path_602326, "signature", newJString(signature))
  result = call_602325.call(path_602326, nil, nil, nil, nil)

var getBuiltinIntent* = Call_GetBuiltinIntent_602313(name: "getBuiltinIntent",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/builtins/intents/{signature}", validator: validate_GetBuiltinIntent_602314,
    base: "/", url: url_GetBuiltinIntent_602315,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBuiltinIntents_602327 = ref object of OpenApiRestCall_601390
proc url_GetBuiltinIntents_602329(protocol: Scheme; host: string; base: string;
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

proc validate_GetBuiltinIntents_602328(path: JsonNode; query: JsonNode;
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
  var valid_602330 = query.getOrDefault("nextToken")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "nextToken", valid_602330
  var valid_602344 = query.getOrDefault("locale")
  valid_602344 = validateParameter(valid_602344, JString, required = false,
                                 default = newJString("en-US"))
  if valid_602344 != nil:
    section.add "locale", valid_602344
  var valid_602345 = query.getOrDefault("signatureContains")
  valid_602345 = validateParameter(valid_602345, JString, required = false,
                                 default = nil)
  if valid_602345 != nil:
    section.add "signatureContains", valid_602345
  var valid_602346 = query.getOrDefault("maxResults")
  valid_602346 = validateParameter(valid_602346, JInt, required = false, default = nil)
  if valid_602346 != nil:
    section.add "maxResults", valid_602346
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
  var valid_602347 = header.getOrDefault("X-Amz-Signature")
  valid_602347 = validateParameter(valid_602347, JString, required = false,
                                 default = nil)
  if valid_602347 != nil:
    section.add "X-Amz-Signature", valid_602347
  var valid_602348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "X-Amz-Content-Sha256", valid_602348
  var valid_602349 = header.getOrDefault("X-Amz-Date")
  valid_602349 = validateParameter(valid_602349, JString, required = false,
                                 default = nil)
  if valid_602349 != nil:
    section.add "X-Amz-Date", valid_602349
  var valid_602350 = header.getOrDefault("X-Amz-Credential")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "X-Amz-Credential", valid_602350
  var valid_602351 = header.getOrDefault("X-Amz-Security-Token")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "X-Amz-Security-Token", valid_602351
  var valid_602352 = header.getOrDefault("X-Amz-Algorithm")
  valid_602352 = validateParameter(valid_602352, JString, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "X-Amz-Algorithm", valid_602352
  var valid_602353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602353 = validateParameter(valid_602353, JString, required = false,
                                 default = nil)
  if valid_602353 != nil:
    section.add "X-Amz-SignedHeaders", valid_602353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602354: Call_GetBuiltinIntents_602327; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of built-in intents that meet the specified criteria.</p> <p>This operation requires permission for the <code>lex:GetBuiltinIntents</code> action.</p>
  ## 
  let valid = call_602354.validator(path, query, header, formData, body)
  let scheme = call_602354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602354.url(scheme.get, call_602354.host, call_602354.base,
                         call_602354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602354, url, valid)

proc call*(call_602355: Call_GetBuiltinIntents_602327; nextToken: string = "";
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
  var query_602356 = newJObject()
  add(query_602356, "nextToken", newJString(nextToken))
  add(query_602356, "locale", newJString(locale))
  add(query_602356, "signatureContains", newJString(signatureContains))
  add(query_602356, "maxResults", newJInt(maxResults))
  result = call_602355.call(nil, query_602356, nil, nil, nil)

var getBuiltinIntents* = Call_GetBuiltinIntents_602327(name: "getBuiltinIntents",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/builtins/intents/", validator: validate_GetBuiltinIntents_602328,
    base: "/", url: url_GetBuiltinIntents_602329,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBuiltinSlotTypes_602357 = ref object of OpenApiRestCall_601390
proc url_GetBuiltinSlotTypes_602359(protocol: Scheme; host: string; base: string;
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

proc validate_GetBuiltinSlotTypes_602358(path: JsonNode; query: JsonNode;
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
  var valid_602360 = query.getOrDefault("nextToken")
  valid_602360 = validateParameter(valid_602360, JString, required = false,
                                 default = nil)
  if valid_602360 != nil:
    section.add "nextToken", valid_602360
  var valid_602361 = query.getOrDefault("locale")
  valid_602361 = validateParameter(valid_602361, JString, required = false,
                                 default = newJString("en-US"))
  if valid_602361 != nil:
    section.add "locale", valid_602361
  var valid_602362 = query.getOrDefault("signatureContains")
  valid_602362 = validateParameter(valid_602362, JString, required = false,
                                 default = nil)
  if valid_602362 != nil:
    section.add "signatureContains", valid_602362
  var valid_602363 = query.getOrDefault("maxResults")
  valid_602363 = validateParameter(valid_602363, JInt, required = false, default = nil)
  if valid_602363 != nil:
    section.add "maxResults", valid_602363
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
  var valid_602364 = header.getOrDefault("X-Amz-Signature")
  valid_602364 = validateParameter(valid_602364, JString, required = false,
                                 default = nil)
  if valid_602364 != nil:
    section.add "X-Amz-Signature", valid_602364
  var valid_602365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602365 = validateParameter(valid_602365, JString, required = false,
                                 default = nil)
  if valid_602365 != nil:
    section.add "X-Amz-Content-Sha256", valid_602365
  var valid_602366 = header.getOrDefault("X-Amz-Date")
  valid_602366 = validateParameter(valid_602366, JString, required = false,
                                 default = nil)
  if valid_602366 != nil:
    section.add "X-Amz-Date", valid_602366
  var valid_602367 = header.getOrDefault("X-Amz-Credential")
  valid_602367 = validateParameter(valid_602367, JString, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "X-Amz-Credential", valid_602367
  var valid_602368 = header.getOrDefault("X-Amz-Security-Token")
  valid_602368 = validateParameter(valid_602368, JString, required = false,
                                 default = nil)
  if valid_602368 != nil:
    section.add "X-Amz-Security-Token", valid_602368
  var valid_602369 = header.getOrDefault("X-Amz-Algorithm")
  valid_602369 = validateParameter(valid_602369, JString, required = false,
                                 default = nil)
  if valid_602369 != nil:
    section.add "X-Amz-Algorithm", valid_602369
  var valid_602370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602370 = validateParameter(valid_602370, JString, required = false,
                                 default = nil)
  if valid_602370 != nil:
    section.add "X-Amz-SignedHeaders", valid_602370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602371: Call_GetBuiltinSlotTypes_602357; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of built-in slot types that meet the specified criteria.</p> <p>For a list of built-in slot types, see <a href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/slot-type-reference">Slot Type Reference</a> in the <i>Alexa Skills Kit</i>.</p> <p>This operation requires permission for the <code>lex:GetBuiltInSlotTypes</code> action.</p>
  ## 
  let valid = call_602371.validator(path, query, header, formData, body)
  let scheme = call_602371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602371.url(scheme.get, call_602371.host, call_602371.base,
                         call_602371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602371, url, valid)

proc call*(call_602372: Call_GetBuiltinSlotTypes_602357; nextToken: string = "";
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
  var query_602373 = newJObject()
  add(query_602373, "nextToken", newJString(nextToken))
  add(query_602373, "locale", newJString(locale))
  add(query_602373, "signatureContains", newJString(signatureContains))
  add(query_602373, "maxResults", newJInt(maxResults))
  result = call_602372.call(nil, query_602373, nil, nil, nil)

var getBuiltinSlotTypes* = Call_GetBuiltinSlotTypes_602357(
    name: "getBuiltinSlotTypes", meth: HttpMethod.HttpGet,
    host: "models.lex.amazonaws.com", route: "/builtins/slottypes/",
    validator: validate_GetBuiltinSlotTypes_602358, base: "/",
    url: url_GetBuiltinSlotTypes_602359, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetExport_602374 = ref object of OpenApiRestCall_601390
proc url_GetExport_602376(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetExport_602375(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602377 = query.getOrDefault("name")
  valid_602377 = validateParameter(valid_602377, JString, required = true,
                                 default = nil)
  if valid_602377 != nil:
    section.add "name", valid_602377
  var valid_602378 = query.getOrDefault("version")
  valid_602378 = validateParameter(valid_602378, JString, required = true,
                                 default = nil)
  if valid_602378 != nil:
    section.add "version", valid_602378
  var valid_602379 = query.getOrDefault("resourceType")
  valid_602379 = validateParameter(valid_602379, JString, required = true,
                                 default = newJString("BOT"))
  if valid_602379 != nil:
    section.add "resourceType", valid_602379
  var valid_602380 = query.getOrDefault("exportType")
  valid_602380 = validateParameter(valid_602380, JString, required = true,
                                 default = newJString("ALEXA_SKILLS_KIT"))
  if valid_602380 != nil:
    section.add "exportType", valid_602380
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
  var valid_602381 = header.getOrDefault("X-Amz-Signature")
  valid_602381 = validateParameter(valid_602381, JString, required = false,
                                 default = nil)
  if valid_602381 != nil:
    section.add "X-Amz-Signature", valid_602381
  var valid_602382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "X-Amz-Content-Sha256", valid_602382
  var valid_602383 = header.getOrDefault("X-Amz-Date")
  valid_602383 = validateParameter(valid_602383, JString, required = false,
                                 default = nil)
  if valid_602383 != nil:
    section.add "X-Amz-Date", valid_602383
  var valid_602384 = header.getOrDefault("X-Amz-Credential")
  valid_602384 = validateParameter(valid_602384, JString, required = false,
                                 default = nil)
  if valid_602384 != nil:
    section.add "X-Amz-Credential", valid_602384
  var valid_602385 = header.getOrDefault("X-Amz-Security-Token")
  valid_602385 = validateParameter(valid_602385, JString, required = false,
                                 default = nil)
  if valid_602385 != nil:
    section.add "X-Amz-Security-Token", valid_602385
  var valid_602386 = header.getOrDefault("X-Amz-Algorithm")
  valid_602386 = validateParameter(valid_602386, JString, required = false,
                                 default = nil)
  if valid_602386 != nil:
    section.add "X-Amz-Algorithm", valid_602386
  var valid_602387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602387 = validateParameter(valid_602387, JString, required = false,
                                 default = nil)
  if valid_602387 != nil:
    section.add "X-Amz-SignedHeaders", valid_602387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602388: Call_GetExport_602374; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Exports the contents of a Amazon Lex resource in a specified format. 
  ## 
  let valid = call_602388.validator(path, query, header, formData, body)
  let scheme = call_602388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602388.url(scheme.get, call_602388.host, call_602388.base,
                         call_602388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602388, url, valid)

proc call*(call_602389: Call_GetExport_602374; name: string; version: string;
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
  var query_602390 = newJObject()
  add(query_602390, "name", newJString(name))
  add(query_602390, "version", newJString(version))
  add(query_602390, "resourceType", newJString(resourceType))
  add(query_602390, "exportType", newJString(exportType))
  result = call_602389.call(nil, query_602390, nil, nil, nil)

var getExport* = Call_GetExport_602374(name: "getExport", meth: HttpMethod.HttpGet,
                                    host: "models.lex.amazonaws.com", route: "/exports/#name&version&resourceType&exportType",
                                    validator: validate_GetExport_602375,
                                    base: "/", url: url_GetExport_602376,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetImport_602391 = ref object of OpenApiRestCall_601390
proc url_GetImport_602393(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetImport_602392(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602394 = path.getOrDefault("importId")
  valid_602394 = validateParameter(valid_602394, JString, required = true,
                                 default = nil)
  if valid_602394 != nil:
    section.add "importId", valid_602394
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
  var valid_602395 = header.getOrDefault("X-Amz-Signature")
  valid_602395 = validateParameter(valid_602395, JString, required = false,
                                 default = nil)
  if valid_602395 != nil:
    section.add "X-Amz-Signature", valid_602395
  var valid_602396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602396 = validateParameter(valid_602396, JString, required = false,
                                 default = nil)
  if valid_602396 != nil:
    section.add "X-Amz-Content-Sha256", valid_602396
  var valid_602397 = header.getOrDefault("X-Amz-Date")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "X-Amz-Date", valid_602397
  var valid_602398 = header.getOrDefault("X-Amz-Credential")
  valid_602398 = validateParameter(valid_602398, JString, required = false,
                                 default = nil)
  if valid_602398 != nil:
    section.add "X-Amz-Credential", valid_602398
  var valid_602399 = header.getOrDefault("X-Amz-Security-Token")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "X-Amz-Security-Token", valid_602399
  var valid_602400 = header.getOrDefault("X-Amz-Algorithm")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "X-Amz-Algorithm", valid_602400
  var valid_602401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602401 = validateParameter(valid_602401, JString, required = false,
                                 default = nil)
  if valid_602401 != nil:
    section.add "X-Amz-SignedHeaders", valid_602401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602402: Call_GetImport_602391; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about an import job started with the <code>StartImport</code> operation.
  ## 
  let valid = call_602402.validator(path, query, header, formData, body)
  let scheme = call_602402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602402.url(scheme.get, call_602402.host, call_602402.base,
                         call_602402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602402, url, valid)

proc call*(call_602403: Call_GetImport_602391; importId: string): Recallable =
  ## getImport
  ## Gets information about an import job started with the <code>StartImport</code> operation.
  ##   importId: string (required)
  ##           : The identifier of the import job information to return.
  var path_602404 = newJObject()
  add(path_602404, "importId", newJString(importId))
  result = call_602403.call(path_602404, nil, nil, nil, nil)

var getImport* = Call_GetImport_602391(name: "getImport", meth: HttpMethod.HttpGet,
                                    host: "models.lex.amazonaws.com",
                                    route: "/imports/{importId}",
                                    validator: validate_GetImport_602392,
                                    base: "/", url: url_GetImport_602393,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntentVersions_602405 = ref object of OpenApiRestCall_601390
proc url_GetIntentVersions_602407(protocol: Scheme; host: string; base: string;
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

proc validate_GetIntentVersions_602406(path: JsonNode; query: JsonNode;
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
  var valid_602408 = path.getOrDefault("name")
  valid_602408 = validateParameter(valid_602408, JString, required = true,
                                 default = nil)
  if valid_602408 != nil:
    section.add "name", valid_602408
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A pagination token for fetching the next page of intent versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  ##   maxResults: JInt
  ##             : The maximum number of intent versions to return in the response. The default is 10.
  section = newJObject()
  var valid_602409 = query.getOrDefault("nextToken")
  valid_602409 = validateParameter(valid_602409, JString, required = false,
                                 default = nil)
  if valid_602409 != nil:
    section.add "nextToken", valid_602409
  var valid_602410 = query.getOrDefault("maxResults")
  valid_602410 = validateParameter(valid_602410, JInt, required = false, default = nil)
  if valid_602410 != nil:
    section.add "maxResults", valid_602410
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
  var valid_602411 = header.getOrDefault("X-Amz-Signature")
  valid_602411 = validateParameter(valid_602411, JString, required = false,
                                 default = nil)
  if valid_602411 != nil:
    section.add "X-Amz-Signature", valid_602411
  var valid_602412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602412 = validateParameter(valid_602412, JString, required = false,
                                 default = nil)
  if valid_602412 != nil:
    section.add "X-Amz-Content-Sha256", valid_602412
  var valid_602413 = header.getOrDefault("X-Amz-Date")
  valid_602413 = validateParameter(valid_602413, JString, required = false,
                                 default = nil)
  if valid_602413 != nil:
    section.add "X-Amz-Date", valid_602413
  var valid_602414 = header.getOrDefault("X-Amz-Credential")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "X-Amz-Credential", valid_602414
  var valid_602415 = header.getOrDefault("X-Amz-Security-Token")
  valid_602415 = validateParameter(valid_602415, JString, required = false,
                                 default = nil)
  if valid_602415 != nil:
    section.add "X-Amz-Security-Token", valid_602415
  var valid_602416 = header.getOrDefault("X-Amz-Algorithm")
  valid_602416 = validateParameter(valid_602416, JString, required = false,
                                 default = nil)
  if valid_602416 != nil:
    section.add "X-Amz-Algorithm", valid_602416
  var valid_602417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602417 = validateParameter(valid_602417, JString, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "X-Amz-SignedHeaders", valid_602417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602418: Call_GetIntentVersions_602405; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about all of the versions of an intent.</p> <p>The <code>GetIntentVersions</code> operation returns an <code>IntentMetadata</code> object for each version of an intent. For example, if an intent has three numbered versions, the <code>GetIntentVersions</code> operation returns four <code>IntentMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetIntentVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetIntentVersions</code> action.</p>
  ## 
  let valid = call_602418.validator(path, query, header, formData, body)
  let scheme = call_602418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602418.url(scheme.get, call_602418.host, call_602418.base,
                         call_602418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602418, url, valid)

proc call*(call_602419: Call_GetIntentVersions_602405; name: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## getIntentVersions
  ## <p>Gets information about all of the versions of an intent.</p> <p>The <code>GetIntentVersions</code> operation returns an <code>IntentMetadata</code> object for each version of an intent. For example, if an intent has three numbered versions, the <code>GetIntentVersions</code> operation returns four <code>IntentMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetIntentVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetIntentVersions</code> action.</p>
  ##   nextToken: string
  ##            : A pagination token for fetching the next page of intent versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  ##   name: string (required)
  ##       : The name of the intent for which versions should be returned.
  ##   maxResults: int
  ##             : The maximum number of intent versions to return in the response. The default is 10.
  var path_602420 = newJObject()
  var query_602421 = newJObject()
  add(query_602421, "nextToken", newJString(nextToken))
  add(path_602420, "name", newJString(name))
  add(query_602421, "maxResults", newJInt(maxResults))
  result = call_602419.call(path_602420, query_602421, nil, nil, nil)

var getIntentVersions* = Call_GetIntentVersions_602405(name: "getIntentVersions",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/intents/{name}/versions/", validator: validate_GetIntentVersions_602406,
    base: "/", url: url_GetIntentVersions_602407,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIntents_602422 = ref object of OpenApiRestCall_601390
proc url_GetIntents_602424(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetIntents_602423(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602425 = query.getOrDefault("nextToken")
  valid_602425 = validateParameter(valid_602425, JString, required = false,
                                 default = nil)
  if valid_602425 != nil:
    section.add "nextToken", valid_602425
  var valid_602426 = query.getOrDefault("nameContains")
  valid_602426 = validateParameter(valid_602426, JString, required = false,
                                 default = nil)
  if valid_602426 != nil:
    section.add "nameContains", valid_602426
  var valid_602427 = query.getOrDefault("maxResults")
  valid_602427 = validateParameter(valid_602427, JInt, required = false, default = nil)
  if valid_602427 != nil:
    section.add "maxResults", valid_602427
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
  var valid_602428 = header.getOrDefault("X-Amz-Signature")
  valid_602428 = validateParameter(valid_602428, JString, required = false,
                                 default = nil)
  if valid_602428 != nil:
    section.add "X-Amz-Signature", valid_602428
  var valid_602429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602429 = validateParameter(valid_602429, JString, required = false,
                                 default = nil)
  if valid_602429 != nil:
    section.add "X-Amz-Content-Sha256", valid_602429
  var valid_602430 = header.getOrDefault("X-Amz-Date")
  valid_602430 = validateParameter(valid_602430, JString, required = false,
                                 default = nil)
  if valid_602430 != nil:
    section.add "X-Amz-Date", valid_602430
  var valid_602431 = header.getOrDefault("X-Amz-Credential")
  valid_602431 = validateParameter(valid_602431, JString, required = false,
                                 default = nil)
  if valid_602431 != nil:
    section.add "X-Amz-Credential", valid_602431
  var valid_602432 = header.getOrDefault("X-Amz-Security-Token")
  valid_602432 = validateParameter(valid_602432, JString, required = false,
                                 default = nil)
  if valid_602432 != nil:
    section.add "X-Amz-Security-Token", valid_602432
  var valid_602433 = header.getOrDefault("X-Amz-Algorithm")
  valid_602433 = validateParameter(valid_602433, JString, required = false,
                                 default = nil)
  if valid_602433 != nil:
    section.add "X-Amz-Algorithm", valid_602433
  var valid_602434 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602434 = validateParameter(valid_602434, JString, required = false,
                                 default = nil)
  if valid_602434 != nil:
    section.add "X-Amz-SignedHeaders", valid_602434
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602435: Call_GetIntents_602422; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns intent information as follows: </p> <ul> <li> <p>If you specify the <code>nameContains</code> field, returns the <code>$LATEST</code> version of all intents that contain the specified string.</p> </li> <li> <p> If you don't specify the <code>nameContains</code> field, returns information about the <code>$LATEST</code> version of all intents. </p> </li> </ul> <p> The operation requires permission for the <code>lex:GetIntents</code> action. </p>
  ## 
  let valid = call_602435.validator(path, query, header, formData, body)
  let scheme = call_602435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602435.url(scheme.get, call_602435.host, call_602435.base,
                         call_602435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602435, url, valid)

proc call*(call_602436: Call_GetIntents_602422; nextToken: string = "";
          nameContains: string = ""; maxResults: int = 0): Recallable =
  ## getIntents
  ## <p>Returns intent information as follows: </p> <ul> <li> <p>If you specify the <code>nameContains</code> field, returns the <code>$LATEST</code> version of all intents that contain the specified string.</p> </li> <li> <p> If you don't specify the <code>nameContains</code> field, returns information about the <code>$LATEST</code> version of all intents. </p> </li> </ul> <p> The operation requires permission for the <code>lex:GetIntents</code> action. </p>
  ##   nextToken: string
  ##            : A pagination token that fetches the next page of intents. If the response to this API call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of intents, specify the pagination token in the next request. 
  ##   nameContains: string
  ##               : Substring to match in intent names. An intent will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  ##   maxResults: int
  ##             : The maximum number of intents to return in the response. The default is 10.
  var query_602437 = newJObject()
  add(query_602437, "nextToken", newJString(nextToken))
  add(query_602437, "nameContains", newJString(nameContains))
  add(query_602437, "maxResults", newJInt(maxResults))
  result = call_602436.call(nil, query_602437, nil, nil, nil)

var getIntents* = Call_GetIntents_602422(name: "getIntents",
                                      meth: HttpMethod.HttpGet,
                                      host: "models.lex.amazonaws.com",
                                      route: "/intents/",
                                      validator: validate_GetIntents_602423,
                                      base: "/", url: url_GetIntents_602424,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSlotType_602438 = ref object of OpenApiRestCall_601390
proc url_GetSlotType_602440(protocol: Scheme; host: string; base: string;
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

proc validate_GetSlotType_602439(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602441 = path.getOrDefault("version")
  valid_602441 = validateParameter(valid_602441, JString, required = true,
                                 default = nil)
  if valid_602441 != nil:
    section.add "version", valid_602441
  var valid_602442 = path.getOrDefault("name")
  valid_602442 = validateParameter(valid_602442, JString, required = true,
                                 default = nil)
  if valid_602442 != nil:
    section.add "name", valid_602442
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
  var valid_602443 = header.getOrDefault("X-Amz-Signature")
  valid_602443 = validateParameter(valid_602443, JString, required = false,
                                 default = nil)
  if valid_602443 != nil:
    section.add "X-Amz-Signature", valid_602443
  var valid_602444 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602444 = validateParameter(valid_602444, JString, required = false,
                                 default = nil)
  if valid_602444 != nil:
    section.add "X-Amz-Content-Sha256", valid_602444
  var valid_602445 = header.getOrDefault("X-Amz-Date")
  valid_602445 = validateParameter(valid_602445, JString, required = false,
                                 default = nil)
  if valid_602445 != nil:
    section.add "X-Amz-Date", valid_602445
  var valid_602446 = header.getOrDefault("X-Amz-Credential")
  valid_602446 = validateParameter(valid_602446, JString, required = false,
                                 default = nil)
  if valid_602446 != nil:
    section.add "X-Amz-Credential", valid_602446
  var valid_602447 = header.getOrDefault("X-Amz-Security-Token")
  valid_602447 = validateParameter(valid_602447, JString, required = false,
                                 default = nil)
  if valid_602447 != nil:
    section.add "X-Amz-Security-Token", valid_602447
  var valid_602448 = header.getOrDefault("X-Amz-Algorithm")
  valid_602448 = validateParameter(valid_602448, JString, required = false,
                                 default = nil)
  if valid_602448 != nil:
    section.add "X-Amz-Algorithm", valid_602448
  var valid_602449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602449 = validateParameter(valid_602449, JString, required = false,
                                 default = nil)
  if valid_602449 != nil:
    section.add "X-Amz-SignedHeaders", valid_602449
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602450: Call_GetSlotType_602438; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a specific version of a slot type. In addition to specifying the slot type name, you must specify the slot type version.</p> <p>This operation requires permissions for the <code>lex:GetSlotType</code> action.</p>
  ## 
  let valid = call_602450.validator(path, query, header, formData, body)
  let scheme = call_602450.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602450.url(scheme.get, call_602450.host, call_602450.base,
                         call_602450.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602450, url, valid)

proc call*(call_602451: Call_GetSlotType_602438; version: string; name: string): Recallable =
  ## getSlotType
  ## <p>Returns information about a specific version of a slot type. In addition to specifying the slot type name, you must specify the slot type version.</p> <p>This operation requires permissions for the <code>lex:GetSlotType</code> action.</p>
  ##   version: string (required)
  ##          : The version of the slot type. 
  ##   name: string (required)
  ##       : The name of the slot type. The name is case sensitive. 
  var path_602452 = newJObject()
  add(path_602452, "version", newJString(version))
  add(path_602452, "name", newJString(name))
  result = call_602451.call(path_602452, nil, nil, nil, nil)

var getSlotType* = Call_GetSlotType_602438(name: "getSlotType",
                                        meth: HttpMethod.HttpGet,
                                        host: "models.lex.amazonaws.com", route: "/slottypes/{name}/versions/{version}",
                                        validator: validate_GetSlotType_602439,
                                        base: "/", url: url_GetSlotType_602440,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSlotTypeVersions_602453 = ref object of OpenApiRestCall_601390
proc url_GetSlotTypeVersions_602455(protocol: Scheme; host: string; base: string;
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

proc validate_GetSlotTypeVersions_602454(path: JsonNode; query: JsonNode;
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
  var valid_602456 = path.getOrDefault("name")
  valid_602456 = validateParameter(valid_602456, JString, required = true,
                                 default = nil)
  if valid_602456 != nil:
    section.add "name", valid_602456
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A pagination token for fetching the next page of slot type versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  ##   maxResults: JInt
  ##             : The maximum number of slot type versions to return in the response. The default is 10.
  section = newJObject()
  var valid_602457 = query.getOrDefault("nextToken")
  valid_602457 = validateParameter(valid_602457, JString, required = false,
                                 default = nil)
  if valid_602457 != nil:
    section.add "nextToken", valid_602457
  var valid_602458 = query.getOrDefault("maxResults")
  valid_602458 = validateParameter(valid_602458, JInt, required = false, default = nil)
  if valid_602458 != nil:
    section.add "maxResults", valid_602458
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
  var valid_602459 = header.getOrDefault("X-Amz-Signature")
  valid_602459 = validateParameter(valid_602459, JString, required = false,
                                 default = nil)
  if valid_602459 != nil:
    section.add "X-Amz-Signature", valid_602459
  var valid_602460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602460 = validateParameter(valid_602460, JString, required = false,
                                 default = nil)
  if valid_602460 != nil:
    section.add "X-Amz-Content-Sha256", valid_602460
  var valid_602461 = header.getOrDefault("X-Amz-Date")
  valid_602461 = validateParameter(valid_602461, JString, required = false,
                                 default = nil)
  if valid_602461 != nil:
    section.add "X-Amz-Date", valid_602461
  var valid_602462 = header.getOrDefault("X-Amz-Credential")
  valid_602462 = validateParameter(valid_602462, JString, required = false,
                                 default = nil)
  if valid_602462 != nil:
    section.add "X-Amz-Credential", valid_602462
  var valid_602463 = header.getOrDefault("X-Amz-Security-Token")
  valid_602463 = validateParameter(valid_602463, JString, required = false,
                                 default = nil)
  if valid_602463 != nil:
    section.add "X-Amz-Security-Token", valid_602463
  var valid_602464 = header.getOrDefault("X-Amz-Algorithm")
  valid_602464 = validateParameter(valid_602464, JString, required = false,
                                 default = nil)
  if valid_602464 != nil:
    section.add "X-Amz-Algorithm", valid_602464
  var valid_602465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602465 = validateParameter(valid_602465, JString, required = false,
                                 default = nil)
  if valid_602465 != nil:
    section.add "X-Amz-SignedHeaders", valid_602465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602466: Call_GetSlotTypeVersions_602453; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about all versions of a slot type.</p> <p>The <code>GetSlotTypeVersions</code> operation returns a <code>SlotTypeMetadata</code> object for each version of a slot type. For example, if a slot type has three numbered versions, the <code>GetSlotTypeVersions</code> operation returns four <code>SlotTypeMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetSlotTypeVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetSlotTypeVersions</code> action.</p>
  ## 
  let valid = call_602466.validator(path, query, header, formData, body)
  let scheme = call_602466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602466.url(scheme.get, call_602466.host, call_602466.base,
                         call_602466.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602466, url, valid)

proc call*(call_602467: Call_GetSlotTypeVersions_602453; name: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## getSlotTypeVersions
  ## <p>Gets information about all versions of a slot type.</p> <p>The <code>GetSlotTypeVersions</code> operation returns a <code>SlotTypeMetadata</code> object for each version of a slot type. For example, if a slot type has three numbered versions, the <code>GetSlotTypeVersions</code> operation returns four <code>SlotTypeMetadata</code> objects in the response, one for each numbered version and one for the <code>$LATEST</code> version. </p> <p>The <code>GetSlotTypeVersions</code> operation always returns at least one version, the <code>$LATEST</code> version.</p> <p>This operation requires permissions for the <code>lex:GetSlotTypeVersions</code> action.</p>
  ##   nextToken: string
  ##            : A pagination token for fetching the next page of slot type versions. If the response to this call is truncated, Amazon Lex returns a pagination token in the response. To fetch the next page of versions, specify the pagination token in the next request. 
  ##   name: string (required)
  ##       : The name of the slot type for which versions should be returned.
  ##   maxResults: int
  ##             : The maximum number of slot type versions to return in the response. The default is 10.
  var path_602468 = newJObject()
  var query_602469 = newJObject()
  add(query_602469, "nextToken", newJString(nextToken))
  add(path_602468, "name", newJString(name))
  add(query_602469, "maxResults", newJInt(maxResults))
  result = call_602467.call(path_602468, query_602469, nil, nil, nil)

var getSlotTypeVersions* = Call_GetSlotTypeVersions_602453(
    name: "getSlotTypeVersions", meth: HttpMethod.HttpGet,
    host: "models.lex.amazonaws.com", route: "/slottypes/{name}/versions/",
    validator: validate_GetSlotTypeVersions_602454, base: "/",
    url: url_GetSlotTypeVersions_602455, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSlotTypes_602470 = ref object of OpenApiRestCall_601390
proc url_GetSlotTypes_602472(protocol: Scheme; host: string; base: string;
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

proc validate_GetSlotTypes_602471(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602473 = query.getOrDefault("nextToken")
  valid_602473 = validateParameter(valid_602473, JString, required = false,
                                 default = nil)
  if valid_602473 != nil:
    section.add "nextToken", valid_602473
  var valid_602474 = query.getOrDefault("nameContains")
  valid_602474 = validateParameter(valid_602474, JString, required = false,
                                 default = nil)
  if valid_602474 != nil:
    section.add "nameContains", valid_602474
  var valid_602475 = query.getOrDefault("maxResults")
  valid_602475 = validateParameter(valid_602475, JInt, required = false, default = nil)
  if valid_602475 != nil:
    section.add "maxResults", valid_602475
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
  var valid_602476 = header.getOrDefault("X-Amz-Signature")
  valid_602476 = validateParameter(valid_602476, JString, required = false,
                                 default = nil)
  if valid_602476 != nil:
    section.add "X-Amz-Signature", valid_602476
  var valid_602477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602477 = validateParameter(valid_602477, JString, required = false,
                                 default = nil)
  if valid_602477 != nil:
    section.add "X-Amz-Content-Sha256", valid_602477
  var valid_602478 = header.getOrDefault("X-Amz-Date")
  valid_602478 = validateParameter(valid_602478, JString, required = false,
                                 default = nil)
  if valid_602478 != nil:
    section.add "X-Amz-Date", valid_602478
  var valid_602479 = header.getOrDefault("X-Amz-Credential")
  valid_602479 = validateParameter(valid_602479, JString, required = false,
                                 default = nil)
  if valid_602479 != nil:
    section.add "X-Amz-Credential", valid_602479
  var valid_602480 = header.getOrDefault("X-Amz-Security-Token")
  valid_602480 = validateParameter(valid_602480, JString, required = false,
                                 default = nil)
  if valid_602480 != nil:
    section.add "X-Amz-Security-Token", valid_602480
  var valid_602481 = header.getOrDefault("X-Amz-Algorithm")
  valid_602481 = validateParameter(valid_602481, JString, required = false,
                                 default = nil)
  if valid_602481 != nil:
    section.add "X-Amz-Algorithm", valid_602481
  var valid_602482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602482 = validateParameter(valid_602482, JString, required = false,
                                 default = nil)
  if valid_602482 != nil:
    section.add "X-Amz-SignedHeaders", valid_602482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602483: Call_GetSlotTypes_602470; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns slot type information as follows: </p> <ul> <li> <p>If you specify the <code>nameContains</code> field, returns the <code>$LATEST</code> version of all slot types that contain the specified string.</p> </li> <li> <p> If you don't specify the <code>nameContains</code> field, returns information about the <code>$LATEST</code> version of all slot types. </p> </li> </ul> <p> The operation requires permission for the <code>lex:GetSlotTypes</code> action. </p>
  ## 
  let valid = call_602483.validator(path, query, header, formData, body)
  let scheme = call_602483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602483.url(scheme.get, call_602483.host, call_602483.base,
                         call_602483.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602483, url, valid)

proc call*(call_602484: Call_GetSlotTypes_602470; nextToken: string = "";
          nameContains: string = ""; maxResults: int = 0): Recallable =
  ## getSlotTypes
  ## <p>Returns slot type information as follows: </p> <ul> <li> <p>If you specify the <code>nameContains</code> field, returns the <code>$LATEST</code> version of all slot types that contain the specified string.</p> </li> <li> <p> If you don't specify the <code>nameContains</code> field, returns information about the <code>$LATEST</code> version of all slot types. </p> </li> </ul> <p> The operation requires permission for the <code>lex:GetSlotTypes</code> action. </p>
  ##   nextToken: string
  ##            : A pagination token that fetches the next page of slot types. If the response to this API call is truncated, Amazon Lex returns a pagination token in the response. To fetch next page of slot types, specify the pagination token in the next request.
  ##   nameContains: string
  ##               : Substring to match in slot type names. A slot type will be returned if any part of its name matches the substring. For example, "xyz" matches both "xyzabc" and "abcxyz."
  ##   maxResults: int
  ##             : The maximum number of slot types to return in the response. The default is 10.
  var query_602485 = newJObject()
  add(query_602485, "nextToken", newJString(nextToken))
  add(query_602485, "nameContains", newJString(nameContains))
  add(query_602485, "maxResults", newJInt(maxResults))
  result = call_602484.call(nil, query_602485, nil, nil, nil)

var getSlotTypes* = Call_GetSlotTypes_602470(name: "getSlotTypes",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com",
    route: "/slottypes/", validator: validate_GetSlotTypes_602471, base: "/",
    url: url_GetSlotTypes_602472, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUtterancesView_602486 = ref object of OpenApiRestCall_601390
proc url_GetUtterancesView_602488(protocol: Scheme; host: string; base: string;
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

proc validate_GetUtterancesView_602487(path: JsonNode; query: JsonNode;
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
  var valid_602489 = path.getOrDefault("botname")
  valid_602489 = validateParameter(valid_602489, JString, required = true,
                                 default = nil)
  if valid_602489 != nil:
    section.add "botname", valid_602489
  result.add "path", section
  ## parameters in `query` object:
  ##   status_type: JString (required)
  ##              : To return utterances that were recognized and handled, use <code>Detected</code>. To return utterances that were not recognized, use <code>Missed</code>.
  ##   bot_versions: JArray (required)
  ##               : An array of bot versions for which utterance information should be returned. The limit is 5 versions per request.
  ##   view: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `status_type` field"
  var valid_602490 = query.getOrDefault("status_type")
  valid_602490 = validateParameter(valid_602490, JString, required = true,
                                 default = newJString("Detected"))
  if valid_602490 != nil:
    section.add "status_type", valid_602490
  var valid_602491 = query.getOrDefault("bot_versions")
  valid_602491 = validateParameter(valid_602491, JArray, required = true, default = nil)
  if valid_602491 != nil:
    section.add "bot_versions", valid_602491
  var valid_602492 = query.getOrDefault("view")
  valid_602492 = validateParameter(valid_602492, JString, required = true,
                                 default = newJString("aggregation"))
  if valid_602492 != nil:
    section.add "view", valid_602492
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
  var valid_602493 = header.getOrDefault("X-Amz-Signature")
  valid_602493 = validateParameter(valid_602493, JString, required = false,
                                 default = nil)
  if valid_602493 != nil:
    section.add "X-Amz-Signature", valid_602493
  var valid_602494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602494 = validateParameter(valid_602494, JString, required = false,
                                 default = nil)
  if valid_602494 != nil:
    section.add "X-Amz-Content-Sha256", valid_602494
  var valid_602495 = header.getOrDefault("X-Amz-Date")
  valid_602495 = validateParameter(valid_602495, JString, required = false,
                                 default = nil)
  if valid_602495 != nil:
    section.add "X-Amz-Date", valid_602495
  var valid_602496 = header.getOrDefault("X-Amz-Credential")
  valid_602496 = validateParameter(valid_602496, JString, required = false,
                                 default = nil)
  if valid_602496 != nil:
    section.add "X-Amz-Credential", valid_602496
  var valid_602497 = header.getOrDefault("X-Amz-Security-Token")
  valid_602497 = validateParameter(valid_602497, JString, required = false,
                                 default = nil)
  if valid_602497 != nil:
    section.add "X-Amz-Security-Token", valid_602497
  var valid_602498 = header.getOrDefault("X-Amz-Algorithm")
  valid_602498 = validateParameter(valid_602498, JString, required = false,
                                 default = nil)
  if valid_602498 != nil:
    section.add "X-Amz-Algorithm", valid_602498
  var valid_602499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602499 = validateParameter(valid_602499, JString, required = false,
                                 default = nil)
  if valid_602499 != nil:
    section.add "X-Amz-SignedHeaders", valid_602499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602500: Call_GetUtterancesView_602486; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Use the <code>GetUtterancesView</code> operation to get information about the utterances that your users have made to your bot. You can use this list to tune the utterances that your bot responds to.</p> <p>For example, say that you have created a bot to order flowers. After your users have used your bot for a while, use the <code>GetUtterancesView</code> operation to see the requests that they have made and whether they have been successful. You might find that the utterance "I want flowers" is not being recognized. You could add this utterance to the <code>OrderFlowers</code> intent so that your bot recognizes that utterance.</p> <p>After you publish a new version of a bot, you can get information about the old version and the new so that you can compare the performance across the two versions. </p> <p>Utterance statistics are generated once a day. Data is available for the last 15 days. You can request information for up to 5 versions of your bot in each request. Amazon Lex returns the most frequent utterances received by the bot in the last 15 days. The response contains information about a maximum of 100 utterances for each version.</p> <p>If you set <code>childDirected</code> field to true when you created your bot, or if you opted out of participating in improving Amazon Lex, utterances are not available.</p> <p>This operation requires permissions for the <code>lex:GetUtterancesView</code> action.</p>
  ## 
  let valid = call_602500.validator(path, query, header, formData, body)
  let scheme = call_602500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602500.url(scheme.get, call_602500.host, call_602500.base,
                         call_602500.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602500, url, valid)

proc call*(call_602501: Call_GetUtterancesView_602486; botname: string;
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
  var path_602502 = newJObject()
  var query_602503 = newJObject()
  add(query_602503, "status_type", newJString(statusType))
  add(path_602502, "botname", newJString(botname))
  if botVersions != nil:
    query_602503.add "bot_versions", botVersions
  add(query_602503, "view", newJString(view))
  result = call_602501.call(path_602502, query_602503, nil, nil, nil)

var getUtterancesView* = Call_GetUtterancesView_602486(name: "getUtterancesView",
    meth: HttpMethod.HttpGet, host: "models.lex.amazonaws.com", route: "/bots/{botname}/utterances#view=aggregation&bot_versions&status_type",
    validator: validate_GetUtterancesView_602487, base: "/",
    url: url_GetUtterancesView_602488, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBot_602504 = ref object of OpenApiRestCall_601390
proc url_PutBot_602506(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutBot_602505(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602507 = path.getOrDefault("name")
  valid_602507 = validateParameter(valid_602507, JString, required = true,
                                 default = nil)
  if valid_602507 != nil:
    section.add "name", valid_602507
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
  var valid_602508 = header.getOrDefault("X-Amz-Signature")
  valid_602508 = validateParameter(valid_602508, JString, required = false,
                                 default = nil)
  if valid_602508 != nil:
    section.add "X-Amz-Signature", valid_602508
  var valid_602509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602509 = validateParameter(valid_602509, JString, required = false,
                                 default = nil)
  if valid_602509 != nil:
    section.add "X-Amz-Content-Sha256", valid_602509
  var valid_602510 = header.getOrDefault("X-Amz-Date")
  valid_602510 = validateParameter(valid_602510, JString, required = false,
                                 default = nil)
  if valid_602510 != nil:
    section.add "X-Amz-Date", valid_602510
  var valid_602511 = header.getOrDefault("X-Amz-Credential")
  valid_602511 = validateParameter(valid_602511, JString, required = false,
                                 default = nil)
  if valid_602511 != nil:
    section.add "X-Amz-Credential", valid_602511
  var valid_602512 = header.getOrDefault("X-Amz-Security-Token")
  valid_602512 = validateParameter(valid_602512, JString, required = false,
                                 default = nil)
  if valid_602512 != nil:
    section.add "X-Amz-Security-Token", valid_602512
  var valid_602513 = header.getOrDefault("X-Amz-Algorithm")
  valid_602513 = validateParameter(valid_602513, JString, required = false,
                                 default = nil)
  if valid_602513 != nil:
    section.add "X-Amz-Algorithm", valid_602513
  var valid_602514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602514 = validateParameter(valid_602514, JString, required = false,
                                 default = nil)
  if valid_602514 != nil:
    section.add "X-Amz-SignedHeaders", valid_602514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602516: Call_PutBot_602504; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon Lex conversational bot or replaces an existing bot. When you create or update a bot you are only required to specify a name, a locale, and whether the bot is directed toward children under age 13. You can use this to add intents later, or to remove intents from an existing bot. When you create a bot with the minimum information, the bot is created or updated but Amazon Lex returns the <code/> response <code>FAILED</code>. You can build the bot after you add one or more intents. For more information about Amazon Lex bots, see <a>how-it-works</a>. </p> <p>If you specify the name of an existing bot, the fields in the request replace the existing values in the <code>$LATEST</code> version of the bot. Amazon Lex removes any fields that you don't provide values for in the request, except for the <code>idleTTLInSeconds</code> and <code>privacySettings</code> fields, which are set to their default values. If you don't specify values for required fields, Amazon Lex throws an exception.</p> <p>This operation requires permissions for the <code>lex:PutBot</code> action. For more information, see <a>security-iam</a>.</p>
  ## 
  let valid = call_602516.validator(path, query, header, formData, body)
  let scheme = call_602516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602516.url(scheme.get, call_602516.host, call_602516.base,
                         call_602516.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602516, url, valid)

proc call*(call_602517: Call_PutBot_602504; name: string; body: JsonNode): Recallable =
  ## putBot
  ## <p>Creates an Amazon Lex conversational bot or replaces an existing bot. When you create or update a bot you are only required to specify a name, a locale, and whether the bot is directed toward children under age 13. You can use this to add intents later, or to remove intents from an existing bot. When you create a bot with the minimum information, the bot is created or updated but Amazon Lex returns the <code/> response <code>FAILED</code>. You can build the bot after you add one or more intents. For more information about Amazon Lex bots, see <a>how-it-works</a>. </p> <p>If you specify the name of an existing bot, the fields in the request replace the existing values in the <code>$LATEST</code> version of the bot. Amazon Lex removes any fields that you don't provide values for in the request, except for the <code>idleTTLInSeconds</code> and <code>privacySettings</code> fields, which are set to their default values. If you don't specify values for required fields, Amazon Lex throws an exception.</p> <p>This operation requires permissions for the <code>lex:PutBot</code> action. For more information, see <a>security-iam</a>.</p>
  ##   name: string (required)
  ##       : The name of the bot. The name is <i>not</i> case sensitive. 
  ##   body: JObject (required)
  var path_602518 = newJObject()
  var body_602519 = newJObject()
  add(path_602518, "name", newJString(name))
  if body != nil:
    body_602519 = body
  result = call_602517.call(path_602518, nil, nil, nil, body_602519)

var putBot* = Call_PutBot_602504(name: "putBot", meth: HttpMethod.HttpPut,
                              host: "models.lex.amazonaws.com",
                              route: "/bots/{name}/versions/$LATEST",
                              validator: validate_PutBot_602505, base: "/",
                              url: url_PutBot_602506,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutIntent_602520 = ref object of OpenApiRestCall_601390
proc url_PutIntent_602522(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_PutIntent_602521(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602523 = path.getOrDefault("name")
  valid_602523 = validateParameter(valid_602523, JString, required = true,
                                 default = nil)
  if valid_602523 != nil:
    section.add "name", valid_602523
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
  var valid_602524 = header.getOrDefault("X-Amz-Signature")
  valid_602524 = validateParameter(valid_602524, JString, required = false,
                                 default = nil)
  if valid_602524 != nil:
    section.add "X-Amz-Signature", valid_602524
  var valid_602525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602525 = validateParameter(valid_602525, JString, required = false,
                                 default = nil)
  if valid_602525 != nil:
    section.add "X-Amz-Content-Sha256", valid_602525
  var valid_602526 = header.getOrDefault("X-Amz-Date")
  valid_602526 = validateParameter(valid_602526, JString, required = false,
                                 default = nil)
  if valid_602526 != nil:
    section.add "X-Amz-Date", valid_602526
  var valid_602527 = header.getOrDefault("X-Amz-Credential")
  valid_602527 = validateParameter(valid_602527, JString, required = false,
                                 default = nil)
  if valid_602527 != nil:
    section.add "X-Amz-Credential", valid_602527
  var valid_602528 = header.getOrDefault("X-Amz-Security-Token")
  valid_602528 = validateParameter(valid_602528, JString, required = false,
                                 default = nil)
  if valid_602528 != nil:
    section.add "X-Amz-Security-Token", valid_602528
  var valid_602529 = header.getOrDefault("X-Amz-Algorithm")
  valid_602529 = validateParameter(valid_602529, JString, required = false,
                                 default = nil)
  if valid_602529 != nil:
    section.add "X-Amz-Algorithm", valid_602529
  var valid_602530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602530 = validateParameter(valid_602530, JString, required = false,
                                 default = nil)
  if valid_602530 != nil:
    section.add "X-Amz-SignedHeaders", valid_602530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602532: Call_PutIntent_602520; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an intent or replaces an existing intent.</p> <p>To define the interaction between the user and your bot, you use one or more intents. For a pizza ordering bot, for example, you would create an <code>OrderPizza</code> intent. </p> <p>To create an intent or replace an existing intent, you must provide the following:</p> <ul> <li> <p>Intent name. For example, <code>OrderPizza</code>.</p> </li> <li> <p>Sample utterances. For example, "Can I order a pizza, please." and "I want to order a pizza."</p> </li> <li> <p>Information to be gathered. You specify slot types for the information that your bot will request from the user. You can specify standard slot types, such as a date or a time, or custom slot types such as the size and crust of a pizza.</p> </li> <li> <p>How the intent will be fulfilled. You can provide a Lambda function or configure the intent to return the intent information to the client application. If you use a Lambda function, when all of the intent information is available, Amazon Lex invokes your Lambda function. If you configure your intent to return the intent information to the client application. </p> </li> </ul> <p>You can specify other optional information in the request, such as:</p> <ul> <li> <p>A confirmation prompt to ask the user to confirm an intent. For example, "Shall I order your pizza?"</p> </li> <li> <p>A conclusion statement to send to the user after the intent has been fulfilled. For example, "I placed your pizza order."</p> </li> <li> <p>A follow-up prompt that asks the user for additional activity. For example, asking "Do you want to order a drink with your pizza?"</p> </li> </ul> <p>If you specify an existing intent name to update the intent, Amazon Lex replaces the values in the <code>$LATEST</code> version of the intent with the values in the request. Amazon Lex removes fields that you don't provide in the request. If you don't specify the required fields, Amazon Lex throws an exception. When you update the <code>$LATEST</code> version of an intent, the <code>status</code> field of any bot that uses the <code>$LATEST</code> version of the intent is set to <code>NOT_BUILT</code>.</p> <p>For more information, see <a>how-it-works</a>.</p> <p>This operation requires permissions for the <code>lex:PutIntent</code> action.</p>
  ## 
  let valid = call_602532.validator(path, query, header, formData, body)
  let scheme = call_602532.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602532.url(scheme.get, call_602532.host, call_602532.base,
                         call_602532.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602532, url, valid)

proc call*(call_602533: Call_PutIntent_602520; name: string; body: JsonNode): Recallable =
  ## putIntent
  ## <p>Creates an intent or replaces an existing intent.</p> <p>To define the interaction between the user and your bot, you use one or more intents. For a pizza ordering bot, for example, you would create an <code>OrderPizza</code> intent. </p> <p>To create an intent or replace an existing intent, you must provide the following:</p> <ul> <li> <p>Intent name. For example, <code>OrderPizza</code>.</p> </li> <li> <p>Sample utterances. For example, "Can I order a pizza, please." and "I want to order a pizza."</p> </li> <li> <p>Information to be gathered. You specify slot types for the information that your bot will request from the user. You can specify standard slot types, such as a date or a time, or custom slot types such as the size and crust of a pizza.</p> </li> <li> <p>How the intent will be fulfilled. You can provide a Lambda function or configure the intent to return the intent information to the client application. If you use a Lambda function, when all of the intent information is available, Amazon Lex invokes your Lambda function. If you configure your intent to return the intent information to the client application. </p> </li> </ul> <p>You can specify other optional information in the request, such as:</p> <ul> <li> <p>A confirmation prompt to ask the user to confirm an intent. For example, "Shall I order your pizza?"</p> </li> <li> <p>A conclusion statement to send to the user after the intent has been fulfilled. For example, "I placed your pizza order."</p> </li> <li> <p>A follow-up prompt that asks the user for additional activity. For example, asking "Do you want to order a drink with your pizza?"</p> </li> </ul> <p>If you specify an existing intent name to update the intent, Amazon Lex replaces the values in the <code>$LATEST</code> version of the intent with the values in the request. Amazon Lex removes fields that you don't provide in the request. If you don't specify the required fields, Amazon Lex throws an exception. When you update the <code>$LATEST</code> version of an intent, the <code>status</code> field of any bot that uses the <code>$LATEST</code> version of the intent is set to <code>NOT_BUILT</code>.</p> <p>For more information, see <a>how-it-works</a>.</p> <p>This operation requires permissions for the <code>lex:PutIntent</code> action.</p>
  ##   name: string (required)
  ##       : <p>The name of the intent. The name is <i>not</i> case sensitive. </p> <p>The name can't match a built-in intent name, or a built-in intent name with "AMAZON." removed. For example, because there is a built-in intent called <code>AMAZON.HelpIntent</code>, you can't create a custom intent called <code>HelpIntent</code>.</p> <p>For a list of built-in intents, see <a 
  ## href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/standard-intents">Standard Built-in Intents</a> in the <i>Alexa Skills Kit</i>.</p>
  ##   body: JObject (required)
  var path_602534 = newJObject()
  var body_602535 = newJObject()
  add(path_602534, "name", newJString(name))
  if body != nil:
    body_602535 = body
  result = call_602533.call(path_602534, nil, nil, nil, body_602535)

var putIntent* = Call_PutIntent_602520(name: "putIntent", meth: HttpMethod.HttpPut,
                                    host: "models.lex.amazonaws.com",
                                    route: "/intents/{name}/versions/$LATEST",
                                    validator: validate_PutIntent_602521,
                                    base: "/", url: url_PutIntent_602522,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutSlotType_602536 = ref object of OpenApiRestCall_601390
proc url_PutSlotType_602538(protocol: Scheme; host: string; base: string;
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

proc validate_PutSlotType_602537(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602539 = path.getOrDefault("name")
  valid_602539 = validateParameter(valid_602539, JString, required = true,
                                 default = nil)
  if valid_602539 != nil:
    section.add "name", valid_602539
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
  var valid_602540 = header.getOrDefault("X-Amz-Signature")
  valid_602540 = validateParameter(valid_602540, JString, required = false,
                                 default = nil)
  if valid_602540 != nil:
    section.add "X-Amz-Signature", valid_602540
  var valid_602541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602541 = validateParameter(valid_602541, JString, required = false,
                                 default = nil)
  if valid_602541 != nil:
    section.add "X-Amz-Content-Sha256", valid_602541
  var valid_602542 = header.getOrDefault("X-Amz-Date")
  valid_602542 = validateParameter(valid_602542, JString, required = false,
                                 default = nil)
  if valid_602542 != nil:
    section.add "X-Amz-Date", valid_602542
  var valid_602543 = header.getOrDefault("X-Amz-Credential")
  valid_602543 = validateParameter(valid_602543, JString, required = false,
                                 default = nil)
  if valid_602543 != nil:
    section.add "X-Amz-Credential", valid_602543
  var valid_602544 = header.getOrDefault("X-Amz-Security-Token")
  valid_602544 = validateParameter(valid_602544, JString, required = false,
                                 default = nil)
  if valid_602544 != nil:
    section.add "X-Amz-Security-Token", valid_602544
  var valid_602545 = header.getOrDefault("X-Amz-Algorithm")
  valid_602545 = validateParameter(valid_602545, JString, required = false,
                                 default = nil)
  if valid_602545 != nil:
    section.add "X-Amz-Algorithm", valid_602545
  var valid_602546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602546 = validateParameter(valid_602546, JString, required = false,
                                 default = nil)
  if valid_602546 != nil:
    section.add "X-Amz-SignedHeaders", valid_602546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602548: Call_PutSlotType_602536; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a custom slot type or replaces an existing custom slot type.</p> <p>To create a custom slot type, specify a name for the slot type and a set of enumeration values, which are the values that a slot of this type can assume. For more information, see <a>how-it-works</a>.</p> <p>If you specify the name of an existing slot type, the fields in the request replace the existing values in the <code>$LATEST</code> version of the slot type. Amazon Lex removes the fields that you don't provide in the request. If you don't specify required fields, Amazon Lex throws an exception. When you update the <code>$LATEST</code> version of a slot type, if a bot uses the <code>$LATEST</code> version of an intent that contains the slot type, the bot's <code>status</code> field is set to <code>NOT_BUILT</code>.</p> <p>This operation requires permissions for the <code>lex:PutSlotType</code> action.</p>
  ## 
  let valid = call_602548.validator(path, query, header, formData, body)
  let scheme = call_602548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602548.url(scheme.get, call_602548.host, call_602548.base,
                         call_602548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602548, url, valid)

proc call*(call_602549: Call_PutSlotType_602536; name: string; body: JsonNode): Recallable =
  ## putSlotType
  ## <p>Creates a custom slot type or replaces an existing custom slot type.</p> <p>To create a custom slot type, specify a name for the slot type and a set of enumeration values, which are the values that a slot of this type can assume. For more information, see <a>how-it-works</a>.</p> <p>If you specify the name of an existing slot type, the fields in the request replace the existing values in the <code>$LATEST</code> version of the slot type. Amazon Lex removes the fields that you don't provide in the request. If you don't specify required fields, Amazon Lex throws an exception. When you update the <code>$LATEST</code> version of a slot type, if a bot uses the <code>$LATEST</code> version of an intent that contains the slot type, the bot's <code>status</code> field is set to <code>NOT_BUILT</code>.</p> <p>This operation requires permissions for the <code>lex:PutSlotType</code> action.</p>
  ##   name: string (required)
  ##       : <p>The name of the slot type. The name is <i>not</i> case sensitive. </p> <p>The name can't match a built-in slot type name, or a built-in slot type name with "AMAZON." removed. For example, because there is a built-in slot type called <code>AMAZON.DATE</code>, you can't create a custom slot type called <code>DATE</code>.</p> <p>For a list of built-in slot types, see <a 
  ## href="https://developer.amazon.com/public/solutions/alexa/alexa-skills-kit/docs/built-in-intent-ref/slot-type-reference">Slot Type Reference</a> in the <i>Alexa Skills Kit</i>.</p>
  ##   body: JObject (required)
  var path_602550 = newJObject()
  var body_602551 = newJObject()
  add(path_602550, "name", newJString(name))
  if body != nil:
    body_602551 = body
  result = call_602549.call(path_602550, nil, nil, nil, body_602551)

var putSlotType* = Call_PutSlotType_602536(name: "putSlotType",
                                        meth: HttpMethod.HttpPut,
                                        host: "models.lex.amazonaws.com", route: "/slottypes/{name}/versions/$LATEST",
                                        validator: validate_PutSlotType_602537,
                                        base: "/", url: url_PutSlotType_602538,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartImport_602552 = ref object of OpenApiRestCall_601390
proc url_StartImport_602554(protocol: Scheme; host: string; base: string;
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

proc validate_StartImport_602553(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602555 = header.getOrDefault("X-Amz-Signature")
  valid_602555 = validateParameter(valid_602555, JString, required = false,
                                 default = nil)
  if valid_602555 != nil:
    section.add "X-Amz-Signature", valid_602555
  var valid_602556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602556 = validateParameter(valid_602556, JString, required = false,
                                 default = nil)
  if valid_602556 != nil:
    section.add "X-Amz-Content-Sha256", valid_602556
  var valid_602557 = header.getOrDefault("X-Amz-Date")
  valid_602557 = validateParameter(valid_602557, JString, required = false,
                                 default = nil)
  if valid_602557 != nil:
    section.add "X-Amz-Date", valid_602557
  var valid_602558 = header.getOrDefault("X-Amz-Credential")
  valid_602558 = validateParameter(valid_602558, JString, required = false,
                                 default = nil)
  if valid_602558 != nil:
    section.add "X-Amz-Credential", valid_602558
  var valid_602559 = header.getOrDefault("X-Amz-Security-Token")
  valid_602559 = validateParameter(valid_602559, JString, required = false,
                                 default = nil)
  if valid_602559 != nil:
    section.add "X-Amz-Security-Token", valid_602559
  var valid_602560 = header.getOrDefault("X-Amz-Algorithm")
  valid_602560 = validateParameter(valid_602560, JString, required = false,
                                 default = nil)
  if valid_602560 != nil:
    section.add "X-Amz-Algorithm", valid_602560
  var valid_602561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602561 = validateParameter(valid_602561, JString, required = false,
                                 default = nil)
  if valid_602561 != nil:
    section.add "X-Amz-SignedHeaders", valid_602561
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602563: Call_StartImport_602552; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a job to import a resource to Amazon Lex.
  ## 
  let valid = call_602563.validator(path, query, header, formData, body)
  let scheme = call_602563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602563.url(scheme.get, call_602563.host, call_602563.base,
                         call_602563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602563, url, valid)

proc call*(call_602564: Call_StartImport_602552; body: JsonNode): Recallable =
  ## startImport
  ## Starts a job to import a resource to Amazon Lex.
  ##   body: JObject (required)
  var body_602565 = newJObject()
  if body != nil:
    body_602565 = body
  result = call_602564.call(nil, nil, nil, nil, body_602565)

var startImport* = Call_StartImport_602552(name: "startImport",
                                        meth: HttpMethod.HttpPost,
                                        host: "models.lex.amazonaws.com",
                                        route: "/imports/",
                                        validator: validate_StartImport_602553,
                                        base: "/", url: url_StartImport_602554,
                                        schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
