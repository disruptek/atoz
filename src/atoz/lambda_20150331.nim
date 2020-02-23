
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Lambda
## version: 2015-03-31
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Lambda</fullname> <p> <b>Overview</b> </p> <p>This is the <i>AWS Lambda API Reference</i>. The AWS Lambda Developer Guide provides additional information. For the service overview, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/welcome.html">What is AWS Lambda</a>, and for information about how the service works, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-introduction.html">AWS Lambda: How it Works</a> in the <b>AWS Lambda Developer Guide</b>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/lambda/
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

  OpenApiRestCall_615866 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_615866](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_615866): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "lambda.ap-northeast-1.amazonaws.com", "ap-southeast-1": "lambda.ap-southeast-1.amazonaws.com",
                           "us-west-2": "lambda.us-west-2.amazonaws.com",
                           "eu-west-2": "lambda.eu-west-2.amazonaws.com", "ap-northeast-3": "lambda.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "lambda.eu-central-1.amazonaws.com",
                           "us-east-2": "lambda.us-east-2.amazonaws.com",
                           "us-east-1": "lambda.us-east-1.amazonaws.com", "cn-northwest-1": "lambda.cn-northwest-1.amazonaws.com.cn", "ap-northeast-2": "lambda.ap-northeast-2.amazonaws.com",
                           "ap-south-1": "lambda.ap-south-1.amazonaws.com",
                           "eu-north-1": "lambda.eu-north-1.amazonaws.com",
                           "us-west-1": "lambda.us-west-1.amazonaws.com", "us-gov-east-1": "lambda.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "lambda.eu-west-3.amazonaws.com",
                           "cn-north-1": "lambda.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "lambda.sa-east-1.amazonaws.com",
                           "eu-west-1": "lambda.eu-west-1.amazonaws.com", "us-gov-west-1": "lambda.us-gov-west-1.amazonaws.com", "ap-southeast-2": "lambda.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "lambda.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "lambda.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "lambda.ap-southeast-1.amazonaws.com",
      "us-west-2": "lambda.us-west-2.amazonaws.com",
      "eu-west-2": "lambda.eu-west-2.amazonaws.com",
      "ap-northeast-3": "lambda.ap-northeast-3.amazonaws.com",
      "eu-central-1": "lambda.eu-central-1.amazonaws.com",
      "us-east-2": "lambda.us-east-2.amazonaws.com",
      "us-east-1": "lambda.us-east-1.amazonaws.com",
      "cn-northwest-1": "lambda.cn-northwest-1.amazonaws.com.cn",
      "ap-northeast-2": "lambda.ap-northeast-2.amazonaws.com",
      "ap-south-1": "lambda.ap-south-1.amazonaws.com",
      "eu-north-1": "lambda.eu-north-1.amazonaws.com",
      "us-west-1": "lambda.us-west-1.amazonaws.com",
      "us-gov-east-1": "lambda.us-gov-east-1.amazonaws.com",
      "eu-west-3": "lambda.eu-west-3.amazonaws.com",
      "cn-north-1": "lambda.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "lambda.sa-east-1.amazonaws.com",
      "eu-west-1": "lambda.eu-west-1.amazonaws.com",
      "us-gov-west-1": "lambda.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "lambda.ap-southeast-2.amazonaws.com",
      "ca-central-1": "lambda.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "lambda"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddLayerVersionPermission_616478 = ref object of OpenApiRestCall_615866
proc url_AddLayerVersionPermission_616480(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LayerName" in path, "`LayerName` is a required path parameter"
  assert "VersionNumber" in path, "`VersionNumber` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-10-31/layers/"),
               (kind: VariableSegment, value: "LayerName"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "VersionNumber"),
               (kind: ConstantSegment, value: "/policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AddLayerVersionPermission_616479(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds permissions to the resource-based policy of a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Use this action to grant layer usage permission to other accounts. You can grant permission to a single account, all AWS accounts, or all accounts in an organization.</p> <p>To revoke permission, call <a>RemoveLayerVersionPermission</a> with the statement ID that you specified when you added it.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   LayerName: JString (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  ##   VersionNumber: JInt (required)
  ##                : The version number.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `LayerName` field"
  var valid_616481 = path.getOrDefault("LayerName")
  valid_616481 = validateParameter(valid_616481, JString, required = true,
                                 default = nil)
  if valid_616481 != nil:
    section.add "LayerName", valid_616481
  var valid_616482 = path.getOrDefault("VersionNumber")
  valid_616482 = validateParameter(valid_616482, JInt, required = true, default = nil)
  if valid_616482 != nil:
    section.add "VersionNumber", valid_616482
  result.add "path", section
  ## parameters in `query` object:
  ##   RevisionId: JString
  ##             : Only update the policy if the revision ID matches the ID specified. Use this option to avoid modifying a policy that has changed since you last read it.
  section = newJObject()
  var valid_616483 = query.getOrDefault("RevisionId")
  valid_616483 = validateParameter(valid_616483, JString, required = false,
                                 default = nil)
  if valid_616483 != nil:
    section.add "RevisionId", valid_616483
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
  var valid_616484 = header.getOrDefault("X-Amz-Date")
  valid_616484 = validateParameter(valid_616484, JString, required = false,
                                 default = nil)
  if valid_616484 != nil:
    section.add "X-Amz-Date", valid_616484
  var valid_616485 = header.getOrDefault("X-Amz-Security-Token")
  valid_616485 = validateParameter(valid_616485, JString, required = false,
                                 default = nil)
  if valid_616485 != nil:
    section.add "X-Amz-Security-Token", valid_616485
  var valid_616486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616486 = validateParameter(valid_616486, JString, required = false,
                                 default = nil)
  if valid_616486 != nil:
    section.add "X-Amz-Content-Sha256", valid_616486
  var valid_616487 = header.getOrDefault("X-Amz-Algorithm")
  valid_616487 = validateParameter(valid_616487, JString, required = false,
                                 default = nil)
  if valid_616487 != nil:
    section.add "X-Amz-Algorithm", valid_616487
  var valid_616488 = header.getOrDefault("X-Amz-Signature")
  valid_616488 = validateParameter(valid_616488, JString, required = false,
                                 default = nil)
  if valid_616488 != nil:
    section.add "X-Amz-Signature", valid_616488
  var valid_616489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616489 = validateParameter(valid_616489, JString, required = false,
                                 default = nil)
  if valid_616489 != nil:
    section.add "X-Amz-SignedHeaders", valid_616489
  var valid_616490 = header.getOrDefault("X-Amz-Credential")
  valid_616490 = validateParameter(valid_616490, JString, required = false,
                                 default = nil)
  if valid_616490 != nil:
    section.add "X-Amz-Credential", valid_616490
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616492: Call_AddLayerVersionPermission_616478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds permissions to the resource-based policy of a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Use this action to grant layer usage permission to other accounts. You can grant permission to a single account, all AWS accounts, or all accounts in an organization.</p> <p>To revoke permission, call <a>RemoveLayerVersionPermission</a> with the statement ID that you specified when you added it.</p>
  ## 
  let valid = call_616492.validator(path, query, header, formData, body)
  let scheme = call_616492.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616492.url(scheme.get, call_616492.host, call_616492.base,
                         call_616492.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616492, url, valid)

proc call*(call_616493: Call_AddLayerVersionPermission_616478; LayerName: string;
          VersionNumber: int; body: JsonNode; RevisionId: string = ""): Recallable =
  ## addLayerVersionPermission
  ## <p>Adds permissions to the resource-based policy of a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Use this action to grant layer usage permission to other accounts. You can grant permission to a single account, all AWS accounts, or all accounts in an organization.</p> <p>To revoke permission, call <a>RemoveLayerVersionPermission</a> with the statement ID that you specified when you added it.</p>
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  ##   VersionNumber: int (required)
  ##                : The version number.
  ##   body: JObject (required)
  ##   RevisionId: string
  ##             : Only update the policy if the revision ID matches the ID specified. Use this option to avoid modifying a policy that has changed since you last read it.
  var path_616494 = newJObject()
  var query_616495 = newJObject()
  var body_616496 = newJObject()
  add(path_616494, "LayerName", newJString(LayerName))
  add(path_616494, "VersionNumber", newJInt(VersionNumber))
  if body != nil:
    body_616496 = body
  add(query_616495, "RevisionId", newJString(RevisionId))
  result = call_616493.call(path_616494, query_616495, nil, nil, body_616496)

var addLayerVersionPermission* = Call_AddLayerVersionPermission_616478(
    name: "addLayerVersionPermission", meth: HttpMethod.HttpPost,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy",
    validator: validate_AddLayerVersionPermission_616479, base: "/",
    url: url_AddLayerVersionPermission_616480,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLayerVersionPolicy_616205 = ref object of OpenApiRestCall_615866
proc url_GetLayerVersionPolicy_616207(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LayerName" in path, "`LayerName` is a required path parameter"
  assert "VersionNumber" in path, "`VersionNumber` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-10-31/layers/"),
               (kind: VariableSegment, value: "LayerName"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "VersionNumber"),
               (kind: ConstantSegment, value: "/policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetLayerVersionPolicy_616206(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the permission policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   LayerName: JString (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  ##   VersionNumber: JInt (required)
  ##                : The version number.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `LayerName` field"
  var valid_616333 = path.getOrDefault("LayerName")
  valid_616333 = validateParameter(valid_616333, JString, required = true,
                                 default = nil)
  if valid_616333 != nil:
    section.add "LayerName", valid_616333
  var valid_616334 = path.getOrDefault("VersionNumber")
  valid_616334 = validateParameter(valid_616334, JInt, required = true, default = nil)
  if valid_616334 != nil:
    section.add "VersionNumber", valid_616334
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
  var valid_616335 = header.getOrDefault("X-Amz-Date")
  valid_616335 = validateParameter(valid_616335, JString, required = false,
                                 default = nil)
  if valid_616335 != nil:
    section.add "X-Amz-Date", valid_616335
  var valid_616336 = header.getOrDefault("X-Amz-Security-Token")
  valid_616336 = validateParameter(valid_616336, JString, required = false,
                                 default = nil)
  if valid_616336 != nil:
    section.add "X-Amz-Security-Token", valid_616336
  var valid_616337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616337 = validateParameter(valid_616337, JString, required = false,
                                 default = nil)
  if valid_616337 != nil:
    section.add "X-Amz-Content-Sha256", valid_616337
  var valid_616338 = header.getOrDefault("X-Amz-Algorithm")
  valid_616338 = validateParameter(valid_616338, JString, required = false,
                                 default = nil)
  if valid_616338 != nil:
    section.add "X-Amz-Algorithm", valid_616338
  var valid_616339 = header.getOrDefault("X-Amz-Signature")
  valid_616339 = validateParameter(valid_616339, JString, required = false,
                                 default = nil)
  if valid_616339 != nil:
    section.add "X-Amz-Signature", valid_616339
  var valid_616340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616340 = validateParameter(valid_616340, JString, required = false,
                                 default = nil)
  if valid_616340 != nil:
    section.add "X-Amz-SignedHeaders", valid_616340
  var valid_616341 = header.getOrDefault("X-Amz-Credential")
  valid_616341 = validateParameter(valid_616341, JString, required = false,
                                 default = nil)
  if valid_616341 != nil:
    section.add "X-Amz-Credential", valid_616341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_616364: Call_GetLayerVersionPolicy_616205; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the permission policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ## 
  let valid = call_616364.validator(path, query, header, formData, body)
  let scheme = call_616364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616364.url(scheme.get, call_616364.host, call_616364.base,
                         call_616364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616364, url, valid)

proc call*(call_616435: Call_GetLayerVersionPolicy_616205; LayerName: string;
          VersionNumber: int): Recallable =
  ## getLayerVersionPolicy
  ## Returns the permission policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  ##   VersionNumber: int (required)
  ##                : The version number.
  var path_616436 = newJObject()
  add(path_616436, "LayerName", newJString(LayerName))
  add(path_616436, "VersionNumber", newJInt(VersionNumber))
  result = call_616435.call(path_616436, nil, nil, nil, nil)

var getLayerVersionPolicy* = Call_GetLayerVersionPolicy_616205(
    name: "getLayerVersionPolicy", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy",
    validator: validate_GetLayerVersionPolicy_616206, base: "/",
    url: url_GetLayerVersionPolicy_616207, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddPermission_616513 = ref object of OpenApiRestCall_615866
proc url_AddPermission_616515(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AddPermission_616514(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Grants an AWS service or another account permission to use a function. You can apply the policy at the function level, or specify a qualifier to restrict access to a single version or alias. If you use a qualifier, the invoker must use the full Amazon Resource Name (ARN) of that version or alias to invoke the function.</p> <p>To grant permission to another account, specify the account ID as the <code>Principal</code>. For AWS services, the principal is a domain-style identifier defined by the service, like <code>s3.amazonaws.com</code> or <code>sns.amazonaws.com</code>. For AWS services, you can also specify the ARN or owning account of the associated resource as the <code>SourceArn</code> or <code>SourceAccount</code>. If you grant permission to a service principal without specifying the source, other accounts could potentially configure resources in their account to invoke your Lambda function.</p> <p>This action adds a statement to a resource-based permissions policy for the function. For more information about function policies, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">Lambda Function Policies</a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_616516 = path.getOrDefault("FunctionName")
  valid_616516 = validateParameter(valid_616516, JString, required = true,
                                 default = nil)
  if valid_616516 != nil:
    section.add "FunctionName", valid_616516
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to add permissions to a published version of the function.
  section = newJObject()
  var valid_616517 = query.getOrDefault("Qualifier")
  valid_616517 = validateParameter(valid_616517, JString, required = false,
                                 default = nil)
  if valid_616517 != nil:
    section.add "Qualifier", valid_616517
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
  var valid_616518 = header.getOrDefault("X-Amz-Date")
  valid_616518 = validateParameter(valid_616518, JString, required = false,
                                 default = nil)
  if valid_616518 != nil:
    section.add "X-Amz-Date", valid_616518
  var valid_616519 = header.getOrDefault("X-Amz-Security-Token")
  valid_616519 = validateParameter(valid_616519, JString, required = false,
                                 default = nil)
  if valid_616519 != nil:
    section.add "X-Amz-Security-Token", valid_616519
  var valid_616520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616520 = validateParameter(valid_616520, JString, required = false,
                                 default = nil)
  if valid_616520 != nil:
    section.add "X-Amz-Content-Sha256", valid_616520
  var valid_616521 = header.getOrDefault("X-Amz-Algorithm")
  valid_616521 = validateParameter(valid_616521, JString, required = false,
                                 default = nil)
  if valid_616521 != nil:
    section.add "X-Amz-Algorithm", valid_616521
  var valid_616522 = header.getOrDefault("X-Amz-Signature")
  valid_616522 = validateParameter(valid_616522, JString, required = false,
                                 default = nil)
  if valid_616522 != nil:
    section.add "X-Amz-Signature", valid_616522
  var valid_616523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616523 = validateParameter(valid_616523, JString, required = false,
                                 default = nil)
  if valid_616523 != nil:
    section.add "X-Amz-SignedHeaders", valid_616523
  var valid_616524 = header.getOrDefault("X-Amz-Credential")
  valid_616524 = validateParameter(valid_616524, JString, required = false,
                                 default = nil)
  if valid_616524 != nil:
    section.add "X-Amz-Credential", valid_616524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616526: Call_AddPermission_616513; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Grants an AWS service or another account permission to use a function. You can apply the policy at the function level, or specify a qualifier to restrict access to a single version or alias. If you use a qualifier, the invoker must use the full Amazon Resource Name (ARN) of that version or alias to invoke the function.</p> <p>To grant permission to another account, specify the account ID as the <code>Principal</code>. For AWS services, the principal is a domain-style identifier defined by the service, like <code>s3.amazonaws.com</code> or <code>sns.amazonaws.com</code>. For AWS services, you can also specify the ARN or owning account of the associated resource as the <code>SourceArn</code> or <code>SourceAccount</code>. If you grant permission to a service principal without specifying the source, other accounts could potentially configure resources in their account to invoke your Lambda function.</p> <p>This action adds a statement to a resource-based permissions policy for the function. For more information about function policies, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">Lambda Function Policies</a>. </p>
  ## 
  let valid = call_616526.validator(path, query, header, formData, body)
  let scheme = call_616526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616526.url(scheme.get, call_616526.host, call_616526.base,
                         call_616526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616526, url, valid)

proc call*(call_616527: Call_AddPermission_616513; FunctionName: string;
          body: JsonNode; Qualifier: string = ""): Recallable =
  ## addPermission
  ## <p>Grants an AWS service or another account permission to use a function. You can apply the policy at the function level, or specify a qualifier to restrict access to a single version or alias. If you use a qualifier, the invoker must use the full Amazon Resource Name (ARN) of that version or alias to invoke the function.</p> <p>To grant permission to another account, specify the account ID as the <code>Principal</code>. For AWS services, the principal is a domain-style identifier defined by the service, like <code>s3.amazonaws.com</code> or <code>sns.amazonaws.com</code>. For AWS services, you can also specify the ARN or owning account of the associated resource as the <code>SourceArn</code> or <code>SourceAccount</code>. If you grant permission to a service principal without specifying the source, other accounts could potentially configure resources in their account to invoke your Lambda function.</p> <p>This action adds a statement to a resource-based permissions policy for the function. For more information about function policies, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">Lambda Function Policies</a>. </p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to add permissions to a published version of the function.
  ##   body: JObject (required)
  var path_616528 = newJObject()
  var query_616529 = newJObject()
  var body_616530 = newJObject()
  add(path_616528, "FunctionName", newJString(FunctionName))
  add(query_616529, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_616530 = body
  result = call_616527.call(path_616528, query_616529, nil, nil, body_616530)

var addPermission* = Call_AddPermission_616513(name: "addPermission",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/policy",
    validator: validate_AddPermission_616514, base: "/", url: url_AddPermission_616515,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPolicy_616497 = ref object of OpenApiRestCall_615866
proc url_GetPolicy_616499(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/policy")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetPolicy_616498(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">resource-based IAM policy</a> for a function, version, or alias.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_616500 = path.getOrDefault("FunctionName")
  valid_616500 = validateParameter(valid_616500, JString, required = true,
                                 default = nil)
  if valid_616500 != nil:
    section.add "FunctionName", valid_616500
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to get the policy for that resource.
  section = newJObject()
  var valid_616501 = query.getOrDefault("Qualifier")
  valid_616501 = validateParameter(valid_616501, JString, required = false,
                                 default = nil)
  if valid_616501 != nil:
    section.add "Qualifier", valid_616501
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
  var valid_616502 = header.getOrDefault("X-Amz-Date")
  valid_616502 = validateParameter(valid_616502, JString, required = false,
                                 default = nil)
  if valid_616502 != nil:
    section.add "X-Amz-Date", valid_616502
  var valid_616503 = header.getOrDefault("X-Amz-Security-Token")
  valid_616503 = validateParameter(valid_616503, JString, required = false,
                                 default = nil)
  if valid_616503 != nil:
    section.add "X-Amz-Security-Token", valid_616503
  var valid_616504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616504 = validateParameter(valid_616504, JString, required = false,
                                 default = nil)
  if valid_616504 != nil:
    section.add "X-Amz-Content-Sha256", valid_616504
  var valid_616505 = header.getOrDefault("X-Amz-Algorithm")
  valid_616505 = validateParameter(valid_616505, JString, required = false,
                                 default = nil)
  if valid_616505 != nil:
    section.add "X-Amz-Algorithm", valid_616505
  var valid_616506 = header.getOrDefault("X-Amz-Signature")
  valid_616506 = validateParameter(valid_616506, JString, required = false,
                                 default = nil)
  if valid_616506 != nil:
    section.add "X-Amz-Signature", valid_616506
  var valid_616507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616507 = validateParameter(valid_616507, JString, required = false,
                                 default = nil)
  if valid_616507 != nil:
    section.add "X-Amz-SignedHeaders", valid_616507
  var valid_616508 = header.getOrDefault("X-Amz-Credential")
  valid_616508 = validateParameter(valid_616508, JString, required = false,
                                 default = nil)
  if valid_616508 != nil:
    section.add "X-Amz-Credential", valid_616508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_616509: Call_GetPolicy_616497; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">resource-based IAM policy</a> for a function, version, or alias.
  ## 
  let valid = call_616509.validator(path, query, header, formData, body)
  let scheme = call_616509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616509.url(scheme.get, call_616509.host, call_616509.base,
                         call_616509.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616509, url, valid)

proc call*(call_616510: Call_GetPolicy_616497; FunctionName: string;
          Qualifier: string = ""): Recallable =
  ## getPolicy
  ## Returns the <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">resource-based IAM policy</a> for a function, version, or alias.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to get the policy for that resource.
  var path_616511 = newJObject()
  var query_616512 = newJObject()
  add(path_616511, "FunctionName", newJString(FunctionName))
  add(query_616512, "Qualifier", newJString(Qualifier))
  result = call_616510.call(path_616511, query_616512, nil, nil, nil)

var getPolicy* = Call_GetPolicy_616497(name: "getPolicy", meth: HttpMethod.HttpGet,
                                    host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/policy",
                                    validator: validate_GetPolicy_616498,
                                    base: "/", url: url_GetPolicy_616499,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAlias_616549 = ref object of OpenApiRestCall_615866
proc url_CreateAlias_616551(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/aliases")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateAlias_616550(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a> for a Lambda function version. Use aliases to provide clients with a function identifier that you can update to invoke a different version.</p> <p>You can also map an alias to split invocation requests between two versions. Use the <code>RoutingConfig</code> parameter to specify a second version and the percentage of invocation requests that it receives.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_616552 = path.getOrDefault("FunctionName")
  valid_616552 = validateParameter(valid_616552, JString, required = true,
                                 default = nil)
  if valid_616552 != nil:
    section.add "FunctionName", valid_616552
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
  var valid_616553 = header.getOrDefault("X-Amz-Date")
  valid_616553 = validateParameter(valid_616553, JString, required = false,
                                 default = nil)
  if valid_616553 != nil:
    section.add "X-Amz-Date", valid_616553
  var valid_616554 = header.getOrDefault("X-Amz-Security-Token")
  valid_616554 = validateParameter(valid_616554, JString, required = false,
                                 default = nil)
  if valid_616554 != nil:
    section.add "X-Amz-Security-Token", valid_616554
  var valid_616555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616555 = validateParameter(valid_616555, JString, required = false,
                                 default = nil)
  if valid_616555 != nil:
    section.add "X-Amz-Content-Sha256", valid_616555
  var valid_616556 = header.getOrDefault("X-Amz-Algorithm")
  valid_616556 = validateParameter(valid_616556, JString, required = false,
                                 default = nil)
  if valid_616556 != nil:
    section.add "X-Amz-Algorithm", valid_616556
  var valid_616557 = header.getOrDefault("X-Amz-Signature")
  valid_616557 = validateParameter(valid_616557, JString, required = false,
                                 default = nil)
  if valid_616557 != nil:
    section.add "X-Amz-Signature", valid_616557
  var valid_616558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616558 = validateParameter(valid_616558, JString, required = false,
                                 default = nil)
  if valid_616558 != nil:
    section.add "X-Amz-SignedHeaders", valid_616558
  var valid_616559 = header.getOrDefault("X-Amz-Credential")
  valid_616559 = validateParameter(valid_616559, JString, required = false,
                                 default = nil)
  if valid_616559 != nil:
    section.add "X-Amz-Credential", valid_616559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616561: Call_CreateAlias_616549; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a> for a Lambda function version. Use aliases to provide clients with a function identifier that you can update to invoke a different version.</p> <p>You can also map an alias to split invocation requests between two versions. Use the <code>RoutingConfig</code> parameter to specify a second version and the percentage of invocation requests that it receives.</p>
  ## 
  let valid = call_616561.validator(path, query, header, formData, body)
  let scheme = call_616561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616561.url(scheme.get, call_616561.host, call_616561.base,
                         call_616561.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616561, url, valid)

proc call*(call_616562: Call_CreateAlias_616549; FunctionName: string; body: JsonNode): Recallable =
  ## createAlias
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a> for a Lambda function version. Use aliases to provide clients with a function identifier that you can update to invoke a different version.</p> <p>You can also map an alias to split invocation requests between two versions. Use the <code>RoutingConfig</code> parameter to specify a second version and the percentage of invocation requests that it receives.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_616563 = newJObject()
  var body_616564 = newJObject()
  add(path_616563, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_616564 = body
  result = call_616562.call(path_616563, nil, nil, nil, body_616564)

var createAlias* = Call_CreateAlias_616549(name: "createAlias",
                                        meth: HttpMethod.HttpPost,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases",
                                        validator: validate_CreateAlias_616550,
                                        base: "/", url: url_CreateAlias_616551,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAliases_616531 = ref object of OpenApiRestCall_615866
proc url_ListAliases_616533(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/aliases")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListAliases_616532(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">aliases</a> for a Lambda function.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_616534 = path.getOrDefault("FunctionName")
  valid_616534 = validateParameter(valid_616534, JString, required = true,
                                 default = nil)
  if valid_616534 != nil:
    section.add "FunctionName", valid_616534
  result.add "path", section
  ## parameters in `query` object:
  ##   FunctionVersion: JString
  ##                  : Specify a function version to only list aliases that invoke that version.
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: JInt
  ##           : Limit the number of aliases returned.
  section = newJObject()
  var valid_616535 = query.getOrDefault("FunctionVersion")
  valid_616535 = validateParameter(valid_616535, JString, required = false,
                                 default = nil)
  if valid_616535 != nil:
    section.add "FunctionVersion", valid_616535
  var valid_616536 = query.getOrDefault("Marker")
  valid_616536 = validateParameter(valid_616536, JString, required = false,
                                 default = nil)
  if valid_616536 != nil:
    section.add "Marker", valid_616536
  var valid_616537 = query.getOrDefault("MaxItems")
  valid_616537 = validateParameter(valid_616537, JInt, required = false, default = nil)
  if valid_616537 != nil:
    section.add "MaxItems", valid_616537
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
  var valid_616538 = header.getOrDefault("X-Amz-Date")
  valid_616538 = validateParameter(valid_616538, JString, required = false,
                                 default = nil)
  if valid_616538 != nil:
    section.add "X-Amz-Date", valid_616538
  var valid_616539 = header.getOrDefault("X-Amz-Security-Token")
  valid_616539 = validateParameter(valid_616539, JString, required = false,
                                 default = nil)
  if valid_616539 != nil:
    section.add "X-Amz-Security-Token", valid_616539
  var valid_616540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616540 = validateParameter(valid_616540, JString, required = false,
                                 default = nil)
  if valid_616540 != nil:
    section.add "X-Amz-Content-Sha256", valid_616540
  var valid_616541 = header.getOrDefault("X-Amz-Algorithm")
  valid_616541 = validateParameter(valid_616541, JString, required = false,
                                 default = nil)
  if valid_616541 != nil:
    section.add "X-Amz-Algorithm", valid_616541
  var valid_616542 = header.getOrDefault("X-Amz-Signature")
  valid_616542 = validateParameter(valid_616542, JString, required = false,
                                 default = nil)
  if valid_616542 != nil:
    section.add "X-Amz-Signature", valid_616542
  var valid_616543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616543 = validateParameter(valid_616543, JString, required = false,
                                 default = nil)
  if valid_616543 != nil:
    section.add "X-Amz-SignedHeaders", valid_616543
  var valid_616544 = header.getOrDefault("X-Amz-Credential")
  valid_616544 = validateParameter(valid_616544, JString, required = false,
                                 default = nil)
  if valid_616544 != nil:
    section.add "X-Amz-Credential", valid_616544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_616545: Call_ListAliases_616531; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">aliases</a> for a Lambda function.
  ## 
  let valid = call_616545.validator(path, query, header, formData, body)
  let scheme = call_616545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616545.url(scheme.get, call_616545.host, call_616545.base,
                         call_616545.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616545, url, valid)

proc call*(call_616546: Call_ListAliases_616531; FunctionName: string;
          FunctionVersion: string = ""; Marker: string = ""; MaxItems: int = 0): Recallable =
  ## listAliases
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">aliases</a> for a Lambda function.
  ##   FunctionVersion: string
  ##                  : Specify a function version to only list aliases that invoke that version.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Marker: string
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: int
  ##           : Limit the number of aliases returned.
  var path_616547 = newJObject()
  var query_616548 = newJObject()
  add(query_616548, "FunctionVersion", newJString(FunctionVersion))
  add(path_616547, "FunctionName", newJString(FunctionName))
  add(query_616548, "Marker", newJString(Marker))
  add(query_616548, "MaxItems", newJInt(MaxItems))
  result = call_616546.call(path_616547, query_616548, nil, nil, nil)

var listAliases* = Call_ListAliases_616531(name: "listAliases",
                                        meth: HttpMethod.HttpGet,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases",
                                        validator: validate_ListAliases_616532,
                                        base: "/", url: url_ListAliases_616533,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEventSourceMapping_616582 = ref object of OpenApiRestCall_615866
proc url_CreateEventSourceMapping_616584(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEventSourceMapping_616583(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a mapping between an event source and an AWS Lambda function. Lambda reads items from the event source and triggers the function.</p> <p>For details about each event source type, see the following topics.</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html">Using AWS Lambda with Amazon DynamoDB</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html">Using AWS Lambda with Amazon Kinesis</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html">Using AWS Lambda with Amazon SQS</a> </p> </li> </ul> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> <li> <p> <code>ParallelizationFactor</code> - Process multiple batches from each shard concurrently.</p> </li> </ul>
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
  var valid_616585 = header.getOrDefault("X-Amz-Date")
  valid_616585 = validateParameter(valid_616585, JString, required = false,
                                 default = nil)
  if valid_616585 != nil:
    section.add "X-Amz-Date", valid_616585
  var valid_616586 = header.getOrDefault("X-Amz-Security-Token")
  valid_616586 = validateParameter(valid_616586, JString, required = false,
                                 default = nil)
  if valid_616586 != nil:
    section.add "X-Amz-Security-Token", valid_616586
  var valid_616587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616587 = validateParameter(valid_616587, JString, required = false,
                                 default = nil)
  if valid_616587 != nil:
    section.add "X-Amz-Content-Sha256", valid_616587
  var valid_616588 = header.getOrDefault("X-Amz-Algorithm")
  valid_616588 = validateParameter(valid_616588, JString, required = false,
                                 default = nil)
  if valid_616588 != nil:
    section.add "X-Amz-Algorithm", valid_616588
  var valid_616589 = header.getOrDefault("X-Amz-Signature")
  valid_616589 = validateParameter(valid_616589, JString, required = false,
                                 default = nil)
  if valid_616589 != nil:
    section.add "X-Amz-Signature", valid_616589
  var valid_616590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616590 = validateParameter(valid_616590, JString, required = false,
                                 default = nil)
  if valid_616590 != nil:
    section.add "X-Amz-SignedHeaders", valid_616590
  var valid_616591 = header.getOrDefault("X-Amz-Credential")
  valid_616591 = validateParameter(valid_616591, JString, required = false,
                                 default = nil)
  if valid_616591 != nil:
    section.add "X-Amz-Credential", valid_616591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616593: Call_CreateEventSourceMapping_616582; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a mapping between an event source and an AWS Lambda function. Lambda reads items from the event source and triggers the function.</p> <p>For details about each event source type, see the following topics.</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html">Using AWS Lambda with Amazon DynamoDB</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html">Using AWS Lambda with Amazon Kinesis</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html">Using AWS Lambda with Amazon SQS</a> </p> </li> </ul> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> <li> <p> <code>ParallelizationFactor</code> - Process multiple batches from each shard concurrently.</p> </li> </ul>
  ## 
  let valid = call_616593.validator(path, query, header, formData, body)
  let scheme = call_616593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616593.url(scheme.get, call_616593.host, call_616593.base,
                         call_616593.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616593, url, valid)

proc call*(call_616594: Call_CreateEventSourceMapping_616582; body: JsonNode): Recallable =
  ## createEventSourceMapping
  ## <p>Creates a mapping between an event source and an AWS Lambda function. Lambda reads items from the event source and triggers the function.</p> <p>For details about each event source type, see the following topics.</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html">Using AWS Lambda with Amazon DynamoDB</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html">Using AWS Lambda with Amazon Kinesis</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html">Using AWS Lambda with Amazon SQS</a> </p> </li> </ul> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> <li> <p> <code>ParallelizationFactor</code> - Process multiple batches from each shard concurrently.</p> </li> </ul>
  ##   body: JObject (required)
  var body_616595 = newJObject()
  if body != nil:
    body_616595 = body
  result = call_616594.call(nil, nil, nil, nil, body_616595)

var createEventSourceMapping* = Call_CreateEventSourceMapping_616582(
    name: "createEventSourceMapping", meth: HttpMethod.HttpPost,
    host: "lambda.amazonaws.com", route: "/2015-03-31/event-source-mappings/",
    validator: validate_CreateEventSourceMapping_616583, base: "/",
    url: url_CreateEventSourceMapping_616584, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEventSourceMappings_616565 = ref object of OpenApiRestCall_615866
proc url_ListEventSourceMappings_616567(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEventSourceMappings_616566(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists event source mappings. Specify an <code>EventSourceArn</code> to only show event source mappings for a single event source.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   FunctionName: JString
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Version or Alias ARN</b> - 
  ## <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction:PROD</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it's limited to 64 characters in length.</p>
  ##   EventSourceArn: JString
  ##                 : <p>The Amazon Resource Name (ARN) of the event source.</p> <ul> <li> <p> <b>Amazon Kinesis</b> - The ARN of the data stream or a stream consumer.</p> </li> <li> <p> <b>Amazon DynamoDB Streams</b> - The ARN of the stream.</p> </li> <li> <p> <b>Amazon Simple Queue Service</b> - The ARN of the queue.</p> </li> </ul>
  ##   Marker: JString
  ##         : A pagination token returned by a previous call.
  ##   MaxItems: JInt
  ##           : The maximum number of event source mappings to return.
  section = newJObject()
  var valid_616568 = query.getOrDefault("FunctionName")
  valid_616568 = validateParameter(valid_616568, JString, required = false,
                                 default = nil)
  if valid_616568 != nil:
    section.add "FunctionName", valid_616568
  var valid_616569 = query.getOrDefault("EventSourceArn")
  valid_616569 = validateParameter(valid_616569, JString, required = false,
                                 default = nil)
  if valid_616569 != nil:
    section.add "EventSourceArn", valid_616569
  var valid_616570 = query.getOrDefault("Marker")
  valid_616570 = validateParameter(valid_616570, JString, required = false,
                                 default = nil)
  if valid_616570 != nil:
    section.add "Marker", valid_616570
  var valid_616571 = query.getOrDefault("MaxItems")
  valid_616571 = validateParameter(valid_616571, JInt, required = false, default = nil)
  if valid_616571 != nil:
    section.add "MaxItems", valid_616571
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
  var valid_616572 = header.getOrDefault("X-Amz-Date")
  valid_616572 = validateParameter(valid_616572, JString, required = false,
                                 default = nil)
  if valid_616572 != nil:
    section.add "X-Amz-Date", valid_616572
  var valid_616573 = header.getOrDefault("X-Amz-Security-Token")
  valid_616573 = validateParameter(valid_616573, JString, required = false,
                                 default = nil)
  if valid_616573 != nil:
    section.add "X-Amz-Security-Token", valid_616573
  var valid_616574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616574 = validateParameter(valid_616574, JString, required = false,
                                 default = nil)
  if valid_616574 != nil:
    section.add "X-Amz-Content-Sha256", valid_616574
  var valid_616575 = header.getOrDefault("X-Amz-Algorithm")
  valid_616575 = validateParameter(valid_616575, JString, required = false,
                                 default = nil)
  if valid_616575 != nil:
    section.add "X-Amz-Algorithm", valid_616575
  var valid_616576 = header.getOrDefault("X-Amz-Signature")
  valid_616576 = validateParameter(valid_616576, JString, required = false,
                                 default = nil)
  if valid_616576 != nil:
    section.add "X-Amz-Signature", valid_616576
  var valid_616577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616577 = validateParameter(valid_616577, JString, required = false,
                                 default = nil)
  if valid_616577 != nil:
    section.add "X-Amz-SignedHeaders", valid_616577
  var valid_616578 = header.getOrDefault("X-Amz-Credential")
  valid_616578 = validateParameter(valid_616578, JString, required = false,
                                 default = nil)
  if valid_616578 != nil:
    section.add "X-Amz-Credential", valid_616578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_616579: Call_ListEventSourceMappings_616565; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists event source mappings. Specify an <code>EventSourceArn</code> to only show event source mappings for a single event source.
  ## 
  let valid = call_616579.validator(path, query, header, formData, body)
  let scheme = call_616579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616579.url(scheme.get, call_616579.host, call_616579.base,
                         call_616579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616579, url, valid)

proc call*(call_616580: Call_ListEventSourceMappings_616565;
          FunctionName: string = ""; EventSourceArn: string = ""; Marker: string = "";
          MaxItems: int = 0): Recallable =
  ## listEventSourceMappings
  ## Lists event source mappings. Specify an <code>EventSourceArn</code> to only show event source mappings for a single event source.
  ##   FunctionName: string
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Version or Alias ARN</b> - 
  ## <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction:PROD</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it's limited to 64 characters in length.</p>
  ##   EventSourceArn: string
  ##                 : <p>The Amazon Resource Name (ARN) of the event source.</p> <ul> <li> <p> <b>Amazon Kinesis</b> - The ARN of the data stream or a stream consumer.</p> </li> <li> <p> <b>Amazon DynamoDB Streams</b> - The ARN of the stream.</p> </li> <li> <p> <b>Amazon Simple Queue Service</b> - The ARN of the queue.</p> </li> </ul>
  ##   Marker: string
  ##         : A pagination token returned by a previous call.
  ##   MaxItems: int
  ##           : The maximum number of event source mappings to return.
  var query_616581 = newJObject()
  add(query_616581, "FunctionName", newJString(FunctionName))
  add(query_616581, "EventSourceArn", newJString(EventSourceArn))
  add(query_616581, "Marker", newJString(Marker))
  add(query_616581, "MaxItems", newJInt(MaxItems))
  result = call_616580.call(nil, query_616581, nil, nil, nil)

var listEventSourceMappings* = Call_ListEventSourceMappings_616565(
    name: "listEventSourceMappings", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com", route: "/2015-03-31/event-source-mappings/",
    validator: validate_ListEventSourceMappings_616566, base: "/",
    url: url_ListEventSourceMappings_616567, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunction_616596 = ref object of OpenApiRestCall_615866
proc url_CreateFunction_616598(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFunction_616597(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates a Lambda function. To create a function, you need a <a href="https://docs.aws.amazon.com/lambda/latest/dg/deployment-package-v2.html">deployment package</a> and an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-permission-model.html#lambda-intro-execution-role">execution role</a>. The deployment package contains your function code. The execution role grants the function permission to use AWS services, such as Amazon CloudWatch Logs for log streaming and AWS X-Ray for request tracing.</p> <p>When you create a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute or so. During this time, you can't invoke or modify the function. The <code>State</code>, <code>StateReason</code>, and <code>StateReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the function is ready to invoke. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Function States</a>.</p> <p>A function has an unpublished version, and can have published versions and aliases. The unpublished version changes when you update your function's code and configuration. A published version is a snapshot of your function code and configuration that can't be changed. An alias is a named resource that maps to a version, and can be changed to map to a different version. Use the <code>Publish</code> parameter to create version <code>1</code> of your function from its initial configuration.</p> <p>The other parameters let you configure version-specific and function-level settings. You can modify version-specific settings later with <a>UpdateFunctionConfiguration</a>. Function-level settings apply to both the unpublished and published versions of the function, and include tags (<a>TagResource</a>) and per-function concurrency limits (<a>PutFunctionConcurrency</a>).</p> <p>If another account or an AWS service invokes your function, use <a>AddPermission</a> to grant permission by creating a resource-based IAM policy. You can grant permissions at the function level, on a version, or on an alias.</p> <p>To invoke your function directly, use <a>Invoke</a>. To invoke your function in response to events in other AWS services, create an event source mapping (<a>CreateEventSourceMapping</a>), or configure a function trigger in the other service. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-invocation.html">Invoking Functions</a>.</p>
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
  var valid_616599 = header.getOrDefault("X-Amz-Date")
  valid_616599 = validateParameter(valid_616599, JString, required = false,
                                 default = nil)
  if valid_616599 != nil:
    section.add "X-Amz-Date", valid_616599
  var valid_616600 = header.getOrDefault("X-Amz-Security-Token")
  valid_616600 = validateParameter(valid_616600, JString, required = false,
                                 default = nil)
  if valid_616600 != nil:
    section.add "X-Amz-Security-Token", valid_616600
  var valid_616601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616601 = validateParameter(valid_616601, JString, required = false,
                                 default = nil)
  if valid_616601 != nil:
    section.add "X-Amz-Content-Sha256", valid_616601
  var valid_616602 = header.getOrDefault("X-Amz-Algorithm")
  valid_616602 = validateParameter(valid_616602, JString, required = false,
                                 default = nil)
  if valid_616602 != nil:
    section.add "X-Amz-Algorithm", valid_616602
  var valid_616603 = header.getOrDefault("X-Amz-Signature")
  valid_616603 = validateParameter(valid_616603, JString, required = false,
                                 default = nil)
  if valid_616603 != nil:
    section.add "X-Amz-Signature", valid_616603
  var valid_616604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616604 = validateParameter(valid_616604, JString, required = false,
                                 default = nil)
  if valid_616604 != nil:
    section.add "X-Amz-SignedHeaders", valid_616604
  var valid_616605 = header.getOrDefault("X-Amz-Credential")
  valid_616605 = validateParameter(valid_616605, JString, required = false,
                                 default = nil)
  if valid_616605 != nil:
    section.add "X-Amz-Credential", valid_616605
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616607: Call_CreateFunction_616596; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Lambda function. To create a function, you need a <a href="https://docs.aws.amazon.com/lambda/latest/dg/deployment-package-v2.html">deployment package</a> and an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-permission-model.html#lambda-intro-execution-role">execution role</a>. The deployment package contains your function code. The execution role grants the function permission to use AWS services, such as Amazon CloudWatch Logs for log streaming and AWS X-Ray for request tracing.</p> <p>When you create a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute or so. During this time, you can't invoke or modify the function. The <code>State</code>, <code>StateReason</code>, and <code>StateReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the function is ready to invoke. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Function States</a>.</p> <p>A function has an unpublished version, and can have published versions and aliases. The unpublished version changes when you update your function's code and configuration. A published version is a snapshot of your function code and configuration that can't be changed. An alias is a named resource that maps to a version, and can be changed to map to a different version. Use the <code>Publish</code> parameter to create version <code>1</code> of your function from its initial configuration.</p> <p>The other parameters let you configure version-specific and function-level settings. You can modify version-specific settings later with <a>UpdateFunctionConfiguration</a>. Function-level settings apply to both the unpublished and published versions of the function, and include tags (<a>TagResource</a>) and per-function concurrency limits (<a>PutFunctionConcurrency</a>).</p> <p>If another account or an AWS service invokes your function, use <a>AddPermission</a> to grant permission by creating a resource-based IAM policy. You can grant permissions at the function level, on a version, or on an alias.</p> <p>To invoke your function directly, use <a>Invoke</a>. To invoke your function in response to events in other AWS services, create an event source mapping (<a>CreateEventSourceMapping</a>), or configure a function trigger in the other service. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-invocation.html">Invoking Functions</a>.</p>
  ## 
  let valid = call_616607.validator(path, query, header, formData, body)
  let scheme = call_616607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616607.url(scheme.get, call_616607.host, call_616607.base,
                         call_616607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616607, url, valid)

proc call*(call_616608: Call_CreateFunction_616596; body: JsonNode): Recallable =
  ## createFunction
  ## <p>Creates a Lambda function. To create a function, you need a <a href="https://docs.aws.amazon.com/lambda/latest/dg/deployment-package-v2.html">deployment package</a> and an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-permission-model.html#lambda-intro-execution-role">execution role</a>. The deployment package contains your function code. The execution role grants the function permission to use AWS services, such as Amazon CloudWatch Logs for log streaming and AWS X-Ray for request tracing.</p> <p>When you create a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute or so. During this time, you can't invoke or modify the function. The <code>State</code>, <code>StateReason</code>, and <code>StateReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the function is ready to invoke. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Function States</a>.</p> <p>A function has an unpublished version, and can have published versions and aliases. The unpublished version changes when you update your function's code and configuration. A published version is a snapshot of your function code and configuration that can't be changed. An alias is a named resource that maps to a version, and can be changed to map to a different version. Use the <code>Publish</code> parameter to create version <code>1</code> of your function from its initial configuration.</p> <p>The other parameters let you configure version-specific and function-level settings. You can modify version-specific settings later with <a>UpdateFunctionConfiguration</a>. Function-level settings apply to both the unpublished and published versions of the function, and include tags (<a>TagResource</a>) and per-function concurrency limits (<a>PutFunctionConcurrency</a>).</p> <p>If another account or an AWS service invokes your function, use <a>AddPermission</a> to grant permission by creating a resource-based IAM policy. You can grant permissions at the function level, on a version, or on an alias.</p> <p>To invoke your function directly, use <a>Invoke</a>. To invoke your function in response to events in other AWS services, create an event source mapping (<a>CreateEventSourceMapping</a>), or configure a function trigger in the other service. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-invocation.html">Invoking Functions</a>.</p>
  ##   body: JObject (required)
  var body_616609 = newJObject()
  if body != nil:
    body_616609 = body
  result = call_616608.call(nil, nil, nil, nil, body_616609)

var createFunction* = Call_CreateFunction_616596(name: "createFunction",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions", validator: validate_CreateFunction_616597,
    base: "/", url: url_CreateFunction_616598, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAlias_616625 = ref object of OpenApiRestCall_615866
proc url_UpdateAlias_616627(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  assert "Name" in path, "`Name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/aliases/"),
               (kind: VariableSegment, value: "Name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateAlias_616626(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the configuration of a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Name: JString (required)
  ##       : The name of the alias.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_616628 = path.getOrDefault("FunctionName")
  valid_616628 = validateParameter(valid_616628, JString, required = true,
                                 default = nil)
  if valid_616628 != nil:
    section.add "FunctionName", valid_616628
  var valid_616629 = path.getOrDefault("Name")
  valid_616629 = validateParameter(valid_616629, JString, required = true,
                                 default = nil)
  if valid_616629 != nil:
    section.add "Name", valid_616629
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
  var valid_616630 = header.getOrDefault("X-Amz-Date")
  valid_616630 = validateParameter(valid_616630, JString, required = false,
                                 default = nil)
  if valid_616630 != nil:
    section.add "X-Amz-Date", valid_616630
  var valid_616631 = header.getOrDefault("X-Amz-Security-Token")
  valid_616631 = validateParameter(valid_616631, JString, required = false,
                                 default = nil)
  if valid_616631 != nil:
    section.add "X-Amz-Security-Token", valid_616631
  var valid_616632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616632 = validateParameter(valid_616632, JString, required = false,
                                 default = nil)
  if valid_616632 != nil:
    section.add "X-Amz-Content-Sha256", valid_616632
  var valid_616633 = header.getOrDefault("X-Amz-Algorithm")
  valid_616633 = validateParameter(valid_616633, JString, required = false,
                                 default = nil)
  if valid_616633 != nil:
    section.add "X-Amz-Algorithm", valid_616633
  var valid_616634 = header.getOrDefault("X-Amz-Signature")
  valid_616634 = validateParameter(valid_616634, JString, required = false,
                                 default = nil)
  if valid_616634 != nil:
    section.add "X-Amz-Signature", valid_616634
  var valid_616635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616635 = validateParameter(valid_616635, JString, required = false,
                                 default = nil)
  if valid_616635 != nil:
    section.add "X-Amz-SignedHeaders", valid_616635
  var valid_616636 = header.getOrDefault("X-Amz-Credential")
  valid_616636 = validateParameter(valid_616636, JString, required = false,
                                 default = nil)
  if valid_616636 != nil:
    section.add "X-Amz-Credential", valid_616636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616638: Call_UpdateAlias_616625; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the configuration of a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ## 
  let valid = call_616638.validator(path, query, header, formData, body)
  let scheme = call_616638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616638.url(scheme.get, call_616638.host, call_616638.base,
                         call_616638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616638, url, valid)

proc call*(call_616639: Call_UpdateAlias_616625; FunctionName: string; Name: string;
          body: JsonNode): Recallable =
  ## updateAlias
  ## Updates the configuration of a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Name: string (required)
  ##       : The name of the alias.
  ##   body: JObject (required)
  var path_616640 = newJObject()
  var body_616641 = newJObject()
  add(path_616640, "FunctionName", newJString(FunctionName))
  add(path_616640, "Name", newJString(Name))
  if body != nil:
    body_616641 = body
  result = call_616639.call(path_616640, nil, nil, nil, body_616641)

var updateAlias* = Call_UpdateAlias_616625(name: "updateAlias",
                                        meth: HttpMethod.HttpPut,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases/{Name}",
                                        validator: validate_UpdateAlias_616626,
                                        base: "/", url: url_UpdateAlias_616627,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAlias_616610 = ref object of OpenApiRestCall_615866
proc url_GetAlias_616612(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  assert "Name" in path, "`Name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/aliases/"),
               (kind: VariableSegment, value: "Name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAlias_616611(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns details about a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Name: JString (required)
  ##       : The name of the alias.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_616613 = path.getOrDefault("FunctionName")
  valid_616613 = validateParameter(valid_616613, JString, required = true,
                                 default = nil)
  if valid_616613 != nil:
    section.add "FunctionName", valid_616613
  var valid_616614 = path.getOrDefault("Name")
  valid_616614 = validateParameter(valid_616614, JString, required = true,
                                 default = nil)
  if valid_616614 != nil:
    section.add "Name", valid_616614
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
  var valid_616615 = header.getOrDefault("X-Amz-Date")
  valid_616615 = validateParameter(valid_616615, JString, required = false,
                                 default = nil)
  if valid_616615 != nil:
    section.add "X-Amz-Date", valid_616615
  var valid_616616 = header.getOrDefault("X-Amz-Security-Token")
  valid_616616 = validateParameter(valid_616616, JString, required = false,
                                 default = nil)
  if valid_616616 != nil:
    section.add "X-Amz-Security-Token", valid_616616
  var valid_616617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616617 = validateParameter(valid_616617, JString, required = false,
                                 default = nil)
  if valid_616617 != nil:
    section.add "X-Amz-Content-Sha256", valid_616617
  var valid_616618 = header.getOrDefault("X-Amz-Algorithm")
  valid_616618 = validateParameter(valid_616618, JString, required = false,
                                 default = nil)
  if valid_616618 != nil:
    section.add "X-Amz-Algorithm", valid_616618
  var valid_616619 = header.getOrDefault("X-Amz-Signature")
  valid_616619 = validateParameter(valid_616619, JString, required = false,
                                 default = nil)
  if valid_616619 != nil:
    section.add "X-Amz-Signature", valid_616619
  var valid_616620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616620 = validateParameter(valid_616620, JString, required = false,
                                 default = nil)
  if valid_616620 != nil:
    section.add "X-Amz-SignedHeaders", valid_616620
  var valid_616621 = header.getOrDefault("X-Amz-Credential")
  valid_616621 = validateParameter(valid_616621, JString, required = false,
                                 default = nil)
  if valid_616621 != nil:
    section.add "X-Amz-Credential", valid_616621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_616622: Call_GetAlias_616610; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns details about a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ## 
  let valid = call_616622.validator(path, query, header, formData, body)
  let scheme = call_616622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616622.url(scheme.get, call_616622.host, call_616622.base,
                         call_616622.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616622, url, valid)

proc call*(call_616623: Call_GetAlias_616610; FunctionName: string; Name: string): Recallable =
  ## getAlias
  ## Returns details about a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Name: string (required)
  ##       : The name of the alias.
  var path_616624 = newJObject()
  add(path_616624, "FunctionName", newJString(FunctionName))
  add(path_616624, "Name", newJString(Name))
  result = call_616623.call(path_616624, nil, nil, nil, nil)

var getAlias* = Call_GetAlias_616610(name: "getAlias", meth: HttpMethod.HttpGet,
                                  host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases/{Name}",
                                  validator: validate_GetAlias_616611, base: "/",
                                  url: url_GetAlias_616612,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAlias_616642 = ref object of OpenApiRestCall_615866
proc url_DeleteAlias_616644(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  assert "Name" in path, "`Name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/aliases/"),
               (kind: VariableSegment, value: "Name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAlias_616643(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Name: JString (required)
  ##       : The name of the alias.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_616645 = path.getOrDefault("FunctionName")
  valid_616645 = validateParameter(valid_616645, JString, required = true,
                                 default = nil)
  if valid_616645 != nil:
    section.add "FunctionName", valid_616645
  var valid_616646 = path.getOrDefault("Name")
  valid_616646 = validateParameter(valid_616646, JString, required = true,
                                 default = nil)
  if valid_616646 != nil:
    section.add "Name", valid_616646
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
  var valid_616647 = header.getOrDefault("X-Amz-Date")
  valid_616647 = validateParameter(valid_616647, JString, required = false,
                                 default = nil)
  if valid_616647 != nil:
    section.add "X-Amz-Date", valid_616647
  var valid_616648 = header.getOrDefault("X-Amz-Security-Token")
  valid_616648 = validateParameter(valid_616648, JString, required = false,
                                 default = nil)
  if valid_616648 != nil:
    section.add "X-Amz-Security-Token", valid_616648
  var valid_616649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616649 = validateParameter(valid_616649, JString, required = false,
                                 default = nil)
  if valid_616649 != nil:
    section.add "X-Amz-Content-Sha256", valid_616649
  var valid_616650 = header.getOrDefault("X-Amz-Algorithm")
  valid_616650 = validateParameter(valid_616650, JString, required = false,
                                 default = nil)
  if valid_616650 != nil:
    section.add "X-Amz-Algorithm", valid_616650
  var valid_616651 = header.getOrDefault("X-Amz-Signature")
  valid_616651 = validateParameter(valid_616651, JString, required = false,
                                 default = nil)
  if valid_616651 != nil:
    section.add "X-Amz-Signature", valid_616651
  var valid_616652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616652 = validateParameter(valid_616652, JString, required = false,
                                 default = nil)
  if valid_616652 != nil:
    section.add "X-Amz-SignedHeaders", valid_616652
  var valid_616653 = header.getOrDefault("X-Amz-Credential")
  valid_616653 = validateParameter(valid_616653, JString, required = false,
                                 default = nil)
  if valid_616653 != nil:
    section.add "X-Amz-Credential", valid_616653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_616654: Call_DeleteAlias_616642; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ## 
  let valid = call_616654.validator(path, query, header, formData, body)
  let scheme = call_616654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616654.url(scheme.get, call_616654.host, call_616654.base,
                         call_616654.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616654, url, valid)

proc call*(call_616655: Call_DeleteAlias_616642; FunctionName: string; Name: string): Recallable =
  ## deleteAlias
  ## Deletes a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Name: string (required)
  ##       : The name of the alias.
  var path_616656 = newJObject()
  add(path_616656, "FunctionName", newJString(FunctionName))
  add(path_616656, "Name", newJString(Name))
  result = call_616655.call(path_616656, nil, nil, nil, nil)

var deleteAlias* = Call_DeleteAlias_616642(name: "deleteAlias",
                                        meth: HttpMethod.HttpDelete,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases/{Name}",
                                        validator: validate_DeleteAlias_616643,
                                        base: "/", url: url_DeleteAlias_616644,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEventSourceMapping_616671 = ref object of OpenApiRestCall_615866
proc url_UpdateEventSourceMapping_616673(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "UUID" in path, "`UUID` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/event-source-mappings/"),
               (kind: VariableSegment, value: "UUID")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateEventSourceMapping_616672(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates an event source mapping. You can change the function that AWS Lambda invokes, or pause invocation and resume later from the same location.</p> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> <li> <p> <code>ParallelizationFactor</code> - Process multiple batches from each shard concurrently.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UUID: JString (required)
  ##       : The identifier of the event source mapping.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UUID` field"
  var valid_616674 = path.getOrDefault("UUID")
  valid_616674 = validateParameter(valid_616674, JString, required = true,
                                 default = nil)
  if valid_616674 != nil:
    section.add "UUID", valid_616674
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
  var valid_616675 = header.getOrDefault("X-Amz-Date")
  valid_616675 = validateParameter(valid_616675, JString, required = false,
                                 default = nil)
  if valid_616675 != nil:
    section.add "X-Amz-Date", valid_616675
  var valid_616676 = header.getOrDefault("X-Amz-Security-Token")
  valid_616676 = validateParameter(valid_616676, JString, required = false,
                                 default = nil)
  if valid_616676 != nil:
    section.add "X-Amz-Security-Token", valid_616676
  var valid_616677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616677 = validateParameter(valid_616677, JString, required = false,
                                 default = nil)
  if valid_616677 != nil:
    section.add "X-Amz-Content-Sha256", valid_616677
  var valid_616678 = header.getOrDefault("X-Amz-Algorithm")
  valid_616678 = validateParameter(valid_616678, JString, required = false,
                                 default = nil)
  if valid_616678 != nil:
    section.add "X-Amz-Algorithm", valid_616678
  var valid_616679 = header.getOrDefault("X-Amz-Signature")
  valid_616679 = validateParameter(valid_616679, JString, required = false,
                                 default = nil)
  if valid_616679 != nil:
    section.add "X-Amz-Signature", valid_616679
  var valid_616680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616680 = validateParameter(valid_616680, JString, required = false,
                                 default = nil)
  if valid_616680 != nil:
    section.add "X-Amz-SignedHeaders", valid_616680
  var valid_616681 = header.getOrDefault("X-Amz-Credential")
  valid_616681 = validateParameter(valid_616681, JString, required = false,
                                 default = nil)
  if valid_616681 != nil:
    section.add "X-Amz-Credential", valid_616681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616683: Call_UpdateEventSourceMapping_616671; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an event source mapping. You can change the function that AWS Lambda invokes, or pause invocation and resume later from the same location.</p> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> <li> <p> <code>ParallelizationFactor</code> - Process multiple batches from each shard concurrently.</p> </li> </ul>
  ## 
  let valid = call_616683.validator(path, query, header, formData, body)
  let scheme = call_616683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616683.url(scheme.get, call_616683.host, call_616683.base,
                         call_616683.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616683, url, valid)

proc call*(call_616684: Call_UpdateEventSourceMapping_616671; UUID: string;
          body: JsonNode): Recallable =
  ## updateEventSourceMapping
  ## <p>Updates an event source mapping. You can change the function that AWS Lambda invokes, or pause invocation and resume later from the same location.</p> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> <li> <p> <code>ParallelizationFactor</code> - Process multiple batches from each shard concurrently.</p> </li> </ul>
  ##   UUID: string (required)
  ##       : The identifier of the event source mapping.
  ##   body: JObject (required)
  var path_616685 = newJObject()
  var body_616686 = newJObject()
  add(path_616685, "UUID", newJString(UUID))
  if body != nil:
    body_616686 = body
  result = call_616684.call(path_616685, nil, nil, nil, body_616686)

var updateEventSourceMapping* = Call_UpdateEventSourceMapping_616671(
    name: "updateEventSourceMapping", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/event-source-mappings/{UUID}",
    validator: validate_UpdateEventSourceMapping_616672, base: "/",
    url: url_UpdateEventSourceMapping_616673, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventSourceMapping_616657 = ref object of OpenApiRestCall_615866
proc url_GetEventSourceMapping_616659(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "UUID" in path, "`UUID` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/event-source-mappings/"),
               (kind: VariableSegment, value: "UUID")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetEventSourceMapping_616658(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns details about an event source mapping. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UUID: JString (required)
  ##       : The identifier of the event source mapping.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UUID` field"
  var valid_616660 = path.getOrDefault("UUID")
  valid_616660 = validateParameter(valid_616660, JString, required = true,
                                 default = nil)
  if valid_616660 != nil:
    section.add "UUID", valid_616660
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
  var valid_616661 = header.getOrDefault("X-Amz-Date")
  valid_616661 = validateParameter(valid_616661, JString, required = false,
                                 default = nil)
  if valid_616661 != nil:
    section.add "X-Amz-Date", valid_616661
  var valid_616662 = header.getOrDefault("X-Amz-Security-Token")
  valid_616662 = validateParameter(valid_616662, JString, required = false,
                                 default = nil)
  if valid_616662 != nil:
    section.add "X-Amz-Security-Token", valid_616662
  var valid_616663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616663 = validateParameter(valid_616663, JString, required = false,
                                 default = nil)
  if valid_616663 != nil:
    section.add "X-Amz-Content-Sha256", valid_616663
  var valid_616664 = header.getOrDefault("X-Amz-Algorithm")
  valid_616664 = validateParameter(valid_616664, JString, required = false,
                                 default = nil)
  if valid_616664 != nil:
    section.add "X-Amz-Algorithm", valid_616664
  var valid_616665 = header.getOrDefault("X-Amz-Signature")
  valid_616665 = validateParameter(valid_616665, JString, required = false,
                                 default = nil)
  if valid_616665 != nil:
    section.add "X-Amz-Signature", valid_616665
  var valid_616666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616666 = validateParameter(valid_616666, JString, required = false,
                                 default = nil)
  if valid_616666 != nil:
    section.add "X-Amz-SignedHeaders", valid_616666
  var valid_616667 = header.getOrDefault("X-Amz-Credential")
  valid_616667 = validateParameter(valid_616667, JString, required = false,
                                 default = nil)
  if valid_616667 != nil:
    section.add "X-Amz-Credential", valid_616667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_616668: Call_GetEventSourceMapping_616657; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns details about an event source mapping. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.
  ## 
  let valid = call_616668.validator(path, query, header, formData, body)
  let scheme = call_616668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616668.url(scheme.get, call_616668.host, call_616668.base,
                         call_616668.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616668, url, valid)

proc call*(call_616669: Call_GetEventSourceMapping_616657; UUID: string): Recallable =
  ## getEventSourceMapping
  ## Returns details about an event source mapping. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.
  ##   UUID: string (required)
  ##       : The identifier of the event source mapping.
  var path_616670 = newJObject()
  add(path_616670, "UUID", newJString(UUID))
  result = call_616669.call(path_616670, nil, nil, nil, nil)

var getEventSourceMapping* = Call_GetEventSourceMapping_616657(
    name: "getEventSourceMapping", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/event-source-mappings/{UUID}",
    validator: validate_GetEventSourceMapping_616658, base: "/",
    url: url_GetEventSourceMapping_616659, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventSourceMapping_616687 = ref object of OpenApiRestCall_615866
proc url_DeleteEventSourceMapping_616689(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "UUID" in path, "`UUID` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/event-source-mappings/"),
               (kind: VariableSegment, value: "UUID")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteEventSourceMapping_616688(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-invocation-modes.html">event source mapping</a>. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.</p> <p>When you delete an event source mapping, it enters a <code>Deleting</code> state and might not be completely deleted for several seconds.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UUID: JString (required)
  ##       : The identifier of the event source mapping.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UUID` field"
  var valid_616690 = path.getOrDefault("UUID")
  valid_616690 = validateParameter(valid_616690, JString, required = true,
                                 default = nil)
  if valid_616690 != nil:
    section.add "UUID", valid_616690
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
  var valid_616691 = header.getOrDefault("X-Amz-Date")
  valid_616691 = validateParameter(valid_616691, JString, required = false,
                                 default = nil)
  if valid_616691 != nil:
    section.add "X-Amz-Date", valid_616691
  var valid_616692 = header.getOrDefault("X-Amz-Security-Token")
  valid_616692 = validateParameter(valid_616692, JString, required = false,
                                 default = nil)
  if valid_616692 != nil:
    section.add "X-Amz-Security-Token", valid_616692
  var valid_616693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616693 = validateParameter(valid_616693, JString, required = false,
                                 default = nil)
  if valid_616693 != nil:
    section.add "X-Amz-Content-Sha256", valid_616693
  var valid_616694 = header.getOrDefault("X-Amz-Algorithm")
  valid_616694 = validateParameter(valid_616694, JString, required = false,
                                 default = nil)
  if valid_616694 != nil:
    section.add "X-Amz-Algorithm", valid_616694
  var valid_616695 = header.getOrDefault("X-Amz-Signature")
  valid_616695 = validateParameter(valid_616695, JString, required = false,
                                 default = nil)
  if valid_616695 != nil:
    section.add "X-Amz-Signature", valid_616695
  var valid_616696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616696 = validateParameter(valid_616696, JString, required = false,
                                 default = nil)
  if valid_616696 != nil:
    section.add "X-Amz-SignedHeaders", valid_616696
  var valid_616697 = header.getOrDefault("X-Amz-Credential")
  valid_616697 = validateParameter(valid_616697, JString, required = false,
                                 default = nil)
  if valid_616697 != nil:
    section.add "X-Amz-Credential", valid_616697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_616698: Call_DeleteEventSourceMapping_616687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-invocation-modes.html">event source mapping</a>. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.</p> <p>When you delete an event source mapping, it enters a <code>Deleting</code> state and might not be completely deleted for several seconds.</p>
  ## 
  let valid = call_616698.validator(path, query, header, formData, body)
  let scheme = call_616698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616698.url(scheme.get, call_616698.host, call_616698.base,
                         call_616698.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616698, url, valid)

proc call*(call_616699: Call_DeleteEventSourceMapping_616687; UUID: string): Recallable =
  ## deleteEventSourceMapping
  ## <p>Deletes an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-invocation-modes.html">event source mapping</a>. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.</p> <p>When you delete an event source mapping, it enters a <code>Deleting</code> state and might not be completely deleted for several seconds.</p>
  ##   UUID: string (required)
  ##       : The identifier of the event source mapping.
  var path_616700 = newJObject()
  add(path_616700, "UUID", newJString(UUID))
  result = call_616699.call(path_616700, nil, nil, nil, nil)

var deleteEventSourceMapping* = Call_DeleteEventSourceMapping_616687(
    name: "deleteEventSourceMapping", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/event-source-mappings/{UUID}",
    validator: validate_DeleteEventSourceMapping_616688, base: "/",
    url: url_DeleteEventSourceMapping_616689, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunction_616701 = ref object of OpenApiRestCall_615866
proc url_GetFunction_616703(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFunction_616702(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about the function or function version, with a link to download the deployment package that's valid for 10 minutes. If you specify a function version, only details that are specific to that version are returned.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_616704 = path.getOrDefault("FunctionName")
  valid_616704 = validateParameter(valid_616704, JString, required = true,
                                 default = nil)
  if valid_616704 != nil:
    section.add "FunctionName", valid_616704
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to get details about a published version of the function.
  section = newJObject()
  var valid_616705 = query.getOrDefault("Qualifier")
  valid_616705 = validateParameter(valid_616705, JString, required = false,
                                 default = nil)
  if valid_616705 != nil:
    section.add "Qualifier", valid_616705
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
  var valid_616706 = header.getOrDefault("X-Amz-Date")
  valid_616706 = validateParameter(valid_616706, JString, required = false,
                                 default = nil)
  if valid_616706 != nil:
    section.add "X-Amz-Date", valid_616706
  var valid_616707 = header.getOrDefault("X-Amz-Security-Token")
  valid_616707 = validateParameter(valid_616707, JString, required = false,
                                 default = nil)
  if valid_616707 != nil:
    section.add "X-Amz-Security-Token", valid_616707
  var valid_616708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616708 = validateParameter(valid_616708, JString, required = false,
                                 default = nil)
  if valid_616708 != nil:
    section.add "X-Amz-Content-Sha256", valid_616708
  var valid_616709 = header.getOrDefault("X-Amz-Algorithm")
  valid_616709 = validateParameter(valid_616709, JString, required = false,
                                 default = nil)
  if valid_616709 != nil:
    section.add "X-Amz-Algorithm", valid_616709
  var valid_616710 = header.getOrDefault("X-Amz-Signature")
  valid_616710 = validateParameter(valid_616710, JString, required = false,
                                 default = nil)
  if valid_616710 != nil:
    section.add "X-Amz-Signature", valid_616710
  var valid_616711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616711 = validateParameter(valid_616711, JString, required = false,
                                 default = nil)
  if valid_616711 != nil:
    section.add "X-Amz-SignedHeaders", valid_616711
  var valid_616712 = header.getOrDefault("X-Amz-Credential")
  valid_616712 = validateParameter(valid_616712, JString, required = false,
                                 default = nil)
  if valid_616712 != nil:
    section.add "X-Amz-Credential", valid_616712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_616713: Call_GetFunction_616701; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the function or function version, with a link to download the deployment package that's valid for 10 minutes. If you specify a function version, only details that are specific to that version are returned.
  ## 
  let valid = call_616713.validator(path, query, header, formData, body)
  let scheme = call_616713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616713.url(scheme.get, call_616713.host, call_616713.base,
                         call_616713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616713, url, valid)

proc call*(call_616714: Call_GetFunction_616701; FunctionName: string;
          Qualifier: string = ""): Recallable =
  ## getFunction
  ## Returns information about the function or function version, with a link to download the deployment package that's valid for 10 minutes. If you specify a function version, only details that are specific to that version are returned.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to get details about a published version of the function.
  var path_616715 = newJObject()
  var query_616716 = newJObject()
  add(path_616715, "FunctionName", newJString(FunctionName))
  add(query_616716, "Qualifier", newJString(Qualifier))
  result = call_616714.call(path_616715, query_616716, nil, nil, nil)

var getFunction* = Call_GetFunction_616701(name: "getFunction",
                                        meth: HttpMethod.HttpGet,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}",
                                        validator: validate_GetFunction_616702,
                                        base: "/", url: url_GetFunction_616703,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunction_616717 = ref object of OpenApiRestCall_615866
proc url_DeleteFunction_616719(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFunction_616718(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Deletes a Lambda function. To delete a specific function version, use the <code>Qualifier</code> parameter. Otherwise, all versions and aliases are deleted.</p> <p>To delete Lambda event source mappings that invoke a function, use <a>DeleteEventSourceMapping</a>. For AWS services and resources that invoke your function directly, delete the trigger in the service where you originally configured it.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function or version.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:1</code> (with version).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_616720 = path.getOrDefault("FunctionName")
  valid_616720 = validateParameter(valid_616720, JString, required = true,
                                 default = nil)
  if valid_616720 != nil:
    section.add "FunctionName", valid_616720
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version to delete. You can't delete a version that's referenced by an alias.
  section = newJObject()
  var valid_616721 = query.getOrDefault("Qualifier")
  valid_616721 = validateParameter(valid_616721, JString, required = false,
                                 default = nil)
  if valid_616721 != nil:
    section.add "Qualifier", valid_616721
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
  var valid_616722 = header.getOrDefault("X-Amz-Date")
  valid_616722 = validateParameter(valid_616722, JString, required = false,
                                 default = nil)
  if valid_616722 != nil:
    section.add "X-Amz-Date", valid_616722
  var valid_616723 = header.getOrDefault("X-Amz-Security-Token")
  valid_616723 = validateParameter(valid_616723, JString, required = false,
                                 default = nil)
  if valid_616723 != nil:
    section.add "X-Amz-Security-Token", valid_616723
  var valid_616724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616724 = validateParameter(valid_616724, JString, required = false,
                                 default = nil)
  if valid_616724 != nil:
    section.add "X-Amz-Content-Sha256", valid_616724
  var valid_616725 = header.getOrDefault("X-Amz-Algorithm")
  valid_616725 = validateParameter(valid_616725, JString, required = false,
                                 default = nil)
  if valid_616725 != nil:
    section.add "X-Amz-Algorithm", valid_616725
  var valid_616726 = header.getOrDefault("X-Amz-Signature")
  valid_616726 = validateParameter(valid_616726, JString, required = false,
                                 default = nil)
  if valid_616726 != nil:
    section.add "X-Amz-Signature", valid_616726
  var valid_616727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616727 = validateParameter(valid_616727, JString, required = false,
                                 default = nil)
  if valid_616727 != nil:
    section.add "X-Amz-SignedHeaders", valid_616727
  var valid_616728 = header.getOrDefault("X-Amz-Credential")
  valid_616728 = validateParameter(valid_616728, JString, required = false,
                                 default = nil)
  if valid_616728 != nil:
    section.add "X-Amz-Credential", valid_616728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_616729: Call_DeleteFunction_616717; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a Lambda function. To delete a specific function version, use the <code>Qualifier</code> parameter. Otherwise, all versions and aliases are deleted.</p> <p>To delete Lambda event source mappings that invoke a function, use <a>DeleteEventSourceMapping</a>. For AWS services and resources that invoke your function directly, delete the trigger in the service where you originally configured it.</p>
  ## 
  let valid = call_616729.validator(path, query, header, formData, body)
  let scheme = call_616729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616729.url(scheme.get, call_616729.host, call_616729.base,
                         call_616729.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616729, url, valid)

proc call*(call_616730: Call_DeleteFunction_616717; FunctionName: string;
          Qualifier: string = ""): Recallable =
  ## deleteFunction
  ## <p>Deletes a Lambda function. To delete a specific function version, use the <code>Qualifier</code> parameter. Otherwise, all versions and aliases are deleted.</p> <p>To delete Lambda event source mappings that invoke a function, use <a>DeleteEventSourceMapping</a>. For AWS services and resources that invoke your function directly, delete the trigger in the service where you originally configured it.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function or version.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:1</code> (with version).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version to delete. You can't delete a version that's referenced by an alias.
  var path_616731 = newJObject()
  var query_616732 = newJObject()
  add(path_616731, "FunctionName", newJString(FunctionName))
  add(query_616732, "Qualifier", newJString(Qualifier))
  result = call_616730.call(path_616731, query_616732, nil, nil, nil)

var deleteFunction* = Call_DeleteFunction_616717(name: "deleteFunction",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}",
    validator: validate_DeleteFunction_616718, base: "/", url: url_DeleteFunction_616719,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutFunctionConcurrency_616733 = ref object of OpenApiRestCall_615866
proc url_PutFunctionConcurrency_616735(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-10-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/concurrency")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutFunctionConcurrency_616734(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Sets the maximum number of simultaneous executions for a function, and reserves capacity for that concurrency level.</p> <p>Concurrency settings apply to the function as a whole, including all published versions and the unpublished version. Reserving concurrency both ensures that your function has capacity to process the specified number of events simultaneously, and prevents it from scaling beyond that level. Use <a>GetFunction</a> to see the current setting for a function.</p> <p>Use <a>GetAccountSettings</a> to see your Regional concurrency limit. You can reserve concurrency for as many functions as you like, as long as you leave at least 100 simultaneous executions unreserved for functions that aren't configured with a per-function limit. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/concurrent-executions.html">Managing Concurrency</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_616736 = path.getOrDefault("FunctionName")
  valid_616736 = validateParameter(valid_616736, JString, required = true,
                                 default = nil)
  if valid_616736 != nil:
    section.add "FunctionName", valid_616736
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
  var valid_616737 = header.getOrDefault("X-Amz-Date")
  valid_616737 = validateParameter(valid_616737, JString, required = false,
                                 default = nil)
  if valid_616737 != nil:
    section.add "X-Amz-Date", valid_616737
  var valid_616738 = header.getOrDefault("X-Amz-Security-Token")
  valid_616738 = validateParameter(valid_616738, JString, required = false,
                                 default = nil)
  if valid_616738 != nil:
    section.add "X-Amz-Security-Token", valid_616738
  var valid_616739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616739 = validateParameter(valid_616739, JString, required = false,
                                 default = nil)
  if valid_616739 != nil:
    section.add "X-Amz-Content-Sha256", valid_616739
  var valid_616740 = header.getOrDefault("X-Amz-Algorithm")
  valid_616740 = validateParameter(valid_616740, JString, required = false,
                                 default = nil)
  if valid_616740 != nil:
    section.add "X-Amz-Algorithm", valid_616740
  var valid_616741 = header.getOrDefault("X-Amz-Signature")
  valid_616741 = validateParameter(valid_616741, JString, required = false,
                                 default = nil)
  if valid_616741 != nil:
    section.add "X-Amz-Signature", valid_616741
  var valid_616742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616742 = validateParameter(valid_616742, JString, required = false,
                                 default = nil)
  if valid_616742 != nil:
    section.add "X-Amz-SignedHeaders", valid_616742
  var valid_616743 = header.getOrDefault("X-Amz-Credential")
  valid_616743 = validateParameter(valid_616743, JString, required = false,
                                 default = nil)
  if valid_616743 != nil:
    section.add "X-Amz-Credential", valid_616743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616745: Call_PutFunctionConcurrency_616733; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the maximum number of simultaneous executions for a function, and reserves capacity for that concurrency level.</p> <p>Concurrency settings apply to the function as a whole, including all published versions and the unpublished version. Reserving concurrency both ensures that your function has capacity to process the specified number of events simultaneously, and prevents it from scaling beyond that level. Use <a>GetFunction</a> to see the current setting for a function.</p> <p>Use <a>GetAccountSettings</a> to see your Regional concurrency limit. You can reserve concurrency for as many functions as you like, as long as you leave at least 100 simultaneous executions unreserved for functions that aren't configured with a per-function limit. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/concurrent-executions.html">Managing Concurrency</a>.</p>
  ## 
  let valid = call_616745.validator(path, query, header, formData, body)
  let scheme = call_616745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616745.url(scheme.get, call_616745.host, call_616745.base,
                         call_616745.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616745, url, valid)

proc call*(call_616746: Call_PutFunctionConcurrency_616733; FunctionName: string;
          body: JsonNode): Recallable =
  ## putFunctionConcurrency
  ## <p>Sets the maximum number of simultaneous executions for a function, and reserves capacity for that concurrency level.</p> <p>Concurrency settings apply to the function as a whole, including all published versions and the unpublished version. Reserving concurrency both ensures that your function has capacity to process the specified number of events simultaneously, and prevents it from scaling beyond that level. Use <a>GetFunction</a> to see the current setting for a function.</p> <p>Use <a>GetAccountSettings</a> to see your Regional concurrency limit. You can reserve concurrency for as many functions as you like, as long as you leave at least 100 simultaneous executions unreserved for functions that aren't configured with a per-function limit. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/concurrent-executions.html">Managing Concurrency</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_616747 = newJObject()
  var body_616748 = newJObject()
  add(path_616747, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_616748 = body
  result = call_616746.call(path_616747, nil, nil, nil, body_616748)

var putFunctionConcurrency* = Call_PutFunctionConcurrency_616733(
    name: "putFunctionConcurrency", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2017-10-31/functions/{FunctionName}/concurrency",
    validator: validate_PutFunctionConcurrency_616734, base: "/",
    url: url_PutFunctionConcurrency_616735, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunctionConcurrency_616749 = ref object of OpenApiRestCall_615866
proc url_DeleteFunctionConcurrency_616751(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-10-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/concurrency")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFunctionConcurrency_616750(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a concurrent execution limit from a function.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_616752 = path.getOrDefault("FunctionName")
  valid_616752 = validateParameter(valid_616752, JString, required = true,
                                 default = nil)
  if valid_616752 != nil:
    section.add "FunctionName", valid_616752
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
  var valid_616753 = header.getOrDefault("X-Amz-Date")
  valid_616753 = validateParameter(valid_616753, JString, required = false,
                                 default = nil)
  if valid_616753 != nil:
    section.add "X-Amz-Date", valid_616753
  var valid_616754 = header.getOrDefault("X-Amz-Security-Token")
  valid_616754 = validateParameter(valid_616754, JString, required = false,
                                 default = nil)
  if valid_616754 != nil:
    section.add "X-Amz-Security-Token", valid_616754
  var valid_616755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616755 = validateParameter(valid_616755, JString, required = false,
                                 default = nil)
  if valid_616755 != nil:
    section.add "X-Amz-Content-Sha256", valid_616755
  var valid_616756 = header.getOrDefault("X-Amz-Algorithm")
  valid_616756 = validateParameter(valid_616756, JString, required = false,
                                 default = nil)
  if valid_616756 != nil:
    section.add "X-Amz-Algorithm", valid_616756
  var valid_616757 = header.getOrDefault("X-Amz-Signature")
  valid_616757 = validateParameter(valid_616757, JString, required = false,
                                 default = nil)
  if valid_616757 != nil:
    section.add "X-Amz-Signature", valid_616757
  var valid_616758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616758 = validateParameter(valid_616758, JString, required = false,
                                 default = nil)
  if valid_616758 != nil:
    section.add "X-Amz-SignedHeaders", valid_616758
  var valid_616759 = header.getOrDefault("X-Amz-Credential")
  valid_616759 = validateParameter(valid_616759, JString, required = false,
                                 default = nil)
  if valid_616759 != nil:
    section.add "X-Amz-Credential", valid_616759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_616760: Call_DeleteFunctionConcurrency_616749; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a concurrent execution limit from a function.
  ## 
  let valid = call_616760.validator(path, query, header, formData, body)
  let scheme = call_616760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616760.url(scheme.get, call_616760.host, call_616760.base,
                         call_616760.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616760, url, valid)

proc call*(call_616761: Call_DeleteFunctionConcurrency_616749; FunctionName: string): Recallable =
  ## deleteFunctionConcurrency
  ## Removes a concurrent execution limit from a function.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  var path_616762 = newJObject()
  add(path_616762, "FunctionName", newJString(FunctionName))
  result = call_616761.call(path_616762, nil, nil, nil, nil)

var deleteFunctionConcurrency* = Call_DeleteFunctionConcurrency_616749(
    name: "deleteFunctionConcurrency", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com",
    route: "/2017-10-31/functions/{FunctionName}/concurrency",
    validator: validate_DeleteFunctionConcurrency_616750, base: "/",
    url: url_DeleteFunctionConcurrency_616751,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutFunctionEventInvokeConfig_616779 = ref object of OpenApiRestCall_615866
proc url_PutFunctionEventInvokeConfig_616781(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-09-25/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/event-invoke-config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutFunctionEventInvokeConfig_616780(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Configures options for <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a> on a function, version, or alias. If a configuration already exists for a function, version, or alias, this operation overwrites it. If you exclude any settings, they are removed. To set one option without affecting existing settings for other options, use <a>PutFunctionEventInvokeConfig</a>.</p> <p>By default, Lambda retries an asynchronous invocation twice if the function returns an error. It retains events in a queue for up to six hours. When an event fails all processing attempts or stays in the asynchronous invocation queue for too long, Lambda discards it. To retain discarded events, configure a dead-letter queue with <a>UpdateFunctionConfiguration</a>.</p> <p>To send an invocation record to a queue, topic, function, or event bus, specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#invocation-async-destinations">destination</a>. You can configure separate destinations for successful invocations (on-success) and events that fail all processing attempts (on-failure). You can configure destinations in addition to or instead of a dead-letter queue.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_616782 = path.getOrDefault("FunctionName")
  valid_616782 = validateParameter(valid_616782, JString, required = true,
                                 default = nil)
  if valid_616782 != nil:
    section.add "FunctionName", valid_616782
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : A version number or alias name.
  section = newJObject()
  var valid_616783 = query.getOrDefault("Qualifier")
  valid_616783 = validateParameter(valid_616783, JString, required = false,
                                 default = nil)
  if valid_616783 != nil:
    section.add "Qualifier", valid_616783
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
  var valid_616784 = header.getOrDefault("X-Amz-Date")
  valid_616784 = validateParameter(valid_616784, JString, required = false,
                                 default = nil)
  if valid_616784 != nil:
    section.add "X-Amz-Date", valid_616784
  var valid_616785 = header.getOrDefault("X-Amz-Security-Token")
  valid_616785 = validateParameter(valid_616785, JString, required = false,
                                 default = nil)
  if valid_616785 != nil:
    section.add "X-Amz-Security-Token", valid_616785
  var valid_616786 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616786 = validateParameter(valid_616786, JString, required = false,
                                 default = nil)
  if valid_616786 != nil:
    section.add "X-Amz-Content-Sha256", valid_616786
  var valid_616787 = header.getOrDefault("X-Amz-Algorithm")
  valid_616787 = validateParameter(valid_616787, JString, required = false,
                                 default = nil)
  if valid_616787 != nil:
    section.add "X-Amz-Algorithm", valid_616787
  var valid_616788 = header.getOrDefault("X-Amz-Signature")
  valid_616788 = validateParameter(valid_616788, JString, required = false,
                                 default = nil)
  if valid_616788 != nil:
    section.add "X-Amz-Signature", valid_616788
  var valid_616789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616789 = validateParameter(valid_616789, JString, required = false,
                                 default = nil)
  if valid_616789 != nil:
    section.add "X-Amz-SignedHeaders", valid_616789
  var valid_616790 = header.getOrDefault("X-Amz-Credential")
  valid_616790 = validateParameter(valid_616790, JString, required = false,
                                 default = nil)
  if valid_616790 != nil:
    section.add "X-Amz-Credential", valid_616790
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616792: Call_PutFunctionEventInvokeConfig_616779; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configures options for <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a> on a function, version, or alias. If a configuration already exists for a function, version, or alias, this operation overwrites it. If you exclude any settings, they are removed. To set one option without affecting existing settings for other options, use <a>PutFunctionEventInvokeConfig</a>.</p> <p>By default, Lambda retries an asynchronous invocation twice if the function returns an error. It retains events in a queue for up to six hours. When an event fails all processing attempts or stays in the asynchronous invocation queue for too long, Lambda discards it. To retain discarded events, configure a dead-letter queue with <a>UpdateFunctionConfiguration</a>.</p> <p>To send an invocation record to a queue, topic, function, or event bus, specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#invocation-async-destinations">destination</a>. You can configure separate destinations for successful invocations (on-success) and events that fail all processing attempts (on-failure). You can configure destinations in addition to or instead of a dead-letter queue.</p>
  ## 
  let valid = call_616792.validator(path, query, header, formData, body)
  let scheme = call_616792.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616792.url(scheme.get, call_616792.host, call_616792.base,
                         call_616792.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616792, url, valid)

proc call*(call_616793: Call_PutFunctionEventInvokeConfig_616779;
          FunctionName: string; body: JsonNode; Qualifier: string = ""): Recallable =
  ## putFunctionEventInvokeConfig
  ## <p>Configures options for <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a> on a function, version, or alias. If a configuration already exists for a function, version, or alias, this operation overwrites it. If you exclude any settings, they are removed. To set one option without affecting existing settings for other options, use <a>PutFunctionEventInvokeConfig</a>.</p> <p>By default, Lambda retries an asynchronous invocation twice if the function returns an error. It retains events in a queue for up to six hours. When an event fails all processing attempts or stays in the asynchronous invocation queue for too long, Lambda discards it. To retain discarded events, configure a dead-letter queue with <a>UpdateFunctionConfiguration</a>.</p> <p>To send an invocation record to a queue, topic, function, or event bus, specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#invocation-async-destinations">destination</a>. You can configure separate destinations for successful invocations (on-success) and events that fail all processing attempts (on-failure). You can configure destinations in addition to or instead of a dead-letter queue.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : A version number or alias name.
  ##   body: JObject (required)
  var path_616794 = newJObject()
  var query_616795 = newJObject()
  var body_616796 = newJObject()
  add(path_616794, "FunctionName", newJString(FunctionName))
  add(query_616795, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_616796 = body
  result = call_616793.call(path_616794, query_616795, nil, nil, body_616796)

var putFunctionEventInvokeConfig* = Call_PutFunctionEventInvokeConfig_616779(
    name: "putFunctionEventInvokeConfig", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config",
    validator: validate_PutFunctionEventInvokeConfig_616780, base: "/",
    url: url_PutFunctionEventInvokeConfig_616781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionEventInvokeConfig_616797 = ref object of OpenApiRestCall_615866
proc url_UpdateFunctionEventInvokeConfig_616799(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-09-25/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/event-invoke-config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFunctionEventInvokeConfig_616798(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_616800 = path.getOrDefault("FunctionName")
  valid_616800 = validateParameter(valid_616800, JString, required = true,
                                 default = nil)
  if valid_616800 != nil:
    section.add "FunctionName", valid_616800
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : A version number or alias name.
  section = newJObject()
  var valid_616801 = query.getOrDefault("Qualifier")
  valid_616801 = validateParameter(valid_616801, JString, required = false,
                                 default = nil)
  if valid_616801 != nil:
    section.add "Qualifier", valid_616801
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
  var valid_616802 = header.getOrDefault("X-Amz-Date")
  valid_616802 = validateParameter(valid_616802, JString, required = false,
                                 default = nil)
  if valid_616802 != nil:
    section.add "X-Amz-Date", valid_616802
  var valid_616803 = header.getOrDefault("X-Amz-Security-Token")
  valid_616803 = validateParameter(valid_616803, JString, required = false,
                                 default = nil)
  if valid_616803 != nil:
    section.add "X-Amz-Security-Token", valid_616803
  var valid_616804 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616804 = validateParameter(valid_616804, JString, required = false,
                                 default = nil)
  if valid_616804 != nil:
    section.add "X-Amz-Content-Sha256", valid_616804
  var valid_616805 = header.getOrDefault("X-Amz-Algorithm")
  valid_616805 = validateParameter(valid_616805, JString, required = false,
                                 default = nil)
  if valid_616805 != nil:
    section.add "X-Amz-Algorithm", valid_616805
  var valid_616806 = header.getOrDefault("X-Amz-Signature")
  valid_616806 = validateParameter(valid_616806, JString, required = false,
                                 default = nil)
  if valid_616806 != nil:
    section.add "X-Amz-Signature", valid_616806
  var valid_616807 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616807 = validateParameter(valid_616807, JString, required = false,
                                 default = nil)
  if valid_616807 != nil:
    section.add "X-Amz-SignedHeaders", valid_616807
  var valid_616808 = header.getOrDefault("X-Amz-Credential")
  valid_616808 = validateParameter(valid_616808, JString, required = false,
                                 default = nil)
  if valid_616808 != nil:
    section.add "X-Amz-Credential", valid_616808
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616810: Call_UpdateFunctionEventInvokeConfig_616797;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Updates the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  let valid = call_616810.validator(path, query, header, formData, body)
  let scheme = call_616810.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616810.url(scheme.get, call_616810.host, call_616810.base,
                         call_616810.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616810, url, valid)

proc call*(call_616811: Call_UpdateFunctionEventInvokeConfig_616797;
          FunctionName: string; body: JsonNode; Qualifier: string = ""): Recallable =
  ## updateFunctionEventInvokeConfig
  ## <p>Updates the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : A version number or alias name.
  ##   body: JObject (required)
  var path_616812 = newJObject()
  var query_616813 = newJObject()
  var body_616814 = newJObject()
  add(path_616812, "FunctionName", newJString(FunctionName))
  add(query_616813, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_616814 = body
  result = call_616811.call(path_616812, query_616813, nil, nil, body_616814)

var updateFunctionEventInvokeConfig* = Call_UpdateFunctionEventInvokeConfig_616797(
    name: "updateFunctionEventInvokeConfig", meth: HttpMethod.HttpPost,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config",
    validator: validate_UpdateFunctionEventInvokeConfig_616798, base: "/",
    url: url_UpdateFunctionEventInvokeConfig_616799,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionEventInvokeConfig_616763 = ref object of OpenApiRestCall_615866
proc url_GetFunctionEventInvokeConfig_616765(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-09-25/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/event-invoke-config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFunctionEventInvokeConfig_616764(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_616766 = path.getOrDefault("FunctionName")
  valid_616766 = validateParameter(valid_616766, JString, required = true,
                                 default = nil)
  if valid_616766 != nil:
    section.add "FunctionName", valid_616766
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : A version number or alias name.
  section = newJObject()
  var valid_616767 = query.getOrDefault("Qualifier")
  valid_616767 = validateParameter(valid_616767, JString, required = false,
                                 default = nil)
  if valid_616767 != nil:
    section.add "Qualifier", valid_616767
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
  var valid_616768 = header.getOrDefault("X-Amz-Date")
  valid_616768 = validateParameter(valid_616768, JString, required = false,
                                 default = nil)
  if valid_616768 != nil:
    section.add "X-Amz-Date", valid_616768
  var valid_616769 = header.getOrDefault("X-Amz-Security-Token")
  valid_616769 = validateParameter(valid_616769, JString, required = false,
                                 default = nil)
  if valid_616769 != nil:
    section.add "X-Amz-Security-Token", valid_616769
  var valid_616770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616770 = validateParameter(valid_616770, JString, required = false,
                                 default = nil)
  if valid_616770 != nil:
    section.add "X-Amz-Content-Sha256", valid_616770
  var valid_616771 = header.getOrDefault("X-Amz-Algorithm")
  valid_616771 = validateParameter(valid_616771, JString, required = false,
                                 default = nil)
  if valid_616771 != nil:
    section.add "X-Amz-Algorithm", valid_616771
  var valid_616772 = header.getOrDefault("X-Amz-Signature")
  valid_616772 = validateParameter(valid_616772, JString, required = false,
                                 default = nil)
  if valid_616772 != nil:
    section.add "X-Amz-Signature", valid_616772
  var valid_616773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616773 = validateParameter(valid_616773, JString, required = false,
                                 default = nil)
  if valid_616773 != nil:
    section.add "X-Amz-SignedHeaders", valid_616773
  var valid_616774 = header.getOrDefault("X-Amz-Credential")
  valid_616774 = validateParameter(valid_616774, JString, required = false,
                                 default = nil)
  if valid_616774 != nil:
    section.add "X-Amz-Credential", valid_616774
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_616775: Call_GetFunctionEventInvokeConfig_616763; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  let valid = call_616775.validator(path, query, header, formData, body)
  let scheme = call_616775.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616775.url(scheme.get, call_616775.host, call_616775.base,
                         call_616775.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616775, url, valid)

proc call*(call_616776: Call_GetFunctionEventInvokeConfig_616763;
          FunctionName: string; Qualifier: string = ""): Recallable =
  ## getFunctionEventInvokeConfig
  ## <p>Retrieves the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : A version number or alias name.
  var path_616777 = newJObject()
  var query_616778 = newJObject()
  add(path_616777, "FunctionName", newJString(FunctionName))
  add(query_616778, "Qualifier", newJString(Qualifier))
  result = call_616776.call(path_616777, query_616778, nil, nil, nil)

var getFunctionEventInvokeConfig* = Call_GetFunctionEventInvokeConfig_616763(
    name: "getFunctionEventInvokeConfig", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config",
    validator: validate_GetFunctionEventInvokeConfig_616764, base: "/",
    url: url_GetFunctionEventInvokeConfig_616765,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunctionEventInvokeConfig_616815 = ref object of OpenApiRestCall_615866
proc url_DeleteFunctionEventInvokeConfig_616817(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-09-25/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/event-invoke-config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFunctionEventInvokeConfig_616816(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_616818 = path.getOrDefault("FunctionName")
  valid_616818 = validateParameter(valid_616818, JString, required = true,
                                 default = nil)
  if valid_616818 != nil:
    section.add "FunctionName", valid_616818
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : A version number or alias name.
  section = newJObject()
  var valid_616819 = query.getOrDefault("Qualifier")
  valid_616819 = validateParameter(valid_616819, JString, required = false,
                                 default = nil)
  if valid_616819 != nil:
    section.add "Qualifier", valid_616819
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
  var valid_616820 = header.getOrDefault("X-Amz-Date")
  valid_616820 = validateParameter(valid_616820, JString, required = false,
                                 default = nil)
  if valid_616820 != nil:
    section.add "X-Amz-Date", valid_616820
  var valid_616821 = header.getOrDefault("X-Amz-Security-Token")
  valid_616821 = validateParameter(valid_616821, JString, required = false,
                                 default = nil)
  if valid_616821 != nil:
    section.add "X-Amz-Security-Token", valid_616821
  var valid_616822 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616822 = validateParameter(valid_616822, JString, required = false,
                                 default = nil)
  if valid_616822 != nil:
    section.add "X-Amz-Content-Sha256", valid_616822
  var valid_616823 = header.getOrDefault("X-Amz-Algorithm")
  valid_616823 = validateParameter(valid_616823, JString, required = false,
                                 default = nil)
  if valid_616823 != nil:
    section.add "X-Amz-Algorithm", valid_616823
  var valid_616824 = header.getOrDefault("X-Amz-Signature")
  valid_616824 = validateParameter(valid_616824, JString, required = false,
                                 default = nil)
  if valid_616824 != nil:
    section.add "X-Amz-Signature", valid_616824
  var valid_616825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616825 = validateParameter(valid_616825, JString, required = false,
                                 default = nil)
  if valid_616825 != nil:
    section.add "X-Amz-SignedHeaders", valid_616825
  var valid_616826 = header.getOrDefault("X-Amz-Credential")
  valid_616826 = validateParameter(valid_616826, JString, required = false,
                                 default = nil)
  if valid_616826 != nil:
    section.add "X-Amz-Credential", valid_616826
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_616827: Call_DeleteFunctionEventInvokeConfig_616815;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  let valid = call_616827.validator(path, query, header, formData, body)
  let scheme = call_616827.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616827.url(scheme.get, call_616827.host, call_616827.base,
                         call_616827.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616827, url, valid)

proc call*(call_616828: Call_DeleteFunctionEventInvokeConfig_616815;
          FunctionName: string; Qualifier: string = ""): Recallable =
  ## deleteFunctionEventInvokeConfig
  ## <p>Deletes the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : A version number or alias name.
  var path_616829 = newJObject()
  var query_616830 = newJObject()
  add(path_616829, "FunctionName", newJString(FunctionName))
  add(query_616830, "Qualifier", newJString(Qualifier))
  result = call_616828.call(path_616829, query_616830, nil, nil, nil)

var deleteFunctionEventInvokeConfig* = Call_DeleteFunctionEventInvokeConfig_616815(
    name: "deleteFunctionEventInvokeConfig", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config",
    validator: validate_DeleteFunctionEventInvokeConfig_616816, base: "/",
    url: url_DeleteFunctionEventInvokeConfig_616817,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLayerVersion_616831 = ref object of OpenApiRestCall_615866
proc url_GetLayerVersion_616833(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LayerName" in path, "`LayerName` is a required path parameter"
  assert "VersionNumber" in path, "`VersionNumber` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-10-31/layers/"),
               (kind: VariableSegment, value: "LayerName"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "VersionNumber")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetLayerVersion_616832(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   LayerName: JString (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  ##   VersionNumber: JInt (required)
  ##                : The version number.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `LayerName` field"
  var valid_616834 = path.getOrDefault("LayerName")
  valid_616834 = validateParameter(valid_616834, JString, required = true,
                                 default = nil)
  if valid_616834 != nil:
    section.add "LayerName", valid_616834
  var valid_616835 = path.getOrDefault("VersionNumber")
  valid_616835 = validateParameter(valid_616835, JInt, required = true, default = nil)
  if valid_616835 != nil:
    section.add "VersionNumber", valid_616835
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
  var valid_616836 = header.getOrDefault("X-Amz-Date")
  valid_616836 = validateParameter(valid_616836, JString, required = false,
                                 default = nil)
  if valid_616836 != nil:
    section.add "X-Amz-Date", valid_616836
  var valid_616837 = header.getOrDefault("X-Amz-Security-Token")
  valid_616837 = validateParameter(valid_616837, JString, required = false,
                                 default = nil)
  if valid_616837 != nil:
    section.add "X-Amz-Security-Token", valid_616837
  var valid_616838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616838 = validateParameter(valid_616838, JString, required = false,
                                 default = nil)
  if valid_616838 != nil:
    section.add "X-Amz-Content-Sha256", valid_616838
  var valid_616839 = header.getOrDefault("X-Amz-Algorithm")
  valid_616839 = validateParameter(valid_616839, JString, required = false,
                                 default = nil)
  if valid_616839 != nil:
    section.add "X-Amz-Algorithm", valid_616839
  var valid_616840 = header.getOrDefault("X-Amz-Signature")
  valid_616840 = validateParameter(valid_616840, JString, required = false,
                                 default = nil)
  if valid_616840 != nil:
    section.add "X-Amz-Signature", valid_616840
  var valid_616841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616841 = validateParameter(valid_616841, JString, required = false,
                                 default = nil)
  if valid_616841 != nil:
    section.add "X-Amz-SignedHeaders", valid_616841
  var valid_616842 = header.getOrDefault("X-Amz-Credential")
  valid_616842 = validateParameter(valid_616842, JString, required = false,
                                 default = nil)
  if valid_616842 != nil:
    section.add "X-Amz-Credential", valid_616842
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_616843: Call_GetLayerVersion_616831; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ## 
  let valid = call_616843.validator(path, query, header, formData, body)
  let scheme = call_616843.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616843.url(scheme.get, call_616843.host, call_616843.base,
                         call_616843.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616843, url, valid)

proc call*(call_616844: Call_GetLayerVersion_616831; LayerName: string;
          VersionNumber: int): Recallable =
  ## getLayerVersion
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  ##   VersionNumber: int (required)
  ##                : The version number.
  var path_616845 = newJObject()
  add(path_616845, "LayerName", newJString(LayerName))
  add(path_616845, "VersionNumber", newJInt(VersionNumber))
  result = call_616844.call(path_616845, nil, nil, nil, nil)

var getLayerVersion* = Call_GetLayerVersion_616831(name: "getLayerVersion",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}",
    validator: validate_GetLayerVersion_616832, base: "/", url: url_GetLayerVersion_616833,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLayerVersion_616846 = ref object of OpenApiRestCall_615866
proc url_DeleteLayerVersion_616848(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LayerName" in path, "`LayerName` is a required path parameter"
  assert "VersionNumber" in path, "`VersionNumber` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-10-31/layers/"),
               (kind: VariableSegment, value: "LayerName"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "VersionNumber")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteLayerVersion_616847(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Deleted versions can no longer be viewed or added to functions. To avoid breaking functions, a copy of the version remains in Lambda until no functions refer to it.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   LayerName: JString (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  ##   VersionNumber: JInt (required)
  ##                : The version number.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `LayerName` field"
  var valid_616849 = path.getOrDefault("LayerName")
  valid_616849 = validateParameter(valid_616849, JString, required = true,
                                 default = nil)
  if valid_616849 != nil:
    section.add "LayerName", valid_616849
  var valid_616850 = path.getOrDefault("VersionNumber")
  valid_616850 = validateParameter(valid_616850, JInt, required = true, default = nil)
  if valid_616850 != nil:
    section.add "VersionNumber", valid_616850
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
  var valid_616851 = header.getOrDefault("X-Amz-Date")
  valid_616851 = validateParameter(valid_616851, JString, required = false,
                                 default = nil)
  if valid_616851 != nil:
    section.add "X-Amz-Date", valid_616851
  var valid_616852 = header.getOrDefault("X-Amz-Security-Token")
  valid_616852 = validateParameter(valid_616852, JString, required = false,
                                 default = nil)
  if valid_616852 != nil:
    section.add "X-Amz-Security-Token", valid_616852
  var valid_616853 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616853 = validateParameter(valid_616853, JString, required = false,
                                 default = nil)
  if valid_616853 != nil:
    section.add "X-Amz-Content-Sha256", valid_616853
  var valid_616854 = header.getOrDefault("X-Amz-Algorithm")
  valid_616854 = validateParameter(valid_616854, JString, required = false,
                                 default = nil)
  if valid_616854 != nil:
    section.add "X-Amz-Algorithm", valid_616854
  var valid_616855 = header.getOrDefault("X-Amz-Signature")
  valid_616855 = validateParameter(valid_616855, JString, required = false,
                                 default = nil)
  if valid_616855 != nil:
    section.add "X-Amz-Signature", valid_616855
  var valid_616856 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616856 = validateParameter(valid_616856, JString, required = false,
                                 default = nil)
  if valid_616856 != nil:
    section.add "X-Amz-SignedHeaders", valid_616856
  var valid_616857 = header.getOrDefault("X-Amz-Credential")
  valid_616857 = validateParameter(valid_616857, JString, required = false,
                                 default = nil)
  if valid_616857 != nil:
    section.add "X-Amz-Credential", valid_616857
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_616858: Call_DeleteLayerVersion_616846; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Deleted versions can no longer be viewed or added to functions. To avoid breaking functions, a copy of the version remains in Lambda until no functions refer to it.
  ## 
  let valid = call_616858.validator(path, query, header, formData, body)
  let scheme = call_616858.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616858.url(scheme.get, call_616858.host, call_616858.base,
                         call_616858.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616858, url, valid)

proc call*(call_616859: Call_DeleteLayerVersion_616846; LayerName: string;
          VersionNumber: int): Recallable =
  ## deleteLayerVersion
  ## Deletes a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Deleted versions can no longer be viewed or added to functions. To avoid breaking functions, a copy of the version remains in Lambda until no functions refer to it.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  ##   VersionNumber: int (required)
  ##                : The version number.
  var path_616860 = newJObject()
  add(path_616860, "LayerName", newJString(LayerName))
  add(path_616860, "VersionNumber", newJInt(VersionNumber))
  result = call_616859.call(path_616860, nil, nil, nil, nil)

var deleteLayerVersion* = Call_DeleteLayerVersion_616846(
    name: "deleteLayerVersion", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}",
    validator: validate_DeleteLayerVersion_616847, base: "/",
    url: url_DeleteLayerVersion_616848, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutProvisionedConcurrencyConfig_616877 = ref object of OpenApiRestCall_615866
proc url_PutProvisionedConcurrencyConfig_616879(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-09-30/functions/"),
               (kind: VariableSegment, value: "FunctionName"), (
        kind: ConstantSegment, value: "/provisioned-concurrency#Qualifier")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutProvisionedConcurrencyConfig_616878(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds a provisioned concurrency configuration to a function's alias or version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_616880 = path.getOrDefault("FunctionName")
  valid_616880 = validateParameter(valid_616880, JString, required = true,
                                 default = nil)
  if valid_616880 != nil:
    section.add "FunctionName", valid_616880
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString (required)
  ##            : The version number or alias name.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Qualifier` field"
  var valid_616881 = query.getOrDefault("Qualifier")
  valid_616881 = validateParameter(valid_616881, JString, required = true,
                                 default = nil)
  if valid_616881 != nil:
    section.add "Qualifier", valid_616881
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
  var valid_616882 = header.getOrDefault("X-Amz-Date")
  valid_616882 = validateParameter(valid_616882, JString, required = false,
                                 default = nil)
  if valid_616882 != nil:
    section.add "X-Amz-Date", valid_616882
  var valid_616883 = header.getOrDefault("X-Amz-Security-Token")
  valid_616883 = validateParameter(valid_616883, JString, required = false,
                                 default = nil)
  if valid_616883 != nil:
    section.add "X-Amz-Security-Token", valid_616883
  var valid_616884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616884 = validateParameter(valid_616884, JString, required = false,
                                 default = nil)
  if valid_616884 != nil:
    section.add "X-Amz-Content-Sha256", valid_616884
  var valid_616885 = header.getOrDefault("X-Amz-Algorithm")
  valid_616885 = validateParameter(valid_616885, JString, required = false,
                                 default = nil)
  if valid_616885 != nil:
    section.add "X-Amz-Algorithm", valid_616885
  var valid_616886 = header.getOrDefault("X-Amz-Signature")
  valid_616886 = validateParameter(valid_616886, JString, required = false,
                                 default = nil)
  if valid_616886 != nil:
    section.add "X-Amz-Signature", valid_616886
  var valid_616887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616887 = validateParameter(valid_616887, JString, required = false,
                                 default = nil)
  if valid_616887 != nil:
    section.add "X-Amz-SignedHeaders", valid_616887
  var valid_616888 = header.getOrDefault("X-Amz-Credential")
  valid_616888 = validateParameter(valid_616888, JString, required = false,
                                 default = nil)
  if valid_616888 != nil:
    section.add "X-Amz-Credential", valid_616888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616890: Call_PutProvisionedConcurrencyConfig_616877;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds a provisioned concurrency configuration to a function's alias or version.
  ## 
  let valid = call_616890.validator(path, query, header, formData, body)
  let scheme = call_616890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616890.url(scheme.get, call_616890.host, call_616890.base,
                         call_616890.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616890, url, valid)

proc call*(call_616891: Call_PutProvisionedConcurrencyConfig_616877;
          FunctionName: string; Qualifier: string; body: JsonNode): Recallable =
  ## putProvisionedConcurrencyConfig
  ## Adds a provisioned concurrency configuration to a function's alias or version.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string (required)
  ##            : The version number or alias name.
  ##   body: JObject (required)
  var path_616892 = newJObject()
  var query_616893 = newJObject()
  var body_616894 = newJObject()
  add(path_616892, "FunctionName", newJString(FunctionName))
  add(query_616893, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_616894 = body
  result = call_616891.call(path_616892, query_616893, nil, nil, body_616894)

var putProvisionedConcurrencyConfig* = Call_PutProvisionedConcurrencyConfig_616877(
    name: "putProvisionedConcurrencyConfig", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com", route: "/2019-09-30/functions/{FunctionName}/provisioned-concurrency#Qualifier",
    validator: validate_PutProvisionedConcurrencyConfig_616878, base: "/",
    url: url_PutProvisionedConcurrencyConfig_616879,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProvisionedConcurrencyConfig_616861 = ref object of OpenApiRestCall_615866
proc url_GetProvisionedConcurrencyConfig_616863(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-09-30/functions/"),
               (kind: VariableSegment, value: "FunctionName"), (
        kind: ConstantSegment, value: "/provisioned-concurrency#Qualifier")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetProvisionedConcurrencyConfig_616862(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves the provisioned concurrency configuration for a function's alias or version.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_616864 = path.getOrDefault("FunctionName")
  valid_616864 = validateParameter(valid_616864, JString, required = true,
                                 default = nil)
  if valid_616864 != nil:
    section.add "FunctionName", valid_616864
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString (required)
  ##            : The version number or alias name.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Qualifier` field"
  var valid_616865 = query.getOrDefault("Qualifier")
  valid_616865 = validateParameter(valid_616865, JString, required = true,
                                 default = nil)
  if valid_616865 != nil:
    section.add "Qualifier", valid_616865
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
  var valid_616866 = header.getOrDefault("X-Amz-Date")
  valid_616866 = validateParameter(valid_616866, JString, required = false,
                                 default = nil)
  if valid_616866 != nil:
    section.add "X-Amz-Date", valid_616866
  var valid_616867 = header.getOrDefault("X-Amz-Security-Token")
  valid_616867 = validateParameter(valid_616867, JString, required = false,
                                 default = nil)
  if valid_616867 != nil:
    section.add "X-Amz-Security-Token", valid_616867
  var valid_616868 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616868 = validateParameter(valid_616868, JString, required = false,
                                 default = nil)
  if valid_616868 != nil:
    section.add "X-Amz-Content-Sha256", valid_616868
  var valid_616869 = header.getOrDefault("X-Amz-Algorithm")
  valid_616869 = validateParameter(valid_616869, JString, required = false,
                                 default = nil)
  if valid_616869 != nil:
    section.add "X-Amz-Algorithm", valid_616869
  var valid_616870 = header.getOrDefault("X-Amz-Signature")
  valid_616870 = validateParameter(valid_616870, JString, required = false,
                                 default = nil)
  if valid_616870 != nil:
    section.add "X-Amz-Signature", valid_616870
  var valid_616871 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616871 = validateParameter(valid_616871, JString, required = false,
                                 default = nil)
  if valid_616871 != nil:
    section.add "X-Amz-SignedHeaders", valid_616871
  var valid_616872 = header.getOrDefault("X-Amz-Credential")
  valid_616872 = validateParameter(valid_616872, JString, required = false,
                                 default = nil)
  if valid_616872 != nil:
    section.add "X-Amz-Credential", valid_616872
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_616873: Call_GetProvisionedConcurrencyConfig_616861;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the provisioned concurrency configuration for a function's alias or version.
  ## 
  let valid = call_616873.validator(path, query, header, formData, body)
  let scheme = call_616873.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616873.url(scheme.get, call_616873.host, call_616873.base,
                         call_616873.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616873, url, valid)

proc call*(call_616874: Call_GetProvisionedConcurrencyConfig_616861;
          FunctionName: string; Qualifier: string): Recallable =
  ## getProvisionedConcurrencyConfig
  ## Retrieves the provisioned concurrency configuration for a function's alias or version.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string (required)
  ##            : The version number or alias name.
  var path_616875 = newJObject()
  var query_616876 = newJObject()
  add(path_616875, "FunctionName", newJString(FunctionName))
  add(query_616876, "Qualifier", newJString(Qualifier))
  result = call_616874.call(path_616875, query_616876, nil, nil, nil)

var getProvisionedConcurrencyConfig* = Call_GetProvisionedConcurrencyConfig_616861(
    name: "getProvisionedConcurrencyConfig", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com", route: "/2019-09-30/functions/{FunctionName}/provisioned-concurrency#Qualifier",
    validator: validate_GetProvisionedConcurrencyConfig_616862, base: "/",
    url: url_GetProvisionedConcurrencyConfig_616863,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProvisionedConcurrencyConfig_616895 = ref object of OpenApiRestCall_615866
proc url_DeleteProvisionedConcurrencyConfig_616897(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-09-30/functions/"),
               (kind: VariableSegment, value: "FunctionName"), (
        kind: ConstantSegment, value: "/provisioned-concurrency#Qualifier")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteProvisionedConcurrencyConfig_616896(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the provisioned concurrency configuration for a function.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_616898 = path.getOrDefault("FunctionName")
  valid_616898 = validateParameter(valid_616898, JString, required = true,
                                 default = nil)
  if valid_616898 != nil:
    section.add "FunctionName", valid_616898
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString (required)
  ##            : The version number or alias name.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Qualifier` field"
  var valid_616899 = query.getOrDefault("Qualifier")
  valid_616899 = validateParameter(valid_616899, JString, required = true,
                                 default = nil)
  if valid_616899 != nil:
    section.add "Qualifier", valid_616899
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
  var valid_616900 = header.getOrDefault("X-Amz-Date")
  valid_616900 = validateParameter(valid_616900, JString, required = false,
                                 default = nil)
  if valid_616900 != nil:
    section.add "X-Amz-Date", valid_616900
  var valid_616901 = header.getOrDefault("X-Amz-Security-Token")
  valid_616901 = validateParameter(valid_616901, JString, required = false,
                                 default = nil)
  if valid_616901 != nil:
    section.add "X-Amz-Security-Token", valid_616901
  var valid_616902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616902 = validateParameter(valid_616902, JString, required = false,
                                 default = nil)
  if valid_616902 != nil:
    section.add "X-Amz-Content-Sha256", valid_616902
  var valid_616903 = header.getOrDefault("X-Amz-Algorithm")
  valid_616903 = validateParameter(valid_616903, JString, required = false,
                                 default = nil)
  if valid_616903 != nil:
    section.add "X-Amz-Algorithm", valid_616903
  var valid_616904 = header.getOrDefault("X-Amz-Signature")
  valid_616904 = validateParameter(valid_616904, JString, required = false,
                                 default = nil)
  if valid_616904 != nil:
    section.add "X-Amz-Signature", valid_616904
  var valid_616905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616905 = validateParameter(valid_616905, JString, required = false,
                                 default = nil)
  if valid_616905 != nil:
    section.add "X-Amz-SignedHeaders", valid_616905
  var valid_616906 = header.getOrDefault("X-Amz-Credential")
  valid_616906 = validateParameter(valid_616906, JString, required = false,
                                 default = nil)
  if valid_616906 != nil:
    section.add "X-Amz-Credential", valid_616906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_616907: Call_DeleteProvisionedConcurrencyConfig_616895;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the provisioned concurrency configuration for a function.
  ## 
  let valid = call_616907.validator(path, query, header, formData, body)
  let scheme = call_616907.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616907.url(scheme.get, call_616907.host, call_616907.base,
                         call_616907.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616907, url, valid)

proc call*(call_616908: Call_DeleteProvisionedConcurrencyConfig_616895;
          FunctionName: string; Qualifier: string): Recallable =
  ## deleteProvisionedConcurrencyConfig
  ## Deletes the provisioned concurrency configuration for a function.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string (required)
  ##            : The version number or alias name.
  var path_616909 = newJObject()
  var query_616910 = newJObject()
  add(path_616909, "FunctionName", newJString(FunctionName))
  add(query_616910, "Qualifier", newJString(Qualifier))
  result = call_616908.call(path_616909, query_616910, nil, nil, nil)

var deleteProvisionedConcurrencyConfig* = Call_DeleteProvisionedConcurrencyConfig_616895(
    name: "deleteProvisionedConcurrencyConfig", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com", route: "/2019-09-30/functions/{FunctionName}/provisioned-concurrency#Qualifier",
    validator: validate_DeleteProvisionedConcurrencyConfig_616896, base: "/",
    url: url_DeleteProvisionedConcurrencyConfig_616897,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountSettings_616911 = ref object of OpenApiRestCall_615866
proc url_GetAccountSettings_616913(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAccountSettings_616912(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Retrieves details about your account's <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limits</a> and usage in an AWS Region.
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
  var valid_616914 = header.getOrDefault("X-Amz-Date")
  valid_616914 = validateParameter(valid_616914, JString, required = false,
                                 default = nil)
  if valid_616914 != nil:
    section.add "X-Amz-Date", valid_616914
  var valid_616915 = header.getOrDefault("X-Amz-Security-Token")
  valid_616915 = validateParameter(valid_616915, JString, required = false,
                                 default = nil)
  if valid_616915 != nil:
    section.add "X-Amz-Security-Token", valid_616915
  var valid_616916 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616916 = validateParameter(valid_616916, JString, required = false,
                                 default = nil)
  if valid_616916 != nil:
    section.add "X-Amz-Content-Sha256", valid_616916
  var valid_616917 = header.getOrDefault("X-Amz-Algorithm")
  valid_616917 = validateParameter(valid_616917, JString, required = false,
                                 default = nil)
  if valid_616917 != nil:
    section.add "X-Amz-Algorithm", valid_616917
  var valid_616918 = header.getOrDefault("X-Amz-Signature")
  valid_616918 = validateParameter(valid_616918, JString, required = false,
                                 default = nil)
  if valid_616918 != nil:
    section.add "X-Amz-Signature", valid_616918
  var valid_616919 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616919 = validateParameter(valid_616919, JString, required = false,
                                 default = nil)
  if valid_616919 != nil:
    section.add "X-Amz-SignedHeaders", valid_616919
  var valid_616920 = header.getOrDefault("X-Amz-Credential")
  valid_616920 = validateParameter(valid_616920, JString, required = false,
                                 default = nil)
  if valid_616920 != nil:
    section.add "X-Amz-Credential", valid_616920
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_616921: Call_GetAccountSettings_616911; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details about your account's <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limits</a> and usage in an AWS Region.
  ## 
  let valid = call_616921.validator(path, query, header, formData, body)
  let scheme = call_616921.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616921.url(scheme.get, call_616921.host, call_616921.base,
                         call_616921.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616921, url, valid)

proc call*(call_616922: Call_GetAccountSettings_616911): Recallable =
  ## getAccountSettings
  ## Retrieves details about your account's <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limits</a> and usage in an AWS Region.
  result = call_616922.call(nil, nil, nil, nil, nil)

var getAccountSettings* = Call_GetAccountSettings_616911(
    name: "getAccountSettings", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com", route: "/2016-08-19/account-settings/",
    validator: validate_GetAccountSettings_616912, base: "/",
    url: url_GetAccountSettings_616913, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionConcurrency_616923 = ref object of OpenApiRestCall_615866
proc url_GetFunctionConcurrency_616925(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-09-30/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/concurrency")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFunctionConcurrency_616924(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns details about the reserved concurrency configuration for a function. To set a concurrency limit for a function, use <a>PutFunctionConcurrency</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_616926 = path.getOrDefault("FunctionName")
  valid_616926 = validateParameter(valid_616926, JString, required = true,
                                 default = nil)
  if valid_616926 != nil:
    section.add "FunctionName", valid_616926
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
  var valid_616927 = header.getOrDefault("X-Amz-Date")
  valid_616927 = validateParameter(valid_616927, JString, required = false,
                                 default = nil)
  if valid_616927 != nil:
    section.add "X-Amz-Date", valid_616927
  var valid_616928 = header.getOrDefault("X-Amz-Security-Token")
  valid_616928 = validateParameter(valid_616928, JString, required = false,
                                 default = nil)
  if valid_616928 != nil:
    section.add "X-Amz-Security-Token", valid_616928
  var valid_616929 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616929 = validateParameter(valid_616929, JString, required = false,
                                 default = nil)
  if valid_616929 != nil:
    section.add "X-Amz-Content-Sha256", valid_616929
  var valid_616930 = header.getOrDefault("X-Amz-Algorithm")
  valid_616930 = validateParameter(valid_616930, JString, required = false,
                                 default = nil)
  if valid_616930 != nil:
    section.add "X-Amz-Algorithm", valid_616930
  var valid_616931 = header.getOrDefault("X-Amz-Signature")
  valid_616931 = validateParameter(valid_616931, JString, required = false,
                                 default = nil)
  if valid_616931 != nil:
    section.add "X-Amz-Signature", valid_616931
  var valid_616932 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616932 = validateParameter(valid_616932, JString, required = false,
                                 default = nil)
  if valid_616932 != nil:
    section.add "X-Amz-SignedHeaders", valid_616932
  var valid_616933 = header.getOrDefault("X-Amz-Credential")
  valid_616933 = validateParameter(valid_616933, JString, required = false,
                                 default = nil)
  if valid_616933 != nil:
    section.add "X-Amz-Credential", valid_616933
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_616934: Call_GetFunctionConcurrency_616923; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns details about the reserved concurrency configuration for a function. To set a concurrency limit for a function, use <a>PutFunctionConcurrency</a>.
  ## 
  let valid = call_616934.validator(path, query, header, formData, body)
  let scheme = call_616934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616934.url(scheme.get, call_616934.host, call_616934.base,
                         call_616934.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616934, url, valid)

proc call*(call_616935: Call_GetFunctionConcurrency_616923; FunctionName: string): Recallable =
  ## getFunctionConcurrency
  ## Returns details about the reserved concurrency configuration for a function. To set a concurrency limit for a function, use <a>PutFunctionConcurrency</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  var path_616936 = newJObject()
  add(path_616936, "FunctionName", newJString(FunctionName))
  result = call_616935.call(path_616936, nil, nil, nil, nil)

var getFunctionConcurrency* = Call_GetFunctionConcurrency_616923(
    name: "getFunctionConcurrency", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2019-09-30/functions/{FunctionName}/concurrency",
    validator: validate_GetFunctionConcurrency_616924, base: "/",
    url: url_GetFunctionConcurrency_616925, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionConfiguration_616953 = ref object of OpenApiRestCall_615866
proc url_UpdateFunctionConfiguration_616955(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFunctionConfiguration_616954(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Modify the version-specific settings of a Lambda function.</p> <p>When you update a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute. During this time, you can't modify the function, but you can still invoke it. The <code>LastUpdateStatus</code>, <code>LastUpdateStatusReason</code>, and <code>LastUpdateStatusReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the update is complete and the function is processing events with the new configuration. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Function States</a>.</p> <p>These settings can vary between versions of a function and are locked when you publish a version. You can't modify the configuration of a published version, only the unpublished version.</p> <p>To configure function concurrency, use <a>PutFunctionConcurrency</a>. To grant invoke permissions to an account or AWS service, use <a>AddPermission</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_616956 = path.getOrDefault("FunctionName")
  valid_616956 = validateParameter(valid_616956, JString, required = true,
                                 default = nil)
  if valid_616956 != nil:
    section.add "FunctionName", valid_616956
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
  var valid_616957 = header.getOrDefault("X-Amz-Date")
  valid_616957 = validateParameter(valid_616957, JString, required = false,
                                 default = nil)
  if valid_616957 != nil:
    section.add "X-Amz-Date", valid_616957
  var valid_616958 = header.getOrDefault("X-Amz-Security-Token")
  valid_616958 = validateParameter(valid_616958, JString, required = false,
                                 default = nil)
  if valid_616958 != nil:
    section.add "X-Amz-Security-Token", valid_616958
  var valid_616959 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616959 = validateParameter(valid_616959, JString, required = false,
                                 default = nil)
  if valid_616959 != nil:
    section.add "X-Amz-Content-Sha256", valid_616959
  var valid_616960 = header.getOrDefault("X-Amz-Algorithm")
  valid_616960 = validateParameter(valid_616960, JString, required = false,
                                 default = nil)
  if valid_616960 != nil:
    section.add "X-Amz-Algorithm", valid_616960
  var valid_616961 = header.getOrDefault("X-Amz-Signature")
  valid_616961 = validateParameter(valid_616961, JString, required = false,
                                 default = nil)
  if valid_616961 != nil:
    section.add "X-Amz-Signature", valid_616961
  var valid_616962 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616962 = validateParameter(valid_616962, JString, required = false,
                                 default = nil)
  if valid_616962 != nil:
    section.add "X-Amz-SignedHeaders", valid_616962
  var valid_616963 = header.getOrDefault("X-Amz-Credential")
  valid_616963 = validateParameter(valid_616963, JString, required = false,
                                 default = nil)
  if valid_616963 != nil:
    section.add "X-Amz-Credential", valid_616963
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_616965: Call_UpdateFunctionConfiguration_616953; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modify the version-specific settings of a Lambda function.</p> <p>When you update a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute. During this time, you can't modify the function, but you can still invoke it. The <code>LastUpdateStatus</code>, <code>LastUpdateStatusReason</code>, and <code>LastUpdateStatusReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the update is complete and the function is processing events with the new configuration. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Function States</a>.</p> <p>These settings can vary between versions of a function and are locked when you publish a version. You can't modify the configuration of a published version, only the unpublished version.</p> <p>To configure function concurrency, use <a>PutFunctionConcurrency</a>. To grant invoke permissions to an account or AWS service, use <a>AddPermission</a>.</p>
  ## 
  let valid = call_616965.validator(path, query, header, formData, body)
  let scheme = call_616965.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616965.url(scheme.get, call_616965.host, call_616965.base,
                         call_616965.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616965, url, valid)

proc call*(call_616966: Call_UpdateFunctionConfiguration_616953;
          FunctionName: string; body: JsonNode): Recallable =
  ## updateFunctionConfiguration
  ## <p>Modify the version-specific settings of a Lambda function.</p> <p>When you update a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute. During this time, you can't modify the function, but you can still invoke it. The <code>LastUpdateStatus</code>, <code>LastUpdateStatusReason</code>, and <code>LastUpdateStatusReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the update is complete and the function is processing events with the new configuration. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Function States</a>.</p> <p>These settings can vary between versions of a function and are locked when you publish a version. You can't modify the configuration of a published version, only the unpublished version.</p> <p>To configure function concurrency, use <a>PutFunctionConcurrency</a>. To grant invoke permissions to an account or AWS service, use <a>AddPermission</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_616967 = newJObject()
  var body_616968 = newJObject()
  add(path_616967, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_616968 = body
  result = call_616966.call(path_616967, nil, nil, nil, body_616968)

var updateFunctionConfiguration* = Call_UpdateFunctionConfiguration_616953(
    name: "updateFunctionConfiguration", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/configuration",
    validator: validate_UpdateFunctionConfiguration_616954, base: "/",
    url: url_UpdateFunctionConfiguration_616955,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionConfiguration_616937 = ref object of OpenApiRestCall_615866
proc url_GetFunctionConfiguration_616939(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/configuration")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFunctionConfiguration_616938(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the version-specific settings of a Lambda function or version. The output includes only options that can vary between versions of a function. To modify these settings, use <a>UpdateFunctionConfiguration</a>.</p> <p>To get all of a function's details, including function-level settings, use <a>GetFunction</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_616940 = path.getOrDefault("FunctionName")
  valid_616940 = validateParameter(valid_616940, JString, required = true,
                                 default = nil)
  if valid_616940 != nil:
    section.add "FunctionName", valid_616940
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to get details about a published version of the function.
  section = newJObject()
  var valid_616941 = query.getOrDefault("Qualifier")
  valid_616941 = validateParameter(valid_616941, JString, required = false,
                                 default = nil)
  if valid_616941 != nil:
    section.add "Qualifier", valid_616941
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
  var valid_616942 = header.getOrDefault("X-Amz-Date")
  valid_616942 = validateParameter(valid_616942, JString, required = false,
                                 default = nil)
  if valid_616942 != nil:
    section.add "X-Amz-Date", valid_616942
  var valid_616943 = header.getOrDefault("X-Amz-Security-Token")
  valid_616943 = validateParameter(valid_616943, JString, required = false,
                                 default = nil)
  if valid_616943 != nil:
    section.add "X-Amz-Security-Token", valid_616943
  var valid_616944 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616944 = validateParameter(valid_616944, JString, required = false,
                                 default = nil)
  if valid_616944 != nil:
    section.add "X-Amz-Content-Sha256", valid_616944
  var valid_616945 = header.getOrDefault("X-Amz-Algorithm")
  valid_616945 = validateParameter(valid_616945, JString, required = false,
                                 default = nil)
  if valid_616945 != nil:
    section.add "X-Amz-Algorithm", valid_616945
  var valid_616946 = header.getOrDefault("X-Amz-Signature")
  valid_616946 = validateParameter(valid_616946, JString, required = false,
                                 default = nil)
  if valid_616946 != nil:
    section.add "X-Amz-Signature", valid_616946
  var valid_616947 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616947 = validateParameter(valid_616947, JString, required = false,
                                 default = nil)
  if valid_616947 != nil:
    section.add "X-Amz-SignedHeaders", valid_616947
  var valid_616948 = header.getOrDefault("X-Amz-Credential")
  valid_616948 = validateParameter(valid_616948, JString, required = false,
                                 default = nil)
  if valid_616948 != nil:
    section.add "X-Amz-Credential", valid_616948
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_616949: Call_GetFunctionConfiguration_616937; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the version-specific settings of a Lambda function or version. The output includes only options that can vary between versions of a function. To modify these settings, use <a>UpdateFunctionConfiguration</a>.</p> <p>To get all of a function's details, including function-level settings, use <a>GetFunction</a>.</p>
  ## 
  let valid = call_616949.validator(path, query, header, formData, body)
  let scheme = call_616949.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616949.url(scheme.get, call_616949.host, call_616949.base,
                         call_616949.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616949, url, valid)

proc call*(call_616950: Call_GetFunctionConfiguration_616937; FunctionName: string;
          Qualifier: string = ""): Recallable =
  ## getFunctionConfiguration
  ## <p>Returns the version-specific settings of a Lambda function or version. The output includes only options that can vary between versions of a function. To modify these settings, use <a>UpdateFunctionConfiguration</a>.</p> <p>To get all of a function's details, including function-level settings, use <a>GetFunction</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to get details about a published version of the function.
  var path_616951 = newJObject()
  var query_616952 = newJObject()
  add(path_616951, "FunctionName", newJString(FunctionName))
  add(query_616952, "Qualifier", newJString(Qualifier))
  result = call_616950.call(path_616951, query_616952, nil, nil, nil)

var getFunctionConfiguration* = Call_GetFunctionConfiguration_616937(
    name: "getFunctionConfiguration", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/configuration",
    validator: validate_GetFunctionConfiguration_616938, base: "/",
    url: url_GetFunctionConfiguration_616939, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLayerVersionByArn_616969 = ref object of OpenApiRestCall_615866
proc url_GetLayerVersionByArn_616971(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetLayerVersionByArn_616970(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   find: JString (required)
  ##   Arn: JString (required)
  ##      : The ARN of the layer version.
  section = newJObject()
  var valid_616985 = query.getOrDefault("find")
  valid_616985 = validateParameter(valid_616985, JString, required = true,
                                 default = newJString("LayerVersion"))
  if valid_616985 != nil:
    section.add "find", valid_616985
  var valid_616986 = query.getOrDefault("Arn")
  valid_616986 = validateParameter(valid_616986, JString, required = true,
                                 default = nil)
  if valid_616986 != nil:
    section.add "Arn", valid_616986
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
  var valid_616987 = header.getOrDefault("X-Amz-Date")
  valid_616987 = validateParameter(valid_616987, JString, required = false,
                                 default = nil)
  if valid_616987 != nil:
    section.add "X-Amz-Date", valid_616987
  var valid_616988 = header.getOrDefault("X-Amz-Security-Token")
  valid_616988 = validateParameter(valid_616988, JString, required = false,
                                 default = nil)
  if valid_616988 != nil:
    section.add "X-Amz-Security-Token", valid_616988
  var valid_616989 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_616989 = validateParameter(valid_616989, JString, required = false,
                                 default = nil)
  if valid_616989 != nil:
    section.add "X-Amz-Content-Sha256", valid_616989
  var valid_616990 = header.getOrDefault("X-Amz-Algorithm")
  valid_616990 = validateParameter(valid_616990, JString, required = false,
                                 default = nil)
  if valid_616990 != nil:
    section.add "X-Amz-Algorithm", valid_616990
  var valid_616991 = header.getOrDefault("X-Amz-Signature")
  valid_616991 = validateParameter(valid_616991, JString, required = false,
                                 default = nil)
  if valid_616991 != nil:
    section.add "X-Amz-Signature", valid_616991
  var valid_616992 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_616992 = validateParameter(valid_616992, JString, required = false,
                                 default = nil)
  if valid_616992 != nil:
    section.add "X-Amz-SignedHeaders", valid_616992
  var valid_616993 = header.getOrDefault("X-Amz-Credential")
  valid_616993 = validateParameter(valid_616993, JString, required = false,
                                 default = nil)
  if valid_616993 != nil:
    section.add "X-Amz-Credential", valid_616993
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_616994: Call_GetLayerVersionByArn_616969; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ## 
  let valid = call_616994.validator(path, query, header, formData, body)
  let scheme = call_616994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_616994.url(scheme.get, call_616994.host, call_616994.base,
                         call_616994.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_616994, url, valid)

proc call*(call_616995: Call_GetLayerVersionByArn_616969; Arn: string;
          find: string = "LayerVersion"): Recallable =
  ## getLayerVersionByArn
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ##   find: string (required)
  ##   Arn: string (required)
  ##      : The ARN of the layer version.
  var query_616996 = newJObject()
  add(query_616996, "find", newJString(find))
  add(query_616996, "Arn", newJString(Arn))
  result = call_616995.call(nil, query_616996, nil, nil, nil)

var getLayerVersionByArn* = Call_GetLayerVersionByArn_616969(
    name: "getLayerVersionByArn", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers#find=LayerVersion&Arn",
    validator: validate_GetLayerVersionByArn_616970, base: "/",
    url: url_GetLayerVersionByArn_616971, schemes: {Scheme.Https, Scheme.Http})
type
  Call_Invoke_616997 = ref object of OpenApiRestCall_615866
proc url_Invoke_616999(protocol: Scheme; host: string; base: string; route: string;
                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/invocations")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_Invoke_616998(path: JsonNode; query: JsonNode; header: JsonNode;
                           formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Invokes a Lambda function. You can invoke a function synchronously (and wait for the response), or asynchronously. To invoke a function asynchronously, set <code>InvocationType</code> to <code>Event</code>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-sync.html">synchronous invocation</a>, details about the function response, including errors, are included in the response body and headers. For either invocation type, you can find more information in the <a href="https://docs.aws.amazon.com/lambda/latest/dg/monitoring-functions.html">execution log</a> and <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-x-ray.html">trace</a>.</p> <p>When an error occurs, your function may be invoked multiple times. Retry behavior varies by error type, client, event source, and invocation type. For example, if you invoke a function asynchronously and it returns an error, Lambda executes the function up to two more times. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/retries-on-errors.html">Retry Behavior</a>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a>, Lambda adds events to a queue before sending them to your function. If your function does not have enough capacity to keep up with the queue, events may be lost. Occasionally, your function may receive the same event multiple times, even if no error occurs. To retain events that were not processed, configure your function with a <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#dlq">dead-letter queue</a>.</p> <p>The status code in the API response doesn't reflect function errors. Error codes are reserved for errors that prevent your function from executing, such as permissions errors, <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limit errors</a>, or issues with your function's code and configuration. For example, Lambda returns <code>TooManyRequestsException</code> if executing the function would cause you to exceed a concurrency limit at either the account level (<code>ConcurrentInvocationLimitExceeded</code>) or function level (<code>ReservedFunctionConcurrentInvocationLimitExceeded</code>).</p> <p>For functions with a long timeout, your client might be disconnected during synchronous invocation while it waits for a response. Configure your HTTP client, SDK, firewall, proxy, or operating system to allow for long connections with timeout or keep-alive settings.</p> <p>This operation requires permission for the <code>lambda:InvokeFunction</code> action.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_617000 = path.getOrDefault("FunctionName")
  valid_617000 = validateParameter(valid_617000, JString, required = true,
                                 default = nil)
  if valid_617000 != nil:
    section.add "FunctionName", valid_617000
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to invoke a published version of the function.
  section = newJObject()
  var valid_617001 = query.getOrDefault("Qualifier")
  valid_617001 = validateParameter(valid_617001, JString, required = false,
                                 default = nil)
  if valid_617001 != nil:
    section.add "Qualifier", valid_617001
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Invocation-Type: JString
  ##                        : <p>Choose from the following options.</p> <ul> <li> <p> <code>RequestResponse</code> (default) - Invoke the function synchronously. Keep the connection open until the function returns a response or times out. The API response includes the function response and additional data.</p> </li> <li> <p> <code>Event</code> - Invoke the function asynchronously. Send events that fail multiple times to the function's dead-letter queue (if it's configured). The API response only includes a status code.</p> </li> <li> <p> <code>DryRun</code> - Validate parameter values and verify that the user or role has permission to invoke the function.</p> </li> </ul>
  ##   X-Amz-Client-Context: JString
  ##                       : Up to 3583 bytes of base64-encoded data about the invoking client to pass to the function in the context object.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Log-Type: JString
  ##                 : Set to <code>Tail</code> to include the execution log in the response.
  section = newJObject()
  var valid_617002 = header.getOrDefault("X-Amz-Date")
  valid_617002 = validateParameter(valid_617002, JString, required = false,
                                 default = nil)
  if valid_617002 != nil:
    section.add "X-Amz-Date", valid_617002
  var valid_617003 = header.getOrDefault("X-Amz-Security-Token")
  valid_617003 = validateParameter(valid_617003, JString, required = false,
                                 default = nil)
  if valid_617003 != nil:
    section.add "X-Amz-Security-Token", valid_617003
  var valid_617004 = header.getOrDefault("X-Amz-Invocation-Type")
  valid_617004 = validateParameter(valid_617004, JString, required = false,
                                 default = newJString("Event"))
  if valid_617004 != nil:
    section.add "X-Amz-Invocation-Type", valid_617004
  var valid_617005 = header.getOrDefault("X-Amz-Client-Context")
  valid_617005 = validateParameter(valid_617005, JString, required = false,
                                 default = nil)
  if valid_617005 != nil:
    section.add "X-Amz-Client-Context", valid_617005
  var valid_617006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617006 = validateParameter(valid_617006, JString, required = false,
                                 default = nil)
  if valid_617006 != nil:
    section.add "X-Amz-Content-Sha256", valid_617006
  var valid_617007 = header.getOrDefault("X-Amz-Algorithm")
  valid_617007 = validateParameter(valid_617007, JString, required = false,
                                 default = nil)
  if valid_617007 != nil:
    section.add "X-Amz-Algorithm", valid_617007
  var valid_617008 = header.getOrDefault("X-Amz-Signature")
  valid_617008 = validateParameter(valid_617008, JString, required = false,
                                 default = nil)
  if valid_617008 != nil:
    section.add "X-Amz-Signature", valid_617008
  var valid_617009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617009 = validateParameter(valid_617009, JString, required = false,
                                 default = nil)
  if valid_617009 != nil:
    section.add "X-Amz-SignedHeaders", valid_617009
  var valid_617010 = header.getOrDefault("X-Amz-Credential")
  valid_617010 = validateParameter(valid_617010, JString, required = false,
                                 default = nil)
  if valid_617010 != nil:
    section.add "X-Amz-Credential", valid_617010
  var valid_617011 = header.getOrDefault("X-Amz-Log-Type")
  valid_617011 = validateParameter(valid_617011, JString, required = false,
                                 default = newJString("None"))
  if valid_617011 != nil:
    section.add "X-Amz-Log-Type", valid_617011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617013: Call_Invoke_616997; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Invokes a Lambda function. You can invoke a function synchronously (and wait for the response), or asynchronously. To invoke a function asynchronously, set <code>InvocationType</code> to <code>Event</code>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-sync.html">synchronous invocation</a>, details about the function response, including errors, are included in the response body and headers. For either invocation type, you can find more information in the <a href="https://docs.aws.amazon.com/lambda/latest/dg/monitoring-functions.html">execution log</a> and <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-x-ray.html">trace</a>.</p> <p>When an error occurs, your function may be invoked multiple times. Retry behavior varies by error type, client, event source, and invocation type. For example, if you invoke a function asynchronously and it returns an error, Lambda executes the function up to two more times. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/retries-on-errors.html">Retry Behavior</a>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a>, Lambda adds events to a queue before sending them to your function. If your function does not have enough capacity to keep up with the queue, events may be lost. Occasionally, your function may receive the same event multiple times, even if no error occurs. To retain events that were not processed, configure your function with a <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#dlq">dead-letter queue</a>.</p> <p>The status code in the API response doesn't reflect function errors. Error codes are reserved for errors that prevent your function from executing, such as permissions errors, <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limit errors</a>, or issues with your function's code and configuration. For example, Lambda returns <code>TooManyRequestsException</code> if executing the function would cause you to exceed a concurrency limit at either the account level (<code>ConcurrentInvocationLimitExceeded</code>) or function level (<code>ReservedFunctionConcurrentInvocationLimitExceeded</code>).</p> <p>For functions with a long timeout, your client might be disconnected during synchronous invocation while it waits for a response. Configure your HTTP client, SDK, firewall, proxy, or operating system to allow for long connections with timeout or keep-alive settings.</p> <p>This operation requires permission for the <code>lambda:InvokeFunction</code> action.</p>
  ## 
  let valid = call_617013.validator(path, query, header, formData, body)
  let scheme = call_617013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617013.url(scheme.get, call_617013.host, call_617013.base,
                         call_617013.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617013, url, valid)

proc call*(call_617014: Call_Invoke_616997; FunctionName: string; body: JsonNode;
          Qualifier: string = ""): Recallable =
  ## invoke
  ## <p>Invokes a Lambda function. You can invoke a function synchronously (and wait for the response), or asynchronously. To invoke a function asynchronously, set <code>InvocationType</code> to <code>Event</code>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-sync.html">synchronous invocation</a>, details about the function response, including errors, are included in the response body and headers. For either invocation type, you can find more information in the <a href="https://docs.aws.amazon.com/lambda/latest/dg/monitoring-functions.html">execution log</a> and <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-x-ray.html">trace</a>.</p> <p>When an error occurs, your function may be invoked multiple times. Retry behavior varies by error type, client, event source, and invocation type. For example, if you invoke a function asynchronously and it returns an error, Lambda executes the function up to two more times. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/retries-on-errors.html">Retry Behavior</a>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a>, Lambda adds events to a queue before sending them to your function. If your function does not have enough capacity to keep up with the queue, events may be lost. Occasionally, your function may receive the same event multiple times, even if no error occurs. To retain events that were not processed, configure your function with a <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#dlq">dead-letter queue</a>.</p> <p>The status code in the API response doesn't reflect function errors. Error codes are reserved for errors that prevent your function from executing, such as permissions errors, <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limit errors</a>, or issues with your function's code and configuration. For example, Lambda returns <code>TooManyRequestsException</code> if executing the function would cause you to exceed a concurrency limit at either the account level (<code>ConcurrentInvocationLimitExceeded</code>) or function level (<code>ReservedFunctionConcurrentInvocationLimitExceeded</code>).</p> <p>For functions with a long timeout, your client might be disconnected during synchronous invocation while it waits for a response. Configure your HTTP client, SDK, firewall, proxy, or operating system to allow for long connections with timeout or keep-alive settings.</p> <p>This operation requires permission for the <code>lambda:InvokeFunction</code> action.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to invoke a published version of the function.
  ##   body: JObject (required)
  var path_617015 = newJObject()
  var query_617016 = newJObject()
  var body_617017 = newJObject()
  add(path_617015, "FunctionName", newJString(FunctionName))
  add(query_617016, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_617017 = body
  result = call_617014.call(path_617015, query_617016, nil, nil, body_617017)

var invoke* = Call_Invoke_616997(name: "invoke", meth: HttpMethod.HttpPost,
                              host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/invocations",
                              validator: validate_Invoke_616998, base: "/",
                              url: url_Invoke_616999,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_InvokeAsync_617018 = ref object of OpenApiRestCall_615866
proc url_InvokeAsync_617020(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2014-11-13/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/invoke-async/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_InvokeAsync_617019(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <important> <p>For asynchronous function invocation, use <a>Invoke</a>.</p> </important> <p>Invokes a function asynchronously.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_617021 = path.getOrDefault("FunctionName")
  valid_617021 = validateParameter(valid_617021, JString, required = true,
                                 default = nil)
  if valid_617021 != nil:
    section.add "FunctionName", valid_617021
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
  var valid_617022 = header.getOrDefault("X-Amz-Date")
  valid_617022 = validateParameter(valid_617022, JString, required = false,
                                 default = nil)
  if valid_617022 != nil:
    section.add "X-Amz-Date", valid_617022
  var valid_617023 = header.getOrDefault("X-Amz-Security-Token")
  valid_617023 = validateParameter(valid_617023, JString, required = false,
                                 default = nil)
  if valid_617023 != nil:
    section.add "X-Amz-Security-Token", valid_617023
  var valid_617024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617024 = validateParameter(valid_617024, JString, required = false,
                                 default = nil)
  if valid_617024 != nil:
    section.add "X-Amz-Content-Sha256", valid_617024
  var valid_617025 = header.getOrDefault("X-Amz-Algorithm")
  valid_617025 = validateParameter(valid_617025, JString, required = false,
                                 default = nil)
  if valid_617025 != nil:
    section.add "X-Amz-Algorithm", valid_617025
  var valid_617026 = header.getOrDefault("X-Amz-Signature")
  valid_617026 = validateParameter(valid_617026, JString, required = false,
                                 default = nil)
  if valid_617026 != nil:
    section.add "X-Amz-Signature", valid_617026
  var valid_617027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617027 = validateParameter(valid_617027, JString, required = false,
                                 default = nil)
  if valid_617027 != nil:
    section.add "X-Amz-SignedHeaders", valid_617027
  var valid_617028 = header.getOrDefault("X-Amz-Credential")
  valid_617028 = validateParameter(valid_617028, JString, required = false,
                                 default = nil)
  if valid_617028 != nil:
    section.add "X-Amz-Credential", valid_617028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617030: Call_InvokeAsync_617018; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <important> <p>For asynchronous function invocation, use <a>Invoke</a>.</p> </important> <p>Invokes a function asynchronously.</p>
  ## 
  let valid = call_617030.validator(path, query, header, formData, body)
  let scheme = call_617030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617030.url(scheme.get, call_617030.host, call_617030.base,
                         call_617030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617030, url, valid)

proc call*(call_617031: Call_InvokeAsync_617018; FunctionName: string; body: JsonNode): Recallable =
  ## invokeAsync
  ## <important> <p>For asynchronous function invocation, use <a>Invoke</a>.</p> </important> <p>Invokes a function asynchronously.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_617032 = newJObject()
  var body_617033 = newJObject()
  add(path_617032, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_617033 = body
  result = call_617031.call(path_617032, nil, nil, nil, body_617033)

var invokeAsync* = Call_InvokeAsync_617018(name: "invokeAsync",
                                        meth: HttpMethod.HttpPost,
                                        host: "lambda.amazonaws.com", route: "/2014-11-13/functions/{FunctionName}/invoke-async/",
                                        validator: validate_InvokeAsync_617019,
                                        base: "/", url: url_InvokeAsync_617020,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctionEventInvokeConfigs_617034 = ref object of OpenApiRestCall_615866
proc url_ListFunctionEventInvokeConfigs_617036(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-09-25/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/event-invoke-config/list")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListFunctionEventInvokeConfigs_617035(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Retrieves a list of configurations for asynchronous invocation for a function.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_617037 = path.getOrDefault("FunctionName")
  valid_617037 = validateParameter(valid_617037, JString, required = true,
                                 default = nil)
  if valid_617037 != nil:
    section.add "FunctionName", valid_617037
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: JInt
  ##           : The maximum number of configurations to return.
  section = newJObject()
  var valid_617038 = query.getOrDefault("Marker")
  valid_617038 = validateParameter(valid_617038, JString, required = false,
                                 default = nil)
  if valid_617038 != nil:
    section.add "Marker", valid_617038
  var valid_617039 = query.getOrDefault("MaxItems")
  valid_617039 = validateParameter(valid_617039, JInt, required = false, default = nil)
  if valid_617039 != nil:
    section.add "MaxItems", valid_617039
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
  var valid_617040 = header.getOrDefault("X-Amz-Date")
  valid_617040 = validateParameter(valid_617040, JString, required = false,
                                 default = nil)
  if valid_617040 != nil:
    section.add "X-Amz-Date", valid_617040
  var valid_617041 = header.getOrDefault("X-Amz-Security-Token")
  valid_617041 = validateParameter(valid_617041, JString, required = false,
                                 default = nil)
  if valid_617041 != nil:
    section.add "X-Amz-Security-Token", valid_617041
  var valid_617042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617042 = validateParameter(valid_617042, JString, required = false,
                                 default = nil)
  if valid_617042 != nil:
    section.add "X-Amz-Content-Sha256", valid_617042
  var valid_617043 = header.getOrDefault("X-Amz-Algorithm")
  valid_617043 = validateParameter(valid_617043, JString, required = false,
                                 default = nil)
  if valid_617043 != nil:
    section.add "X-Amz-Algorithm", valid_617043
  var valid_617044 = header.getOrDefault("X-Amz-Signature")
  valid_617044 = validateParameter(valid_617044, JString, required = false,
                                 default = nil)
  if valid_617044 != nil:
    section.add "X-Amz-Signature", valid_617044
  var valid_617045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617045 = validateParameter(valid_617045, JString, required = false,
                                 default = nil)
  if valid_617045 != nil:
    section.add "X-Amz-SignedHeaders", valid_617045
  var valid_617046 = header.getOrDefault("X-Amz-Credential")
  valid_617046 = validateParameter(valid_617046, JString, required = false,
                                 default = nil)
  if valid_617046 != nil:
    section.add "X-Amz-Credential", valid_617046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617047: Call_ListFunctionEventInvokeConfigs_617034; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list of configurations for asynchronous invocation for a function.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  let valid = call_617047.validator(path, query, header, formData, body)
  let scheme = call_617047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617047.url(scheme.get, call_617047.host, call_617047.base,
                         call_617047.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617047, url, valid)

proc call*(call_617048: Call_ListFunctionEventInvokeConfigs_617034;
          FunctionName: string; Marker: string = ""; MaxItems: int = 0): Recallable =
  ## listFunctionEventInvokeConfigs
  ## <p>Retrieves a list of configurations for asynchronous invocation for a function.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Marker: string
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: int
  ##           : The maximum number of configurations to return.
  var path_617049 = newJObject()
  var query_617050 = newJObject()
  add(path_617049, "FunctionName", newJString(FunctionName))
  add(query_617050, "Marker", newJString(Marker))
  add(query_617050, "MaxItems", newJInt(MaxItems))
  result = call_617048.call(path_617049, query_617050, nil, nil, nil)

var listFunctionEventInvokeConfigs* = Call_ListFunctionEventInvokeConfigs_617034(
    name: "listFunctionEventInvokeConfigs", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config/list",
    validator: validate_ListFunctionEventInvokeConfigs_617035, base: "/",
    url: url_ListFunctionEventInvokeConfigs_617036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctions_617051 = ref object of OpenApiRestCall_615866
proc url_ListFunctions_617053(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFunctions_617052(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of Lambda functions, with the version-specific configuration of each. Lambda returns up to 50 functions per call.</p> <p>Set <code>FunctionVersion</code> to <code>ALL</code> to include all published versions of each function in addition to the unpublished version. To get more information about a function or version, use <a>GetFunction</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   FunctionVersion: JString
  ##                  : Set to <code>ALL</code> to include entries for all published versions of each function.
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MasterRegion: JString
  ##               : For Lambda@Edge functions, the AWS Region of the master function. For example, <code>us-east-1</code> filters the list of functions to only include Lambda@Edge functions replicated from a master function in US East (N. Virginia). If specified, you must set <code>FunctionVersion</code> to <code>ALL</code>.
  ##   MaxItems: JInt
  ##           : The maximum number of functions to return.
  section = newJObject()
  var valid_617054 = query.getOrDefault("FunctionVersion")
  valid_617054 = validateParameter(valid_617054, JString, required = false,
                                 default = newJString("ALL"))
  if valid_617054 != nil:
    section.add "FunctionVersion", valid_617054
  var valid_617055 = query.getOrDefault("Marker")
  valid_617055 = validateParameter(valid_617055, JString, required = false,
                                 default = nil)
  if valid_617055 != nil:
    section.add "Marker", valid_617055
  var valid_617056 = query.getOrDefault("MasterRegion")
  valid_617056 = validateParameter(valid_617056, JString, required = false,
                                 default = nil)
  if valid_617056 != nil:
    section.add "MasterRegion", valid_617056
  var valid_617057 = query.getOrDefault("MaxItems")
  valid_617057 = validateParameter(valid_617057, JInt, required = false, default = nil)
  if valid_617057 != nil:
    section.add "MaxItems", valid_617057
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
  var valid_617058 = header.getOrDefault("X-Amz-Date")
  valid_617058 = validateParameter(valid_617058, JString, required = false,
                                 default = nil)
  if valid_617058 != nil:
    section.add "X-Amz-Date", valid_617058
  var valid_617059 = header.getOrDefault("X-Amz-Security-Token")
  valid_617059 = validateParameter(valid_617059, JString, required = false,
                                 default = nil)
  if valid_617059 != nil:
    section.add "X-Amz-Security-Token", valid_617059
  var valid_617060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617060 = validateParameter(valid_617060, JString, required = false,
                                 default = nil)
  if valid_617060 != nil:
    section.add "X-Amz-Content-Sha256", valid_617060
  var valid_617061 = header.getOrDefault("X-Amz-Algorithm")
  valid_617061 = validateParameter(valid_617061, JString, required = false,
                                 default = nil)
  if valid_617061 != nil:
    section.add "X-Amz-Algorithm", valid_617061
  var valid_617062 = header.getOrDefault("X-Amz-Signature")
  valid_617062 = validateParameter(valid_617062, JString, required = false,
                                 default = nil)
  if valid_617062 != nil:
    section.add "X-Amz-Signature", valid_617062
  var valid_617063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617063 = validateParameter(valid_617063, JString, required = false,
                                 default = nil)
  if valid_617063 != nil:
    section.add "X-Amz-SignedHeaders", valid_617063
  var valid_617064 = header.getOrDefault("X-Amz-Credential")
  valid_617064 = validateParameter(valid_617064, JString, required = false,
                                 default = nil)
  if valid_617064 != nil:
    section.add "X-Amz-Credential", valid_617064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617065: Call_ListFunctions_617051; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of Lambda functions, with the version-specific configuration of each. Lambda returns up to 50 functions per call.</p> <p>Set <code>FunctionVersion</code> to <code>ALL</code> to include all published versions of each function in addition to the unpublished version. To get more information about a function or version, use <a>GetFunction</a>.</p>
  ## 
  let valid = call_617065.validator(path, query, header, formData, body)
  let scheme = call_617065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617065.url(scheme.get, call_617065.host, call_617065.base,
                         call_617065.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617065, url, valid)

proc call*(call_617066: Call_ListFunctions_617051; FunctionVersion: string = "ALL";
          Marker: string = ""; MasterRegion: string = ""; MaxItems: int = 0): Recallable =
  ## listFunctions
  ## <p>Returns a list of Lambda functions, with the version-specific configuration of each. Lambda returns up to 50 functions per call.</p> <p>Set <code>FunctionVersion</code> to <code>ALL</code> to include all published versions of each function in addition to the unpublished version. To get more information about a function or version, use <a>GetFunction</a>.</p>
  ##   FunctionVersion: string
  ##                  : Set to <code>ALL</code> to include entries for all published versions of each function.
  ##   Marker: string
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MasterRegion: string
  ##               : For Lambda@Edge functions, the AWS Region of the master function. For example, <code>us-east-1</code> filters the list of functions to only include Lambda@Edge functions replicated from a master function in US East (N. Virginia). If specified, you must set <code>FunctionVersion</code> to <code>ALL</code>.
  ##   MaxItems: int
  ##           : The maximum number of functions to return.
  var query_617067 = newJObject()
  add(query_617067, "FunctionVersion", newJString(FunctionVersion))
  add(query_617067, "Marker", newJString(Marker))
  add(query_617067, "MasterRegion", newJString(MasterRegion))
  add(query_617067, "MaxItems", newJInt(MaxItems))
  result = call_617066.call(nil, query_617067, nil, nil, nil)

var listFunctions* = Call_ListFunctions_617051(name: "listFunctions",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/", validator: validate_ListFunctions_617052,
    base: "/", url: url_ListFunctions_617053, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PublishLayerVersion_617086 = ref object of OpenApiRestCall_615866
proc url_PublishLayerVersion_617088(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LayerName" in path, "`LayerName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-10-31/layers/"),
               (kind: VariableSegment, value: "LayerName"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PublishLayerVersion_617087(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a> from a ZIP archive. Each time you call <code>PublishLayerVersion</code> with the same layer name, a new version is created.</p> <p>Add layers to your function with <a>CreateFunction</a> or <a>UpdateFunctionConfiguration</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   LayerName: JString (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `LayerName` field"
  var valid_617089 = path.getOrDefault("LayerName")
  valid_617089 = validateParameter(valid_617089, JString, required = true,
                                 default = nil)
  if valid_617089 != nil:
    section.add "LayerName", valid_617089
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
  var valid_617090 = header.getOrDefault("X-Amz-Date")
  valid_617090 = validateParameter(valid_617090, JString, required = false,
                                 default = nil)
  if valid_617090 != nil:
    section.add "X-Amz-Date", valid_617090
  var valid_617091 = header.getOrDefault("X-Amz-Security-Token")
  valid_617091 = validateParameter(valid_617091, JString, required = false,
                                 default = nil)
  if valid_617091 != nil:
    section.add "X-Amz-Security-Token", valid_617091
  var valid_617092 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617092 = validateParameter(valid_617092, JString, required = false,
                                 default = nil)
  if valid_617092 != nil:
    section.add "X-Amz-Content-Sha256", valid_617092
  var valid_617093 = header.getOrDefault("X-Amz-Algorithm")
  valid_617093 = validateParameter(valid_617093, JString, required = false,
                                 default = nil)
  if valid_617093 != nil:
    section.add "X-Amz-Algorithm", valid_617093
  var valid_617094 = header.getOrDefault("X-Amz-Signature")
  valid_617094 = validateParameter(valid_617094, JString, required = false,
                                 default = nil)
  if valid_617094 != nil:
    section.add "X-Amz-Signature", valid_617094
  var valid_617095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617095 = validateParameter(valid_617095, JString, required = false,
                                 default = nil)
  if valid_617095 != nil:
    section.add "X-Amz-SignedHeaders", valid_617095
  var valid_617096 = header.getOrDefault("X-Amz-Credential")
  valid_617096 = validateParameter(valid_617096, JString, required = false,
                                 default = nil)
  if valid_617096 != nil:
    section.add "X-Amz-Credential", valid_617096
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617098: Call_PublishLayerVersion_617086; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a> from a ZIP archive. Each time you call <code>PublishLayerVersion</code> with the same layer name, a new version is created.</p> <p>Add layers to your function with <a>CreateFunction</a> or <a>UpdateFunctionConfiguration</a>.</p>
  ## 
  let valid = call_617098.validator(path, query, header, formData, body)
  let scheme = call_617098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617098.url(scheme.get, call_617098.host, call_617098.base,
                         call_617098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617098, url, valid)

proc call*(call_617099: Call_PublishLayerVersion_617086; LayerName: string;
          body: JsonNode): Recallable =
  ## publishLayerVersion
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a> from a ZIP archive. Each time you call <code>PublishLayerVersion</code> with the same layer name, a new version is created.</p> <p>Add layers to your function with <a>CreateFunction</a> or <a>UpdateFunctionConfiguration</a>.</p>
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  ##   body: JObject (required)
  var path_617100 = newJObject()
  var body_617101 = newJObject()
  add(path_617100, "LayerName", newJString(LayerName))
  if body != nil:
    body_617101 = body
  result = call_617099.call(path_617100, nil, nil, nil, body_617101)

var publishLayerVersion* = Call_PublishLayerVersion_617086(
    name: "publishLayerVersion", meth: HttpMethod.HttpPost,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions",
    validator: validate_PublishLayerVersion_617087, base: "/",
    url: url_PublishLayerVersion_617088, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLayerVersions_617068 = ref object of OpenApiRestCall_615866
proc url_ListLayerVersions_617070(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LayerName" in path, "`LayerName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-10-31/layers/"),
               (kind: VariableSegment, value: "LayerName"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListLayerVersions_617069(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Lists the versions of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Versions that have been deleted aren't listed. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only versions that indicate that they're compatible with that runtime.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   LayerName: JString (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `LayerName` field"
  var valid_617071 = path.getOrDefault("LayerName")
  valid_617071 = validateParameter(valid_617071, JString, required = true,
                                 default = nil)
  if valid_617071 != nil:
    section.add "LayerName", valid_617071
  result.add "path", section
  ## parameters in `query` object:
  ##   CompatibleRuntime: JString
  ##                    : A runtime identifier. For example, <code>go1.x</code>.
  ##   Marker: JString
  ##         : A pagination token returned by a previous call.
  ##   MaxItems: JInt
  ##           : The maximum number of versions to return.
  section = newJObject()
  var valid_617072 = query.getOrDefault("CompatibleRuntime")
  valid_617072 = validateParameter(valid_617072, JString, required = false,
                                 default = newJString("nodejs"))
  if valid_617072 != nil:
    section.add "CompatibleRuntime", valid_617072
  var valid_617073 = query.getOrDefault("Marker")
  valid_617073 = validateParameter(valid_617073, JString, required = false,
                                 default = nil)
  if valid_617073 != nil:
    section.add "Marker", valid_617073
  var valid_617074 = query.getOrDefault("MaxItems")
  valid_617074 = validateParameter(valid_617074, JInt, required = false, default = nil)
  if valid_617074 != nil:
    section.add "MaxItems", valid_617074
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
  var valid_617075 = header.getOrDefault("X-Amz-Date")
  valid_617075 = validateParameter(valid_617075, JString, required = false,
                                 default = nil)
  if valid_617075 != nil:
    section.add "X-Amz-Date", valid_617075
  var valid_617076 = header.getOrDefault("X-Amz-Security-Token")
  valid_617076 = validateParameter(valid_617076, JString, required = false,
                                 default = nil)
  if valid_617076 != nil:
    section.add "X-Amz-Security-Token", valid_617076
  var valid_617077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617077 = validateParameter(valid_617077, JString, required = false,
                                 default = nil)
  if valid_617077 != nil:
    section.add "X-Amz-Content-Sha256", valid_617077
  var valid_617078 = header.getOrDefault("X-Amz-Algorithm")
  valid_617078 = validateParameter(valid_617078, JString, required = false,
                                 default = nil)
  if valid_617078 != nil:
    section.add "X-Amz-Algorithm", valid_617078
  var valid_617079 = header.getOrDefault("X-Amz-Signature")
  valid_617079 = validateParameter(valid_617079, JString, required = false,
                                 default = nil)
  if valid_617079 != nil:
    section.add "X-Amz-Signature", valid_617079
  var valid_617080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617080 = validateParameter(valid_617080, JString, required = false,
                                 default = nil)
  if valid_617080 != nil:
    section.add "X-Amz-SignedHeaders", valid_617080
  var valid_617081 = header.getOrDefault("X-Amz-Credential")
  valid_617081 = validateParameter(valid_617081, JString, required = false,
                                 default = nil)
  if valid_617081 != nil:
    section.add "X-Amz-Credential", valid_617081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617082: Call_ListLayerVersions_617068; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Versions that have been deleted aren't listed. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only versions that indicate that they're compatible with that runtime.
  ## 
  let valid = call_617082.validator(path, query, header, formData, body)
  let scheme = call_617082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617082.url(scheme.get, call_617082.host, call_617082.base,
                         call_617082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617082, url, valid)

proc call*(call_617083: Call_ListLayerVersions_617068; LayerName: string;
          CompatibleRuntime: string = "nodejs"; Marker: string = ""; MaxItems: int = 0): Recallable =
  ## listLayerVersions
  ## Lists the versions of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Versions that have been deleted aren't listed. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only versions that indicate that they're compatible with that runtime.
  ##   CompatibleRuntime: string
  ##                    : A runtime identifier. For example, <code>go1.x</code>.
  ##   Marker: string
  ##         : A pagination token returned by a previous call.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  ##   MaxItems: int
  ##           : The maximum number of versions to return.
  var path_617084 = newJObject()
  var query_617085 = newJObject()
  add(query_617085, "CompatibleRuntime", newJString(CompatibleRuntime))
  add(query_617085, "Marker", newJString(Marker))
  add(path_617084, "LayerName", newJString(LayerName))
  add(query_617085, "MaxItems", newJInt(MaxItems))
  result = call_617083.call(path_617084, query_617085, nil, nil, nil)

var listLayerVersions* = Call_ListLayerVersions_617068(name: "listLayerVersions",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions",
    validator: validate_ListLayerVersions_617069, base: "/",
    url: url_ListLayerVersions_617070, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLayers_617102 = ref object of OpenApiRestCall_615866
proc url_ListLayers_617104(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLayers_617103(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layers</a> and shows information about the latest version of each. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only layers that indicate that they're compatible with that runtime.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   CompatibleRuntime: JString
  ##                    : A runtime identifier. For example, <code>go1.x</code>.
  ##   Marker: JString
  ##         : A pagination token returned by a previous call.
  ##   MaxItems: JInt
  ##           : The maximum number of layers to return.
  section = newJObject()
  var valid_617105 = query.getOrDefault("CompatibleRuntime")
  valid_617105 = validateParameter(valid_617105, JString, required = false,
                                 default = newJString("nodejs"))
  if valid_617105 != nil:
    section.add "CompatibleRuntime", valid_617105
  var valid_617106 = query.getOrDefault("Marker")
  valid_617106 = validateParameter(valid_617106, JString, required = false,
                                 default = nil)
  if valid_617106 != nil:
    section.add "Marker", valid_617106
  var valid_617107 = query.getOrDefault("MaxItems")
  valid_617107 = validateParameter(valid_617107, JInt, required = false, default = nil)
  if valid_617107 != nil:
    section.add "MaxItems", valid_617107
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
  var valid_617108 = header.getOrDefault("X-Amz-Date")
  valid_617108 = validateParameter(valid_617108, JString, required = false,
                                 default = nil)
  if valid_617108 != nil:
    section.add "X-Amz-Date", valid_617108
  var valid_617109 = header.getOrDefault("X-Amz-Security-Token")
  valid_617109 = validateParameter(valid_617109, JString, required = false,
                                 default = nil)
  if valid_617109 != nil:
    section.add "X-Amz-Security-Token", valid_617109
  var valid_617110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617110 = validateParameter(valid_617110, JString, required = false,
                                 default = nil)
  if valid_617110 != nil:
    section.add "X-Amz-Content-Sha256", valid_617110
  var valid_617111 = header.getOrDefault("X-Amz-Algorithm")
  valid_617111 = validateParameter(valid_617111, JString, required = false,
                                 default = nil)
  if valid_617111 != nil:
    section.add "X-Amz-Algorithm", valid_617111
  var valid_617112 = header.getOrDefault("X-Amz-Signature")
  valid_617112 = validateParameter(valid_617112, JString, required = false,
                                 default = nil)
  if valid_617112 != nil:
    section.add "X-Amz-Signature", valid_617112
  var valid_617113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617113 = validateParameter(valid_617113, JString, required = false,
                                 default = nil)
  if valid_617113 != nil:
    section.add "X-Amz-SignedHeaders", valid_617113
  var valid_617114 = header.getOrDefault("X-Amz-Credential")
  valid_617114 = validateParameter(valid_617114, JString, required = false,
                                 default = nil)
  if valid_617114 != nil:
    section.add "X-Amz-Credential", valid_617114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617115: Call_ListLayers_617102; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layers</a> and shows information about the latest version of each. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only layers that indicate that they're compatible with that runtime.
  ## 
  let valid = call_617115.validator(path, query, header, formData, body)
  let scheme = call_617115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617115.url(scheme.get, call_617115.host, call_617115.base,
                         call_617115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617115, url, valid)

proc call*(call_617116: Call_ListLayers_617102;
          CompatibleRuntime: string = "nodejs"; Marker: string = ""; MaxItems: int = 0): Recallable =
  ## listLayers
  ## Lists <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layers</a> and shows information about the latest version of each. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only layers that indicate that they're compatible with that runtime.
  ##   CompatibleRuntime: string
  ##                    : A runtime identifier. For example, <code>go1.x</code>.
  ##   Marker: string
  ##         : A pagination token returned by a previous call.
  ##   MaxItems: int
  ##           : The maximum number of layers to return.
  var query_617117 = newJObject()
  add(query_617117, "CompatibleRuntime", newJString(CompatibleRuntime))
  add(query_617117, "Marker", newJString(Marker))
  add(query_617117, "MaxItems", newJInt(MaxItems))
  result = call_617116.call(nil, query_617117, nil, nil, nil)

var listLayers* = Call_ListLayers_617102(name: "listLayers",
                                      meth: HttpMethod.HttpGet,
                                      host: "lambda.amazonaws.com",
                                      route: "/2018-10-31/layers",
                                      validator: validate_ListLayers_617103,
                                      base: "/", url: url_ListLayers_617104,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisionedConcurrencyConfigs_617118 = ref object of OpenApiRestCall_615866
proc url_ListProvisionedConcurrencyConfigs_617120(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2019-09-30/functions/"),
               (kind: VariableSegment, value: "FunctionName"), (
        kind: ConstantSegment, value: "/provisioned-concurrency#List=ALL")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListProvisionedConcurrencyConfigs_617119(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a list of provisioned concurrency configurations for a function.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_617121 = path.getOrDefault("FunctionName")
  valid_617121 = validateParameter(valid_617121, JString, required = true,
                                 default = nil)
  if valid_617121 != nil:
    section.add "FunctionName", valid_617121
  result.add "path", section
  ## parameters in `query` object:
  ##   List: JString (required)
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: JInt
  ##           : Specify a number to limit the number of configurations returned.
  section = newJObject()
  var valid_617122 = query.getOrDefault("List")
  valid_617122 = validateParameter(valid_617122, JString, required = true,
                                 default = newJString("ALL"))
  if valid_617122 != nil:
    section.add "List", valid_617122
  var valid_617123 = query.getOrDefault("Marker")
  valid_617123 = validateParameter(valid_617123, JString, required = false,
                                 default = nil)
  if valid_617123 != nil:
    section.add "Marker", valid_617123
  var valid_617124 = query.getOrDefault("MaxItems")
  valid_617124 = validateParameter(valid_617124, JInt, required = false, default = nil)
  if valid_617124 != nil:
    section.add "MaxItems", valid_617124
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
  var valid_617125 = header.getOrDefault("X-Amz-Date")
  valid_617125 = validateParameter(valid_617125, JString, required = false,
                                 default = nil)
  if valid_617125 != nil:
    section.add "X-Amz-Date", valid_617125
  var valid_617126 = header.getOrDefault("X-Amz-Security-Token")
  valid_617126 = validateParameter(valid_617126, JString, required = false,
                                 default = nil)
  if valid_617126 != nil:
    section.add "X-Amz-Security-Token", valid_617126
  var valid_617127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617127 = validateParameter(valid_617127, JString, required = false,
                                 default = nil)
  if valid_617127 != nil:
    section.add "X-Amz-Content-Sha256", valid_617127
  var valid_617128 = header.getOrDefault("X-Amz-Algorithm")
  valid_617128 = validateParameter(valid_617128, JString, required = false,
                                 default = nil)
  if valid_617128 != nil:
    section.add "X-Amz-Algorithm", valid_617128
  var valid_617129 = header.getOrDefault("X-Amz-Signature")
  valid_617129 = validateParameter(valid_617129, JString, required = false,
                                 default = nil)
  if valid_617129 != nil:
    section.add "X-Amz-Signature", valid_617129
  var valid_617130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617130 = validateParameter(valid_617130, JString, required = false,
                                 default = nil)
  if valid_617130 != nil:
    section.add "X-Amz-SignedHeaders", valid_617130
  var valid_617131 = header.getOrDefault("X-Amz-Credential")
  valid_617131 = validateParameter(valid_617131, JString, required = false,
                                 default = nil)
  if valid_617131 != nil:
    section.add "X-Amz-Credential", valid_617131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617132: Call_ListProvisionedConcurrencyConfigs_617118;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves a list of provisioned concurrency configurations for a function.
  ## 
  let valid = call_617132.validator(path, query, header, formData, body)
  let scheme = call_617132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617132.url(scheme.get, call_617132.host, call_617132.base,
                         call_617132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617132, url, valid)

proc call*(call_617133: Call_ListProvisionedConcurrencyConfigs_617118;
          FunctionName: string; List: string = "ALL"; Marker: string = "";
          MaxItems: int = 0): Recallable =
  ## listProvisionedConcurrencyConfigs
  ## Retrieves a list of provisioned concurrency configurations for a function.
  ##   List: string (required)
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Marker: string
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: int
  ##           : Specify a number to limit the number of configurations returned.
  var path_617134 = newJObject()
  var query_617135 = newJObject()
  add(query_617135, "List", newJString(List))
  add(path_617134, "FunctionName", newJString(FunctionName))
  add(query_617135, "Marker", newJString(Marker))
  add(query_617135, "MaxItems", newJInt(MaxItems))
  result = call_617133.call(path_617134, query_617135, nil, nil, nil)

var listProvisionedConcurrencyConfigs* = Call_ListProvisionedConcurrencyConfigs_617118(
    name: "listProvisionedConcurrencyConfigs", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com", route: "/2019-09-30/functions/{FunctionName}/provisioned-concurrency#List=ALL",
    validator: validate_ListProvisionedConcurrencyConfigs_617119, base: "/",
    url: url_ListProvisionedConcurrencyConfigs_617120,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_617150 = ref object of OpenApiRestCall_615866
proc url_TagResource_617152(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ARN" in path, "`ARN` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-03-31/tags/"),
               (kind: VariableSegment, value: "ARN")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_617151(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> to a function.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ARN: JString (required)
  ##      : The function's Amazon Resource Name (ARN).
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ARN` field"
  var valid_617153 = path.getOrDefault("ARN")
  valid_617153 = validateParameter(valid_617153, JString, required = true,
                                 default = nil)
  if valid_617153 != nil:
    section.add "ARN", valid_617153
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
  var valid_617154 = header.getOrDefault("X-Amz-Date")
  valid_617154 = validateParameter(valid_617154, JString, required = false,
                                 default = nil)
  if valid_617154 != nil:
    section.add "X-Amz-Date", valid_617154
  var valid_617155 = header.getOrDefault("X-Amz-Security-Token")
  valid_617155 = validateParameter(valid_617155, JString, required = false,
                                 default = nil)
  if valid_617155 != nil:
    section.add "X-Amz-Security-Token", valid_617155
  var valid_617156 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617156 = validateParameter(valid_617156, JString, required = false,
                                 default = nil)
  if valid_617156 != nil:
    section.add "X-Amz-Content-Sha256", valid_617156
  var valid_617157 = header.getOrDefault("X-Amz-Algorithm")
  valid_617157 = validateParameter(valid_617157, JString, required = false,
                                 default = nil)
  if valid_617157 != nil:
    section.add "X-Amz-Algorithm", valid_617157
  var valid_617158 = header.getOrDefault("X-Amz-Signature")
  valid_617158 = validateParameter(valid_617158, JString, required = false,
                                 default = nil)
  if valid_617158 != nil:
    section.add "X-Amz-Signature", valid_617158
  var valid_617159 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617159 = validateParameter(valid_617159, JString, required = false,
                                 default = nil)
  if valid_617159 != nil:
    section.add "X-Amz-SignedHeaders", valid_617159
  var valid_617160 = header.getOrDefault("X-Amz-Credential")
  valid_617160 = validateParameter(valid_617160, JString, required = false,
                                 default = nil)
  if valid_617160 != nil:
    section.add "X-Amz-Credential", valid_617160
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617162: Call_TagResource_617150; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> to a function.
  ## 
  let valid = call_617162.validator(path, query, header, formData, body)
  let scheme = call_617162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617162.url(scheme.get, call_617162.host, call_617162.base,
                         call_617162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617162, url, valid)

proc call*(call_617163: Call_TagResource_617150; ARN: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> to a function.
  ##   ARN: string (required)
  ##      : The function's Amazon Resource Name (ARN).
  ##   body: JObject (required)
  var path_617164 = newJObject()
  var body_617165 = newJObject()
  add(path_617164, "ARN", newJString(ARN))
  if body != nil:
    body_617165 = body
  result = call_617163.call(path_617164, nil, nil, nil, body_617165)

var tagResource* = Call_TagResource_617150(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "lambda.amazonaws.com",
                                        route: "/2017-03-31/tags/{ARN}",
                                        validator: validate_TagResource_617151,
                                        base: "/", url: url_TagResource_617152,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_617136 = ref object of OpenApiRestCall_615866
proc url_ListTags_617138(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ARN" in path, "`ARN` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-03-31/tags/"),
               (kind: VariableSegment, value: "ARN")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTags_617137(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a function's <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a>. You can also view tags with <a>GetFunction</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ARN: JString (required)
  ##      : The function's Amazon Resource Name (ARN).
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ARN` field"
  var valid_617139 = path.getOrDefault("ARN")
  valid_617139 = validateParameter(valid_617139, JString, required = true,
                                 default = nil)
  if valid_617139 != nil:
    section.add "ARN", valid_617139
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
  var valid_617140 = header.getOrDefault("X-Amz-Date")
  valid_617140 = validateParameter(valid_617140, JString, required = false,
                                 default = nil)
  if valid_617140 != nil:
    section.add "X-Amz-Date", valid_617140
  var valid_617141 = header.getOrDefault("X-Amz-Security-Token")
  valid_617141 = validateParameter(valid_617141, JString, required = false,
                                 default = nil)
  if valid_617141 != nil:
    section.add "X-Amz-Security-Token", valid_617141
  var valid_617142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617142 = validateParameter(valid_617142, JString, required = false,
                                 default = nil)
  if valid_617142 != nil:
    section.add "X-Amz-Content-Sha256", valid_617142
  var valid_617143 = header.getOrDefault("X-Amz-Algorithm")
  valid_617143 = validateParameter(valid_617143, JString, required = false,
                                 default = nil)
  if valid_617143 != nil:
    section.add "X-Amz-Algorithm", valid_617143
  var valid_617144 = header.getOrDefault("X-Amz-Signature")
  valid_617144 = validateParameter(valid_617144, JString, required = false,
                                 default = nil)
  if valid_617144 != nil:
    section.add "X-Amz-Signature", valid_617144
  var valid_617145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617145 = validateParameter(valid_617145, JString, required = false,
                                 default = nil)
  if valid_617145 != nil:
    section.add "X-Amz-SignedHeaders", valid_617145
  var valid_617146 = header.getOrDefault("X-Amz-Credential")
  valid_617146 = validateParameter(valid_617146, JString, required = false,
                                 default = nil)
  if valid_617146 != nil:
    section.add "X-Amz-Credential", valid_617146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617147: Call_ListTags_617136; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a function's <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a>. You can also view tags with <a>GetFunction</a>.
  ## 
  let valid = call_617147.validator(path, query, header, formData, body)
  let scheme = call_617147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617147.url(scheme.get, call_617147.host, call_617147.base,
                         call_617147.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617147, url, valid)

proc call*(call_617148: Call_ListTags_617136; ARN: string): Recallable =
  ## listTags
  ## Returns a function's <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a>. You can also view tags with <a>GetFunction</a>.
  ##   ARN: string (required)
  ##      : The function's Amazon Resource Name (ARN).
  var path_617149 = newJObject()
  add(path_617149, "ARN", newJString(ARN))
  result = call_617148.call(path_617149, nil, nil, nil, nil)

var listTags* = Call_ListTags_617136(name: "listTags", meth: HttpMethod.HttpGet,
                                  host: "lambda.amazonaws.com",
                                  route: "/2017-03-31/tags/{ARN}",
                                  validator: validate_ListTags_617137, base: "/",
                                  url: url_ListTags_617138,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PublishVersion_617183 = ref object of OpenApiRestCall_615866
proc url_PublishVersion_617185(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PublishVersion_617184(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates a <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">version</a> from the current code and configuration of a function. Use versions to create a snapshot of your function code and configuration that doesn't change.</p> <p>AWS Lambda doesn't publish a version if the function's configuration and code haven't changed since the last version. Use <a>UpdateFunctionCode</a> or <a>UpdateFunctionConfiguration</a> to update the function before publishing a version.</p> <p>Clients can invoke versions directly or with an alias. To create an alias, use <a>CreateAlias</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_617186 = path.getOrDefault("FunctionName")
  valid_617186 = validateParameter(valid_617186, JString, required = true,
                                 default = nil)
  if valid_617186 != nil:
    section.add "FunctionName", valid_617186
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
  var valid_617187 = header.getOrDefault("X-Amz-Date")
  valid_617187 = validateParameter(valid_617187, JString, required = false,
                                 default = nil)
  if valid_617187 != nil:
    section.add "X-Amz-Date", valid_617187
  var valid_617188 = header.getOrDefault("X-Amz-Security-Token")
  valid_617188 = validateParameter(valid_617188, JString, required = false,
                                 default = nil)
  if valid_617188 != nil:
    section.add "X-Amz-Security-Token", valid_617188
  var valid_617189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617189 = validateParameter(valid_617189, JString, required = false,
                                 default = nil)
  if valid_617189 != nil:
    section.add "X-Amz-Content-Sha256", valid_617189
  var valid_617190 = header.getOrDefault("X-Amz-Algorithm")
  valid_617190 = validateParameter(valid_617190, JString, required = false,
                                 default = nil)
  if valid_617190 != nil:
    section.add "X-Amz-Algorithm", valid_617190
  var valid_617191 = header.getOrDefault("X-Amz-Signature")
  valid_617191 = validateParameter(valid_617191, JString, required = false,
                                 default = nil)
  if valid_617191 != nil:
    section.add "X-Amz-Signature", valid_617191
  var valid_617192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617192 = validateParameter(valid_617192, JString, required = false,
                                 default = nil)
  if valid_617192 != nil:
    section.add "X-Amz-SignedHeaders", valid_617192
  var valid_617193 = header.getOrDefault("X-Amz-Credential")
  valid_617193 = validateParameter(valid_617193, JString, required = false,
                                 default = nil)
  if valid_617193 != nil:
    section.add "X-Amz-Credential", valid_617193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617195: Call_PublishVersion_617183; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">version</a> from the current code and configuration of a function. Use versions to create a snapshot of your function code and configuration that doesn't change.</p> <p>AWS Lambda doesn't publish a version if the function's configuration and code haven't changed since the last version. Use <a>UpdateFunctionCode</a> or <a>UpdateFunctionConfiguration</a> to update the function before publishing a version.</p> <p>Clients can invoke versions directly or with an alias. To create an alias, use <a>CreateAlias</a>.</p>
  ## 
  let valid = call_617195.validator(path, query, header, formData, body)
  let scheme = call_617195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617195.url(scheme.get, call_617195.host, call_617195.base,
                         call_617195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617195, url, valid)

proc call*(call_617196: Call_PublishVersion_617183; FunctionName: string;
          body: JsonNode): Recallable =
  ## publishVersion
  ## <p>Creates a <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">version</a> from the current code and configuration of a function. Use versions to create a snapshot of your function code and configuration that doesn't change.</p> <p>AWS Lambda doesn't publish a version if the function's configuration and code haven't changed since the last version. Use <a>UpdateFunctionCode</a> or <a>UpdateFunctionConfiguration</a> to update the function before publishing a version.</p> <p>Clients can invoke versions directly or with an alias. To create an alias, use <a>CreateAlias</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_617197 = newJObject()
  var body_617198 = newJObject()
  add(path_617197, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_617198 = body
  result = call_617196.call(path_617197, nil, nil, nil, body_617198)

var publishVersion* = Call_PublishVersion_617183(name: "publishVersion",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/versions",
    validator: validate_PublishVersion_617184, base: "/", url: url_PublishVersion_617185,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVersionsByFunction_617166 = ref object of OpenApiRestCall_615866
proc url_ListVersionsByFunction_617168(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListVersionsByFunction_617167(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">versions</a>, with the version-specific configuration of each. Lambda returns up to 50 versions per call.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_617169 = path.getOrDefault("FunctionName")
  valid_617169 = validateParameter(valid_617169, JString, required = true,
                                 default = nil)
  if valid_617169 != nil:
    section.add "FunctionName", valid_617169
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: JInt
  ##           : The maximum number of versions to return.
  section = newJObject()
  var valid_617170 = query.getOrDefault("Marker")
  valid_617170 = validateParameter(valid_617170, JString, required = false,
                                 default = nil)
  if valid_617170 != nil:
    section.add "Marker", valid_617170
  var valid_617171 = query.getOrDefault("MaxItems")
  valid_617171 = validateParameter(valid_617171, JInt, required = false, default = nil)
  if valid_617171 != nil:
    section.add "MaxItems", valid_617171
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
  var valid_617172 = header.getOrDefault("X-Amz-Date")
  valid_617172 = validateParameter(valid_617172, JString, required = false,
                                 default = nil)
  if valid_617172 != nil:
    section.add "X-Amz-Date", valid_617172
  var valid_617173 = header.getOrDefault("X-Amz-Security-Token")
  valid_617173 = validateParameter(valid_617173, JString, required = false,
                                 default = nil)
  if valid_617173 != nil:
    section.add "X-Amz-Security-Token", valid_617173
  var valid_617174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617174 = validateParameter(valid_617174, JString, required = false,
                                 default = nil)
  if valid_617174 != nil:
    section.add "X-Amz-Content-Sha256", valid_617174
  var valid_617175 = header.getOrDefault("X-Amz-Algorithm")
  valid_617175 = validateParameter(valid_617175, JString, required = false,
                                 default = nil)
  if valid_617175 != nil:
    section.add "X-Amz-Algorithm", valid_617175
  var valid_617176 = header.getOrDefault("X-Amz-Signature")
  valid_617176 = validateParameter(valid_617176, JString, required = false,
                                 default = nil)
  if valid_617176 != nil:
    section.add "X-Amz-Signature", valid_617176
  var valid_617177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617177 = validateParameter(valid_617177, JString, required = false,
                                 default = nil)
  if valid_617177 != nil:
    section.add "X-Amz-SignedHeaders", valid_617177
  var valid_617178 = header.getOrDefault("X-Amz-Credential")
  valid_617178 = validateParameter(valid_617178, JString, required = false,
                                 default = nil)
  if valid_617178 != nil:
    section.add "X-Amz-Credential", valid_617178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617179: Call_ListVersionsByFunction_617166; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">versions</a>, with the version-specific configuration of each. Lambda returns up to 50 versions per call.
  ## 
  let valid = call_617179.validator(path, query, header, formData, body)
  let scheme = call_617179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617179.url(scheme.get, call_617179.host, call_617179.base,
                         call_617179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617179, url, valid)

proc call*(call_617180: Call_ListVersionsByFunction_617166; FunctionName: string;
          Marker: string = ""; MaxItems: int = 0): Recallable =
  ## listVersionsByFunction
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">versions</a>, with the version-specific configuration of each. Lambda returns up to 50 versions per call.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Marker: string
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: int
  ##           : The maximum number of versions to return.
  var path_617181 = newJObject()
  var query_617182 = newJObject()
  add(path_617181, "FunctionName", newJString(FunctionName))
  add(query_617182, "Marker", newJString(Marker))
  add(query_617182, "MaxItems", newJInt(MaxItems))
  result = call_617180.call(path_617181, query_617182, nil, nil, nil)

var listVersionsByFunction* = Call_ListVersionsByFunction_617166(
    name: "listVersionsByFunction", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/versions",
    validator: validate_ListVersionsByFunction_617167, base: "/",
    url: url_ListVersionsByFunction_617168, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveLayerVersionPermission_617199 = ref object of OpenApiRestCall_615866
proc url_RemoveLayerVersionPermission_617201(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "LayerName" in path, "`LayerName` is a required path parameter"
  assert "VersionNumber" in path, "`VersionNumber` is a required path parameter"
  assert "StatementId" in path, "`StatementId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2018-10-31/layers/"),
               (kind: VariableSegment, value: "LayerName"),
               (kind: ConstantSegment, value: "/versions/"),
               (kind: VariableSegment, value: "VersionNumber"),
               (kind: ConstantSegment, value: "/policy/"),
               (kind: VariableSegment, value: "StatementId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RemoveLayerVersionPermission_617200(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a statement from the permissions policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   StatementId: JString (required)
  ##              : The identifier that was specified when the statement was added.
  ##   LayerName: JString (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  ##   VersionNumber: JInt (required)
  ##                : The version number.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `StatementId` field"
  var valid_617202 = path.getOrDefault("StatementId")
  valid_617202 = validateParameter(valid_617202, JString, required = true,
                                 default = nil)
  if valid_617202 != nil:
    section.add "StatementId", valid_617202
  var valid_617203 = path.getOrDefault("LayerName")
  valid_617203 = validateParameter(valid_617203, JString, required = true,
                                 default = nil)
  if valid_617203 != nil:
    section.add "LayerName", valid_617203
  var valid_617204 = path.getOrDefault("VersionNumber")
  valid_617204 = validateParameter(valid_617204, JInt, required = true, default = nil)
  if valid_617204 != nil:
    section.add "VersionNumber", valid_617204
  result.add "path", section
  ## parameters in `query` object:
  ##   RevisionId: JString
  ##             : Only update the policy if the revision ID matches the ID specified. Use this option to avoid modifying a policy that has changed since you last read it.
  section = newJObject()
  var valid_617205 = query.getOrDefault("RevisionId")
  valid_617205 = validateParameter(valid_617205, JString, required = false,
                                 default = nil)
  if valid_617205 != nil:
    section.add "RevisionId", valid_617205
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
  var valid_617206 = header.getOrDefault("X-Amz-Date")
  valid_617206 = validateParameter(valid_617206, JString, required = false,
                                 default = nil)
  if valid_617206 != nil:
    section.add "X-Amz-Date", valid_617206
  var valid_617207 = header.getOrDefault("X-Amz-Security-Token")
  valid_617207 = validateParameter(valid_617207, JString, required = false,
                                 default = nil)
  if valid_617207 != nil:
    section.add "X-Amz-Security-Token", valid_617207
  var valid_617208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617208 = validateParameter(valid_617208, JString, required = false,
                                 default = nil)
  if valid_617208 != nil:
    section.add "X-Amz-Content-Sha256", valid_617208
  var valid_617209 = header.getOrDefault("X-Amz-Algorithm")
  valid_617209 = validateParameter(valid_617209, JString, required = false,
                                 default = nil)
  if valid_617209 != nil:
    section.add "X-Amz-Algorithm", valid_617209
  var valid_617210 = header.getOrDefault("X-Amz-Signature")
  valid_617210 = validateParameter(valid_617210, JString, required = false,
                                 default = nil)
  if valid_617210 != nil:
    section.add "X-Amz-Signature", valid_617210
  var valid_617211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617211 = validateParameter(valid_617211, JString, required = false,
                                 default = nil)
  if valid_617211 != nil:
    section.add "X-Amz-SignedHeaders", valid_617211
  var valid_617212 = header.getOrDefault("X-Amz-Credential")
  valid_617212 = validateParameter(valid_617212, JString, required = false,
                                 default = nil)
  if valid_617212 != nil:
    section.add "X-Amz-Credential", valid_617212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617213: Call_RemoveLayerVersionPermission_617199; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a statement from the permissions policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ## 
  let valid = call_617213.validator(path, query, header, formData, body)
  let scheme = call_617213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617213.url(scheme.get, call_617213.host, call_617213.base,
                         call_617213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617213, url, valid)

proc call*(call_617214: Call_RemoveLayerVersionPermission_617199;
          StatementId: string; LayerName: string; VersionNumber: int;
          RevisionId: string = ""): Recallable =
  ## removeLayerVersionPermission
  ## Removes a statement from the permissions policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ##   StatementId: string (required)
  ##              : The identifier that was specified when the statement was added.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  ##   VersionNumber: int (required)
  ##                : The version number.
  ##   RevisionId: string
  ##             : Only update the policy if the revision ID matches the ID specified. Use this option to avoid modifying a policy that has changed since you last read it.
  var path_617215 = newJObject()
  var query_617216 = newJObject()
  add(path_617215, "StatementId", newJString(StatementId))
  add(path_617215, "LayerName", newJString(LayerName))
  add(path_617215, "VersionNumber", newJInt(VersionNumber))
  add(query_617216, "RevisionId", newJString(RevisionId))
  result = call_617214.call(path_617215, query_617216, nil, nil, nil)

var removeLayerVersionPermission* = Call_RemoveLayerVersionPermission_617199(
    name: "removeLayerVersionPermission", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com", route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy/{StatementId}",
    validator: validate_RemoveLayerVersionPermission_617200, base: "/",
    url: url_RemoveLayerVersionPermission_617201,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemovePermission_617217 = ref object of OpenApiRestCall_615866
proc url_RemovePermission_617219(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  assert "StatementId" in path, "`StatementId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/policy/"),
               (kind: VariableSegment, value: "StatementId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RemovePermission_617218(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Revokes function-use permission from an AWS service or another account. You can get the ID of the statement from the output of <a>GetPolicy</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   StatementId: JString (required)
  ##              : Statement ID of the permission to remove.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_617220 = path.getOrDefault("FunctionName")
  valid_617220 = validateParameter(valid_617220, JString, required = true,
                                 default = nil)
  if valid_617220 != nil:
    section.add "FunctionName", valid_617220
  var valid_617221 = path.getOrDefault("StatementId")
  valid_617221 = validateParameter(valid_617221, JString, required = true,
                                 default = nil)
  if valid_617221 != nil:
    section.add "StatementId", valid_617221
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to remove permissions from a published version of the function.
  ##   RevisionId: JString
  ##             : Only update the policy if the revision ID matches the ID that's specified. Use this option to avoid modifying a policy that has changed since you last read it.
  section = newJObject()
  var valid_617222 = query.getOrDefault("Qualifier")
  valid_617222 = validateParameter(valid_617222, JString, required = false,
                                 default = nil)
  if valid_617222 != nil:
    section.add "Qualifier", valid_617222
  var valid_617223 = query.getOrDefault("RevisionId")
  valid_617223 = validateParameter(valid_617223, JString, required = false,
                                 default = nil)
  if valid_617223 != nil:
    section.add "RevisionId", valid_617223
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
  var valid_617224 = header.getOrDefault("X-Amz-Date")
  valid_617224 = validateParameter(valid_617224, JString, required = false,
                                 default = nil)
  if valid_617224 != nil:
    section.add "X-Amz-Date", valid_617224
  var valid_617225 = header.getOrDefault("X-Amz-Security-Token")
  valid_617225 = validateParameter(valid_617225, JString, required = false,
                                 default = nil)
  if valid_617225 != nil:
    section.add "X-Amz-Security-Token", valid_617225
  var valid_617226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617226 = validateParameter(valid_617226, JString, required = false,
                                 default = nil)
  if valid_617226 != nil:
    section.add "X-Amz-Content-Sha256", valid_617226
  var valid_617227 = header.getOrDefault("X-Amz-Algorithm")
  valid_617227 = validateParameter(valid_617227, JString, required = false,
                                 default = nil)
  if valid_617227 != nil:
    section.add "X-Amz-Algorithm", valid_617227
  var valid_617228 = header.getOrDefault("X-Amz-Signature")
  valid_617228 = validateParameter(valid_617228, JString, required = false,
                                 default = nil)
  if valid_617228 != nil:
    section.add "X-Amz-Signature", valid_617228
  var valid_617229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617229 = validateParameter(valid_617229, JString, required = false,
                                 default = nil)
  if valid_617229 != nil:
    section.add "X-Amz-SignedHeaders", valid_617229
  var valid_617230 = header.getOrDefault("X-Amz-Credential")
  valid_617230 = validateParameter(valid_617230, JString, required = false,
                                 default = nil)
  if valid_617230 != nil:
    section.add "X-Amz-Credential", valid_617230
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617231: Call_RemovePermission_617217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Revokes function-use permission from an AWS service or another account. You can get the ID of the statement from the output of <a>GetPolicy</a>.
  ## 
  let valid = call_617231.validator(path, query, header, formData, body)
  let scheme = call_617231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617231.url(scheme.get, call_617231.host, call_617231.base,
                         call_617231.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617231, url, valid)

proc call*(call_617232: Call_RemovePermission_617217; FunctionName: string;
          StatementId: string; Qualifier: string = ""; RevisionId: string = ""): Recallable =
  ## removePermission
  ## Revokes function-use permission from an AWS service or another account. You can get the ID of the statement from the output of <a>GetPolicy</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   StatementId: string (required)
  ##              : Statement ID of the permission to remove.
  ##   Qualifier: string
  ##            : Specify a version or alias to remove permissions from a published version of the function.
  ##   RevisionId: string
  ##             : Only update the policy if the revision ID matches the ID that's specified. Use this option to avoid modifying a policy that has changed since you last read it.
  var path_617233 = newJObject()
  var query_617234 = newJObject()
  add(path_617233, "FunctionName", newJString(FunctionName))
  add(path_617233, "StatementId", newJString(StatementId))
  add(query_617234, "Qualifier", newJString(Qualifier))
  add(query_617234, "RevisionId", newJString(RevisionId))
  result = call_617232.call(path_617233, query_617234, nil, nil, nil)

var removePermission* = Call_RemovePermission_617217(name: "removePermission",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/policy/{StatementId}",
    validator: validate_RemovePermission_617218, base: "/",
    url: url_RemovePermission_617219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_617235 = ref object of OpenApiRestCall_615866
proc url_UntagResource_617237(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ARN" in path, "`ARN` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2017-03-31/tags/"),
               (kind: VariableSegment, value: "ARN"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_617236(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> from a function.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ARN: JString (required)
  ##      : The function's Amazon Resource Name (ARN).
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ARN` field"
  var valid_617238 = path.getOrDefault("ARN")
  valid_617238 = validateParameter(valid_617238, JString, required = true,
                                 default = nil)
  if valid_617238 != nil:
    section.add "ARN", valid_617238
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A list of tag keys to remove from the function.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_617239 = query.getOrDefault("tagKeys")
  valid_617239 = validateParameter(valid_617239, JArray, required = true, default = nil)
  if valid_617239 != nil:
    section.add "tagKeys", valid_617239
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
  var valid_617240 = header.getOrDefault("X-Amz-Date")
  valid_617240 = validateParameter(valid_617240, JString, required = false,
                                 default = nil)
  if valid_617240 != nil:
    section.add "X-Amz-Date", valid_617240
  var valid_617241 = header.getOrDefault("X-Amz-Security-Token")
  valid_617241 = validateParameter(valid_617241, JString, required = false,
                                 default = nil)
  if valid_617241 != nil:
    section.add "X-Amz-Security-Token", valid_617241
  var valid_617242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617242 = validateParameter(valid_617242, JString, required = false,
                                 default = nil)
  if valid_617242 != nil:
    section.add "X-Amz-Content-Sha256", valid_617242
  var valid_617243 = header.getOrDefault("X-Amz-Algorithm")
  valid_617243 = validateParameter(valid_617243, JString, required = false,
                                 default = nil)
  if valid_617243 != nil:
    section.add "X-Amz-Algorithm", valid_617243
  var valid_617244 = header.getOrDefault("X-Amz-Signature")
  valid_617244 = validateParameter(valid_617244, JString, required = false,
                                 default = nil)
  if valid_617244 != nil:
    section.add "X-Amz-Signature", valid_617244
  var valid_617245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617245 = validateParameter(valid_617245, JString, required = false,
                                 default = nil)
  if valid_617245 != nil:
    section.add "X-Amz-SignedHeaders", valid_617245
  var valid_617246 = header.getOrDefault("X-Amz-Credential")
  valid_617246 = validateParameter(valid_617246, JString, required = false,
                                 default = nil)
  if valid_617246 != nil:
    section.add "X-Amz-Credential", valid_617246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617247: Call_UntagResource_617235; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> from a function.
  ## 
  let valid = call_617247.validator(path, query, header, formData, body)
  let scheme = call_617247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617247.url(scheme.get, call_617247.host, call_617247.base,
                         call_617247.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617247, url, valid)

proc call*(call_617248: Call_UntagResource_617235; ARN: string; tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> from a function.
  ##   ARN: string (required)
  ##      : The function's Amazon Resource Name (ARN).
  ##   tagKeys: JArray (required)
  ##          : A list of tag keys to remove from the function.
  var path_617249 = newJObject()
  var query_617250 = newJObject()
  add(path_617249, "ARN", newJString(ARN))
  if tagKeys != nil:
    query_617250.add "tagKeys", tagKeys
  result = call_617248.call(path_617249, query_617250, nil, nil, nil)

var untagResource* = Call_UntagResource_617235(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2017-03-31/tags/{ARN}#tagKeys", validator: validate_UntagResource_617236,
    base: "/", url: url_UntagResource_617237, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionCode_617251 = ref object of OpenApiRestCall_615866
proc url_UpdateFunctionCode_617253(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "FunctionName" in path, "`FunctionName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/2015-03-31/functions/"),
               (kind: VariableSegment, value: "FunctionName"),
               (kind: ConstantSegment, value: "/code")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFunctionCode_617252(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Updates a Lambda function's code.</p> <p>The function's code is locked when you publish a version. You can't modify the code of a published version, only the unpublished version.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_617254 = path.getOrDefault("FunctionName")
  valid_617254 = validateParameter(valid_617254, JString, required = true,
                                 default = nil)
  if valid_617254 != nil:
    section.add "FunctionName", valid_617254
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
  var valid_617255 = header.getOrDefault("X-Amz-Date")
  valid_617255 = validateParameter(valid_617255, JString, required = false,
                                 default = nil)
  if valid_617255 != nil:
    section.add "X-Amz-Date", valid_617255
  var valid_617256 = header.getOrDefault("X-Amz-Security-Token")
  valid_617256 = validateParameter(valid_617256, JString, required = false,
                                 default = nil)
  if valid_617256 != nil:
    section.add "X-Amz-Security-Token", valid_617256
  var valid_617257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617257 = validateParameter(valid_617257, JString, required = false,
                                 default = nil)
  if valid_617257 != nil:
    section.add "X-Amz-Content-Sha256", valid_617257
  var valid_617258 = header.getOrDefault("X-Amz-Algorithm")
  valid_617258 = validateParameter(valid_617258, JString, required = false,
                                 default = nil)
  if valid_617258 != nil:
    section.add "X-Amz-Algorithm", valid_617258
  var valid_617259 = header.getOrDefault("X-Amz-Signature")
  valid_617259 = validateParameter(valid_617259, JString, required = false,
                                 default = nil)
  if valid_617259 != nil:
    section.add "X-Amz-Signature", valid_617259
  var valid_617260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617260 = validateParameter(valid_617260, JString, required = false,
                                 default = nil)
  if valid_617260 != nil:
    section.add "X-Amz-SignedHeaders", valid_617260
  var valid_617261 = header.getOrDefault("X-Amz-Credential")
  valid_617261 = validateParameter(valid_617261, JString, required = false,
                                 default = nil)
  if valid_617261 != nil:
    section.add "X-Amz-Credential", valid_617261
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617263: Call_UpdateFunctionCode_617251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a Lambda function's code.</p> <p>The function's code is locked when you publish a version. You can't modify the code of a published version, only the unpublished version.</p>
  ## 
  let valid = call_617263.validator(path, query, header, formData, body)
  let scheme = call_617263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617263.url(scheme.get, call_617263.host, call_617263.base,
                         call_617263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617263, url, valid)

proc call*(call_617264: Call_UpdateFunctionCode_617251; FunctionName: string;
          body: JsonNode): Recallable =
  ## updateFunctionCode
  ## <p>Updates a Lambda function's code.</p> <p>The function's code is locked when you publish a version. You can't modify the code of a published version, only the unpublished version.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_617265 = newJObject()
  var body_617266 = newJObject()
  add(path_617265, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_617266 = body
  result = call_617264.call(path_617265, nil, nil, nil, body_617266)

var updateFunctionCode* = Call_UpdateFunctionCode_617251(
    name: "updateFunctionCode", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/code",
    validator: validate_UpdateFunctionCode_617252, base: "/",
    url: url_UpdateFunctionCode_617253, schemes: {Scheme.Https, Scheme.Http})
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
