
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "lambda.ap-northeast-1.amazonaws.com", "ap-southeast-1": "lambda.ap-southeast-1.amazonaws.com",
                           "us-west-2": "lambda.us-west-2.amazonaws.com",
                           "eu-west-2": "lambda.eu-west-2.amazonaws.com", "ap-northeast-3": "lambda.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "lambda.eu-central-1.amazonaws.com",
                           "us-east-2": "lambda.us-east-2.amazonaws.com",
                           "us-east-1": "lambda.us-east-1.amazonaws.com", "cn-northwest-1": "lambda.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "lambda.ap-south-1.amazonaws.com",
                           "eu-north-1": "lambda.eu-north-1.amazonaws.com", "ap-northeast-2": "lambda.ap-northeast-2.amazonaws.com",
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
      "ap-south-1": "lambda.ap-south-1.amazonaws.com",
      "eu-north-1": "lambda.eu-north-1.amazonaws.com",
      "ap-northeast-2": "lambda.ap-northeast-2.amazonaws.com",
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_AddLayerVersionPermission_21626031 = ref object of OpenApiRestCall_21625435
proc url_AddLayerVersionPermission_21626033(protocol: Scheme; host: string;
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

proc validate_AddLayerVersionPermission_21626032(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Adds permissions to the resource-based policy of a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Use this action to grant layer usage permission to other accounts. You can grant permission to a single account, all AWS accounts, or all accounts in an organization.</p> <p>To revoke permission, call <a>RemoveLayerVersionPermission</a> with the statement ID that you specified when you added it.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   VersionNumber: JInt (required)
  ##                : The version number.
  ##   LayerName: JString (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `VersionNumber` field"
  var valid_21626034 = path.getOrDefault("VersionNumber")
  valid_21626034 = validateParameter(valid_21626034, JInt, required = true,
                                   default = nil)
  if valid_21626034 != nil:
    section.add "VersionNumber", valid_21626034
  var valid_21626035 = path.getOrDefault("LayerName")
  valid_21626035 = validateParameter(valid_21626035, JString, required = true,
                                   default = nil)
  if valid_21626035 != nil:
    section.add "LayerName", valid_21626035
  result.add "path", section
  ## parameters in `query` object:
  ##   RevisionId: JString
  ##             : Only update the policy if the revision ID matches the ID specified. Use this option to avoid modifying a policy that has changed since you last read it.
  section = newJObject()
  var valid_21626036 = query.getOrDefault("RevisionId")
  valid_21626036 = validateParameter(valid_21626036, JString, required = false,
                                   default = nil)
  if valid_21626036 != nil:
    section.add "RevisionId", valid_21626036
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
  var valid_21626037 = header.getOrDefault("X-Amz-Date")
  valid_21626037 = validateParameter(valid_21626037, JString, required = false,
                                   default = nil)
  if valid_21626037 != nil:
    section.add "X-Amz-Date", valid_21626037
  var valid_21626038 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "X-Amz-Security-Token", valid_21626038
  var valid_21626039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-Algorithm", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-Signature")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Signature", valid_21626041
  var valid_21626042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626042
  var valid_21626043 = header.getOrDefault("X-Amz-Credential")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-Credential", valid_21626043
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

proc call*(call_21626045: Call_AddLayerVersionPermission_21626031;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds permissions to the resource-based policy of a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Use this action to grant layer usage permission to other accounts. You can grant permission to a single account, all AWS accounts, or all accounts in an organization.</p> <p>To revoke permission, call <a>RemoveLayerVersionPermission</a> with the statement ID that you specified when you added it.</p>
  ## 
  let valid = call_21626045.validator(path, query, header, formData, body, _)
  let scheme = call_21626045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626045.makeUrl(scheme.get, call_21626045.host, call_21626045.base,
                               call_21626045.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626045, uri, valid, _)

proc call*(call_21626046: Call_AddLayerVersionPermission_21626031;
          VersionNumber: int; LayerName: string; body: JsonNode;
          RevisionId: string = ""): Recallable =
  ## addLayerVersionPermission
  ## <p>Adds permissions to the resource-based policy of a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Use this action to grant layer usage permission to other accounts. You can grant permission to a single account, all AWS accounts, or all accounts in an organization.</p> <p>To revoke permission, call <a>RemoveLayerVersionPermission</a> with the statement ID that you specified when you added it.</p>
  ##   RevisionId: string
  ##             : Only update the policy if the revision ID matches the ID specified. Use this option to avoid modifying a policy that has changed since you last read it.
  ##   VersionNumber: int (required)
  ##                : The version number.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  ##   body: JObject (required)
  var path_21626047 = newJObject()
  var query_21626048 = newJObject()
  var body_21626049 = newJObject()
  add(query_21626048, "RevisionId", newJString(RevisionId))
  add(path_21626047, "VersionNumber", newJInt(VersionNumber))
  add(path_21626047, "LayerName", newJString(LayerName))
  if body != nil:
    body_21626049 = body
  result = call_21626046.call(path_21626047, query_21626048, nil, nil, body_21626049)

var addLayerVersionPermission* = Call_AddLayerVersionPermission_21626031(
    name: "addLayerVersionPermission", meth: HttpMethod.HttpPost,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy",
    validator: validate_AddLayerVersionPermission_21626032, base: "/",
    makeUrl: url_AddLayerVersionPermission_21626033,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLayerVersionPolicy_21625779 = ref object of OpenApiRestCall_21625435
proc url_GetLayerVersionPolicy_21625781(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
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

proc validate_GetLayerVersionPolicy_21625780(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the permission policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   VersionNumber: JInt (required)
  ##                : The version number.
  ##   LayerName: JString (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `VersionNumber` field"
  var valid_21625895 = path.getOrDefault("VersionNumber")
  valid_21625895 = validateParameter(valid_21625895, JInt, required = true,
                                   default = nil)
  if valid_21625895 != nil:
    section.add "VersionNumber", valid_21625895
  var valid_21625896 = path.getOrDefault("LayerName")
  valid_21625896 = validateParameter(valid_21625896, JString, required = true,
                                   default = nil)
  if valid_21625896 != nil:
    section.add "LayerName", valid_21625896
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
  var valid_21625897 = header.getOrDefault("X-Amz-Date")
  valid_21625897 = validateParameter(valid_21625897, JString, required = false,
                                   default = nil)
  if valid_21625897 != nil:
    section.add "X-Amz-Date", valid_21625897
  var valid_21625898 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625898 = validateParameter(valid_21625898, JString, required = false,
                                   default = nil)
  if valid_21625898 != nil:
    section.add "X-Amz-Security-Token", valid_21625898
  var valid_21625899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Algorithm", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-Signature")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Signature", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-Credential")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-Credential", valid_21625903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625928: Call_GetLayerVersionPolicy_21625779;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the permission policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ## 
  let valid = call_21625928.validator(path, query, header, formData, body, _)
  let scheme = call_21625928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625928.makeUrl(scheme.get, call_21625928.host, call_21625928.base,
                               call_21625928.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625928, uri, valid, _)

proc call*(call_21625991: Call_GetLayerVersionPolicy_21625779; VersionNumber: int;
          LayerName: string): Recallable =
  ## getLayerVersionPolicy
  ## Returns the permission policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ##   VersionNumber: int (required)
  ##                : The version number.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  var path_21625993 = newJObject()
  add(path_21625993, "VersionNumber", newJInt(VersionNumber))
  add(path_21625993, "LayerName", newJString(LayerName))
  result = call_21625991.call(path_21625993, nil, nil, nil, nil)

var getLayerVersionPolicy* = Call_GetLayerVersionPolicy_21625779(
    name: "getLayerVersionPolicy", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy",
    validator: validate_GetLayerVersionPolicy_21625780, base: "/",
    makeUrl: url_GetLayerVersionPolicy_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddPermission_21626067 = ref object of OpenApiRestCall_21625435
proc url_AddPermission_21626069(protocol: Scheme; host: string; base: string;
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

proc validate_AddPermission_21626068(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626070 = path.getOrDefault("FunctionName")
  valid_21626070 = validateParameter(valid_21626070, JString, required = true,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "FunctionName", valid_21626070
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to add permissions to a published version of the function.
  section = newJObject()
  var valid_21626071 = query.getOrDefault("Qualifier")
  valid_21626071 = validateParameter(valid_21626071, JString, required = false,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "Qualifier", valid_21626071
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
  var valid_21626072 = header.getOrDefault("X-Amz-Date")
  valid_21626072 = validateParameter(valid_21626072, JString, required = false,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "X-Amz-Date", valid_21626072
  var valid_21626073 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626073 = validateParameter(valid_21626073, JString, required = false,
                                   default = nil)
  if valid_21626073 != nil:
    section.add "X-Amz-Security-Token", valid_21626073
  var valid_21626074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626074 = validateParameter(valid_21626074, JString, required = false,
                                   default = nil)
  if valid_21626074 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626074
  var valid_21626075 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = nil)
  if valid_21626075 != nil:
    section.add "X-Amz-Algorithm", valid_21626075
  var valid_21626076 = header.getOrDefault("X-Amz-Signature")
  valid_21626076 = validateParameter(valid_21626076, JString, required = false,
                                   default = nil)
  if valid_21626076 != nil:
    section.add "X-Amz-Signature", valid_21626076
  var valid_21626077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626077
  var valid_21626078 = header.getOrDefault("X-Amz-Credential")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Credential", valid_21626078
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

proc call*(call_21626080: Call_AddPermission_21626067; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Grants an AWS service or another account permission to use a function. You can apply the policy at the function level, or specify a qualifier to restrict access to a single version or alias. If you use a qualifier, the invoker must use the full Amazon Resource Name (ARN) of that version or alias to invoke the function.</p> <p>To grant permission to another account, specify the account ID as the <code>Principal</code>. For AWS services, the principal is a domain-style identifier defined by the service, like <code>s3.amazonaws.com</code> or <code>sns.amazonaws.com</code>. For AWS services, you can also specify the ARN or owning account of the associated resource as the <code>SourceArn</code> or <code>SourceAccount</code>. If you grant permission to a service principal without specifying the source, other accounts could potentially configure resources in their account to invoke your Lambda function.</p> <p>This action adds a statement to a resource-based permissions policy for the function. For more information about function policies, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">Lambda Function Policies</a>. </p>
  ## 
  let valid = call_21626080.validator(path, query, header, formData, body, _)
  let scheme = call_21626080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626080.makeUrl(scheme.get, call_21626080.host, call_21626080.base,
                               call_21626080.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626080, uri, valid, _)

proc call*(call_21626081: Call_AddPermission_21626067; FunctionName: string;
          body: JsonNode; Qualifier: string = ""): Recallable =
  ## addPermission
  ## <p>Grants an AWS service or another account permission to use a function. You can apply the policy at the function level, or specify a qualifier to restrict access to a single version or alias. If you use a qualifier, the invoker must use the full Amazon Resource Name (ARN) of that version or alias to invoke the function.</p> <p>To grant permission to another account, specify the account ID as the <code>Principal</code>. For AWS services, the principal is a domain-style identifier defined by the service, like <code>s3.amazonaws.com</code> or <code>sns.amazonaws.com</code>. For AWS services, you can also specify the ARN or owning account of the associated resource as the <code>SourceArn</code> or <code>SourceAccount</code>. If you grant permission to a service principal without specifying the source, other accounts could potentially configure resources in their account to invoke your Lambda function.</p> <p>This action adds a statement to a resource-based permissions policy for the function. For more information about function policies, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">Lambda Function Policies</a>. </p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to add permissions to a published version of the function.
  ##   body: JObject (required)
  var path_21626082 = newJObject()
  var query_21626083 = newJObject()
  var body_21626084 = newJObject()
  add(path_21626082, "FunctionName", newJString(FunctionName))
  add(query_21626083, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_21626084 = body
  result = call_21626081.call(path_21626082, query_21626083, nil, nil, body_21626084)

var addPermission* = Call_AddPermission_21626067(name: "addPermission",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/policy",
    validator: validate_AddPermission_21626068, base: "/",
    makeUrl: url_AddPermission_21626069, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPolicy_21626051 = ref object of OpenApiRestCall_21625435
proc url_GetPolicy_21626053(protocol: Scheme; host: string; base: string;
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

proc validate_GetPolicy_21626052(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626054 = path.getOrDefault("FunctionName")
  valid_21626054 = validateParameter(valid_21626054, JString, required = true,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "FunctionName", valid_21626054
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to get the policy for that resource.
  section = newJObject()
  var valid_21626055 = query.getOrDefault("Qualifier")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "Qualifier", valid_21626055
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
  var valid_21626056 = header.getOrDefault("X-Amz-Date")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-Date", valid_21626056
  var valid_21626057 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-Security-Token", valid_21626057
  var valid_21626058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626058
  var valid_21626059 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "X-Amz-Algorithm", valid_21626059
  var valid_21626060 = header.getOrDefault("X-Amz-Signature")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "X-Amz-Signature", valid_21626060
  var valid_21626061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626061
  var valid_21626062 = header.getOrDefault("X-Amz-Credential")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Credential", valid_21626062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626063: Call_GetPolicy_21626051; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">resource-based IAM policy</a> for a function, version, or alias.
  ## 
  let valid = call_21626063.validator(path, query, header, formData, body, _)
  let scheme = call_21626063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626063.makeUrl(scheme.get, call_21626063.host, call_21626063.base,
                               call_21626063.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626063, uri, valid, _)

proc call*(call_21626064: Call_GetPolicy_21626051; FunctionName: string;
          Qualifier: string = ""): Recallable =
  ## getPolicy
  ## Returns the <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">resource-based IAM policy</a> for a function, version, or alias.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to get the policy for that resource.
  var path_21626065 = newJObject()
  var query_21626066 = newJObject()
  add(path_21626065, "FunctionName", newJString(FunctionName))
  add(query_21626066, "Qualifier", newJString(Qualifier))
  result = call_21626064.call(path_21626065, query_21626066, nil, nil, nil)

var getPolicy* = Call_GetPolicy_21626051(name: "getPolicy", meth: HttpMethod.HttpGet,
                                      host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/policy",
                                      validator: validate_GetPolicy_21626052,
                                      base: "/", makeUrl: url_GetPolicy_21626053,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAlias_21626103 = ref object of OpenApiRestCall_21625435
proc url_CreateAlias_21626105(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAlias_21626104(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626106 = path.getOrDefault("FunctionName")
  valid_21626106 = validateParameter(valid_21626106, JString, required = true,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "FunctionName", valid_21626106
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
  var valid_21626107 = header.getOrDefault("X-Amz-Date")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-Date", valid_21626107
  var valid_21626108 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Security-Token", valid_21626108
  var valid_21626109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626109 = validateParameter(valid_21626109, JString, required = false,
                                   default = nil)
  if valid_21626109 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626109
  var valid_21626110 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Algorithm", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-Signature")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "X-Amz-Signature", valid_21626111
  var valid_21626112 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626112 = validateParameter(valid_21626112, JString, required = false,
                                   default = nil)
  if valid_21626112 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626112
  var valid_21626113 = header.getOrDefault("X-Amz-Credential")
  valid_21626113 = validateParameter(valid_21626113, JString, required = false,
                                   default = nil)
  if valid_21626113 != nil:
    section.add "X-Amz-Credential", valid_21626113
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

proc call*(call_21626115: Call_CreateAlias_21626103; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a> for a Lambda function version. Use aliases to provide clients with a function identifier that you can update to invoke a different version.</p> <p>You can also map an alias to split invocation requests between two versions. Use the <code>RoutingConfig</code> parameter to specify a second version and the percentage of invocation requests that it receives.</p>
  ## 
  let valid = call_21626115.validator(path, query, header, formData, body, _)
  let scheme = call_21626115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626115.makeUrl(scheme.get, call_21626115.host, call_21626115.base,
                               call_21626115.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626115, uri, valid, _)

proc call*(call_21626116: Call_CreateAlias_21626103; FunctionName: string;
          body: JsonNode): Recallable =
  ## createAlias
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a> for a Lambda function version. Use aliases to provide clients with a function identifier that you can update to invoke a different version.</p> <p>You can also map an alias to split invocation requests between two versions. Use the <code>RoutingConfig</code> parameter to specify a second version and the percentage of invocation requests that it receives.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_21626117 = newJObject()
  var body_21626118 = newJObject()
  add(path_21626117, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_21626118 = body
  result = call_21626116.call(path_21626117, nil, nil, nil, body_21626118)

var createAlias* = Call_CreateAlias_21626103(name: "createAlias",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/aliases",
    validator: validate_CreateAlias_21626104, base: "/", makeUrl: url_CreateAlias_21626105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAliases_21626085 = ref object of OpenApiRestCall_21625435
proc url_ListAliases_21626087(protocol: Scheme; host: string; base: string;
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

proc validate_ListAliases_21626086(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626088 = path.getOrDefault("FunctionName")
  valid_21626088 = validateParameter(valid_21626088, JString, required = true,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "FunctionName", valid_21626088
  result.add "path", section
  ## parameters in `query` object:
  ##   FunctionVersion: JString
  ##                  : Specify a function version to only list aliases that invoke that version.
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: JInt
  ##           : Limit the number of aliases returned.
  section = newJObject()
  var valid_21626089 = query.getOrDefault("FunctionVersion")
  valid_21626089 = validateParameter(valid_21626089, JString, required = false,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "FunctionVersion", valid_21626089
  var valid_21626090 = query.getOrDefault("Marker")
  valid_21626090 = validateParameter(valid_21626090, JString, required = false,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "Marker", valid_21626090
  var valid_21626091 = query.getOrDefault("MaxItems")
  valid_21626091 = validateParameter(valid_21626091, JInt, required = false,
                                   default = nil)
  if valid_21626091 != nil:
    section.add "MaxItems", valid_21626091
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
  var valid_21626092 = header.getOrDefault("X-Amz-Date")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-Date", valid_21626092
  var valid_21626093 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Security-Token", valid_21626093
  var valid_21626094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626094 = validateParameter(valid_21626094, JString, required = false,
                                   default = nil)
  if valid_21626094 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Algorithm", valid_21626095
  var valid_21626096 = header.getOrDefault("X-Amz-Signature")
  valid_21626096 = validateParameter(valid_21626096, JString, required = false,
                                   default = nil)
  if valid_21626096 != nil:
    section.add "X-Amz-Signature", valid_21626096
  var valid_21626097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-Credential")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-Credential", valid_21626098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626099: Call_ListAliases_21626085; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">aliases</a> for a Lambda function.
  ## 
  let valid = call_21626099.validator(path, query, header, formData, body, _)
  let scheme = call_21626099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626099.makeUrl(scheme.get, call_21626099.host, call_21626099.base,
                               call_21626099.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626099, uri, valid, _)

proc call*(call_21626100: Call_ListAliases_21626085; FunctionName: string;
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
  var path_21626101 = newJObject()
  var query_21626102 = newJObject()
  add(query_21626102, "FunctionVersion", newJString(FunctionVersion))
  add(path_21626101, "FunctionName", newJString(FunctionName))
  add(query_21626102, "Marker", newJString(Marker))
  add(query_21626102, "MaxItems", newJInt(MaxItems))
  result = call_21626100.call(path_21626101, query_21626102, nil, nil, nil)

var listAliases* = Call_ListAliases_21626085(name: "listAliases",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/aliases",
    validator: validate_ListAliases_21626086, base: "/", makeUrl: url_ListAliases_21626087,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEventSourceMapping_21626136 = ref object of OpenApiRestCall_21625435
proc url_CreateEventSourceMapping_21626138(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEventSourceMapping_21626137(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626139 = header.getOrDefault("X-Amz-Date")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-Date", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Security-Token", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Algorithm", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-Signature")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-Signature", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626144
  var valid_21626145 = header.getOrDefault("X-Amz-Credential")
  valid_21626145 = validateParameter(valid_21626145, JString, required = false,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "X-Amz-Credential", valid_21626145
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

proc call*(call_21626147: Call_CreateEventSourceMapping_21626136;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a mapping between an event source and an AWS Lambda function. Lambda reads items from the event source and triggers the function.</p> <p>For details about each event source type, see the following topics.</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html">Using AWS Lambda with Amazon DynamoDB</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html">Using AWS Lambda with Amazon Kinesis</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html">Using AWS Lambda with Amazon SQS</a> </p> </li> </ul> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> <li> <p> <code>ParallelizationFactor</code> - Process multiple batches from each shard concurrently.</p> </li> </ul>
  ## 
  let valid = call_21626147.validator(path, query, header, formData, body, _)
  let scheme = call_21626147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626147.makeUrl(scheme.get, call_21626147.host, call_21626147.base,
                               call_21626147.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626147, uri, valid, _)

proc call*(call_21626148: Call_CreateEventSourceMapping_21626136; body: JsonNode): Recallable =
  ## createEventSourceMapping
  ## <p>Creates a mapping between an event source and an AWS Lambda function. Lambda reads items from the event source and triggers the function.</p> <p>For details about each event source type, see the following topics.</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html">Using AWS Lambda with Amazon DynamoDB</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html">Using AWS Lambda with Amazon Kinesis</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html">Using AWS Lambda with Amazon SQS</a> </p> </li> </ul> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> <li> <p> <code>ParallelizationFactor</code> - Process multiple batches from each shard concurrently.</p> </li> </ul>
  ##   body: JObject (required)
  var body_21626149 = newJObject()
  if body != nil:
    body_21626149 = body
  result = call_21626148.call(nil, nil, nil, nil, body_21626149)

var createEventSourceMapping* = Call_CreateEventSourceMapping_21626136(
    name: "createEventSourceMapping", meth: HttpMethod.HttpPost,
    host: "lambda.amazonaws.com", route: "/2015-03-31/event-source-mappings/",
    validator: validate_CreateEventSourceMapping_21626137, base: "/",
    makeUrl: url_CreateEventSourceMapping_21626138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEventSourceMappings_21626119 = ref object of OpenApiRestCall_21625435
proc url_ListEventSourceMappings_21626121(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEventSourceMappings_21626120(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626122 = query.getOrDefault("FunctionName")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "FunctionName", valid_21626122
  var valid_21626123 = query.getOrDefault("EventSourceArn")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "EventSourceArn", valid_21626123
  var valid_21626124 = query.getOrDefault("Marker")
  valid_21626124 = validateParameter(valid_21626124, JString, required = false,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "Marker", valid_21626124
  var valid_21626125 = query.getOrDefault("MaxItems")
  valid_21626125 = validateParameter(valid_21626125, JInt, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "MaxItems", valid_21626125
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
  var valid_21626126 = header.getOrDefault("X-Amz-Date")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-Date", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-Security-Token", valid_21626127
  var valid_21626128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626128
  var valid_21626129 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "X-Amz-Algorithm", valid_21626129
  var valid_21626130 = header.getOrDefault("X-Amz-Signature")
  valid_21626130 = validateParameter(valid_21626130, JString, required = false,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "X-Amz-Signature", valid_21626130
  var valid_21626131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626131 = validateParameter(valid_21626131, JString, required = false,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626131
  var valid_21626132 = header.getOrDefault("X-Amz-Credential")
  valid_21626132 = validateParameter(valid_21626132, JString, required = false,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "X-Amz-Credential", valid_21626132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626133: Call_ListEventSourceMappings_21626119;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists event source mappings. Specify an <code>EventSourceArn</code> to only show event source mappings for a single event source.
  ## 
  let valid = call_21626133.validator(path, query, header, formData, body, _)
  let scheme = call_21626133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626133.makeUrl(scheme.get, call_21626133.host, call_21626133.base,
                               call_21626133.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626133, uri, valid, _)

proc call*(call_21626134: Call_ListEventSourceMappings_21626119;
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
  var query_21626135 = newJObject()
  add(query_21626135, "FunctionName", newJString(FunctionName))
  add(query_21626135, "EventSourceArn", newJString(EventSourceArn))
  add(query_21626135, "Marker", newJString(Marker))
  add(query_21626135, "MaxItems", newJInt(MaxItems))
  result = call_21626134.call(nil, query_21626135, nil, nil, nil)

var listEventSourceMappings* = Call_ListEventSourceMappings_21626119(
    name: "listEventSourceMappings", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com", route: "/2015-03-31/event-source-mappings/",
    validator: validate_ListEventSourceMappings_21626120, base: "/",
    makeUrl: url_ListEventSourceMappings_21626121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunction_21626150 = ref object of OpenApiRestCall_21625435
proc url_CreateFunction_21626152(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFunction_21626151(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626153 = header.getOrDefault("X-Amz-Date")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Date", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "X-Amz-Security-Token", valid_21626154
  var valid_21626155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-Algorithm", valid_21626156
  var valid_21626157 = header.getOrDefault("X-Amz-Signature")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Signature", valid_21626157
  var valid_21626158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626158
  var valid_21626159 = header.getOrDefault("X-Amz-Credential")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "X-Amz-Credential", valid_21626159
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

proc call*(call_21626161: Call_CreateFunction_21626150; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a Lambda function. To create a function, you need a <a href="https://docs.aws.amazon.com/lambda/latest/dg/deployment-package-v2.html">deployment package</a> and an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-permission-model.html#lambda-intro-execution-role">execution role</a>. The deployment package contains your function code. The execution role grants the function permission to use AWS services, such as Amazon CloudWatch Logs for log streaming and AWS X-Ray for request tracing.</p> <p>When you create a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute or so. During this time, you can't invoke or modify the function. The <code>State</code>, <code>StateReason</code>, and <code>StateReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the function is ready to invoke. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Function States</a>.</p> <p>A function has an unpublished version, and can have published versions and aliases. The unpublished version changes when you update your function's code and configuration. A published version is a snapshot of your function code and configuration that can't be changed. An alias is a named resource that maps to a version, and can be changed to map to a different version. Use the <code>Publish</code> parameter to create version <code>1</code> of your function from its initial configuration.</p> <p>The other parameters let you configure version-specific and function-level settings. You can modify version-specific settings later with <a>UpdateFunctionConfiguration</a>. Function-level settings apply to both the unpublished and published versions of the function, and include tags (<a>TagResource</a>) and per-function concurrency limits (<a>PutFunctionConcurrency</a>).</p> <p>If another account or an AWS service invokes your function, use <a>AddPermission</a> to grant permission by creating a resource-based IAM policy. You can grant permissions at the function level, on a version, or on an alias.</p> <p>To invoke your function directly, use <a>Invoke</a>. To invoke your function in response to events in other AWS services, create an event source mapping (<a>CreateEventSourceMapping</a>), or configure a function trigger in the other service. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-invocation.html">Invoking Functions</a>.</p>
  ## 
  let valid = call_21626161.validator(path, query, header, formData, body, _)
  let scheme = call_21626161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626161.makeUrl(scheme.get, call_21626161.host, call_21626161.base,
                               call_21626161.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626161, uri, valid, _)

proc call*(call_21626162: Call_CreateFunction_21626150; body: JsonNode): Recallable =
  ## createFunction
  ## <p>Creates a Lambda function. To create a function, you need a <a href="https://docs.aws.amazon.com/lambda/latest/dg/deployment-package-v2.html">deployment package</a> and an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-permission-model.html#lambda-intro-execution-role">execution role</a>. The deployment package contains your function code. The execution role grants the function permission to use AWS services, such as Amazon CloudWatch Logs for log streaming and AWS X-Ray for request tracing.</p> <p>When you create a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute or so. During this time, you can't invoke or modify the function. The <code>State</code>, <code>StateReason</code>, and <code>StateReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the function is ready to invoke. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Function States</a>.</p> <p>A function has an unpublished version, and can have published versions and aliases. The unpublished version changes when you update your function's code and configuration. A published version is a snapshot of your function code and configuration that can't be changed. An alias is a named resource that maps to a version, and can be changed to map to a different version. Use the <code>Publish</code> parameter to create version <code>1</code> of your function from its initial configuration.</p> <p>The other parameters let you configure version-specific and function-level settings. You can modify version-specific settings later with <a>UpdateFunctionConfiguration</a>. Function-level settings apply to both the unpublished and published versions of the function, and include tags (<a>TagResource</a>) and per-function concurrency limits (<a>PutFunctionConcurrency</a>).</p> <p>If another account or an AWS service invokes your function, use <a>AddPermission</a> to grant permission by creating a resource-based IAM policy. You can grant permissions at the function level, on a version, or on an alias.</p> <p>To invoke your function directly, use <a>Invoke</a>. To invoke your function in response to events in other AWS services, create an event source mapping (<a>CreateEventSourceMapping</a>), or configure a function trigger in the other service. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-invocation.html">Invoking Functions</a>.</p>
  ##   body: JObject (required)
  var body_21626163 = newJObject()
  if body != nil:
    body_21626163 = body
  result = call_21626162.call(nil, nil, nil, nil, body_21626163)

var createFunction* = Call_CreateFunction_21626150(name: "createFunction",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions", validator: validate_CreateFunction_21626151,
    base: "/", makeUrl: url_CreateFunction_21626152,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAlias_21626179 = ref object of OpenApiRestCall_21625435
proc url_UpdateAlias_21626181(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAlias_21626180(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626182 = path.getOrDefault("FunctionName")
  valid_21626182 = validateParameter(valid_21626182, JString, required = true,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "FunctionName", valid_21626182
  var valid_21626183 = path.getOrDefault("Name")
  valid_21626183 = validateParameter(valid_21626183, JString, required = true,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "Name", valid_21626183
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
  var valid_21626184 = header.getOrDefault("X-Amz-Date")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-Date", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Security-Token", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626186
  var valid_21626187 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626187 = validateParameter(valid_21626187, JString, required = false,
                                   default = nil)
  if valid_21626187 != nil:
    section.add "X-Amz-Algorithm", valid_21626187
  var valid_21626188 = header.getOrDefault("X-Amz-Signature")
  valid_21626188 = validateParameter(valid_21626188, JString, required = false,
                                   default = nil)
  if valid_21626188 != nil:
    section.add "X-Amz-Signature", valid_21626188
  var valid_21626189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626189
  var valid_21626190 = header.getOrDefault("X-Amz-Credential")
  valid_21626190 = validateParameter(valid_21626190, JString, required = false,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "X-Amz-Credential", valid_21626190
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

proc call*(call_21626192: Call_UpdateAlias_21626179; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the configuration of a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ## 
  let valid = call_21626192.validator(path, query, header, formData, body, _)
  let scheme = call_21626192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626192.makeUrl(scheme.get, call_21626192.host, call_21626192.base,
                               call_21626192.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626192, uri, valid, _)

proc call*(call_21626193: Call_UpdateAlias_21626179; FunctionName: string;
          Name: string; body: JsonNode): Recallable =
  ## updateAlias
  ## Updates the configuration of a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Name: string (required)
  ##       : The name of the alias.
  ##   body: JObject (required)
  var path_21626194 = newJObject()
  var body_21626195 = newJObject()
  add(path_21626194, "FunctionName", newJString(FunctionName))
  add(path_21626194, "Name", newJString(Name))
  if body != nil:
    body_21626195 = body
  result = call_21626193.call(path_21626194, nil, nil, nil, body_21626195)

var updateAlias* = Call_UpdateAlias_21626179(name: "updateAlias",
    meth: HttpMethod.HttpPut, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/aliases/{Name}",
    validator: validate_UpdateAlias_21626180, base: "/", makeUrl: url_UpdateAlias_21626181,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAlias_21626164 = ref object of OpenApiRestCall_21625435
proc url_GetAlias_21626166(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetAlias_21626165(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626167 = path.getOrDefault("FunctionName")
  valid_21626167 = validateParameter(valid_21626167, JString, required = true,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "FunctionName", valid_21626167
  var valid_21626168 = path.getOrDefault("Name")
  valid_21626168 = validateParameter(valid_21626168, JString, required = true,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "Name", valid_21626168
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
  var valid_21626169 = header.getOrDefault("X-Amz-Date")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "X-Amz-Date", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Security-Token", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-Algorithm", valid_21626172
  var valid_21626173 = header.getOrDefault("X-Amz-Signature")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "X-Amz-Signature", valid_21626173
  var valid_21626174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626174
  var valid_21626175 = header.getOrDefault("X-Amz-Credential")
  valid_21626175 = validateParameter(valid_21626175, JString, required = false,
                                   default = nil)
  if valid_21626175 != nil:
    section.add "X-Amz-Credential", valid_21626175
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626176: Call_GetAlias_21626164; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns details about a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ## 
  let valid = call_21626176.validator(path, query, header, formData, body, _)
  let scheme = call_21626176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626176.makeUrl(scheme.get, call_21626176.host, call_21626176.base,
                               call_21626176.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626176, uri, valid, _)

proc call*(call_21626177: Call_GetAlias_21626164; FunctionName: string; Name: string): Recallable =
  ## getAlias
  ## Returns details about a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Name: string (required)
  ##       : The name of the alias.
  var path_21626178 = newJObject()
  add(path_21626178, "FunctionName", newJString(FunctionName))
  add(path_21626178, "Name", newJString(Name))
  result = call_21626177.call(path_21626178, nil, nil, nil, nil)

var getAlias* = Call_GetAlias_21626164(name: "getAlias", meth: HttpMethod.HttpGet,
                                    host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases/{Name}",
                                    validator: validate_GetAlias_21626165,
                                    base: "/", makeUrl: url_GetAlias_21626166,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAlias_21626196 = ref object of OpenApiRestCall_21625435
proc url_DeleteAlias_21626198(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAlias_21626197(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626199 = path.getOrDefault("FunctionName")
  valid_21626199 = validateParameter(valid_21626199, JString, required = true,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "FunctionName", valid_21626199
  var valid_21626200 = path.getOrDefault("Name")
  valid_21626200 = validateParameter(valid_21626200, JString, required = true,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "Name", valid_21626200
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
  var valid_21626201 = header.getOrDefault("X-Amz-Date")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-Date", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Security-Token", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626203
  var valid_21626204 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "X-Amz-Algorithm", valid_21626204
  var valid_21626205 = header.getOrDefault("X-Amz-Signature")
  valid_21626205 = validateParameter(valid_21626205, JString, required = false,
                                   default = nil)
  if valid_21626205 != nil:
    section.add "X-Amz-Signature", valid_21626205
  var valid_21626206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626206 = validateParameter(valid_21626206, JString, required = false,
                                   default = nil)
  if valid_21626206 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626206
  var valid_21626207 = header.getOrDefault("X-Amz-Credential")
  valid_21626207 = validateParameter(valid_21626207, JString, required = false,
                                   default = nil)
  if valid_21626207 != nil:
    section.add "X-Amz-Credential", valid_21626207
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626208: Call_DeleteAlias_21626196; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ## 
  let valid = call_21626208.validator(path, query, header, formData, body, _)
  let scheme = call_21626208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626208.makeUrl(scheme.get, call_21626208.host, call_21626208.base,
                               call_21626208.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626208, uri, valid, _)

proc call*(call_21626209: Call_DeleteAlias_21626196; FunctionName: string;
          Name: string): Recallable =
  ## deleteAlias
  ## Deletes a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Name: string (required)
  ##       : The name of the alias.
  var path_21626210 = newJObject()
  add(path_21626210, "FunctionName", newJString(FunctionName))
  add(path_21626210, "Name", newJString(Name))
  result = call_21626209.call(path_21626210, nil, nil, nil, nil)

var deleteAlias* = Call_DeleteAlias_21626196(name: "deleteAlias",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/aliases/{Name}",
    validator: validate_DeleteAlias_21626197, base: "/", makeUrl: url_DeleteAlias_21626198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEventSourceMapping_21626225 = ref object of OpenApiRestCall_21625435
proc url_UpdateEventSourceMapping_21626227(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_UpdateEventSourceMapping_21626226(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates an event source mapping. You can change the function that AWS Lambda invokes, or pause invocation and resume later from the same location.</p> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> <li> <p> <code>ParallelizationFactor</code> - Process multiple batches from each shard concurrently.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UUID: JString (required)
  ##       : The identifier of the event source mapping.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UUID` field"
  var valid_21626228 = path.getOrDefault("UUID")
  valid_21626228 = validateParameter(valid_21626228, JString, required = true,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "UUID", valid_21626228
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
  var valid_21626229 = header.getOrDefault("X-Amz-Date")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-Date", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Security-Token", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Algorithm", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-Signature")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-Signature", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626234
  var valid_21626235 = header.getOrDefault("X-Amz-Credential")
  valid_21626235 = validateParameter(valid_21626235, JString, required = false,
                                   default = nil)
  if valid_21626235 != nil:
    section.add "X-Amz-Credential", valid_21626235
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

proc call*(call_21626237: Call_UpdateEventSourceMapping_21626225;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates an event source mapping. You can change the function that AWS Lambda invokes, or pause invocation and resume later from the same location.</p> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> <li> <p> <code>ParallelizationFactor</code> - Process multiple batches from each shard concurrently.</p> </li> </ul>
  ## 
  let valid = call_21626237.validator(path, query, header, formData, body, _)
  let scheme = call_21626237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626237.makeUrl(scheme.get, call_21626237.host, call_21626237.base,
                               call_21626237.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626237, uri, valid, _)

proc call*(call_21626238: Call_UpdateEventSourceMapping_21626225; UUID: string;
          body: JsonNode): Recallable =
  ## updateEventSourceMapping
  ## <p>Updates an event source mapping. You can change the function that AWS Lambda invokes, or pause invocation and resume later from the same location.</p> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> <li> <p> <code>ParallelizationFactor</code> - Process multiple batches from each shard concurrently.</p> </li> </ul>
  ##   UUID: string (required)
  ##       : The identifier of the event source mapping.
  ##   body: JObject (required)
  var path_21626239 = newJObject()
  var body_21626240 = newJObject()
  add(path_21626239, "UUID", newJString(UUID))
  if body != nil:
    body_21626240 = body
  result = call_21626238.call(path_21626239, nil, nil, nil, body_21626240)

var updateEventSourceMapping* = Call_UpdateEventSourceMapping_21626225(
    name: "updateEventSourceMapping", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/event-source-mappings/{UUID}",
    validator: validate_UpdateEventSourceMapping_21626226, base: "/",
    makeUrl: url_UpdateEventSourceMapping_21626227,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventSourceMapping_21626211 = ref object of OpenApiRestCall_21625435
proc url_GetEventSourceMapping_21626213(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
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

proc validate_GetEventSourceMapping_21626212(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns details about an event source mapping. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UUID: JString (required)
  ##       : The identifier of the event source mapping.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UUID` field"
  var valid_21626214 = path.getOrDefault("UUID")
  valid_21626214 = validateParameter(valid_21626214, JString, required = true,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "UUID", valid_21626214
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
  var valid_21626215 = header.getOrDefault("X-Amz-Date")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Date", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Security-Token", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-Algorithm", valid_21626218
  var valid_21626219 = header.getOrDefault("X-Amz-Signature")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Signature", valid_21626219
  var valid_21626220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626220 = validateParameter(valid_21626220, JString, required = false,
                                   default = nil)
  if valid_21626220 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626220
  var valid_21626221 = header.getOrDefault("X-Amz-Credential")
  valid_21626221 = validateParameter(valid_21626221, JString, required = false,
                                   default = nil)
  if valid_21626221 != nil:
    section.add "X-Amz-Credential", valid_21626221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626222: Call_GetEventSourceMapping_21626211;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns details about an event source mapping. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.
  ## 
  let valid = call_21626222.validator(path, query, header, formData, body, _)
  let scheme = call_21626222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626222.makeUrl(scheme.get, call_21626222.host, call_21626222.base,
                               call_21626222.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626222, uri, valid, _)

proc call*(call_21626223: Call_GetEventSourceMapping_21626211; UUID: string): Recallable =
  ## getEventSourceMapping
  ## Returns details about an event source mapping. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.
  ##   UUID: string (required)
  ##       : The identifier of the event source mapping.
  var path_21626224 = newJObject()
  add(path_21626224, "UUID", newJString(UUID))
  result = call_21626223.call(path_21626224, nil, nil, nil, nil)

var getEventSourceMapping* = Call_GetEventSourceMapping_21626211(
    name: "getEventSourceMapping", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/event-source-mappings/{UUID}",
    validator: validate_GetEventSourceMapping_21626212, base: "/",
    makeUrl: url_GetEventSourceMapping_21626213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventSourceMapping_21626241 = ref object of OpenApiRestCall_21625435
proc url_DeleteEventSourceMapping_21626243(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_DeleteEventSourceMapping_21626242(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-invocation-modes.html">event source mapping</a>. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.</p> <p>When you delete an event source mapping, it enters a <code>Deleting</code> state and might not be completely deleted for several seconds.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UUID: JString (required)
  ##       : The identifier of the event source mapping.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UUID` field"
  var valid_21626244 = path.getOrDefault("UUID")
  valid_21626244 = validateParameter(valid_21626244, JString, required = true,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "UUID", valid_21626244
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
  var valid_21626245 = header.getOrDefault("X-Amz-Date")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Date", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-Security-Token", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-Algorithm", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Signature")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Signature", valid_21626249
  var valid_21626250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626250
  var valid_21626251 = header.getOrDefault("X-Amz-Credential")
  valid_21626251 = validateParameter(valid_21626251, JString, required = false,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "X-Amz-Credential", valid_21626251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626252: Call_DeleteEventSourceMapping_21626241;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-invocation-modes.html">event source mapping</a>. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.</p> <p>When you delete an event source mapping, it enters a <code>Deleting</code> state and might not be completely deleted for several seconds.</p>
  ## 
  let valid = call_21626252.validator(path, query, header, formData, body, _)
  let scheme = call_21626252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626252.makeUrl(scheme.get, call_21626252.host, call_21626252.base,
                               call_21626252.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626252, uri, valid, _)

proc call*(call_21626253: Call_DeleteEventSourceMapping_21626241; UUID: string): Recallable =
  ## deleteEventSourceMapping
  ## <p>Deletes an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-invocation-modes.html">event source mapping</a>. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.</p> <p>When you delete an event source mapping, it enters a <code>Deleting</code> state and might not be completely deleted for several seconds.</p>
  ##   UUID: string (required)
  ##       : The identifier of the event source mapping.
  var path_21626254 = newJObject()
  add(path_21626254, "UUID", newJString(UUID))
  result = call_21626253.call(path_21626254, nil, nil, nil, nil)

var deleteEventSourceMapping* = Call_DeleteEventSourceMapping_21626241(
    name: "deleteEventSourceMapping", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/event-source-mappings/{UUID}",
    validator: validate_DeleteEventSourceMapping_21626242, base: "/",
    makeUrl: url_DeleteEventSourceMapping_21626243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunction_21626255 = ref object of OpenApiRestCall_21625435
proc url_GetFunction_21626257(protocol: Scheme; host: string; base: string;
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

proc validate_GetFunction_21626256(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626258 = path.getOrDefault("FunctionName")
  valid_21626258 = validateParameter(valid_21626258, JString, required = true,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "FunctionName", valid_21626258
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to get details about a published version of the function.
  section = newJObject()
  var valid_21626259 = query.getOrDefault("Qualifier")
  valid_21626259 = validateParameter(valid_21626259, JString, required = false,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "Qualifier", valid_21626259
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
  var valid_21626260 = header.getOrDefault("X-Amz-Date")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "X-Amz-Date", valid_21626260
  var valid_21626261 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "X-Amz-Security-Token", valid_21626261
  var valid_21626262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626262
  var valid_21626263 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "X-Amz-Algorithm", valid_21626263
  var valid_21626264 = header.getOrDefault("X-Amz-Signature")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-Signature", valid_21626264
  var valid_21626265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626265 = validateParameter(valid_21626265, JString, required = false,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626265
  var valid_21626266 = header.getOrDefault("X-Amz-Credential")
  valid_21626266 = validateParameter(valid_21626266, JString, required = false,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "X-Amz-Credential", valid_21626266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626267: Call_GetFunction_21626255; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about the function or function version, with a link to download the deployment package that's valid for 10 minutes. If you specify a function version, only details that are specific to that version are returned.
  ## 
  let valid = call_21626267.validator(path, query, header, formData, body, _)
  let scheme = call_21626267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626267.makeUrl(scheme.get, call_21626267.host, call_21626267.base,
                               call_21626267.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626267, uri, valid, _)

proc call*(call_21626268: Call_GetFunction_21626255; FunctionName: string;
          Qualifier: string = ""): Recallable =
  ## getFunction
  ## Returns information about the function or function version, with a link to download the deployment package that's valid for 10 minutes. If you specify a function version, only details that are specific to that version are returned.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to get details about a published version of the function.
  var path_21626269 = newJObject()
  var query_21626270 = newJObject()
  add(path_21626269, "FunctionName", newJString(FunctionName))
  add(query_21626270, "Qualifier", newJString(Qualifier))
  result = call_21626268.call(path_21626269, query_21626270, nil, nil, nil)

var getFunction* = Call_GetFunction_21626255(name: "getFunction",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}",
    validator: validate_GetFunction_21626256, base: "/", makeUrl: url_GetFunction_21626257,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunction_21626271 = ref object of OpenApiRestCall_21625435
proc url_DeleteFunction_21626273(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFunction_21626272(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626274 = path.getOrDefault("FunctionName")
  valid_21626274 = validateParameter(valid_21626274, JString, required = true,
                                   default = nil)
  if valid_21626274 != nil:
    section.add "FunctionName", valid_21626274
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version to delete. You can't delete a version that's referenced by an alias.
  section = newJObject()
  var valid_21626275 = query.getOrDefault("Qualifier")
  valid_21626275 = validateParameter(valid_21626275, JString, required = false,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "Qualifier", valid_21626275
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
  var valid_21626276 = header.getOrDefault("X-Amz-Date")
  valid_21626276 = validateParameter(valid_21626276, JString, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "X-Amz-Date", valid_21626276
  var valid_21626277 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "X-Amz-Security-Token", valid_21626277
  var valid_21626278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626278 = validateParameter(valid_21626278, JString, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626278
  var valid_21626279 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "X-Amz-Algorithm", valid_21626279
  var valid_21626280 = header.getOrDefault("X-Amz-Signature")
  valid_21626280 = validateParameter(valid_21626280, JString, required = false,
                                   default = nil)
  if valid_21626280 != nil:
    section.add "X-Amz-Signature", valid_21626280
  var valid_21626281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626281 = validateParameter(valid_21626281, JString, required = false,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626281
  var valid_21626282 = header.getOrDefault("X-Amz-Credential")
  valid_21626282 = validateParameter(valid_21626282, JString, required = false,
                                   default = nil)
  if valid_21626282 != nil:
    section.add "X-Amz-Credential", valid_21626282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626283: Call_DeleteFunction_21626271; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes a Lambda function. To delete a specific function version, use the <code>Qualifier</code> parameter. Otherwise, all versions and aliases are deleted.</p> <p>To delete Lambda event source mappings that invoke a function, use <a>DeleteEventSourceMapping</a>. For AWS services and resources that invoke your function directly, delete the trigger in the service where you originally configured it.</p>
  ## 
  let valid = call_21626283.validator(path, query, header, formData, body, _)
  let scheme = call_21626283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626283.makeUrl(scheme.get, call_21626283.host, call_21626283.base,
                               call_21626283.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626283, uri, valid, _)

proc call*(call_21626284: Call_DeleteFunction_21626271; FunctionName: string;
          Qualifier: string = ""): Recallable =
  ## deleteFunction
  ## <p>Deletes a Lambda function. To delete a specific function version, use the <code>Qualifier</code> parameter. Otherwise, all versions and aliases are deleted.</p> <p>To delete Lambda event source mappings that invoke a function, use <a>DeleteEventSourceMapping</a>. For AWS services and resources that invoke your function directly, delete the trigger in the service where you originally configured it.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function or version.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:1</code> (with version).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version to delete. You can't delete a version that's referenced by an alias.
  var path_21626285 = newJObject()
  var query_21626286 = newJObject()
  add(path_21626285, "FunctionName", newJString(FunctionName))
  add(query_21626286, "Qualifier", newJString(Qualifier))
  result = call_21626284.call(path_21626285, query_21626286, nil, nil, nil)

var deleteFunction* = Call_DeleteFunction_21626271(name: "deleteFunction",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}",
    validator: validate_DeleteFunction_21626272, base: "/",
    makeUrl: url_DeleteFunction_21626273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutFunctionConcurrency_21626287 = ref object of OpenApiRestCall_21625435
proc url_PutFunctionConcurrency_21626289(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
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

proc validate_PutFunctionConcurrency_21626288(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626290 = path.getOrDefault("FunctionName")
  valid_21626290 = validateParameter(valid_21626290, JString, required = true,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "FunctionName", valid_21626290
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
  var valid_21626291 = header.getOrDefault("X-Amz-Date")
  valid_21626291 = validateParameter(valid_21626291, JString, required = false,
                                   default = nil)
  if valid_21626291 != nil:
    section.add "X-Amz-Date", valid_21626291
  var valid_21626292 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626292 = validateParameter(valid_21626292, JString, required = false,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "X-Amz-Security-Token", valid_21626292
  var valid_21626293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-Algorithm", valid_21626294
  var valid_21626295 = header.getOrDefault("X-Amz-Signature")
  valid_21626295 = validateParameter(valid_21626295, JString, required = false,
                                   default = nil)
  if valid_21626295 != nil:
    section.add "X-Amz-Signature", valid_21626295
  var valid_21626296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626296 = validateParameter(valid_21626296, JString, required = false,
                                   default = nil)
  if valid_21626296 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626296
  var valid_21626297 = header.getOrDefault("X-Amz-Credential")
  valid_21626297 = validateParameter(valid_21626297, JString, required = false,
                                   default = nil)
  if valid_21626297 != nil:
    section.add "X-Amz-Credential", valid_21626297
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

proc call*(call_21626299: Call_PutFunctionConcurrency_21626287;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Sets the maximum number of simultaneous executions for a function, and reserves capacity for that concurrency level.</p> <p>Concurrency settings apply to the function as a whole, including all published versions and the unpublished version. Reserving concurrency both ensures that your function has capacity to process the specified number of events simultaneously, and prevents it from scaling beyond that level. Use <a>GetFunction</a> to see the current setting for a function.</p> <p>Use <a>GetAccountSettings</a> to see your Regional concurrency limit. You can reserve concurrency for as many functions as you like, as long as you leave at least 100 simultaneous executions unreserved for functions that aren't configured with a per-function limit. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/concurrent-executions.html">Managing Concurrency</a>.</p>
  ## 
  let valid = call_21626299.validator(path, query, header, formData, body, _)
  let scheme = call_21626299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626299.makeUrl(scheme.get, call_21626299.host, call_21626299.base,
                               call_21626299.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626299, uri, valid, _)

proc call*(call_21626300: Call_PutFunctionConcurrency_21626287;
          FunctionName: string; body: JsonNode): Recallable =
  ## putFunctionConcurrency
  ## <p>Sets the maximum number of simultaneous executions for a function, and reserves capacity for that concurrency level.</p> <p>Concurrency settings apply to the function as a whole, including all published versions and the unpublished version. Reserving concurrency both ensures that your function has capacity to process the specified number of events simultaneously, and prevents it from scaling beyond that level. Use <a>GetFunction</a> to see the current setting for a function.</p> <p>Use <a>GetAccountSettings</a> to see your Regional concurrency limit. You can reserve concurrency for as many functions as you like, as long as you leave at least 100 simultaneous executions unreserved for functions that aren't configured with a per-function limit. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/concurrent-executions.html">Managing Concurrency</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_21626301 = newJObject()
  var body_21626302 = newJObject()
  add(path_21626301, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_21626302 = body
  result = call_21626300.call(path_21626301, nil, nil, nil, body_21626302)

var putFunctionConcurrency* = Call_PutFunctionConcurrency_21626287(
    name: "putFunctionConcurrency", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2017-10-31/functions/{FunctionName}/concurrency",
    validator: validate_PutFunctionConcurrency_21626288, base: "/",
    makeUrl: url_PutFunctionConcurrency_21626289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunctionConcurrency_21626303 = ref object of OpenApiRestCall_21625435
proc url_DeleteFunctionConcurrency_21626305(protocol: Scheme; host: string;
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

proc validate_DeleteFunctionConcurrency_21626304(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626306 = path.getOrDefault("FunctionName")
  valid_21626306 = validateParameter(valid_21626306, JString, required = true,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "FunctionName", valid_21626306
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
  var valid_21626307 = header.getOrDefault("X-Amz-Date")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "X-Amz-Date", valid_21626307
  var valid_21626308 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "X-Amz-Security-Token", valid_21626308
  var valid_21626309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626309
  var valid_21626310 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626310 = validateParameter(valid_21626310, JString, required = false,
                                   default = nil)
  if valid_21626310 != nil:
    section.add "X-Amz-Algorithm", valid_21626310
  var valid_21626311 = header.getOrDefault("X-Amz-Signature")
  valid_21626311 = validateParameter(valid_21626311, JString, required = false,
                                   default = nil)
  if valid_21626311 != nil:
    section.add "X-Amz-Signature", valid_21626311
  var valid_21626312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626312 = validateParameter(valid_21626312, JString, required = false,
                                   default = nil)
  if valid_21626312 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626312
  var valid_21626313 = header.getOrDefault("X-Amz-Credential")
  valid_21626313 = validateParameter(valid_21626313, JString, required = false,
                                   default = nil)
  if valid_21626313 != nil:
    section.add "X-Amz-Credential", valid_21626313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626314: Call_DeleteFunctionConcurrency_21626303;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a concurrent execution limit from a function.
  ## 
  let valid = call_21626314.validator(path, query, header, formData, body, _)
  let scheme = call_21626314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626314.makeUrl(scheme.get, call_21626314.host, call_21626314.base,
                               call_21626314.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626314, uri, valid, _)

proc call*(call_21626315: Call_DeleteFunctionConcurrency_21626303;
          FunctionName: string): Recallable =
  ## deleteFunctionConcurrency
  ## Removes a concurrent execution limit from a function.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  var path_21626316 = newJObject()
  add(path_21626316, "FunctionName", newJString(FunctionName))
  result = call_21626315.call(path_21626316, nil, nil, nil, nil)

var deleteFunctionConcurrency* = Call_DeleteFunctionConcurrency_21626303(
    name: "deleteFunctionConcurrency", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com",
    route: "/2017-10-31/functions/{FunctionName}/concurrency",
    validator: validate_DeleteFunctionConcurrency_21626304, base: "/",
    makeUrl: url_DeleteFunctionConcurrency_21626305,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutFunctionEventInvokeConfig_21626333 = ref object of OpenApiRestCall_21625435
proc url_PutFunctionEventInvokeConfig_21626335(protocol: Scheme; host: string;
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

proc validate_PutFunctionEventInvokeConfig_21626334(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626336 = path.getOrDefault("FunctionName")
  valid_21626336 = validateParameter(valid_21626336, JString, required = true,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "FunctionName", valid_21626336
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : A version number or alias name.
  section = newJObject()
  var valid_21626337 = query.getOrDefault("Qualifier")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "Qualifier", valid_21626337
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_21626346: Call_PutFunctionEventInvokeConfig_21626333;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Configures options for <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a> on a function, version, or alias. If a configuration already exists for a function, version, or alias, this operation overwrites it. If you exclude any settings, they are removed. To set one option without affecting existing settings for other options, use <a>PutFunctionEventInvokeConfig</a>.</p> <p>By default, Lambda retries an asynchronous invocation twice if the function returns an error. It retains events in a queue for up to six hours. When an event fails all processing attempts or stays in the asynchronous invocation queue for too long, Lambda discards it. To retain discarded events, configure a dead-letter queue with <a>UpdateFunctionConfiguration</a>.</p> <p>To send an invocation record to a queue, topic, function, or event bus, specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#invocation-async-destinations">destination</a>. You can configure separate destinations for successful invocations (on-success) and events that fail all processing attempts (on-failure). You can configure destinations in addition to or instead of a dead-letter queue.</p>
  ## 
  let valid = call_21626346.validator(path, query, header, formData, body, _)
  let scheme = call_21626346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626346.makeUrl(scheme.get, call_21626346.host, call_21626346.base,
                               call_21626346.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626346, uri, valid, _)

proc call*(call_21626347: Call_PutFunctionEventInvokeConfig_21626333;
          FunctionName: string; body: JsonNode; Qualifier: string = ""): Recallable =
  ## putFunctionEventInvokeConfig
  ## <p>Configures options for <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a> on a function, version, or alias. If a configuration already exists for a function, version, or alias, this operation overwrites it. If you exclude any settings, they are removed. To set one option without affecting existing settings for other options, use <a>PutFunctionEventInvokeConfig</a>.</p> <p>By default, Lambda retries an asynchronous invocation twice if the function returns an error. It retains events in a queue for up to six hours. When an event fails all processing attempts or stays in the asynchronous invocation queue for too long, Lambda discards it. To retain discarded events, configure a dead-letter queue with <a>UpdateFunctionConfiguration</a>.</p> <p>To send an invocation record to a queue, topic, function, or event bus, specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#invocation-async-destinations">destination</a>. You can configure separate destinations for successful invocations (on-success) and events that fail all processing attempts (on-failure). You can configure destinations in addition to or instead of a dead-letter queue.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : A version number or alias name.
  ##   body: JObject (required)
  var path_21626348 = newJObject()
  var query_21626349 = newJObject()
  var body_21626350 = newJObject()
  add(path_21626348, "FunctionName", newJString(FunctionName))
  add(query_21626349, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_21626350 = body
  result = call_21626347.call(path_21626348, query_21626349, nil, nil, body_21626350)

var putFunctionEventInvokeConfig* = Call_PutFunctionEventInvokeConfig_21626333(
    name: "putFunctionEventInvokeConfig", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config",
    validator: validate_PutFunctionEventInvokeConfig_21626334, base: "/",
    makeUrl: url_PutFunctionEventInvokeConfig_21626335,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionEventInvokeConfig_21626351 = ref object of OpenApiRestCall_21625435
proc url_UpdateFunctionEventInvokeConfig_21626353(protocol: Scheme; host: string;
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

proc validate_UpdateFunctionEventInvokeConfig_21626352(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626354 = path.getOrDefault("FunctionName")
  valid_21626354 = validateParameter(valid_21626354, JString, required = true,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "FunctionName", valid_21626354
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : A version number or alias name.
  section = newJObject()
  var valid_21626355 = query.getOrDefault("Qualifier")
  valid_21626355 = validateParameter(valid_21626355, JString, required = false,
                                   default = nil)
  if valid_21626355 != nil:
    section.add "Qualifier", valid_21626355
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
  var valid_21626356 = header.getOrDefault("X-Amz-Date")
  valid_21626356 = validateParameter(valid_21626356, JString, required = false,
                                   default = nil)
  if valid_21626356 != nil:
    section.add "X-Amz-Date", valid_21626356
  var valid_21626357 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626357 = validateParameter(valid_21626357, JString, required = false,
                                   default = nil)
  if valid_21626357 != nil:
    section.add "X-Amz-Security-Token", valid_21626357
  var valid_21626358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626358 = validateParameter(valid_21626358, JString, required = false,
                                   default = nil)
  if valid_21626358 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626358
  var valid_21626359 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626359 = validateParameter(valid_21626359, JString, required = false,
                                   default = nil)
  if valid_21626359 != nil:
    section.add "X-Amz-Algorithm", valid_21626359
  var valid_21626360 = header.getOrDefault("X-Amz-Signature")
  valid_21626360 = validateParameter(valid_21626360, JString, required = false,
                                   default = nil)
  if valid_21626360 != nil:
    section.add "X-Amz-Signature", valid_21626360
  var valid_21626361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626361 = validateParameter(valid_21626361, JString, required = false,
                                   default = nil)
  if valid_21626361 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626361
  var valid_21626362 = header.getOrDefault("X-Amz-Credential")
  valid_21626362 = validateParameter(valid_21626362, JString, required = false,
                                   default = nil)
  if valid_21626362 != nil:
    section.add "X-Amz-Credential", valid_21626362
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

proc call*(call_21626364: Call_UpdateFunctionEventInvokeConfig_21626351;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  let valid = call_21626364.validator(path, query, header, formData, body, _)
  let scheme = call_21626364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626364.makeUrl(scheme.get, call_21626364.host, call_21626364.base,
                               call_21626364.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626364, uri, valid, _)

proc call*(call_21626365: Call_UpdateFunctionEventInvokeConfig_21626351;
          FunctionName: string; body: JsonNode; Qualifier: string = ""): Recallable =
  ## updateFunctionEventInvokeConfig
  ## <p>Updates the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : A version number or alias name.
  ##   body: JObject (required)
  var path_21626366 = newJObject()
  var query_21626367 = newJObject()
  var body_21626368 = newJObject()
  add(path_21626366, "FunctionName", newJString(FunctionName))
  add(query_21626367, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_21626368 = body
  result = call_21626365.call(path_21626366, query_21626367, nil, nil, body_21626368)

var updateFunctionEventInvokeConfig* = Call_UpdateFunctionEventInvokeConfig_21626351(
    name: "updateFunctionEventInvokeConfig", meth: HttpMethod.HttpPost,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config",
    validator: validate_UpdateFunctionEventInvokeConfig_21626352, base: "/",
    makeUrl: url_UpdateFunctionEventInvokeConfig_21626353,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionEventInvokeConfig_21626317 = ref object of OpenApiRestCall_21625435
proc url_GetFunctionEventInvokeConfig_21626319(protocol: Scheme; host: string;
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

proc validate_GetFunctionEventInvokeConfig_21626318(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626320 = path.getOrDefault("FunctionName")
  valid_21626320 = validateParameter(valid_21626320, JString, required = true,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "FunctionName", valid_21626320
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : A version number or alias name.
  section = newJObject()
  var valid_21626321 = query.getOrDefault("Qualifier")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "Qualifier", valid_21626321
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
  var valid_21626322 = header.getOrDefault("X-Amz-Date")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "X-Amz-Date", valid_21626322
  var valid_21626323 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626323 = validateParameter(valid_21626323, JString, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "X-Amz-Security-Token", valid_21626323
  var valid_21626324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626324
  var valid_21626325 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626325 = validateParameter(valid_21626325, JString, required = false,
                                   default = nil)
  if valid_21626325 != nil:
    section.add "X-Amz-Algorithm", valid_21626325
  var valid_21626326 = header.getOrDefault("X-Amz-Signature")
  valid_21626326 = validateParameter(valid_21626326, JString, required = false,
                                   default = nil)
  if valid_21626326 != nil:
    section.add "X-Amz-Signature", valid_21626326
  var valid_21626327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626327 = validateParameter(valid_21626327, JString, required = false,
                                   default = nil)
  if valid_21626327 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626327
  var valid_21626328 = header.getOrDefault("X-Amz-Credential")
  valid_21626328 = validateParameter(valid_21626328, JString, required = false,
                                   default = nil)
  if valid_21626328 != nil:
    section.add "X-Amz-Credential", valid_21626328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626329: Call_GetFunctionEventInvokeConfig_21626317;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  let valid = call_21626329.validator(path, query, header, formData, body, _)
  let scheme = call_21626329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626329.makeUrl(scheme.get, call_21626329.host, call_21626329.base,
                               call_21626329.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626329, uri, valid, _)

proc call*(call_21626330: Call_GetFunctionEventInvokeConfig_21626317;
          FunctionName: string; Qualifier: string = ""): Recallable =
  ## getFunctionEventInvokeConfig
  ## <p>Retrieves the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : A version number or alias name.
  var path_21626331 = newJObject()
  var query_21626332 = newJObject()
  add(path_21626331, "FunctionName", newJString(FunctionName))
  add(query_21626332, "Qualifier", newJString(Qualifier))
  result = call_21626330.call(path_21626331, query_21626332, nil, nil, nil)

var getFunctionEventInvokeConfig* = Call_GetFunctionEventInvokeConfig_21626317(
    name: "getFunctionEventInvokeConfig", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config",
    validator: validate_GetFunctionEventInvokeConfig_21626318, base: "/",
    makeUrl: url_GetFunctionEventInvokeConfig_21626319,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunctionEventInvokeConfig_21626369 = ref object of OpenApiRestCall_21625435
proc url_DeleteFunctionEventInvokeConfig_21626371(protocol: Scheme; host: string;
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

proc validate_DeleteFunctionEventInvokeConfig_21626370(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626372 = path.getOrDefault("FunctionName")
  valid_21626372 = validateParameter(valid_21626372, JString, required = true,
                                   default = nil)
  if valid_21626372 != nil:
    section.add "FunctionName", valid_21626372
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : A version number or alias name.
  section = newJObject()
  var valid_21626373 = query.getOrDefault("Qualifier")
  valid_21626373 = validateParameter(valid_21626373, JString, required = false,
                                   default = nil)
  if valid_21626373 != nil:
    section.add "Qualifier", valid_21626373
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
  var valid_21626374 = header.getOrDefault("X-Amz-Date")
  valid_21626374 = validateParameter(valid_21626374, JString, required = false,
                                   default = nil)
  if valid_21626374 != nil:
    section.add "X-Amz-Date", valid_21626374
  var valid_21626375 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626375 = validateParameter(valid_21626375, JString, required = false,
                                   default = nil)
  if valid_21626375 != nil:
    section.add "X-Amz-Security-Token", valid_21626375
  var valid_21626376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626376 = validateParameter(valid_21626376, JString, required = false,
                                   default = nil)
  if valid_21626376 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626376
  var valid_21626377 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626377 = validateParameter(valid_21626377, JString, required = false,
                                   default = nil)
  if valid_21626377 != nil:
    section.add "X-Amz-Algorithm", valid_21626377
  var valid_21626378 = header.getOrDefault("X-Amz-Signature")
  valid_21626378 = validateParameter(valid_21626378, JString, required = false,
                                   default = nil)
  if valid_21626378 != nil:
    section.add "X-Amz-Signature", valid_21626378
  var valid_21626379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626379 = validateParameter(valid_21626379, JString, required = false,
                                   default = nil)
  if valid_21626379 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626379
  var valid_21626380 = header.getOrDefault("X-Amz-Credential")
  valid_21626380 = validateParameter(valid_21626380, JString, required = false,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "X-Amz-Credential", valid_21626380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626381: Call_DeleteFunctionEventInvokeConfig_21626369;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  let valid = call_21626381.validator(path, query, header, formData, body, _)
  let scheme = call_21626381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626381.makeUrl(scheme.get, call_21626381.host, call_21626381.base,
                               call_21626381.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626381, uri, valid, _)

proc call*(call_21626382: Call_DeleteFunctionEventInvokeConfig_21626369;
          FunctionName: string; Qualifier: string = ""): Recallable =
  ## deleteFunctionEventInvokeConfig
  ## <p>Deletes the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : A version number or alias name.
  var path_21626383 = newJObject()
  var query_21626384 = newJObject()
  add(path_21626383, "FunctionName", newJString(FunctionName))
  add(query_21626384, "Qualifier", newJString(Qualifier))
  result = call_21626382.call(path_21626383, query_21626384, nil, nil, nil)

var deleteFunctionEventInvokeConfig* = Call_DeleteFunctionEventInvokeConfig_21626369(
    name: "deleteFunctionEventInvokeConfig", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config",
    validator: validate_DeleteFunctionEventInvokeConfig_21626370, base: "/",
    makeUrl: url_DeleteFunctionEventInvokeConfig_21626371,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLayerVersion_21626385 = ref object of OpenApiRestCall_21625435
proc url_GetLayerVersion_21626387(protocol: Scheme; host: string; base: string;
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

proc validate_GetLayerVersion_21626386(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   VersionNumber: JInt (required)
  ##                : The version number.
  ##   LayerName: JString (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `VersionNumber` field"
  var valid_21626388 = path.getOrDefault("VersionNumber")
  valid_21626388 = validateParameter(valid_21626388, JInt, required = true,
                                   default = nil)
  if valid_21626388 != nil:
    section.add "VersionNumber", valid_21626388
  var valid_21626389 = path.getOrDefault("LayerName")
  valid_21626389 = validateParameter(valid_21626389, JString, required = true,
                                   default = nil)
  if valid_21626389 != nil:
    section.add "LayerName", valid_21626389
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
  var valid_21626390 = header.getOrDefault("X-Amz-Date")
  valid_21626390 = validateParameter(valid_21626390, JString, required = false,
                                   default = nil)
  if valid_21626390 != nil:
    section.add "X-Amz-Date", valid_21626390
  var valid_21626391 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626391 = validateParameter(valid_21626391, JString, required = false,
                                   default = nil)
  if valid_21626391 != nil:
    section.add "X-Amz-Security-Token", valid_21626391
  var valid_21626392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626392 = validateParameter(valid_21626392, JString, required = false,
                                   default = nil)
  if valid_21626392 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626392
  var valid_21626393 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626393 = validateParameter(valid_21626393, JString, required = false,
                                   default = nil)
  if valid_21626393 != nil:
    section.add "X-Amz-Algorithm", valid_21626393
  var valid_21626394 = header.getOrDefault("X-Amz-Signature")
  valid_21626394 = validateParameter(valid_21626394, JString, required = false,
                                   default = nil)
  if valid_21626394 != nil:
    section.add "X-Amz-Signature", valid_21626394
  var valid_21626395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626395 = validateParameter(valid_21626395, JString, required = false,
                                   default = nil)
  if valid_21626395 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626395
  var valid_21626396 = header.getOrDefault("X-Amz-Credential")
  valid_21626396 = validateParameter(valid_21626396, JString, required = false,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "X-Amz-Credential", valid_21626396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626397: Call_GetLayerVersion_21626385; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ## 
  let valid = call_21626397.validator(path, query, header, formData, body, _)
  let scheme = call_21626397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626397.makeUrl(scheme.get, call_21626397.host, call_21626397.base,
                               call_21626397.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626397, uri, valid, _)

proc call*(call_21626398: Call_GetLayerVersion_21626385; VersionNumber: int;
          LayerName: string): Recallable =
  ## getLayerVersion
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ##   VersionNumber: int (required)
  ##                : The version number.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  var path_21626399 = newJObject()
  add(path_21626399, "VersionNumber", newJInt(VersionNumber))
  add(path_21626399, "LayerName", newJString(LayerName))
  result = call_21626398.call(path_21626399, nil, nil, nil, nil)

var getLayerVersion* = Call_GetLayerVersion_21626385(name: "getLayerVersion",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}",
    validator: validate_GetLayerVersion_21626386, base: "/",
    makeUrl: url_GetLayerVersion_21626387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLayerVersion_21626400 = ref object of OpenApiRestCall_21625435
proc url_DeleteLayerVersion_21626402(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteLayerVersion_21626401(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Deleted versions can no longer be viewed or added to functions. To avoid breaking functions, a copy of the version remains in Lambda until no functions refer to it.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   VersionNumber: JInt (required)
  ##                : The version number.
  ##   LayerName: JString (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `VersionNumber` field"
  var valid_21626403 = path.getOrDefault("VersionNumber")
  valid_21626403 = validateParameter(valid_21626403, JInt, required = true,
                                   default = nil)
  if valid_21626403 != nil:
    section.add "VersionNumber", valid_21626403
  var valid_21626404 = path.getOrDefault("LayerName")
  valid_21626404 = validateParameter(valid_21626404, JString, required = true,
                                   default = nil)
  if valid_21626404 != nil:
    section.add "LayerName", valid_21626404
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
  var valid_21626405 = header.getOrDefault("X-Amz-Date")
  valid_21626405 = validateParameter(valid_21626405, JString, required = false,
                                   default = nil)
  if valid_21626405 != nil:
    section.add "X-Amz-Date", valid_21626405
  var valid_21626406 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626406 = validateParameter(valid_21626406, JString, required = false,
                                   default = nil)
  if valid_21626406 != nil:
    section.add "X-Amz-Security-Token", valid_21626406
  var valid_21626407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626407 = validateParameter(valid_21626407, JString, required = false,
                                   default = nil)
  if valid_21626407 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626407
  var valid_21626408 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626408 = validateParameter(valid_21626408, JString, required = false,
                                   default = nil)
  if valid_21626408 != nil:
    section.add "X-Amz-Algorithm", valid_21626408
  var valid_21626409 = header.getOrDefault("X-Amz-Signature")
  valid_21626409 = validateParameter(valid_21626409, JString, required = false,
                                   default = nil)
  if valid_21626409 != nil:
    section.add "X-Amz-Signature", valid_21626409
  var valid_21626410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626410 = validateParameter(valid_21626410, JString, required = false,
                                   default = nil)
  if valid_21626410 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626410
  var valid_21626411 = header.getOrDefault("X-Amz-Credential")
  valid_21626411 = validateParameter(valid_21626411, JString, required = false,
                                   default = nil)
  if valid_21626411 != nil:
    section.add "X-Amz-Credential", valid_21626411
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626412: Call_DeleteLayerVersion_21626400; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Deleted versions can no longer be viewed or added to functions. To avoid breaking functions, a copy of the version remains in Lambda until no functions refer to it.
  ## 
  let valid = call_21626412.validator(path, query, header, formData, body, _)
  let scheme = call_21626412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626412.makeUrl(scheme.get, call_21626412.host, call_21626412.base,
                               call_21626412.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626412, uri, valid, _)

proc call*(call_21626413: Call_DeleteLayerVersion_21626400; VersionNumber: int;
          LayerName: string): Recallable =
  ## deleteLayerVersion
  ## Deletes a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Deleted versions can no longer be viewed or added to functions. To avoid breaking functions, a copy of the version remains in Lambda until no functions refer to it.
  ##   VersionNumber: int (required)
  ##                : The version number.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  var path_21626414 = newJObject()
  add(path_21626414, "VersionNumber", newJInt(VersionNumber))
  add(path_21626414, "LayerName", newJString(LayerName))
  result = call_21626413.call(path_21626414, nil, nil, nil, nil)

var deleteLayerVersion* = Call_DeleteLayerVersion_21626400(
    name: "deleteLayerVersion", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}",
    validator: validate_DeleteLayerVersion_21626401, base: "/",
    makeUrl: url_DeleteLayerVersion_21626402, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutProvisionedConcurrencyConfig_21626431 = ref object of OpenApiRestCall_21625435
proc url_PutProvisionedConcurrencyConfig_21626433(protocol: Scheme; host: string;
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

proc validate_PutProvisionedConcurrencyConfig_21626432(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626434 = path.getOrDefault("FunctionName")
  valid_21626434 = validateParameter(valid_21626434, JString, required = true,
                                   default = nil)
  if valid_21626434 != nil:
    section.add "FunctionName", valid_21626434
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString (required)
  ##            : The version number or alias name.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Qualifier` field"
  var valid_21626435 = query.getOrDefault("Qualifier")
  valid_21626435 = validateParameter(valid_21626435, JString, required = true,
                                   default = nil)
  if valid_21626435 != nil:
    section.add "Qualifier", valid_21626435
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
  var valid_21626436 = header.getOrDefault("X-Amz-Date")
  valid_21626436 = validateParameter(valid_21626436, JString, required = false,
                                   default = nil)
  if valid_21626436 != nil:
    section.add "X-Amz-Date", valid_21626436
  var valid_21626437 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626437 = validateParameter(valid_21626437, JString, required = false,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "X-Amz-Security-Token", valid_21626437
  var valid_21626438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626438 = validateParameter(valid_21626438, JString, required = false,
                                   default = nil)
  if valid_21626438 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626438
  var valid_21626439 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626439 = validateParameter(valid_21626439, JString, required = false,
                                   default = nil)
  if valid_21626439 != nil:
    section.add "X-Amz-Algorithm", valid_21626439
  var valid_21626440 = header.getOrDefault("X-Amz-Signature")
  valid_21626440 = validateParameter(valid_21626440, JString, required = false,
                                   default = nil)
  if valid_21626440 != nil:
    section.add "X-Amz-Signature", valid_21626440
  var valid_21626441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626441 = validateParameter(valid_21626441, JString, required = false,
                                   default = nil)
  if valid_21626441 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626441
  var valid_21626442 = header.getOrDefault("X-Amz-Credential")
  valid_21626442 = validateParameter(valid_21626442, JString, required = false,
                                   default = nil)
  if valid_21626442 != nil:
    section.add "X-Amz-Credential", valid_21626442
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

proc call*(call_21626444: Call_PutProvisionedConcurrencyConfig_21626431;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds a provisioned concurrency configuration to a function's alias or version.
  ## 
  let valid = call_21626444.validator(path, query, header, formData, body, _)
  let scheme = call_21626444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626444.makeUrl(scheme.get, call_21626444.host, call_21626444.base,
                               call_21626444.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626444, uri, valid, _)

proc call*(call_21626445: Call_PutProvisionedConcurrencyConfig_21626431;
          FunctionName: string; Qualifier: string; body: JsonNode): Recallable =
  ## putProvisionedConcurrencyConfig
  ## Adds a provisioned concurrency configuration to a function's alias or version.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string (required)
  ##            : The version number or alias name.
  ##   body: JObject (required)
  var path_21626446 = newJObject()
  var query_21626447 = newJObject()
  var body_21626448 = newJObject()
  add(path_21626446, "FunctionName", newJString(FunctionName))
  add(query_21626447, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_21626448 = body
  result = call_21626445.call(path_21626446, query_21626447, nil, nil, body_21626448)

var putProvisionedConcurrencyConfig* = Call_PutProvisionedConcurrencyConfig_21626431(
    name: "putProvisionedConcurrencyConfig", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com", route: "/2019-09-30/functions/{FunctionName}/provisioned-concurrency#Qualifier",
    validator: validate_PutProvisionedConcurrencyConfig_21626432, base: "/",
    makeUrl: url_PutProvisionedConcurrencyConfig_21626433,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProvisionedConcurrencyConfig_21626415 = ref object of OpenApiRestCall_21625435
proc url_GetProvisionedConcurrencyConfig_21626417(protocol: Scheme; host: string;
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

proc validate_GetProvisionedConcurrencyConfig_21626416(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626418 = path.getOrDefault("FunctionName")
  valid_21626418 = validateParameter(valid_21626418, JString, required = true,
                                   default = nil)
  if valid_21626418 != nil:
    section.add "FunctionName", valid_21626418
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString (required)
  ##            : The version number or alias name.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Qualifier` field"
  var valid_21626419 = query.getOrDefault("Qualifier")
  valid_21626419 = validateParameter(valid_21626419, JString, required = true,
                                   default = nil)
  if valid_21626419 != nil:
    section.add "Qualifier", valid_21626419
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
  var valid_21626420 = header.getOrDefault("X-Amz-Date")
  valid_21626420 = validateParameter(valid_21626420, JString, required = false,
                                   default = nil)
  if valid_21626420 != nil:
    section.add "X-Amz-Date", valid_21626420
  var valid_21626421 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626421 = validateParameter(valid_21626421, JString, required = false,
                                   default = nil)
  if valid_21626421 != nil:
    section.add "X-Amz-Security-Token", valid_21626421
  var valid_21626422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626422 = validateParameter(valid_21626422, JString, required = false,
                                   default = nil)
  if valid_21626422 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626422
  var valid_21626423 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626423 = validateParameter(valid_21626423, JString, required = false,
                                   default = nil)
  if valid_21626423 != nil:
    section.add "X-Amz-Algorithm", valid_21626423
  var valid_21626424 = header.getOrDefault("X-Amz-Signature")
  valid_21626424 = validateParameter(valid_21626424, JString, required = false,
                                   default = nil)
  if valid_21626424 != nil:
    section.add "X-Amz-Signature", valid_21626424
  var valid_21626425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626425 = validateParameter(valid_21626425, JString, required = false,
                                   default = nil)
  if valid_21626425 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626425
  var valid_21626426 = header.getOrDefault("X-Amz-Credential")
  valid_21626426 = validateParameter(valid_21626426, JString, required = false,
                                   default = nil)
  if valid_21626426 != nil:
    section.add "X-Amz-Credential", valid_21626426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626427: Call_GetProvisionedConcurrencyConfig_21626415;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the provisioned concurrency configuration for a function's alias or version.
  ## 
  let valid = call_21626427.validator(path, query, header, formData, body, _)
  let scheme = call_21626427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626427.makeUrl(scheme.get, call_21626427.host, call_21626427.base,
                               call_21626427.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626427, uri, valid, _)

proc call*(call_21626428: Call_GetProvisionedConcurrencyConfig_21626415;
          FunctionName: string; Qualifier: string): Recallable =
  ## getProvisionedConcurrencyConfig
  ## Retrieves the provisioned concurrency configuration for a function's alias or version.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string (required)
  ##            : The version number or alias name.
  var path_21626429 = newJObject()
  var query_21626430 = newJObject()
  add(path_21626429, "FunctionName", newJString(FunctionName))
  add(query_21626430, "Qualifier", newJString(Qualifier))
  result = call_21626428.call(path_21626429, query_21626430, nil, nil, nil)

var getProvisionedConcurrencyConfig* = Call_GetProvisionedConcurrencyConfig_21626415(
    name: "getProvisionedConcurrencyConfig", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com", route: "/2019-09-30/functions/{FunctionName}/provisioned-concurrency#Qualifier",
    validator: validate_GetProvisionedConcurrencyConfig_21626416, base: "/",
    makeUrl: url_GetProvisionedConcurrencyConfig_21626417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProvisionedConcurrencyConfig_21626449 = ref object of OpenApiRestCall_21625435
proc url_DeleteProvisionedConcurrencyConfig_21626451(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_DeleteProvisionedConcurrencyConfig_21626450(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626452 = path.getOrDefault("FunctionName")
  valid_21626452 = validateParameter(valid_21626452, JString, required = true,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "FunctionName", valid_21626452
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString (required)
  ##            : The version number or alias name.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Qualifier` field"
  var valid_21626453 = query.getOrDefault("Qualifier")
  valid_21626453 = validateParameter(valid_21626453, JString, required = true,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "Qualifier", valid_21626453
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
  var valid_21626454 = header.getOrDefault("X-Amz-Date")
  valid_21626454 = validateParameter(valid_21626454, JString, required = false,
                                   default = nil)
  if valid_21626454 != nil:
    section.add "X-Amz-Date", valid_21626454
  var valid_21626455 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626455 = validateParameter(valid_21626455, JString, required = false,
                                   default = nil)
  if valid_21626455 != nil:
    section.add "X-Amz-Security-Token", valid_21626455
  var valid_21626456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626456 = validateParameter(valid_21626456, JString, required = false,
                                   default = nil)
  if valid_21626456 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626456
  var valid_21626457 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626457 = validateParameter(valid_21626457, JString, required = false,
                                   default = nil)
  if valid_21626457 != nil:
    section.add "X-Amz-Algorithm", valid_21626457
  var valid_21626458 = header.getOrDefault("X-Amz-Signature")
  valid_21626458 = validateParameter(valid_21626458, JString, required = false,
                                   default = nil)
  if valid_21626458 != nil:
    section.add "X-Amz-Signature", valid_21626458
  var valid_21626459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626459 = validateParameter(valid_21626459, JString, required = false,
                                   default = nil)
  if valid_21626459 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626459
  var valid_21626460 = header.getOrDefault("X-Amz-Credential")
  valid_21626460 = validateParameter(valid_21626460, JString, required = false,
                                   default = nil)
  if valid_21626460 != nil:
    section.add "X-Amz-Credential", valid_21626460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626461: Call_DeleteProvisionedConcurrencyConfig_21626449;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the provisioned concurrency configuration for a function.
  ## 
  let valid = call_21626461.validator(path, query, header, formData, body, _)
  let scheme = call_21626461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626461.makeUrl(scheme.get, call_21626461.host, call_21626461.base,
                               call_21626461.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626461, uri, valid, _)

proc call*(call_21626462: Call_DeleteProvisionedConcurrencyConfig_21626449;
          FunctionName: string; Qualifier: string): Recallable =
  ## deleteProvisionedConcurrencyConfig
  ## Deletes the provisioned concurrency configuration for a function.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string (required)
  ##            : The version number or alias name.
  var path_21626463 = newJObject()
  var query_21626464 = newJObject()
  add(path_21626463, "FunctionName", newJString(FunctionName))
  add(query_21626464, "Qualifier", newJString(Qualifier))
  result = call_21626462.call(path_21626463, query_21626464, nil, nil, nil)

var deleteProvisionedConcurrencyConfig* = Call_DeleteProvisionedConcurrencyConfig_21626449(
    name: "deleteProvisionedConcurrencyConfig", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com", route: "/2019-09-30/functions/{FunctionName}/provisioned-concurrency#Qualifier",
    validator: validate_DeleteProvisionedConcurrencyConfig_21626450, base: "/",
    makeUrl: url_DeleteProvisionedConcurrencyConfig_21626451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountSettings_21626465 = ref object of OpenApiRestCall_21625435
proc url_GetAccountSettings_21626467(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAccountSettings_21626466(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626468 = header.getOrDefault("X-Amz-Date")
  valid_21626468 = validateParameter(valid_21626468, JString, required = false,
                                   default = nil)
  if valid_21626468 != nil:
    section.add "X-Amz-Date", valid_21626468
  var valid_21626469 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626469 = validateParameter(valid_21626469, JString, required = false,
                                   default = nil)
  if valid_21626469 != nil:
    section.add "X-Amz-Security-Token", valid_21626469
  var valid_21626470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626470 = validateParameter(valid_21626470, JString, required = false,
                                   default = nil)
  if valid_21626470 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626470
  var valid_21626471 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626471 = validateParameter(valid_21626471, JString, required = false,
                                   default = nil)
  if valid_21626471 != nil:
    section.add "X-Amz-Algorithm", valid_21626471
  var valid_21626472 = header.getOrDefault("X-Amz-Signature")
  valid_21626472 = validateParameter(valid_21626472, JString, required = false,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "X-Amz-Signature", valid_21626472
  var valid_21626473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626473 = validateParameter(valid_21626473, JString, required = false,
                                   default = nil)
  if valid_21626473 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626473
  var valid_21626474 = header.getOrDefault("X-Amz-Credential")
  valid_21626474 = validateParameter(valid_21626474, JString, required = false,
                                   default = nil)
  if valid_21626474 != nil:
    section.add "X-Amz-Credential", valid_21626474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626475: Call_GetAccountSettings_21626465; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves details about your account's <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limits</a> and usage in an AWS Region.
  ## 
  let valid = call_21626475.validator(path, query, header, formData, body, _)
  let scheme = call_21626475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626475.makeUrl(scheme.get, call_21626475.host, call_21626475.base,
                               call_21626475.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626475, uri, valid, _)

proc call*(call_21626476: Call_GetAccountSettings_21626465): Recallable =
  ## getAccountSettings
  ## Retrieves details about your account's <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limits</a> and usage in an AWS Region.
  result = call_21626476.call(nil, nil, nil, nil, nil)

var getAccountSettings* = Call_GetAccountSettings_21626465(
    name: "getAccountSettings", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com", route: "/2016-08-19/account-settings/",
    validator: validate_GetAccountSettings_21626466, base: "/",
    makeUrl: url_GetAccountSettings_21626467, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionConcurrency_21626477 = ref object of OpenApiRestCall_21625435
proc url_GetFunctionConcurrency_21626479(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
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

proc validate_GetFunctionConcurrency_21626478(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626480 = path.getOrDefault("FunctionName")
  valid_21626480 = validateParameter(valid_21626480, JString, required = true,
                                   default = nil)
  if valid_21626480 != nil:
    section.add "FunctionName", valid_21626480
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
  var valid_21626481 = header.getOrDefault("X-Amz-Date")
  valid_21626481 = validateParameter(valid_21626481, JString, required = false,
                                   default = nil)
  if valid_21626481 != nil:
    section.add "X-Amz-Date", valid_21626481
  var valid_21626482 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626482 = validateParameter(valid_21626482, JString, required = false,
                                   default = nil)
  if valid_21626482 != nil:
    section.add "X-Amz-Security-Token", valid_21626482
  var valid_21626483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626483 = validateParameter(valid_21626483, JString, required = false,
                                   default = nil)
  if valid_21626483 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626483
  var valid_21626484 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626484 = validateParameter(valid_21626484, JString, required = false,
                                   default = nil)
  if valid_21626484 != nil:
    section.add "X-Amz-Algorithm", valid_21626484
  var valid_21626485 = header.getOrDefault("X-Amz-Signature")
  valid_21626485 = validateParameter(valid_21626485, JString, required = false,
                                   default = nil)
  if valid_21626485 != nil:
    section.add "X-Amz-Signature", valid_21626485
  var valid_21626486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626486 = validateParameter(valid_21626486, JString, required = false,
                                   default = nil)
  if valid_21626486 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626486
  var valid_21626487 = header.getOrDefault("X-Amz-Credential")
  valid_21626487 = validateParameter(valid_21626487, JString, required = false,
                                   default = nil)
  if valid_21626487 != nil:
    section.add "X-Amz-Credential", valid_21626487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626488: Call_GetFunctionConcurrency_21626477;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns details about the reserved concurrency configuration for a function. To set a concurrency limit for a function, use <a>PutFunctionConcurrency</a>.
  ## 
  let valid = call_21626488.validator(path, query, header, formData, body, _)
  let scheme = call_21626488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626488.makeUrl(scheme.get, call_21626488.host, call_21626488.base,
                               call_21626488.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626488, uri, valid, _)

proc call*(call_21626489: Call_GetFunctionConcurrency_21626477;
          FunctionName: string): Recallable =
  ## getFunctionConcurrency
  ## Returns details about the reserved concurrency configuration for a function. To set a concurrency limit for a function, use <a>PutFunctionConcurrency</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  var path_21626490 = newJObject()
  add(path_21626490, "FunctionName", newJString(FunctionName))
  result = call_21626489.call(path_21626490, nil, nil, nil, nil)

var getFunctionConcurrency* = Call_GetFunctionConcurrency_21626477(
    name: "getFunctionConcurrency", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2019-09-30/functions/{FunctionName}/concurrency",
    validator: validate_GetFunctionConcurrency_21626478, base: "/",
    makeUrl: url_GetFunctionConcurrency_21626479,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionConfiguration_21626507 = ref object of OpenApiRestCall_21625435
proc url_UpdateFunctionConfiguration_21626509(protocol: Scheme; host: string;
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

proc validate_UpdateFunctionConfiguration_21626508(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626510 = path.getOrDefault("FunctionName")
  valid_21626510 = validateParameter(valid_21626510, JString, required = true,
                                   default = nil)
  if valid_21626510 != nil:
    section.add "FunctionName", valid_21626510
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
  var valid_21626511 = header.getOrDefault("X-Amz-Date")
  valid_21626511 = validateParameter(valid_21626511, JString, required = false,
                                   default = nil)
  if valid_21626511 != nil:
    section.add "X-Amz-Date", valid_21626511
  var valid_21626512 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626512 = validateParameter(valid_21626512, JString, required = false,
                                   default = nil)
  if valid_21626512 != nil:
    section.add "X-Amz-Security-Token", valid_21626512
  var valid_21626513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626513 = validateParameter(valid_21626513, JString, required = false,
                                   default = nil)
  if valid_21626513 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626513
  var valid_21626514 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626514 = validateParameter(valid_21626514, JString, required = false,
                                   default = nil)
  if valid_21626514 != nil:
    section.add "X-Amz-Algorithm", valid_21626514
  var valid_21626515 = header.getOrDefault("X-Amz-Signature")
  valid_21626515 = validateParameter(valid_21626515, JString, required = false,
                                   default = nil)
  if valid_21626515 != nil:
    section.add "X-Amz-Signature", valid_21626515
  var valid_21626516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626516 = validateParameter(valid_21626516, JString, required = false,
                                   default = nil)
  if valid_21626516 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626516
  var valid_21626517 = header.getOrDefault("X-Amz-Credential")
  valid_21626517 = validateParameter(valid_21626517, JString, required = false,
                                   default = nil)
  if valid_21626517 != nil:
    section.add "X-Amz-Credential", valid_21626517
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

proc call*(call_21626519: Call_UpdateFunctionConfiguration_21626507;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Modify the version-specific settings of a Lambda function.</p> <p>When you update a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute. During this time, you can't modify the function, but you can still invoke it. The <code>LastUpdateStatus</code>, <code>LastUpdateStatusReason</code>, and <code>LastUpdateStatusReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the update is complete and the function is processing events with the new configuration. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Function States</a>.</p> <p>These settings can vary between versions of a function and are locked when you publish a version. You can't modify the configuration of a published version, only the unpublished version.</p> <p>To configure function concurrency, use <a>PutFunctionConcurrency</a>. To grant invoke permissions to an account or AWS service, use <a>AddPermission</a>.</p>
  ## 
  let valid = call_21626519.validator(path, query, header, formData, body, _)
  let scheme = call_21626519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626519.makeUrl(scheme.get, call_21626519.host, call_21626519.base,
                               call_21626519.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626519, uri, valid, _)

proc call*(call_21626520: Call_UpdateFunctionConfiguration_21626507;
          FunctionName: string; body: JsonNode): Recallable =
  ## updateFunctionConfiguration
  ## <p>Modify the version-specific settings of a Lambda function.</p> <p>When you update a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute. During this time, you can't modify the function, but you can still invoke it. The <code>LastUpdateStatus</code>, <code>LastUpdateStatusReason</code>, and <code>LastUpdateStatusReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the update is complete and the function is processing events with the new configuration. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Function States</a>.</p> <p>These settings can vary between versions of a function and are locked when you publish a version. You can't modify the configuration of a published version, only the unpublished version.</p> <p>To configure function concurrency, use <a>PutFunctionConcurrency</a>. To grant invoke permissions to an account or AWS service, use <a>AddPermission</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_21626521 = newJObject()
  var body_21626522 = newJObject()
  add(path_21626521, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_21626522 = body
  result = call_21626520.call(path_21626521, nil, nil, nil, body_21626522)

var updateFunctionConfiguration* = Call_UpdateFunctionConfiguration_21626507(
    name: "updateFunctionConfiguration", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/configuration",
    validator: validate_UpdateFunctionConfiguration_21626508, base: "/",
    makeUrl: url_UpdateFunctionConfiguration_21626509,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionConfiguration_21626491 = ref object of OpenApiRestCall_21625435
proc url_GetFunctionConfiguration_21626493(protocol: Scheme; host: string;
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

proc validate_GetFunctionConfiguration_21626492(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626494 = path.getOrDefault("FunctionName")
  valid_21626494 = validateParameter(valid_21626494, JString, required = true,
                                   default = nil)
  if valid_21626494 != nil:
    section.add "FunctionName", valid_21626494
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to get details about a published version of the function.
  section = newJObject()
  var valid_21626495 = query.getOrDefault("Qualifier")
  valid_21626495 = validateParameter(valid_21626495, JString, required = false,
                                   default = nil)
  if valid_21626495 != nil:
    section.add "Qualifier", valid_21626495
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

proc call*(call_21626503: Call_GetFunctionConfiguration_21626491;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns the version-specific settings of a Lambda function or version. The output includes only options that can vary between versions of a function. To modify these settings, use <a>UpdateFunctionConfiguration</a>.</p> <p>To get all of a function's details, including function-level settings, use <a>GetFunction</a>.</p>
  ## 
  let valid = call_21626503.validator(path, query, header, formData, body, _)
  let scheme = call_21626503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626503.makeUrl(scheme.get, call_21626503.host, call_21626503.base,
                               call_21626503.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626503, uri, valid, _)

proc call*(call_21626504: Call_GetFunctionConfiguration_21626491;
          FunctionName: string; Qualifier: string = ""): Recallable =
  ## getFunctionConfiguration
  ## <p>Returns the version-specific settings of a Lambda function or version. The output includes only options that can vary between versions of a function. To modify these settings, use <a>UpdateFunctionConfiguration</a>.</p> <p>To get all of a function's details, including function-level settings, use <a>GetFunction</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to get details about a published version of the function.
  var path_21626505 = newJObject()
  var query_21626506 = newJObject()
  add(path_21626505, "FunctionName", newJString(FunctionName))
  add(query_21626506, "Qualifier", newJString(Qualifier))
  result = call_21626504.call(path_21626505, query_21626506, nil, nil, nil)

var getFunctionConfiguration* = Call_GetFunctionConfiguration_21626491(
    name: "getFunctionConfiguration", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/configuration",
    validator: validate_GetFunctionConfiguration_21626492, base: "/",
    makeUrl: url_GetFunctionConfiguration_21626493,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLayerVersionByArn_21626523 = ref object of OpenApiRestCall_21625435
proc url_GetLayerVersionByArn_21626525(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetLayerVersionByArn_21626524(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626540 = query.getOrDefault("find")
  valid_21626540 = validateParameter(valid_21626540, JString, required = true,
                                   default = newJString("LayerVersion"))
  if valid_21626540 != nil:
    section.add "find", valid_21626540
  var valid_21626541 = query.getOrDefault("Arn")
  valid_21626541 = validateParameter(valid_21626541, JString, required = true,
                                   default = nil)
  if valid_21626541 != nil:
    section.add "Arn", valid_21626541
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
  var valid_21626542 = header.getOrDefault("X-Amz-Date")
  valid_21626542 = validateParameter(valid_21626542, JString, required = false,
                                   default = nil)
  if valid_21626542 != nil:
    section.add "X-Amz-Date", valid_21626542
  var valid_21626543 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626543 = validateParameter(valid_21626543, JString, required = false,
                                   default = nil)
  if valid_21626543 != nil:
    section.add "X-Amz-Security-Token", valid_21626543
  var valid_21626544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626544 = validateParameter(valid_21626544, JString, required = false,
                                   default = nil)
  if valid_21626544 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626544
  var valid_21626545 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626545 = validateParameter(valid_21626545, JString, required = false,
                                   default = nil)
  if valid_21626545 != nil:
    section.add "X-Amz-Algorithm", valid_21626545
  var valid_21626546 = header.getOrDefault("X-Amz-Signature")
  valid_21626546 = validateParameter(valid_21626546, JString, required = false,
                                   default = nil)
  if valid_21626546 != nil:
    section.add "X-Amz-Signature", valid_21626546
  var valid_21626547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626547 = validateParameter(valid_21626547, JString, required = false,
                                   default = nil)
  if valid_21626547 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626547
  var valid_21626548 = header.getOrDefault("X-Amz-Credential")
  valid_21626548 = validateParameter(valid_21626548, JString, required = false,
                                   default = nil)
  if valid_21626548 != nil:
    section.add "X-Amz-Credential", valid_21626548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626549: Call_GetLayerVersionByArn_21626523; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ## 
  let valid = call_21626549.validator(path, query, header, formData, body, _)
  let scheme = call_21626549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626549.makeUrl(scheme.get, call_21626549.host, call_21626549.base,
                               call_21626549.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626549, uri, valid, _)

proc call*(call_21626550: Call_GetLayerVersionByArn_21626523; Arn: string;
          find: string = "LayerVersion"): Recallable =
  ## getLayerVersionByArn
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ##   find: string (required)
  ##   Arn: string (required)
  ##      : The ARN of the layer version.
  var query_21626551 = newJObject()
  add(query_21626551, "find", newJString(find))
  add(query_21626551, "Arn", newJString(Arn))
  result = call_21626550.call(nil, query_21626551, nil, nil, nil)

var getLayerVersionByArn* = Call_GetLayerVersionByArn_21626523(
    name: "getLayerVersionByArn", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers#find=LayerVersion&Arn",
    validator: validate_GetLayerVersionByArn_21626524, base: "/",
    makeUrl: url_GetLayerVersionByArn_21626525,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_Invoke_21626553 = ref object of OpenApiRestCall_21625435
proc url_Invoke_21626555(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_Invoke_21626554(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626556 = path.getOrDefault("FunctionName")
  valid_21626556 = validateParameter(valid_21626556, JString, required = true,
                                   default = nil)
  if valid_21626556 != nil:
    section.add "FunctionName", valid_21626556
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to invoke a published version of the function.
  section = newJObject()
  var valid_21626557 = query.getOrDefault("Qualifier")
  valid_21626557 = validateParameter(valid_21626557, JString, required = false,
                                   default = nil)
  if valid_21626557 != nil:
    section.add "Qualifier", valid_21626557
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
  var valid_21626558 = header.getOrDefault("X-Amz-Date")
  valid_21626558 = validateParameter(valid_21626558, JString, required = false,
                                   default = nil)
  if valid_21626558 != nil:
    section.add "X-Amz-Date", valid_21626558
  var valid_21626559 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626559 = validateParameter(valid_21626559, JString, required = false,
                                   default = nil)
  if valid_21626559 != nil:
    section.add "X-Amz-Security-Token", valid_21626559
  var valid_21626560 = header.getOrDefault("X-Amz-Invocation-Type")
  valid_21626560 = validateParameter(valid_21626560, JString, required = false,
                                   default = newJString("Event"))
  if valid_21626560 != nil:
    section.add "X-Amz-Invocation-Type", valid_21626560
  var valid_21626561 = header.getOrDefault("X-Amz-Client-Context")
  valid_21626561 = validateParameter(valid_21626561, JString, required = false,
                                   default = nil)
  if valid_21626561 != nil:
    section.add "X-Amz-Client-Context", valid_21626561
  var valid_21626562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626562 = validateParameter(valid_21626562, JString, required = false,
                                   default = nil)
  if valid_21626562 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626562
  var valid_21626563 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626563 = validateParameter(valid_21626563, JString, required = false,
                                   default = nil)
  if valid_21626563 != nil:
    section.add "X-Amz-Algorithm", valid_21626563
  var valid_21626564 = header.getOrDefault("X-Amz-Signature")
  valid_21626564 = validateParameter(valid_21626564, JString, required = false,
                                   default = nil)
  if valid_21626564 != nil:
    section.add "X-Amz-Signature", valid_21626564
  var valid_21626565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626565 = validateParameter(valid_21626565, JString, required = false,
                                   default = nil)
  if valid_21626565 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626565
  var valid_21626566 = header.getOrDefault("X-Amz-Credential")
  valid_21626566 = validateParameter(valid_21626566, JString, required = false,
                                   default = nil)
  if valid_21626566 != nil:
    section.add "X-Amz-Credential", valid_21626566
  var valid_21626567 = header.getOrDefault("X-Amz-Log-Type")
  valid_21626567 = validateParameter(valid_21626567, JString, required = false,
                                   default = newJString("None"))
  if valid_21626567 != nil:
    section.add "X-Amz-Log-Type", valid_21626567
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

proc call*(call_21626569: Call_Invoke_21626553; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Invokes a Lambda function. You can invoke a function synchronously (and wait for the response), or asynchronously. To invoke a function asynchronously, set <code>InvocationType</code> to <code>Event</code>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-sync.html">synchronous invocation</a>, details about the function response, including errors, are included in the response body and headers. For either invocation type, you can find more information in the <a href="https://docs.aws.amazon.com/lambda/latest/dg/monitoring-functions.html">execution log</a> and <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-x-ray.html">trace</a>.</p> <p>When an error occurs, your function may be invoked multiple times. Retry behavior varies by error type, client, event source, and invocation type. For example, if you invoke a function asynchronously and it returns an error, Lambda executes the function up to two more times. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/retries-on-errors.html">Retry Behavior</a>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a>, Lambda adds events to a queue before sending them to your function. If your function does not have enough capacity to keep up with the queue, events may be lost. Occasionally, your function may receive the same event multiple times, even if no error occurs. To retain events that were not processed, configure your function with a <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#dlq">dead-letter queue</a>.</p> <p>The status code in the API response doesn't reflect function errors. Error codes are reserved for errors that prevent your function from executing, such as permissions errors, <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limit errors</a>, or issues with your function's code and configuration. For example, Lambda returns <code>TooManyRequestsException</code> if executing the function would cause you to exceed a concurrency limit at either the account level (<code>ConcurrentInvocationLimitExceeded</code>) or function level (<code>ReservedFunctionConcurrentInvocationLimitExceeded</code>).</p> <p>For functions with a long timeout, your client might be disconnected during synchronous invocation while it waits for a response. Configure your HTTP client, SDK, firewall, proxy, or operating system to allow for long connections with timeout or keep-alive settings.</p> <p>This operation requires permission for the <code>lambda:InvokeFunction</code> action.</p>
  ## 
  let valid = call_21626569.validator(path, query, header, formData, body, _)
  let scheme = call_21626569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626569.makeUrl(scheme.get, call_21626569.host, call_21626569.base,
                               call_21626569.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626569, uri, valid, _)

proc call*(call_21626570: Call_Invoke_21626553; FunctionName: string; body: JsonNode;
          Qualifier: string = ""): Recallable =
  ## invoke
  ## <p>Invokes a Lambda function. You can invoke a function synchronously (and wait for the response), or asynchronously. To invoke a function asynchronously, set <code>InvocationType</code> to <code>Event</code>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-sync.html">synchronous invocation</a>, details about the function response, including errors, are included in the response body and headers. For either invocation type, you can find more information in the <a href="https://docs.aws.amazon.com/lambda/latest/dg/monitoring-functions.html">execution log</a> and <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-x-ray.html">trace</a>.</p> <p>When an error occurs, your function may be invoked multiple times. Retry behavior varies by error type, client, event source, and invocation type. For example, if you invoke a function asynchronously and it returns an error, Lambda executes the function up to two more times. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/retries-on-errors.html">Retry Behavior</a>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a>, Lambda adds events to a queue before sending them to your function. If your function does not have enough capacity to keep up with the queue, events may be lost. Occasionally, your function may receive the same event multiple times, even if no error occurs. To retain events that were not processed, configure your function with a <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#dlq">dead-letter queue</a>.</p> <p>The status code in the API response doesn't reflect function errors. Error codes are reserved for errors that prevent your function from executing, such as permissions errors, <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limit errors</a>, or issues with your function's code and configuration. For example, Lambda returns <code>TooManyRequestsException</code> if executing the function would cause you to exceed a concurrency limit at either the account level (<code>ConcurrentInvocationLimitExceeded</code>) or function level (<code>ReservedFunctionConcurrentInvocationLimitExceeded</code>).</p> <p>For functions with a long timeout, your client might be disconnected during synchronous invocation while it waits for a response. Configure your HTTP client, SDK, firewall, proxy, or operating system to allow for long connections with timeout or keep-alive settings.</p> <p>This operation requires permission for the <code>lambda:InvokeFunction</code> action.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to invoke a published version of the function.
  ##   body: JObject (required)
  var path_21626571 = newJObject()
  var query_21626572 = newJObject()
  var body_21626573 = newJObject()
  add(path_21626571, "FunctionName", newJString(FunctionName))
  add(query_21626572, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_21626573 = body
  result = call_21626570.call(path_21626571, query_21626572, nil, nil, body_21626573)

var invoke* = Call_Invoke_21626553(name: "invoke", meth: HttpMethod.HttpPost,
                                host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/invocations",
                                validator: validate_Invoke_21626554, base: "/",
                                makeUrl: url_Invoke_21626555,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_InvokeAsync_21626574 = ref object of OpenApiRestCall_21625435
proc url_InvokeAsync_21626576(protocol: Scheme; host: string; base: string;
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

proc validate_InvokeAsync_21626575(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626577 = path.getOrDefault("FunctionName")
  valid_21626577 = validateParameter(valid_21626577, JString, required = true,
                                   default = nil)
  if valid_21626577 != nil:
    section.add "FunctionName", valid_21626577
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
  var valid_21626578 = header.getOrDefault("X-Amz-Date")
  valid_21626578 = validateParameter(valid_21626578, JString, required = false,
                                   default = nil)
  if valid_21626578 != nil:
    section.add "X-Amz-Date", valid_21626578
  var valid_21626579 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626579 = validateParameter(valid_21626579, JString, required = false,
                                   default = nil)
  if valid_21626579 != nil:
    section.add "X-Amz-Security-Token", valid_21626579
  var valid_21626580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626580 = validateParameter(valid_21626580, JString, required = false,
                                   default = nil)
  if valid_21626580 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626580
  var valid_21626581 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626581 = validateParameter(valid_21626581, JString, required = false,
                                   default = nil)
  if valid_21626581 != nil:
    section.add "X-Amz-Algorithm", valid_21626581
  var valid_21626582 = header.getOrDefault("X-Amz-Signature")
  valid_21626582 = validateParameter(valid_21626582, JString, required = false,
                                   default = nil)
  if valid_21626582 != nil:
    section.add "X-Amz-Signature", valid_21626582
  var valid_21626583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626583 = validateParameter(valid_21626583, JString, required = false,
                                   default = nil)
  if valid_21626583 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626583
  var valid_21626584 = header.getOrDefault("X-Amz-Credential")
  valid_21626584 = validateParameter(valid_21626584, JString, required = false,
                                   default = nil)
  if valid_21626584 != nil:
    section.add "X-Amz-Credential", valid_21626584
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

proc call*(call_21626586: Call_InvokeAsync_21626574; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <important> <p>For asynchronous function invocation, use <a>Invoke</a>.</p> </important> <p>Invokes a function asynchronously.</p>
  ## 
  let valid = call_21626586.validator(path, query, header, formData, body, _)
  let scheme = call_21626586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626586.makeUrl(scheme.get, call_21626586.host, call_21626586.base,
                               call_21626586.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626586, uri, valid, _)

proc call*(call_21626587: Call_InvokeAsync_21626574; FunctionName: string;
          body: JsonNode): Recallable =
  ## invokeAsync
  ## <important> <p>For asynchronous function invocation, use <a>Invoke</a>.</p> </important> <p>Invokes a function asynchronously.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_21626588 = newJObject()
  var body_21626589 = newJObject()
  add(path_21626588, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_21626589 = body
  result = call_21626587.call(path_21626588, nil, nil, nil, body_21626589)

var invokeAsync* = Call_InvokeAsync_21626574(name: "invokeAsync",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2014-11-13/functions/{FunctionName}/invoke-async/",
    validator: validate_InvokeAsync_21626575, base: "/", makeUrl: url_InvokeAsync_21626576,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctionEventInvokeConfigs_21626590 = ref object of OpenApiRestCall_21625435
proc url_ListFunctionEventInvokeConfigs_21626592(protocol: Scheme; host: string;
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

proc validate_ListFunctionEventInvokeConfigs_21626591(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626593 = path.getOrDefault("FunctionName")
  valid_21626593 = validateParameter(valid_21626593, JString, required = true,
                                   default = nil)
  if valid_21626593 != nil:
    section.add "FunctionName", valid_21626593
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: JInt
  ##           : The maximum number of configurations to return.
  section = newJObject()
  var valid_21626594 = query.getOrDefault("Marker")
  valid_21626594 = validateParameter(valid_21626594, JString, required = false,
                                   default = nil)
  if valid_21626594 != nil:
    section.add "Marker", valid_21626594
  var valid_21626595 = query.getOrDefault("MaxItems")
  valid_21626595 = validateParameter(valid_21626595, JInt, required = false,
                                   default = nil)
  if valid_21626595 != nil:
    section.add "MaxItems", valid_21626595
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
  var valid_21626596 = header.getOrDefault("X-Amz-Date")
  valid_21626596 = validateParameter(valid_21626596, JString, required = false,
                                   default = nil)
  if valid_21626596 != nil:
    section.add "X-Amz-Date", valid_21626596
  var valid_21626597 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626597 = validateParameter(valid_21626597, JString, required = false,
                                   default = nil)
  if valid_21626597 != nil:
    section.add "X-Amz-Security-Token", valid_21626597
  var valid_21626598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626598 = validateParameter(valid_21626598, JString, required = false,
                                   default = nil)
  if valid_21626598 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626598
  var valid_21626599 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626599 = validateParameter(valid_21626599, JString, required = false,
                                   default = nil)
  if valid_21626599 != nil:
    section.add "X-Amz-Algorithm", valid_21626599
  var valid_21626600 = header.getOrDefault("X-Amz-Signature")
  valid_21626600 = validateParameter(valid_21626600, JString, required = false,
                                   default = nil)
  if valid_21626600 != nil:
    section.add "X-Amz-Signature", valid_21626600
  var valid_21626601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626601 = validateParameter(valid_21626601, JString, required = false,
                                   default = nil)
  if valid_21626601 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626601
  var valid_21626602 = header.getOrDefault("X-Amz-Credential")
  valid_21626602 = validateParameter(valid_21626602, JString, required = false,
                                   default = nil)
  if valid_21626602 != nil:
    section.add "X-Amz-Credential", valid_21626602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626603: Call_ListFunctionEventInvokeConfigs_21626590;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves a list of configurations for asynchronous invocation for a function.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  let valid = call_21626603.validator(path, query, header, formData, body, _)
  let scheme = call_21626603.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626603.makeUrl(scheme.get, call_21626603.host, call_21626603.base,
                               call_21626603.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626603, uri, valid, _)

proc call*(call_21626604: Call_ListFunctionEventInvokeConfigs_21626590;
          FunctionName: string; Marker: string = ""; MaxItems: int = 0): Recallable =
  ## listFunctionEventInvokeConfigs
  ## <p>Retrieves a list of configurations for asynchronous invocation for a function.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Marker: string
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: int
  ##           : The maximum number of configurations to return.
  var path_21626605 = newJObject()
  var query_21626606 = newJObject()
  add(path_21626605, "FunctionName", newJString(FunctionName))
  add(query_21626606, "Marker", newJString(Marker))
  add(query_21626606, "MaxItems", newJInt(MaxItems))
  result = call_21626604.call(path_21626605, query_21626606, nil, nil, nil)

var listFunctionEventInvokeConfigs* = Call_ListFunctionEventInvokeConfigs_21626590(
    name: "listFunctionEventInvokeConfigs", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config/list",
    validator: validate_ListFunctionEventInvokeConfigs_21626591, base: "/",
    makeUrl: url_ListFunctionEventInvokeConfigs_21626592,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctions_21626607 = ref object of OpenApiRestCall_21625435
proc url_ListFunctions_21626609(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFunctions_21626608(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626610 = query.getOrDefault("FunctionVersion")
  valid_21626610 = validateParameter(valid_21626610, JString, required = false,
                                   default = newJString("ALL"))
  if valid_21626610 != nil:
    section.add "FunctionVersion", valid_21626610
  var valid_21626611 = query.getOrDefault("Marker")
  valid_21626611 = validateParameter(valid_21626611, JString, required = false,
                                   default = nil)
  if valid_21626611 != nil:
    section.add "Marker", valid_21626611
  var valid_21626612 = query.getOrDefault("MasterRegion")
  valid_21626612 = validateParameter(valid_21626612, JString, required = false,
                                   default = nil)
  if valid_21626612 != nil:
    section.add "MasterRegion", valid_21626612
  var valid_21626613 = query.getOrDefault("MaxItems")
  valid_21626613 = validateParameter(valid_21626613, JInt, required = false,
                                   default = nil)
  if valid_21626613 != nil:
    section.add "MaxItems", valid_21626613
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
  var valid_21626614 = header.getOrDefault("X-Amz-Date")
  valid_21626614 = validateParameter(valid_21626614, JString, required = false,
                                   default = nil)
  if valid_21626614 != nil:
    section.add "X-Amz-Date", valid_21626614
  var valid_21626615 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626615 = validateParameter(valid_21626615, JString, required = false,
                                   default = nil)
  if valid_21626615 != nil:
    section.add "X-Amz-Security-Token", valid_21626615
  var valid_21626616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626616 = validateParameter(valid_21626616, JString, required = false,
                                   default = nil)
  if valid_21626616 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626616
  var valid_21626617 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626617 = validateParameter(valid_21626617, JString, required = false,
                                   default = nil)
  if valid_21626617 != nil:
    section.add "X-Amz-Algorithm", valid_21626617
  var valid_21626618 = header.getOrDefault("X-Amz-Signature")
  valid_21626618 = validateParameter(valid_21626618, JString, required = false,
                                   default = nil)
  if valid_21626618 != nil:
    section.add "X-Amz-Signature", valid_21626618
  var valid_21626619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626619 = validateParameter(valid_21626619, JString, required = false,
                                   default = nil)
  if valid_21626619 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626619
  var valid_21626620 = header.getOrDefault("X-Amz-Credential")
  valid_21626620 = validateParameter(valid_21626620, JString, required = false,
                                   default = nil)
  if valid_21626620 != nil:
    section.add "X-Amz-Credential", valid_21626620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626621: Call_ListFunctions_21626607; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of Lambda functions, with the version-specific configuration of each. Lambda returns up to 50 functions per call.</p> <p>Set <code>FunctionVersion</code> to <code>ALL</code> to include all published versions of each function in addition to the unpublished version. To get more information about a function or version, use <a>GetFunction</a>.</p>
  ## 
  let valid = call_21626621.validator(path, query, header, formData, body, _)
  let scheme = call_21626621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626621.makeUrl(scheme.get, call_21626621.host, call_21626621.base,
                               call_21626621.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626621, uri, valid, _)

proc call*(call_21626622: Call_ListFunctions_21626607;
          FunctionVersion: string = "ALL"; Marker: string = "";
          MasterRegion: string = ""; MaxItems: int = 0): Recallable =
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
  var query_21626623 = newJObject()
  add(query_21626623, "FunctionVersion", newJString(FunctionVersion))
  add(query_21626623, "Marker", newJString(Marker))
  add(query_21626623, "MasterRegion", newJString(MasterRegion))
  add(query_21626623, "MaxItems", newJInt(MaxItems))
  result = call_21626622.call(nil, query_21626623, nil, nil, nil)

var listFunctions* = Call_ListFunctions_21626607(name: "listFunctions",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/", validator: validate_ListFunctions_21626608,
    base: "/", makeUrl: url_ListFunctions_21626609,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PublishLayerVersion_21626642 = ref object of OpenApiRestCall_21625435
proc url_PublishLayerVersion_21626644(protocol: Scheme; host: string; base: string;
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

proc validate_PublishLayerVersion_21626643(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a> from a ZIP archive. Each time you call <code>PublishLayerVersion</code> with the same layer name, a new version is created.</p> <p>Add layers to your function with <a>CreateFunction</a> or <a>UpdateFunctionConfiguration</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   LayerName: JString (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `LayerName` field"
  var valid_21626645 = path.getOrDefault("LayerName")
  valid_21626645 = validateParameter(valid_21626645, JString, required = true,
                                   default = nil)
  if valid_21626645 != nil:
    section.add "LayerName", valid_21626645
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
  var valid_21626646 = header.getOrDefault("X-Amz-Date")
  valid_21626646 = validateParameter(valid_21626646, JString, required = false,
                                   default = nil)
  if valid_21626646 != nil:
    section.add "X-Amz-Date", valid_21626646
  var valid_21626647 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626647 = validateParameter(valid_21626647, JString, required = false,
                                   default = nil)
  if valid_21626647 != nil:
    section.add "X-Amz-Security-Token", valid_21626647
  var valid_21626648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626648 = validateParameter(valid_21626648, JString, required = false,
                                   default = nil)
  if valid_21626648 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626648
  var valid_21626649 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626649 = validateParameter(valid_21626649, JString, required = false,
                                   default = nil)
  if valid_21626649 != nil:
    section.add "X-Amz-Algorithm", valid_21626649
  var valid_21626650 = header.getOrDefault("X-Amz-Signature")
  valid_21626650 = validateParameter(valid_21626650, JString, required = false,
                                   default = nil)
  if valid_21626650 != nil:
    section.add "X-Amz-Signature", valid_21626650
  var valid_21626651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626651 = validateParameter(valid_21626651, JString, required = false,
                                   default = nil)
  if valid_21626651 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626651
  var valid_21626652 = header.getOrDefault("X-Amz-Credential")
  valid_21626652 = validateParameter(valid_21626652, JString, required = false,
                                   default = nil)
  if valid_21626652 != nil:
    section.add "X-Amz-Credential", valid_21626652
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

proc call*(call_21626654: Call_PublishLayerVersion_21626642; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a> from a ZIP archive. Each time you call <code>PublishLayerVersion</code> with the same layer name, a new version is created.</p> <p>Add layers to your function with <a>CreateFunction</a> or <a>UpdateFunctionConfiguration</a>.</p>
  ## 
  let valid = call_21626654.validator(path, query, header, formData, body, _)
  let scheme = call_21626654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626654.makeUrl(scheme.get, call_21626654.host, call_21626654.base,
                               call_21626654.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626654, uri, valid, _)

proc call*(call_21626655: Call_PublishLayerVersion_21626642; LayerName: string;
          body: JsonNode): Recallable =
  ## publishLayerVersion
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a> from a ZIP archive. Each time you call <code>PublishLayerVersion</code> with the same layer name, a new version is created.</p> <p>Add layers to your function with <a>CreateFunction</a> or <a>UpdateFunctionConfiguration</a>.</p>
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  ##   body: JObject (required)
  var path_21626656 = newJObject()
  var body_21626657 = newJObject()
  add(path_21626656, "LayerName", newJString(LayerName))
  if body != nil:
    body_21626657 = body
  result = call_21626655.call(path_21626656, nil, nil, nil, body_21626657)

var publishLayerVersion* = Call_PublishLayerVersion_21626642(
    name: "publishLayerVersion", meth: HttpMethod.HttpPost,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions",
    validator: validate_PublishLayerVersion_21626643, base: "/",
    makeUrl: url_PublishLayerVersion_21626644,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLayerVersions_21626624 = ref object of OpenApiRestCall_21625435
proc url_ListLayerVersions_21626626(protocol: Scheme; host: string; base: string;
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

proc validate_ListLayerVersions_21626625(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the versions of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Versions that have been deleted aren't listed. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only versions that indicate that they're compatible with that runtime.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   LayerName: JString (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `LayerName` field"
  var valid_21626627 = path.getOrDefault("LayerName")
  valid_21626627 = validateParameter(valid_21626627, JString, required = true,
                                   default = nil)
  if valid_21626627 != nil:
    section.add "LayerName", valid_21626627
  result.add "path", section
  ## parameters in `query` object:
  ##   CompatibleRuntime: JString
  ##                    : A runtime identifier. For example, <code>go1.x</code>.
  ##   Marker: JString
  ##         : A pagination token returned by a previous call.
  ##   MaxItems: JInt
  ##           : The maximum number of versions to return.
  section = newJObject()
  var valid_21626628 = query.getOrDefault("CompatibleRuntime")
  valid_21626628 = validateParameter(valid_21626628, JString, required = false,
                                   default = newJString("nodejs"))
  if valid_21626628 != nil:
    section.add "CompatibleRuntime", valid_21626628
  var valid_21626629 = query.getOrDefault("Marker")
  valid_21626629 = validateParameter(valid_21626629, JString, required = false,
                                   default = nil)
  if valid_21626629 != nil:
    section.add "Marker", valid_21626629
  var valid_21626630 = query.getOrDefault("MaxItems")
  valid_21626630 = validateParameter(valid_21626630, JInt, required = false,
                                   default = nil)
  if valid_21626630 != nil:
    section.add "MaxItems", valid_21626630
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
  var valid_21626631 = header.getOrDefault("X-Amz-Date")
  valid_21626631 = validateParameter(valid_21626631, JString, required = false,
                                   default = nil)
  if valid_21626631 != nil:
    section.add "X-Amz-Date", valid_21626631
  var valid_21626632 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626632 = validateParameter(valid_21626632, JString, required = false,
                                   default = nil)
  if valid_21626632 != nil:
    section.add "X-Amz-Security-Token", valid_21626632
  var valid_21626633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626633 = validateParameter(valid_21626633, JString, required = false,
                                   default = nil)
  if valid_21626633 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626633
  var valid_21626634 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626634 = validateParameter(valid_21626634, JString, required = false,
                                   default = nil)
  if valid_21626634 != nil:
    section.add "X-Amz-Algorithm", valid_21626634
  var valid_21626635 = header.getOrDefault("X-Amz-Signature")
  valid_21626635 = validateParameter(valid_21626635, JString, required = false,
                                   default = nil)
  if valid_21626635 != nil:
    section.add "X-Amz-Signature", valid_21626635
  var valid_21626636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626636 = validateParameter(valid_21626636, JString, required = false,
                                   default = nil)
  if valid_21626636 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626636
  var valid_21626637 = header.getOrDefault("X-Amz-Credential")
  valid_21626637 = validateParameter(valid_21626637, JString, required = false,
                                   default = nil)
  if valid_21626637 != nil:
    section.add "X-Amz-Credential", valid_21626637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626638: Call_ListLayerVersions_21626624; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the versions of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Versions that have been deleted aren't listed. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only versions that indicate that they're compatible with that runtime.
  ## 
  let valid = call_21626638.validator(path, query, header, formData, body, _)
  let scheme = call_21626638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626638.makeUrl(scheme.get, call_21626638.host, call_21626638.base,
                               call_21626638.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626638, uri, valid, _)

proc call*(call_21626639: Call_ListLayerVersions_21626624; LayerName: string;
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
  var path_21626640 = newJObject()
  var query_21626641 = newJObject()
  add(query_21626641, "CompatibleRuntime", newJString(CompatibleRuntime))
  add(query_21626641, "Marker", newJString(Marker))
  add(path_21626640, "LayerName", newJString(LayerName))
  add(query_21626641, "MaxItems", newJInt(MaxItems))
  result = call_21626639.call(path_21626640, query_21626641, nil, nil, nil)

var listLayerVersions* = Call_ListLayerVersions_21626624(name: "listLayerVersions",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions",
    validator: validate_ListLayerVersions_21626625, base: "/",
    makeUrl: url_ListLayerVersions_21626626, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLayers_21626658 = ref object of OpenApiRestCall_21625435
proc url_ListLayers_21626660(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListLayers_21626659(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626661 = query.getOrDefault("CompatibleRuntime")
  valid_21626661 = validateParameter(valid_21626661, JString, required = false,
                                   default = newJString("nodejs"))
  if valid_21626661 != nil:
    section.add "CompatibleRuntime", valid_21626661
  var valid_21626662 = query.getOrDefault("Marker")
  valid_21626662 = validateParameter(valid_21626662, JString, required = false,
                                   default = nil)
  if valid_21626662 != nil:
    section.add "Marker", valid_21626662
  var valid_21626663 = query.getOrDefault("MaxItems")
  valid_21626663 = validateParameter(valid_21626663, JInt, required = false,
                                   default = nil)
  if valid_21626663 != nil:
    section.add "MaxItems", valid_21626663
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
  var valid_21626664 = header.getOrDefault("X-Amz-Date")
  valid_21626664 = validateParameter(valid_21626664, JString, required = false,
                                   default = nil)
  if valid_21626664 != nil:
    section.add "X-Amz-Date", valid_21626664
  var valid_21626665 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626665 = validateParameter(valid_21626665, JString, required = false,
                                   default = nil)
  if valid_21626665 != nil:
    section.add "X-Amz-Security-Token", valid_21626665
  var valid_21626666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626666 = validateParameter(valid_21626666, JString, required = false,
                                   default = nil)
  if valid_21626666 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626666
  var valid_21626667 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626667 = validateParameter(valid_21626667, JString, required = false,
                                   default = nil)
  if valid_21626667 != nil:
    section.add "X-Amz-Algorithm", valid_21626667
  var valid_21626668 = header.getOrDefault("X-Amz-Signature")
  valid_21626668 = validateParameter(valid_21626668, JString, required = false,
                                   default = nil)
  if valid_21626668 != nil:
    section.add "X-Amz-Signature", valid_21626668
  var valid_21626669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626669 = validateParameter(valid_21626669, JString, required = false,
                                   default = nil)
  if valid_21626669 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626669
  var valid_21626670 = header.getOrDefault("X-Amz-Credential")
  valid_21626670 = validateParameter(valid_21626670, JString, required = false,
                                   default = nil)
  if valid_21626670 != nil:
    section.add "X-Amz-Credential", valid_21626670
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626671: Call_ListLayers_21626658; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layers</a> and shows information about the latest version of each. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only layers that indicate that they're compatible with that runtime.
  ## 
  let valid = call_21626671.validator(path, query, header, formData, body, _)
  let scheme = call_21626671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626671.makeUrl(scheme.get, call_21626671.host, call_21626671.base,
                               call_21626671.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626671, uri, valid, _)

proc call*(call_21626672: Call_ListLayers_21626658;
          CompatibleRuntime: string = "nodejs"; Marker: string = ""; MaxItems: int = 0): Recallable =
  ## listLayers
  ## Lists <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layers</a> and shows information about the latest version of each. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only layers that indicate that they're compatible with that runtime.
  ##   CompatibleRuntime: string
  ##                    : A runtime identifier. For example, <code>go1.x</code>.
  ##   Marker: string
  ##         : A pagination token returned by a previous call.
  ##   MaxItems: int
  ##           : The maximum number of layers to return.
  var query_21626673 = newJObject()
  add(query_21626673, "CompatibleRuntime", newJString(CompatibleRuntime))
  add(query_21626673, "Marker", newJString(Marker))
  add(query_21626673, "MaxItems", newJInt(MaxItems))
  result = call_21626672.call(nil, query_21626673, nil, nil, nil)

var listLayers* = Call_ListLayers_21626658(name: "listLayers",
                                        meth: HttpMethod.HttpGet,
                                        host: "lambda.amazonaws.com",
                                        route: "/2018-10-31/layers",
                                        validator: validate_ListLayers_21626659,
                                        base: "/", makeUrl: url_ListLayers_21626660,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisionedConcurrencyConfigs_21626674 = ref object of OpenApiRestCall_21625435
proc url_ListProvisionedConcurrencyConfigs_21626676(protocol: Scheme; host: string;
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

proc validate_ListProvisionedConcurrencyConfigs_21626675(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626677 = path.getOrDefault("FunctionName")
  valid_21626677 = validateParameter(valid_21626677, JString, required = true,
                                   default = nil)
  if valid_21626677 != nil:
    section.add "FunctionName", valid_21626677
  result.add "path", section
  ## parameters in `query` object:
  ##   List: JString (required)
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: JInt
  ##           : Specify a number to limit the number of configurations returned.
  section = newJObject()
  var valid_21626678 = query.getOrDefault("List")
  valid_21626678 = validateParameter(valid_21626678, JString, required = true,
                                   default = newJString("ALL"))
  if valid_21626678 != nil:
    section.add "List", valid_21626678
  var valid_21626679 = query.getOrDefault("Marker")
  valid_21626679 = validateParameter(valid_21626679, JString, required = false,
                                   default = nil)
  if valid_21626679 != nil:
    section.add "Marker", valid_21626679
  var valid_21626680 = query.getOrDefault("MaxItems")
  valid_21626680 = validateParameter(valid_21626680, JInt, required = false,
                                   default = nil)
  if valid_21626680 != nil:
    section.add "MaxItems", valid_21626680
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
  var valid_21626681 = header.getOrDefault("X-Amz-Date")
  valid_21626681 = validateParameter(valid_21626681, JString, required = false,
                                   default = nil)
  if valid_21626681 != nil:
    section.add "X-Amz-Date", valid_21626681
  var valid_21626682 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626682 = validateParameter(valid_21626682, JString, required = false,
                                   default = nil)
  if valid_21626682 != nil:
    section.add "X-Amz-Security-Token", valid_21626682
  var valid_21626683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626683 = validateParameter(valid_21626683, JString, required = false,
                                   default = nil)
  if valid_21626683 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626683
  var valid_21626684 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626684 = validateParameter(valid_21626684, JString, required = false,
                                   default = nil)
  if valid_21626684 != nil:
    section.add "X-Amz-Algorithm", valid_21626684
  var valid_21626685 = header.getOrDefault("X-Amz-Signature")
  valid_21626685 = validateParameter(valid_21626685, JString, required = false,
                                   default = nil)
  if valid_21626685 != nil:
    section.add "X-Amz-Signature", valid_21626685
  var valid_21626686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626686 = validateParameter(valid_21626686, JString, required = false,
                                   default = nil)
  if valid_21626686 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626686
  var valid_21626687 = header.getOrDefault("X-Amz-Credential")
  valid_21626687 = validateParameter(valid_21626687, JString, required = false,
                                   default = nil)
  if valid_21626687 != nil:
    section.add "X-Amz-Credential", valid_21626687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626688: Call_ListProvisionedConcurrencyConfigs_21626674;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of provisioned concurrency configurations for a function.
  ## 
  let valid = call_21626688.validator(path, query, header, formData, body, _)
  let scheme = call_21626688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626688.makeUrl(scheme.get, call_21626688.host, call_21626688.base,
                               call_21626688.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626688, uri, valid, _)

proc call*(call_21626689: Call_ListProvisionedConcurrencyConfigs_21626674;
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
  var path_21626690 = newJObject()
  var query_21626691 = newJObject()
  add(query_21626691, "List", newJString(List))
  add(path_21626690, "FunctionName", newJString(FunctionName))
  add(query_21626691, "Marker", newJString(Marker))
  add(query_21626691, "MaxItems", newJInt(MaxItems))
  result = call_21626689.call(path_21626690, query_21626691, nil, nil, nil)

var listProvisionedConcurrencyConfigs* = Call_ListProvisionedConcurrencyConfigs_21626674(
    name: "listProvisionedConcurrencyConfigs", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com", route: "/2019-09-30/functions/{FunctionName}/provisioned-concurrency#List=ALL",
    validator: validate_ListProvisionedConcurrencyConfigs_21626675, base: "/",
    makeUrl: url_ListProvisionedConcurrencyConfigs_21626676,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21626706 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21626708(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_21626707(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> to a function.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ARN: JString (required)
  ##      : The function's Amazon Resource Name (ARN).
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ARN` field"
  var valid_21626709 = path.getOrDefault("ARN")
  valid_21626709 = validateParameter(valid_21626709, JString, required = true,
                                   default = nil)
  if valid_21626709 != nil:
    section.add "ARN", valid_21626709
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
  var valid_21626710 = header.getOrDefault("X-Amz-Date")
  valid_21626710 = validateParameter(valid_21626710, JString, required = false,
                                   default = nil)
  if valid_21626710 != nil:
    section.add "X-Amz-Date", valid_21626710
  var valid_21626711 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626711 = validateParameter(valid_21626711, JString, required = false,
                                   default = nil)
  if valid_21626711 != nil:
    section.add "X-Amz-Security-Token", valid_21626711
  var valid_21626712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626712 = validateParameter(valid_21626712, JString, required = false,
                                   default = nil)
  if valid_21626712 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626712
  var valid_21626713 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626713 = validateParameter(valid_21626713, JString, required = false,
                                   default = nil)
  if valid_21626713 != nil:
    section.add "X-Amz-Algorithm", valid_21626713
  var valid_21626714 = header.getOrDefault("X-Amz-Signature")
  valid_21626714 = validateParameter(valid_21626714, JString, required = false,
                                   default = nil)
  if valid_21626714 != nil:
    section.add "X-Amz-Signature", valid_21626714
  var valid_21626715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626715 = validateParameter(valid_21626715, JString, required = false,
                                   default = nil)
  if valid_21626715 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626715
  var valid_21626716 = header.getOrDefault("X-Amz-Credential")
  valid_21626716 = validateParameter(valid_21626716, JString, required = false,
                                   default = nil)
  if valid_21626716 != nil:
    section.add "X-Amz-Credential", valid_21626716
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

proc call*(call_21626718: Call_TagResource_21626706; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> to a function.
  ## 
  let valid = call_21626718.validator(path, query, header, formData, body, _)
  let scheme = call_21626718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626718.makeUrl(scheme.get, call_21626718.host, call_21626718.base,
                               call_21626718.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626718, uri, valid, _)

proc call*(call_21626719: Call_TagResource_21626706; ARN: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> to a function.
  ##   ARN: string (required)
  ##      : The function's Amazon Resource Name (ARN).
  ##   body: JObject (required)
  var path_21626720 = newJObject()
  var body_21626721 = newJObject()
  add(path_21626720, "ARN", newJString(ARN))
  if body != nil:
    body_21626721 = body
  result = call_21626719.call(path_21626720, nil, nil, nil, body_21626721)

var tagResource* = Call_TagResource_21626706(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2017-03-31/tags/{ARN}", validator: validate_TagResource_21626707,
    base: "/", makeUrl: url_TagResource_21626708,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_21626692 = ref object of OpenApiRestCall_21625435
proc url_ListTags_21626694(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListTags_21626693(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a function's <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a>. You can also view tags with <a>GetFunction</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ARN: JString (required)
  ##      : The function's Amazon Resource Name (ARN).
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ARN` field"
  var valid_21626695 = path.getOrDefault("ARN")
  valid_21626695 = validateParameter(valid_21626695, JString, required = true,
                                   default = nil)
  if valid_21626695 != nil:
    section.add "ARN", valid_21626695
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
  var valid_21626696 = header.getOrDefault("X-Amz-Date")
  valid_21626696 = validateParameter(valid_21626696, JString, required = false,
                                   default = nil)
  if valid_21626696 != nil:
    section.add "X-Amz-Date", valid_21626696
  var valid_21626697 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626697 = validateParameter(valid_21626697, JString, required = false,
                                   default = nil)
  if valid_21626697 != nil:
    section.add "X-Amz-Security-Token", valid_21626697
  var valid_21626698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626698 = validateParameter(valid_21626698, JString, required = false,
                                   default = nil)
  if valid_21626698 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626698
  var valid_21626699 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626699 = validateParameter(valid_21626699, JString, required = false,
                                   default = nil)
  if valid_21626699 != nil:
    section.add "X-Amz-Algorithm", valid_21626699
  var valid_21626700 = header.getOrDefault("X-Amz-Signature")
  valid_21626700 = validateParameter(valid_21626700, JString, required = false,
                                   default = nil)
  if valid_21626700 != nil:
    section.add "X-Amz-Signature", valid_21626700
  var valid_21626701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626701 = validateParameter(valid_21626701, JString, required = false,
                                   default = nil)
  if valid_21626701 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626701
  var valid_21626702 = header.getOrDefault("X-Amz-Credential")
  valid_21626702 = validateParameter(valid_21626702, JString, required = false,
                                   default = nil)
  if valid_21626702 != nil:
    section.add "X-Amz-Credential", valid_21626702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626703: Call_ListTags_21626692; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a function's <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a>. You can also view tags with <a>GetFunction</a>.
  ## 
  let valid = call_21626703.validator(path, query, header, formData, body, _)
  let scheme = call_21626703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626703.makeUrl(scheme.get, call_21626703.host, call_21626703.base,
                               call_21626703.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626703, uri, valid, _)

proc call*(call_21626704: Call_ListTags_21626692; ARN: string): Recallable =
  ## listTags
  ## Returns a function's <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a>. You can also view tags with <a>GetFunction</a>.
  ##   ARN: string (required)
  ##      : The function's Amazon Resource Name (ARN).
  var path_21626705 = newJObject()
  add(path_21626705, "ARN", newJString(ARN))
  result = call_21626704.call(path_21626705, nil, nil, nil, nil)

var listTags* = Call_ListTags_21626692(name: "listTags", meth: HttpMethod.HttpGet,
                                    host: "lambda.amazonaws.com",
                                    route: "/2017-03-31/tags/{ARN}",
                                    validator: validate_ListTags_21626693,
                                    base: "/", makeUrl: url_ListTags_21626694,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PublishVersion_21626739 = ref object of OpenApiRestCall_21625435
proc url_PublishVersion_21626741(protocol: Scheme; host: string; base: string;
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

proc validate_PublishVersion_21626740(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626742 = path.getOrDefault("FunctionName")
  valid_21626742 = validateParameter(valid_21626742, JString, required = true,
                                   default = nil)
  if valid_21626742 != nil:
    section.add "FunctionName", valid_21626742
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
  var valid_21626743 = header.getOrDefault("X-Amz-Date")
  valid_21626743 = validateParameter(valid_21626743, JString, required = false,
                                   default = nil)
  if valid_21626743 != nil:
    section.add "X-Amz-Date", valid_21626743
  var valid_21626744 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626744 = validateParameter(valid_21626744, JString, required = false,
                                   default = nil)
  if valid_21626744 != nil:
    section.add "X-Amz-Security-Token", valid_21626744
  var valid_21626745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626745 = validateParameter(valid_21626745, JString, required = false,
                                   default = nil)
  if valid_21626745 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626745
  var valid_21626746 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626746 = validateParameter(valid_21626746, JString, required = false,
                                   default = nil)
  if valid_21626746 != nil:
    section.add "X-Amz-Algorithm", valid_21626746
  var valid_21626747 = header.getOrDefault("X-Amz-Signature")
  valid_21626747 = validateParameter(valid_21626747, JString, required = false,
                                   default = nil)
  if valid_21626747 != nil:
    section.add "X-Amz-Signature", valid_21626747
  var valid_21626748 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626748 = validateParameter(valid_21626748, JString, required = false,
                                   default = nil)
  if valid_21626748 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626748
  var valid_21626749 = header.getOrDefault("X-Amz-Credential")
  valid_21626749 = validateParameter(valid_21626749, JString, required = false,
                                   default = nil)
  if valid_21626749 != nil:
    section.add "X-Amz-Credential", valid_21626749
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

proc call*(call_21626751: Call_PublishVersion_21626739; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">version</a> from the current code and configuration of a function. Use versions to create a snapshot of your function code and configuration that doesn't change.</p> <p>AWS Lambda doesn't publish a version if the function's configuration and code haven't changed since the last version. Use <a>UpdateFunctionCode</a> or <a>UpdateFunctionConfiguration</a> to update the function before publishing a version.</p> <p>Clients can invoke versions directly or with an alias. To create an alias, use <a>CreateAlias</a>.</p>
  ## 
  let valid = call_21626751.validator(path, query, header, formData, body, _)
  let scheme = call_21626751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626751.makeUrl(scheme.get, call_21626751.host, call_21626751.base,
                               call_21626751.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626751, uri, valid, _)

proc call*(call_21626752: Call_PublishVersion_21626739; FunctionName: string;
          body: JsonNode): Recallable =
  ## publishVersion
  ## <p>Creates a <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">version</a> from the current code and configuration of a function. Use versions to create a snapshot of your function code and configuration that doesn't change.</p> <p>AWS Lambda doesn't publish a version if the function's configuration and code haven't changed since the last version. Use <a>UpdateFunctionCode</a> or <a>UpdateFunctionConfiguration</a> to update the function before publishing a version.</p> <p>Clients can invoke versions directly or with an alias. To create an alias, use <a>CreateAlias</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_21626753 = newJObject()
  var body_21626754 = newJObject()
  add(path_21626753, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_21626754 = body
  result = call_21626752.call(path_21626753, nil, nil, nil, body_21626754)

var publishVersion* = Call_PublishVersion_21626739(name: "publishVersion",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/versions",
    validator: validate_PublishVersion_21626740, base: "/",
    makeUrl: url_PublishVersion_21626741, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVersionsByFunction_21626722 = ref object of OpenApiRestCall_21625435
proc url_ListVersionsByFunction_21626724(protocol: Scheme; host: string;
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
               (kind: ConstantSegment, value: "/versions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListVersionsByFunction_21626723(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626725 = path.getOrDefault("FunctionName")
  valid_21626725 = validateParameter(valid_21626725, JString, required = true,
                                   default = nil)
  if valid_21626725 != nil:
    section.add "FunctionName", valid_21626725
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: JInt
  ##           : The maximum number of versions to return.
  section = newJObject()
  var valid_21626726 = query.getOrDefault("Marker")
  valid_21626726 = validateParameter(valid_21626726, JString, required = false,
                                   default = nil)
  if valid_21626726 != nil:
    section.add "Marker", valid_21626726
  var valid_21626727 = query.getOrDefault("MaxItems")
  valid_21626727 = validateParameter(valid_21626727, JInt, required = false,
                                   default = nil)
  if valid_21626727 != nil:
    section.add "MaxItems", valid_21626727
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
  var valid_21626728 = header.getOrDefault("X-Amz-Date")
  valid_21626728 = validateParameter(valid_21626728, JString, required = false,
                                   default = nil)
  if valid_21626728 != nil:
    section.add "X-Amz-Date", valid_21626728
  var valid_21626729 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626729 = validateParameter(valid_21626729, JString, required = false,
                                   default = nil)
  if valid_21626729 != nil:
    section.add "X-Amz-Security-Token", valid_21626729
  var valid_21626730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626730 = validateParameter(valid_21626730, JString, required = false,
                                   default = nil)
  if valid_21626730 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626730
  var valid_21626731 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626731 = validateParameter(valid_21626731, JString, required = false,
                                   default = nil)
  if valid_21626731 != nil:
    section.add "X-Amz-Algorithm", valid_21626731
  var valid_21626732 = header.getOrDefault("X-Amz-Signature")
  valid_21626732 = validateParameter(valid_21626732, JString, required = false,
                                   default = nil)
  if valid_21626732 != nil:
    section.add "X-Amz-Signature", valid_21626732
  var valid_21626733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626733 = validateParameter(valid_21626733, JString, required = false,
                                   default = nil)
  if valid_21626733 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626733
  var valid_21626734 = header.getOrDefault("X-Amz-Credential")
  valid_21626734 = validateParameter(valid_21626734, JString, required = false,
                                   default = nil)
  if valid_21626734 != nil:
    section.add "X-Amz-Credential", valid_21626734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626735: Call_ListVersionsByFunction_21626722;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">versions</a>, with the version-specific configuration of each. Lambda returns up to 50 versions per call.
  ## 
  let valid = call_21626735.validator(path, query, header, formData, body, _)
  let scheme = call_21626735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626735.makeUrl(scheme.get, call_21626735.host, call_21626735.base,
                               call_21626735.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626735, uri, valid, _)

proc call*(call_21626736: Call_ListVersionsByFunction_21626722;
          FunctionName: string; Marker: string = ""; MaxItems: int = 0): Recallable =
  ## listVersionsByFunction
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">versions</a>, with the version-specific configuration of each. Lambda returns up to 50 versions per call.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Marker: string
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: int
  ##           : The maximum number of versions to return.
  var path_21626737 = newJObject()
  var query_21626738 = newJObject()
  add(path_21626737, "FunctionName", newJString(FunctionName))
  add(query_21626738, "Marker", newJString(Marker))
  add(query_21626738, "MaxItems", newJInt(MaxItems))
  result = call_21626736.call(path_21626737, query_21626738, nil, nil, nil)

var listVersionsByFunction* = Call_ListVersionsByFunction_21626722(
    name: "listVersionsByFunction", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/versions",
    validator: validate_ListVersionsByFunction_21626723, base: "/",
    makeUrl: url_ListVersionsByFunction_21626724,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveLayerVersionPermission_21626755 = ref object of OpenApiRestCall_21625435
proc url_RemoveLayerVersionPermission_21626757(protocol: Scheme; host: string;
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

proc validate_RemoveLayerVersionPermission_21626756(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Removes a statement from the permissions policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   VersionNumber: JInt (required)
  ##                : The version number.
  ##   StatementId: JString (required)
  ##              : The identifier that was specified when the statement was added.
  ##   LayerName: JString (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `VersionNumber` field"
  var valid_21626758 = path.getOrDefault("VersionNumber")
  valid_21626758 = validateParameter(valid_21626758, JInt, required = true,
                                   default = nil)
  if valid_21626758 != nil:
    section.add "VersionNumber", valid_21626758
  var valid_21626759 = path.getOrDefault("StatementId")
  valid_21626759 = validateParameter(valid_21626759, JString, required = true,
                                   default = nil)
  if valid_21626759 != nil:
    section.add "StatementId", valid_21626759
  var valid_21626760 = path.getOrDefault("LayerName")
  valid_21626760 = validateParameter(valid_21626760, JString, required = true,
                                   default = nil)
  if valid_21626760 != nil:
    section.add "LayerName", valid_21626760
  result.add "path", section
  ## parameters in `query` object:
  ##   RevisionId: JString
  ##             : Only update the policy if the revision ID matches the ID specified. Use this option to avoid modifying a policy that has changed since you last read it.
  section = newJObject()
  var valid_21626761 = query.getOrDefault("RevisionId")
  valid_21626761 = validateParameter(valid_21626761, JString, required = false,
                                   default = nil)
  if valid_21626761 != nil:
    section.add "RevisionId", valid_21626761
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
  var valid_21626762 = header.getOrDefault("X-Amz-Date")
  valid_21626762 = validateParameter(valid_21626762, JString, required = false,
                                   default = nil)
  if valid_21626762 != nil:
    section.add "X-Amz-Date", valid_21626762
  var valid_21626763 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626763 = validateParameter(valid_21626763, JString, required = false,
                                   default = nil)
  if valid_21626763 != nil:
    section.add "X-Amz-Security-Token", valid_21626763
  var valid_21626764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626764 = validateParameter(valid_21626764, JString, required = false,
                                   default = nil)
  if valid_21626764 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626764
  var valid_21626765 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626765 = validateParameter(valid_21626765, JString, required = false,
                                   default = nil)
  if valid_21626765 != nil:
    section.add "X-Amz-Algorithm", valid_21626765
  var valid_21626766 = header.getOrDefault("X-Amz-Signature")
  valid_21626766 = validateParameter(valid_21626766, JString, required = false,
                                   default = nil)
  if valid_21626766 != nil:
    section.add "X-Amz-Signature", valid_21626766
  var valid_21626767 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626767 = validateParameter(valid_21626767, JString, required = false,
                                   default = nil)
  if valid_21626767 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626767
  var valid_21626768 = header.getOrDefault("X-Amz-Credential")
  valid_21626768 = validateParameter(valid_21626768, JString, required = false,
                                   default = nil)
  if valid_21626768 != nil:
    section.add "X-Amz-Credential", valid_21626768
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626769: Call_RemoveLayerVersionPermission_21626755;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a statement from the permissions policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ## 
  let valid = call_21626769.validator(path, query, header, formData, body, _)
  let scheme = call_21626769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626769.makeUrl(scheme.get, call_21626769.host, call_21626769.base,
                               call_21626769.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626769, uri, valid, _)

proc call*(call_21626770: Call_RemoveLayerVersionPermission_21626755;
          VersionNumber: int; StatementId: string; LayerName: string;
          RevisionId: string = ""): Recallable =
  ## removeLayerVersionPermission
  ## Removes a statement from the permissions policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ##   RevisionId: string
  ##             : Only update the policy if the revision ID matches the ID specified. Use this option to avoid modifying a policy that has changed since you last read it.
  ##   VersionNumber: int (required)
  ##                : The version number.
  ##   StatementId: string (required)
  ##              : The identifier that was specified when the statement was added.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  var path_21626771 = newJObject()
  var query_21626772 = newJObject()
  add(query_21626772, "RevisionId", newJString(RevisionId))
  add(path_21626771, "VersionNumber", newJInt(VersionNumber))
  add(path_21626771, "StatementId", newJString(StatementId))
  add(path_21626771, "LayerName", newJString(LayerName))
  result = call_21626770.call(path_21626771, query_21626772, nil, nil, nil)

var removeLayerVersionPermission* = Call_RemoveLayerVersionPermission_21626755(
    name: "removeLayerVersionPermission", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com", route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy/{StatementId}",
    validator: validate_RemoveLayerVersionPermission_21626756, base: "/",
    makeUrl: url_RemoveLayerVersionPermission_21626757,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemovePermission_21626773 = ref object of OpenApiRestCall_21625435
proc url_RemovePermission_21626775(protocol: Scheme; host: string; base: string;
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

proc validate_RemovePermission_21626774(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626776 = path.getOrDefault("FunctionName")
  valid_21626776 = validateParameter(valid_21626776, JString, required = true,
                                   default = nil)
  if valid_21626776 != nil:
    section.add "FunctionName", valid_21626776
  var valid_21626777 = path.getOrDefault("StatementId")
  valid_21626777 = validateParameter(valid_21626777, JString, required = true,
                                   default = nil)
  if valid_21626777 != nil:
    section.add "StatementId", valid_21626777
  result.add "path", section
  ## parameters in `query` object:
  ##   RevisionId: JString
  ##             : Only update the policy if the revision ID matches the ID that's specified. Use this option to avoid modifying a policy that has changed since you last read it.
  ##   Qualifier: JString
  ##            : Specify a version or alias to remove permissions from a published version of the function.
  section = newJObject()
  var valid_21626778 = query.getOrDefault("RevisionId")
  valid_21626778 = validateParameter(valid_21626778, JString, required = false,
                                   default = nil)
  if valid_21626778 != nil:
    section.add "RevisionId", valid_21626778
  var valid_21626779 = query.getOrDefault("Qualifier")
  valid_21626779 = validateParameter(valid_21626779, JString, required = false,
                                   default = nil)
  if valid_21626779 != nil:
    section.add "Qualifier", valid_21626779
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
  var valid_21626780 = header.getOrDefault("X-Amz-Date")
  valid_21626780 = validateParameter(valid_21626780, JString, required = false,
                                   default = nil)
  if valid_21626780 != nil:
    section.add "X-Amz-Date", valid_21626780
  var valid_21626781 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626781 = validateParameter(valid_21626781, JString, required = false,
                                   default = nil)
  if valid_21626781 != nil:
    section.add "X-Amz-Security-Token", valid_21626781
  var valid_21626782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626782 = validateParameter(valid_21626782, JString, required = false,
                                   default = nil)
  if valid_21626782 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626782
  var valid_21626783 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626783 = validateParameter(valid_21626783, JString, required = false,
                                   default = nil)
  if valid_21626783 != nil:
    section.add "X-Amz-Algorithm", valid_21626783
  var valid_21626784 = header.getOrDefault("X-Amz-Signature")
  valid_21626784 = validateParameter(valid_21626784, JString, required = false,
                                   default = nil)
  if valid_21626784 != nil:
    section.add "X-Amz-Signature", valid_21626784
  var valid_21626785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626785 = validateParameter(valid_21626785, JString, required = false,
                                   default = nil)
  if valid_21626785 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626785
  var valid_21626786 = header.getOrDefault("X-Amz-Credential")
  valid_21626786 = validateParameter(valid_21626786, JString, required = false,
                                   default = nil)
  if valid_21626786 != nil:
    section.add "X-Amz-Credential", valid_21626786
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626787: Call_RemovePermission_21626773; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Revokes function-use permission from an AWS service or another account. You can get the ID of the statement from the output of <a>GetPolicy</a>.
  ## 
  let valid = call_21626787.validator(path, query, header, formData, body, _)
  let scheme = call_21626787.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626787.makeUrl(scheme.get, call_21626787.host, call_21626787.base,
                               call_21626787.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626787, uri, valid, _)

proc call*(call_21626788: Call_RemovePermission_21626773; FunctionName: string;
          StatementId: string; RevisionId: string = ""; Qualifier: string = ""): Recallable =
  ## removePermission
  ## Revokes function-use permission from an AWS service or another account. You can get the ID of the statement from the output of <a>GetPolicy</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   RevisionId: string
  ##             : Only update the policy if the revision ID matches the ID that's specified. Use this option to avoid modifying a policy that has changed since you last read it.
  ##   StatementId: string (required)
  ##              : Statement ID of the permission to remove.
  ##   Qualifier: string
  ##            : Specify a version or alias to remove permissions from a published version of the function.
  var path_21626789 = newJObject()
  var query_21626790 = newJObject()
  add(path_21626789, "FunctionName", newJString(FunctionName))
  add(query_21626790, "RevisionId", newJString(RevisionId))
  add(path_21626789, "StatementId", newJString(StatementId))
  add(query_21626790, "Qualifier", newJString(Qualifier))
  result = call_21626788.call(path_21626789, query_21626790, nil, nil, nil)

var removePermission* = Call_RemovePermission_21626773(name: "removePermission",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/policy/{StatementId}",
    validator: validate_RemovePermission_21626774, base: "/",
    makeUrl: url_RemovePermission_21626775, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21626791 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21626793(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_21626792(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Removes <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> from a function.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ARN: JString (required)
  ##      : The function's Amazon Resource Name (ARN).
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `ARN` field"
  var valid_21626794 = path.getOrDefault("ARN")
  valid_21626794 = validateParameter(valid_21626794, JString, required = true,
                                   default = nil)
  if valid_21626794 != nil:
    section.add "ARN", valid_21626794
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A list of tag keys to remove from the function.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_21626795 = query.getOrDefault("tagKeys")
  valid_21626795 = validateParameter(valid_21626795, JArray, required = true,
                                   default = nil)
  if valid_21626795 != nil:
    section.add "tagKeys", valid_21626795
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
  var valid_21626796 = header.getOrDefault("X-Amz-Date")
  valid_21626796 = validateParameter(valid_21626796, JString, required = false,
                                   default = nil)
  if valid_21626796 != nil:
    section.add "X-Amz-Date", valid_21626796
  var valid_21626797 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626797 = validateParameter(valid_21626797, JString, required = false,
                                   default = nil)
  if valid_21626797 != nil:
    section.add "X-Amz-Security-Token", valid_21626797
  var valid_21626798 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626798 = validateParameter(valid_21626798, JString, required = false,
                                   default = nil)
  if valid_21626798 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626798
  var valid_21626799 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626799 = validateParameter(valid_21626799, JString, required = false,
                                   default = nil)
  if valid_21626799 != nil:
    section.add "X-Amz-Algorithm", valid_21626799
  var valid_21626800 = header.getOrDefault("X-Amz-Signature")
  valid_21626800 = validateParameter(valid_21626800, JString, required = false,
                                   default = nil)
  if valid_21626800 != nil:
    section.add "X-Amz-Signature", valid_21626800
  var valid_21626801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626801 = validateParameter(valid_21626801, JString, required = false,
                                   default = nil)
  if valid_21626801 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626801
  var valid_21626802 = header.getOrDefault("X-Amz-Credential")
  valid_21626802 = validateParameter(valid_21626802, JString, required = false,
                                   default = nil)
  if valid_21626802 != nil:
    section.add "X-Amz-Credential", valid_21626802
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626803: Call_UntagResource_21626791; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> from a function.
  ## 
  let valid = call_21626803.validator(path, query, header, formData, body, _)
  let scheme = call_21626803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626803.makeUrl(scheme.get, call_21626803.host, call_21626803.base,
                               call_21626803.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626803, uri, valid, _)

proc call*(call_21626804: Call_UntagResource_21626791; ARN: string; tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> from a function.
  ##   ARN: string (required)
  ##      : The function's Amazon Resource Name (ARN).
  ##   tagKeys: JArray (required)
  ##          : A list of tag keys to remove from the function.
  var path_21626805 = newJObject()
  var query_21626806 = newJObject()
  add(path_21626805, "ARN", newJString(ARN))
  if tagKeys != nil:
    query_21626806.add "tagKeys", tagKeys
  result = call_21626804.call(path_21626805, query_21626806, nil, nil, nil)

var untagResource* = Call_UntagResource_21626791(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2017-03-31/tags/{ARN}#tagKeys", validator: validate_UntagResource_21626792,
    base: "/", makeUrl: url_UntagResource_21626793,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionCode_21626807 = ref object of OpenApiRestCall_21625435
proc url_UpdateFunctionCode_21626809(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFunctionCode_21626808(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626810 = path.getOrDefault("FunctionName")
  valid_21626810 = validateParameter(valid_21626810, JString, required = true,
                                   default = nil)
  if valid_21626810 != nil:
    section.add "FunctionName", valid_21626810
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
  var valid_21626811 = header.getOrDefault("X-Amz-Date")
  valid_21626811 = validateParameter(valid_21626811, JString, required = false,
                                   default = nil)
  if valid_21626811 != nil:
    section.add "X-Amz-Date", valid_21626811
  var valid_21626812 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626812 = validateParameter(valid_21626812, JString, required = false,
                                   default = nil)
  if valid_21626812 != nil:
    section.add "X-Amz-Security-Token", valid_21626812
  var valid_21626813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626813 = validateParameter(valid_21626813, JString, required = false,
                                   default = nil)
  if valid_21626813 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626813
  var valid_21626814 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626814 = validateParameter(valid_21626814, JString, required = false,
                                   default = nil)
  if valid_21626814 != nil:
    section.add "X-Amz-Algorithm", valid_21626814
  var valid_21626815 = header.getOrDefault("X-Amz-Signature")
  valid_21626815 = validateParameter(valid_21626815, JString, required = false,
                                   default = nil)
  if valid_21626815 != nil:
    section.add "X-Amz-Signature", valid_21626815
  var valid_21626816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626816 = validateParameter(valid_21626816, JString, required = false,
                                   default = nil)
  if valid_21626816 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626816
  var valid_21626817 = header.getOrDefault("X-Amz-Credential")
  valid_21626817 = validateParameter(valid_21626817, JString, required = false,
                                   default = nil)
  if valid_21626817 != nil:
    section.add "X-Amz-Credential", valid_21626817
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

proc call*(call_21626819: Call_UpdateFunctionCode_21626807; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates a Lambda function's code.</p> <p>The function's code is locked when you publish a version. You can't modify the code of a published version, only the unpublished version.</p>
  ## 
  let valid = call_21626819.validator(path, query, header, formData, body, _)
  let scheme = call_21626819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626819.makeUrl(scheme.get, call_21626819.host, call_21626819.base,
                               call_21626819.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626819, uri, valid, _)

proc call*(call_21626820: Call_UpdateFunctionCode_21626807; FunctionName: string;
          body: JsonNode): Recallable =
  ## updateFunctionCode
  ## <p>Updates a Lambda function's code.</p> <p>The function's code is locked when you publish a version. You can't modify the code of a published version, only the unpublished version.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_21626821 = newJObject()
  var body_21626822 = newJObject()
  add(path_21626821, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_21626822 = body
  result = call_21626820.call(path_21626821, nil, nil, nil, body_21626822)

var updateFunctionCode* = Call_UpdateFunctionCode_21626807(
    name: "updateFunctionCode", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/code",
    validator: validate_UpdateFunctionCode_21626808, base: "/",
    makeUrl: url_UpdateFunctionCode_21626809, schemes: {Scheme.Https, Scheme.Http})
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