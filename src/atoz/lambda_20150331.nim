
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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  Call_AddLayerVersionPermission_601998 = ref object of OpenApiRestCall_601389
proc url_AddLayerVersionPermission_602000(protocol: Scheme; host: string;
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

proc validate_AddLayerVersionPermission_601999(path: JsonNode; query: JsonNode;
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
  var valid_602001 = path.getOrDefault("VersionNumber")
  valid_602001 = validateParameter(valid_602001, JInt, required = true, default = nil)
  if valid_602001 != nil:
    section.add "VersionNumber", valid_602001
  var valid_602002 = path.getOrDefault("LayerName")
  valid_602002 = validateParameter(valid_602002, JString, required = true,
                                 default = nil)
  if valid_602002 != nil:
    section.add "LayerName", valid_602002
  result.add "path", section
  ## parameters in `query` object:
  ##   RevisionId: JString
  ##             : Only update the policy if the revision ID matches the ID specified. Use this option to avoid modifying a policy that has changed since you last read it.
  section = newJObject()
  var valid_602003 = query.getOrDefault("RevisionId")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "RevisionId", valid_602003
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

proc call*(call_602012: Call_AddLayerVersionPermission_601998; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds permissions to the resource-based policy of a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Use this action to grant layer usage permission to other accounts. You can grant permission to a single account, all AWS accounts, or all accounts in an organization.</p> <p>To revoke permission, call <a>RemoveLayerVersionPermission</a> with the statement ID that you specified when you added it.</p>
  ## 
  let valid = call_602012.validator(path, query, header, formData, body)
  let scheme = call_602012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602012.url(scheme.get, call_602012.host, call_602012.base,
                         call_602012.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602012, url, valid)

proc call*(call_602013: Call_AddLayerVersionPermission_601998; VersionNumber: int;
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
  var path_602014 = newJObject()
  var query_602015 = newJObject()
  var body_602016 = newJObject()
  add(query_602015, "RevisionId", newJString(RevisionId))
  add(path_602014, "VersionNumber", newJInt(VersionNumber))
  add(path_602014, "LayerName", newJString(LayerName))
  if body != nil:
    body_602016 = body
  result = call_602013.call(path_602014, query_602015, nil, nil, body_602016)

var addLayerVersionPermission* = Call_AddLayerVersionPermission_601998(
    name: "addLayerVersionPermission", meth: HttpMethod.HttpPost,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy",
    validator: validate_AddLayerVersionPermission_601999, base: "/",
    url: url_AddLayerVersionPermission_602000,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLayerVersionPolicy_601727 = ref object of OpenApiRestCall_601389
proc url_GetLayerVersionPolicy_601729(protocol: Scheme; host: string; base: string;
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

proc validate_GetLayerVersionPolicy_601728(path: JsonNode; query: JsonNode;
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
  var valid_601855 = path.getOrDefault("VersionNumber")
  valid_601855 = validateParameter(valid_601855, JInt, required = true, default = nil)
  if valid_601855 != nil:
    section.add "VersionNumber", valid_601855
  var valid_601856 = path.getOrDefault("LayerName")
  valid_601856 = validateParameter(valid_601856, JString, required = true,
                                 default = nil)
  if valid_601856 != nil:
    section.add "LayerName", valid_601856
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
  if body != nil:
    result.add "body", body

proc call*(call_601886: Call_GetLayerVersionPolicy_601727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the permission policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ## 
  let valid = call_601886.validator(path, query, header, formData, body)
  let scheme = call_601886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601886.url(scheme.get, call_601886.host, call_601886.base,
                         call_601886.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601886, url, valid)

proc call*(call_601957: Call_GetLayerVersionPolicy_601727; VersionNumber: int;
          LayerName: string): Recallable =
  ## getLayerVersionPolicy
  ## Returns the permission policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ##   VersionNumber: int (required)
  ##                : The version number.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  var path_601958 = newJObject()
  add(path_601958, "VersionNumber", newJInt(VersionNumber))
  add(path_601958, "LayerName", newJString(LayerName))
  result = call_601957.call(path_601958, nil, nil, nil, nil)

var getLayerVersionPolicy* = Call_GetLayerVersionPolicy_601727(
    name: "getLayerVersionPolicy", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy",
    validator: validate_GetLayerVersionPolicy_601728, base: "/",
    url: url_GetLayerVersionPolicy_601729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddPermission_602033 = ref object of OpenApiRestCall_601389
proc url_AddPermission_602035(protocol: Scheme; host: string; base: string;
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

proc validate_AddPermission_602034(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602036 = path.getOrDefault("FunctionName")
  valid_602036 = validateParameter(valid_602036, JString, required = true,
                                 default = nil)
  if valid_602036 != nil:
    section.add "FunctionName", valid_602036
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to add permissions to a published version of the function.
  section = newJObject()
  var valid_602037 = query.getOrDefault("Qualifier")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "Qualifier", valid_602037
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
  var valid_602038 = header.getOrDefault("X-Amz-Signature")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-Signature", valid_602038
  var valid_602039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-Content-Sha256", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-Date")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-Date", valid_602040
  var valid_602041 = header.getOrDefault("X-Amz-Credential")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Credential", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-Security-Token")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-Security-Token", valid_602042
  var valid_602043 = header.getOrDefault("X-Amz-Algorithm")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "X-Amz-Algorithm", valid_602043
  var valid_602044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "X-Amz-SignedHeaders", valid_602044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602046: Call_AddPermission_602033; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Grants an AWS service or another account permission to use a function. You can apply the policy at the function level, or specify a qualifier to restrict access to a single version or alias. If you use a qualifier, the invoker must use the full Amazon Resource Name (ARN) of that version or alias to invoke the function.</p> <p>To grant permission to another account, specify the account ID as the <code>Principal</code>. For AWS services, the principal is a domain-style identifier defined by the service, like <code>s3.amazonaws.com</code> or <code>sns.amazonaws.com</code>. For AWS services, you can also specify the ARN or owning account of the associated resource as the <code>SourceArn</code> or <code>SourceAccount</code>. If you grant permission to a service principal without specifying the source, other accounts could potentially configure resources in their account to invoke your Lambda function.</p> <p>This action adds a statement to a resource-based permissions policy for the function. For more information about function policies, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">Lambda Function Policies</a>. </p>
  ## 
  let valid = call_602046.validator(path, query, header, formData, body)
  let scheme = call_602046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602046.url(scheme.get, call_602046.host, call_602046.base,
                         call_602046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602046, url, valid)

proc call*(call_602047: Call_AddPermission_602033; FunctionName: string;
          body: JsonNode; Qualifier: string = ""): Recallable =
  ## addPermission
  ## <p>Grants an AWS service or another account permission to use a function. You can apply the policy at the function level, or specify a qualifier to restrict access to a single version or alias. If you use a qualifier, the invoker must use the full Amazon Resource Name (ARN) of that version or alias to invoke the function.</p> <p>To grant permission to another account, specify the account ID as the <code>Principal</code>. For AWS services, the principal is a domain-style identifier defined by the service, like <code>s3.amazonaws.com</code> or <code>sns.amazonaws.com</code>. For AWS services, you can also specify the ARN or owning account of the associated resource as the <code>SourceArn</code> or <code>SourceAccount</code>. If you grant permission to a service principal without specifying the source, other accounts could potentially configure resources in their account to invoke your Lambda function.</p> <p>This action adds a statement to a resource-based permissions policy for the function. For more information about function policies, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">Lambda Function Policies</a>. </p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to add permissions to a published version of the function.
  ##   body: JObject (required)
  var path_602048 = newJObject()
  var query_602049 = newJObject()
  var body_602050 = newJObject()
  add(path_602048, "FunctionName", newJString(FunctionName))
  add(query_602049, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_602050 = body
  result = call_602047.call(path_602048, query_602049, nil, nil, body_602050)

var addPermission* = Call_AddPermission_602033(name: "addPermission",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/policy",
    validator: validate_AddPermission_602034, base: "/", url: url_AddPermission_602035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPolicy_602017 = ref object of OpenApiRestCall_601389
proc url_GetPolicy_602019(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetPolicy_602018(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602020 = path.getOrDefault("FunctionName")
  valid_602020 = validateParameter(valid_602020, JString, required = true,
                                 default = nil)
  if valid_602020 != nil:
    section.add "FunctionName", valid_602020
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to get the policy for that resource.
  section = newJObject()
  var valid_602021 = query.getOrDefault("Qualifier")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "Qualifier", valid_602021
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
  var valid_602022 = header.getOrDefault("X-Amz-Signature")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-Signature", valid_602022
  var valid_602023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-Content-Sha256", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-Date")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Date", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Credential")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Credential", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-Security-Token")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Security-Token", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-Algorithm")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-Algorithm", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-SignedHeaders", valid_602028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602029: Call_GetPolicy_602017; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">resource-based IAM policy</a> for a function, version, or alias.
  ## 
  let valid = call_602029.validator(path, query, header, formData, body)
  let scheme = call_602029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602029.url(scheme.get, call_602029.host, call_602029.base,
                         call_602029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602029, url, valid)

proc call*(call_602030: Call_GetPolicy_602017; FunctionName: string;
          Qualifier: string = ""): Recallable =
  ## getPolicy
  ## Returns the <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">resource-based IAM policy</a> for a function, version, or alias.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to get the policy for that resource.
  var path_602031 = newJObject()
  var query_602032 = newJObject()
  add(path_602031, "FunctionName", newJString(FunctionName))
  add(query_602032, "Qualifier", newJString(Qualifier))
  result = call_602030.call(path_602031, query_602032, nil, nil, nil)

var getPolicy* = Call_GetPolicy_602017(name: "getPolicy", meth: HttpMethod.HttpGet,
                                    host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/policy",
                                    validator: validate_GetPolicy_602018,
                                    base: "/", url: url_GetPolicy_602019,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAlias_602069 = ref object of OpenApiRestCall_601389
proc url_CreateAlias_602071(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAlias_602070(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602072 = path.getOrDefault("FunctionName")
  valid_602072 = validateParameter(valid_602072, JString, required = true,
                                 default = nil)
  if valid_602072 != nil:
    section.add "FunctionName", valid_602072
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
  var valid_602073 = header.getOrDefault("X-Amz-Signature")
  valid_602073 = validateParameter(valid_602073, JString, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "X-Amz-Signature", valid_602073
  var valid_602074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-Content-Sha256", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Date")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Date", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Credential")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Credential", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Security-Token")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Security-Token", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-Algorithm")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-Algorithm", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-SignedHeaders", valid_602079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602081: Call_CreateAlias_602069; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a> for a Lambda function version. Use aliases to provide clients with a function identifier that you can update to invoke a different version.</p> <p>You can also map an alias to split invocation requests between two versions. Use the <code>RoutingConfig</code> parameter to specify a second version and the percentage of invocation requests that it receives.</p>
  ## 
  let valid = call_602081.validator(path, query, header, formData, body)
  let scheme = call_602081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602081.url(scheme.get, call_602081.host, call_602081.base,
                         call_602081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602081, url, valid)

proc call*(call_602082: Call_CreateAlias_602069; FunctionName: string; body: JsonNode): Recallable =
  ## createAlias
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a> for a Lambda function version. Use aliases to provide clients with a function identifier that you can update to invoke a different version.</p> <p>You can also map an alias to split invocation requests between two versions. Use the <code>RoutingConfig</code> parameter to specify a second version and the percentage of invocation requests that it receives.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_602083 = newJObject()
  var body_602084 = newJObject()
  add(path_602083, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_602084 = body
  result = call_602082.call(path_602083, nil, nil, nil, body_602084)

var createAlias* = Call_CreateAlias_602069(name: "createAlias",
                                        meth: HttpMethod.HttpPost,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases",
                                        validator: validate_CreateAlias_602070,
                                        base: "/", url: url_CreateAlias_602071,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAliases_602051 = ref object of OpenApiRestCall_601389
proc url_ListAliases_602053(protocol: Scheme; host: string; base: string;
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

proc validate_ListAliases_602052(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602054 = path.getOrDefault("FunctionName")
  valid_602054 = validateParameter(valid_602054, JString, required = true,
                                 default = nil)
  if valid_602054 != nil:
    section.add "FunctionName", valid_602054
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   FunctionVersion: JString
  ##                  : Specify a function version to only list aliases that invoke that version.
  ##   MaxItems: JInt
  ##           : Limit the number of aliases returned.
  section = newJObject()
  var valid_602055 = query.getOrDefault("Marker")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "Marker", valid_602055
  var valid_602056 = query.getOrDefault("FunctionVersion")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "FunctionVersion", valid_602056
  var valid_602057 = query.getOrDefault("MaxItems")
  valid_602057 = validateParameter(valid_602057, JInt, required = false, default = nil)
  if valid_602057 != nil:
    section.add "MaxItems", valid_602057
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
  var valid_602058 = header.getOrDefault("X-Amz-Signature")
  valid_602058 = validateParameter(valid_602058, JString, required = false,
                                 default = nil)
  if valid_602058 != nil:
    section.add "X-Amz-Signature", valid_602058
  var valid_602059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602059 = validateParameter(valid_602059, JString, required = false,
                                 default = nil)
  if valid_602059 != nil:
    section.add "X-Amz-Content-Sha256", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-Date")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-Date", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Credential")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Credential", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Security-Token")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Security-Token", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-Algorithm")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-Algorithm", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-SignedHeaders", valid_602064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602065: Call_ListAliases_602051; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">aliases</a> for a Lambda function.
  ## 
  let valid = call_602065.validator(path, query, header, formData, body)
  let scheme = call_602065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602065.url(scheme.get, call_602065.host, call_602065.base,
                         call_602065.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602065, url, valid)

proc call*(call_602066: Call_ListAliases_602051; FunctionName: string;
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
  var path_602067 = newJObject()
  var query_602068 = newJObject()
  add(query_602068, "Marker", newJString(Marker))
  add(query_602068, "FunctionVersion", newJString(FunctionVersion))
  add(path_602067, "FunctionName", newJString(FunctionName))
  add(query_602068, "MaxItems", newJInt(MaxItems))
  result = call_602066.call(path_602067, query_602068, nil, nil, nil)

var listAliases* = Call_ListAliases_602051(name: "listAliases",
                                        meth: HttpMethod.HttpGet,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases",
                                        validator: validate_ListAliases_602052,
                                        base: "/", url: url_ListAliases_602053,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEventSourceMapping_602102 = ref object of OpenApiRestCall_601389
proc url_CreateEventSourceMapping_602104(protocol: Scheme; host: string;
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

proc validate_CreateEventSourceMapping_602103(path: JsonNode; query: JsonNode;
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
  var valid_602105 = header.getOrDefault("X-Amz-Signature")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Signature", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Content-Sha256", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Date")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Date", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-Credential")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Credential", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Security-Token")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Security-Token", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Algorithm")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Algorithm", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-SignedHeaders", valid_602111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602113: Call_CreateEventSourceMapping_602102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a mapping between an event source and an AWS Lambda function. Lambda reads items from the event source and triggers the function.</p> <p>For details about each event source type, see the following topics.</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html">Using AWS Lambda with Amazon DynamoDB</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html">Using AWS Lambda with Amazon Kinesis</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html">Using AWS Lambda with Amazon SQS</a> </p> </li> </ul> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> </ul>
  ## 
  let valid = call_602113.validator(path, query, header, formData, body)
  let scheme = call_602113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602113.url(scheme.get, call_602113.host, call_602113.base,
                         call_602113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602113, url, valid)

proc call*(call_602114: Call_CreateEventSourceMapping_602102; body: JsonNode): Recallable =
  ## createEventSourceMapping
  ## <p>Creates a mapping between an event source and an AWS Lambda function. Lambda reads items from the event source and triggers the function.</p> <p>For details about each event source type, see the following topics.</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html">Using AWS Lambda with Amazon DynamoDB</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html">Using AWS Lambda with Amazon Kinesis</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html">Using AWS Lambda with Amazon SQS</a> </p> </li> </ul> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> </ul>
  ##   body: JObject (required)
  var body_602115 = newJObject()
  if body != nil:
    body_602115 = body
  result = call_602114.call(nil, nil, nil, nil, body_602115)

var createEventSourceMapping* = Call_CreateEventSourceMapping_602102(
    name: "createEventSourceMapping", meth: HttpMethod.HttpPost,
    host: "lambda.amazonaws.com", route: "/2015-03-31/event-source-mappings/",
    validator: validate_CreateEventSourceMapping_602103, base: "/",
    url: url_CreateEventSourceMapping_602104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEventSourceMappings_602085 = ref object of OpenApiRestCall_601389
proc url_ListEventSourceMappings_602087(protocol: Scheme; host: string; base: string;
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

proc validate_ListEventSourceMappings_602086(path: JsonNode; query: JsonNode;
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
  var valid_602088 = query.getOrDefault("Marker")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "Marker", valid_602088
  var valid_602089 = query.getOrDefault("FunctionName")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "FunctionName", valid_602089
  var valid_602090 = query.getOrDefault("MaxItems")
  valid_602090 = validateParameter(valid_602090, JInt, required = false, default = nil)
  if valid_602090 != nil:
    section.add "MaxItems", valid_602090
  var valid_602091 = query.getOrDefault("EventSourceArn")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "EventSourceArn", valid_602091
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
  var valid_602092 = header.getOrDefault("X-Amz-Signature")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Signature", valid_602092
  var valid_602093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Content-Sha256", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Date")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Date", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Credential")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Credential", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-Security-Token")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-Security-Token", valid_602096
  var valid_602097 = header.getOrDefault("X-Amz-Algorithm")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "X-Amz-Algorithm", valid_602097
  var valid_602098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602098 = validateParameter(valid_602098, JString, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "X-Amz-SignedHeaders", valid_602098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602099: Call_ListEventSourceMappings_602085; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists event source mappings. Specify an <code>EventSourceArn</code> to only show event source mappings for a single event source.
  ## 
  let valid = call_602099.validator(path, query, header, formData, body)
  let scheme = call_602099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602099.url(scheme.get, call_602099.host, call_602099.base,
                         call_602099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602099, url, valid)

proc call*(call_602100: Call_ListEventSourceMappings_602085; Marker: string = "";
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
  var query_602101 = newJObject()
  add(query_602101, "Marker", newJString(Marker))
  add(query_602101, "FunctionName", newJString(FunctionName))
  add(query_602101, "MaxItems", newJInt(MaxItems))
  add(query_602101, "EventSourceArn", newJString(EventSourceArn))
  result = call_602100.call(nil, query_602101, nil, nil, nil)

var listEventSourceMappings* = Call_ListEventSourceMappings_602085(
    name: "listEventSourceMappings", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com", route: "/2015-03-31/event-source-mappings/",
    validator: validate_ListEventSourceMappings_602086, base: "/",
    url: url_ListEventSourceMappings_602087, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunction_602116 = ref object of OpenApiRestCall_601389
proc url_CreateFunction_602118(protocol: Scheme; host: string; base: string;
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

proc validate_CreateFunction_602117(path: JsonNode; query: JsonNode;
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
  var valid_602119 = header.getOrDefault("X-Amz-Signature")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "X-Amz-Signature", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Content-Sha256", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Date")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Date", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Credential")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Credential", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Security-Token")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Security-Token", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Algorithm")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Algorithm", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-SignedHeaders", valid_602125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602127: Call_CreateFunction_602116; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Lambda function. To create a function, you need a <a href="https://docs.aws.amazon.com/lambda/latest/dg/deployment-package-v2.html">deployment package</a> and an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-permission-model.html#lambda-intro-execution-role">execution role</a>. The deployment package contains your function code. The execution role grants the function permission to use AWS services, such as Amazon CloudWatch Logs for log streaming and AWS X-Ray for request tracing.</p> <p>When you create a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute or so. During this time, you can't invoke or modify the function. The <code>State</code>, <code>StateReason</code>, and <code>StateReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the function is ready to invoke. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Function States</a>.</p> <p>A function has an unpublished version, and can have published versions and aliases. The unpublished version changes when you update your function's code and configuration. A published version is a snapshot of your function code and configuration that can't be changed. An alias is a named resource that maps to a version, and can be changed to map to a different version. Use the <code>Publish</code> parameter to create version <code>1</code> of your function from its initial configuration.</p> <p>The other parameters let you configure version-specific and function-level settings. You can modify version-specific settings later with <a>UpdateFunctionConfiguration</a>. Function-level settings apply to both the unpublished and published versions of the function, and include tags (<a>TagResource</a>) and per-function concurrency limits (<a>PutFunctionConcurrency</a>).</p> <p>If another account or an AWS service invokes your function, use <a>AddPermission</a> to grant permission by creating a resource-based IAM policy. You can grant permissions at the function level, on a version, or on an alias.</p> <p>To invoke your function directly, use <a>Invoke</a>. To invoke your function in response to events in other AWS services, create an event source mapping (<a>CreateEventSourceMapping</a>), or configure a function trigger in the other service. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-invocation.html">Invoking Functions</a>.</p>
  ## 
  let valid = call_602127.validator(path, query, header, formData, body)
  let scheme = call_602127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602127.url(scheme.get, call_602127.host, call_602127.base,
                         call_602127.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602127, url, valid)

proc call*(call_602128: Call_CreateFunction_602116; body: JsonNode): Recallable =
  ## createFunction
  ## <p>Creates a Lambda function. To create a function, you need a <a href="https://docs.aws.amazon.com/lambda/latest/dg/deployment-package-v2.html">deployment package</a> and an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-permission-model.html#lambda-intro-execution-role">execution role</a>. The deployment package contains your function code. The execution role grants the function permission to use AWS services, such as Amazon CloudWatch Logs for log streaming and AWS X-Ray for request tracing.</p> <p>When you create a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute or so. During this time, you can't invoke or modify the function. The <code>State</code>, <code>StateReason</code>, and <code>StateReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the function is ready to invoke. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Function States</a>.</p> <p>A function has an unpublished version, and can have published versions and aliases. The unpublished version changes when you update your function's code and configuration. A published version is a snapshot of your function code and configuration that can't be changed. An alias is a named resource that maps to a version, and can be changed to map to a different version. Use the <code>Publish</code> parameter to create version <code>1</code> of your function from its initial configuration.</p> <p>The other parameters let you configure version-specific and function-level settings. You can modify version-specific settings later with <a>UpdateFunctionConfiguration</a>. Function-level settings apply to both the unpublished and published versions of the function, and include tags (<a>TagResource</a>) and per-function concurrency limits (<a>PutFunctionConcurrency</a>).</p> <p>If another account or an AWS service invokes your function, use <a>AddPermission</a> to grant permission by creating a resource-based IAM policy. You can grant permissions at the function level, on a version, or on an alias.</p> <p>To invoke your function directly, use <a>Invoke</a>. To invoke your function in response to events in other AWS services, create an event source mapping (<a>CreateEventSourceMapping</a>), or configure a function trigger in the other service. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-invocation.html">Invoking Functions</a>.</p>
  ##   body: JObject (required)
  var body_602129 = newJObject()
  if body != nil:
    body_602129 = body
  result = call_602128.call(nil, nil, nil, nil, body_602129)

var createFunction* = Call_CreateFunction_602116(name: "createFunction",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions", validator: validate_CreateFunction_602117,
    base: "/", url: url_CreateFunction_602118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAlias_602145 = ref object of OpenApiRestCall_601389
proc url_UpdateAlias_602147(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAlias_602146(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602148 = path.getOrDefault("FunctionName")
  valid_602148 = validateParameter(valid_602148, JString, required = true,
                                 default = nil)
  if valid_602148 != nil:
    section.add "FunctionName", valid_602148
  var valid_602149 = path.getOrDefault("Name")
  valid_602149 = validateParameter(valid_602149, JString, required = true,
                                 default = nil)
  if valid_602149 != nil:
    section.add "Name", valid_602149
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
  var valid_602150 = header.getOrDefault("X-Amz-Signature")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-Signature", valid_602150
  var valid_602151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-Content-Sha256", valid_602151
  var valid_602152 = header.getOrDefault("X-Amz-Date")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-Date", valid_602152
  var valid_602153 = header.getOrDefault("X-Amz-Credential")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Credential", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Security-Token")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Security-Token", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-Algorithm")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Algorithm", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-SignedHeaders", valid_602156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602158: Call_UpdateAlias_602145; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the configuration of a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ## 
  let valid = call_602158.validator(path, query, header, formData, body)
  let scheme = call_602158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602158.url(scheme.get, call_602158.host, call_602158.base,
                         call_602158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602158, url, valid)

proc call*(call_602159: Call_UpdateAlias_602145; FunctionName: string; Name: string;
          body: JsonNode): Recallable =
  ## updateAlias
  ## Updates the configuration of a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Name: string (required)
  ##       : The name of the alias.
  ##   body: JObject (required)
  var path_602160 = newJObject()
  var body_602161 = newJObject()
  add(path_602160, "FunctionName", newJString(FunctionName))
  add(path_602160, "Name", newJString(Name))
  if body != nil:
    body_602161 = body
  result = call_602159.call(path_602160, nil, nil, nil, body_602161)

var updateAlias* = Call_UpdateAlias_602145(name: "updateAlias",
                                        meth: HttpMethod.HttpPut,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases/{Name}",
                                        validator: validate_UpdateAlias_602146,
                                        base: "/", url: url_UpdateAlias_602147,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAlias_602130 = ref object of OpenApiRestCall_601389
proc url_GetAlias_602132(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetAlias_602131(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602133 = path.getOrDefault("FunctionName")
  valid_602133 = validateParameter(valid_602133, JString, required = true,
                                 default = nil)
  if valid_602133 != nil:
    section.add "FunctionName", valid_602133
  var valid_602134 = path.getOrDefault("Name")
  valid_602134 = validateParameter(valid_602134, JString, required = true,
                                 default = nil)
  if valid_602134 != nil:
    section.add "Name", valid_602134
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
  var valid_602135 = header.getOrDefault("X-Amz-Signature")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-Signature", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Content-Sha256", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-Date")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Date", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-Credential")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Credential", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Security-Token")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Security-Token", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Algorithm")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Algorithm", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-SignedHeaders", valid_602141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602142: Call_GetAlias_602130; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns details about a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ## 
  let valid = call_602142.validator(path, query, header, formData, body)
  let scheme = call_602142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602142.url(scheme.get, call_602142.host, call_602142.base,
                         call_602142.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602142, url, valid)

proc call*(call_602143: Call_GetAlias_602130; FunctionName: string; Name: string): Recallable =
  ## getAlias
  ## Returns details about a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Name: string (required)
  ##       : The name of the alias.
  var path_602144 = newJObject()
  add(path_602144, "FunctionName", newJString(FunctionName))
  add(path_602144, "Name", newJString(Name))
  result = call_602143.call(path_602144, nil, nil, nil, nil)

var getAlias* = Call_GetAlias_602130(name: "getAlias", meth: HttpMethod.HttpGet,
                                  host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases/{Name}",
                                  validator: validate_GetAlias_602131, base: "/",
                                  url: url_GetAlias_602132,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAlias_602162 = ref object of OpenApiRestCall_601389
proc url_DeleteAlias_602164(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAlias_602163(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602165 = path.getOrDefault("FunctionName")
  valid_602165 = validateParameter(valid_602165, JString, required = true,
                                 default = nil)
  if valid_602165 != nil:
    section.add "FunctionName", valid_602165
  var valid_602166 = path.getOrDefault("Name")
  valid_602166 = validateParameter(valid_602166, JString, required = true,
                                 default = nil)
  if valid_602166 != nil:
    section.add "Name", valid_602166
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
  var valid_602167 = header.getOrDefault("X-Amz-Signature")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Signature", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-Content-Sha256", valid_602168
  var valid_602169 = header.getOrDefault("X-Amz-Date")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-Date", valid_602169
  var valid_602170 = header.getOrDefault("X-Amz-Credential")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "X-Amz-Credential", valid_602170
  var valid_602171 = header.getOrDefault("X-Amz-Security-Token")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "X-Amz-Security-Token", valid_602171
  var valid_602172 = header.getOrDefault("X-Amz-Algorithm")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "X-Amz-Algorithm", valid_602172
  var valid_602173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "X-Amz-SignedHeaders", valid_602173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602174: Call_DeleteAlias_602162; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ## 
  let valid = call_602174.validator(path, query, header, formData, body)
  let scheme = call_602174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602174.url(scheme.get, call_602174.host, call_602174.base,
                         call_602174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602174, url, valid)

proc call*(call_602175: Call_DeleteAlias_602162; FunctionName: string; Name: string): Recallable =
  ## deleteAlias
  ## Deletes a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Name: string (required)
  ##       : The name of the alias.
  var path_602176 = newJObject()
  add(path_602176, "FunctionName", newJString(FunctionName))
  add(path_602176, "Name", newJString(Name))
  result = call_602175.call(path_602176, nil, nil, nil, nil)

var deleteAlias* = Call_DeleteAlias_602162(name: "deleteAlias",
                                        meth: HttpMethod.HttpDelete,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases/{Name}",
                                        validator: validate_DeleteAlias_602163,
                                        base: "/", url: url_DeleteAlias_602164,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEventSourceMapping_602191 = ref object of OpenApiRestCall_601389
proc url_UpdateEventSourceMapping_602193(protocol: Scheme; host: string;
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

proc validate_UpdateEventSourceMapping_602192(path: JsonNode; query: JsonNode;
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
  var valid_602194 = path.getOrDefault("UUID")
  valid_602194 = validateParameter(valid_602194, JString, required = true,
                                 default = nil)
  if valid_602194 != nil:
    section.add "UUID", valid_602194
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
  var valid_602195 = header.getOrDefault("X-Amz-Signature")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Signature", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Content-Sha256", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Date")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Date", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Credential")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Credential", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-Security-Token")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Security-Token", valid_602199
  var valid_602200 = header.getOrDefault("X-Amz-Algorithm")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-Algorithm", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-SignedHeaders", valid_602201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602203: Call_UpdateEventSourceMapping_602191; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an event source mapping. You can change the function that AWS Lambda invokes, or pause invocation and resume later from the same location.</p> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> </ul>
  ## 
  let valid = call_602203.validator(path, query, header, formData, body)
  let scheme = call_602203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602203.url(scheme.get, call_602203.host, call_602203.base,
                         call_602203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602203, url, valid)

proc call*(call_602204: Call_UpdateEventSourceMapping_602191; UUID: string;
          body: JsonNode): Recallable =
  ## updateEventSourceMapping
  ## <p>Updates an event source mapping. You can change the function that AWS Lambda invokes, or pause invocation and resume later from the same location.</p> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> </ul>
  ##   UUID: string (required)
  ##       : The identifier of the event source mapping.
  ##   body: JObject (required)
  var path_602205 = newJObject()
  var body_602206 = newJObject()
  add(path_602205, "UUID", newJString(UUID))
  if body != nil:
    body_602206 = body
  result = call_602204.call(path_602205, nil, nil, nil, body_602206)

var updateEventSourceMapping* = Call_UpdateEventSourceMapping_602191(
    name: "updateEventSourceMapping", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/event-source-mappings/{UUID}",
    validator: validate_UpdateEventSourceMapping_602192, base: "/",
    url: url_UpdateEventSourceMapping_602193, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventSourceMapping_602177 = ref object of OpenApiRestCall_601389
proc url_GetEventSourceMapping_602179(protocol: Scheme; host: string; base: string;
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

proc validate_GetEventSourceMapping_602178(path: JsonNode; query: JsonNode;
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
  var valid_602180 = path.getOrDefault("UUID")
  valid_602180 = validateParameter(valid_602180, JString, required = true,
                                 default = nil)
  if valid_602180 != nil:
    section.add "UUID", valid_602180
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
  var valid_602181 = header.getOrDefault("X-Amz-Signature")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Signature", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Content-Sha256", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-Date")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Date", valid_602183
  var valid_602184 = header.getOrDefault("X-Amz-Credential")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-Credential", valid_602184
  var valid_602185 = header.getOrDefault("X-Amz-Security-Token")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "X-Amz-Security-Token", valid_602185
  var valid_602186 = header.getOrDefault("X-Amz-Algorithm")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "X-Amz-Algorithm", valid_602186
  var valid_602187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602187 = validateParameter(valid_602187, JString, required = false,
                                 default = nil)
  if valid_602187 != nil:
    section.add "X-Amz-SignedHeaders", valid_602187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602188: Call_GetEventSourceMapping_602177; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns details about an event source mapping. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.
  ## 
  let valid = call_602188.validator(path, query, header, formData, body)
  let scheme = call_602188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602188.url(scheme.get, call_602188.host, call_602188.base,
                         call_602188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602188, url, valid)

proc call*(call_602189: Call_GetEventSourceMapping_602177; UUID: string): Recallable =
  ## getEventSourceMapping
  ## Returns details about an event source mapping. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.
  ##   UUID: string (required)
  ##       : The identifier of the event source mapping.
  var path_602190 = newJObject()
  add(path_602190, "UUID", newJString(UUID))
  result = call_602189.call(path_602190, nil, nil, nil, nil)

var getEventSourceMapping* = Call_GetEventSourceMapping_602177(
    name: "getEventSourceMapping", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/event-source-mappings/{UUID}",
    validator: validate_GetEventSourceMapping_602178, base: "/",
    url: url_GetEventSourceMapping_602179, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventSourceMapping_602207 = ref object of OpenApiRestCall_601389
proc url_DeleteEventSourceMapping_602209(protocol: Scheme; host: string;
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

proc validate_DeleteEventSourceMapping_602208(path: JsonNode; query: JsonNode;
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
  var valid_602210 = path.getOrDefault("UUID")
  valid_602210 = validateParameter(valid_602210, JString, required = true,
                                 default = nil)
  if valid_602210 != nil:
    section.add "UUID", valid_602210
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
  var valid_602211 = header.getOrDefault("X-Amz-Signature")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "X-Amz-Signature", valid_602211
  var valid_602212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "X-Amz-Content-Sha256", valid_602212
  var valid_602213 = header.getOrDefault("X-Amz-Date")
  valid_602213 = validateParameter(valid_602213, JString, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "X-Amz-Date", valid_602213
  var valid_602214 = header.getOrDefault("X-Amz-Credential")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "X-Amz-Credential", valid_602214
  var valid_602215 = header.getOrDefault("X-Amz-Security-Token")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-Security-Token", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-Algorithm")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-Algorithm", valid_602216
  var valid_602217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "X-Amz-SignedHeaders", valid_602217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602218: Call_DeleteEventSourceMapping_602207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-invocation-modes.html">event source mapping</a>. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.</p> <p>When you delete an event source mapping, it enters a <code>Deleting</code> state and might not be completely deleted for several seconds.</p>
  ## 
  let valid = call_602218.validator(path, query, header, formData, body)
  let scheme = call_602218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602218.url(scheme.get, call_602218.host, call_602218.base,
                         call_602218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602218, url, valid)

proc call*(call_602219: Call_DeleteEventSourceMapping_602207; UUID: string): Recallable =
  ## deleteEventSourceMapping
  ## <p>Deletes an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-invocation-modes.html">event source mapping</a>. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.</p> <p>When you delete an event source mapping, it enters a <code>Deleting</code> state and might not be completely deleted for several seconds.</p>
  ##   UUID: string (required)
  ##       : The identifier of the event source mapping.
  var path_602220 = newJObject()
  add(path_602220, "UUID", newJString(UUID))
  result = call_602219.call(path_602220, nil, nil, nil, nil)

var deleteEventSourceMapping* = Call_DeleteEventSourceMapping_602207(
    name: "deleteEventSourceMapping", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/event-source-mappings/{UUID}",
    validator: validate_DeleteEventSourceMapping_602208, base: "/",
    url: url_DeleteEventSourceMapping_602209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunction_602221 = ref object of OpenApiRestCall_601389
proc url_GetFunction_602223(protocol: Scheme; host: string; base: string;
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

proc validate_GetFunction_602222(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602224 = path.getOrDefault("FunctionName")
  valid_602224 = validateParameter(valid_602224, JString, required = true,
                                 default = nil)
  if valid_602224 != nil:
    section.add "FunctionName", valid_602224
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to get details about a published version of the function.
  section = newJObject()
  var valid_602225 = query.getOrDefault("Qualifier")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "Qualifier", valid_602225
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
  var valid_602226 = header.getOrDefault("X-Amz-Signature")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-Signature", valid_602226
  var valid_602227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-Content-Sha256", valid_602227
  var valid_602228 = header.getOrDefault("X-Amz-Date")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "X-Amz-Date", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-Credential")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-Credential", valid_602229
  var valid_602230 = header.getOrDefault("X-Amz-Security-Token")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Security-Token", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-Algorithm")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-Algorithm", valid_602231
  var valid_602232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "X-Amz-SignedHeaders", valid_602232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602233: Call_GetFunction_602221; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the function or function version, with a link to download the deployment package that's valid for 10 minutes. If you specify a function version, only details that are specific to that version are returned.
  ## 
  let valid = call_602233.validator(path, query, header, formData, body)
  let scheme = call_602233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602233.url(scheme.get, call_602233.host, call_602233.base,
                         call_602233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602233, url, valid)

proc call*(call_602234: Call_GetFunction_602221; FunctionName: string;
          Qualifier: string = ""): Recallable =
  ## getFunction
  ## Returns information about the function or function version, with a link to download the deployment package that's valid for 10 minutes. If you specify a function version, only details that are specific to that version are returned.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to get details about a published version of the function.
  var path_602235 = newJObject()
  var query_602236 = newJObject()
  add(path_602235, "FunctionName", newJString(FunctionName))
  add(query_602236, "Qualifier", newJString(Qualifier))
  result = call_602234.call(path_602235, query_602236, nil, nil, nil)

var getFunction* = Call_GetFunction_602221(name: "getFunction",
                                        meth: HttpMethod.HttpGet,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}",
                                        validator: validate_GetFunction_602222,
                                        base: "/", url: url_GetFunction_602223,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunction_602237 = ref object of OpenApiRestCall_601389
proc url_DeleteFunction_602239(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFunction_602238(path: JsonNode; query: JsonNode;
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
  var valid_602240 = path.getOrDefault("FunctionName")
  valid_602240 = validateParameter(valid_602240, JString, required = true,
                                 default = nil)
  if valid_602240 != nil:
    section.add "FunctionName", valid_602240
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version to delete. You can't delete a version that's referenced by an alias.
  section = newJObject()
  var valid_602241 = query.getOrDefault("Qualifier")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "Qualifier", valid_602241
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
  var valid_602242 = header.getOrDefault("X-Amz-Signature")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "X-Amz-Signature", valid_602242
  var valid_602243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "X-Amz-Content-Sha256", valid_602243
  var valid_602244 = header.getOrDefault("X-Amz-Date")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-Date", valid_602244
  var valid_602245 = header.getOrDefault("X-Amz-Credential")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Credential", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-Security-Token")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-Security-Token", valid_602246
  var valid_602247 = header.getOrDefault("X-Amz-Algorithm")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "X-Amz-Algorithm", valid_602247
  var valid_602248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602248 = validateParameter(valid_602248, JString, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "X-Amz-SignedHeaders", valid_602248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602249: Call_DeleteFunction_602237; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a Lambda function. To delete a specific function version, use the <code>Qualifier</code> parameter. Otherwise, all versions and aliases are deleted.</p> <p>To delete Lambda event source mappings that invoke a function, use <a>DeleteEventSourceMapping</a>. For AWS services and resources that invoke your function directly, delete the trigger in the service where you originally configured it.</p>
  ## 
  let valid = call_602249.validator(path, query, header, formData, body)
  let scheme = call_602249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602249.url(scheme.get, call_602249.host, call_602249.base,
                         call_602249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602249, url, valid)

proc call*(call_602250: Call_DeleteFunction_602237; FunctionName: string;
          Qualifier: string = ""): Recallable =
  ## deleteFunction
  ## <p>Deletes a Lambda function. To delete a specific function version, use the <code>Qualifier</code> parameter. Otherwise, all versions and aliases are deleted.</p> <p>To delete Lambda event source mappings that invoke a function, use <a>DeleteEventSourceMapping</a>. For AWS services and resources that invoke your function directly, delete the trigger in the service where you originally configured it.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function or version.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:1</code> (with version).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version to delete. You can't delete a version that's referenced by an alias.
  var path_602251 = newJObject()
  var query_602252 = newJObject()
  add(path_602251, "FunctionName", newJString(FunctionName))
  add(query_602252, "Qualifier", newJString(Qualifier))
  result = call_602250.call(path_602251, query_602252, nil, nil, nil)

var deleteFunction* = Call_DeleteFunction_602237(name: "deleteFunction",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}",
    validator: validate_DeleteFunction_602238, base: "/", url: url_DeleteFunction_602239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutFunctionConcurrency_602253 = ref object of OpenApiRestCall_601389
proc url_PutFunctionConcurrency_602255(protocol: Scheme; host: string; base: string;
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

proc validate_PutFunctionConcurrency_602254(path: JsonNode; query: JsonNode;
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
  var valid_602256 = path.getOrDefault("FunctionName")
  valid_602256 = validateParameter(valid_602256, JString, required = true,
                                 default = nil)
  if valid_602256 != nil:
    section.add "FunctionName", valid_602256
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
  var valid_602257 = header.getOrDefault("X-Amz-Signature")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "X-Amz-Signature", valid_602257
  var valid_602258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602258 = validateParameter(valid_602258, JString, required = false,
                                 default = nil)
  if valid_602258 != nil:
    section.add "X-Amz-Content-Sha256", valid_602258
  var valid_602259 = header.getOrDefault("X-Amz-Date")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "X-Amz-Date", valid_602259
  var valid_602260 = header.getOrDefault("X-Amz-Credential")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "X-Amz-Credential", valid_602260
  var valid_602261 = header.getOrDefault("X-Amz-Security-Token")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "X-Amz-Security-Token", valid_602261
  var valid_602262 = header.getOrDefault("X-Amz-Algorithm")
  valid_602262 = validateParameter(valid_602262, JString, required = false,
                                 default = nil)
  if valid_602262 != nil:
    section.add "X-Amz-Algorithm", valid_602262
  var valid_602263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602263 = validateParameter(valid_602263, JString, required = false,
                                 default = nil)
  if valid_602263 != nil:
    section.add "X-Amz-SignedHeaders", valid_602263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602265: Call_PutFunctionConcurrency_602253; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the maximum number of simultaneous executions for a function, and reserves capacity for that concurrency level.</p> <p>Concurrency settings apply to the function as a whole, including all published versions and the unpublished version. Reserving concurrency both ensures that your function has capacity to process the specified number of events simultaneously, and prevents it from scaling beyond that level. Use <a>GetFunction</a> to see the current setting for a function.</p> <p>Use <a>GetAccountSettings</a> to see your Regional concurrency limit. You can reserve concurrency for as many functions as you like, as long as you leave at least 100 simultaneous executions unreserved for functions that aren't configured with a per-function limit. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/concurrent-executions.html">Managing Concurrency</a>.</p>
  ## 
  let valid = call_602265.validator(path, query, header, formData, body)
  let scheme = call_602265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602265.url(scheme.get, call_602265.host, call_602265.base,
                         call_602265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602265, url, valid)

proc call*(call_602266: Call_PutFunctionConcurrency_602253; FunctionName: string;
          body: JsonNode): Recallable =
  ## putFunctionConcurrency
  ## <p>Sets the maximum number of simultaneous executions for a function, and reserves capacity for that concurrency level.</p> <p>Concurrency settings apply to the function as a whole, including all published versions and the unpublished version. Reserving concurrency both ensures that your function has capacity to process the specified number of events simultaneously, and prevents it from scaling beyond that level. Use <a>GetFunction</a> to see the current setting for a function.</p> <p>Use <a>GetAccountSettings</a> to see your Regional concurrency limit. You can reserve concurrency for as many functions as you like, as long as you leave at least 100 simultaneous executions unreserved for functions that aren't configured with a per-function limit. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/concurrent-executions.html">Managing Concurrency</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_602267 = newJObject()
  var body_602268 = newJObject()
  add(path_602267, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_602268 = body
  result = call_602266.call(path_602267, nil, nil, nil, body_602268)

var putFunctionConcurrency* = Call_PutFunctionConcurrency_602253(
    name: "putFunctionConcurrency", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2017-10-31/functions/{FunctionName}/concurrency",
    validator: validate_PutFunctionConcurrency_602254, base: "/",
    url: url_PutFunctionConcurrency_602255, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunctionConcurrency_602269 = ref object of OpenApiRestCall_601389
proc url_DeleteFunctionConcurrency_602271(protocol: Scheme; host: string;
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

proc validate_DeleteFunctionConcurrency_602270(path: JsonNode; query: JsonNode;
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
  var valid_602272 = path.getOrDefault("FunctionName")
  valid_602272 = validateParameter(valid_602272, JString, required = true,
                                 default = nil)
  if valid_602272 != nil:
    section.add "FunctionName", valid_602272
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
  var valid_602273 = header.getOrDefault("X-Amz-Signature")
  valid_602273 = validateParameter(valid_602273, JString, required = false,
                                 default = nil)
  if valid_602273 != nil:
    section.add "X-Amz-Signature", valid_602273
  var valid_602274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602274 = validateParameter(valid_602274, JString, required = false,
                                 default = nil)
  if valid_602274 != nil:
    section.add "X-Amz-Content-Sha256", valid_602274
  var valid_602275 = header.getOrDefault("X-Amz-Date")
  valid_602275 = validateParameter(valid_602275, JString, required = false,
                                 default = nil)
  if valid_602275 != nil:
    section.add "X-Amz-Date", valid_602275
  var valid_602276 = header.getOrDefault("X-Amz-Credential")
  valid_602276 = validateParameter(valid_602276, JString, required = false,
                                 default = nil)
  if valid_602276 != nil:
    section.add "X-Amz-Credential", valid_602276
  var valid_602277 = header.getOrDefault("X-Amz-Security-Token")
  valid_602277 = validateParameter(valid_602277, JString, required = false,
                                 default = nil)
  if valid_602277 != nil:
    section.add "X-Amz-Security-Token", valid_602277
  var valid_602278 = header.getOrDefault("X-Amz-Algorithm")
  valid_602278 = validateParameter(valid_602278, JString, required = false,
                                 default = nil)
  if valid_602278 != nil:
    section.add "X-Amz-Algorithm", valid_602278
  var valid_602279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602279 = validateParameter(valid_602279, JString, required = false,
                                 default = nil)
  if valid_602279 != nil:
    section.add "X-Amz-SignedHeaders", valid_602279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602280: Call_DeleteFunctionConcurrency_602269; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a concurrent execution limit from a function.
  ## 
  let valid = call_602280.validator(path, query, header, formData, body)
  let scheme = call_602280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602280.url(scheme.get, call_602280.host, call_602280.base,
                         call_602280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602280, url, valid)

proc call*(call_602281: Call_DeleteFunctionConcurrency_602269; FunctionName: string): Recallable =
  ## deleteFunctionConcurrency
  ## Removes a concurrent execution limit from a function.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  var path_602282 = newJObject()
  add(path_602282, "FunctionName", newJString(FunctionName))
  result = call_602281.call(path_602282, nil, nil, nil, nil)

var deleteFunctionConcurrency* = Call_DeleteFunctionConcurrency_602269(
    name: "deleteFunctionConcurrency", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com",
    route: "/2017-10-31/functions/{FunctionName}/concurrency",
    validator: validate_DeleteFunctionConcurrency_602270, base: "/",
    url: url_DeleteFunctionConcurrency_602271,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutFunctionEventInvokeConfig_602299 = ref object of OpenApiRestCall_601389
proc url_PutFunctionEventInvokeConfig_602301(protocol: Scheme; host: string;
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

proc validate_PutFunctionEventInvokeConfig_602300(path: JsonNode; query: JsonNode;
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
  var valid_602302 = path.getOrDefault("FunctionName")
  valid_602302 = validateParameter(valid_602302, JString, required = true,
                                 default = nil)
  if valid_602302 != nil:
    section.add "FunctionName", valid_602302
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : A version number or alias name.
  section = newJObject()
  var valid_602303 = query.getOrDefault("Qualifier")
  valid_602303 = validateParameter(valid_602303, JString, required = false,
                                 default = nil)
  if valid_602303 != nil:
    section.add "Qualifier", valid_602303
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
  var valid_602304 = header.getOrDefault("X-Amz-Signature")
  valid_602304 = validateParameter(valid_602304, JString, required = false,
                                 default = nil)
  if valid_602304 != nil:
    section.add "X-Amz-Signature", valid_602304
  var valid_602305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602305 = validateParameter(valid_602305, JString, required = false,
                                 default = nil)
  if valid_602305 != nil:
    section.add "X-Amz-Content-Sha256", valid_602305
  var valid_602306 = header.getOrDefault("X-Amz-Date")
  valid_602306 = validateParameter(valid_602306, JString, required = false,
                                 default = nil)
  if valid_602306 != nil:
    section.add "X-Amz-Date", valid_602306
  var valid_602307 = header.getOrDefault("X-Amz-Credential")
  valid_602307 = validateParameter(valid_602307, JString, required = false,
                                 default = nil)
  if valid_602307 != nil:
    section.add "X-Amz-Credential", valid_602307
  var valid_602308 = header.getOrDefault("X-Amz-Security-Token")
  valid_602308 = validateParameter(valid_602308, JString, required = false,
                                 default = nil)
  if valid_602308 != nil:
    section.add "X-Amz-Security-Token", valid_602308
  var valid_602309 = header.getOrDefault("X-Amz-Algorithm")
  valid_602309 = validateParameter(valid_602309, JString, required = false,
                                 default = nil)
  if valid_602309 != nil:
    section.add "X-Amz-Algorithm", valid_602309
  var valid_602310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602310 = validateParameter(valid_602310, JString, required = false,
                                 default = nil)
  if valid_602310 != nil:
    section.add "X-Amz-SignedHeaders", valid_602310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602312: Call_PutFunctionEventInvokeConfig_602299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configures options for <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a> on a function, version, or alias.</p> <p>By default, Lambda retries an asynchronous invocation twice if the function returns an error. It retains events in a queue for up to six hours. When an event fails all processing attempts or stays in the asynchronous invocation queue for too long, Lambda discards it. To retain discarded events, configure a dead-letter queue with <a>UpdateFunctionConfiguration</a>.</p>
  ## 
  let valid = call_602312.validator(path, query, header, formData, body)
  let scheme = call_602312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602312.url(scheme.get, call_602312.host, call_602312.base,
                         call_602312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602312, url, valid)

proc call*(call_602313: Call_PutFunctionEventInvokeConfig_602299;
          FunctionName: string; body: JsonNode; Qualifier: string = ""): Recallable =
  ## putFunctionEventInvokeConfig
  ## <p>Configures options for <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a> on a function, version, or alias.</p> <p>By default, Lambda retries an asynchronous invocation twice if the function returns an error. It retains events in a queue for up to six hours. When an event fails all processing attempts or stays in the asynchronous invocation queue for too long, Lambda discards it. To retain discarded events, configure a dead-letter queue with <a>UpdateFunctionConfiguration</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : A version number or alias name.
  ##   body: JObject (required)
  var path_602314 = newJObject()
  var query_602315 = newJObject()
  var body_602316 = newJObject()
  add(path_602314, "FunctionName", newJString(FunctionName))
  add(query_602315, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_602316 = body
  result = call_602313.call(path_602314, query_602315, nil, nil, body_602316)

var putFunctionEventInvokeConfig* = Call_PutFunctionEventInvokeConfig_602299(
    name: "putFunctionEventInvokeConfig", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config",
    validator: validate_PutFunctionEventInvokeConfig_602300, base: "/",
    url: url_PutFunctionEventInvokeConfig_602301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionEventInvokeConfig_602317 = ref object of OpenApiRestCall_601389
proc url_UpdateFunctionEventInvokeConfig_602319(protocol: Scheme; host: string;
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

proc validate_UpdateFunctionEventInvokeConfig_602318(path: JsonNode;
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
  var valid_602320 = path.getOrDefault("FunctionName")
  valid_602320 = validateParameter(valid_602320, JString, required = true,
                                 default = nil)
  if valid_602320 != nil:
    section.add "FunctionName", valid_602320
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : A version number or alias name.
  section = newJObject()
  var valid_602321 = query.getOrDefault("Qualifier")
  valid_602321 = validateParameter(valid_602321, JString, required = false,
                                 default = nil)
  if valid_602321 != nil:
    section.add "Qualifier", valid_602321
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
  var valid_602322 = header.getOrDefault("X-Amz-Signature")
  valid_602322 = validateParameter(valid_602322, JString, required = false,
                                 default = nil)
  if valid_602322 != nil:
    section.add "X-Amz-Signature", valid_602322
  var valid_602323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602323 = validateParameter(valid_602323, JString, required = false,
                                 default = nil)
  if valid_602323 != nil:
    section.add "X-Amz-Content-Sha256", valid_602323
  var valid_602324 = header.getOrDefault("X-Amz-Date")
  valid_602324 = validateParameter(valid_602324, JString, required = false,
                                 default = nil)
  if valid_602324 != nil:
    section.add "X-Amz-Date", valid_602324
  var valid_602325 = header.getOrDefault("X-Amz-Credential")
  valid_602325 = validateParameter(valid_602325, JString, required = false,
                                 default = nil)
  if valid_602325 != nil:
    section.add "X-Amz-Credential", valid_602325
  var valid_602326 = header.getOrDefault("X-Amz-Security-Token")
  valid_602326 = validateParameter(valid_602326, JString, required = false,
                                 default = nil)
  if valid_602326 != nil:
    section.add "X-Amz-Security-Token", valid_602326
  var valid_602327 = header.getOrDefault("X-Amz-Algorithm")
  valid_602327 = validateParameter(valid_602327, JString, required = false,
                                 default = nil)
  if valid_602327 != nil:
    section.add "X-Amz-Algorithm", valid_602327
  var valid_602328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602328 = validateParameter(valid_602328, JString, required = false,
                                 default = nil)
  if valid_602328 != nil:
    section.add "X-Amz-SignedHeaders", valid_602328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602330: Call_UpdateFunctionEventInvokeConfig_602317;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Updates the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  let valid = call_602330.validator(path, query, header, formData, body)
  let scheme = call_602330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602330.url(scheme.get, call_602330.host, call_602330.base,
                         call_602330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602330, url, valid)

proc call*(call_602331: Call_UpdateFunctionEventInvokeConfig_602317;
          FunctionName: string; body: JsonNode; Qualifier: string = ""): Recallable =
  ## updateFunctionEventInvokeConfig
  ## <p>Updates the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : A version number or alias name.
  ##   body: JObject (required)
  var path_602332 = newJObject()
  var query_602333 = newJObject()
  var body_602334 = newJObject()
  add(path_602332, "FunctionName", newJString(FunctionName))
  add(query_602333, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_602334 = body
  result = call_602331.call(path_602332, query_602333, nil, nil, body_602334)

var updateFunctionEventInvokeConfig* = Call_UpdateFunctionEventInvokeConfig_602317(
    name: "updateFunctionEventInvokeConfig", meth: HttpMethod.HttpPost,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config",
    validator: validate_UpdateFunctionEventInvokeConfig_602318, base: "/",
    url: url_UpdateFunctionEventInvokeConfig_602319,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionEventInvokeConfig_602283 = ref object of OpenApiRestCall_601389
proc url_GetFunctionEventInvokeConfig_602285(protocol: Scheme; host: string;
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

proc validate_GetFunctionEventInvokeConfig_602284(path: JsonNode; query: JsonNode;
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
  var valid_602286 = path.getOrDefault("FunctionName")
  valid_602286 = validateParameter(valid_602286, JString, required = true,
                                 default = nil)
  if valid_602286 != nil:
    section.add "FunctionName", valid_602286
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : A version number or alias name.
  section = newJObject()
  var valid_602287 = query.getOrDefault("Qualifier")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "Qualifier", valid_602287
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
  var valid_602288 = header.getOrDefault("X-Amz-Signature")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "X-Amz-Signature", valid_602288
  var valid_602289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "X-Amz-Content-Sha256", valid_602289
  var valid_602290 = header.getOrDefault("X-Amz-Date")
  valid_602290 = validateParameter(valid_602290, JString, required = false,
                                 default = nil)
  if valid_602290 != nil:
    section.add "X-Amz-Date", valid_602290
  var valid_602291 = header.getOrDefault("X-Amz-Credential")
  valid_602291 = validateParameter(valid_602291, JString, required = false,
                                 default = nil)
  if valid_602291 != nil:
    section.add "X-Amz-Credential", valid_602291
  var valid_602292 = header.getOrDefault("X-Amz-Security-Token")
  valid_602292 = validateParameter(valid_602292, JString, required = false,
                                 default = nil)
  if valid_602292 != nil:
    section.add "X-Amz-Security-Token", valid_602292
  var valid_602293 = header.getOrDefault("X-Amz-Algorithm")
  valid_602293 = validateParameter(valid_602293, JString, required = false,
                                 default = nil)
  if valid_602293 != nil:
    section.add "X-Amz-Algorithm", valid_602293
  var valid_602294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602294 = validateParameter(valid_602294, JString, required = false,
                                 default = nil)
  if valid_602294 != nil:
    section.add "X-Amz-SignedHeaders", valid_602294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602295: Call_GetFunctionEventInvokeConfig_602283; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  let valid = call_602295.validator(path, query, header, formData, body)
  let scheme = call_602295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602295.url(scheme.get, call_602295.host, call_602295.base,
                         call_602295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602295, url, valid)

proc call*(call_602296: Call_GetFunctionEventInvokeConfig_602283;
          FunctionName: string; Qualifier: string = ""): Recallable =
  ## getFunctionEventInvokeConfig
  ## <p>Retrieves the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : A version number or alias name.
  var path_602297 = newJObject()
  var query_602298 = newJObject()
  add(path_602297, "FunctionName", newJString(FunctionName))
  add(query_602298, "Qualifier", newJString(Qualifier))
  result = call_602296.call(path_602297, query_602298, nil, nil, nil)

var getFunctionEventInvokeConfig* = Call_GetFunctionEventInvokeConfig_602283(
    name: "getFunctionEventInvokeConfig", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config",
    validator: validate_GetFunctionEventInvokeConfig_602284, base: "/",
    url: url_GetFunctionEventInvokeConfig_602285,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunctionEventInvokeConfig_602335 = ref object of OpenApiRestCall_601389
proc url_DeleteFunctionEventInvokeConfig_602337(protocol: Scheme; host: string;
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

proc validate_DeleteFunctionEventInvokeConfig_602336(path: JsonNode;
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
  var valid_602338 = path.getOrDefault("FunctionName")
  valid_602338 = validateParameter(valid_602338, JString, required = true,
                                 default = nil)
  if valid_602338 != nil:
    section.add "FunctionName", valid_602338
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : A version number or alias name.
  section = newJObject()
  var valid_602339 = query.getOrDefault("Qualifier")
  valid_602339 = validateParameter(valid_602339, JString, required = false,
                                 default = nil)
  if valid_602339 != nil:
    section.add "Qualifier", valid_602339
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
  var valid_602340 = header.getOrDefault("X-Amz-Signature")
  valid_602340 = validateParameter(valid_602340, JString, required = false,
                                 default = nil)
  if valid_602340 != nil:
    section.add "X-Amz-Signature", valid_602340
  var valid_602341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602341 = validateParameter(valid_602341, JString, required = false,
                                 default = nil)
  if valid_602341 != nil:
    section.add "X-Amz-Content-Sha256", valid_602341
  var valid_602342 = header.getOrDefault("X-Amz-Date")
  valid_602342 = validateParameter(valid_602342, JString, required = false,
                                 default = nil)
  if valid_602342 != nil:
    section.add "X-Amz-Date", valid_602342
  var valid_602343 = header.getOrDefault("X-Amz-Credential")
  valid_602343 = validateParameter(valid_602343, JString, required = false,
                                 default = nil)
  if valid_602343 != nil:
    section.add "X-Amz-Credential", valid_602343
  var valid_602344 = header.getOrDefault("X-Amz-Security-Token")
  valid_602344 = validateParameter(valid_602344, JString, required = false,
                                 default = nil)
  if valid_602344 != nil:
    section.add "X-Amz-Security-Token", valid_602344
  var valid_602345 = header.getOrDefault("X-Amz-Algorithm")
  valid_602345 = validateParameter(valid_602345, JString, required = false,
                                 default = nil)
  if valid_602345 != nil:
    section.add "X-Amz-Algorithm", valid_602345
  var valid_602346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602346 = validateParameter(valid_602346, JString, required = false,
                                 default = nil)
  if valid_602346 != nil:
    section.add "X-Amz-SignedHeaders", valid_602346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602347: Call_DeleteFunctionEventInvokeConfig_602335;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  let valid = call_602347.validator(path, query, header, formData, body)
  let scheme = call_602347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602347.url(scheme.get, call_602347.host, call_602347.base,
                         call_602347.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602347, url, valid)

proc call*(call_602348: Call_DeleteFunctionEventInvokeConfig_602335;
          FunctionName: string; Qualifier: string = ""): Recallable =
  ## deleteFunctionEventInvokeConfig
  ## <p>Deletes the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : A version number or alias name.
  var path_602349 = newJObject()
  var query_602350 = newJObject()
  add(path_602349, "FunctionName", newJString(FunctionName))
  add(query_602350, "Qualifier", newJString(Qualifier))
  result = call_602348.call(path_602349, query_602350, nil, nil, nil)

var deleteFunctionEventInvokeConfig* = Call_DeleteFunctionEventInvokeConfig_602335(
    name: "deleteFunctionEventInvokeConfig", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config",
    validator: validate_DeleteFunctionEventInvokeConfig_602336, base: "/",
    url: url_DeleteFunctionEventInvokeConfig_602337,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLayerVersion_602351 = ref object of OpenApiRestCall_601389
proc url_GetLayerVersion_602353(protocol: Scheme; host: string; base: string;
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

proc validate_GetLayerVersion_602352(path: JsonNode; query: JsonNode;
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
  var valid_602354 = path.getOrDefault("VersionNumber")
  valid_602354 = validateParameter(valid_602354, JInt, required = true, default = nil)
  if valid_602354 != nil:
    section.add "VersionNumber", valid_602354
  var valid_602355 = path.getOrDefault("LayerName")
  valid_602355 = validateParameter(valid_602355, JString, required = true,
                                 default = nil)
  if valid_602355 != nil:
    section.add "LayerName", valid_602355
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
  var valid_602356 = header.getOrDefault("X-Amz-Signature")
  valid_602356 = validateParameter(valid_602356, JString, required = false,
                                 default = nil)
  if valid_602356 != nil:
    section.add "X-Amz-Signature", valid_602356
  var valid_602357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602357 = validateParameter(valid_602357, JString, required = false,
                                 default = nil)
  if valid_602357 != nil:
    section.add "X-Amz-Content-Sha256", valid_602357
  var valid_602358 = header.getOrDefault("X-Amz-Date")
  valid_602358 = validateParameter(valid_602358, JString, required = false,
                                 default = nil)
  if valid_602358 != nil:
    section.add "X-Amz-Date", valid_602358
  var valid_602359 = header.getOrDefault("X-Amz-Credential")
  valid_602359 = validateParameter(valid_602359, JString, required = false,
                                 default = nil)
  if valid_602359 != nil:
    section.add "X-Amz-Credential", valid_602359
  var valid_602360 = header.getOrDefault("X-Amz-Security-Token")
  valid_602360 = validateParameter(valid_602360, JString, required = false,
                                 default = nil)
  if valid_602360 != nil:
    section.add "X-Amz-Security-Token", valid_602360
  var valid_602361 = header.getOrDefault("X-Amz-Algorithm")
  valid_602361 = validateParameter(valid_602361, JString, required = false,
                                 default = nil)
  if valid_602361 != nil:
    section.add "X-Amz-Algorithm", valid_602361
  var valid_602362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602362 = validateParameter(valid_602362, JString, required = false,
                                 default = nil)
  if valid_602362 != nil:
    section.add "X-Amz-SignedHeaders", valid_602362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602363: Call_GetLayerVersion_602351; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ## 
  let valid = call_602363.validator(path, query, header, formData, body)
  let scheme = call_602363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602363.url(scheme.get, call_602363.host, call_602363.base,
                         call_602363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602363, url, valid)

proc call*(call_602364: Call_GetLayerVersion_602351; VersionNumber: int;
          LayerName: string): Recallable =
  ## getLayerVersion
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ##   VersionNumber: int (required)
  ##                : The version number.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  var path_602365 = newJObject()
  add(path_602365, "VersionNumber", newJInt(VersionNumber))
  add(path_602365, "LayerName", newJString(LayerName))
  result = call_602364.call(path_602365, nil, nil, nil, nil)

var getLayerVersion* = Call_GetLayerVersion_602351(name: "getLayerVersion",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}",
    validator: validate_GetLayerVersion_602352, base: "/", url: url_GetLayerVersion_602353,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLayerVersion_602366 = ref object of OpenApiRestCall_601389
proc url_DeleteLayerVersion_602368(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteLayerVersion_602367(path: JsonNode; query: JsonNode;
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
  var valid_602369 = path.getOrDefault("VersionNumber")
  valid_602369 = validateParameter(valid_602369, JInt, required = true, default = nil)
  if valid_602369 != nil:
    section.add "VersionNumber", valid_602369
  var valid_602370 = path.getOrDefault("LayerName")
  valid_602370 = validateParameter(valid_602370, JString, required = true,
                                 default = nil)
  if valid_602370 != nil:
    section.add "LayerName", valid_602370
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
  var valid_602371 = header.getOrDefault("X-Amz-Signature")
  valid_602371 = validateParameter(valid_602371, JString, required = false,
                                 default = nil)
  if valid_602371 != nil:
    section.add "X-Amz-Signature", valid_602371
  var valid_602372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602372 = validateParameter(valid_602372, JString, required = false,
                                 default = nil)
  if valid_602372 != nil:
    section.add "X-Amz-Content-Sha256", valid_602372
  var valid_602373 = header.getOrDefault("X-Amz-Date")
  valid_602373 = validateParameter(valid_602373, JString, required = false,
                                 default = nil)
  if valid_602373 != nil:
    section.add "X-Amz-Date", valid_602373
  var valid_602374 = header.getOrDefault("X-Amz-Credential")
  valid_602374 = validateParameter(valid_602374, JString, required = false,
                                 default = nil)
  if valid_602374 != nil:
    section.add "X-Amz-Credential", valid_602374
  var valid_602375 = header.getOrDefault("X-Amz-Security-Token")
  valid_602375 = validateParameter(valid_602375, JString, required = false,
                                 default = nil)
  if valid_602375 != nil:
    section.add "X-Amz-Security-Token", valid_602375
  var valid_602376 = header.getOrDefault("X-Amz-Algorithm")
  valid_602376 = validateParameter(valid_602376, JString, required = false,
                                 default = nil)
  if valid_602376 != nil:
    section.add "X-Amz-Algorithm", valid_602376
  var valid_602377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602377 = validateParameter(valid_602377, JString, required = false,
                                 default = nil)
  if valid_602377 != nil:
    section.add "X-Amz-SignedHeaders", valid_602377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602378: Call_DeleteLayerVersion_602366; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Deleted versions can no longer be viewed or added to functions. To avoid breaking functions, a copy of the version remains in Lambda until no functions refer to it.
  ## 
  let valid = call_602378.validator(path, query, header, formData, body)
  let scheme = call_602378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602378.url(scheme.get, call_602378.host, call_602378.base,
                         call_602378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602378, url, valid)

proc call*(call_602379: Call_DeleteLayerVersion_602366; VersionNumber: int;
          LayerName: string): Recallable =
  ## deleteLayerVersion
  ## Deletes a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Deleted versions can no longer be viewed or added to functions. To avoid breaking functions, a copy of the version remains in Lambda until no functions refer to it.
  ##   VersionNumber: int (required)
  ##                : The version number.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  var path_602380 = newJObject()
  add(path_602380, "VersionNumber", newJInt(VersionNumber))
  add(path_602380, "LayerName", newJString(LayerName))
  result = call_602379.call(path_602380, nil, nil, nil, nil)

var deleteLayerVersion* = Call_DeleteLayerVersion_602366(
    name: "deleteLayerVersion", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}",
    validator: validate_DeleteLayerVersion_602367, base: "/",
    url: url_DeleteLayerVersion_602368, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutProvisionedConcurrencyConfig_602397 = ref object of OpenApiRestCall_601389
proc url_PutProvisionedConcurrencyConfig_602399(protocol: Scheme; host: string;
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

proc validate_PutProvisionedConcurrencyConfig_602398(path: JsonNode;
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
  var valid_602400 = path.getOrDefault("FunctionName")
  valid_602400 = validateParameter(valid_602400, JString, required = true,
                                 default = nil)
  if valid_602400 != nil:
    section.add "FunctionName", valid_602400
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString (required)
  ##            : The version number or alias name.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Qualifier` field"
  var valid_602401 = query.getOrDefault("Qualifier")
  valid_602401 = validateParameter(valid_602401, JString, required = true,
                                 default = nil)
  if valid_602401 != nil:
    section.add "Qualifier", valid_602401
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
  var valid_602402 = header.getOrDefault("X-Amz-Signature")
  valid_602402 = validateParameter(valid_602402, JString, required = false,
                                 default = nil)
  if valid_602402 != nil:
    section.add "X-Amz-Signature", valid_602402
  var valid_602403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602403 = validateParameter(valid_602403, JString, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "X-Amz-Content-Sha256", valid_602403
  var valid_602404 = header.getOrDefault("X-Amz-Date")
  valid_602404 = validateParameter(valid_602404, JString, required = false,
                                 default = nil)
  if valid_602404 != nil:
    section.add "X-Amz-Date", valid_602404
  var valid_602405 = header.getOrDefault("X-Amz-Credential")
  valid_602405 = validateParameter(valid_602405, JString, required = false,
                                 default = nil)
  if valid_602405 != nil:
    section.add "X-Amz-Credential", valid_602405
  var valid_602406 = header.getOrDefault("X-Amz-Security-Token")
  valid_602406 = validateParameter(valid_602406, JString, required = false,
                                 default = nil)
  if valid_602406 != nil:
    section.add "X-Amz-Security-Token", valid_602406
  var valid_602407 = header.getOrDefault("X-Amz-Algorithm")
  valid_602407 = validateParameter(valid_602407, JString, required = false,
                                 default = nil)
  if valid_602407 != nil:
    section.add "X-Amz-Algorithm", valid_602407
  var valid_602408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602408 = validateParameter(valid_602408, JString, required = false,
                                 default = nil)
  if valid_602408 != nil:
    section.add "X-Amz-SignedHeaders", valid_602408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602410: Call_PutProvisionedConcurrencyConfig_602397;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds a provisioned concurrency configuration to a function's alias or version.
  ## 
  let valid = call_602410.validator(path, query, header, formData, body)
  let scheme = call_602410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602410.url(scheme.get, call_602410.host, call_602410.base,
                         call_602410.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602410, url, valid)

proc call*(call_602411: Call_PutProvisionedConcurrencyConfig_602397;
          FunctionName: string; Qualifier: string; body: JsonNode): Recallable =
  ## putProvisionedConcurrencyConfig
  ## Adds a provisioned concurrency configuration to a function's alias or version.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string (required)
  ##            : The version number or alias name.
  ##   body: JObject (required)
  var path_602412 = newJObject()
  var query_602413 = newJObject()
  var body_602414 = newJObject()
  add(path_602412, "FunctionName", newJString(FunctionName))
  add(query_602413, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_602414 = body
  result = call_602411.call(path_602412, query_602413, nil, nil, body_602414)

var putProvisionedConcurrencyConfig* = Call_PutProvisionedConcurrencyConfig_602397(
    name: "putProvisionedConcurrencyConfig", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com", route: "/2019-09-30/functions/{FunctionName}/provisioned-concurrency#Qualifier",
    validator: validate_PutProvisionedConcurrencyConfig_602398, base: "/",
    url: url_PutProvisionedConcurrencyConfig_602399,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProvisionedConcurrencyConfig_602381 = ref object of OpenApiRestCall_601389
proc url_GetProvisionedConcurrencyConfig_602383(protocol: Scheme; host: string;
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

proc validate_GetProvisionedConcurrencyConfig_602382(path: JsonNode;
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
  var valid_602384 = path.getOrDefault("FunctionName")
  valid_602384 = validateParameter(valid_602384, JString, required = true,
                                 default = nil)
  if valid_602384 != nil:
    section.add "FunctionName", valid_602384
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString (required)
  ##            : The version number or alias name.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Qualifier` field"
  var valid_602385 = query.getOrDefault("Qualifier")
  valid_602385 = validateParameter(valid_602385, JString, required = true,
                                 default = nil)
  if valid_602385 != nil:
    section.add "Qualifier", valid_602385
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
  var valid_602386 = header.getOrDefault("X-Amz-Signature")
  valid_602386 = validateParameter(valid_602386, JString, required = false,
                                 default = nil)
  if valid_602386 != nil:
    section.add "X-Amz-Signature", valid_602386
  var valid_602387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602387 = validateParameter(valid_602387, JString, required = false,
                                 default = nil)
  if valid_602387 != nil:
    section.add "X-Amz-Content-Sha256", valid_602387
  var valid_602388 = header.getOrDefault("X-Amz-Date")
  valid_602388 = validateParameter(valid_602388, JString, required = false,
                                 default = nil)
  if valid_602388 != nil:
    section.add "X-Amz-Date", valid_602388
  var valid_602389 = header.getOrDefault("X-Amz-Credential")
  valid_602389 = validateParameter(valid_602389, JString, required = false,
                                 default = nil)
  if valid_602389 != nil:
    section.add "X-Amz-Credential", valid_602389
  var valid_602390 = header.getOrDefault("X-Amz-Security-Token")
  valid_602390 = validateParameter(valid_602390, JString, required = false,
                                 default = nil)
  if valid_602390 != nil:
    section.add "X-Amz-Security-Token", valid_602390
  var valid_602391 = header.getOrDefault("X-Amz-Algorithm")
  valid_602391 = validateParameter(valid_602391, JString, required = false,
                                 default = nil)
  if valid_602391 != nil:
    section.add "X-Amz-Algorithm", valid_602391
  var valid_602392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602392 = validateParameter(valid_602392, JString, required = false,
                                 default = nil)
  if valid_602392 != nil:
    section.add "X-Amz-SignedHeaders", valid_602392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602393: Call_GetProvisionedConcurrencyConfig_602381;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the provisioned concurrency configuration for a function's alias or version.
  ## 
  let valid = call_602393.validator(path, query, header, formData, body)
  let scheme = call_602393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602393.url(scheme.get, call_602393.host, call_602393.base,
                         call_602393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602393, url, valid)

proc call*(call_602394: Call_GetProvisionedConcurrencyConfig_602381;
          FunctionName: string; Qualifier: string): Recallable =
  ## getProvisionedConcurrencyConfig
  ## Retrieves the provisioned concurrency configuration for a function's alias or version.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string (required)
  ##            : The version number or alias name.
  var path_602395 = newJObject()
  var query_602396 = newJObject()
  add(path_602395, "FunctionName", newJString(FunctionName))
  add(query_602396, "Qualifier", newJString(Qualifier))
  result = call_602394.call(path_602395, query_602396, nil, nil, nil)

var getProvisionedConcurrencyConfig* = Call_GetProvisionedConcurrencyConfig_602381(
    name: "getProvisionedConcurrencyConfig", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com", route: "/2019-09-30/functions/{FunctionName}/provisioned-concurrency#Qualifier",
    validator: validate_GetProvisionedConcurrencyConfig_602382, base: "/",
    url: url_GetProvisionedConcurrencyConfig_602383,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProvisionedConcurrencyConfig_602415 = ref object of OpenApiRestCall_601389
proc url_DeleteProvisionedConcurrencyConfig_602417(protocol: Scheme; host: string;
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

proc validate_DeleteProvisionedConcurrencyConfig_602416(path: JsonNode;
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
  var valid_602418 = path.getOrDefault("FunctionName")
  valid_602418 = validateParameter(valid_602418, JString, required = true,
                                 default = nil)
  if valid_602418 != nil:
    section.add "FunctionName", valid_602418
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString (required)
  ##            : The version number or alias name.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Qualifier` field"
  var valid_602419 = query.getOrDefault("Qualifier")
  valid_602419 = validateParameter(valid_602419, JString, required = true,
                                 default = nil)
  if valid_602419 != nil:
    section.add "Qualifier", valid_602419
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
  var valid_602420 = header.getOrDefault("X-Amz-Signature")
  valid_602420 = validateParameter(valid_602420, JString, required = false,
                                 default = nil)
  if valid_602420 != nil:
    section.add "X-Amz-Signature", valid_602420
  var valid_602421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602421 = validateParameter(valid_602421, JString, required = false,
                                 default = nil)
  if valid_602421 != nil:
    section.add "X-Amz-Content-Sha256", valid_602421
  var valid_602422 = header.getOrDefault("X-Amz-Date")
  valid_602422 = validateParameter(valid_602422, JString, required = false,
                                 default = nil)
  if valid_602422 != nil:
    section.add "X-Amz-Date", valid_602422
  var valid_602423 = header.getOrDefault("X-Amz-Credential")
  valid_602423 = validateParameter(valid_602423, JString, required = false,
                                 default = nil)
  if valid_602423 != nil:
    section.add "X-Amz-Credential", valid_602423
  var valid_602424 = header.getOrDefault("X-Amz-Security-Token")
  valid_602424 = validateParameter(valid_602424, JString, required = false,
                                 default = nil)
  if valid_602424 != nil:
    section.add "X-Amz-Security-Token", valid_602424
  var valid_602425 = header.getOrDefault("X-Amz-Algorithm")
  valid_602425 = validateParameter(valid_602425, JString, required = false,
                                 default = nil)
  if valid_602425 != nil:
    section.add "X-Amz-Algorithm", valid_602425
  var valid_602426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602426 = validateParameter(valid_602426, JString, required = false,
                                 default = nil)
  if valid_602426 != nil:
    section.add "X-Amz-SignedHeaders", valid_602426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602427: Call_DeleteProvisionedConcurrencyConfig_602415;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the provisioned concurrency configuration for a function.
  ## 
  let valid = call_602427.validator(path, query, header, formData, body)
  let scheme = call_602427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602427.url(scheme.get, call_602427.host, call_602427.base,
                         call_602427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602427, url, valid)

proc call*(call_602428: Call_DeleteProvisionedConcurrencyConfig_602415;
          FunctionName: string; Qualifier: string): Recallable =
  ## deleteProvisionedConcurrencyConfig
  ## Deletes the provisioned concurrency configuration for a function.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string (required)
  ##            : The version number or alias name.
  var path_602429 = newJObject()
  var query_602430 = newJObject()
  add(path_602429, "FunctionName", newJString(FunctionName))
  add(query_602430, "Qualifier", newJString(Qualifier))
  result = call_602428.call(path_602429, query_602430, nil, nil, nil)

var deleteProvisionedConcurrencyConfig* = Call_DeleteProvisionedConcurrencyConfig_602415(
    name: "deleteProvisionedConcurrencyConfig", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com", route: "/2019-09-30/functions/{FunctionName}/provisioned-concurrency#Qualifier",
    validator: validate_DeleteProvisionedConcurrencyConfig_602416, base: "/",
    url: url_DeleteProvisionedConcurrencyConfig_602417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountSettings_602431 = ref object of OpenApiRestCall_601389
proc url_GetAccountSettings_602433(protocol: Scheme; host: string; base: string;
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

proc validate_GetAccountSettings_602432(path: JsonNode; query: JsonNode;
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
  var valid_602434 = header.getOrDefault("X-Amz-Signature")
  valid_602434 = validateParameter(valid_602434, JString, required = false,
                                 default = nil)
  if valid_602434 != nil:
    section.add "X-Amz-Signature", valid_602434
  var valid_602435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602435 = validateParameter(valid_602435, JString, required = false,
                                 default = nil)
  if valid_602435 != nil:
    section.add "X-Amz-Content-Sha256", valid_602435
  var valid_602436 = header.getOrDefault("X-Amz-Date")
  valid_602436 = validateParameter(valid_602436, JString, required = false,
                                 default = nil)
  if valid_602436 != nil:
    section.add "X-Amz-Date", valid_602436
  var valid_602437 = header.getOrDefault("X-Amz-Credential")
  valid_602437 = validateParameter(valid_602437, JString, required = false,
                                 default = nil)
  if valid_602437 != nil:
    section.add "X-Amz-Credential", valid_602437
  var valid_602438 = header.getOrDefault("X-Amz-Security-Token")
  valid_602438 = validateParameter(valid_602438, JString, required = false,
                                 default = nil)
  if valid_602438 != nil:
    section.add "X-Amz-Security-Token", valid_602438
  var valid_602439 = header.getOrDefault("X-Amz-Algorithm")
  valid_602439 = validateParameter(valid_602439, JString, required = false,
                                 default = nil)
  if valid_602439 != nil:
    section.add "X-Amz-Algorithm", valid_602439
  var valid_602440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602440 = validateParameter(valid_602440, JString, required = false,
                                 default = nil)
  if valid_602440 != nil:
    section.add "X-Amz-SignedHeaders", valid_602440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602441: Call_GetAccountSettings_602431; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details about your account's <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limits</a> and usage in an AWS Region.
  ## 
  let valid = call_602441.validator(path, query, header, formData, body)
  let scheme = call_602441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602441.url(scheme.get, call_602441.host, call_602441.base,
                         call_602441.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602441, url, valid)

proc call*(call_602442: Call_GetAccountSettings_602431): Recallable =
  ## getAccountSettings
  ## Retrieves details about your account's <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limits</a> and usage in an AWS Region.
  result = call_602442.call(nil, nil, nil, nil, nil)

var getAccountSettings* = Call_GetAccountSettings_602431(
    name: "getAccountSettings", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com", route: "/2016-08-19/account-settings/",
    validator: validate_GetAccountSettings_602432, base: "/",
    url: url_GetAccountSettings_602433, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionConcurrency_602443 = ref object of OpenApiRestCall_601389
proc url_GetFunctionConcurrency_602445(protocol: Scheme; host: string; base: string;
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

proc validate_GetFunctionConcurrency_602444(path: JsonNode; query: JsonNode;
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
  var valid_602446 = path.getOrDefault("FunctionName")
  valid_602446 = validateParameter(valid_602446, JString, required = true,
                                 default = nil)
  if valid_602446 != nil:
    section.add "FunctionName", valid_602446
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
  var valid_602447 = header.getOrDefault("X-Amz-Signature")
  valid_602447 = validateParameter(valid_602447, JString, required = false,
                                 default = nil)
  if valid_602447 != nil:
    section.add "X-Amz-Signature", valid_602447
  var valid_602448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602448 = validateParameter(valid_602448, JString, required = false,
                                 default = nil)
  if valid_602448 != nil:
    section.add "X-Amz-Content-Sha256", valid_602448
  var valid_602449 = header.getOrDefault("X-Amz-Date")
  valid_602449 = validateParameter(valid_602449, JString, required = false,
                                 default = nil)
  if valid_602449 != nil:
    section.add "X-Amz-Date", valid_602449
  var valid_602450 = header.getOrDefault("X-Amz-Credential")
  valid_602450 = validateParameter(valid_602450, JString, required = false,
                                 default = nil)
  if valid_602450 != nil:
    section.add "X-Amz-Credential", valid_602450
  var valid_602451 = header.getOrDefault("X-Amz-Security-Token")
  valid_602451 = validateParameter(valid_602451, JString, required = false,
                                 default = nil)
  if valid_602451 != nil:
    section.add "X-Amz-Security-Token", valid_602451
  var valid_602452 = header.getOrDefault("X-Amz-Algorithm")
  valid_602452 = validateParameter(valid_602452, JString, required = false,
                                 default = nil)
  if valid_602452 != nil:
    section.add "X-Amz-Algorithm", valid_602452
  var valid_602453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602453 = validateParameter(valid_602453, JString, required = false,
                                 default = nil)
  if valid_602453 != nil:
    section.add "X-Amz-SignedHeaders", valid_602453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602454: Call_GetFunctionConcurrency_602443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns details about the concurrency configuration for a function. To set a concurrency limit for a function, use <a>PutFunctionConcurrency</a>.
  ## 
  let valid = call_602454.validator(path, query, header, formData, body)
  let scheme = call_602454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602454.url(scheme.get, call_602454.host, call_602454.base,
                         call_602454.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602454, url, valid)

proc call*(call_602455: Call_GetFunctionConcurrency_602443; FunctionName: string): Recallable =
  ## getFunctionConcurrency
  ## Returns details about the concurrency configuration for a function. To set a concurrency limit for a function, use <a>PutFunctionConcurrency</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  var path_602456 = newJObject()
  add(path_602456, "FunctionName", newJString(FunctionName))
  result = call_602455.call(path_602456, nil, nil, nil, nil)

var getFunctionConcurrency* = Call_GetFunctionConcurrency_602443(
    name: "getFunctionConcurrency", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2019-09-30/functions/{FunctionName}/concurrency",
    validator: validate_GetFunctionConcurrency_602444, base: "/",
    url: url_GetFunctionConcurrency_602445, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionConfiguration_602473 = ref object of OpenApiRestCall_601389
proc url_UpdateFunctionConfiguration_602475(protocol: Scheme; host: string;
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

proc validate_UpdateFunctionConfiguration_602474(path: JsonNode; query: JsonNode;
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
  var valid_602476 = path.getOrDefault("FunctionName")
  valid_602476 = validateParameter(valid_602476, JString, required = true,
                                 default = nil)
  if valid_602476 != nil:
    section.add "FunctionName", valid_602476
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
  var valid_602477 = header.getOrDefault("X-Amz-Signature")
  valid_602477 = validateParameter(valid_602477, JString, required = false,
                                 default = nil)
  if valid_602477 != nil:
    section.add "X-Amz-Signature", valid_602477
  var valid_602478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602478 = validateParameter(valid_602478, JString, required = false,
                                 default = nil)
  if valid_602478 != nil:
    section.add "X-Amz-Content-Sha256", valid_602478
  var valid_602479 = header.getOrDefault("X-Amz-Date")
  valid_602479 = validateParameter(valid_602479, JString, required = false,
                                 default = nil)
  if valid_602479 != nil:
    section.add "X-Amz-Date", valid_602479
  var valid_602480 = header.getOrDefault("X-Amz-Credential")
  valid_602480 = validateParameter(valid_602480, JString, required = false,
                                 default = nil)
  if valid_602480 != nil:
    section.add "X-Amz-Credential", valid_602480
  var valid_602481 = header.getOrDefault("X-Amz-Security-Token")
  valid_602481 = validateParameter(valid_602481, JString, required = false,
                                 default = nil)
  if valid_602481 != nil:
    section.add "X-Amz-Security-Token", valid_602481
  var valid_602482 = header.getOrDefault("X-Amz-Algorithm")
  valid_602482 = validateParameter(valid_602482, JString, required = false,
                                 default = nil)
  if valid_602482 != nil:
    section.add "X-Amz-Algorithm", valid_602482
  var valid_602483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602483 = validateParameter(valid_602483, JString, required = false,
                                 default = nil)
  if valid_602483 != nil:
    section.add "X-Amz-SignedHeaders", valid_602483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602485: Call_UpdateFunctionConfiguration_602473; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modify the version-specific settings of a Lambda function.</p> <p>When you update a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute. During this time, you can't modify the function, but you can still invoke it. The <code>LastUpdateStatus</code>, <code>LastUpdateStatusReason</code>, and <code>LastUpdateStatusReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the update is complete and the function is processing events with the new configuration. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Function States</a>.</p> <p>These settings can vary between versions of a function and are locked when you publish a version. You can't modify the configuration of a published version, only the unpublished version.</p> <p>To configure function concurrency, use <a>PutFunctionConcurrency</a>. To grant invoke permissions to an account or AWS service, use <a>AddPermission</a>.</p>
  ## 
  let valid = call_602485.validator(path, query, header, formData, body)
  let scheme = call_602485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602485.url(scheme.get, call_602485.host, call_602485.base,
                         call_602485.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602485, url, valid)

proc call*(call_602486: Call_UpdateFunctionConfiguration_602473;
          FunctionName: string; body: JsonNode): Recallable =
  ## updateFunctionConfiguration
  ## <p>Modify the version-specific settings of a Lambda function.</p> <p>When you update a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute. During this time, you can't modify the function, but you can still invoke it. The <code>LastUpdateStatus</code>, <code>LastUpdateStatusReason</code>, and <code>LastUpdateStatusReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the update is complete and the function is processing events with the new configuration. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Function States</a>.</p> <p>These settings can vary between versions of a function and are locked when you publish a version. You can't modify the configuration of a published version, only the unpublished version.</p> <p>To configure function concurrency, use <a>PutFunctionConcurrency</a>. To grant invoke permissions to an account or AWS service, use <a>AddPermission</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_602487 = newJObject()
  var body_602488 = newJObject()
  add(path_602487, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_602488 = body
  result = call_602486.call(path_602487, nil, nil, nil, body_602488)

var updateFunctionConfiguration* = Call_UpdateFunctionConfiguration_602473(
    name: "updateFunctionConfiguration", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/configuration",
    validator: validate_UpdateFunctionConfiguration_602474, base: "/",
    url: url_UpdateFunctionConfiguration_602475,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionConfiguration_602457 = ref object of OpenApiRestCall_601389
proc url_GetFunctionConfiguration_602459(protocol: Scheme; host: string;
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

proc validate_GetFunctionConfiguration_602458(path: JsonNode; query: JsonNode;
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
  var valid_602460 = path.getOrDefault("FunctionName")
  valid_602460 = validateParameter(valid_602460, JString, required = true,
                                 default = nil)
  if valid_602460 != nil:
    section.add "FunctionName", valid_602460
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to get details about a published version of the function.
  section = newJObject()
  var valid_602461 = query.getOrDefault("Qualifier")
  valid_602461 = validateParameter(valid_602461, JString, required = false,
                                 default = nil)
  if valid_602461 != nil:
    section.add "Qualifier", valid_602461
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
  var valid_602462 = header.getOrDefault("X-Amz-Signature")
  valid_602462 = validateParameter(valid_602462, JString, required = false,
                                 default = nil)
  if valid_602462 != nil:
    section.add "X-Amz-Signature", valid_602462
  var valid_602463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602463 = validateParameter(valid_602463, JString, required = false,
                                 default = nil)
  if valid_602463 != nil:
    section.add "X-Amz-Content-Sha256", valid_602463
  var valid_602464 = header.getOrDefault("X-Amz-Date")
  valid_602464 = validateParameter(valid_602464, JString, required = false,
                                 default = nil)
  if valid_602464 != nil:
    section.add "X-Amz-Date", valid_602464
  var valid_602465 = header.getOrDefault("X-Amz-Credential")
  valid_602465 = validateParameter(valid_602465, JString, required = false,
                                 default = nil)
  if valid_602465 != nil:
    section.add "X-Amz-Credential", valid_602465
  var valid_602466 = header.getOrDefault("X-Amz-Security-Token")
  valid_602466 = validateParameter(valid_602466, JString, required = false,
                                 default = nil)
  if valid_602466 != nil:
    section.add "X-Amz-Security-Token", valid_602466
  var valid_602467 = header.getOrDefault("X-Amz-Algorithm")
  valid_602467 = validateParameter(valid_602467, JString, required = false,
                                 default = nil)
  if valid_602467 != nil:
    section.add "X-Amz-Algorithm", valid_602467
  var valid_602468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602468 = validateParameter(valid_602468, JString, required = false,
                                 default = nil)
  if valid_602468 != nil:
    section.add "X-Amz-SignedHeaders", valid_602468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602469: Call_GetFunctionConfiguration_602457; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the version-specific settings of a Lambda function or version. The output includes only options that can vary between versions of a function. To modify these settings, use <a>UpdateFunctionConfiguration</a>.</p> <p>To get all of a function's details, including function-level settings, use <a>GetFunction</a>.</p>
  ## 
  let valid = call_602469.validator(path, query, header, formData, body)
  let scheme = call_602469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602469.url(scheme.get, call_602469.host, call_602469.base,
                         call_602469.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602469, url, valid)

proc call*(call_602470: Call_GetFunctionConfiguration_602457; FunctionName: string;
          Qualifier: string = ""): Recallable =
  ## getFunctionConfiguration
  ## <p>Returns the version-specific settings of a Lambda function or version. The output includes only options that can vary between versions of a function. To modify these settings, use <a>UpdateFunctionConfiguration</a>.</p> <p>To get all of a function's details, including function-level settings, use <a>GetFunction</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to get details about a published version of the function.
  var path_602471 = newJObject()
  var query_602472 = newJObject()
  add(path_602471, "FunctionName", newJString(FunctionName))
  add(query_602472, "Qualifier", newJString(Qualifier))
  result = call_602470.call(path_602471, query_602472, nil, nil, nil)

var getFunctionConfiguration* = Call_GetFunctionConfiguration_602457(
    name: "getFunctionConfiguration", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/configuration",
    validator: validate_GetFunctionConfiguration_602458, base: "/",
    url: url_GetFunctionConfiguration_602459, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLayerVersionByArn_602489 = ref object of OpenApiRestCall_601389
proc url_GetLayerVersionByArn_602491(protocol: Scheme; host: string; base: string;
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

proc validate_GetLayerVersionByArn_602490(path: JsonNode; query: JsonNode;
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
  var valid_602505 = query.getOrDefault("find")
  valid_602505 = validateParameter(valid_602505, JString, required = true,
                                 default = newJString("LayerVersion"))
  if valid_602505 != nil:
    section.add "find", valid_602505
  var valid_602506 = query.getOrDefault("Arn")
  valid_602506 = validateParameter(valid_602506, JString, required = true,
                                 default = nil)
  if valid_602506 != nil:
    section.add "Arn", valid_602506
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
  var valid_602507 = header.getOrDefault("X-Amz-Signature")
  valid_602507 = validateParameter(valid_602507, JString, required = false,
                                 default = nil)
  if valid_602507 != nil:
    section.add "X-Amz-Signature", valid_602507
  var valid_602508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602508 = validateParameter(valid_602508, JString, required = false,
                                 default = nil)
  if valid_602508 != nil:
    section.add "X-Amz-Content-Sha256", valid_602508
  var valid_602509 = header.getOrDefault("X-Amz-Date")
  valid_602509 = validateParameter(valid_602509, JString, required = false,
                                 default = nil)
  if valid_602509 != nil:
    section.add "X-Amz-Date", valid_602509
  var valid_602510 = header.getOrDefault("X-Amz-Credential")
  valid_602510 = validateParameter(valid_602510, JString, required = false,
                                 default = nil)
  if valid_602510 != nil:
    section.add "X-Amz-Credential", valid_602510
  var valid_602511 = header.getOrDefault("X-Amz-Security-Token")
  valid_602511 = validateParameter(valid_602511, JString, required = false,
                                 default = nil)
  if valid_602511 != nil:
    section.add "X-Amz-Security-Token", valid_602511
  var valid_602512 = header.getOrDefault("X-Amz-Algorithm")
  valid_602512 = validateParameter(valid_602512, JString, required = false,
                                 default = nil)
  if valid_602512 != nil:
    section.add "X-Amz-Algorithm", valid_602512
  var valid_602513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602513 = validateParameter(valid_602513, JString, required = false,
                                 default = nil)
  if valid_602513 != nil:
    section.add "X-Amz-SignedHeaders", valid_602513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602514: Call_GetLayerVersionByArn_602489; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ## 
  let valid = call_602514.validator(path, query, header, formData, body)
  let scheme = call_602514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602514.url(scheme.get, call_602514.host, call_602514.base,
                         call_602514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602514, url, valid)

proc call*(call_602515: Call_GetLayerVersionByArn_602489; Arn: string;
          find: string = "LayerVersion"): Recallable =
  ## getLayerVersionByArn
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ##   find: string (required)
  ##   Arn: string (required)
  ##      : The ARN of the layer version.
  var query_602516 = newJObject()
  add(query_602516, "find", newJString(find))
  add(query_602516, "Arn", newJString(Arn))
  result = call_602515.call(nil, query_602516, nil, nil, nil)

var getLayerVersionByArn* = Call_GetLayerVersionByArn_602489(
    name: "getLayerVersionByArn", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers#find=LayerVersion&Arn",
    validator: validate_GetLayerVersionByArn_602490, base: "/",
    url: url_GetLayerVersionByArn_602491, schemes: {Scheme.Https, Scheme.Http})
type
  Call_Invoke_602517 = ref object of OpenApiRestCall_601389
proc url_Invoke_602519(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_Invoke_602518(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602520 = path.getOrDefault("FunctionName")
  valid_602520 = validateParameter(valid_602520, JString, required = true,
                                 default = nil)
  if valid_602520 != nil:
    section.add "FunctionName", valid_602520
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to invoke a published version of the function.
  section = newJObject()
  var valid_602521 = query.getOrDefault("Qualifier")
  valid_602521 = validateParameter(valid_602521, JString, required = false,
                                 default = nil)
  if valid_602521 != nil:
    section.add "Qualifier", valid_602521
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
  var valid_602522 = header.getOrDefault("X-Amz-Invocation-Type")
  valid_602522 = validateParameter(valid_602522, JString, required = false,
                                 default = newJString("Event"))
  if valid_602522 != nil:
    section.add "X-Amz-Invocation-Type", valid_602522
  var valid_602523 = header.getOrDefault("X-Amz-Signature")
  valid_602523 = validateParameter(valid_602523, JString, required = false,
                                 default = nil)
  if valid_602523 != nil:
    section.add "X-Amz-Signature", valid_602523
  var valid_602524 = header.getOrDefault("X-Amz-Client-Context")
  valid_602524 = validateParameter(valid_602524, JString, required = false,
                                 default = nil)
  if valid_602524 != nil:
    section.add "X-Amz-Client-Context", valid_602524
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
  var valid_602529 = header.getOrDefault("X-Amz-Log-Type")
  valid_602529 = validateParameter(valid_602529, JString, required = false,
                                 default = newJString("None"))
  if valid_602529 != nil:
    section.add "X-Amz-Log-Type", valid_602529
  var valid_602530 = header.getOrDefault("X-Amz-Algorithm")
  valid_602530 = validateParameter(valid_602530, JString, required = false,
                                 default = nil)
  if valid_602530 != nil:
    section.add "X-Amz-Algorithm", valid_602530
  var valid_602531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602531 = validateParameter(valid_602531, JString, required = false,
                                 default = nil)
  if valid_602531 != nil:
    section.add "X-Amz-SignedHeaders", valid_602531
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602533: Call_Invoke_602517; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Invokes a Lambda function. You can invoke a function synchronously (and wait for the response), or asynchronously. To invoke a function asynchronously, set <code>InvocationType</code> to <code>Event</code>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-sync.html">synchronous invocation</a>, details about the function response, including errors, are included in the response body and headers. For either invocation type, you can find more information in the <a href="https://docs.aws.amazon.com/lambda/latest/dg/monitoring-functions.html">execution log</a> and <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-x-ray.html">trace</a>.</p> <p>When an error occurs, your function may be invoked multiple times. Retry behavior varies by error type, client, event source, and invocation type. For example, if you invoke a function asynchronously and it returns an error, Lambda executes the function up to two more times. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/retries-on-errors.html">Retry Behavior</a>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a>, Lambda adds events to a queue before sending them to your function. If your function does not have enough capacity to keep up with the queue, events may be lost. Occasionally, your function may receive the same event multiple times, even if no error occurs. To retain events that were not processed, configure your function with a <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#dlq">dead-letter queue</a>.</p> <p>The status code in the API response doesn't reflect function errors. Error codes are reserved for errors that prevent your function from executing, such as permissions errors, <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limit errors</a>, or issues with your function's code and configuration. For example, Lambda returns <code>TooManyRequestsException</code> if executing the function would cause you to exceed a concurrency limit at either the account level (<code>ConcurrentInvocationLimitExceeded</code>) or function level (<code>ReservedFunctionConcurrentInvocationLimitExceeded</code>).</p> <p>For functions with a long timeout, your client might be disconnected during synchronous invocation while it waits for a response. Configure your HTTP client, SDK, firewall, proxy, or operating system to allow for long connections with timeout or keep-alive settings.</p> <p>This operation requires permission for the <code>lambda:InvokeFunction</code> action.</p>
  ## 
  let valid = call_602533.validator(path, query, header, formData, body)
  let scheme = call_602533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602533.url(scheme.get, call_602533.host, call_602533.base,
                         call_602533.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602533, url, valid)

proc call*(call_602534: Call_Invoke_602517; FunctionName: string; body: JsonNode;
          Qualifier: string = ""): Recallable =
  ## invoke
  ## <p>Invokes a Lambda function. You can invoke a function synchronously (and wait for the response), or asynchronously. To invoke a function asynchronously, set <code>InvocationType</code> to <code>Event</code>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-sync.html">synchronous invocation</a>, details about the function response, including errors, are included in the response body and headers. For either invocation type, you can find more information in the <a href="https://docs.aws.amazon.com/lambda/latest/dg/monitoring-functions.html">execution log</a> and <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-x-ray.html">trace</a>.</p> <p>When an error occurs, your function may be invoked multiple times. Retry behavior varies by error type, client, event source, and invocation type. For example, if you invoke a function asynchronously and it returns an error, Lambda executes the function up to two more times. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/retries-on-errors.html">Retry Behavior</a>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a>, Lambda adds events to a queue before sending them to your function. If your function does not have enough capacity to keep up with the queue, events may be lost. Occasionally, your function may receive the same event multiple times, even if no error occurs. To retain events that were not processed, configure your function with a <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#dlq">dead-letter queue</a>.</p> <p>The status code in the API response doesn't reflect function errors. Error codes are reserved for errors that prevent your function from executing, such as permissions errors, <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limit errors</a>, or issues with your function's code and configuration. For example, Lambda returns <code>TooManyRequestsException</code> if executing the function would cause you to exceed a concurrency limit at either the account level (<code>ConcurrentInvocationLimitExceeded</code>) or function level (<code>ReservedFunctionConcurrentInvocationLimitExceeded</code>).</p> <p>For functions with a long timeout, your client might be disconnected during synchronous invocation while it waits for a response. Configure your HTTP client, SDK, firewall, proxy, or operating system to allow for long connections with timeout or keep-alive settings.</p> <p>This operation requires permission for the <code>lambda:InvokeFunction</code> action.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to invoke a published version of the function.
  ##   body: JObject (required)
  var path_602535 = newJObject()
  var query_602536 = newJObject()
  var body_602537 = newJObject()
  add(path_602535, "FunctionName", newJString(FunctionName))
  add(query_602536, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_602537 = body
  result = call_602534.call(path_602535, query_602536, nil, nil, body_602537)

var invoke* = Call_Invoke_602517(name: "invoke", meth: HttpMethod.HttpPost,
                              host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/invocations",
                              validator: validate_Invoke_602518, base: "/",
                              url: url_Invoke_602519,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_InvokeAsync_602538 = ref object of OpenApiRestCall_601389
proc url_InvokeAsync_602540(protocol: Scheme; host: string; base: string;
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

proc validate_InvokeAsync_602539(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602541 = path.getOrDefault("FunctionName")
  valid_602541 = validateParameter(valid_602541, JString, required = true,
                                 default = nil)
  if valid_602541 != nil:
    section.add "FunctionName", valid_602541
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
  var valid_602542 = header.getOrDefault("X-Amz-Signature")
  valid_602542 = validateParameter(valid_602542, JString, required = false,
                                 default = nil)
  if valid_602542 != nil:
    section.add "X-Amz-Signature", valid_602542
  var valid_602543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602543 = validateParameter(valid_602543, JString, required = false,
                                 default = nil)
  if valid_602543 != nil:
    section.add "X-Amz-Content-Sha256", valid_602543
  var valid_602544 = header.getOrDefault("X-Amz-Date")
  valid_602544 = validateParameter(valid_602544, JString, required = false,
                                 default = nil)
  if valid_602544 != nil:
    section.add "X-Amz-Date", valid_602544
  var valid_602545 = header.getOrDefault("X-Amz-Credential")
  valid_602545 = validateParameter(valid_602545, JString, required = false,
                                 default = nil)
  if valid_602545 != nil:
    section.add "X-Amz-Credential", valid_602545
  var valid_602546 = header.getOrDefault("X-Amz-Security-Token")
  valid_602546 = validateParameter(valid_602546, JString, required = false,
                                 default = nil)
  if valid_602546 != nil:
    section.add "X-Amz-Security-Token", valid_602546
  var valid_602547 = header.getOrDefault("X-Amz-Algorithm")
  valid_602547 = validateParameter(valid_602547, JString, required = false,
                                 default = nil)
  if valid_602547 != nil:
    section.add "X-Amz-Algorithm", valid_602547
  var valid_602548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602548 = validateParameter(valid_602548, JString, required = false,
                                 default = nil)
  if valid_602548 != nil:
    section.add "X-Amz-SignedHeaders", valid_602548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602550: Call_InvokeAsync_602538; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <important> <p>For asynchronous function invocation, use <a>Invoke</a>.</p> </important> <p>Invokes a function asynchronously.</p>
  ## 
  let valid = call_602550.validator(path, query, header, formData, body)
  let scheme = call_602550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602550.url(scheme.get, call_602550.host, call_602550.base,
                         call_602550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602550, url, valid)

proc call*(call_602551: Call_InvokeAsync_602538; FunctionName: string; body: JsonNode): Recallable =
  ## invokeAsync
  ## <important> <p>For asynchronous function invocation, use <a>Invoke</a>.</p> </important> <p>Invokes a function asynchronously.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_602552 = newJObject()
  var body_602553 = newJObject()
  add(path_602552, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_602553 = body
  result = call_602551.call(path_602552, nil, nil, nil, body_602553)

var invokeAsync* = Call_InvokeAsync_602538(name: "invokeAsync",
                                        meth: HttpMethod.HttpPost,
                                        host: "lambda.amazonaws.com", route: "/2014-11-13/functions/{FunctionName}/invoke-async/",
                                        validator: validate_InvokeAsync_602539,
                                        base: "/", url: url_InvokeAsync_602540,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctionEventInvokeConfigs_602554 = ref object of OpenApiRestCall_601389
proc url_ListFunctionEventInvokeConfigs_602556(protocol: Scheme; host: string;
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

proc validate_ListFunctionEventInvokeConfigs_602555(path: JsonNode;
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
  var valid_602557 = path.getOrDefault("FunctionName")
  valid_602557 = validateParameter(valid_602557, JString, required = true,
                                 default = nil)
  if valid_602557 != nil:
    section.add "FunctionName", valid_602557
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: JInt
  ##           : The maximum number of configurations to return.
  section = newJObject()
  var valid_602558 = query.getOrDefault("Marker")
  valid_602558 = validateParameter(valid_602558, JString, required = false,
                                 default = nil)
  if valid_602558 != nil:
    section.add "Marker", valid_602558
  var valid_602559 = query.getOrDefault("MaxItems")
  valid_602559 = validateParameter(valid_602559, JInt, required = false, default = nil)
  if valid_602559 != nil:
    section.add "MaxItems", valid_602559
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
  var valid_602560 = header.getOrDefault("X-Amz-Signature")
  valid_602560 = validateParameter(valid_602560, JString, required = false,
                                 default = nil)
  if valid_602560 != nil:
    section.add "X-Amz-Signature", valid_602560
  var valid_602561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602561 = validateParameter(valid_602561, JString, required = false,
                                 default = nil)
  if valid_602561 != nil:
    section.add "X-Amz-Content-Sha256", valid_602561
  var valid_602562 = header.getOrDefault("X-Amz-Date")
  valid_602562 = validateParameter(valid_602562, JString, required = false,
                                 default = nil)
  if valid_602562 != nil:
    section.add "X-Amz-Date", valid_602562
  var valid_602563 = header.getOrDefault("X-Amz-Credential")
  valid_602563 = validateParameter(valid_602563, JString, required = false,
                                 default = nil)
  if valid_602563 != nil:
    section.add "X-Amz-Credential", valid_602563
  var valid_602564 = header.getOrDefault("X-Amz-Security-Token")
  valid_602564 = validateParameter(valid_602564, JString, required = false,
                                 default = nil)
  if valid_602564 != nil:
    section.add "X-Amz-Security-Token", valid_602564
  var valid_602565 = header.getOrDefault("X-Amz-Algorithm")
  valid_602565 = validateParameter(valid_602565, JString, required = false,
                                 default = nil)
  if valid_602565 != nil:
    section.add "X-Amz-Algorithm", valid_602565
  var valid_602566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602566 = validateParameter(valid_602566, JString, required = false,
                                 default = nil)
  if valid_602566 != nil:
    section.add "X-Amz-SignedHeaders", valid_602566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602567: Call_ListFunctionEventInvokeConfigs_602554; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list of configurations for asynchronous invocation for a function.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  let valid = call_602567.validator(path, query, header, formData, body)
  let scheme = call_602567.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602567.url(scheme.get, call_602567.host, call_602567.base,
                         call_602567.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602567, url, valid)

proc call*(call_602568: Call_ListFunctionEventInvokeConfigs_602554;
          FunctionName: string; Marker: string = ""; MaxItems: int = 0): Recallable =
  ## listFunctionEventInvokeConfigs
  ## <p>Retrieves a list of configurations for asynchronous invocation for a function.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ##   Marker: string
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   MaxItems: int
  ##           : The maximum number of configurations to return.
  var path_602569 = newJObject()
  var query_602570 = newJObject()
  add(query_602570, "Marker", newJString(Marker))
  add(path_602569, "FunctionName", newJString(FunctionName))
  add(query_602570, "MaxItems", newJInt(MaxItems))
  result = call_602568.call(path_602569, query_602570, nil, nil, nil)

var listFunctionEventInvokeConfigs* = Call_ListFunctionEventInvokeConfigs_602554(
    name: "listFunctionEventInvokeConfigs", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config/list",
    validator: validate_ListFunctionEventInvokeConfigs_602555, base: "/",
    url: url_ListFunctionEventInvokeConfigs_602556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctions_602571 = ref object of OpenApiRestCall_601389
proc url_ListFunctions_602573(protocol: Scheme; host: string; base: string;
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

proc validate_ListFunctions_602572(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602574 = query.getOrDefault("Marker")
  valid_602574 = validateParameter(valid_602574, JString, required = false,
                                 default = nil)
  if valid_602574 != nil:
    section.add "Marker", valid_602574
  var valid_602575 = query.getOrDefault("FunctionVersion")
  valid_602575 = validateParameter(valid_602575, JString, required = false,
                                 default = newJString("ALL"))
  if valid_602575 != nil:
    section.add "FunctionVersion", valid_602575
  var valid_602576 = query.getOrDefault("MaxItems")
  valid_602576 = validateParameter(valid_602576, JInt, required = false, default = nil)
  if valid_602576 != nil:
    section.add "MaxItems", valid_602576
  var valid_602577 = query.getOrDefault("MasterRegion")
  valid_602577 = validateParameter(valid_602577, JString, required = false,
                                 default = nil)
  if valid_602577 != nil:
    section.add "MasterRegion", valid_602577
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
  var valid_602578 = header.getOrDefault("X-Amz-Signature")
  valid_602578 = validateParameter(valid_602578, JString, required = false,
                                 default = nil)
  if valid_602578 != nil:
    section.add "X-Amz-Signature", valid_602578
  var valid_602579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602579 = validateParameter(valid_602579, JString, required = false,
                                 default = nil)
  if valid_602579 != nil:
    section.add "X-Amz-Content-Sha256", valid_602579
  var valid_602580 = header.getOrDefault("X-Amz-Date")
  valid_602580 = validateParameter(valid_602580, JString, required = false,
                                 default = nil)
  if valid_602580 != nil:
    section.add "X-Amz-Date", valid_602580
  var valid_602581 = header.getOrDefault("X-Amz-Credential")
  valid_602581 = validateParameter(valid_602581, JString, required = false,
                                 default = nil)
  if valid_602581 != nil:
    section.add "X-Amz-Credential", valid_602581
  var valid_602582 = header.getOrDefault("X-Amz-Security-Token")
  valid_602582 = validateParameter(valid_602582, JString, required = false,
                                 default = nil)
  if valid_602582 != nil:
    section.add "X-Amz-Security-Token", valid_602582
  var valid_602583 = header.getOrDefault("X-Amz-Algorithm")
  valid_602583 = validateParameter(valid_602583, JString, required = false,
                                 default = nil)
  if valid_602583 != nil:
    section.add "X-Amz-Algorithm", valid_602583
  var valid_602584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602584 = validateParameter(valid_602584, JString, required = false,
                                 default = nil)
  if valid_602584 != nil:
    section.add "X-Amz-SignedHeaders", valid_602584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602585: Call_ListFunctions_602571; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of Lambda functions, with the version-specific configuration of each.</p> <p>Set <code>FunctionVersion</code> to <code>ALL</code> to include all published versions of each function in addition to the unpublished version. To get more information about a function or version, use <a>GetFunction</a>.</p>
  ## 
  let valid = call_602585.validator(path, query, header, formData, body)
  let scheme = call_602585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602585.url(scheme.get, call_602585.host, call_602585.base,
                         call_602585.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602585, url, valid)

proc call*(call_602586: Call_ListFunctions_602571; Marker: string = "";
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
  var query_602587 = newJObject()
  add(query_602587, "Marker", newJString(Marker))
  add(query_602587, "FunctionVersion", newJString(FunctionVersion))
  add(query_602587, "MaxItems", newJInt(MaxItems))
  add(query_602587, "MasterRegion", newJString(MasterRegion))
  result = call_602586.call(nil, query_602587, nil, nil, nil)

var listFunctions* = Call_ListFunctions_602571(name: "listFunctions",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/", validator: validate_ListFunctions_602572,
    base: "/", url: url_ListFunctions_602573, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PublishLayerVersion_602606 = ref object of OpenApiRestCall_601389
proc url_PublishLayerVersion_602608(protocol: Scheme; host: string; base: string;
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

proc validate_PublishLayerVersion_602607(path: JsonNode; query: JsonNode;
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
  var valid_602609 = path.getOrDefault("LayerName")
  valid_602609 = validateParameter(valid_602609, JString, required = true,
                                 default = nil)
  if valid_602609 != nil:
    section.add "LayerName", valid_602609
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
  var valid_602610 = header.getOrDefault("X-Amz-Signature")
  valid_602610 = validateParameter(valid_602610, JString, required = false,
                                 default = nil)
  if valid_602610 != nil:
    section.add "X-Amz-Signature", valid_602610
  var valid_602611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602611 = validateParameter(valid_602611, JString, required = false,
                                 default = nil)
  if valid_602611 != nil:
    section.add "X-Amz-Content-Sha256", valid_602611
  var valid_602612 = header.getOrDefault("X-Amz-Date")
  valid_602612 = validateParameter(valid_602612, JString, required = false,
                                 default = nil)
  if valid_602612 != nil:
    section.add "X-Amz-Date", valid_602612
  var valid_602613 = header.getOrDefault("X-Amz-Credential")
  valid_602613 = validateParameter(valid_602613, JString, required = false,
                                 default = nil)
  if valid_602613 != nil:
    section.add "X-Amz-Credential", valid_602613
  var valid_602614 = header.getOrDefault("X-Amz-Security-Token")
  valid_602614 = validateParameter(valid_602614, JString, required = false,
                                 default = nil)
  if valid_602614 != nil:
    section.add "X-Amz-Security-Token", valid_602614
  var valid_602615 = header.getOrDefault("X-Amz-Algorithm")
  valid_602615 = validateParameter(valid_602615, JString, required = false,
                                 default = nil)
  if valid_602615 != nil:
    section.add "X-Amz-Algorithm", valid_602615
  var valid_602616 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602616 = validateParameter(valid_602616, JString, required = false,
                                 default = nil)
  if valid_602616 != nil:
    section.add "X-Amz-SignedHeaders", valid_602616
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602618: Call_PublishLayerVersion_602606; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a> from a ZIP archive. Each time you call <code>PublishLayerVersion</code> with the same layer name, a new version is created.</p> <p>Add layers to your function with <a>CreateFunction</a> or <a>UpdateFunctionConfiguration</a>.</p>
  ## 
  let valid = call_602618.validator(path, query, header, formData, body)
  let scheme = call_602618.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602618.url(scheme.get, call_602618.host, call_602618.base,
                         call_602618.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602618, url, valid)

proc call*(call_602619: Call_PublishLayerVersion_602606; LayerName: string;
          body: JsonNode): Recallable =
  ## publishLayerVersion
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a> from a ZIP archive. Each time you call <code>PublishLayerVersion</code> with the same layer name, a new version is created.</p> <p>Add layers to your function with <a>CreateFunction</a> or <a>UpdateFunctionConfiguration</a>.</p>
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  ##   body: JObject (required)
  var path_602620 = newJObject()
  var body_602621 = newJObject()
  add(path_602620, "LayerName", newJString(LayerName))
  if body != nil:
    body_602621 = body
  result = call_602619.call(path_602620, nil, nil, nil, body_602621)

var publishLayerVersion* = Call_PublishLayerVersion_602606(
    name: "publishLayerVersion", meth: HttpMethod.HttpPost,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions",
    validator: validate_PublishLayerVersion_602607, base: "/",
    url: url_PublishLayerVersion_602608, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLayerVersions_602588 = ref object of OpenApiRestCall_601389
proc url_ListLayerVersions_602590(protocol: Scheme; host: string; base: string;
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

proc validate_ListLayerVersions_602589(path: JsonNode; query: JsonNode;
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
  var valid_602591 = path.getOrDefault("LayerName")
  valid_602591 = validateParameter(valid_602591, JString, required = true,
                                 default = nil)
  if valid_602591 != nil:
    section.add "LayerName", valid_602591
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : A pagination token returned by a previous call.
  ##   CompatibleRuntime: JString
  ##                    : A runtime identifier. For example, <code>go1.x</code>.
  ##   MaxItems: JInt
  ##           : The maximum number of versions to return.
  section = newJObject()
  var valid_602592 = query.getOrDefault("Marker")
  valid_602592 = validateParameter(valid_602592, JString, required = false,
                                 default = nil)
  if valid_602592 != nil:
    section.add "Marker", valid_602592
  var valid_602593 = query.getOrDefault("CompatibleRuntime")
  valid_602593 = validateParameter(valid_602593, JString, required = false,
                                 default = newJString("nodejs"))
  if valid_602593 != nil:
    section.add "CompatibleRuntime", valid_602593
  var valid_602594 = query.getOrDefault("MaxItems")
  valid_602594 = validateParameter(valid_602594, JInt, required = false, default = nil)
  if valid_602594 != nil:
    section.add "MaxItems", valid_602594
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
  var valid_602595 = header.getOrDefault("X-Amz-Signature")
  valid_602595 = validateParameter(valid_602595, JString, required = false,
                                 default = nil)
  if valid_602595 != nil:
    section.add "X-Amz-Signature", valid_602595
  var valid_602596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602596 = validateParameter(valid_602596, JString, required = false,
                                 default = nil)
  if valid_602596 != nil:
    section.add "X-Amz-Content-Sha256", valid_602596
  var valid_602597 = header.getOrDefault("X-Amz-Date")
  valid_602597 = validateParameter(valid_602597, JString, required = false,
                                 default = nil)
  if valid_602597 != nil:
    section.add "X-Amz-Date", valid_602597
  var valid_602598 = header.getOrDefault("X-Amz-Credential")
  valid_602598 = validateParameter(valid_602598, JString, required = false,
                                 default = nil)
  if valid_602598 != nil:
    section.add "X-Amz-Credential", valid_602598
  var valid_602599 = header.getOrDefault("X-Amz-Security-Token")
  valid_602599 = validateParameter(valid_602599, JString, required = false,
                                 default = nil)
  if valid_602599 != nil:
    section.add "X-Amz-Security-Token", valid_602599
  var valid_602600 = header.getOrDefault("X-Amz-Algorithm")
  valid_602600 = validateParameter(valid_602600, JString, required = false,
                                 default = nil)
  if valid_602600 != nil:
    section.add "X-Amz-Algorithm", valid_602600
  var valid_602601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602601 = validateParameter(valid_602601, JString, required = false,
                                 default = nil)
  if valid_602601 != nil:
    section.add "X-Amz-SignedHeaders", valid_602601
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602602: Call_ListLayerVersions_602588; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Versions that have been deleted aren't listed. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only versions that indicate that they're compatible with that runtime.
  ## 
  let valid = call_602602.validator(path, query, header, formData, body)
  let scheme = call_602602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602602.url(scheme.get, call_602602.host, call_602602.base,
                         call_602602.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602602, url, valid)

proc call*(call_602603: Call_ListLayerVersions_602588; LayerName: string;
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
  var path_602604 = newJObject()
  var query_602605 = newJObject()
  add(query_602605, "Marker", newJString(Marker))
  add(query_602605, "CompatibleRuntime", newJString(CompatibleRuntime))
  add(query_602605, "MaxItems", newJInt(MaxItems))
  add(path_602604, "LayerName", newJString(LayerName))
  result = call_602603.call(path_602604, query_602605, nil, nil, nil)

var listLayerVersions* = Call_ListLayerVersions_602588(name: "listLayerVersions",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions",
    validator: validate_ListLayerVersions_602589, base: "/",
    url: url_ListLayerVersions_602590, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLayers_602622 = ref object of OpenApiRestCall_601389
proc url_ListLayers_602624(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListLayers_602623(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602625 = query.getOrDefault("Marker")
  valid_602625 = validateParameter(valid_602625, JString, required = false,
                                 default = nil)
  if valid_602625 != nil:
    section.add "Marker", valid_602625
  var valid_602626 = query.getOrDefault("CompatibleRuntime")
  valid_602626 = validateParameter(valid_602626, JString, required = false,
                                 default = newJString("nodejs"))
  if valid_602626 != nil:
    section.add "CompatibleRuntime", valid_602626
  var valid_602627 = query.getOrDefault("MaxItems")
  valid_602627 = validateParameter(valid_602627, JInt, required = false, default = nil)
  if valid_602627 != nil:
    section.add "MaxItems", valid_602627
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
  var valid_602628 = header.getOrDefault("X-Amz-Signature")
  valid_602628 = validateParameter(valid_602628, JString, required = false,
                                 default = nil)
  if valid_602628 != nil:
    section.add "X-Amz-Signature", valid_602628
  var valid_602629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602629 = validateParameter(valid_602629, JString, required = false,
                                 default = nil)
  if valid_602629 != nil:
    section.add "X-Amz-Content-Sha256", valid_602629
  var valid_602630 = header.getOrDefault("X-Amz-Date")
  valid_602630 = validateParameter(valid_602630, JString, required = false,
                                 default = nil)
  if valid_602630 != nil:
    section.add "X-Amz-Date", valid_602630
  var valid_602631 = header.getOrDefault("X-Amz-Credential")
  valid_602631 = validateParameter(valid_602631, JString, required = false,
                                 default = nil)
  if valid_602631 != nil:
    section.add "X-Amz-Credential", valid_602631
  var valid_602632 = header.getOrDefault("X-Amz-Security-Token")
  valid_602632 = validateParameter(valid_602632, JString, required = false,
                                 default = nil)
  if valid_602632 != nil:
    section.add "X-Amz-Security-Token", valid_602632
  var valid_602633 = header.getOrDefault("X-Amz-Algorithm")
  valid_602633 = validateParameter(valid_602633, JString, required = false,
                                 default = nil)
  if valid_602633 != nil:
    section.add "X-Amz-Algorithm", valid_602633
  var valid_602634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602634 = validateParameter(valid_602634, JString, required = false,
                                 default = nil)
  if valid_602634 != nil:
    section.add "X-Amz-SignedHeaders", valid_602634
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602635: Call_ListLayers_602622; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layers</a> and shows information about the latest version of each. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only layers that indicate that they're compatible with that runtime.
  ## 
  let valid = call_602635.validator(path, query, header, formData, body)
  let scheme = call_602635.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602635.url(scheme.get, call_602635.host, call_602635.base,
                         call_602635.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602635, url, valid)

proc call*(call_602636: Call_ListLayers_602622; Marker: string = "";
          CompatibleRuntime: string = "nodejs"; MaxItems: int = 0): Recallable =
  ## listLayers
  ## Lists <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layers</a> and shows information about the latest version of each. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only layers that indicate that they're compatible with that runtime.
  ##   Marker: string
  ##         : A pagination token returned by a previous call.
  ##   CompatibleRuntime: string
  ##                    : A runtime identifier. For example, <code>go1.x</code>.
  ##   MaxItems: int
  ##           : The maximum number of layers to return.
  var query_602637 = newJObject()
  add(query_602637, "Marker", newJString(Marker))
  add(query_602637, "CompatibleRuntime", newJString(CompatibleRuntime))
  add(query_602637, "MaxItems", newJInt(MaxItems))
  result = call_602636.call(nil, query_602637, nil, nil, nil)

var listLayers* = Call_ListLayers_602622(name: "listLayers",
                                      meth: HttpMethod.HttpGet,
                                      host: "lambda.amazonaws.com",
                                      route: "/2018-10-31/layers",
                                      validator: validate_ListLayers_602623,
                                      base: "/", url: url_ListLayers_602624,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisionedConcurrencyConfigs_602638 = ref object of OpenApiRestCall_601389
proc url_ListProvisionedConcurrencyConfigs_602640(protocol: Scheme; host: string;
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

proc validate_ListProvisionedConcurrencyConfigs_602639(path: JsonNode;
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
  var valid_602641 = path.getOrDefault("FunctionName")
  valid_602641 = validateParameter(valid_602641, JString, required = true,
                                 default = nil)
  if valid_602641 != nil:
    section.add "FunctionName", valid_602641
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: JInt
  ##           : Specify a number to limit the number of configurations returned.
  ##   List: JString (required)
  section = newJObject()
  var valid_602642 = query.getOrDefault("Marker")
  valid_602642 = validateParameter(valid_602642, JString, required = false,
                                 default = nil)
  if valid_602642 != nil:
    section.add "Marker", valid_602642
  var valid_602643 = query.getOrDefault("MaxItems")
  valid_602643 = validateParameter(valid_602643, JInt, required = false, default = nil)
  if valid_602643 != nil:
    section.add "MaxItems", valid_602643
  assert query != nil, "query argument is necessary due to required `List` field"
  var valid_602644 = query.getOrDefault("List")
  valid_602644 = validateParameter(valid_602644, JString, required = true,
                                 default = newJString("ALL"))
  if valid_602644 != nil:
    section.add "List", valid_602644
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
  var valid_602645 = header.getOrDefault("X-Amz-Signature")
  valid_602645 = validateParameter(valid_602645, JString, required = false,
                                 default = nil)
  if valid_602645 != nil:
    section.add "X-Amz-Signature", valid_602645
  var valid_602646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602646 = validateParameter(valid_602646, JString, required = false,
                                 default = nil)
  if valid_602646 != nil:
    section.add "X-Amz-Content-Sha256", valid_602646
  var valid_602647 = header.getOrDefault("X-Amz-Date")
  valid_602647 = validateParameter(valid_602647, JString, required = false,
                                 default = nil)
  if valid_602647 != nil:
    section.add "X-Amz-Date", valid_602647
  var valid_602648 = header.getOrDefault("X-Amz-Credential")
  valid_602648 = validateParameter(valid_602648, JString, required = false,
                                 default = nil)
  if valid_602648 != nil:
    section.add "X-Amz-Credential", valid_602648
  var valid_602649 = header.getOrDefault("X-Amz-Security-Token")
  valid_602649 = validateParameter(valid_602649, JString, required = false,
                                 default = nil)
  if valid_602649 != nil:
    section.add "X-Amz-Security-Token", valid_602649
  var valid_602650 = header.getOrDefault("X-Amz-Algorithm")
  valid_602650 = validateParameter(valid_602650, JString, required = false,
                                 default = nil)
  if valid_602650 != nil:
    section.add "X-Amz-Algorithm", valid_602650
  var valid_602651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602651 = validateParameter(valid_602651, JString, required = false,
                                 default = nil)
  if valid_602651 != nil:
    section.add "X-Amz-SignedHeaders", valid_602651
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602652: Call_ListProvisionedConcurrencyConfigs_602638;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves a list of provisioned concurrency configurations for a function.
  ## 
  let valid = call_602652.validator(path, query, header, formData, body)
  let scheme = call_602652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602652.url(scheme.get, call_602652.host, call_602652.base,
                         call_602652.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602652, url, valid)

proc call*(call_602653: Call_ListProvisionedConcurrencyConfigs_602638;
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
  var path_602654 = newJObject()
  var query_602655 = newJObject()
  add(query_602655, "Marker", newJString(Marker))
  add(path_602654, "FunctionName", newJString(FunctionName))
  add(query_602655, "MaxItems", newJInt(MaxItems))
  add(query_602655, "List", newJString(List))
  result = call_602653.call(path_602654, query_602655, nil, nil, nil)

var listProvisionedConcurrencyConfigs* = Call_ListProvisionedConcurrencyConfigs_602638(
    name: "listProvisionedConcurrencyConfigs", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com", route: "/2019-09-30/functions/{FunctionName}/provisioned-concurrency#List=ALL",
    validator: validate_ListProvisionedConcurrencyConfigs_602639, base: "/",
    url: url_ListProvisionedConcurrencyConfigs_602640,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602670 = ref object of OpenApiRestCall_601389
proc url_TagResource_602672(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_602671(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602673 = path.getOrDefault("ARN")
  valid_602673 = validateParameter(valid_602673, JString, required = true,
                                 default = nil)
  if valid_602673 != nil:
    section.add "ARN", valid_602673
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
  var valid_602674 = header.getOrDefault("X-Amz-Signature")
  valid_602674 = validateParameter(valid_602674, JString, required = false,
                                 default = nil)
  if valid_602674 != nil:
    section.add "X-Amz-Signature", valid_602674
  var valid_602675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602675 = validateParameter(valid_602675, JString, required = false,
                                 default = nil)
  if valid_602675 != nil:
    section.add "X-Amz-Content-Sha256", valid_602675
  var valid_602676 = header.getOrDefault("X-Amz-Date")
  valid_602676 = validateParameter(valid_602676, JString, required = false,
                                 default = nil)
  if valid_602676 != nil:
    section.add "X-Amz-Date", valid_602676
  var valid_602677 = header.getOrDefault("X-Amz-Credential")
  valid_602677 = validateParameter(valid_602677, JString, required = false,
                                 default = nil)
  if valid_602677 != nil:
    section.add "X-Amz-Credential", valid_602677
  var valid_602678 = header.getOrDefault("X-Amz-Security-Token")
  valid_602678 = validateParameter(valid_602678, JString, required = false,
                                 default = nil)
  if valid_602678 != nil:
    section.add "X-Amz-Security-Token", valid_602678
  var valid_602679 = header.getOrDefault("X-Amz-Algorithm")
  valid_602679 = validateParameter(valid_602679, JString, required = false,
                                 default = nil)
  if valid_602679 != nil:
    section.add "X-Amz-Algorithm", valid_602679
  var valid_602680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602680 = validateParameter(valid_602680, JString, required = false,
                                 default = nil)
  if valid_602680 != nil:
    section.add "X-Amz-SignedHeaders", valid_602680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602682: Call_TagResource_602670; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> to a function.
  ## 
  let valid = call_602682.validator(path, query, header, formData, body)
  let scheme = call_602682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602682.url(scheme.get, call_602682.host, call_602682.base,
                         call_602682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602682, url, valid)

proc call*(call_602683: Call_TagResource_602670; ARN: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> to a function.
  ##   ARN: string (required)
  ##      : The function's Amazon Resource Name (ARN).
  ##   body: JObject (required)
  var path_602684 = newJObject()
  var body_602685 = newJObject()
  add(path_602684, "ARN", newJString(ARN))
  if body != nil:
    body_602685 = body
  result = call_602683.call(path_602684, nil, nil, nil, body_602685)

var tagResource* = Call_TagResource_602670(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "lambda.amazonaws.com",
                                        route: "/2017-03-31/tags/{ARN}",
                                        validator: validate_TagResource_602671,
                                        base: "/", url: url_TagResource_602672,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_602656 = ref object of OpenApiRestCall_601389
proc url_ListTags_602658(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListTags_602657(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602659 = path.getOrDefault("ARN")
  valid_602659 = validateParameter(valid_602659, JString, required = true,
                                 default = nil)
  if valid_602659 != nil:
    section.add "ARN", valid_602659
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
  var valid_602660 = header.getOrDefault("X-Amz-Signature")
  valid_602660 = validateParameter(valid_602660, JString, required = false,
                                 default = nil)
  if valid_602660 != nil:
    section.add "X-Amz-Signature", valid_602660
  var valid_602661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602661 = validateParameter(valid_602661, JString, required = false,
                                 default = nil)
  if valid_602661 != nil:
    section.add "X-Amz-Content-Sha256", valid_602661
  var valid_602662 = header.getOrDefault("X-Amz-Date")
  valid_602662 = validateParameter(valid_602662, JString, required = false,
                                 default = nil)
  if valid_602662 != nil:
    section.add "X-Amz-Date", valid_602662
  var valid_602663 = header.getOrDefault("X-Amz-Credential")
  valid_602663 = validateParameter(valid_602663, JString, required = false,
                                 default = nil)
  if valid_602663 != nil:
    section.add "X-Amz-Credential", valid_602663
  var valid_602664 = header.getOrDefault("X-Amz-Security-Token")
  valid_602664 = validateParameter(valid_602664, JString, required = false,
                                 default = nil)
  if valid_602664 != nil:
    section.add "X-Amz-Security-Token", valid_602664
  var valid_602665 = header.getOrDefault("X-Amz-Algorithm")
  valid_602665 = validateParameter(valid_602665, JString, required = false,
                                 default = nil)
  if valid_602665 != nil:
    section.add "X-Amz-Algorithm", valid_602665
  var valid_602666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602666 = validateParameter(valid_602666, JString, required = false,
                                 default = nil)
  if valid_602666 != nil:
    section.add "X-Amz-SignedHeaders", valid_602666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602667: Call_ListTags_602656; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a function's <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a>. You can also view tags with <a>GetFunction</a>.
  ## 
  let valid = call_602667.validator(path, query, header, formData, body)
  let scheme = call_602667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602667.url(scheme.get, call_602667.host, call_602667.base,
                         call_602667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602667, url, valid)

proc call*(call_602668: Call_ListTags_602656; ARN: string): Recallable =
  ## listTags
  ## Returns a function's <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a>. You can also view tags with <a>GetFunction</a>.
  ##   ARN: string (required)
  ##      : The function's Amazon Resource Name (ARN).
  var path_602669 = newJObject()
  add(path_602669, "ARN", newJString(ARN))
  result = call_602668.call(path_602669, nil, nil, nil, nil)

var listTags* = Call_ListTags_602656(name: "listTags", meth: HttpMethod.HttpGet,
                                  host: "lambda.amazonaws.com",
                                  route: "/2017-03-31/tags/{ARN}",
                                  validator: validate_ListTags_602657, base: "/",
                                  url: url_ListTags_602658,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PublishVersion_602703 = ref object of OpenApiRestCall_601389
proc url_PublishVersion_602705(protocol: Scheme; host: string; base: string;
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

proc validate_PublishVersion_602704(path: JsonNode; query: JsonNode;
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
  var valid_602706 = path.getOrDefault("FunctionName")
  valid_602706 = validateParameter(valid_602706, JString, required = true,
                                 default = nil)
  if valid_602706 != nil:
    section.add "FunctionName", valid_602706
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
  var valid_602707 = header.getOrDefault("X-Amz-Signature")
  valid_602707 = validateParameter(valid_602707, JString, required = false,
                                 default = nil)
  if valid_602707 != nil:
    section.add "X-Amz-Signature", valid_602707
  var valid_602708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602708 = validateParameter(valid_602708, JString, required = false,
                                 default = nil)
  if valid_602708 != nil:
    section.add "X-Amz-Content-Sha256", valid_602708
  var valid_602709 = header.getOrDefault("X-Amz-Date")
  valid_602709 = validateParameter(valid_602709, JString, required = false,
                                 default = nil)
  if valid_602709 != nil:
    section.add "X-Amz-Date", valid_602709
  var valid_602710 = header.getOrDefault("X-Amz-Credential")
  valid_602710 = validateParameter(valid_602710, JString, required = false,
                                 default = nil)
  if valid_602710 != nil:
    section.add "X-Amz-Credential", valid_602710
  var valid_602711 = header.getOrDefault("X-Amz-Security-Token")
  valid_602711 = validateParameter(valid_602711, JString, required = false,
                                 default = nil)
  if valid_602711 != nil:
    section.add "X-Amz-Security-Token", valid_602711
  var valid_602712 = header.getOrDefault("X-Amz-Algorithm")
  valid_602712 = validateParameter(valid_602712, JString, required = false,
                                 default = nil)
  if valid_602712 != nil:
    section.add "X-Amz-Algorithm", valid_602712
  var valid_602713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602713 = validateParameter(valid_602713, JString, required = false,
                                 default = nil)
  if valid_602713 != nil:
    section.add "X-Amz-SignedHeaders", valid_602713
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602715: Call_PublishVersion_602703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">version</a> from the current code and configuration of a function. Use versions to create a snapshot of your function code and configuration that doesn't change.</p> <p>AWS Lambda doesn't publish a version if the function's configuration and code haven't changed since the last version. Use <a>UpdateFunctionCode</a> or <a>UpdateFunctionConfiguration</a> to update the function before publishing a version.</p> <p>Clients can invoke versions directly or with an alias. To create an alias, use <a>CreateAlias</a>.</p>
  ## 
  let valid = call_602715.validator(path, query, header, formData, body)
  let scheme = call_602715.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602715.url(scheme.get, call_602715.host, call_602715.base,
                         call_602715.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602715, url, valid)

proc call*(call_602716: Call_PublishVersion_602703; FunctionName: string;
          body: JsonNode): Recallable =
  ## publishVersion
  ## <p>Creates a <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">version</a> from the current code and configuration of a function. Use versions to create a snapshot of your function code and configuration that doesn't change.</p> <p>AWS Lambda doesn't publish a version if the function's configuration and code haven't changed since the last version. Use <a>UpdateFunctionCode</a> or <a>UpdateFunctionConfiguration</a> to update the function before publishing a version.</p> <p>Clients can invoke versions directly or with an alias. To create an alias, use <a>CreateAlias</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_602717 = newJObject()
  var body_602718 = newJObject()
  add(path_602717, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_602718 = body
  result = call_602716.call(path_602717, nil, nil, nil, body_602718)

var publishVersion* = Call_PublishVersion_602703(name: "publishVersion",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/versions",
    validator: validate_PublishVersion_602704, base: "/", url: url_PublishVersion_602705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVersionsByFunction_602686 = ref object of OpenApiRestCall_601389
proc url_ListVersionsByFunction_602688(protocol: Scheme; host: string; base: string;
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

proc validate_ListVersionsByFunction_602687(path: JsonNode; query: JsonNode;
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
  var valid_602689 = path.getOrDefault("FunctionName")
  valid_602689 = validateParameter(valid_602689, JString, required = true,
                                 default = nil)
  if valid_602689 != nil:
    section.add "FunctionName", valid_602689
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: JInt
  ##           : Limit the number of versions that are returned.
  section = newJObject()
  var valid_602690 = query.getOrDefault("Marker")
  valid_602690 = validateParameter(valid_602690, JString, required = false,
                                 default = nil)
  if valid_602690 != nil:
    section.add "Marker", valid_602690
  var valid_602691 = query.getOrDefault("MaxItems")
  valid_602691 = validateParameter(valid_602691, JInt, required = false, default = nil)
  if valid_602691 != nil:
    section.add "MaxItems", valid_602691
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
  var valid_602692 = header.getOrDefault("X-Amz-Signature")
  valid_602692 = validateParameter(valid_602692, JString, required = false,
                                 default = nil)
  if valid_602692 != nil:
    section.add "X-Amz-Signature", valid_602692
  var valid_602693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602693 = validateParameter(valid_602693, JString, required = false,
                                 default = nil)
  if valid_602693 != nil:
    section.add "X-Amz-Content-Sha256", valid_602693
  var valid_602694 = header.getOrDefault("X-Amz-Date")
  valid_602694 = validateParameter(valid_602694, JString, required = false,
                                 default = nil)
  if valid_602694 != nil:
    section.add "X-Amz-Date", valid_602694
  var valid_602695 = header.getOrDefault("X-Amz-Credential")
  valid_602695 = validateParameter(valid_602695, JString, required = false,
                                 default = nil)
  if valid_602695 != nil:
    section.add "X-Amz-Credential", valid_602695
  var valid_602696 = header.getOrDefault("X-Amz-Security-Token")
  valid_602696 = validateParameter(valid_602696, JString, required = false,
                                 default = nil)
  if valid_602696 != nil:
    section.add "X-Amz-Security-Token", valid_602696
  var valid_602697 = header.getOrDefault("X-Amz-Algorithm")
  valid_602697 = validateParameter(valid_602697, JString, required = false,
                                 default = nil)
  if valid_602697 != nil:
    section.add "X-Amz-Algorithm", valid_602697
  var valid_602698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602698 = validateParameter(valid_602698, JString, required = false,
                                 default = nil)
  if valid_602698 != nil:
    section.add "X-Amz-SignedHeaders", valid_602698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602699: Call_ListVersionsByFunction_602686; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">versions</a>, with the version-specific configuration of each. 
  ## 
  let valid = call_602699.validator(path, query, header, formData, body)
  let scheme = call_602699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602699.url(scheme.get, call_602699.host, call_602699.base,
                         call_602699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602699, url, valid)

proc call*(call_602700: Call_ListVersionsByFunction_602686; FunctionName: string;
          Marker: string = ""; MaxItems: int = 0): Recallable =
  ## listVersionsByFunction
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">versions</a>, with the version-specific configuration of each. 
  ##   Marker: string
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   MaxItems: int
  ##           : Limit the number of versions that are returned.
  var path_602701 = newJObject()
  var query_602702 = newJObject()
  add(query_602702, "Marker", newJString(Marker))
  add(path_602701, "FunctionName", newJString(FunctionName))
  add(query_602702, "MaxItems", newJInt(MaxItems))
  result = call_602700.call(path_602701, query_602702, nil, nil, nil)

var listVersionsByFunction* = Call_ListVersionsByFunction_602686(
    name: "listVersionsByFunction", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/versions",
    validator: validate_ListVersionsByFunction_602687, base: "/",
    url: url_ListVersionsByFunction_602688, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveLayerVersionPermission_602719 = ref object of OpenApiRestCall_601389
proc url_RemoveLayerVersionPermission_602721(protocol: Scheme; host: string;
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

proc validate_RemoveLayerVersionPermission_602720(path: JsonNode; query: JsonNode;
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
  var valid_602722 = path.getOrDefault("VersionNumber")
  valid_602722 = validateParameter(valid_602722, JInt, required = true, default = nil)
  if valid_602722 != nil:
    section.add "VersionNumber", valid_602722
  var valid_602723 = path.getOrDefault("StatementId")
  valid_602723 = validateParameter(valid_602723, JString, required = true,
                                 default = nil)
  if valid_602723 != nil:
    section.add "StatementId", valid_602723
  var valid_602724 = path.getOrDefault("LayerName")
  valid_602724 = validateParameter(valid_602724, JString, required = true,
                                 default = nil)
  if valid_602724 != nil:
    section.add "LayerName", valid_602724
  result.add "path", section
  ## parameters in `query` object:
  ##   RevisionId: JString
  ##             : Only update the policy if the revision ID matches the ID specified. Use this option to avoid modifying a policy that has changed since you last read it.
  section = newJObject()
  var valid_602725 = query.getOrDefault("RevisionId")
  valid_602725 = validateParameter(valid_602725, JString, required = false,
                                 default = nil)
  if valid_602725 != nil:
    section.add "RevisionId", valid_602725
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
  var valid_602726 = header.getOrDefault("X-Amz-Signature")
  valid_602726 = validateParameter(valid_602726, JString, required = false,
                                 default = nil)
  if valid_602726 != nil:
    section.add "X-Amz-Signature", valid_602726
  var valid_602727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602727 = validateParameter(valid_602727, JString, required = false,
                                 default = nil)
  if valid_602727 != nil:
    section.add "X-Amz-Content-Sha256", valid_602727
  var valid_602728 = header.getOrDefault("X-Amz-Date")
  valid_602728 = validateParameter(valid_602728, JString, required = false,
                                 default = nil)
  if valid_602728 != nil:
    section.add "X-Amz-Date", valid_602728
  var valid_602729 = header.getOrDefault("X-Amz-Credential")
  valid_602729 = validateParameter(valid_602729, JString, required = false,
                                 default = nil)
  if valid_602729 != nil:
    section.add "X-Amz-Credential", valid_602729
  var valid_602730 = header.getOrDefault("X-Amz-Security-Token")
  valid_602730 = validateParameter(valid_602730, JString, required = false,
                                 default = nil)
  if valid_602730 != nil:
    section.add "X-Amz-Security-Token", valid_602730
  var valid_602731 = header.getOrDefault("X-Amz-Algorithm")
  valid_602731 = validateParameter(valid_602731, JString, required = false,
                                 default = nil)
  if valid_602731 != nil:
    section.add "X-Amz-Algorithm", valid_602731
  var valid_602732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602732 = validateParameter(valid_602732, JString, required = false,
                                 default = nil)
  if valid_602732 != nil:
    section.add "X-Amz-SignedHeaders", valid_602732
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602733: Call_RemoveLayerVersionPermission_602719; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a statement from the permissions policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ## 
  let valid = call_602733.validator(path, query, header, formData, body)
  let scheme = call_602733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602733.url(scheme.get, call_602733.host, call_602733.base,
                         call_602733.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602733, url, valid)

proc call*(call_602734: Call_RemoveLayerVersionPermission_602719;
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
  var path_602735 = newJObject()
  var query_602736 = newJObject()
  add(query_602736, "RevisionId", newJString(RevisionId))
  add(path_602735, "VersionNumber", newJInt(VersionNumber))
  add(path_602735, "StatementId", newJString(StatementId))
  add(path_602735, "LayerName", newJString(LayerName))
  result = call_602734.call(path_602735, query_602736, nil, nil, nil)

var removeLayerVersionPermission* = Call_RemoveLayerVersionPermission_602719(
    name: "removeLayerVersionPermission", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com", route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy/{StatementId}",
    validator: validate_RemoveLayerVersionPermission_602720, base: "/",
    url: url_RemoveLayerVersionPermission_602721,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemovePermission_602737 = ref object of OpenApiRestCall_601389
proc url_RemovePermission_602739(protocol: Scheme; host: string; base: string;
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

proc validate_RemovePermission_602738(path: JsonNode; query: JsonNode;
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
  var valid_602740 = path.getOrDefault("FunctionName")
  valid_602740 = validateParameter(valid_602740, JString, required = true,
                                 default = nil)
  if valid_602740 != nil:
    section.add "FunctionName", valid_602740
  var valid_602741 = path.getOrDefault("StatementId")
  valid_602741 = validateParameter(valid_602741, JString, required = true,
                                 default = nil)
  if valid_602741 != nil:
    section.add "StatementId", valid_602741
  result.add "path", section
  ## parameters in `query` object:
  ##   RevisionId: JString
  ##             : Only update the policy if the revision ID matches the ID that's specified. Use this option to avoid modifying a policy that has changed since you last read it.
  ##   Qualifier: JString
  ##            : Specify a version or alias to remove permissions from a published version of the function.
  section = newJObject()
  var valid_602742 = query.getOrDefault("RevisionId")
  valid_602742 = validateParameter(valid_602742, JString, required = false,
                                 default = nil)
  if valid_602742 != nil:
    section.add "RevisionId", valid_602742
  var valid_602743 = query.getOrDefault("Qualifier")
  valid_602743 = validateParameter(valid_602743, JString, required = false,
                                 default = nil)
  if valid_602743 != nil:
    section.add "Qualifier", valid_602743
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
  var valid_602744 = header.getOrDefault("X-Amz-Signature")
  valid_602744 = validateParameter(valid_602744, JString, required = false,
                                 default = nil)
  if valid_602744 != nil:
    section.add "X-Amz-Signature", valid_602744
  var valid_602745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602745 = validateParameter(valid_602745, JString, required = false,
                                 default = nil)
  if valid_602745 != nil:
    section.add "X-Amz-Content-Sha256", valid_602745
  var valid_602746 = header.getOrDefault("X-Amz-Date")
  valid_602746 = validateParameter(valid_602746, JString, required = false,
                                 default = nil)
  if valid_602746 != nil:
    section.add "X-Amz-Date", valid_602746
  var valid_602747 = header.getOrDefault("X-Amz-Credential")
  valid_602747 = validateParameter(valid_602747, JString, required = false,
                                 default = nil)
  if valid_602747 != nil:
    section.add "X-Amz-Credential", valid_602747
  var valid_602748 = header.getOrDefault("X-Amz-Security-Token")
  valid_602748 = validateParameter(valid_602748, JString, required = false,
                                 default = nil)
  if valid_602748 != nil:
    section.add "X-Amz-Security-Token", valid_602748
  var valid_602749 = header.getOrDefault("X-Amz-Algorithm")
  valid_602749 = validateParameter(valid_602749, JString, required = false,
                                 default = nil)
  if valid_602749 != nil:
    section.add "X-Amz-Algorithm", valid_602749
  var valid_602750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602750 = validateParameter(valid_602750, JString, required = false,
                                 default = nil)
  if valid_602750 != nil:
    section.add "X-Amz-SignedHeaders", valid_602750
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602751: Call_RemovePermission_602737; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Revokes function-use permission from an AWS service or another account. You can get the ID of the statement from the output of <a>GetPolicy</a>.
  ## 
  let valid = call_602751.validator(path, query, header, formData, body)
  let scheme = call_602751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602751.url(scheme.get, call_602751.host, call_602751.base,
                         call_602751.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602751, url, valid)

proc call*(call_602752: Call_RemovePermission_602737; FunctionName: string;
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
  var path_602753 = newJObject()
  var query_602754 = newJObject()
  add(query_602754, "RevisionId", newJString(RevisionId))
  add(path_602753, "FunctionName", newJString(FunctionName))
  add(path_602753, "StatementId", newJString(StatementId))
  add(query_602754, "Qualifier", newJString(Qualifier))
  result = call_602752.call(path_602753, query_602754, nil, nil, nil)

var removePermission* = Call_RemovePermission_602737(name: "removePermission",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/policy/{StatementId}",
    validator: validate_RemovePermission_602738, base: "/",
    url: url_RemovePermission_602739, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_602755 = ref object of OpenApiRestCall_601389
proc url_UntagResource_602757(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_602756(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602758 = path.getOrDefault("ARN")
  valid_602758 = validateParameter(valid_602758, JString, required = true,
                                 default = nil)
  if valid_602758 != nil:
    section.add "ARN", valid_602758
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A list of tag keys to remove from the function.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_602759 = query.getOrDefault("tagKeys")
  valid_602759 = validateParameter(valid_602759, JArray, required = true, default = nil)
  if valid_602759 != nil:
    section.add "tagKeys", valid_602759
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
  var valid_602760 = header.getOrDefault("X-Amz-Signature")
  valid_602760 = validateParameter(valid_602760, JString, required = false,
                                 default = nil)
  if valid_602760 != nil:
    section.add "X-Amz-Signature", valid_602760
  var valid_602761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602761 = validateParameter(valid_602761, JString, required = false,
                                 default = nil)
  if valid_602761 != nil:
    section.add "X-Amz-Content-Sha256", valid_602761
  var valid_602762 = header.getOrDefault("X-Amz-Date")
  valid_602762 = validateParameter(valid_602762, JString, required = false,
                                 default = nil)
  if valid_602762 != nil:
    section.add "X-Amz-Date", valid_602762
  var valid_602763 = header.getOrDefault("X-Amz-Credential")
  valid_602763 = validateParameter(valid_602763, JString, required = false,
                                 default = nil)
  if valid_602763 != nil:
    section.add "X-Amz-Credential", valid_602763
  var valid_602764 = header.getOrDefault("X-Amz-Security-Token")
  valid_602764 = validateParameter(valid_602764, JString, required = false,
                                 default = nil)
  if valid_602764 != nil:
    section.add "X-Amz-Security-Token", valid_602764
  var valid_602765 = header.getOrDefault("X-Amz-Algorithm")
  valid_602765 = validateParameter(valid_602765, JString, required = false,
                                 default = nil)
  if valid_602765 != nil:
    section.add "X-Amz-Algorithm", valid_602765
  var valid_602766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602766 = validateParameter(valid_602766, JString, required = false,
                                 default = nil)
  if valid_602766 != nil:
    section.add "X-Amz-SignedHeaders", valid_602766
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602767: Call_UntagResource_602755; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> from a function.
  ## 
  let valid = call_602767.validator(path, query, header, formData, body)
  let scheme = call_602767.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602767.url(scheme.get, call_602767.host, call_602767.base,
                         call_602767.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602767, url, valid)

proc call*(call_602768: Call_UntagResource_602755; ARN: string; tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> from a function.
  ##   ARN: string (required)
  ##      : The function's Amazon Resource Name (ARN).
  ##   tagKeys: JArray (required)
  ##          : A list of tag keys to remove from the function.
  var path_602769 = newJObject()
  var query_602770 = newJObject()
  add(path_602769, "ARN", newJString(ARN))
  if tagKeys != nil:
    query_602770.add "tagKeys", tagKeys
  result = call_602768.call(path_602769, query_602770, nil, nil, nil)

var untagResource* = Call_UntagResource_602755(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2017-03-31/tags/{ARN}#tagKeys", validator: validate_UntagResource_602756,
    base: "/", url: url_UntagResource_602757, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionCode_602771 = ref object of OpenApiRestCall_601389
proc url_UpdateFunctionCode_602773(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFunctionCode_602772(path: JsonNode; query: JsonNode;
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
  var valid_602774 = path.getOrDefault("FunctionName")
  valid_602774 = validateParameter(valid_602774, JString, required = true,
                                 default = nil)
  if valid_602774 != nil:
    section.add "FunctionName", valid_602774
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
  var valid_602775 = header.getOrDefault("X-Amz-Signature")
  valid_602775 = validateParameter(valid_602775, JString, required = false,
                                 default = nil)
  if valid_602775 != nil:
    section.add "X-Amz-Signature", valid_602775
  var valid_602776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602776 = validateParameter(valid_602776, JString, required = false,
                                 default = nil)
  if valid_602776 != nil:
    section.add "X-Amz-Content-Sha256", valid_602776
  var valid_602777 = header.getOrDefault("X-Amz-Date")
  valid_602777 = validateParameter(valid_602777, JString, required = false,
                                 default = nil)
  if valid_602777 != nil:
    section.add "X-Amz-Date", valid_602777
  var valid_602778 = header.getOrDefault("X-Amz-Credential")
  valid_602778 = validateParameter(valid_602778, JString, required = false,
                                 default = nil)
  if valid_602778 != nil:
    section.add "X-Amz-Credential", valid_602778
  var valid_602779 = header.getOrDefault("X-Amz-Security-Token")
  valid_602779 = validateParameter(valid_602779, JString, required = false,
                                 default = nil)
  if valid_602779 != nil:
    section.add "X-Amz-Security-Token", valid_602779
  var valid_602780 = header.getOrDefault("X-Amz-Algorithm")
  valid_602780 = validateParameter(valid_602780, JString, required = false,
                                 default = nil)
  if valid_602780 != nil:
    section.add "X-Amz-Algorithm", valid_602780
  var valid_602781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602781 = validateParameter(valid_602781, JString, required = false,
                                 default = nil)
  if valid_602781 != nil:
    section.add "X-Amz-SignedHeaders", valid_602781
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602783: Call_UpdateFunctionCode_602771; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a Lambda function's code.</p> <p>The function's code is locked when you publish a version. You can't modify the code of a published version, only the unpublished version.</p>
  ## 
  let valid = call_602783.validator(path, query, header, formData, body)
  let scheme = call_602783.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602783.url(scheme.get, call_602783.host, call_602783.base,
                         call_602783.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602783, url, valid)

proc call*(call_602784: Call_UpdateFunctionCode_602771; FunctionName: string;
          body: JsonNode): Recallable =
  ## updateFunctionCode
  ## <p>Updates a Lambda function's code.</p> <p>The function's code is locked when you publish a version. You can't modify the code of a published version, only the unpublished version.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_602785 = newJObject()
  var body_602786 = newJObject()
  add(path_602785, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_602786 = body
  result = call_602784.call(path_602785, nil, nil, nil, body_602786)

var updateFunctionCode* = Call_UpdateFunctionCode_602771(
    name: "updateFunctionCode", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/code",
    validator: validate_UpdateFunctionCode_602772, base: "/",
    url: url_UpdateFunctionCode_602773, schemes: {Scheme.Https, Scheme.Http})
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
