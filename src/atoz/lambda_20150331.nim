
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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddLayerVersionPermission_606198 = ref object of OpenApiRestCall_605589
proc url_AddLayerVersionPermission_606200(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AddLayerVersionPermission_606199(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606201 = path.getOrDefault("VersionNumber")
  valid_606201 = validateParameter(valid_606201, JInt, required = true, default = nil)
  if valid_606201 != nil:
    section.add "VersionNumber", valid_606201
  var valid_606202 = path.getOrDefault("LayerName")
  valid_606202 = validateParameter(valid_606202, JString, required = true,
                                 default = nil)
  if valid_606202 != nil:
    section.add "LayerName", valid_606202
  result.add "path", section
  ## parameters in `query` object:
  ##   RevisionId: JString
  ##             : Only update the policy if the revision ID matches the ID specified. Use this option to avoid modifying a policy that has changed since you last read it.
  section = newJObject()
  var valid_606203 = query.getOrDefault("RevisionId")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "RevisionId", valid_606203
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
  var valid_606204 = header.getOrDefault("X-Amz-Signature")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Signature", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Content-Sha256", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Date")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Date", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-Credential")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Credential", valid_606207
  var valid_606208 = header.getOrDefault("X-Amz-Security-Token")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-Security-Token", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-Algorithm")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-Algorithm", valid_606209
  var valid_606210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606210 = validateParameter(valid_606210, JString, required = false,
                                 default = nil)
  if valid_606210 != nil:
    section.add "X-Amz-SignedHeaders", valid_606210
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606212: Call_AddLayerVersionPermission_606198; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds permissions to the resource-based policy of a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Use this action to grant layer usage permission to other accounts. You can grant permission to a single account, all AWS accounts, or all accounts in an organization.</p> <p>To revoke permission, call <a>RemoveLayerVersionPermission</a> with the statement ID that you specified when you added it.</p>
  ## 
  let valid = call_606212.validator(path, query, header, formData, body)
  let scheme = call_606212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606212.url(scheme.get, call_606212.host, call_606212.base,
                         call_606212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606212, url, valid)

proc call*(call_606213: Call_AddLayerVersionPermission_606198; VersionNumber: int;
          LayerName: string; body: JsonNode; RevisionId: string = ""): Recallable =
  ## addLayerVersionPermission
  ## <p>Adds permissions to the resource-based policy of a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Use this action to grant layer usage permission to other accounts. You can grant permission to a single account, all AWS accounts, or all accounts in an organization.</p> <p>To revoke permission, call <a>RemoveLayerVersionPermission</a> with the statement ID that you specified when you added it.</p>
  ##   RevisionId: string
  ##             : Only update the policy if the revision ID matches the ID specified. Use this option to avoid modifying a policy that has changed since you last read it.
  ##   VersionNumber: int (required)
  ##                : The version number.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  ##   body: JObject (required)
  var path_606214 = newJObject()
  var query_606215 = newJObject()
  var body_606216 = newJObject()
  add(query_606215, "RevisionId", newJString(RevisionId))
  add(path_606214, "VersionNumber", newJInt(VersionNumber))
  add(path_606214, "LayerName", newJString(LayerName))
  if body != nil:
    body_606216 = body
  result = call_606213.call(path_606214, query_606215, nil, nil, body_606216)

var addLayerVersionPermission* = Call_AddLayerVersionPermission_606198(
    name: "addLayerVersionPermission", meth: HttpMethod.HttpPost,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy",
    validator: validate_AddLayerVersionPermission_606199, base: "/",
    url: url_AddLayerVersionPermission_606200,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLayerVersionPolicy_605927 = ref object of OpenApiRestCall_605589
proc url_GetLayerVersionPolicy_605929(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetLayerVersionPolicy_605928(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606055 = path.getOrDefault("VersionNumber")
  valid_606055 = validateParameter(valid_606055, JInt, required = true, default = nil)
  if valid_606055 != nil:
    section.add "VersionNumber", valid_606055
  var valid_606056 = path.getOrDefault("LayerName")
  valid_606056 = validateParameter(valid_606056, JString, required = true,
                                 default = nil)
  if valid_606056 != nil:
    section.add "LayerName", valid_606056
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
  var valid_606057 = header.getOrDefault("X-Amz-Signature")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Signature", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Content-Sha256", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Date")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Date", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Credential")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Credential", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-Security-Token")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-Security-Token", valid_606061
  var valid_606062 = header.getOrDefault("X-Amz-Algorithm")
  valid_606062 = validateParameter(valid_606062, JString, required = false,
                                 default = nil)
  if valid_606062 != nil:
    section.add "X-Amz-Algorithm", valid_606062
  var valid_606063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606063 = validateParameter(valid_606063, JString, required = false,
                                 default = nil)
  if valid_606063 != nil:
    section.add "X-Amz-SignedHeaders", valid_606063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606086: Call_GetLayerVersionPolicy_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the permission policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ## 
  let valid = call_606086.validator(path, query, header, formData, body)
  let scheme = call_606086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606086.url(scheme.get, call_606086.host, call_606086.base,
                         call_606086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606086, url, valid)

proc call*(call_606157: Call_GetLayerVersionPolicy_605927; VersionNumber: int;
          LayerName: string): Recallable =
  ## getLayerVersionPolicy
  ## Returns the permission policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ##   VersionNumber: int (required)
  ##                : The version number.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  var path_606158 = newJObject()
  add(path_606158, "VersionNumber", newJInt(VersionNumber))
  add(path_606158, "LayerName", newJString(LayerName))
  result = call_606157.call(path_606158, nil, nil, nil, nil)

var getLayerVersionPolicy* = Call_GetLayerVersionPolicy_605927(
    name: "getLayerVersionPolicy", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy",
    validator: validate_GetLayerVersionPolicy_605928, base: "/",
    url: url_GetLayerVersionPolicy_605929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddPermission_606233 = ref object of OpenApiRestCall_605589
proc url_AddPermission_606235(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AddPermission_606234(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606236 = path.getOrDefault("FunctionName")
  valid_606236 = validateParameter(valid_606236, JString, required = true,
                                 default = nil)
  if valid_606236 != nil:
    section.add "FunctionName", valid_606236
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to add permissions to a published version of the function.
  section = newJObject()
  var valid_606237 = query.getOrDefault("Qualifier")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "Qualifier", valid_606237
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
  var valid_606238 = header.getOrDefault("X-Amz-Signature")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-Signature", valid_606238
  var valid_606239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-Content-Sha256", valid_606239
  var valid_606240 = header.getOrDefault("X-Amz-Date")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-Date", valid_606240
  var valid_606241 = header.getOrDefault("X-Amz-Credential")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "X-Amz-Credential", valid_606241
  var valid_606242 = header.getOrDefault("X-Amz-Security-Token")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "X-Amz-Security-Token", valid_606242
  var valid_606243 = header.getOrDefault("X-Amz-Algorithm")
  valid_606243 = validateParameter(valid_606243, JString, required = false,
                                 default = nil)
  if valid_606243 != nil:
    section.add "X-Amz-Algorithm", valid_606243
  var valid_606244 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606244 = validateParameter(valid_606244, JString, required = false,
                                 default = nil)
  if valid_606244 != nil:
    section.add "X-Amz-SignedHeaders", valid_606244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606246: Call_AddPermission_606233; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Grants an AWS service or another account permission to use a function. You can apply the policy at the function level, or specify a qualifier to restrict access to a single version or alias. If you use a qualifier, the invoker must use the full Amazon Resource Name (ARN) of that version or alias to invoke the function.</p> <p>To grant permission to another account, specify the account ID as the <code>Principal</code>. For AWS services, the principal is a domain-style identifier defined by the service, like <code>s3.amazonaws.com</code> or <code>sns.amazonaws.com</code>. For AWS services, you can also specify the ARN or owning account of the associated resource as the <code>SourceArn</code> or <code>SourceAccount</code>. If you grant permission to a service principal without specifying the source, other accounts could potentially configure resources in their account to invoke your Lambda function.</p> <p>This action adds a statement to a resource-based permissions policy for the function. For more information about function policies, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">Lambda Function Policies</a>. </p>
  ## 
  let valid = call_606246.validator(path, query, header, formData, body)
  let scheme = call_606246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606246.url(scheme.get, call_606246.host, call_606246.base,
                         call_606246.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606246, url, valid)

proc call*(call_606247: Call_AddPermission_606233; FunctionName: string;
          body: JsonNode; Qualifier: string = ""): Recallable =
  ## addPermission
  ## <p>Grants an AWS service or another account permission to use a function. You can apply the policy at the function level, or specify a qualifier to restrict access to a single version or alias. If you use a qualifier, the invoker must use the full Amazon Resource Name (ARN) of that version or alias to invoke the function.</p> <p>To grant permission to another account, specify the account ID as the <code>Principal</code>. For AWS services, the principal is a domain-style identifier defined by the service, like <code>s3.amazonaws.com</code> or <code>sns.amazonaws.com</code>. For AWS services, you can also specify the ARN or owning account of the associated resource as the <code>SourceArn</code> or <code>SourceAccount</code>. If you grant permission to a service principal without specifying the source, other accounts could potentially configure resources in their account to invoke your Lambda function.</p> <p>This action adds a statement to a resource-based permissions policy for the function. For more information about function policies, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">Lambda Function Policies</a>. </p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to add permissions to a published version of the function.
  ##   body: JObject (required)
  var path_606248 = newJObject()
  var query_606249 = newJObject()
  var body_606250 = newJObject()
  add(path_606248, "FunctionName", newJString(FunctionName))
  add(query_606249, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_606250 = body
  result = call_606247.call(path_606248, query_606249, nil, nil, body_606250)

var addPermission* = Call_AddPermission_606233(name: "addPermission",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/policy",
    validator: validate_AddPermission_606234, base: "/", url: url_AddPermission_606235,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPolicy_606217 = ref object of OpenApiRestCall_605589
proc url_GetPolicy_606219(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetPolicy_606218(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606220 = path.getOrDefault("FunctionName")
  valid_606220 = validateParameter(valid_606220, JString, required = true,
                                 default = nil)
  if valid_606220 != nil:
    section.add "FunctionName", valid_606220
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to get the policy for that resource.
  section = newJObject()
  var valid_606221 = query.getOrDefault("Qualifier")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "Qualifier", valid_606221
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
  var valid_606222 = header.getOrDefault("X-Amz-Signature")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "X-Amz-Signature", valid_606222
  var valid_606223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-Content-Sha256", valid_606223
  var valid_606224 = header.getOrDefault("X-Amz-Date")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Date", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-Credential")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-Credential", valid_606225
  var valid_606226 = header.getOrDefault("X-Amz-Security-Token")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "X-Amz-Security-Token", valid_606226
  var valid_606227 = header.getOrDefault("X-Amz-Algorithm")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "X-Amz-Algorithm", valid_606227
  var valid_606228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606228 = validateParameter(valid_606228, JString, required = false,
                                 default = nil)
  if valid_606228 != nil:
    section.add "X-Amz-SignedHeaders", valid_606228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606229: Call_GetPolicy_606217; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">resource-based IAM policy</a> for a function, version, or alias.
  ## 
  let valid = call_606229.validator(path, query, header, formData, body)
  let scheme = call_606229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606229.url(scheme.get, call_606229.host, call_606229.base,
                         call_606229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606229, url, valid)

proc call*(call_606230: Call_GetPolicy_606217; FunctionName: string;
          Qualifier: string = ""): Recallable =
  ## getPolicy
  ## Returns the <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">resource-based IAM policy</a> for a function, version, or alias.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to get the policy for that resource.
  var path_606231 = newJObject()
  var query_606232 = newJObject()
  add(path_606231, "FunctionName", newJString(FunctionName))
  add(query_606232, "Qualifier", newJString(Qualifier))
  result = call_606230.call(path_606231, query_606232, nil, nil, nil)

var getPolicy* = Call_GetPolicy_606217(name: "getPolicy", meth: HttpMethod.HttpGet,
                                    host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/policy",
                                    validator: validate_GetPolicy_606218,
                                    base: "/", url: url_GetPolicy_606219,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAlias_606269 = ref object of OpenApiRestCall_605589
proc url_CreateAlias_606271(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateAlias_606270(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606272 = path.getOrDefault("FunctionName")
  valid_606272 = validateParameter(valid_606272, JString, required = true,
                                 default = nil)
  if valid_606272 != nil:
    section.add "FunctionName", valid_606272
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
  var valid_606273 = header.getOrDefault("X-Amz-Signature")
  valid_606273 = validateParameter(valid_606273, JString, required = false,
                                 default = nil)
  if valid_606273 != nil:
    section.add "X-Amz-Signature", valid_606273
  var valid_606274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "X-Amz-Content-Sha256", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Date")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Date", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Credential")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Credential", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Security-Token")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Security-Token", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Algorithm")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Algorithm", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-SignedHeaders", valid_606279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606281: Call_CreateAlias_606269; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a> for a Lambda function version. Use aliases to provide clients with a function identifier that you can update to invoke a different version.</p> <p>You can also map an alias to split invocation requests between two versions. Use the <code>RoutingConfig</code> parameter to specify a second version and the percentage of invocation requests that it receives.</p>
  ## 
  let valid = call_606281.validator(path, query, header, formData, body)
  let scheme = call_606281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606281.url(scheme.get, call_606281.host, call_606281.base,
                         call_606281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606281, url, valid)

proc call*(call_606282: Call_CreateAlias_606269; FunctionName: string; body: JsonNode): Recallable =
  ## createAlias
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a> for a Lambda function version. Use aliases to provide clients with a function identifier that you can update to invoke a different version.</p> <p>You can also map an alias to split invocation requests between two versions. Use the <code>RoutingConfig</code> parameter to specify a second version and the percentage of invocation requests that it receives.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_606283 = newJObject()
  var body_606284 = newJObject()
  add(path_606283, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_606284 = body
  result = call_606282.call(path_606283, nil, nil, nil, body_606284)

var createAlias* = Call_CreateAlias_606269(name: "createAlias",
                                        meth: HttpMethod.HttpPost,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases",
                                        validator: validate_CreateAlias_606270,
                                        base: "/", url: url_CreateAlias_606271,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAliases_606251 = ref object of OpenApiRestCall_605589
proc url_ListAliases_606253(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListAliases_606252(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606254 = path.getOrDefault("FunctionName")
  valid_606254 = validateParameter(valid_606254, JString, required = true,
                                 default = nil)
  if valid_606254 != nil:
    section.add "FunctionName", valid_606254
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   FunctionVersion: JString
  ##                  : Specify a function version to only list aliases that invoke that version.
  ##   MaxItems: JInt
  ##           : Limit the number of aliases returned.
  section = newJObject()
  var valid_606255 = query.getOrDefault("Marker")
  valid_606255 = validateParameter(valid_606255, JString, required = false,
                                 default = nil)
  if valid_606255 != nil:
    section.add "Marker", valid_606255
  var valid_606256 = query.getOrDefault("FunctionVersion")
  valid_606256 = validateParameter(valid_606256, JString, required = false,
                                 default = nil)
  if valid_606256 != nil:
    section.add "FunctionVersion", valid_606256
  var valid_606257 = query.getOrDefault("MaxItems")
  valid_606257 = validateParameter(valid_606257, JInt, required = false, default = nil)
  if valid_606257 != nil:
    section.add "MaxItems", valid_606257
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
  var valid_606258 = header.getOrDefault("X-Amz-Signature")
  valid_606258 = validateParameter(valid_606258, JString, required = false,
                                 default = nil)
  if valid_606258 != nil:
    section.add "X-Amz-Signature", valid_606258
  var valid_606259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606259 = validateParameter(valid_606259, JString, required = false,
                                 default = nil)
  if valid_606259 != nil:
    section.add "X-Amz-Content-Sha256", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-Date")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Date", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Credential")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Credential", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Security-Token")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Security-Token", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Algorithm")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Algorithm", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-SignedHeaders", valid_606264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606265: Call_ListAliases_606251; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">aliases</a> for a Lambda function.
  ## 
  let valid = call_606265.validator(path, query, header, formData, body)
  let scheme = call_606265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606265.url(scheme.get, call_606265.host, call_606265.base,
                         call_606265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606265, url, valid)

proc call*(call_606266: Call_ListAliases_606251; FunctionName: string;
          Marker: string = ""; FunctionVersion: string = ""; MaxItems: int = 0): Recallable =
  ## listAliases
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">aliases</a> for a Lambda function.
  ##   Marker: string
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   FunctionVersion: string
  ##                  : Specify a function version to only list aliases that invoke that version.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   MaxItems: int
  ##           : Limit the number of aliases returned.
  var path_606267 = newJObject()
  var query_606268 = newJObject()
  add(query_606268, "Marker", newJString(Marker))
  add(query_606268, "FunctionVersion", newJString(FunctionVersion))
  add(path_606267, "FunctionName", newJString(FunctionName))
  add(query_606268, "MaxItems", newJInt(MaxItems))
  result = call_606266.call(path_606267, query_606268, nil, nil, nil)

var listAliases* = Call_ListAliases_606251(name: "listAliases",
                                        meth: HttpMethod.HttpGet,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases",
                                        validator: validate_ListAliases_606252,
                                        base: "/", url: url_ListAliases_606253,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEventSourceMapping_606302 = ref object of OpenApiRestCall_605589
proc url_CreateEventSourceMapping_606304(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateEventSourceMapping_606303(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a mapping between an event source and an AWS Lambda function. Lambda reads items from the event source and triggers the function.</p> <p>For details about each event source type, see the following topics.</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html">Using AWS Lambda with Amazon DynamoDB</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html">Using AWS Lambda with Amazon Kinesis</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html">Using AWS Lambda with Amazon SQS</a> </p> </li> </ul> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> </ul>
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
  var valid_606305 = header.getOrDefault("X-Amz-Signature")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Signature", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Content-Sha256", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Date")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Date", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Credential")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Credential", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Security-Token")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Security-Token", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Algorithm")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Algorithm", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-SignedHeaders", valid_606311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606313: Call_CreateEventSourceMapping_606302; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a mapping between an event source and an AWS Lambda function. Lambda reads items from the event source and triggers the function.</p> <p>For details about each event source type, see the following topics.</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html">Using AWS Lambda with Amazon DynamoDB</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html">Using AWS Lambda with Amazon Kinesis</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html">Using AWS Lambda with Amazon SQS</a> </p> </li> </ul> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> </ul>
  ## 
  let valid = call_606313.validator(path, query, header, formData, body)
  let scheme = call_606313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606313.url(scheme.get, call_606313.host, call_606313.base,
                         call_606313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606313, url, valid)

proc call*(call_606314: Call_CreateEventSourceMapping_606302; body: JsonNode): Recallable =
  ## createEventSourceMapping
  ## <p>Creates a mapping between an event source and an AWS Lambda function. Lambda reads items from the event source and triggers the function.</p> <p>For details about each event source type, see the following topics.</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html">Using AWS Lambda with Amazon DynamoDB</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html">Using AWS Lambda with Amazon Kinesis</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html">Using AWS Lambda with Amazon SQS</a> </p> </li> </ul> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> </ul>
  ##   body: JObject (required)
  var body_606315 = newJObject()
  if body != nil:
    body_606315 = body
  result = call_606314.call(nil, nil, nil, nil, body_606315)

var createEventSourceMapping* = Call_CreateEventSourceMapping_606302(
    name: "createEventSourceMapping", meth: HttpMethod.HttpPost,
    host: "lambda.amazonaws.com", route: "/2015-03-31/event-source-mappings/",
    validator: validate_CreateEventSourceMapping_606303, base: "/",
    url: url_CreateEventSourceMapping_606304, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEventSourceMappings_606285 = ref object of OpenApiRestCall_605589
proc url_ListEventSourceMappings_606287(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEventSourceMappings_606286(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists event source mappings. Specify an <code>EventSourceArn</code> to only show event source mappings for a single event source.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : A pagination token returned by a previous call.
  ##   FunctionName: JString
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Version or Alias ARN</b> - 
  ## <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction:PROD</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it's limited to 64 characters in length.</p>
  ##   MaxItems: JInt
  ##           : The maximum number of event source mappings to return.
  ##   EventSourceArn: JString
  ##                 : <p>The Amazon Resource Name (ARN) of the event source.</p> <ul> <li> <p> <b>Amazon Kinesis</b> - The ARN of the data stream or a stream consumer.</p> </li> <li> <p> <b>Amazon DynamoDB Streams</b> - The ARN of the stream.</p> </li> <li> <p> <b>Amazon Simple Queue Service</b> - The ARN of the queue.</p> </li> </ul>
  section = newJObject()
  var valid_606288 = query.getOrDefault("Marker")
  valid_606288 = validateParameter(valid_606288, JString, required = false,
                                 default = nil)
  if valid_606288 != nil:
    section.add "Marker", valid_606288
  var valid_606289 = query.getOrDefault("FunctionName")
  valid_606289 = validateParameter(valid_606289, JString, required = false,
                                 default = nil)
  if valid_606289 != nil:
    section.add "FunctionName", valid_606289
  var valid_606290 = query.getOrDefault("MaxItems")
  valid_606290 = validateParameter(valid_606290, JInt, required = false, default = nil)
  if valid_606290 != nil:
    section.add "MaxItems", valid_606290
  var valid_606291 = query.getOrDefault("EventSourceArn")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "EventSourceArn", valid_606291
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
  var valid_606292 = header.getOrDefault("X-Amz-Signature")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-Signature", valid_606292
  var valid_606293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Content-Sha256", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Date")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Date", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Credential")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Credential", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-Security-Token")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-Security-Token", valid_606296
  var valid_606297 = header.getOrDefault("X-Amz-Algorithm")
  valid_606297 = validateParameter(valid_606297, JString, required = false,
                                 default = nil)
  if valid_606297 != nil:
    section.add "X-Amz-Algorithm", valid_606297
  var valid_606298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606298 = validateParameter(valid_606298, JString, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "X-Amz-SignedHeaders", valid_606298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606299: Call_ListEventSourceMappings_606285; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists event source mappings. Specify an <code>EventSourceArn</code> to only show event source mappings for a single event source.
  ## 
  let valid = call_606299.validator(path, query, header, formData, body)
  let scheme = call_606299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606299.url(scheme.get, call_606299.host, call_606299.base,
                         call_606299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606299, url, valid)

proc call*(call_606300: Call_ListEventSourceMappings_606285; Marker: string = "";
          FunctionName: string = ""; MaxItems: int = 0; EventSourceArn: string = ""): Recallable =
  ## listEventSourceMappings
  ## Lists event source mappings. Specify an <code>EventSourceArn</code> to only show event source mappings for a single event source.
  ##   Marker: string
  ##         : A pagination token returned by a previous call.
  ##   FunctionName: string
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Version or Alias ARN</b> - 
  ## <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction:PROD</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it's limited to 64 characters in length.</p>
  ##   MaxItems: int
  ##           : The maximum number of event source mappings to return.
  ##   EventSourceArn: string
  ##                 : <p>The Amazon Resource Name (ARN) of the event source.</p> <ul> <li> <p> <b>Amazon Kinesis</b> - The ARN of the data stream or a stream consumer.</p> </li> <li> <p> <b>Amazon DynamoDB Streams</b> - The ARN of the stream.</p> </li> <li> <p> <b>Amazon Simple Queue Service</b> - The ARN of the queue.</p> </li> </ul>
  var query_606301 = newJObject()
  add(query_606301, "Marker", newJString(Marker))
  add(query_606301, "FunctionName", newJString(FunctionName))
  add(query_606301, "MaxItems", newJInt(MaxItems))
  add(query_606301, "EventSourceArn", newJString(EventSourceArn))
  result = call_606300.call(nil, query_606301, nil, nil, nil)

var listEventSourceMappings* = Call_ListEventSourceMappings_606285(
    name: "listEventSourceMappings", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com", route: "/2015-03-31/event-source-mappings/",
    validator: validate_ListEventSourceMappings_606286, base: "/",
    url: url_ListEventSourceMappings_606287, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunction_606316 = ref object of OpenApiRestCall_605589
proc url_CreateFunction_606318(protocol: Scheme; host: string; base: string;
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

proc validate_CreateFunction_606317(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606319 = header.getOrDefault("X-Amz-Signature")
  valid_606319 = validateParameter(valid_606319, JString, required = false,
                                 default = nil)
  if valid_606319 != nil:
    section.add "X-Amz-Signature", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Content-Sha256", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Date")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Date", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Credential")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Credential", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Security-Token")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Security-Token", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Algorithm")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Algorithm", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-SignedHeaders", valid_606325
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606327: Call_CreateFunction_606316; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Lambda function. To create a function, you need a <a href="https://docs.aws.amazon.com/lambda/latest/dg/deployment-package-v2.html">deployment package</a> and an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-permission-model.html#lambda-intro-execution-role">execution role</a>. The deployment package contains your function code. The execution role grants the function permission to use AWS services, such as Amazon CloudWatch Logs for log streaming and AWS X-Ray for request tracing.</p> <p>When you create a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute or so. During this time, you can't invoke or modify the function. The <code>State</code>, <code>StateReason</code>, and <code>StateReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the function is ready to invoke. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Function States</a>.</p> <p>A function has an unpublished version, and can have published versions and aliases. The unpublished version changes when you update your function's code and configuration. A published version is a snapshot of your function code and configuration that can't be changed. An alias is a named resource that maps to a version, and can be changed to map to a different version. Use the <code>Publish</code> parameter to create version <code>1</code> of your function from its initial configuration.</p> <p>The other parameters let you configure version-specific and function-level settings. You can modify version-specific settings later with <a>UpdateFunctionConfiguration</a>. Function-level settings apply to both the unpublished and published versions of the function, and include tags (<a>TagResource</a>) and per-function concurrency limits (<a>PutFunctionConcurrency</a>).</p> <p>If another account or an AWS service invokes your function, use <a>AddPermission</a> to grant permission by creating a resource-based IAM policy. You can grant permissions at the function level, on a version, or on an alias.</p> <p>To invoke your function directly, use <a>Invoke</a>. To invoke your function in response to events in other AWS services, create an event source mapping (<a>CreateEventSourceMapping</a>), or configure a function trigger in the other service. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-invocation.html">Invoking Functions</a>.</p>
  ## 
  let valid = call_606327.validator(path, query, header, formData, body)
  let scheme = call_606327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606327.url(scheme.get, call_606327.host, call_606327.base,
                         call_606327.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606327, url, valid)

proc call*(call_606328: Call_CreateFunction_606316; body: JsonNode): Recallable =
  ## createFunction
  ## <p>Creates a Lambda function. To create a function, you need a <a href="https://docs.aws.amazon.com/lambda/latest/dg/deployment-package-v2.html">deployment package</a> and an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-permission-model.html#lambda-intro-execution-role">execution role</a>. The deployment package contains your function code. The execution role grants the function permission to use AWS services, such as Amazon CloudWatch Logs for log streaming and AWS X-Ray for request tracing.</p> <p>When you create a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute or so. During this time, you can't invoke or modify the function. The <code>State</code>, <code>StateReason</code>, and <code>StateReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the function is ready to invoke. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Function States</a>.</p> <p>A function has an unpublished version, and can have published versions and aliases. The unpublished version changes when you update your function's code and configuration. A published version is a snapshot of your function code and configuration that can't be changed. An alias is a named resource that maps to a version, and can be changed to map to a different version. Use the <code>Publish</code> parameter to create version <code>1</code> of your function from its initial configuration.</p> <p>The other parameters let you configure version-specific and function-level settings. You can modify version-specific settings later with <a>UpdateFunctionConfiguration</a>. Function-level settings apply to both the unpublished and published versions of the function, and include tags (<a>TagResource</a>) and per-function concurrency limits (<a>PutFunctionConcurrency</a>).</p> <p>If another account or an AWS service invokes your function, use <a>AddPermission</a> to grant permission by creating a resource-based IAM policy. You can grant permissions at the function level, on a version, or on an alias.</p> <p>To invoke your function directly, use <a>Invoke</a>. To invoke your function in response to events in other AWS services, create an event source mapping (<a>CreateEventSourceMapping</a>), or configure a function trigger in the other service. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-invocation.html">Invoking Functions</a>.</p>
  ##   body: JObject (required)
  var body_606329 = newJObject()
  if body != nil:
    body_606329 = body
  result = call_606328.call(nil, nil, nil, nil, body_606329)

var createFunction* = Call_CreateFunction_606316(name: "createFunction",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions", validator: validate_CreateFunction_606317,
    base: "/", url: url_CreateFunction_606318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAlias_606345 = ref object of OpenApiRestCall_605589
proc url_UpdateAlias_606347(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateAlias_606346(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606348 = path.getOrDefault("FunctionName")
  valid_606348 = validateParameter(valid_606348, JString, required = true,
                                 default = nil)
  if valid_606348 != nil:
    section.add "FunctionName", valid_606348
  var valid_606349 = path.getOrDefault("Name")
  valid_606349 = validateParameter(valid_606349, JString, required = true,
                                 default = nil)
  if valid_606349 != nil:
    section.add "Name", valid_606349
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
  var valid_606350 = header.getOrDefault("X-Amz-Signature")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-Signature", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Content-Sha256", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-Date")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Date", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-Credential")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Credential", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Security-Token")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Security-Token", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-Algorithm")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Algorithm", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-SignedHeaders", valid_606356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606358: Call_UpdateAlias_606345; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the configuration of a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ## 
  let valid = call_606358.validator(path, query, header, formData, body)
  let scheme = call_606358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606358.url(scheme.get, call_606358.host, call_606358.base,
                         call_606358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606358, url, valid)

proc call*(call_606359: Call_UpdateAlias_606345; FunctionName: string; Name: string;
          body: JsonNode): Recallable =
  ## updateAlias
  ## Updates the configuration of a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Name: string (required)
  ##       : The name of the alias.
  ##   body: JObject (required)
  var path_606360 = newJObject()
  var body_606361 = newJObject()
  add(path_606360, "FunctionName", newJString(FunctionName))
  add(path_606360, "Name", newJString(Name))
  if body != nil:
    body_606361 = body
  result = call_606359.call(path_606360, nil, nil, nil, body_606361)

var updateAlias* = Call_UpdateAlias_606345(name: "updateAlias",
                                        meth: HttpMethod.HttpPut,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases/{Name}",
                                        validator: validate_UpdateAlias_606346,
                                        base: "/", url: url_UpdateAlias_606347,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAlias_606330 = ref object of OpenApiRestCall_605589
proc url_GetAlias_606332(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetAlias_606331(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606333 = path.getOrDefault("FunctionName")
  valid_606333 = validateParameter(valid_606333, JString, required = true,
                                 default = nil)
  if valid_606333 != nil:
    section.add "FunctionName", valid_606333
  var valid_606334 = path.getOrDefault("Name")
  valid_606334 = validateParameter(valid_606334, JString, required = true,
                                 default = nil)
  if valid_606334 != nil:
    section.add "Name", valid_606334
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
  var valid_606335 = header.getOrDefault("X-Amz-Signature")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Signature", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Content-Sha256", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Date")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Date", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Credential")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Credential", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Security-Token")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Security-Token", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Algorithm")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Algorithm", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-SignedHeaders", valid_606341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606342: Call_GetAlias_606330; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns details about a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ## 
  let valid = call_606342.validator(path, query, header, formData, body)
  let scheme = call_606342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606342.url(scheme.get, call_606342.host, call_606342.base,
                         call_606342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606342, url, valid)

proc call*(call_606343: Call_GetAlias_606330; FunctionName: string; Name: string): Recallable =
  ## getAlias
  ## Returns details about a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Name: string (required)
  ##       : The name of the alias.
  var path_606344 = newJObject()
  add(path_606344, "FunctionName", newJString(FunctionName))
  add(path_606344, "Name", newJString(Name))
  result = call_606343.call(path_606344, nil, nil, nil, nil)

var getAlias* = Call_GetAlias_606330(name: "getAlias", meth: HttpMethod.HttpGet,
                                  host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases/{Name}",
                                  validator: validate_GetAlias_606331, base: "/",
                                  url: url_GetAlias_606332,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAlias_606362 = ref object of OpenApiRestCall_605589
proc url_DeleteAlias_606364(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteAlias_606363(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606365 = path.getOrDefault("FunctionName")
  valid_606365 = validateParameter(valid_606365, JString, required = true,
                                 default = nil)
  if valid_606365 != nil:
    section.add "FunctionName", valid_606365
  var valid_606366 = path.getOrDefault("Name")
  valid_606366 = validateParameter(valid_606366, JString, required = true,
                                 default = nil)
  if valid_606366 != nil:
    section.add "Name", valid_606366
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
  var valid_606367 = header.getOrDefault("X-Amz-Signature")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Signature", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Content-Sha256", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Date")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Date", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-Credential")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-Credential", valid_606370
  var valid_606371 = header.getOrDefault("X-Amz-Security-Token")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-Security-Token", valid_606371
  var valid_606372 = header.getOrDefault("X-Amz-Algorithm")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "X-Amz-Algorithm", valid_606372
  var valid_606373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606373 = validateParameter(valid_606373, JString, required = false,
                                 default = nil)
  if valid_606373 != nil:
    section.add "X-Amz-SignedHeaders", valid_606373
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606374: Call_DeleteAlias_606362; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ## 
  let valid = call_606374.validator(path, query, header, formData, body)
  let scheme = call_606374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606374.url(scheme.get, call_606374.host, call_606374.base,
                         call_606374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606374, url, valid)

proc call*(call_606375: Call_DeleteAlias_606362; FunctionName: string; Name: string): Recallable =
  ## deleteAlias
  ## Deletes a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Name: string (required)
  ##       : The name of the alias.
  var path_606376 = newJObject()
  add(path_606376, "FunctionName", newJString(FunctionName))
  add(path_606376, "Name", newJString(Name))
  result = call_606375.call(path_606376, nil, nil, nil, nil)

var deleteAlias* = Call_DeleteAlias_606362(name: "deleteAlias",
                                        meth: HttpMethod.HttpDelete,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases/{Name}",
                                        validator: validate_DeleteAlias_606363,
                                        base: "/", url: url_DeleteAlias_606364,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEventSourceMapping_606391 = ref object of OpenApiRestCall_605589
proc url_UpdateEventSourceMapping_606393(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateEventSourceMapping_606392(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates an event source mapping. You can change the function that AWS Lambda invokes, or pause invocation and resume later from the same location.</p> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   UUID: JString (required)
  ##       : The identifier of the event source mapping.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `UUID` field"
  var valid_606394 = path.getOrDefault("UUID")
  valid_606394 = validateParameter(valid_606394, JString, required = true,
                                 default = nil)
  if valid_606394 != nil:
    section.add "UUID", valid_606394
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
  var valid_606395 = header.getOrDefault("X-Amz-Signature")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-Signature", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-Content-Sha256", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-Date")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Date", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Credential")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Credential", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-Security-Token")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Security-Token", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-Algorithm")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Algorithm", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-SignedHeaders", valid_606401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606403: Call_UpdateEventSourceMapping_606391; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an event source mapping. You can change the function that AWS Lambda invokes, or pause invocation and resume later from the same location.</p> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> </ul>
  ## 
  let valid = call_606403.validator(path, query, header, formData, body)
  let scheme = call_606403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606403.url(scheme.get, call_606403.host, call_606403.base,
                         call_606403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606403, url, valid)

proc call*(call_606404: Call_UpdateEventSourceMapping_606391; UUID: string;
          body: JsonNode): Recallable =
  ## updateEventSourceMapping
  ## <p>Updates an event source mapping. You can change the function that AWS Lambda invokes, or pause invocation and resume later from the same location.</p> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> </ul>
  ##   UUID: string (required)
  ##       : The identifier of the event source mapping.
  ##   body: JObject (required)
  var path_606405 = newJObject()
  var body_606406 = newJObject()
  add(path_606405, "UUID", newJString(UUID))
  if body != nil:
    body_606406 = body
  result = call_606404.call(path_606405, nil, nil, nil, body_606406)

var updateEventSourceMapping* = Call_UpdateEventSourceMapping_606391(
    name: "updateEventSourceMapping", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/event-source-mappings/{UUID}",
    validator: validate_UpdateEventSourceMapping_606392, base: "/",
    url: url_UpdateEventSourceMapping_606393, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventSourceMapping_606377 = ref object of OpenApiRestCall_605589
proc url_GetEventSourceMapping_606379(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetEventSourceMapping_606378(path: JsonNode; query: JsonNode;
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
  var valid_606380 = path.getOrDefault("UUID")
  valid_606380 = validateParameter(valid_606380, JString, required = true,
                                 default = nil)
  if valid_606380 != nil:
    section.add "UUID", valid_606380
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
  var valid_606381 = header.getOrDefault("X-Amz-Signature")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Signature", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Content-Sha256", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-Date")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Date", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-Credential")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-Credential", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-Security-Token")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Security-Token", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-Algorithm")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-Algorithm", valid_606386
  var valid_606387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606387 = validateParameter(valid_606387, JString, required = false,
                                 default = nil)
  if valid_606387 != nil:
    section.add "X-Amz-SignedHeaders", valid_606387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606388: Call_GetEventSourceMapping_606377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns details about an event source mapping. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.
  ## 
  let valid = call_606388.validator(path, query, header, formData, body)
  let scheme = call_606388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606388.url(scheme.get, call_606388.host, call_606388.base,
                         call_606388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606388, url, valid)

proc call*(call_606389: Call_GetEventSourceMapping_606377; UUID: string): Recallable =
  ## getEventSourceMapping
  ## Returns details about an event source mapping. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.
  ##   UUID: string (required)
  ##       : The identifier of the event source mapping.
  var path_606390 = newJObject()
  add(path_606390, "UUID", newJString(UUID))
  result = call_606389.call(path_606390, nil, nil, nil, nil)

var getEventSourceMapping* = Call_GetEventSourceMapping_606377(
    name: "getEventSourceMapping", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/event-source-mappings/{UUID}",
    validator: validate_GetEventSourceMapping_606378, base: "/",
    url: url_GetEventSourceMapping_606379, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventSourceMapping_606407 = ref object of OpenApiRestCall_605589
proc url_DeleteEventSourceMapping_606409(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteEventSourceMapping_606408(path: JsonNode; query: JsonNode;
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
  var valid_606410 = path.getOrDefault("UUID")
  valid_606410 = validateParameter(valid_606410, JString, required = true,
                                 default = nil)
  if valid_606410 != nil:
    section.add "UUID", valid_606410
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
  var valid_606411 = header.getOrDefault("X-Amz-Signature")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-Signature", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Content-Sha256", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-Date")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Date", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-Credential")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Credential", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-Security-Token")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Security-Token", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-Algorithm")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-Algorithm", valid_606416
  var valid_606417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606417 = validateParameter(valid_606417, JString, required = false,
                                 default = nil)
  if valid_606417 != nil:
    section.add "X-Amz-SignedHeaders", valid_606417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606418: Call_DeleteEventSourceMapping_606407; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-invocation-modes.html">event source mapping</a>. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.</p> <p>When you delete an event source mapping, it enters a <code>Deleting</code> state and might not be completely deleted for several seconds.</p>
  ## 
  let valid = call_606418.validator(path, query, header, formData, body)
  let scheme = call_606418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606418.url(scheme.get, call_606418.host, call_606418.base,
                         call_606418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606418, url, valid)

proc call*(call_606419: Call_DeleteEventSourceMapping_606407; UUID: string): Recallable =
  ## deleteEventSourceMapping
  ## <p>Deletes an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-invocation-modes.html">event source mapping</a>. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.</p> <p>When you delete an event source mapping, it enters a <code>Deleting</code> state and might not be completely deleted for several seconds.</p>
  ##   UUID: string (required)
  ##       : The identifier of the event source mapping.
  var path_606420 = newJObject()
  add(path_606420, "UUID", newJString(UUID))
  result = call_606419.call(path_606420, nil, nil, nil, nil)

var deleteEventSourceMapping* = Call_DeleteEventSourceMapping_606407(
    name: "deleteEventSourceMapping", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/event-source-mappings/{UUID}",
    validator: validate_DeleteEventSourceMapping_606408, base: "/",
    url: url_DeleteEventSourceMapping_606409, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunction_606421 = ref object of OpenApiRestCall_605589
proc url_GetFunction_606423(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFunction_606422(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606424 = path.getOrDefault("FunctionName")
  valid_606424 = validateParameter(valid_606424, JString, required = true,
                                 default = nil)
  if valid_606424 != nil:
    section.add "FunctionName", valid_606424
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to get details about a published version of the function.
  section = newJObject()
  var valid_606425 = query.getOrDefault("Qualifier")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "Qualifier", valid_606425
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
  var valid_606426 = header.getOrDefault("X-Amz-Signature")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-Signature", valid_606426
  var valid_606427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-Content-Sha256", valid_606427
  var valid_606428 = header.getOrDefault("X-Amz-Date")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "X-Amz-Date", valid_606428
  var valid_606429 = header.getOrDefault("X-Amz-Credential")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-Credential", valid_606429
  var valid_606430 = header.getOrDefault("X-Amz-Security-Token")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Security-Token", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-Algorithm")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-Algorithm", valid_606431
  var valid_606432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606432 = validateParameter(valid_606432, JString, required = false,
                                 default = nil)
  if valid_606432 != nil:
    section.add "X-Amz-SignedHeaders", valid_606432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606433: Call_GetFunction_606421; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the function or function version, with a link to download the deployment package that's valid for 10 minutes. If you specify a function version, only details that are specific to that version are returned.
  ## 
  let valid = call_606433.validator(path, query, header, formData, body)
  let scheme = call_606433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606433.url(scheme.get, call_606433.host, call_606433.base,
                         call_606433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606433, url, valid)

proc call*(call_606434: Call_GetFunction_606421; FunctionName: string;
          Qualifier: string = ""): Recallable =
  ## getFunction
  ## Returns information about the function or function version, with a link to download the deployment package that's valid for 10 minutes. If you specify a function version, only details that are specific to that version are returned.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to get details about a published version of the function.
  var path_606435 = newJObject()
  var query_606436 = newJObject()
  add(path_606435, "FunctionName", newJString(FunctionName))
  add(query_606436, "Qualifier", newJString(Qualifier))
  result = call_606434.call(path_606435, query_606436, nil, nil, nil)

var getFunction* = Call_GetFunction_606421(name: "getFunction",
                                        meth: HttpMethod.HttpGet,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}",
                                        validator: validate_GetFunction_606422,
                                        base: "/", url: url_GetFunction_606423,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunction_606437 = ref object of OpenApiRestCall_605589
proc url_DeleteFunction_606439(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFunction_606438(path: JsonNode; query: JsonNode;
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
  var valid_606440 = path.getOrDefault("FunctionName")
  valid_606440 = validateParameter(valid_606440, JString, required = true,
                                 default = nil)
  if valid_606440 != nil:
    section.add "FunctionName", valid_606440
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version to delete. You can't delete a version that's referenced by an alias.
  section = newJObject()
  var valid_606441 = query.getOrDefault("Qualifier")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "Qualifier", valid_606441
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
  var valid_606442 = header.getOrDefault("X-Amz-Signature")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "X-Amz-Signature", valid_606442
  var valid_606443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606443 = validateParameter(valid_606443, JString, required = false,
                                 default = nil)
  if valid_606443 != nil:
    section.add "X-Amz-Content-Sha256", valid_606443
  var valid_606444 = header.getOrDefault("X-Amz-Date")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-Date", valid_606444
  var valid_606445 = header.getOrDefault("X-Amz-Credential")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-Credential", valid_606445
  var valid_606446 = header.getOrDefault("X-Amz-Security-Token")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-Security-Token", valid_606446
  var valid_606447 = header.getOrDefault("X-Amz-Algorithm")
  valid_606447 = validateParameter(valid_606447, JString, required = false,
                                 default = nil)
  if valid_606447 != nil:
    section.add "X-Amz-Algorithm", valid_606447
  var valid_606448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606448 = validateParameter(valid_606448, JString, required = false,
                                 default = nil)
  if valid_606448 != nil:
    section.add "X-Amz-SignedHeaders", valid_606448
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606449: Call_DeleteFunction_606437; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a Lambda function. To delete a specific function version, use the <code>Qualifier</code> parameter. Otherwise, all versions and aliases are deleted.</p> <p>To delete Lambda event source mappings that invoke a function, use <a>DeleteEventSourceMapping</a>. For AWS services and resources that invoke your function directly, delete the trigger in the service where you originally configured it.</p>
  ## 
  let valid = call_606449.validator(path, query, header, formData, body)
  let scheme = call_606449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606449.url(scheme.get, call_606449.host, call_606449.base,
                         call_606449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606449, url, valid)

proc call*(call_606450: Call_DeleteFunction_606437; FunctionName: string;
          Qualifier: string = ""): Recallable =
  ## deleteFunction
  ## <p>Deletes a Lambda function. To delete a specific function version, use the <code>Qualifier</code> parameter. Otherwise, all versions and aliases are deleted.</p> <p>To delete Lambda event source mappings that invoke a function, use <a>DeleteEventSourceMapping</a>. For AWS services and resources that invoke your function directly, delete the trigger in the service where you originally configured it.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function or version.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:1</code> (with version).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version to delete. You can't delete a version that's referenced by an alias.
  var path_606451 = newJObject()
  var query_606452 = newJObject()
  add(path_606451, "FunctionName", newJString(FunctionName))
  add(query_606452, "Qualifier", newJString(Qualifier))
  result = call_606450.call(path_606451, query_606452, nil, nil, nil)

var deleteFunction* = Call_DeleteFunction_606437(name: "deleteFunction",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}",
    validator: validate_DeleteFunction_606438, base: "/", url: url_DeleteFunction_606439,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutFunctionConcurrency_606453 = ref object of OpenApiRestCall_605589
proc url_PutFunctionConcurrency_606455(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutFunctionConcurrency_606454(path: JsonNode; query: JsonNode;
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
  var valid_606456 = path.getOrDefault("FunctionName")
  valid_606456 = validateParameter(valid_606456, JString, required = true,
                                 default = nil)
  if valid_606456 != nil:
    section.add "FunctionName", valid_606456
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
  var valid_606457 = header.getOrDefault("X-Amz-Signature")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-Signature", valid_606457
  var valid_606458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-Content-Sha256", valid_606458
  var valid_606459 = header.getOrDefault("X-Amz-Date")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-Date", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-Credential")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-Credential", valid_606460
  var valid_606461 = header.getOrDefault("X-Amz-Security-Token")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-Security-Token", valid_606461
  var valid_606462 = header.getOrDefault("X-Amz-Algorithm")
  valid_606462 = validateParameter(valid_606462, JString, required = false,
                                 default = nil)
  if valid_606462 != nil:
    section.add "X-Amz-Algorithm", valid_606462
  var valid_606463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606463 = validateParameter(valid_606463, JString, required = false,
                                 default = nil)
  if valid_606463 != nil:
    section.add "X-Amz-SignedHeaders", valid_606463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606465: Call_PutFunctionConcurrency_606453; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the maximum number of simultaneous executions for a function, and reserves capacity for that concurrency level.</p> <p>Concurrency settings apply to the function as a whole, including all published versions and the unpublished version. Reserving concurrency both ensures that your function has capacity to process the specified number of events simultaneously, and prevents it from scaling beyond that level. Use <a>GetFunction</a> to see the current setting for a function.</p> <p>Use <a>GetAccountSettings</a> to see your Regional concurrency limit. You can reserve concurrency for as many functions as you like, as long as you leave at least 100 simultaneous executions unreserved for functions that aren't configured with a per-function limit. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/concurrent-executions.html">Managing Concurrency</a>.</p>
  ## 
  let valid = call_606465.validator(path, query, header, formData, body)
  let scheme = call_606465.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606465.url(scheme.get, call_606465.host, call_606465.base,
                         call_606465.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606465, url, valid)

proc call*(call_606466: Call_PutFunctionConcurrency_606453; FunctionName: string;
          body: JsonNode): Recallable =
  ## putFunctionConcurrency
  ## <p>Sets the maximum number of simultaneous executions for a function, and reserves capacity for that concurrency level.</p> <p>Concurrency settings apply to the function as a whole, including all published versions and the unpublished version. Reserving concurrency both ensures that your function has capacity to process the specified number of events simultaneously, and prevents it from scaling beyond that level. Use <a>GetFunction</a> to see the current setting for a function.</p> <p>Use <a>GetAccountSettings</a> to see your Regional concurrency limit. You can reserve concurrency for as many functions as you like, as long as you leave at least 100 simultaneous executions unreserved for functions that aren't configured with a per-function limit. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/concurrent-executions.html">Managing Concurrency</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_606467 = newJObject()
  var body_606468 = newJObject()
  add(path_606467, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_606468 = body
  result = call_606466.call(path_606467, nil, nil, nil, body_606468)

var putFunctionConcurrency* = Call_PutFunctionConcurrency_606453(
    name: "putFunctionConcurrency", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2017-10-31/functions/{FunctionName}/concurrency",
    validator: validate_PutFunctionConcurrency_606454, base: "/",
    url: url_PutFunctionConcurrency_606455, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunctionConcurrency_606469 = ref object of OpenApiRestCall_605589
proc url_DeleteFunctionConcurrency_606471(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFunctionConcurrency_606470(path: JsonNode; query: JsonNode;
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
  var valid_606472 = path.getOrDefault("FunctionName")
  valid_606472 = validateParameter(valid_606472, JString, required = true,
                                 default = nil)
  if valid_606472 != nil:
    section.add "FunctionName", valid_606472
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
  var valid_606473 = header.getOrDefault("X-Amz-Signature")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "X-Amz-Signature", valid_606473
  var valid_606474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "X-Amz-Content-Sha256", valid_606474
  var valid_606475 = header.getOrDefault("X-Amz-Date")
  valid_606475 = validateParameter(valid_606475, JString, required = false,
                                 default = nil)
  if valid_606475 != nil:
    section.add "X-Amz-Date", valid_606475
  var valid_606476 = header.getOrDefault("X-Amz-Credential")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "X-Amz-Credential", valid_606476
  var valid_606477 = header.getOrDefault("X-Amz-Security-Token")
  valid_606477 = validateParameter(valid_606477, JString, required = false,
                                 default = nil)
  if valid_606477 != nil:
    section.add "X-Amz-Security-Token", valid_606477
  var valid_606478 = header.getOrDefault("X-Amz-Algorithm")
  valid_606478 = validateParameter(valid_606478, JString, required = false,
                                 default = nil)
  if valid_606478 != nil:
    section.add "X-Amz-Algorithm", valid_606478
  var valid_606479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606479 = validateParameter(valid_606479, JString, required = false,
                                 default = nil)
  if valid_606479 != nil:
    section.add "X-Amz-SignedHeaders", valid_606479
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606480: Call_DeleteFunctionConcurrency_606469; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a concurrent execution limit from a function.
  ## 
  let valid = call_606480.validator(path, query, header, formData, body)
  let scheme = call_606480.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606480.url(scheme.get, call_606480.host, call_606480.base,
                         call_606480.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606480, url, valid)

proc call*(call_606481: Call_DeleteFunctionConcurrency_606469; FunctionName: string): Recallable =
  ## deleteFunctionConcurrency
  ## Removes a concurrent execution limit from a function.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  var path_606482 = newJObject()
  add(path_606482, "FunctionName", newJString(FunctionName))
  result = call_606481.call(path_606482, nil, nil, nil, nil)

var deleteFunctionConcurrency* = Call_DeleteFunctionConcurrency_606469(
    name: "deleteFunctionConcurrency", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com",
    route: "/2017-10-31/functions/{FunctionName}/concurrency",
    validator: validate_DeleteFunctionConcurrency_606470, base: "/",
    url: url_DeleteFunctionConcurrency_606471,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutFunctionEventInvokeConfig_606499 = ref object of OpenApiRestCall_605589
proc url_PutFunctionEventInvokeConfig_606501(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutFunctionEventInvokeConfig_606500(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Configures options for <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a> on a function, version, or alias.</p> <p>By default, Lambda retries an asynchronous invocation twice if the function returns an error. It retains events in a queue for up to six hours. When an event fails all processing attempts or stays in the asynchronous invocation queue for too long, Lambda discards it. To retain discarded events, configure a dead-letter queue with <a>UpdateFunctionConfiguration</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_606502 = path.getOrDefault("FunctionName")
  valid_606502 = validateParameter(valid_606502, JString, required = true,
                                 default = nil)
  if valid_606502 != nil:
    section.add "FunctionName", valid_606502
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : A version number or alias name.
  section = newJObject()
  var valid_606503 = query.getOrDefault("Qualifier")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "Qualifier", valid_606503
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
  var valid_606504 = header.getOrDefault("X-Amz-Signature")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-Signature", valid_606504
  var valid_606505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606505 = validateParameter(valid_606505, JString, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "X-Amz-Content-Sha256", valid_606505
  var valid_606506 = header.getOrDefault("X-Amz-Date")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "X-Amz-Date", valid_606506
  var valid_606507 = header.getOrDefault("X-Amz-Credential")
  valid_606507 = validateParameter(valid_606507, JString, required = false,
                                 default = nil)
  if valid_606507 != nil:
    section.add "X-Amz-Credential", valid_606507
  var valid_606508 = header.getOrDefault("X-Amz-Security-Token")
  valid_606508 = validateParameter(valid_606508, JString, required = false,
                                 default = nil)
  if valid_606508 != nil:
    section.add "X-Amz-Security-Token", valid_606508
  var valid_606509 = header.getOrDefault("X-Amz-Algorithm")
  valid_606509 = validateParameter(valid_606509, JString, required = false,
                                 default = nil)
  if valid_606509 != nil:
    section.add "X-Amz-Algorithm", valid_606509
  var valid_606510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606510 = validateParameter(valid_606510, JString, required = false,
                                 default = nil)
  if valid_606510 != nil:
    section.add "X-Amz-SignedHeaders", valid_606510
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606512: Call_PutFunctionEventInvokeConfig_606499; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configures options for <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a> on a function, version, or alias.</p> <p>By default, Lambda retries an asynchronous invocation twice if the function returns an error. It retains events in a queue for up to six hours. When an event fails all processing attempts or stays in the asynchronous invocation queue for too long, Lambda discards it. To retain discarded events, configure a dead-letter queue with <a>UpdateFunctionConfiguration</a>.</p>
  ## 
  let valid = call_606512.validator(path, query, header, formData, body)
  let scheme = call_606512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606512.url(scheme.get, call_606512.host, call_606512.base,
                         call_606512.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606512, url, valid)

proc call*(call_606513: Call_PutFunctionEventInvokeConfig_606499;
          FunctionName: string; body: JsonNode; Qualifier: string = ""): Recallable =
  ## putFunctionEventInvokeConfig
  ## <p>Configures options for <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a> on a function, version, or alias.</p> <p>By default, Lambda retries an asynchronous invocation twice if the function returns an error. It retains events in a queue for up to six hours. When an event fails all processing attempts or stays in the asynchronous invocation queue for too long, Lambda discards it. To retain discarded events, configure a dead-letter queue with <a>UpdateFunctionConfiguration</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : A version number or alias name.
  ##   body: JObject (required)
  var path_606514 = newJObject()
  var query_606515 = newJObject()
  var body_606516 = newJObject()
  add(path_606514, "FunctionName", newJString(FunctionName))
  add(query_606515, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_606516 = body
  result = call_606513.call(path_606514, query_606515, nil, nil, body_606516)

var putFunctionEventInvokeConfig* = Call_PutFunctionEventInvokeConfig_606499(
    name: "putFunctionEventInvokeConfig", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config",
    validator: validate_PutFunctionEventInvokeConfig_606500, base: "/",
    url: url_PutFunctionEventInvokeConfig_606501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionEventInvokeConfig_606517 = ref object of OpenApiRestCall_605589
proc url_UpdateFunctionEventInvokeConfig_606519(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFunctionEventInvokeConfig_606518(path: JsonNode;
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
  var valid_606520 = path.getOrDefault("FunctionName")
  valid_606520 = validateParameter(valid_606520, JString, required = true,
                                 default = nil)
  if valid_606520 != nil:
    section.add "FunctionName", valid_606520
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : A version number or alias name.
  section = newJObject()
  var valid_606521 = query.getOrDefault("Qualifier")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "Qualifier", valid_606521
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
  var valid_606522 = header.getOrDefault("X-Amz-Signature")
  valid_606522 = validateParameter(valid_606522, JString, required = false,
                                 default = nil)
  if valid_606522 != nil:
    section.add "X-Amz-Signature", valid_606522
  var valid_606523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606523 = validateParameter(valid_606523, JString, required = false,
                                 default = nil)
  if valid_606523 != nil:
    section.add "X-Amz-Content-Sha256", valid_606523
  var valid_606524 = header.getOrDefault("X-Amz-Date")
  valid_606524 = validateParameter(valid_606524, JString, required = false,
                                 default = nil)
  if valid_606524 != nil:
    section.add "X-Amz-Date", valid_606524
  var valid_606525 = header.getOrDefault("X-Amz-Credential")
  valid_606525 = validateParameter(valid_606525, JString, required = false,
                                 default = nil)
  if valid_606525 != nil:
    section.add "X-Amz-Credential", valid_606525
  var valid_606526 = header.getOrDefault("X-Amz-Security-Token")
  valid_606526 = validateParameter(valid_606526, JString, required = false,
                                 default = nil)
  if valid_606526 != nil:
    section.add "X-Amz-Security-Token", valid_606526
  var valid_606527 = header.getOrDefault("X-Amz-Algorithm")
  valid_606527 = validateParameter(valid_606527, JString, required = false,
                                 default = nil)
  if valid_606527 != nil:
    section.add "X-Amz-Algorithm", valid_606527
  var valid_606528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606528 = validateParameter(valid_606528, JString, required = false,
                                 default = nil)
  if valid_606528 != nil:
    section.add "X-Amz-SignedHeaders", valid_606528
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606530: Call_UpdateFunctionEventInvokeConfig_606517;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Updates the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  let valid = call_606530.validator(path, query, header, formData, body)
  let scheme = call_606530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606530.url(scheme.get, call_606530.host, call_606530.base,
                         call_606530.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606530, url, valid)

proc call*(call_606531: Call_UpdateFunctionEventInvokeConfig_606517;
          FunctionName: string; body: JsonNode; Qualifier: string = ""): Recallable =
  ## updateFunctionEventInvokeConfig
  ## <p>Updates the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : A version number or alias name.
  ##   body: JObject (required)
  var path_606532 = newJObject()
  var query_606533 = newJObject()
  var body_606534 = newJObject()
  add(path_606532, "FunctionName", newJString(FunctionName))
  add(query_606533, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_606534 = body
  result = call_606531.call(path_606532, query_606533, nil, nil, body_606534)

var updateFunctionEventInvokeConfig* = Call_UpdateFunctionEventInvokeConfig_606517(
    name: "updateFunctionEventInvokeConfig", meth: HttpMethod.HttpPost,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config",
    validator: validate_UpdateFunctionEventInvokeConfig_606518, base: "/",
    url: url_UpdateFunctionEventInvokeConfig_606519,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionEventInvokeConfig_606483 = ref object of OpenApiRestCall_605589
proc url_GetFunctionEventInvokeConfig_606485(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFunctionEventInvokeConfig_606484(path: JsonNode; query: JsonNode;
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
  var valid_606486 = path.getOrDefault("FunctionName")
  valid_606486 = validateParameter(valid_606486, JString, required = true,
                                 default = nil)
  if valid_606486 != nil:
    section.add "FunctionName", valid_606486
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : A version number or alias name.
  section = newJObject()
  var valid_606487 = query.getOrDefault("Qualifier")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "Qualifier", valid_606487
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
  var valid_606488 = header.getOrDefault("X-Amz-Signature")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-Signature", valid_606488
  var valid_606489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "X-Amz-Content-Sha256", valid_606489
  var valid_606490 = header.getOrDefault("X-Amz-Date")
  valid_606490 = validateParameter(valid_606490, JString, required = false,
                                 default = nil)
  if valid_606490 != nil:
    section.add "X-Amz-Date", valid_606490
  var valid_606491 = header.getOrDefault("X-Amz-Credential")
  valid_606491 = validateParameter(valid_606491, JString, required = false,
                                 default = nil)
  if valid_606491 != nil:
    section.add "X-Amz-Credential", valid_606491
  var valid_606492 = header.getOrDefault("X-Amz-Security-Token")
  valid_606492 = validateParameter(valid_606492, JString, required = false,
                                 default = nil)
  if valid_606492 != nil:
    section.add "X-Amz-Security-Token", valid_606492
  var valid_606493 = header.getOrDefault("X-Amz-Algorithm")
  valid_606493 = validateParameter(valid_606493, JString, required = false,
                                 default = nil)
  if valid_606493 != nil:
    section.add "X-Amz-Algorithm", valid_606493
  var valid_606494 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606494 = validateParameter(valid_606494, JString, required = false,
                                 default = nil)
  if valid_606494 != nil:
    section.add "X-Amz-SignedHeaders", valid_606494
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606495: Call_GetFunctionEventInvokeConfig_606483; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  let valid = call_606495.validator(path, query, header, formData, body)
  let scheme = call_606495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606495.url(scheme.get, call_606495.host, call_606495.base,
                         call_606495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606495, url, valid)

proc call*(call_606496: Call_GetFunctionEventInvokeConfig_606483;
          FunctionName: string; Qualifier: string = ""): Recallable =
  ## getFunctionEventInvokeConfig
  ## <p>Retrieves the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : A version number or alias name.
  var path_606497 = newJObject()
  var query_606498 = newJObject()
  add(path_606497, "FunctionName", newJString(FunctionName))
  add(query_606498, "Qualifier", newJString(Qualifier))
  result = call_606496.call(path_606497, query_606498, nil, nil, nil)

var getFunctionEventInvokeConfig* = Call_GetFunctionEventInvokeConfig_606483(
    name: "getFunctionEventInvokeConfig", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config",
    validator: validate_GetFunctionEventInvokeConfig_606484, base: "/",
    url: url_GetFunctionEventInvokeConfig_606485,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunctionEventInvokeConfig_606535 = ref object of OpenApiRestCall_605589
proc url_DeleteFunctionEventInvokeConfig_606537(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFunctionEventInvokeConfig_606536(path: JsonNode;
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
  var valid_606538 = path.getOrDefault("FunctionName")
  valid_606538 = validateParameter(valid_606538, JString, required = true,
                                 default = nil)
  if valid_606538 != nil:
    section.add "FunctionName", valid_606538
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : A version number or alias name.
  section = newJObject()
  var valid_606539 = query.getOrDefault("Qualifier")
  valid_606539 = validateParameter(valid_606539, JString, required = false,
                                 default = nil)
  if valid_606539 != nil:
    section.add "Qualifier", valid_606539
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
  var valid_606540 = header.getOrDefault("X-Amz-Signature")
  valid_606540 = validateParameter(valid_606540, JString, required = false,
                                 default = nil)
  if valid_606540 != nil:
    section.add "X-Amz-Signature", valid_606540
  var valid_606541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606541 = validateParameter(valid_606541, JString, required = false,
                                 default = nil)
  if valid_606541 != nil:
    section.add "X-Amz-Content-Sha256", valid_606541
  var valid_606542 = header.getOrDefault("X-Amz-Date")
  valid_606542 = validateParameter(valid_606542, JString, required = false,
                                 default = nil)
  if valid_606542 != nil:
    section.add "X-Amz-Date", valid_606542
  var valid_606543 = header.getOrDefault("X-Amz-Credential")
  valid_606543 = validateParameter(valid_606543, JString, required = false,
                                 default = nil)
  if valid_606543 != nil:
    section.add "X-Amz-Credential", valid_606543
  var valid_606544 = header.getOrDefault("X-Amz-Security-Token")
  valid_606544 = validateParameter(valid_606544, JString, required = false,
                                 default = nil)
  if valid_606544 != nil:
    section.add "X-Amz-Security-Token", valid_606544
  var valid_606545 = header.getOrDefault("X-Amz-Algorithm")
  valid_606545 = validateParameter(valid_606545, JString, required = false,
                                 default = nil)
  if valid_606545 != nil:
    section.add "X-Amz-Algorithm", valid_606545
  var valid_606546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "X-Amz-SignedHeaders", valid_606546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606547: Call_DeleteFunctionEventInvokeConfig_606535;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  let valid = call_606547.validator(path, query, header, formData, body)
  let scheme = call_606547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606547.url(scheme.get, call_606547.host, call_606547.base,
                         call_606547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606547, url, valid)

proc call*(call_606548: Call_DeleteFunctionEventInvokeConfig_606535;
          FunctionName: string; Qualifier: string = ""): Recallable =
  ## deleteFunctionEventInvokeConfig
  ## <p>Deletes the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : A version number or alias name.
  var path_606549 = newJObject()
  var query_606550 = newJObject()
  add(path_606549, "FunctionName", newJString(FunctionName))
  add(query_606550, "Qualifier", newJString(Qualifier))
  result = call_606548.call(path_606549, query_606550, nil, nil, nil)

var deleteFunctionEventInvokeConfig* = Call_DeleteFunctionEventInvokeConfig_606535(
    name: "deleteFunctionEventInvokeConfig", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config",
    validator: validate_DeleteFunctionEventInvokeConfig_606536, base: "/",
    url: url_DeleteFunctionEventInvokeConfig_606537,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLayerVersion_606551 = ref object of OpenApiRestCall_605589
proc url_GetLayerVersion_606553(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetLayerVersion_606552(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_606554 = path.getOrDefault("VersionNumber")
  valid_606554 = validateParameter(valid_606554, JInt, required = true, default = nil)
  if valid_606554 != nil:
    section.add "VersionNumber", valid_606554
  var valid_606555 = path.getOrDefault("LayerName")
  valid_606555 = validateParameter(valid_606555, JString, required = true,
                                 default = nil)
  if valid_606555 != nil:
    section.add "LayerName", valid_606555
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
  var valid_606556 = header.getOrDefault("X-Amz-Signature")
  valid_606556 = validateParameter(valid_606556, JString, required = false,
                                 default = nil)
  if valid_606556 != nil:
    section.add "X-Amz-Signature", valid_606556
  var valid_606557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606557 = validateParameter(valid_606557, JString, required = false,
                                 default = nil)
  if valid_606557 != nil:
    section.add "X-Amz-Content-Sha256", valid_606557
  var valid_606558 = header.getOrDefault("X-Amz-Date")
  valid_606558 = validateParameter(valid_606558, JString, required = false,
                                 default = nil)
  if valid_606558 != nil:
    section.add "X-Amz-Date", valid_606558
  var valid_606559 = header.getOrDefault("X-Amz-Credential")
  valid_606559 = validateParameter(valid_606559, JString, required = false,
                                 default = nil)
  if valid_606559 != nil:
    section.add "X-Amz-Credential", valid_606559
  var valid_606560 = header.getOrDefault("X-Amz-Security-Token")
  valid_606560 = validateParameter(valid_606560, JString, required = false,
                                 default = nil)
  if valid_606560 != nil:
    section.add "X-Amz-Security-Token", valid_606560
  var valid_606561 = header.getOrDefault("X-Amz-Algorithm")
  valid_606561 = validateParameter(valid_606561, JString, required = false,
                                 default = nil)
  if valid_606561 != nil:
    section.add "X-Amz-Algorithm", valid_606561
  var valid_606562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606562 = validateParameter(valid_606562, JString, required = false,
                                 default = nil)
  if valid_606562 != nil:
    section.add "X-Amz-SignedHeaders", valid_606562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606563: Call_GetLayerVersion_606551; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ## 
  let valid = call_606563.validator(path, query, header, formData, body)
  let scheme = call_606563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606563.url(scheme.get, call_606563.host, call_606563.base,
                         call_606563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606563, url, valid)

proc call*(call_606564: Call_GetLayerVersion_606551; VersionNumber: int;
          LayerName: string): Recallable =
  ## getLayerVersion
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ##   VersionNumber: int (required)
  ##                : The version number.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  var path_606565 = newJObject()
  add(path_606565, "VersionNumber", newJInt(VersionNumber))
  add(path_606565, "LayerName", newJString(LayerName))
  result = call_606564.call(path_606565, nil, nil, nil, nil)

var getLayerVersion* = Call_GetLayerVersion_606551(name: "getLayerVersion",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}",
    validator: validate_GetLayerVersion_606552, base: "/", url: url_GetLayerVersion_606553,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLayerVersion_606566 = ref object of OpenApiRestCall_605589
proc url_DeleteLayerVersion_606568(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteLayerVersion_606567(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_606569 = path.getOrDefault("VersionNumber")
  valid_606569 = validateParameter(valid_606569, JInt, required = true, default = nil)
  if valid_606569 != nil:
    section.add "VersionNumber", valid_606569
  var valid_606570 = path.getOrDefault("LayerName")
  valid_606570 = validateParameter(valid_606570, JString, required = true,
                                 default = nil)
  if valid_606570 != nil:
    section.add "LayerName", valid_606570
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
  var valid_606571 = header.getOrDefault("X-Amz-Signature")
  valid_606571 = validateParameter(valid_606571, JString, required = false,
                                 default = nil)
  if valid_606571 != nil:
    section.add "X-Amz-Signature", valid_606571
  var valid_606572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606572 = validateParameter(valid_606572, JString, required = false,
                                 default = nil)
  if valid_606572 != nil:
    section.add "X-Amz-Content-Sha256", valid_606572
  var valid_606573 = header.getOrDefault("X-Amz-Date")
  valid_606573 = validateParameter(valid_606573, JString, required = false,
                                 default = nil)
  if valid_606573 != nil:
    section.add "X-Amz-Date", valid_606573
  var valid_606574 = header.getOrDefault("X-Amz-Credential")
  valid_606574 = validateParameter(valid_606574, JString, required = false,
                                 default = nil)
  if valid_606574 != nil:
    section.add "X-Amz-Credential", valid_606574
  var valid_606575 = header.getOrDefault("X-Amz-Security-Token")
  valid_606575 = validateParameter(valid_606575, JString, required = false,
                                 default = nil)
  if valid_606575 != nil:
    section.add "X-Amz-Security-Token", valid_606575
  var valid_606576 = header.getOrDefault("X-Amz-Algorithm")
  valid_606576 = validateParameter(valid_606576, JString, required = false,
                                 default = nil)
  if valid_606576 != nil:
    section.add "X-Amz-Algorithm", valid_606576
  var valid_606577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606577 = validateParameter(valid_606577, JString, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "X-Amz-SignedHeaders", valid_606577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606578: Call_DeleteLayerVersion_606566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Deleted versions can no longer be viewed or added to functions. To avoid breaking functions, a copy of the version remains in Lambda until no functions refer to it.
  ## 
  let valid = call_606578.validator(path, query, header, formData, body)
  let scheme = call_606578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606578.url(scheme.get, call_606578.host, call_606578.base,
                         call_606578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606578, url, valid)

proc call*(call_606579: Call_DeleteLayerVersion_606566; VersionNumber: int;
          LayerName: string): Recallable =
  ## deleteLayerVersion
  ## Deletes a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Deleted versions can no longer be viewed or added to functions. To avoid breaking functions, a copy of the version remains in Lambda until no functions refer to it.
  ##   VersionNumber: int (required)
  ##                : The version number.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  var path_606580 = newJObject()
  add(path_606580, "VersionNumber", newJInt(VersionNumber))
  add(path_606580, "LayerName", newJString(LayerName))
  result = call_606579.call(path_606580, nil, nil, nil, nil)

var deleteLayerVersion* = Call_DeleteLayerVersion_606566(
    name: "deleteLayerVersion", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}",
    validator: validate_DeleteLayerVersion_606567, base: "/",
    url: url_DeleteLayerVersion_606568, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutProvisionedConcurrencyConfig_606597 = ref object of OpenApiRestCall_605589
proc url_PutProvisionedConcurrencyConfig_606599(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PutProvisionedConcurrencyConfig_606598(path: JsonNode;
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
  var valid_606600 = path.getOrDefault("FunctionName")
  valid_606600 = validateParameter(valid_606600, JString, required = true,
                                 default = nil)
  if valid_606600 != nil:
    section.add "FunctionName", valid_606600
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString (required)
  ##            : The version number or alias name.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Qualifier` field"
  var valid_606601 = query.getOrDefault("Qualifier")
  valid_606601 = validateParameter(valid_606601, JString, required = true,
                                 default = nil)
  if valid_606601 != nil:
    section.add "Qualifier", valid_606601
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
  var valid_606602 = header.getOrDefault("X-Amz-Signature")
  valid_606602 = validateParameter(valid_606602, JString, required = false,
                                 default = nil)
  if valid_606602 != nil:
    section.add "X-Amz-Signature", valid_606602
  var valid_606603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606603 = validateParameter(valid_606603, JString, required = false,
                                 default = nil)
  if valid_606603 != nil:
    section.add "X-Amz-Content-Sha256", valid_606603
  var valid_606604 = header.getOrDefault("X-Amz-Date")
  valid_606604 = validateParameter(valid_606604, JString, required = false,
                                 default = nil)
  if valid_606604 != nil:
    section.add "X-Amz-Date", valid_606604
  var valid_606605 = header.getOrDefault("X-Amz-Credential")
  valid_606605 = validateParameter(valid_606605, JString, required = false,
                                 default = nil)
  if valid_606605 != nil:
    section.add "X-Amz-Credential", valid_606605
  var valid_606606 = header.getOrDefault("X-Amz-Security-Token")
  valid_606606 = validateParameter(valid_606606, JString, required = false,
                                 default = nil)
  if valid_606606 != nil:
    section.add "X-Amz-Security-Token", valid_606606
  var valid_606607 = header.getOrDefault("X-Amz-Algorithm")
  valid_606607 = validateParameter(valid_606607, JString, required = false,
                                 default = nil)
  if valid_606607 != nil:
    section.add "X-Amz-Algorithm", valid_606607
  var valid_606608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606608 = validateParameter(valid_606608, JString, required = false,
                                 default = nil)
  if valid_606608 != nil:
    section.add "X-Amz-SignedHeaders", valid_606608
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606610: Call_PutProvisionedConcurrencyConfig_606597;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds a provisioned concurrency configuration to a function's alias or version.
  ## 
  let valid = call_606610.validator(path, query, header, formData, body)
  let scheme = call_606610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606610.url(scheme.get, call_606610.host, call_606610.base,
                         call_606610.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606610, url, valid)

proc call*(call_606611: Call_PutProvisionedConcurrencyConfig_606597;
          FunctionName: string; Qualifier: string; body: JsonNode): Recallable =
  ## putProvisionedConcurrencyConfig
  ## Adds a provisioned concurrency configuration to a function's alias or version.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string (required)
  ##            : The version number or alias name.
  ##   body: JObject (required)
  var path_606612 = newJObject()
  var query_606613 = newJObject()
  var body_606614 = newJObject()
  add(path_606612, "FunctionName", newJString(FunctionName))
  add(query_606613, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_606614 = body
  result = call_606611.call(path_606612, query_606613, nil, nil, body_606614)

var putProvisionedConcurrencyConfig* = Call_PutProvisionedConcurrencyConfig_606597(
    name: "putProvisionedConcurrencyConfig", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com", route: "/2019-09-30/functions/{FunctionName}/provisioned-concurrency#Qualifier",
    validator: validate_PutProvisionedConcurrencyConfig_606598, base: "/",
    url: url_PutProvisionedConcurrencyConfig_606599,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProvisionedConcurrencyConfig_606581 = ref object of OpenApiRestCall_605589
proc url_GetProvisionedConcurrencyConfig_606583(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetProvisionedConcurrencyConfig_606582(path: JsonNode;
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
  var valid_606584 = path.getOrDefault("FunctionName")
  valid_606584 = validateParameter(valid_606584, JString, required = true,
                                 default = nil)
  if valid_606584 != nil:
    section.add "FunctionName", valid_606584
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString (required)
  ##            : The version number or alias name.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Qualifier` field"
  var valid_606585 = query.getOrDefault("Qualifier")
  valid_606585 = validateParameter(valid_606585, JString, required = true,
                                 default = nil)
  if valid_606585 != nil:
    section.add "Qualifier", valid_606585
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
  var valid_606586 = header.getOrDefault("X-Amz-Signature")
  valid_606586 = validateParameter(valid_606586, JString, required = false,
                                 default = nil)
  if valid_606586 != nil:
    section.add "X-Amz-Signature", valid_606586
  var valid_606587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606587 = validateParameter(valid_606587, JString, required = false,
                                 default = nil)
  if valid_606587 != nil:
    section.add "X-Amz-Content-Sha256", valid_606587
  var valid_606588 = header.getOrDefault("X-Amz-Date")
  valid_606588 = validateParameter(valid_606588, JString, required = false,
                                 default = nil)
  if valid_606588 != nil:
    section.add "X-Amz-Date", valid_606588
  var valid_606589 = header.getOrDefault("X-Amz-Credential")
  valid_606589 = validateParameter(valid_606589, JString, required = false,
                                 default = nil)
  if valid_606589 != nil:
    section.add "X-Amz-Credential", valid_606589
  var valid_606590 = header.getOrDefault("X-Amz-Security-Token")
  valid_606590 = validateParameter(valid_606590, JString, required = false,
                                 default = nil)
  if valid_606590 != nil:
    section.add "X-Amz-Security-Token", valid_606590
  var valid_606591 = header.getOrDefault("X-Amz-Algorithm")
  valid_606591 = validateParameter(valid_606591, JString, required = false,
                                 default = nil)
  if valid_606591 != nil:
    section.add "X-Amz-Algorithm", valid_606591
  var valid_606592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606592 = validateParameter(valid_606592, JString, required = false,
                                 default = nil)
  if valid_606592 != nil:
    section.add "X-Amz-SignedHeaders", valid_606592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606593: Call_GetProvisionedConcurrencyConfig_606581;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the provisioned concurrency configuration for a function's alias or version.
  ## 
  let valid = call_606593.validator(path, query, header, formData, body)
  let scheme = call_606593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606593.url(scheme.get, call_606593.host, call_606593.base,
                         call_606593.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606593, url, valid)

proc call*(call_606594: Call_GetProvisionedConcurrencyConfig_606581;
          FunctionName: string; Qualifier: string): Recallable =
  ## getProvisionedConcurrencyConfig
  ## Retrieves the provisioned concurrency configuration for a function's alias or version.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string (required)
  ##            : The version number or alias name.
  var path_606595 = newJObject()
  var query_606596 = newJObject()
  add(path_606595, "FunctionName", newJString(FunctionName))
  add(query_606596, "Qualifier", newJString(Qualifier))
  result = call_606594.call(path_606595, query_606596, nil, nil, nil)

var getProvisionedConcurrencyConfig* = Call_GetProvisionedConcurrencyConfig_606581(
    name: "getProvisionedConcurrencyConfig", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com", route: "/2019-09-30/functions/{FunctionName}/provisioned-concurrency#Qualifier",
    validator: validate_GetProvisionedConcurrencyConfig_606582, base: "/",
    url: url_GetProvisionedConcurrencyConfig_606583,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProvisionedConcurrencyConfig_606615 = ref object of OpenApiRestCall_605589
proc url_DeleteProvisionedConcurrencyConfig_606617(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteProvisionedConcurrencyConfig_606616(path: JsonNode;
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
  var valid_606618 = path.getOrDefault("FunctionName")
  valid_606618 = validateParameter(valid_606618, JString, required = true,
                                 default = nil)
  if valid_606618 != nil:
    section.add "FunctionName", valid_606618
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString (required)
  ##            : The version number or alias name.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Qualifier` field"
  var valid_606619 = query.getOrDefault("Qualifier")
  valid_606619 = validateParameter(valid_606619, JString, required = true,
                                 default = nil)
  if valid_606619 != nil:
    section.add "Qualifier", valid_606619
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
  var valid_606620 = header.getOrDefault("X-Amz-Signature")
  valid_606620 = validateParameter(valid_606620, JString, required = false,
                                 default = nil)
  if valid_606620 != nil:
    section.add "X-Amz-Signature", valid_606620
  var valid_606621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606621 = validateParameter(valid_606621, JString, required = false,
                                 default = nil)
  if valid_606621 != nil:
    section.add "X-Amz-Content-Sha256", valid_606621
  var valid_606622 = header.getOrDefault("X-Amz-Date")
  valid_606622 = validateParameter(valid_606622, JString, required = false,
                                 default = nil)
  if valid_606622 != nil:
    section.add "X-Amz-Date", valid_606622
  var valid_606623 = header.getOrDefault("X-Amz-Credential")
  valid_606623 = validateParameter(valid_606623, JString, required = false,
                                 default = nil)
  if valid_606623 != nil:
    section.add "X-Amz-Credential", valid_606623
  var valid_606624 = header.getOrDefault("X-Amz-Security-Token")
  valid_606624 = validateParameter(valid_606624, JString, required = false,
                                 default = nil)
  if valid_606624 != nil:
    section.add "X-Amz-Security-Token", valid_606624
  var valid_606625 = header.getOrDefault("X-Amz-Algorithm")
  valid_606625 = validateParameter(valid_606625, JString, required = false,
                                 default = nil)
  if valid_606625 != nil:
    section.add "X-Amz-Algorithm", valid_606625
  var valid_606626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606626 = validateParameter(valid_606626, JString, required = false,
                                 default = nil)
  if valid_606626 != nil:
    section.add "X-Amz-SignedHeaders", valid_606626
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606627: Call_DeleteProvisionedConcurrencyConfig_606615;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the provisioned concurrency configuration for a function.
  ## 
  let valid = call_606627.validator(path, query, header, formData, body)
  let scheme = call_606627.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606627.url(scheme.get, call_606627.host, call_606627.base,
                         call_606627.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606627, url, valid)

proc call*(call_606628: Call_DeleteProvisionedConcurrencyConfig_606615;
          FunctionName: string; Qualifier: string): Recallable =
  ## deleteProvisionedConcurrencyConfig
  ## Deletes the provisioned concurrency configuration for a function.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string (required)
  ##            : The version number or alias name.
  var path_606629 = newJObject()
  var query_606630 = newJObject()
  add(path_606629, "FunctionName", newJString(FunctionName))
  add(query_606630, "Qualifier", newJString(Qualifier))
  result = call_606628.call(path_606629, query_606630, nil, nil, nil)

var deleteProvisionedConcurrencyConfig* = Call_DeleteProvisionedConcurrencyConfig_606615(
    name: "deleteProvisionedConcurrencyConfig", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com", route: "/2019-09-30/functions/{FunctionName}/provisioned-concurrency#Qualifier",
    validator: validate_DeleteProvisionedConcurrencyConfig_606616, base: "/",
    url: url_DeleteProvisionedConcurrencyConfig_606617,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountSettings_606631 = ref object of OpenApiRestCall_605589
proc url_GetAccountSettings_606633(protocol: Scheme; host: string; base: string;
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

proc validate_GetAccountSettings_606632(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606634 = header.getOrDefault("X-Amz-Signature")
  valid_606634 = validateParameter(valid_606634, JString, required = false,
                                 default = nil)
  if valid_606634 != nil:
    section.add "X-Amz-Signature", valid_606634
  var valid_606635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606635 = validateParameter(valid_606635, JString, required = false,
                                 default = nil)
  if valid_606635 != nil:
    section.add "X-Amz-Content-Sha256", valid_606635
  var valid_606636 = header.getOrDefault("X-Amz-Date")
  valid_606636 = validateParameter(valid_606636, JString, required = false,
                                 default = nil)
  if valid_606636 != nil:
    section.add "X-Amz-Date", valid_606636
  var valid_606637 = header.getOrDefault("X-Amz-Credential")
  valid_606637 = validateParameter(valid_606637, JString, required = false,
                                 default = nil)
  if valid_606637 != nil:
    section.add "X-Amz-Credential", valid_606637
  var valid_606638 = header.getOrDefault("X-Amz-Security-Token")
  valid_606638 = validateParameter(valid_606638, JString, required = false,
                                 default = nil)
  if valid_606638 != nil:
    section.add "X-Amz-Security-Token", valid_606638
  var valid_606639 = header.getOrDefault("X-Amz-Algorithm")
  valid_606639 = validateParameter(valid_606639, JString, required = false,
                                 default = nil)
  if valid_606639 != nil:
    section.add "X-Amz-Algorithm", valid_606639
  var valid_606640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606640 = validateParameter(valid_606640, JString, required = false,
                                 default = nil)
  if valid_606640 != nil:
    section.add "X-Amz-SignedHeaders", valid_606640
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606641: Call_GetAccountSettings_606631; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details about your account's <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limits</a> and usage in an AWS Region.
  ## 
  let valid = call_606641.validator(path, query, header, formData, body)
  let scheme = call_606641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606641.url(scheme.get, call_606641.host, call_606641.base,
                         call_606641.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606641, url, valid)

proc call*(call_606642: Call_GetAccountSettings_606631): Recallable =
  ## getAccountSettings
  ## Retrieves details about your account's <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limits</a> and usage in an AWS Region.
  result = call_606642.call(nil, nil, nil, nil, nil)

var getAccountSettings* = Call_GetAccountSettings_606631(
    name: "getAccountSettings", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com", route: "/2016-08-19/account-settings/",
    validator: validate_GetAccountSettings_606632, base: "/",
    url: url_GetAccountSettings_606633, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionConcurrency_606643 = ref object of OpenApiRestCall_605589
proc url_GetFunctionConcurrency_606645(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFunctionConcurrency_606644(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns details about the concurrency configuration for a function. To set a concurrency limit for a function, use <a>PutFunctionConcurrency</a>.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_606646 = path.getOrDefault("FunctionName")
  valid_606646 = validateParameter(valid_606646, JString, required = true,
                                 default = nil)
  if valid_606646 != nil:
    section.add "FunctionName", valid_606646
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
  var valid_606647 = header.getOrDefault("X-Amz-Signature")
  valid_606647 = validateParameter(valid_606647, JString, required = false,
                                 default = nil)
  if valid_606647 != nil:
    section.add "X-Amz-Signature", valid_606647
  var valid_606648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606648 = validateParameter(valid_606648, JString, required = false,
                                 default = nil)
  if valid_606648 != nil:
    section.add "X-Amz-Content-Sha256", valid_606648
  var valid_606649 = header.getOrDefault("X-Amz-Date")
  valid_606649 = validateParameter(valid_606649, JString, required = false,
                                 default = nil)
  if valid_606649 != nil:
    section.add "X-Amz-Date", valid_606649
  var valid_606650 = header.getOrDefault("X-Amz-Credential")
  valid_606650 = validateParameter(valid_606650, JString, required = false,
                                 default = nil)
  if valid_606650 != nil:
    section.add "X-Amz-Credential", valid_606650
  var valid_606651 = header.getOrDefault("X-Amz-Security-Token")
  valid_606651 = validateParameter(valid_606651, JString, required = false,
                                 default = nil)
  if valid_606651 != nil:
    section.add "X-Amz-Security-Token", valid_606651
  var valid_606652 = header.getOrDefault("X-Amz-Algorithm")
  valid_606652 = validateParameter(valid_606652, JString, required = false,
                                 default = nil)
  if valid_606652 != nil:
    section.add "X-Amz-Algorithm", valid_606652
  var valid_606653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606653 = validateParameter(valid_606653, JString, required = false,
                                 default = nil)
  if valid_606653 != nil:
    section.add "X-Amz-SignedHeaders", valid_606653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606654: Call_GetFunctionConcurrency_606643; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns details about the concurrency configuration for a function. To set a concurrency limit for a function, use <a>PutFunctionConcurrency</a>.
  ## 
  let valid = call_606654.validator(path, query, header, formData, body)
  let scheme = call_606654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606654.url(scheme.get, call_606654.host, call_606654.base,
                         call_606654.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606654, url, valid)

proc call*(call_606655: Call_GetFunctionConcurrency_606643; FunctionName: string): Recallable =
  ## getFunctionConcurrency
  ## Returns details about the concurrency configuration for a function. To set a concurrency limit for a function, use <a>PutFunctionConcurrency</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  var path_606656 = newJObject()
  add(path_606656, "FunctionName", newJString(FunctionName))
  result = call_606655.call(path_606656, nil, nil, nil, nil)

var getFunctionConcurrency* = Call_GetFunctionConcurrency_606643(
    name: "getFunctionConcurrency", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2019-09-30/functions/{FunctionName}/concurrency",
    validator: validate_GetFunctionConcurrency_606644, base: "/",
    url: url_GetFunctionConcurrency_606645, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionConfiguration_606673 = ref object of OpenApiRestCall_605589
proc url_UpdateFunctionConfiguration_606675(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFunctionConfiguration_606674(path: JsonNode; query: JsonNode;
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
  var valid_606676 = path.getOrDefault("FunctionName")
  valid_606676 = validateParameter(valid_606676, JString, required = true,
                                 default = nil)
  if valid_606676 != nil:
    section.add "FunctionName", valid_606676
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
  var valid_606677 = header.getOrDefault("X-Amz-Signature")
  valid_606677 = validateParameter(valid_606677, JString, required = false,
                                 default = nil)
  if valid_606677 != nil:
    section.add "X-Amz-Signature", valid_606677
  var valid_606678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606678 = validateParameter(valid_606678, JString, required = false,
                                 default = nil)
  if valid_606678 != nil:
    section.add "X-Amz-Content-Sha256", valid_606678
  var valid_606679 = header.getOrDefault("X-Amz-Date")
  valid_606679 = validateParameter(valid_606679, JString, required = false,
                                 default = nil)
  if valid_606679 != nil:
    section.add "X-Amz-Date", valid_606679
  var valid_606680 = header.getOrDefault("X-Amz-Credential")
  valid_606680 = validateParameter(valid_606680, JString, required = false,
                                 default = nil)
  if valid_606680 != nil:
    section.add "X-Amz-Credential", valid_606680
  var valid_606681 = header.getOrDefault("X-Amz-Security-Token")
  valid_606681 = validateParameter(valid_606681, JString, required = false,
                                 default = nil)
  if valid_606681 != nil:
    section.add "X-Amz-Security-Token", valid_606681
  var valid_606682 = header.getOrDefault("X-Amz-Algorithm")
  valid_606682 = validateParameter(valid_606682, JString, required = false,
                                 default = nil)
  if valid_606682 != nil:
    section.add "X-Amz-Algorithm", valid_606682
  var valid_606683 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606683 = validateParameter(valid_606683, JString, required = false,
                                 default = nil)
  if valid_606683 != nil:
    section.add "X-Amz-SignedHeaders", valid_606683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606685: Call_UpdateFunctionConfiguration_606673; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modify the version-specific settings of a Lambda function.</p> <p>When you update a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute. During this time, you can't modify the function, but you can still invoke it. The <code>LastUpdateStatus</code>, <code>LastUpdateStatusReason</code>, and <code>LastUpdateStatusReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the update is complete and the function is processing events with the new configuration. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Function States</a>.</p> <p>These settings can vary between versions of a function and are locked when you publish a version. You can't modify the configuration of a published version, only the unpublished version.</p> <p>To configure function concurrency, use <a>PutFunctionConcurrency</a>. To grant invoke permissions to an account or AWS service, use <a>AddPermission</a>.</p>
  ## 
  let valid = call_606685.validator(path, query, header, formData, body)
  let scheme = call_606685.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606685.url(scheme.get, call_606685.host, call_606685.base,
                         call_606685.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606685, url, valid)

proc call*(call_606686: Call_UpdateFunctionConfiguration_606673;
          FunctionName: string; body: JsonNode): Recallable =
  ## updateFunctionConfiguration
  ## <p>Modify the version-specific settings of a Lambda function.</p> <p>When you update a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute. During this time, you can't modify the function, but you can still invoke it. The <code>LastUpdateStatus</code>, <code>LastUpdateStatusReason</code>, and <code>LastUpdateStatusReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the update is complete and the function is processing events with the new configuration. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Function States</a>.</p> <p>These settings can vary between versions of a function and are locked when you publish a version. You can't modify the configuration of a published version, only the unpublished version.</p> <p>To configure function concurrency, use <a>PutFunctionConcurrency</a>. To grant invoke permissions to an account or AWS service, use <a>AddPermission</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_606687 = newJObject()
  var body_606688 = newJObject()
  add(path_606687, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_606688 = body
  result = call_606686.call(path_606687, nil, nil, nil, body_606688)

var updateFunctionConfiguration* = Call_UpdateFunctionConfiguration_606673(
    name: "updateFunctionConfiguration", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/configuration",
    validator: validate_UpdateFunctionConfiguration_606674, base: "/",
    url: url_UpdateFunctionConfiguration_606675,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionConfiguration_606657 = ref object of OpenApiRestCall_605589
proc url_GetFunctionConfiguration_606659(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetFunctionConfiguration_606658(path: JsonNode; query: JsonNode;
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
  var valid_606660 = path.getOrDefault("FunctionName")
  valid_606660 = validateParameter(valid_606660, JString, required = true,
                                 default = nil)
  if valid_606660 != nil:
    section.add "FunctionName", valid_606660
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to get details about a published version of the function.
  section = newJObject()
  var valid_606661 = query.getOrDefault("Qualifier")
  valid_606661 = validateParameter(valid_606661, JString, required = false,
                                 default = nil)
  if valid_606661 != nil:
    section.add "Qualifier", valid_606661
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
  var valid_606662 = header.getOrDefault("X-Amz-Signature")
  valid_606662 = validateParameter(valid_606662, JString, required = false,
                                 default = nil)
  if valid_606662 != nil:
    section.add "X-Amz-Signature", valid_606662
  var valid_606663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606663 = validateParameter(valid_606663, JString, required = false,
                                 default = nil)
  if valid_606663 != nil:
    section.add "X-Amz-Content-Sha256", valid_606663
  var valid_606664 = header.getOrDefault("X-Amz-Date")
  valid_606664 = validateParameter(valid_606664, JString, required = false,
                                 default = nil)
  if valid_606664 != nil:
    section.add "X-Amz-Date", valid_606664
  var valid_606665 = header.getOrDefault("X-Amz-Credential")
  valid_606665 = validateParameter(valid_606665, JString, required = false,
                                 default = nil)
  if valid_606665 != nil:
    section.add "X-Amz-Credential", valid_606665
  var valid_606666 = header.getOrDefault("X-Amz-Security-Token")
  valid_606666 = validateParameter(valid_606666, JString, required = false,
                                 default = nil)
  if valid_606666 != nil:
    section.add "X-Amz-Security-Token", valid_606666
  var valid_606667 = header.getOrDefault("X-Amz-Algorithm")
  valid_606667 = validateParameter(valid_606667, JString, required = false,
                                 default = nil)
  if valid_606667 != nil:
    section.add "X-Amz-Algorithm", valid_606667
  var valid_606668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606668 = validateParameter(valid_606668, JString, required = false,
                                 default = nil)
  if valid_606668 != nil:
    section.add "X-Amz-SignedHeaders", valid_606668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606669: Call_GetFunctionConfiguration_606657; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the version-specific settings of a Lambda function or version. The output includes only options that can vary between versions of a function. To modify these settings, use <a>UpdateFunctionConfiguration</a>.</p> <p>To get all of a function's details, including function-level settings, use <a>GetFunction</a>.</p>
  ## 
  let valid = call_606669.validator(path, query, header, formData, body)
  let scheme = call_606669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606669.url(scheme.get, call_606669.host, call_606669.base,
                         call_606669.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606669, url, valid)

proc call*(call_606670: Call_GetFunctionConfiguration_606657; FunctionName: string;
          Qualifier: string = ""): Recallable =
  ## getFunctionConfiguration
  ## <p>Returns the version-specific settings of a Lambda function or version. The output includes only options that can vary between versions of a function. To modify these settings, use <a>UpdateFunctionConfiguration</a>.</p> <p>To get all of a function's details, including function-level settings, use <a>GetFunction</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to get details about a published version of the function.
  var path_606671 = newJObject()
  var query_606672 = newJObject()
  add(path_606671, "FunctionName", newJString(FunctionName))
  add(query_606672, "Qualifier", newJString(Qualifier))
  result = call_606670.call(path_606671, query_606672, nil, nil, nil)

var getFunctionConfiguration* = Call_GetFunctionConfiguration_606657(
    name: "getFunctionConfiguration", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/configuration",
    validator: validate_GetFunctionConfiguration_606658, base: "/",
    url: url_GetFunctionConfiguration_606659, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLayerVersionByArn_606689 = ref object of OpenApiRestCall_605589
proc url_GetLayerVersionByArn_606691(protocol: Scheme; host: string; base: string;
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

proc validate_GetLayerVersionByArn_606690(path: JsonNode; query: JsonNode;
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
  assert query != nil, "query argument is necessary due to required `find` field"
  var valid_606705 = query.getOrDefault("find")
  valid_606705 = validateParameter(valid_606705, JString, required = true,
                                 default = newJString("LayerVersion"))
  if valid_606705 != nil:
    section.add "find", valid_606705
  var valid_606706 = query.getOrDefault("Arn")
  valid_606706 = validateParameter(valid_606706, JString, required = true,
                                 default = nil)
  if valid_606706 != nil:
    section.add "Arn", valid_606706
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
  var valid_606707 = header.getOrDefault("X-Amz-Signature")
  valid_606707 = validateParameter(valid_606707, JString, required = false,
                                 default = nil)
  if valid_606707 != nil:
    section.add "X-Amz-Signature", valid_606707
  var valid_606708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606708 = validateParameter(valid_606708, JString, required = false,
                                 default = nil)
  if valid_606708 != nil:
    section.add "X-Amz-Content-Sha256", valid_606708
  var valid_606709 = header.getOrDefault("X-Amz-Date")
  valid_606709 = validateParameter(valid_606709, JString, required = false,
                                 default = nil)
  if valid_606709 != nil:
    section.add "X-Amz-Date", valid_606709
  var valid_606710 = header.getOrDefault("X-Amz-Credential")
  valid_606710 = validateParameter(valid_606710, JString, required = false,
                                 default = nil)
  if valid_606710 != nil:
    section.add "X-Amz-Credential", valid_606710
  var valid_606711 = header.getOrDefault("X-Amz-Security-Token")
  valid_606711 = validateParameter(valid_606711, JString, required = false,
                                 default = nil)
  if valid_606711 != nil:
    section.add "X-Amz-Security-Token", valid_606711
  var valid_606712 = header.getOrDefault("X-Amz-Algorithm")
  valid_606712 = validateParameter(valid_606712, JString, required = false,
                                 default = nil)
  if valid_606712 != nil:
    section.add "X-Amz-Algorithm", valid_606712
  var valid_606713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606713 = validateParameter(valid_606713, JString, required = false,
                                 default = nil)
  if valid_606713 != nil:
    section.add "X-Amz-SignedHeaders", valid_606713
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606714: Call_GetLayerVersionByArn_606689; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ## 
  let valid = call_606714.validator(path, query, header, formData, body)
  let scheme = call_606714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606714.url(scheme.get, call_606714.host, call_606714.base,
                         call_606714.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606714, url, valid)

proc call*(call_606715: Call_GetLayerVersionByArn_606689; Arn: string;
          find: string = "LayerVersion"): Recallable =
  ## getLayerVersionByArn
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ##   find: string (required)
  ##   Arn: string (required)
  ##      : The ARN of the layer version.
  var query_606716 = newJObject()
  add(query_606716, "find", newJString(find))
  add(query_606716, "Arn", newJString(Arn))
  result = call_606715.call(nil, query_606716, nil, nil, nil)

var getLayerVersionByArn* = Call_GetLayerVersionByArn_606689(
    name: "getLayerVersionByArn", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers#find=LayerVersion&Arn",
    validator: validate_GetLayerVersionByArn_606690, base: "/",
    url: url_GetLayerVersionByArn_606691, schemes: {Scheme.Https, Scheme.Http})
type
  Call_Invoke_606717 = ref object of OpenApiRestCall_605589
proc url_Invoke_606719(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_Invoke_606718(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606720 = path.getOrDefault("FunctionName")
  valid_606720 = validateParameter(valid_606720, JString, required = true,
                                 default = nil)
  if valid_606720 != nil:
    section.add "FunctionName", valid_606720
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to invoke a published version of the function.
  section = newJObject()
  var valid_606721 = query.getOrDefault("Qualifier")
  valid_606721 = validateParameter(valid_606721, JString, required = false,
                                 default = nil)
  if valid_606721 != nil:
    section.add "Qualifier", valid_606721
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Invocation-Type: JString
  ##                        : <p>Choose from the following options.</p> <ul> <li> <p> <code>RequestResponse</code> (default) - Invoke the function synchronously. Keep the connection open until the function returns a response or times out. The API response includes the function response and additional data.</p> </li> <li> <p> <code>Event</code> - Invoke the function asynchronously. Send events that fail multiple times to the function's dead-letter queue (if it's configured). The API response only includes a status code.</p> </li> <li> <p> <code>DryRun</code> - Validate parameter values and verify that the user or role has permission to invoke the function.</p> </li> </ul>
  ##   X-Amz-Signature: JString
  ##   X-Amz-Client-Context: JString
  ##                       : Up to 3583 bytes of base64-encoded data about the invoking client to pass to the function in the context object.
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Log-Type: JString
  ##                 : Set to <code>Tail</code> to include the execution log in the response.
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606722 = header.getOrDefault("X-Amz-Invocation-Type")
  valid_606722 = validateParameter(valid_606722, JString, required = false,
                                 default = newJString("Event"))
  if valid_606722 != nil:
    section.add "X-Amz-Invocation-Type", valid_606722
  var valid_606723 = header.getOrDefault("X-Amz-Signature")
  valid_606723 = validateParameter(valid_606723, JString, required = false,
                                 default = nil)
  if valid_606723 != nil:
    section.add "X-Amz-Signature", valid_606723
  var valid_606724 = header.getOrDefault("X-Amz-Client-Context")
  valid_606724 = validateParameter(valid_606724, JString, required = false,
                                 default = nil)
  if valid_606724 != nil:
    section.add "X-Amz-Client-Context", valid_606724
  var valid_606725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606725 = validateParameter(valid_606725, JString, required = false,
                                 default = nil)
  if valid_606725 != nil:
    section.add "X-Amz-Content-Sha256", valid_606725
  var valid_606726 = header.getOrDefault("X-Amz-Date")
  valid_606726 = validateParameter(valid_606726, JString, required = false,
                                 default = nil)
  if valid_606726 != nil:
    section.add "X-Amz-Date", valid_606726
  var valid_606727 = header.getOrDefault("X-Amz-Credential")
  valid_606727 = validateParameter(valid_606727, JString, required = false,
                                 default = nil)
  if valid_606727 != nil:
    section.add "X-Amz-Credential", valid_606727
  var valid_606728 = header.getOrDefault("X-Amz-Security-Token")
  valid_606728 = validateParameter(valid_606728, JString, required = false,
                                 default = nil)
  if valid_606728 != nil:
    section.add "X-Amz-Security-Token", valid_606728
  var valid_606729 = header.getOrDefault("X-Amz-Log-Type")
  valid_606729 = validateParameter(valid_606729, JString, required = false,
                                 default = newJString("None"))
  if valid_606729 != nil:
    section.add "X-Amz-Log-Type", valid_606729
  var valid_606730 = header.getOrDefault("X-Amz-Algorithm")
  valid_606730 = validateParameter(valid_606730, JString, required = false,
                                 default = nil)
  if valid_606730 != nil:
    section.add "X-Amz-Algorithm", valid_606730
  var valid_606731 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606731 = validateParameter(valid_606731, JString, required = false,
                                 default = nil)
  if valid_606731 != nil:
    section.add "X-Amz-SignedHeaders", valid_606731
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606733: Call_Invoke_606717; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Invokes a Lambda function. You can invoke a function synchronously (and wait for the response), or asynchronously. To invoke a function asynchronously, set <code>InvocationType</code> to <code>Event</code>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-sync.html">synchronous invocation</a>, details about the function response, including errors, are included in the response body and headers. For either invocation type, you can find more information in the <a href="https://docs.aws.amazon.com/lambda/latest/dg/monitoring-functions.html">execution log</a> and <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-x-ray.html">trace</a>.</p> <p>When an error occurs, your function may be invoked multiple times. Retry behavior varies by error type, client, event source, and invocation type. For example, if you invoke a function asynchronously and it returns an error, Lambda executes the function up to two more times. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/retries-on-errors.html">Retry Behavior</a>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a>, Lambda adds events to a queue before sending them to your function. If your function does not have enough capacity to keep up with the queue, events may be lost. Occasionally, your function may receive the same event multiple times, even if no error occurs. To retain events that were not processed, configure your function with a <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#dlq">dead-letter queue</a>.</p> <p>The status code in the API response doesn't reflect function errors. Error codes are reserved for errors that prevent your function from executing, such as permissions errors, <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limit errors</a>, or issues with your function's code and configuration. For example, Lambda returns <code>TooManyRequestsException</code> if executing the function would cause you to exceed a concurrency limit at either the account level (<code>ConcurrentInvocationLimitExceeded</code>) or function level (<code>ReservedFunctionConcurrentInvocationLimitExceeded</code>).</p> <p>For functions with a long timeout, your client might be disconnected during synchronous invocation while it waits for a response. Configure your HTTP client, SDK, firewall, proxy, or operating system to allow for long connections with timeout or keep-alive settings.</p> <p>This operation requires permission for the <code>lambda:InvokeFunction</code> action.</p>
  ## 
  let valid = call_606733.validator(path, query, header, formData, body)
  let scheme = call_606733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606733.url(scheme.get, call_606733.host, call_606733.base,
                         call_606733.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606733, url, valid)

proc call*(call_606734: Call_Invoke_606717; FunctionName: string; body: JsonNode;
          Qualifier: string = ""): Recallable =
  ## invoke
  ## <p>Invokes a Lambda function. You can invoke a function synchronously (and wait for the response), or asynchronously. To invoke a function asynchronously, set <code>InvocationType</code> to <code>Event</code>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-sync.html">synchronous invocation</a>, details about the function response, including errors, are included in the response body and headers. For either invocation type, you can find more information in the <a href="https://docs.aws.amazon.com/lambda/latest/dg/monitoring-functions.html">execution log</a> and <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-x-ray.html">trace</a>.</p> <p>When an error occurs, your function may be invoked multiple times. Retry behavior varies by error type, client, event source, and invocation type. For example, if you invoke a function asynchronously and it returns an error, Lambda executes the function up to two more times. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/retries-on-errors.html">Retry Behavior</a>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a>, Lambda adds events to a queue before sending them to your function. If your function does not have enough capacity to keep up with the queue, events may be lost. Occasionally, your function may receive the same event multiple times, even if no error occurs. To retain events that were not processed, configure your function with a <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#dlq">dead-letter queue</a>.</p> <p>The status code in the API response doesn't reflect function errors. Error codes are reserved for errors that prevent your function from executing, such as permissions errors, <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limit errors</a>, or issues with your function's code and configuration. For example, Lambda returns <code>TooManyRequestsException</code> if executing the function would cause you to exceed a concurrency limit at either the account level (<code>ConcurrentInvocationLimitExceeded</code>) or function level (<code>ReservedFunctionConcurrentInvocationLimitExceeded</code>).</p> <p>For functions with a long timeout, your client might be disconnected during synchronous invocation while it waits for a response. Configure your HTTP client, SDK, firewall, proxy, or operating system to allow for long connections with timeout or keep-alive settings.</p> <p>This operation requires permission for the <code>lambda:InvokeFunction</code> action.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to invoke a published version of the function.
  ##   body: JObject (required)
  var path_606735 = newJObject()
  var query_606736 = newJObject()
  var body_606737 = newJObject()
  add(path_606735, "FunctionName", newJString(FunctionName))
  add(query_606736, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_606737 = body
  result = call_606734.call(path_606735, query_606736, nil, nil, body_606737)

var invoke* = Call_Invoke_606717(name: "invoke", meth: HttpMethod.HttpPost,
                              host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/invocations",
                              validator: validate_Invoke_606718, base: "/",
                              url: url_Invoke_606719,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_InvokeAsync_606738 = ref object of OpenApiRestCall_605589
proc url_InvokeAsync_606740(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_InvokeAsync_606739(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606741 = path.getOrDefault("FunctionName")
  valid_606741 = validateParameter(valid_606741, JString, required = true,
                                 default = nil)
  if valid_606741 != nil:
    section.add "FunctionName", valid_606741
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
  var valid_606742 = header.getOrDefault("X-Amz-Signature")
  valid_606742 = validateParameter(valid_606742, JString, required = false,
                                 default = nil)
  if valid_606742 != nil:
    section.add "X-Amz-Signature", valid_606742
  var valid_606743 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606743 = validateParameter(valid_606743, JString, required = false,
                                 default = nil)
  if valid_606743 != nil:
    section.add "X-Amz-Content-Sha256", valid_606743
  var valid_606744 = header.getOrDefault("X-Amz-Date")
  valid_606744 = validateParameter(valid_606744, JString, required = false,
                                 default = nil)
  if valid_606744 != nil:
    section.add "X-Amz-Date", valid_606744
  var valid_606745 = header.getOrDefault("X-Amz-Credential")
  valid_606745 = validateParameter(valid_606745, JString, required = false,
                                 default = nil)
  if valid_606745 != nil:
    section.add "X-Amz-Credential", valid_606745
  var valid_606746 = header.getOrDefault("X-Amz-Security-Token")
  valid_606746 = validateParameter(valid_606746, JString, required = false,
                                 default = nil)
  if valid_606746 != nil:
    section.add "X-Amz-Security-Token", valid_606746
  var valid_606747 = header.getOrDefault("X-Amz-Algorithm")
  valid_606747 = validateParameter(valid_606747, JString, required = false,
                                 default = nil)
  if valid_606747 != nil:
    section.add "X-Amz-Algorithm", valid_606747
  var valid_606748 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606748 = validateParameter(valid_606748, JString, required = false,
                                 default = nil)
  if valid_606748 != nil:
    section.add "X-Amz-SignedHeaders", valid_606748
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606750: Call_InvokeAsync_606738; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <important> <p>For asynchronous function invocation, use <a>Invoke</a>.</p> </important> <p>Invokes a function asynchronously.</p>
  ## 
  let valid = call_606750.validator(path, query, header, formData, body)
  let scheme = call_606750.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606750.url(scheme.get, call_606750.host, call_606750.base,
                         call_606750.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606750, url, valid)

proc call*(call_606751: Call_InvokeAsync_606738; FunctionName: string; body: JsonNode): Recallable =
  ## invokeAsync
  ## <important> <p>For asynchronous function invocation, use <a>Invoke</a>.</p> </important> <p>Invokes a function asynchronously.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_606752 = newJObject()
  var body_606753 = newJObject()
  add(path_606752, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_606753 = body
  result = call_606751.call(path_606752, nil, nil, nil, body_606753)

var invokeAsync* = Call_InvokeAsync_606738(name: "invokeAsync",
                                        meth: HttpMethod.HttpPost,
                                        host: "lambda.amazonaws.com", route: "/2014-11-13/functions/{FunctionName}/invoke-async/",
                                        validator: validate_InvokeAsync_606739,
                                        base: "/", url: url_InvokeAsync_606740,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctionEventInvokeConfigs_606754 = ref object of OpenApiRestCall_605589
proc url_ListFunctionEventInvokeConfigs_606756(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListFunctionEventInvokeConfigs_606755(path: JsonNode;
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
  var valid_606757 = path.getOrDefault("FunctionName")
  valid_606757 = validateParameter(valid_606757, JString, required = true,
                                 default = nil)
  if valid_606757 != nil:
    section.add "FunctionName", valid_606757
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: JInt
  ##           : The maximum number of configurations to return.
  section = newJObject()
  var valid_606758 = query.getOrDefault("Marker")
  valid_606758 = validateParameter(valid_606758, JString, required = false,
                                 default = nil)
  if valid_606758 != nil:
    section.add "Marker", valid_606758
  var valid_606759 = query.getOrDefault("MaxItems")
  valid_606759 = validateParameter(valid_606759, JInt, required = false, default = nil)
  if valid_606759 != nil:
    section.add "MaxItems", valid_606759
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
  var valid_606760 = header.getOrDefault("X-Amz-Signature")
  valid_606760 = validateParameter(valid_606760, JString, required = false,
                                 default = nil)
  if valid_606760 != nil:
    section.add "X-Amz-Signature", valid_606760
  var valid_606761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606761 = validateParameter(valid_606761, JString, required = false,
                                 default = nil)
  if valid_606761 != nil:
    section.add "X-Amz-Content-Sha256", valid_606761
  var valid_606762 = header.getOrDefault("X-Amz-Date")
  valid_606762 = validateParameter(valid_606762, JString, required = false,
                                 default = nil)
  if valid_606762 != nil:
    section.add "X-Amz-Date", valid_606762
  var valid_606763 = header.getOrDefault("X-Amz-Credential")
  valid_606763 = validateParameter(valid_606763, JString, required = false,
                                 default = nil)
  if valid_606763 != nil:
    section.add "X-Amz-Credential", valid_606763
  var valid_606764 = header.getOrDefault("X-Amz-Security-Token")
  valid_606764 = validateParameter(valid_606764, JString, required = false,
                                 default = nil)
  if valid_606764 != nil:
    section.add "X-Amz-Security-Token", valid_606764
  var valid_606765 = header.getOrDefault("X-Amz-Algorithm")
  valid_606765 = validateParameter(valid_606765, JString, required = false,
                                 default = nil)
  if valid_606765 != nil:
    section.add "X-Amz-Algorithm", valid_606765
  var valid_606766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606766 = validateParameter(valid_606766, JString, required = false,
                                 default = nil)
  if valid_606766 != nil:
    section.add "X-Amz-SignedHeaders", valid_606766
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606767: Call_ListFunctionEventInvokeConfigs_606754; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list of configurations for asynchronous invocation for a function.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  let valid = call_606767.validator(path, query, header, formData, body)
  let scheme = call_606767.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606767.url(scheme.get, call_606767.host, call_606767.base,
                         call_606767.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606767, url, valid)

proc call*(call_606768: Call_ListFunctionEventInvokeConfigs_606754;
          FunctionName: string; Marker: string = ""; MaxItems: int = 0): Recallable =
  ## listFunctionEventInvokeConfigs
  ## <p>Retrieves a list of configurations for asynchronous invocation for a function.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ##   Marker: string
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   MaxItems: int
  ##           : The maximum number of configurations to return.
  var path_606769 = newJObject()
  var query_606770 = newJObject()
  add(query_606770, "Marker", newJString(Marker))
  add(path_606769, "FunctionName", newJString(FunctionName))
  add(query_606770, "MaxItems", newJInt(MaxItems))
  result = call_606768.call(path_606769, query_606770, nil, nil, nil)

var listFunctionEventInvokeConfigs* = Call_ListFunctionEventInvokeConfigs_606754(
    name: "listFunctionEventInvokeConfigs", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config/list",
    validator: validate_ListFunctionEventInvokeConfigs_606755, base: "/",
    url: url_ListFunctionEventInvokeConfigs_606756,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctions_606771 = ref object of OpenApiRestCall_605589
proc url_ListFunctions_606773(protocol: Scheme; host: string; base: string;
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

proc validate_ListFunctions_606772(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of Lambda functions, with the version-specific configuration of each.</p> <p>Set <code>FunctionVersion</code> to <code>ALL</code> to include all published versions of each function in addition to the unpublished version. To get more information about a function or version, use <a>GetFunction</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   FunctionVersion: JString
  ##                  : Set to <code>ALL</code> to include entries for all published versions of each function.
  ##   MaxItems: JInt
  ##           : Specify a value between 1 and 50 to limit the number of functions in the response.
  ##   MasterRegion: JString
  ##               : For Lambda@Edge functions, the AWS Region of the master function. For example, <code>us-east-2</code> or <code>ALL</code>. If specified, you must set <code>FunctionVersion</code> to <code>ALL</code>.
  section = newJObject()
  var valid_606774 = query.getOrDefault("Marker")
  valid_606774 = validateParameter(valid_606774, JString, required = false,
                                 default = nil)
  if valid_606774 != nil:
    section.add "Marker", valid_606774
  var valid_606775 = query.getOrDefault("FunctionVersion")
  valid_606775 = validateParameter(valid_606775, JString, required = false,
                                 default = newJString("ALL"))
  if valid_606775 != nil:
    section.add "FunctionVersion", valid_606775
  var valid_606776 = query.getOrDefault("MaxItems")
  valid_606776 = validateParameter(valid_606776, JInt, required = false, default = nil)
  if valid_606776 != nil:
    section.add "MaxItems", valid_606776
  var valid_606777 = query.getOrDefault("MasterRegion")
  valid_606777 = validateParameter(valid_606777, JString, required = false,
                                 default = nil)
  if valid_606777 != nil:
    section.add "MasterRegion", valid_606777
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
  var valid_606778 = header.getOrDefault("X-Amz-Signature")
  valid_606778 = validateParameter(valid_606778, JString, required = false,
                                 default = nil)
  if valid_606778 != nil:
    section.add "X-Amz-Signature", valid_606778
  var valid_606779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606779 = validateParameter(valid_606779, JString, required = false,
                                 default = nil)
  if valid_606779 != nil:
    section.add "X-Amz-Content-Sha256", valid_606779
  var valid_606780 = header.getOrDefault("X-Amz-Date")
  valid_606780 = validateParameter(valid_606780, JString, required = false,
                                 default = nil)
  if valid_606780 != nil:
    section.add "X-Amz-Date", valid_606780
  var valid_606781 = header.getOrDefault("X-Amz-Credential")
  valid_606781 = validateParameter(valid_606781, JString, required = false,
                                 default = nil)
  if valid_606781 != nil:
    section.add "X-Amz-Credential", valid_606781
  var valid_606782 = header.getOrDefault("X-Amz-Security-Token")
  valid_606782 = validateParameter(valid_606782, JString, required = false,
                                 default = nil)
  if valid_606782 != nil:
    section.add "X-Amz-Security-Token", valid_606782
  var valid_606783 = header.getOrDefault("X-Amz-Algorithm")
  valid_606783 = validateParameter(valid_606783, JString, required = false,
                                 default = nil)
  if valid_606783 != nil:
    section.add "X-Amz-Algorithm", valid_606783
  var valid_606784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606784 = validateParameter(valid_606784, JString, required = false,
                                 default = nil)
  if valid_606784 != nil:
    section.add "X-Amz-SignedHeaders", valid_606784
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606785: Call_ListFunctions_606771; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of Lambda functions, with the version-specific configuration of each.</p> <p>Set <code>FunctionVersion</code> to <code>ALL</code> to include all published versions of each function in addition to the unpublished version. To get more information about a function or version, use <a>GetFunction</a>.</p>
  ## 
  let valid = call_606785.validator(path, query, header, formData, body)
  let scheme = call_606785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606785.url(scheme.get, call_606785.host, call_606785.base,
                         call_606785.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606785, url, valid)

proc call*(call_606786: Call_ListFunctions_606771; Marker: string = "";
          FunctionVersion: string = "ALL"; MaxItems: int = 0; MasterRegion: string = ""): Recallable =
  ## listFunctions
  ## <p>Returns a list of Lambda functions, with the version-specific configuration of each.</p> <p>Set <code>FunctionVersion</code> to <code>ALL</code> to include all published versions of each function in addition to the unpublished version. To get more information about a function or version, use <a>GetFunction</a>.</p>
  ##   Marker: string
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   FunctionVersion: string
  ##                  : Set to <code>ALL</code> to include entries for all published versions of each function.
  ##   MaxItems: int
  ##           : Specify a value between 1 and 50 to limit the number of functions in the response.
  ##   MasterRegion: string
  ##               : For Lambda@Edge functions, the AWS Region of the master function. For example, <code>us-east-2</code> or <code>ALL</code>. If specified, you must set <code>FunctionVersion</code> to <code>ALL</code>.
  var query_606787 = newJObject()
  add(query_606787, "Marker", newJString(Marker))
  add(query_606787, "FunctionVersion", newJString(FunctionVersion))
  add(query_606787, "MaxItems", newJInt(MaxItems))
  add(query_606787, "MasterRegion", newJString(MasterRegion))
  result = call_606786.call(nil, query_606787, nil, nil, nil)

var listFunctions* = Call_ListFunctions_606771(name: "listFunctions",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/", validator: validate_ListFunctions_606772,
    base: "/", url: url_ListFunctions_606773, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PublishLayerVersion_606806 = ref object of OpenApiRestCall_605589
proc url_PublishLayerVersion_606808(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PublishLayerVersion_606807(path: JsonNode; query: JsonNode;
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
  var valid_606809 = path.getOrDefault("LayerName")
  valid_606809 = validateParameter(valid_606809, JString, required = true,
                                 default = nil)
  if valid_606809 != nil:
    section.add "LayerName", valid_606809
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
  var valid_606810 = header.getOrDefault("X-Amz-Signature")
  valid_606810 = validateParameter(valid_606810, JString, required = false,
                                 default = nil)
  if valid_606810 != nil:
    section.add "X-Amz-Signature", valid_606810
  var valid_606811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606811 = validateParameter(valid_606811, JString, required = false,
                                 default = nil)
  if valid_606811 != nil:
    section.add "X-Amz-Content-Sha256", valid_606811
  var valid_606812 = header.getOrDefault("X-Amz-Date")
  valid_606812 = validateParameter(valid_606812, JString, required = false,
                                 default = nil)
  if valid_606812 != nil:
    section.add "X-Amz-Date", valid_606812
  var valid_606813 = header.getOrDefault("X-Amz-Credential")
  valid_606813 = validateParameter(valid_606813, JString, required = false,
                                 default = nil)
  if valid_606813 != nil:
    section.add "X-Amz-Credential", valid_606813
  var valid_606814 = header.getOrDefault("X-Amz-Security-Token")
  valid_606814 = validateParameter(valid_606814, JString, required = false,
                                 default = nil)
  if valid_606814 != nil:
    section.add "X-Amz-Security-Token", valid_606814
  var valid_606815 = header.getOrDefault("X-Amz-Algorithm")
  valid_606815 = validateParameter(valid_606815, JString, required = false,
                                 default = nil)
  if valid_606815 != nil:
    section.add "X-Amz-Algorithm", valid_606815
  var valid_606816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606816 = validateParameter(valid_606816, JString, required = false,
                                 default = nil)
  if valid_606816 != nil:
    section.add "X-Amz-SignedHeaders", valid_606816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606818: Call_PublishLayerVersion_606806; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a> from a ZIP archive. Each time you call <code>PublishLayerVersion</code> with the same layer name, a new version is created.</p> <p>Add layers to your function with <a>CreateFunction</a> or <a>UpdateFunctionConfiguration</a>.</p>
  ## 
  let valid = call_606818.validator(path, query, header, formData, body)
  let scheme = call_606818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606818.url(scheme.get, call_606818.host, call_606818.base,
                         call_606818.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606818, url, valid)

proc call*(call_606819: Call_PublishLayerVersion_606806; LayerName: string;
          body: JsonNode): Recallable =
  ## publishLayerVersion
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a> from a ZIP archive. Each time you call <code>PublishLayerVersion</code> with the same layer name, a new version is created.</p> <p>Add layers to your function with <a>CreateFunction</a> or <a>UpdateFunctionConfiguration</a>.</p>
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  ##   body: JObject (required)
  var path_606820 = newJObject()
  var body_606821 = newJObject()
  add(path_606820, "LayerName", newJString(LayerName))
  if body != nil:
    body_606821 = body
  result = call_606819.call(path_606820, nil, nil, nil, body_606821)

var publishLayerVersion* = Call_PublishLayerVersion_606806(
    name: "publishLayerVersion", meth: HttpMethod.HttpPost,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions",
    validator: validate_PublishLayerVersion_606807, base: "/",
    url: url_PublishLayerVersion_606808, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLayerVersions_606788 = ref object of OpenApiRestCall_605589
proc url_ListLayerVersions_606790(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListLayerVersions_606789(path: JsonNode; query: JsonNode;
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
  var valid_606791 = path.getOrDefault("LayerName")
  valid_606791 = validateParameter(valid_606791, JString, required = true,
                                 default = nil)
  if valid_606791 != nil:
    section.add "LayerName", valid_606791
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : A pagination token returned by a previous call.
  ##   CompatibleRuntime: JString
  ##                    : A runtime identifier. For example, <code>go1.x</code>.
  ##   MaxItems: JInt
  ##           : The maximum number of versions to return.
  section = newJObject()
  var valid_606792 = query.getOrDefault("Marker")
  valid_606792 = validateParameter(valid_606792, JString, required = false,
                                 default = nil)
  if valid_606792 != nil:
    section.add "Marker", valid_606792
  var valid_606793 = query.getOrDefault("CompatibleRuntime")
  valid_606793 = validateParameter(valid_606793, JString, required = false,
                                 default = newJString("nodejs"))
  if valid_606793 != nil:
    section.add "CompatibleRuntime", valid_606793
  var valid_606794 = query.getOrDefault("MaxItems")
  valid_606794 = validateParameter(valid_606794, JInt, required = false, default = nil)
  if valid_606794 != nil:
    section.add "MaxItems", valid_606794
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
  var valid_606795 = header.getOrDefault("X-Amz-Signature")
  valid_606795 = validateParameter(valid_606795, JString, required = false,
                                 default = nil)
  if valid_606795 != nil:
    section.add "X-Amz-Signature", valid_606795
  var valid_606796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606796 = validateParameter(valid_606796, JString, required = false,
                                 default = nil)
  if valid_606796 != nil:
    section.add "X-Amz-Content-Sha256", valid_606796
  var valid_606797 = header.getOrDefault("X-Amz-Date")
  valid_606797 = validateParameter(valid_606797, JString, required = false,
                                 default = nil)
  if valid_606797 != nil:
    section.add "X-Amz-Date", valid_606797
  var valid_606798 = header.getOrDefault("X-Amz-Credential")
  valid_606798 = validateParameter(valid_606798, JString, required = false,
                                 default = nil)
  if valid_606798 != nil:
    section.add "X-Amz-Credential", valid_606798
  var valid_606799 = header.getOrDefault("X-Amz-Security-Token")
  valid_606799 = validateParameter(valid_606799, JString, required = false,
                                 default = nil)
  if valid_606799 != nil:
    section.add "X-Amz-Security-Token", valid_606799
  var valid_606800 = header.getOrDefault("X-Amz-Algorithm")
  valid_606800 = validateParameter(valid_606800, JString, required = false,
                                 default = nil)
  if valid_606800 != nil:
    section.add "X-Amz-Algorithm", valid_606800
  var valid_606801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606801 = validateParameter(valid_606801, JString, required = false,
                                 default = nil)
  if valid_606801 != nil:
    section.add "X-Amz-SignedHeaders", valid_606801
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606802: Call_ListLayerVersions_606788; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Versions that have been deleted aren't listed. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only versions that indicate that they're compatible with that runtime.
  ## 
  let valid = call_606802.validator(path, query, header, formData, body)
  let scheme = call_606802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606802.url(scheme.get, call_606802.host, call_606802.base,
                         call_606802.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606802, url, valid)

proc call*(call_606803: Call_ListLayerVersions_606788; LayerName: string;
          Marker: string = ""; CompatibleRuntime: string = "nodejs"; MaxItems: int = 0): Recallable =
  ## listLayerVersions
  ## Lists the versions of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Versions that have been deleted aren't listed. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only versions that indicate that they're compatible with that runtime.
  ##   Marker: string
  ##         : A pagination token returned by a previous call.
  ##   CompatibleRuntime: string
  ##                    : A runtime identifier. For example, <code>go1.x</code>.
  ##   MaxItems: int
  ##           : The maximum number of versions to return.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  var path_606804 = newJObject()
  var query_606805 = newJObject()
  add(query_606805, "Marker", newJString(Marker))
  add(query_606805, "CompatibleRuntime", newJString(CompatibleRuntime))
  add(query_606805, "MaxItems", newJInt(MaxItems))
  add(path_606804, "LayerName", newJString(LayerName))
  result = call_606803.call(path_606804, query_606805, nil, nil, nil)

var listLayerVersions* = Call_ListLayerVersions_606788(name: "listLayerVersions",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions",
    validator: validate_ListLayerVersions_606789, base: "/",
    url: url_ListLayerVersions_606790, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLayers_606822 = ref object of OpenApiRestCall_605589
proc url_ListLayers_606824(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListLayers_606823(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layers</a> and shows information about the latest version of each. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only layers that indicate that they're compatible with that runtime.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : A pagination token returned by a previous call.
  ##   CompatibleRuntime: JString
  ##                    : A runtime identifier. For example, <code>go1.x</code>.
  ##   MaxItems: JInt
  ##           : The maximum number of layers to return.
  section = newJObject()
  var valid_606825 = query.getOrDefault("Marker")
  valid_606825 = validateParameter(valid_606825, JString, required = false,
                                 default = nil)
  if valid_606825 != nil:
    section.add "Marker", valid_606825
  var valid_606826 = query.getOrDefault("CompatibleRuntime")
  valid_606826 = validateParameter(valid_606826, JString, required = false,
                                 default = newJString("nodejs"))
  if valid_606826 != nil:
    section.add "CompatibleRuntime", valid_606826
  var valid_606827 = query.getOrDefault("MaxItems")
  valid_606827 = validateParameter(valid_606827, JInt, required = false, default = nil)
  if valid_606827 != nil:
    section.add "MaxItems", valid_606827
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
  var valid_606828 = header.getOrDefault("X-Amz-Signature")
  valid_606828 = validateParameter(valid_606828, JString, required = false,
                                 default = nil)
  if valid_606828 != nil:
    section.add "X-Amz-Signature", valid_606828
  var valid_606829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606829 = validateParameter(valid_606829, JString, required = false,
                                 default = nil)
  if valid_606829 != nil:
    section.add "X-Amz-Content-Sha256", valid_606829
  var valid_606830 = header.getOrDefault("X-Amz-Date")
  valid_606830 = validateParameter(valid_606830, JString, required = false,
                                 default = nil)
  if valid_606830 != nil:
    section.add "X-Amz-Date", valid_606830
  var valid_606831 = header.getOrDefault("X-Amz-Credential")
  valid_606831 = validateParameter(valid_606831, JString, required = false,
                                 default = nil)
  if valid_606831 != nil:
    section.add "X-Amz-Credential", valid_606831
  var valid_606832 = header.getOrDefault("X-Amz-Security-Token")
  valid_606832 = validateParameter(valid_606832, JString, required = false,
                                 default = nil)
  if valid_606832 != nil:
    section.add "X-Amz-Security-Token", valid_606832
  var valid_606833 = header.getOrDefault("X-Amz-Algorithm")
  valid_606833 = validateParameter(valid_606833, JString, required = false,
                                 default = nil)
  if valid_606833 != nil:
    section.add "X-Amz-Algorithm", valid_606833
  var valid_606834 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606834 = validateParameter(valid_606834, JString, required = false,
                                 default = nil)
  if valid_606834 != nil:
    section.add "X-Amz-SignedHeaders", valid_606834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606835: Call_ListLayers_606822; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layers</a> and shows information about the latest version of each. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only layers that indicate that they're compatible with that runtime.
  ## 
  let valid = call_606835.validator(path, query, header, formData, body)
  let scheme = call_606835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606835.url(scheme.get, call_606835.host, call_606835.base,
                         call_606835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606835, url, valid)

proc call*(call_606836: Call_ListLayers_606822; Marker: string = "";
          CompatibleRuntime: string = "nodejs"; MaxItems: int = 0): Recallable =
  ## listLayers
  ## Lists <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layers</a> and shows information about the latest version of each. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only layers that indicate that they're compatible with that runtime.
  ##   Marker: string
  ##         : A pagination token returned by a previous call.
  ##   CompatibleRuntime: string
  ##                    : A runtime identifier. For example, <code>go1.x</code>.
  ##   MaxItems: int
  ##           : The maximum number of layers to return.
  var query_606837 = newJObject()
  add(query_606837, "Marker", newJString(Marker))
  add(query_606837, "CompatibleRuntime", newJString(CompatibleRuntime))
  add(query_606837, "MaxItems", newJInt(MaxItems))
  result = call_606836.call(nil, query_606837, nil, nil, nil)

var listLayers* = Call_ListLayers_606822(name: "listLayers",
                                      meth: HttpMethod.HttpGet,
                                      host: "lambda.amazonaws.com",
                                      route: "/2018-10-31/layers",
                                      validator: validate_ListLayers_606823,
                                      base: "/", url: url_ListLayers_606824,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisionedConcurrencyConfigs_606838 = ref object of OpenApiRestCall_605589
proc url_ListProvisionedConcurrencyConfigs_606840(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListProvisionedConcurrencyConfigs_606839(path: JsonNode;
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
  var valid_606841 = path.getOrDefault("FunctionName")
  valid_606841 = validateParameter(valid_606841, JString, required = true,
                                 default = nil)
  if valid_606841 != nil:
    section.add "FunctionName", valid_606841
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: JInt
  ##           : Specify a number to limit the number of configurations returned.
  ##   List: JString (required)
  section = newJObject()
  var valid_606842 = query.getOrDefault("Marker")
  valid_606842 = validateParameter(valid_606842, JString, required = false,
                                 default = nil)
  if valid_606842 != nil:
    section.add "Marker", valid_606842
  var valid_606843 = query.getOrDefault("MaxItems")
  valid_606843 = validateParameter(valid_606843, JInt, required = false, default = nil)
  if valid_606843 != nil:
    section.add "MaxItems", valid_606843
  assert query != nil, "query argument is necessary due to required `List` field"
  var valid_606844 = query.getOrDefault("List")
  valid_606844 = validateParameter(valid_606844, JString, required = true,
                                 default = newJString("ALL"))
  if valid_606844 != nil:
    section.add "List", valid_606844
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
  var valid_606845 = header.getOrDefault("X-Amz-Signature")
  valid_606845 = validateParameter(valid_606845, JString, required = false,
                                 default = nil)
  if valid_606845 != nil:
    section.add "X-Amz-Signature", valid_606845
  var valid_606846 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606846 = validateParameter(valid_606846, JString, required = false,
                                 default = nil)
  if valid_606846 != nil:
    section.add "X-Amz-Content-Sha256", valid_606846
  var valid_606847 = header.getOrDefault("X-Amz-Date")
  valid_606847 = validateParameter(valid_606847, JString, required = false,
                                 default = nil)
  if valid_606847 != nil:
    section.add "X-Amz-Date", valid_606847
  var valid_606848 = header.getOrDefault("X-Amz-Credential")
  valid_606848 = validateParameter(valid_606848, JString, required = false,
                                 default = nil)
  if valid_606848 != nil:
    section.add "X-Amz-Credential", valid_606848
  var valid_606849 = header.getOrDefault("X-Amz-Security-Token")
  valid_606849 = validateParameter(valid_606849, JString, required = false,
                                 default = nil)
  if valid_606849 != nil:
    section.add "X-Amz-Security-Token", valid_606849
  var valid_606850 = header.getOrDefault("X-Amz-Algorithm")
  valid_606850 = validateParameter(valid_606850, JString, required = false,
                                 default = nil)
  if valid_606850 != nil:
    section.add "X-Amz-Algorithm", valid_606850
  var valid_606851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606851 = validateParameter(valid_606851, JString, required = false,
                                 default = nil)
  if valid_606851 != nil:
    section.add "X-Amz-SignedHeaders", valid_606851
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606852: Call_ListProvisionedConcurrencyConfigs_606838;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves a list of provisioned concurrency configurations for a function.
  ## 
  let valid = call_606852.validator(path, query, header, formData, body)
  let scheme = call_606852.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606852.url(scheme.get, call_606852.host, call_606852.base,
                         call_606852.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606852, url, valid)

proc call*(call_606853: Call_ListProvisionedConcurrencyConfigs_606838;
          FunctionName: string; Marker: string = ""; MaxItems: int = 0;
          List: string = "ALL"): Recallable =
  ## listProvisionedConcurrencyConfigs
  ## Retrieves a list of provisioned concurrency configurations for a function.
  ##   Marker: string
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   MaxItems: int
  ##           : Specify a number to limit the number of configurations returned.
  ##   List: string (required)
  var path_606854 = newJObject()
  var query_606855 = newJObject()
  add(query_606855, "Marker", newJString(Marker))
  add(path_606854, "FunctionName", newJString(FunctionName))
  add(query_606855, "MaxItems", newJInt(MaxItems))
  add(query_606855, "List", newJString(List))
  result = call_606853.call(path_606854, query_606855, nil, nil, nil)

var listProvisionedConcurrencyConfigs* = Call_ListProvisionedConcurrencyConfigs_606838(
    name: "listProvisionedConcurrencyConfigs", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com", route: "/2019-09-30/functions/{FunctionName}/provisioned-concurrency#List=ALL",
    validator: validate_ListProvisionedConcurrencyConfigs_606839, base: "/",
    url: url_ListProvisionedConcurrencyConfigs_606840,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606870 = ref object of OpenApiRestCall_605589
proc url_TagResource_606872(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_606871(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606873 = path.getOrDefault("ARN")
  valid_606873 = validateParameter(valid_606873, JString, required = true,
                                 default = nil)
  if valid_606873 != nil:
    section.add "ARN", valid_606873
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
  var valid_606874 = header.getOrDefault("X-Amz-Signature")
  valid_606874 = validateParameter(valid_606874, JString, required = false,
                                 default = nil)
  if valid_606874 != nil:
    section.add "X-Amz-Signature", valid_606874
  var valid_606875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606875 = validateParameter(valid_606875, JString, required = false,
                                 default = nil)
  if valid_606875 != nil:
    section.add "X-Amz-Content-Sha256", valid_606875
  var valid_606876 = header.getOrDefault("X-Amz-Date")
  valid_606876 = validateParameter(valid_606876, JString, required = false,
                                 default = nil)
  if valid_606876 != nil:
    section.add "X-Amz-Date", valid_606876
  var valid_606877 = header.getOrDefault("X-Amz-Credential")
  valid_606877 = validateParameter(valid_606877, JString, required = false,
                                 default = nil)
  if valid_606877 != nil:
    section.add "X-Amz-Credential", valid_606877
  var valid_606878 = header.getOrDefault("X-Amz-Security-Token")
  valid_606878 = validateParameter(valid_606878, JString, required = false,
                                 default = nil)
  if valid_606878 != nil:
    section.add "X-Amz-Security-Token", valid_606878
  var valid_606879 = header.getOrDefault("X-Amz-Algorithm")
  valid_606879 = validateParameter(valid_606879, JString, required = false,
                                 default = nil)
  if valid_606879 != nil:
    section.add "X-Amz-Algorithm", valid_606879
  var valid_606880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606880 = validateParameter(valid_606880, JString, required = false,
                                 default = nil)
  if valid_606880 != nil:
    section.add "X-Amz-SignedHeaders", valid_606880
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606882: Call_TagResource_606870; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> to a function.
  ## 
  let valid = call_606882.validator(path, query, header, formData, body)
  let scheme = call_606882.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606882.url(scheme.get, call_606882.host, call_606882.base,
                         call_606882.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606882, url, valid)

proc call*(call_606883: Call_TagResource_606870; ARN: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> to a function.
  ##   ARN: string (required)
  ##      : The function's Amazon Resource Name (ARN).
  ##   body: JObject (required)
  var path_606884 = newJObject()
  var body_606885 = newJObject()
  add(path_606884, "ARN", newJString(ARN))
  if body != nil:
    body_606885 = body
  result = call_606883.call(path_606884, nil, nil, nil, body_606885)

var tagResource* = Call_TagResource_606870(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "lambda.amazonaws.com",
                                        route: "/2017-03-31/tags/{ARN}",
                                        validator: validate_TagResource_606871,
                                        base: "/", url: url_TagResource_606872,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_606856 = ref object of OpenApiRestCall_605589
proc url_ListTags_606858(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTags_606857(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606859 = path.getOrDefault("ARN")
  valid_606859 = validateParameter(valid_606859, JString, required = true,
                                 default = nil)
  if valid_606859 != nil:
    section.add "ARN", valid_606859
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
  var valid_606860 = header.getOrDefault("X-Amz-Signature")
  valid_606860 = validateParameter(valid_606860, JString, required = false,
                                 default = nil)
  if valid_606860 != nil:
    section.add "X-Amz-Signature", valid_606860
  var valid_606861 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606861 = validateParameter(valid_606861, JString, required = false,
                                 default = nil)
  if valid_606861 != nil:
    section.add "X-Amz-Content-Sha256", valid_606861
  var valid_606862 = header.getOrDefault("X-Amz-Date")
  valid_606862 = validateParameter(valid_606862, JString, required = false,
                                 default = nil)
  if valid_606862 != nil:
    section.add "X-Amz-Date", valid_606862
  var valid_606863 = header.getOrDefault("X-Amz-Credential")
  valid_606863 = validateParameter(valid_606863, JString, required = false,
                                 default = nil)
  if valid_606863 != nil:
    section.add "X-Amz-Credential", valid_606863
  var valid_606864 = header.getOrDefault("X-Amz-Security-Token")
  valid_606864 = validateParameter(valid_606864, JString, required = false,
                                 default = nil)
  if valid_606864 != nil:
    section.add "X-Amz-Security-Token", valid_606864
  var valid_606865 = header.getOrDefault("X-Amz-Algorithm")
  valid_606865 = validateParameter(valid_606865, JString, required = false,
                                 default = nil)
  if valid_606865 != nil:
    section.add "X-Amz-Algorithm", valid_606865
  var valid_606866 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606866 = validateParameter(valid_606866, JString, required = false,
                                 default = nil)
  if valid_606866 != nil:
    section.add "X-Amz-SignedHeaders", valid_606866
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606867: Call_ListTags_606856; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a function's <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a>. You can also view tags with <a>GetFunction</a>.
  ## 
  let valid = call_606867.validator(path, query, header, formData, body)
  let scheme = call_606867.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606867.url(scheme.get, call_606867.host, call_606867.base,
                         call_606867.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606867, url, valid)

proc call*(call_606868: Call_ListTags_606856; ARN: string): Recallable =
  ## listTags
  ## Returns a function's <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a>. You can also view tags with <a>GetFunction</a>.
  ##   ARN: string (required)
  ##      : The function's Amazon Resource Name (ARN).
  var path_606869 = newJObject()
  add(path_606869, "ARN", newJString(ARN))
  result = call_606868.call(path_606869, nil, nil, nil, nil)

var listTags* = Call_ListTags_606856(name: "listTags", meth: HttpMethod.HttpGet,
                                  host: "lambda.amazonaws.com",
                                  route: "/2017-03-31/tags/{ARN}",
                                  validator: validate_ListTags_606857, base: "/",
                                  url: url_ListTags_606858,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PublishVersion_606903 = ref object of OpenApiRestCall_605589
proc url_PublishVersion_606905(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PublishVersion_606904(path: JsonNode; query: JsonNode;
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
  var valid_606906 = path.getOrDefault("FunctionName")
  valid_606906 = validateParameter(valid_606906, JString, required = true,
                                 default = nil)
  if valid_606906 != nil:
    section.add "FunctionName", valid_606906
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
  var valid_606907 = header.getOrDefault("X-Amz-Signature")
  valid_606907 = validateParameter(valid_606907, JString, required = false,
                                 default = nil)
  if valid_606907 != nil:
    section.add "X-Amz-Signature", valid_606907
  var valid_606908 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606908 = validateParameter(valid_606908, JString, required = false,
                                 default = nil)
  if valid_606908 != nil:
    section.add "X-Amz-Content-Sha256", valid_606908
  var valid_606909 = header.getOrDefault("X-Amz-Date")
  valid_606909 = validateParameter(valid_606909, JString, required = false,
                                 default = nil)
  if valid_606909 != nil:
    section.add "X-Amz-Date", valid_606909
  var valid_606910 = header.getOrDefault("X-Amz-Credential")
  valid_606910 = validateParameter(valid_606910, JString, required = false,
                                 default = nil)
  if valid_606910 != nil:
    section.add "X-Amz-Credential", valid_606910
  var valid_606911 = header.getOrDefault("X-Amz-Security-Token")
  valid_606911 = validateParameter(valid_606911, JString, required = false,
                                 default = nil)
  if valid_606911 != nil:
    section.add "X-Amz-Security-Token", valid_606911
  var valid_606912 = header.getOrDefault("X-Amz-Algorithm")
  valid_606912 = validateParameter(valid_606912, JString, required = false,
                                 default = nil)
  if valid_606912 != nil:
    section.add "X-Amz-Algorithm", valid_606912
  var valid_606913 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606913 = validateParameter(valid_606913, JString, required = false,
                                 default = nil)
  if valid_606913 != nil:
    section.add "X-Amz-SignedHeaders", valid_606913
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606915: Call_PublishVersion_606903; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">version</a> from the current code and configuration of a function. Use versions to create a snapshot of your function code and configuration that doesn't change.</p> <p>AWS Lambda doesn't publish a version if the function's configuration and code haven't changed since the last version. Use <a>UpdateFunctionCode</a> or <a>UpdateFunctionConfiguration</a> to update the function before publishing a version.</p> <p>Clients can invoke versions directly or with an alias. To create an alias, use <a>CreateAlias</a>.</p>
  ## 
  let valid = call_606915.validator(path, query, header, formData, body)
  let scheme = call_606915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606915.url(scheme.get, call_606915.host, call_606915.base,
                         call_606915.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606915, url, valid)

proc call*(call_606916: Call_PublishVersion_606903; FunctionName: string;
          body: JsonNode): Recallable =
  ## publishVersion
  ## <p>Creates a <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">version</a> from the current code and configuration of a function. Use versions to create a snapshot of your function code and configuration that doesn't change.</p> <p>AWS Lambda doesn't publish a version if the function's configuration and code haven't changed since the last version. Use <a>UpdateFunctionCode</a> or <a>UpdateFunctionConfiguration</a> to update the function before publishing a version.</p> <p>Clients can invoke versions directly or with an alias. To create an alias, use <a>CreateAlias</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_606917 = newJObject()
  var body_606918 = newJObject()
  add(path_606917, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_606918 = body
  result = call_606916.call(path_606917, nil, nil, nil, body_606918)

var publishVersion* = Call_PublishVersion_606903(name: "publishVersion",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/versions",
    validator: validate_PublishVersion_606904, base: "/", url: url_PublishVersion_606905,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVersionsByFunction_606886 = ref object of OpenApiRestCall_605589
proc url_ListVersionsByFunction_606888(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListVersionsByFunction_606887(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">versions</a>, with the version-specific configuration of each. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   FunctionName: JString (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `FunctionName` field"
  var valid_606889 = path.getOrDefault("FunctionName")
  valid_606889 = validateParameter(valid_606889, JString, required = true,
                                 default = nil)
  if valid_606889 != nil:
    section.add "FunctionName", valid_606889
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: JInt
  ##           : Limit the number of versions that are returned.
  section = newJObject()
  var valid_606890 = query.getOrDefault("Marker")
  valid_606890 = validateParameter(valid_606890, JString, required = false,
                                 default = nil)
  if valid_606890 != nil:
    section.add "Marker", valid_606890
  var valid_606891 = query.getOrDefault("MaxItems")
  valid_606891 = validateParameter(valid_606891, JInt, required = false, default = nil)
  if valid_606891 != nil:
    section.add "MaxItems", valid_606891
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
  var valid_606892 = header.getOrDefault("X-Amz-Signature")
  valid_606892 = validateParameter(valid_606892, JString, required = false,
                                 default = nil)
  if valid_606892 != nil:
    section.add "X-Amz-Signature", valid_606892
  var valid_606893 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606893 = validateParameter(valid_606893, JString, required = false,
                                 default = nil)
  if valid_606893 != nil:
    section.add "X-Amz-Content-Sha256", valid_606893
  var valid_606894 = header.getOrDefault("X-Amz-Date")
  valid_606894 = validateParameter(valid_606894, JString, required = false,
                                 default = nil)
  if valid_606894 != nil:
    section.add "X-Amz-Date", valid_606894
  var valid_606895 = header.getOrDefault("X-Amz-Credential")
  valid_606895 = validateParameter(valid_606895, JString, required = false,
                                 default = nil)
  if valid_606895 != nil:
    section.add "X-Amz-Credential", valid_606895
  var valid_606896 = header.getOrDefault("X-Amz-Security-Token")
  valid_606896 = validateParameter(valid_606896, JString, required = false,
                                 default = nil)
  if valid_606896 != nil:
    section.add "X-Amz-Security-Token", valid_606896
  var valid_606897 = header.getOrDefault("X-Amz-Algorithm")
  valid_606897 = validateParameter(valid_606897, JString, required = false,
                                 default = nil)
  if valid_606897 != nil:
    section.add "X-Amz-Algorithm", valid_606897
  var valid_606898 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606898 = validateParameter(valid_606898, JString, required = false,
                                 default = nil)
  if valid_606898 != nil:
    section.add "X-Amz-SignedHeaders", valid_606898
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606899: Call_ListVersionsByFunction_606886; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">versions</a>, with the version-specific configuration of each. 
  ## 
  let valid = call_606899.validator(path, query, header, formData, body)
  let scheme = call_606899.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606899.url(scheme.get, call_606899.host, call_606899.base,
                         call_606899.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606899, url, valid)

proc call*(call_606900: Call_ListVersionsByFunction_606886; FunctionName: string;
          Marker: string = ""; MaxItems: int = 0): Recallable =
  ## listVersionsByFunction
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">versions</a>, with the version-specific configuration of each. 
  ##   Marker: string
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   MaxItems: int
  ##           : Limit the number of versions that are returned.
  var path_606901 = newJObject()
  var query_606902 = newJObject()
  add(query_606902, "Marker", newJString(Marker))
  add(path_606901, "FunctionName", newJString(FunctionName))
  add(query_606902, "MaxItems", newJInt(MaxItems))
  result = call_606900.call(path_606901, query_606902, nil, nil, nil)

var listVersionsByFunction* = Call_ListVersionsByFunction_606886(
    name: "listVersionsByFunction", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/versions",
    validator: validate_ListVersionsByFunction_606887, base: "/",
    url: url_ListVersionsByFunction_606888, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveLayerVersionPermission_606919 = ref object of OpenApiRestCall_605589
proc url_RemoveLayerVersionPermission_606921(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RemoveLayerVersionPermission_606920(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_606922 = path.getOrDefault("VersionNumber")
  valid_606922 = validateParameter(valid_606922, JInt, required = true, default = nil)
  if valid_606922 != nil:
    section.add "VersionNumber", valid_606922
  var valid_606923 = path.getOrDefault("StatementId")
  valid_606923 = validateParameter(valid_606923, JString, required = true,
                                 default = nil)
  if valid_606923 != nil:
    section.add "StatementId", valid_606923
  var valid_606924 = path.getOrDefault("LayerName")
  valid_606924 = validateParameter(valid_606924, JString, required = true,
                                 default = nil)
  if valid_606924 != nil:
    section.add "LayerName", valid_606924
  result.add "path", section
  ## parameters in `query` object:
  ##   RevisionId: JString
  ##             : Only update the policy if the revision ID matches the ID specified. Use this option to avoid modifying a policy that has changed since you last read it.
  section = newJObject()
  var valid_606925 = query.getOrDefault("RevisionId")
  valid_606925 = validateParameter(valid_606925, JString, required = false,
                                 default = nil)
  if valid_606925 != nil:
    section.add "RevisionId", valid_606925
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
  var valid_606926 = header.getOrDefault("X-Amz-Signature")
  valid_606926 = validateParameter(valid_606926, JString, required = false,
                                 default = nil)
  if valid_606926 != nil:
    section.add "X-Amz-Signature", valid_606926
  var valid_606927 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606927 = validateParameter(valid_606927, JString, required = false,
                                 default = nil)
  if valid_606927 != nil:
    section.add "X-Amz-Content-Sha256", valid_606927
  var valid_606928 = header.getOrDefault("X-Amz-Date")
  valid_606928 = validateParameter(valid_606928, JString, required = false,
                                 default = nil)
  if valid_606928 != nil:
    section.add "X-Amz-Date", valid_606928
  var valid_606929 = header.getOrDefault("X-Amz-Credential")
  valid_606929 = validateParameter(valid_606929, JString, required = false,
                                 default = nil)
  if valid_606929 != nil:
    section.add "X-Amz-Credential", valid_606929
  var valid_606930 = header.getOrDefault("X-Amz-Security-Token")
  valid_606930 = validateParameter(valid_606930, JString, required = false,
                                 default = nil)
  if valid_606930 != nil:
    section.add "X-Amz-Security-Token", valid_606930
  var valid_606931 = header.getOrDefault("X-Amz-Algorithm")
  valid_606931 = validateParameter(valid_606931, JString, required = false,
                                 default = nil)
  if valid_606931 != nil:
    section.add "X-Amz-Algorithm", valid_606931
  var valid_606932 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606932 = validateParameter(valid_606932, JString, required = false,
                                 default = nil)
  if valid_606932 != nil:
    section.add "X-Amz-SignedHeaders", valid_606932
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606933: Call_RemoveLayerVersionPermission_606919; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a statement from the permissions policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ## 
  let valid = call_606933.validator(path, query, header, formData, body)
  let scheme = call_606933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606933.url(scheme.get, call_606933.host, call_606933.base,
                         call_606933.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606933, url, valid)

proc call*(call_606934: Call_RemoveLayerVersionPermission_606919;
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
  var path_606935 = newJObject()
  var query_606936 = newJObject()
  add(query_606936, "RevisionId", newJString(RevisionId))
  add(path_606935, "VersionNumber", newJInt(VersionNumber))
  add(path_606935, "StatementId", newJString(StatementId))
  add(path_606935, "LayerName", newJString(LayerName))
  result = call_606934.call(path_606935, query_606936, nil, nil, nil)

var removeLayerVersionPermission* = Call_RemoveLayerVersionPermission_606919(
    name: "removeLayerVersionPermission", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com", route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy/{StatementId}",
    validator: validate_RemoveLayerVersionPermission_606920, base: "/",
    url: url_RemoveLayerVersionPermission_606921,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemovePermission_606937 = ref object of OpenApiRestCall_605589
proc url_RemovePermission_606939(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RemovePermission_606938(path: JsonNode; query: JsonNode;
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
  var valid_606940 = path.getOrDefault("FunctionName")
  valid_606940 = validateParameter(valid_606940, JString, required = true,
                                 default = nil)
  if valid_606940 != nil:
    section.add "FunctionName", valid_606940
  var valid_606941 = path.getOrDefault("StatementId")
  valid_606941 = validateParameter(valid_606941, JString, required = true,
                                 default = nil)
  if valid_606941 != nil:
    section.add "StatementId", valid_606941
  result.add "path", section
  ## parameters in `query` object:
  ##   RevisionId: JString
  ##             : Only update the policy if the revision ID matches the ID that's specified. Use this option to avoid modifying a policy that has changed since you last read it.
  ##   Qualifier: JString
  ##            : Specify a version or alias to remove permissions from a published version of the function.
  section = newJObject()
  var valid_606942 = query.getOrDefault("RevisionId")
  valid_606942 = validateParameter(valid_606942, JString, required = false,
                                 default = nil)
  if valid_606942 != nil:
    section.add "RevisionId", valid_606942
  var valid_606943 = query.getOrDefault("Qualifier")
  valid_606943 = validateParameter(valid_606943, JString, required = false,
                                 default = nil)
  if valid_606943 != nil:
    section.add "Qualifier", valid_606943
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
  var valid_606944 = header.getOrDefault("X-Amz-Signature")
  valid_606944 = validateParameter(valid_606944, JString, required = false,
                                 default = nil)
  if valid_606944 != nil:
    section.add "X-Amz-Signature", valid_606944
  var valid_606945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606945 = validateParameter(valid_606945, JString, required = false,
                                 default = nil)
  if valid_606945 != nil:
    section.add "X-Amz-Content-Sha256", valid_606945
  var valid_606946 = header.getOrDefault("X-Amz-Date")
  valid_606946 = validateParameter(valid_606946, JString, required = false,
                                 default = nil)
  if valid_606946 != nil:
    section.add "X-Amz-Date", valid_606946
  var valid_606947 = header.getOrDefault("X-Amz-Credential")
  valid_606947 = validateParameter(valid_606947, JString, required = false,
                                 default = nil)
  if valid_606947 != nil:
    section.add "X-Amz-Credential", valid_606947
  var valid_606948 = header.getOrDefault("X-Amz-Security-Token")
  valid_606948 = validateParameter(valid_606948, JString, required = false,
                                 default = nil)
  if valid_606948 != nil:
    section.add "X-Amz-Security-Token", valid_606948
  var valid_606949 = header.getOrDefault("X-Amz-Algorithm")
  valid_606949 = validateParameter(valid_606949, JString, required = false,
                                 default = nil)
  if valid_606949 != nil:
    section.add "X-Amz-Algorithm", valid_606949
  var valid_606950 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606950 = validateParameter(valid_606950, JString, required = false,
                                 default = nil)
  if valid_606950 != nil:
    section.add "X-Amz-SignedHeaders", valid_606950
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606951: Call_RemovePermission_606937; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Revokes function-use permission from an AWS service or another account. You can get the ID of the statement from the output of <a>GetPolicy</a>.
  ## 
  let valid = call_606951.validator(path, query, header, formData, body)
  let scheme = call_606951.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606951.url(scheme.get, call_606951.host, call_606951.base,
                         call_606951.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606951, url, valid)

proc call*(call_606952: Call_RemovePermission_606937; FunctionName: string;
          StatementId: string; RevisionId: string = ""; Qualifier: string = ""): Recallable =
  ## removePermission
  ## Revokes function-use permission from an AWS service or another account. You can get the ID of the statement from the output of <a>GetPolicy</a>.
  ##   RevisionId: string
  ##             : Only update the policy if the revision ID matches the ID that's specified. Use this option to avoid modifying a policy that has changed since you last read it.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   StatementId: string (required)
  ##              : Statement ID of the permission to remove.
  ##   Qualifier: string
  ##            : Specify a version or alias to remove permissions from a published version of the function.
  var path_606953 = newJObject()
  var query_606954 = newJObject()
  add(query_606954, "RevisionId", newJString(RevisionId))
  add(path_606953, "FunctionName", newJString(FunctionName))
  add(path_606953, "StatementId", newJString(StatementId))
  add(query_606954, "Qualifier", newJString(Qualifier))
  result = call_606952.call(path_606953, query_606954, nil, nil, nil)

var removePermission* = Call_RemovePermission_606937(name: "removePermission",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/policy/{StatementId}",
    validator: validate_RemovePermission_606938, base: "/",
    url: url_RemovePermission_606939, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606955 = ref object of OpenApiRestCall_605589
proc url_UntagResource_606957(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_606956(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606958 = path.getOrDefault("ARN")
  valid_606958 = validateParameter(valid_606958, JString, required = true,
                                 default = nil)
  if valid_606958 != nil:
    section.add "ARN", valid_606958
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A list of tag keys to remove from the function.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_606959 = query.getOrDefault("tagKeys")
  valid_606959 = validateParameter(valid_606959, JArray, required = true, default = nil)
  if valid_606959 != nil:
    section.add "tagKeys", valid_606959
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
  var valid_606960 = header.getOrDefault("X-Amz-Signature")
  valid_606960 = validateParameter(valid_606960, JString, required = false,
                                 default = nil)
  if valid_606960 != nil:
    section.add "X-Amz-Signature", valid_606960
  var valid_606961 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606961 = validateParameter(valid_606961, JString, required = false,
                                 default = nil)
  if valid_606961 != nil:
    section.add "X-Amz-Content-Sha256", valid_606961
  var valid_606962 = header.getOrDefault("X-Amz-Date")
  valid_606962 = validateParameter(valid_606962, JString, required = false,
                                 default = nil)
  if valid_606962 != nil:
    section.add "X-Amz-Date", valid_606962
  var valid_606963 = header.getOrDefault("X-Amz-Credential")
  valid_606963 = validateParameter(valid_606963, JString, required = false,
                                 default = nil)
  if valid_606963 != nil:
    section.add "X-Amz-Credential", valid_606963
  var valid_606964 = header.getOrDefault("X-Amz-Security-Token")
  valid_606964 = validateParameter(valid_606964, JString, required = false,
                                 default = nil)
  if valid_606964 != nil:
    section.add "X-Amz-Security-Token", valid_606964
  var valid_606965 = header.getOrDefault("X-Amz-Algorithm")
  valid_606965 = validateParameter(valid_606965, JString, required = false,
                                 default = nil)
  if valid_606965 != nil:
    section.add "X-Amz-Algorithm", valid_606965
  var valid_606966 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606966 = validateParameter(valid_606966, JString, required = false,
                                 default = nil)
  if valid_606966 != nil:
    section.add "X-Amz-SignedHeaders", valid_606966
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606967: Call_UntagResource_606955; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> from a function.
  ## 
  let valid = call_606967.validator(path, query, header, formData, body)
  let scheme = call_606967.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606967.url(scheme.get, call_606967.host, call_606967.base,
                         call_606967.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606967, url, valid)

proc call*(call_606968: Call_UntagResource_606955; ARN: string; tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> from a function.
  ##   ARN: string (required)
  ##      : The function's Amazon Resource Name (ARN).
  ##   tagKeys: JArray (required)
  ##          : A list of tag keys to remove from the function.
  var path_606969 = newJObject()
  var query_606970 = newJObject()
  add(path_606969, "ARN", newJString(ARN))
  if tagKeys != nil:
    query_606970.add "tagKeys", tagKeys
  result = call_606968.call(path_606969, query_606970, nil, nil, nil)

var untagResource* = Call_UntagResource_606955(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2017-03-31/tags/{ARN}#tagKeys", validator: validate_UntagResource_606956,
    base: "/", url: url_UntagResource_606957, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionCode_606971 = ref object of OpenApiRestCall_605589
proc url_UpdateFunctionCode_606973(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFunctionCode_606972(path: JsonNode; query: JsonNode;
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
  var valid_606974 = path.getOrDefault("FunctionName")
  valid_606974 = validateParameter(valid_606974, JString, required = true,
                                 default = nil)
  if valid_606974 != nil:
    section.add "FunctionName", valid_606974
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
  var valid_606975 = header.getOrDefault("X-Amz-Signature")
  valid_606975 = validateParameter(valid_606975, JString, required = false,
                                 default = nil)
  if valid_606975 != nil:
    section.add "X-Amz-Signature", valid_606975
  var valid_606976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606976 = validateParameter(valid_606976, JString, required = false,
                                 default = nil)
  if valid_606976 != nil:
    section.add "X-Amz-Content-Sha256", valid_606976
  var valid_606977 = header.getOrDefault("X-Amz-Date")
  valid_606977 = validateParameter(valid_606977, JString, required = false,
                                 default = nil)
  if valid_606977 != nil:
    section.add "X-Amz-Date", valid_606977
  var valid_606978 = header.getOrDefault("X-Amz-Credential")
  valid_606978 = validateParameter(valid_606978, JString, required = false,
                                 default = nil)
  if valid_606978 != nil:
    section.add "X-Amz-Credential", valid_606978
  var valid_606979 = header.getOrDefault("X-Amz-Security-Token")
  valid_606979 = validateParameter(valid_606979, JString, required = false,
                                 default = nil)
  if valid_606979 != nil:
    section.add "X-Amz-Security-Token", valid_606979
  var valid_606980 = header.getOrDefault("X-Amz-Algorithm")
  valid_606980 = validateParameter(valid_606980, JString, required = false,
                                 default = nil)
  if valid_606980 != nil:
    section.add "X-Amz-Algorithm", valid_606980
  var valid_606981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606981 = validateParameter(valid_606981, JString, required = false,
                                 default = nil)
  if valid_606981 != nil:
    section.add "X-Amz-SignedHeaders", valid_606981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606983: Call_UpdateFunctionCode_606971; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a Lambda function's code.</p> <p>The function's code is locked when you publish a version. You can't modify the code of a published version, only the unpublished version.</p>
  ## 
  let valid = call_606983.validator(path, query, header, formData, body)
  let scheme = call_606983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606983.url(scheme.get, call_606983.host, call_606983.base,
                         call_606983.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606983, url, valid)

proc call*(call_606984: Call_UpdateFunctionCode_606971; FunctionName: string;
          body: JsonNode): Recallable =
  ## updateFunctionCode
  ## <p>Updates a Lambda function's code.</p> <p>The function's code is locked when you publish a version. You can't modify the code of a published version, only the unpublished version.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_606985 = newJObject()
  var body_606986 = newJObject()
  add(path_606985, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_606986 = body
  result = call_606984.call(path_606985, nil, nil, nil, body_606986)

var updateFunctionCode* = Call_UpdateFunctionCode_606971(
    name: "updateFunctionCode", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/code",
    validator: validate_UpdateFunctionCode_606972, base: "/",
    url: url_UpdateFunctionCode_606973, schemes: {Scheme.Https, Scheme.Http})
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
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
