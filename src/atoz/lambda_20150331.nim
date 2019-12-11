
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

  OpenApiRestCall_597389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_597389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_597389): Option[Scheme] {.used.} =
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
  Call_AddLayerVersionPermission_597998 = ref object of OpenApiRestCall_597389
proc url_AddLayerVersionPermission_598000(protocol: Scheme; host: string;
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

proc validate_AddLayerVersionPermission_597999(path: JsonNode; query: JsonNode;
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
  var valid_598001 = path.getOrDefault("VersionNumber")
  valid_598001 = validateParameter(valid_598001, JInt, required = true, default = nil)
  if valid_598001 != nil:
    section.add "VersionNumber", valid_598001
  var valid_598002 = path.getOrDefault("LayerName")
  valid_598002 = validateParameter(valid_598002, JString, required = true,
                                 default = nil)
  if valid_598002 != nil:
    section.add "LayerName", valid_598002
  result.add "path", section
  ## parameters in `query` object:
  ##   RevisionId: JString
  ##             : Only update the policy if the revision ID matches the ID specified. Use this option to avoid modifying a policy that has changed since you last read it.
  section = newJObject()
  var valid_598003 = query.getOrDefault("RevisionId")
  valid_598003 = validateParameter(valid_598003, JString, required = false,
                                 default = nil)
  if valid_598003 != nil:
    section.add "RevisionId", valid_598003
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
  var valid_598004 = header.getOrDefault("X-Amz-Signature")
  valid_598004 = validateParameter(valid_598004, JString, required = false,
                                 default = nil)
  if valid_598004 != nil:
    section.add "X-Amz-Signature", valid_598004
  var valid_598005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598005 = validateParameter(valid_598005, JString, required = false,
                                 default = nil)
  if valid_598005 != nil:
    section.add "X-Amz-Content-Sha256", valid_598005
  var valid_598006 = header.getOrDefault("X-Amz-Date")
  valid_598006 = validateParameter(valid_598006, JString, required = false,
                                 default = nil)
  if valid_598006 != nil:
    section.add "X-Amz-Date", valid_598006
  var valid_598007 = header.getOrDefault("X-Amz-Credential")
  valid_598007 = validateParameter(valid_598007, JString, required = false,
                                 default = nil)
  if valid_598007 != nil:
    section.add "X-Amz-Credential", valid_598007
  var valid_598008 = header.getOrDefault("X-Amz-Security-Token")
  valid_598008 = validateParameter(valid_598008, JString, required = false,
                                 default = nil)
  if valid_598008 != nil:
    section.add "X-Amz-Security-Token", valid_598008
  var valid_598009 = header.getOrDefault("X-Amz-Algorithm")
  valid_598009 = validateParameter(valid_598009, JString, required = false,
                                 default = nil)
  if valid_598009 != nil:
    section.add "X-Amz-Algorithm", valid_598009
  var valid_598010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598010 = validateParameter(valid_598010, JString, required = false,
                                 default = nil)
  if valid_598010 != nil:
    section.add "X-Amz-SignedHeaders", valid_598010
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598012: Call_AddLayerVersionPermission_597998; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds permissions to the resource-based policy of a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Use this action to grant layer usage permission to other accounts. You can grant permission to a single account, all AWS accounts, or all accounts in an organization.</p> <p>To revoke permission, call <a>RemoveLayerVersionPermission</a> with the statement ID that you specified when you added it.</p>
  ## 
  let valid = call_598012.validator(path, query, header, formData, body)
  let scheme = call_598012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598012.url(scheme.get, call_598012.host, call_598012.base,
                         call_598012.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598012, url, valid)

proc call*(call_598013: Call_AddLayerVersionPermission_597998; VersionNumber: int;
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
  var path_598014 = newJObject()
  var query_598015 = newJObject()
  var body_598016 = newJObject()
  add(query_598015, "RevisionId", newJString(RevisionId))
  add(path_598014, "VersionNumber", newJInt(VersionNumber))
  add(path_598014, "LayerName", newJString(LayerName))
  if body != nil:
    body_598016 = body
  result = call_598013.call(path_598014, query_598015, nil, nil, body_598016)

var addLayerVersionPermission* = Call_AddLayerVersionPermission_597998(
    name: "addLayerVersionPermission", meth: HttpMethod.HttpPost,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy",
    validator: validate_AddLayerVersionPermission_597999, base: "/",
    url: url_AddLayerVersionPermission_598000,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLayerVersionPolicy_597727 = ref object of OpenApiRestCall_597389
proc url_GetLayerVersionPolicy_597729(protocol: Scheme; host: string; base: string;
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

proc validate_GetLayerVersionPolicy_597728(path: JsonNode; query: JsonNode;
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
  var valid_597855 = path.getOrDefault("VersionNumber")
  valid_597855 = validateParameter(valid_597855, JInt, required = true, default = nil)
  if valid_597855 != nil:
    section.add "VersionNumber", valid_597855
  var valid_597856 = path.getOrDefault("LayerName")
  valid_597856 = validateParameter(valid_597856, JString, required = true,
                                 default = nil)
  if valid_597856 != nil:
    section.add "LayerName", valid_597856
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
  var valid_597857 = header.getOrDefault("X-Amz-Signature")
  valid_597857 = validateParameter(valid_597857, JString, required = false,
                                 default = nil)
  if valid_597857 != nil:
    section.add "X-Amz-Signature", valid_597857
  var valid_597858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597858 = validateParameter(valid_597858, JString, required = false,
                                 default = nil)
  if valid_597858 != nil:
    section.add "X-Amz-Content-Sha256", valid_597858
  var valid_597859 = header.getOrDefault("X-Amz-Date")
  valid_597859 = validateParameter(valid_597859, JString, required = false,
                                 default = nil)
  if valid_597859 != nil:
    section.add "X-Amz-Date", valid_597859
  var valid_597860 = header.getOrDefault("X-Amz-Credential")
  valid_597860 = validateParameter(valid_597860, JString, required = false,
                                 default = nil)
  if valid_597860 != nil:
    section.add "X-Amz-Credential", valid_597860
  var valid_597861 = header.getOrDefault("X-Amz-Security-Token")
  valid_597861 = validateParameter(valid_597861, JString, required = false,
                                 default = nil)
  if valid_597861 != nil:
    section.add "X-Amz-Security-Token", valid_597861
  var valid_597862 = header.getOrDefault("X-Amz-Algorithm")
  valid_597862 = validateParameter(valid_597862, JString, required = false,
                                 default = nil)
  if valid_597862 != nil:
    section.add "X-Amz-Algorithm", valid_597862
  var valid_597863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597863 = validateParameter(valid_597863, JString, required = false,
                                 default = nil)
  if valid_597863 != nil:
    section.add "X-Amz-SignedHeaders", valid_597863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_597886: Call_GetLayerVersionPolicy_597727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the permission policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ## 
  let valid = call_597886.validator(path, query, header, formData, body)
  let scheme = call_597886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597886.url(scheme.get, call_597886.host, call_597886.base,
                         call_597886.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597886, url, valid)

proc call*(call_597957: Call_GetLayerVersionPolicy_597727; VersionNumber: int;
          LayerName: string): Recallable =
  ## getLayerVersionPolicy
  ## Returns the permission policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ##   VersionNumber: int (required)
  ##                : The version number.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  var path_597958 = newJObject()
  add(path_597958, "VersionNumber", newJInt(VersionNumber))
  add(path_597958, "LayerName", newJString(LayerName))
  result = call_597957.call(path_597958, nil, nil, nil, nil)

var getLayerVersionPolicy* = Call_GetLayerVersionPolicy_597727(
    name: "getLayerVersionPolicy", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy",
    validator: validate_GetLayerVersionPolicy_597728, base: "/",
    url: url_GetLayerVersionPolicy_597729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddPermission_598033 = ref object of OpenApiRestCall_597389
proc url_AddPermission_598035(protocol: Scheme; host: string; base: string;
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

proc validate_AddPermission_598034(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598036 = path.getOrDefault("FunctionName")
  valid_598036 = validateParameter(valid_598036, JString, required = true,
                                 default = nil)
  if valid_598036 != nil:
    section.add "FunctionName", valid_598036
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to add permissions to a published version of the function.
  section = newJObject()
  var valid_598037 = query.getOrDefault("Qualifier")
  valid_598037 = validateParameter(valid_598037, JString, required = false,
                                 default = nil)
  if valid_598037 != nil:
    section.add "Qualifier", valid_598037
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
  var valid_598038 = header.getOrDefault("X-Amz-Signature")
  valid_598038 = validateParameter(valid_598038, JString, required = false,
                                 default = nil)
  if valid_598038 != nil:
    section.add "X-Amz-Signature", valid_598038
  var valid_598039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598039 = validateParameter(valid_598039, JString, required = false,
                                 default = nil)
  if valid_598039 != nil:
    section.add "X-Amz-Content-Sha256", valid_598039
  var valid_598040 = header.getOrDefault("X-Amz-Date")
  valid_598040 = validateParameter(valid_598040, JString, required = false,
                                 default = nil)
  if valid_598040 != nil:
    section.add "X-Amz-Date", valid_598040
  var valid_598041 = header.getOrDefault("X-Amz-Credential")
  valid_598041 = validateParameter(valid_598041, JString, required = false,
                                 default = nil)
  if valid_598041 != nil:
    section.add "X-Amz-Credential", valid_598041
  var valid_598042 = header.getOrDefault("X-Amz-Security-Token")
  valid_598042 = validateParameter(valid_598042, JString, required = false,
                                 default = nil)
  if valid_598042 != nil:
    section.add "X-Amz-Security-Token", valid_598042
  var valid_598043 = header.getOrDefault("X-Amz-Algorithm")
  valid_598043 = validateParameter(valid_598043, JString, required = false,
                                 default = nil)
  if valid_598043 != nil:
    section.add "X-Amz-Algorithm", valid_598043
  var valid_598044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598044 = validateParameter(valid_598044, JString, required = false,
                                 default = nil)
  if valid_598044 != nil:
    section.add "X-Amz-SignedHeaders", valid_598044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598046: Call_AddPermission_598033; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Grants an AWS service or another account permission to use a function. You can apply the policy at the function level, or specify a qualifier to restrict access to a single version or alias. If you use a qualifier, the invoker must use the full Amazon Resource Name (ARN) of that version or alias to invoke the function.</p> <p>To grant permission to another account, specify the account ID as the <code>Principal</code>. For AWS services, the principal is a domain-style identifier defined by the service, like <code>s3.amazonaws.com</code> or <code>sns.amazonaws.com</code>. For AWS services, you can also specify the ARN or owning account of the associated resource as the <code>SourceArn</code> or <code>SourceAccount</code>. If you grant permission to a service principal without specifying the source, other accounts could potentially configure resources in their account to invoke your Lambda function.</p> <p>This action adds a statement to a resource-based permissions policy for the function. For more information about function policies, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">Lambda Function Policies</a>. </p>
  ## 
  let valid = call_598046.validator(path, query, header, formData, body)
  let scheme = call_598046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598046.url(scheme.get, call_598046.host, call_598046.base,
                         call_598046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598046, url, valid)

proc call*(call_598047: Call_AddPermission_598033; FunctionName: string;
          body: JsonNode; Qualifier: string = ""): Recallable =
  ## addPermission
  ## <p>Grants an AWS service or another account permission to use a function. You can apply the policy at the function level, or specify a qualifier to restrict access to a single version or alias. If you use a qualifier, the invoker must use the full Amazon Resource Name (ARN) of that version or alias to invoke the function.</p> <p>To grant permission to another account, specify the account ID as the <code>Principal</code>. For AWS services, the principal is a domain-style identifier defined by the service, like <code>s3.amazonaws.com</code> or <code>sns.amazonaws.com</code>. For AWS services, you can also specify the ARN or owning account of the associated resource as the <code>SourceArn</code> or <code>SourceAccount</code>. If you grant permission to a service principal without specifying the source, other accounts could potentially configure resources in their account to invoke your Lambda function.</p> <p>This action adds a statement to a resource-based permissions policy for the function. For more information about function policies, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">Lambda Function Policies</a>. </p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to add permissions to a published version of the function.
  ##   body: JObject (required)
  var path_598048 = newJObject()
  var query_598049 = newJObject()
  var body_598050 = newJObject()
  add(path_598048, "FunctionName", newJString(FunctionName))
  add(query_598049, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_598050 = body
  result = call_598047.call(path_598048, query_598049, nil, nil, body_598050)

var addPermission* = Call_AddPermission_598033(name: "addPermission",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/policy",
    validator: validate_AddPermission_598034, base: "/", url: url_AddPermission_598035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPolicy_598017 = ref object of OpenApiRestCall_597389
proc url_GetPolicy_598019(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetPolicy_598018(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598020 = path.getOrDefault("FunctionName")
  valid_598020 = validateParameter(valid_598020, JString, required = true,
                                 default = nil)
  if valid_598020 != nil:
    section.add "FunctionName", valid_598020
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to get the policy for that resource.
  section = newJObject()
  var valid_598021 = query.getOrDefault("Qualifier")
  valid_598021 = validateParameter(valid_598021, JString, required = false,
                                 default = nil)
  if valid_598021 != nil:
    section.add "Qualifier", valid_598021
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
  var valid_598022 = header.getOrDefault("X-Amz-Signature")
  valid_598022 = validateParameter(valid_598022, JString, required = false,
                                 default = nil)
  if valid_598022 != nil:
    section.add "X-Amz-Signature", valid_598022
  var valid_598023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598023 = validateParameter(valid_598023, JString, required = false,
                                 default = nil)
  if valid_598023 != nil:
    section.add "X-Amz-Content-Sha256", valid_598023
  var valid_598024 = header.getOrDefault("X-Amz-Date")
  valid_598024 = validateParameter(valid_598024, JString, required = false,
                                 default = nil)
  if valid_598024 != nil:
    section.add "X-Amz-Date", valid_598024
  var valid_598025 = header.getOrDefault("X-Amz-Credential")
  valid_598025 = validateParameter(valid_598025, JString, required = false,
                                 default = nil)
  if valid_598025 != nil:
    section.add "X-Amz-Credential", valid_598025
  var valid_598026 = header.getOrDefault("X-Amz-Security-Token")
  valid_598026 = validateParameter(valid_598026, JString, required = false,
                                 default = nil)
  if valid_598026 != nil:
    section.add "X-Amz-Security-Token", valid_598026
  var valid_598027 = header.getOrDefault("X-Amz-Algorithm")
  valid_598027 = validateParameter(valid_598027, JString, required = false,
                                 default = nil)
  if valid_598027 != nil:
    section.add "X-Amz-Algorithm", valid_598027
  var valid_598028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598028 = validateParameter(valid_598028, JString, required = false,
                                 default = nil)
  if valid_598028 != nil:
    section.add "X-Amz-SignedHeaders", valid_598028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598029: Call_GetPolicy_598017; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">resource-based IAM policy</a> for a function, version, or alias.
  ## 
  let valid = call_598029.validator(path, query, header, formData, body)
  let scheme = call_598029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598029.url(scheme.get, call_598029.host, call_598029.base,
                         call_598029.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598029, url, valid)

proc call*(call_598030: Call_GetPolicy_598017; FunctionName: string;
          Qualifier: string = ""): Recallable =
  ## getPolicy
  ## Returns the <a href="https://docs.aws.amazon.com/lambda/latest/dg/access-control-resource-based.html">resource-based IAM policy</a> for a function, version, or alias.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to get the policy for that resource.
  var path_598031 = newJObject()
  var query_598032 = newJObject()
  add(path_598031, "FunctionName", newJString(FunctionName))
  add(query_598032, "Qualifier", newJString(Qualifier))
  result = call_598030.call(path_598031, query_598032, nil, nil, nil)

var getPolicy* = Call_GetPolicy_598017(name: "getPolicy", meth: HttpMethod.HttpGet,
                                    host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/policy",
                                    validator: validate_GetPolicy_598018,
                                    base: "/", url: url_GetPolicy_598019,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAlias_598069 = ref object of OpenApiRestCall_597389
proc url_CreateAlias_598071(protocol: Scheme; host: string; base: string;
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

proc validate_CreateAlias_598070(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598072 = path.getOrDefault("FunctionName")
  valid_598072 = validateParameter(valid_598072, JString, required = true,
                                 default = nil)
  if valid_598072 != nil:
    section.add "FunctionName", valid_598072
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
  var valid_598073 = header.getOrDefault("X-Amz-Signature")
  valid_598073 = validateParameter(valid_598073, JString, required = false,
                                 default = nil)
  if valid_598073 != nil:
    section.add "X-Amz-Signature", valid_598073
  var valid_598074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598074 = validateParameter(valid_598074, JString, required = false,
                                 default = nil)
  if valid_598074 != nil:
    section.add "X-Amz-Content-Sha256", valid_598074
  var valid_598075 = header.getOrDefault("X-Amz-Date")
  valid_598075 = validateParameter(valid_598075, JString, required = false,
                                 default = nil)
  if valid_598075 != nil:
    section.add "X-Amz-Date", valid_598075
  var valid_598076 = header.getOrDefault("X-Amz-Credential")
  valid_598076 = validateParameter(valid_598076, JString, required = false,
                                 default = nil)
  if valid_598076 != nil:
    section.add "X-Amz-Credential", valid_598076
  var valid_598077 = header.getOrDefault("X-Amz-Security-Token")
  valid_598077 = validateParameter(valid_598077, JString, required = false,
                                 default = nil)
  if valid_598077 != nil:
    section.add "X-Amz-Security-Token", valid_598077
  var valid_598078 = header.getOrDefault("X-Amz-Algorithm")
  valid_598078 = validateParameter(valid_598078, JString, required = false,
                                 default = nil)
  if valid_598078 != nil:
    section.add "X-Amz-Algorithm", valid_598078
  var valid_598079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598079 = validateParameter(valid_598079, JString, required = false,
                                 default = nil)
  if valid_598079 != nil:
    section.add "X-Amz-SignedHeaders", valid_598079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598081: Call_CreateAlias_598069; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a> for a Lambda function version. Use aliases to provide clients with a function identifier that you can update to invoke a different version.</p> <p>You can also map an alias to split invocation requests between two versions. Use the <code>RoutingConfig</code> parameter to specify a second version and the percentage of invocation requests that it receives.</p>
  ## 
  let valid = call_598081.validator(path, query, header, formData, body)
  let scheme = call_598081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598081.url(scheme.get, call_598081.host, call_598081.base,
                         call_598081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598081, url, valid)

proc call*(call_598082: Call_CreateAlias_598069; FunctionName: string; body: JsonNode): Recallable =
  ## createAlias
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a> for a Lambda function version. Use aliases to provide clients with a function identifier that you can update to invoke a different version.</p> <p>You can also map an alias to split invocation requests between two versions. Use the <code>RoutingConfig</code> parameter to specify a second version and the percentage of invocation requests that it receives.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_598083 = newJObject()
  var body_598084 = newJObject()
  add(path_598083, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_598084 = body
  result = call_598082.call(path_598083, nil, nil, nil, body_598084)

var createAlias* = Call_CreateAlias_598069(name: "createAlias",
                                        meth: HttpMethod.HttpPost,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases",
                                        validator: validate_CreateAlias_598070,
                                        base: "/", url: url_CreateAlias_598071,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAliases_598051 = ref object of OpenApiRestCall_597389
proc url_ListAliases_598053(protocol: Scheme; host: string; base: string;
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

proc validate_ListAliases_598052(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598054 = path.getOrDefault("FunctionName")
  valid_598054 = validateParameter(valid_598054, JString, required = true,
                                 default = nil)
  if valid_598054 != nil:
    section.add "FunctionName", valid_598054
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   FunctionVersion: JString
  ##                  : Specify a function version to only list aliases that invoke that version.
  ##   MaxItems: JInt
  ##           : Limit the number of aliases returned.
  section = newJObject()
  var valid_598055 = query.getOrDefault("Marker")
  valid_598055 = validateParameter(valid_598055, JString, required = false,
                                 default = nil)
  if valid_598055 != nil:
    section.add "Marker", valid_598055
  var valid_598056 = query.getOrDefault("FunctionVersion")
  valid_598056 = validateParameter(valid_598056, JString, required = false,
                                 default = nil)
  if valid_598056 != nil:
    section.add "FunctionVersion", valid_598056
  var valid_598057 = query.getOrDefault("MaxItems")
  valid_598057 = validateParameter(valid_598057, JInt, required = false, default = nil)
  if valid_598057 != nil:
    section.add "MaxItems", valid_598057
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
  var valid_598058 = header.getOrDefault("X-Amz-Signature")
  valid_598058 = validateParameter(valid_598058, JString, required = false,
                                 default = nil)
  if valid_598058 != nil:
    section.add "X-Amz-Signature", valid_598058
  var valid_598059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598059 = validateParameter(valid_598059, JString, required = false,
                                 default = nil)
  if valid_598059 != nil:
    section.add "X-Amz-Content-Sha256", valid_598059
  var valid_598060 = header.getOrDefault("X-Amz-Date")
  valid_598060 = validateParameter(valid_598060, JString, required = false,
                                 default = nil)
  if valid_598060 != nil:
    section.add "X-Amz-Date", valid_598060
  var valid_598061 = header.getOrDefault("X-Amz-Credential")
  valid_598061 = validateParameter(valid_598061, JString, required = false,
                                 default = nil)
  if valid_598061 != nil:
    section.add "X-Amz-Credential", valid_598061
  var valid_598062 = header.getOrDefault("X-Amz-Security-Token")
  valid_598062 = validateParameter(valid_598062, JString, required = false,
                                 default = nil)
  if valid_598062 != nil:
    section.add "X-Amz-Security-Token", valid_598062
  var valid_598063 = header.getOrDefault("X-Amz-Algorithm")
  valid_598063 = validateParameter(valid_598063, JString, required = false,
                                 default = nil)
  if valid_598063 != nil:
    section.add "X-Amz-Algorithm", valid_598063
  var valid_598064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598064 = validateParameter(valid_598064, JString, required = false,
                                 default = nil)
  if valid_598064 != nil:
    section.add "X-Amz-SignedHeaders", valid_598064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598065: Call_ListAliases_598051; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">aliases</a> for a Lambda function.
  ## 
  let valid = call_598065.validator(path, query, header, formData, body)
  let scheme = call_598065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598065.url(scheme.get, call_598065.host, call_598065.base,
                         call_598065.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598065, url, valid)

proc call*(call_598066: Call_ListAliases_598051; FunctionName: string;
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
  var path_598067 = newJObject()
  var query_598068 = newJObject()
  add(query_598068, "Marker", newJString(Marker))
  add(query_598068, "FunctionVersion", newJString(FunctionVersion))
  add(path_598067, "FunctionName", newJString(FunctionName))
  add(query_598068, "MaxItems", newJInt(MaxItems))
  result = call_598066.call(path_598067, query_598068, nil, nil, nil)

var listAliases* = Call_ListAliases_598051(name: "listAliases",
                                        meth: HttpMethod.HttpGet,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases",
                                        validator: validate_ListAliases_598052,
                                        base: "/", url: url_ListAliases_598053,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateEventSourceMapping_598102 = ref object of OpenApiRestCall_597389
proc url_CreateEventSourceMapping_598104(protocol: Scheme; host: string;
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

proc validate_CreateEventSourceMapping_598103(path: JsonNode; query: JsonNode;
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
  var valid_598105 = header.getOrDefault("X-Amz-Signature")
  valid_598105 = validateParameter(valid_598105, JString, required = false,
                                 default = nil)
  if valid_598105 != nil:
    section.add "X-Amz-Signature", valid_598105
  var valid_598106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598106 = validateParameter(valid_598106, JString, required = false,
                                 default = nil)
  if valid_598106 != nil:
    section.add "X-Amz-Content-Sha256", valid_598106
  var valid_598107 = header.getOrDefault("X-Amz-Date")
  valid_598107 = validateParameter(valid_598107, JString, required = false,
                                 default = nil)
  if valid_598107 != nil:
    section.add "X-Amz-Date", valid_598107
  var valid_598108 = header.getOrDefault("X-Amz-Credential")
  valid_598108 = validateParameter(valid_598108, JString, required = false,
                                 default = nil)
  if valid_598108 != nil:
    section.add "X-Amz-Credential", valid_598108
  var valid_598109 = header.getOrDefault("X-Amz-Security-Token")
  valid_598109 = validateParameter(valid_598109, JString, required = false,
                                 default = nil)
  if valid_598109 != nil:
    section.add "X-Amz-Security-Token", valid_598109
  var valid_598110 = header.getOrDefault("X-Amz-Algorithm")
  valid_598110 = validateParameter(valid_598110, JString, required = false,
                                 default = nil)
  if valid_598110 != nil:
    section.add "X-Amz-Algorithm", valid_598110
  var valid_598111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598111 = validateParameter(valid_598111, JString, required = false,
                                 default = nil)
  if valid_598111 != nil:
    section.add "X-Amz-SignedHeaders", valid_598111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598113: Call_CreateEventSourceMapping_598102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a mapping between an event source and an AWS Lambda function. Lambda reads items from the event source and triggers the function.</p> <p>For details about each event source type, see the following topics.</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html">Using AWS Lambda with Amazon DynamoDB</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html">Using AWS Lambda with Amazon Kinesis</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html">Using AWS Lambda with Amazon SQS</a> </p> </li> </ul> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> </ul>
  ## 
  let valid = call_598113.validator(path, query, header, formData, body)
  let scheme = call_598113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598113.url(scheme.get, call_598113.host, call_598113.base,
                         call_598113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598113, url, valid)

proc call*(call_598114: Call_CreateEventSourceMapping_598102; body: JsonNode): Recallable =
  ## createEventSourceMapping
  ## <p>Creates a mapping between an event source and an AWS Lambda function. Lambda reads items from the event source and triggers the function.</p> <p>For details about each event source type, see the following topics.</p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-ddb.html">Using AWS Lambda with Amazon DynamoDB</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-kinesis.html">Using AWS Lambda with Amazon Kinesis</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/lambda/latest/dg/with-sqs.html">Using AWS Lambda with Amazon SQS</a> </p> </li> </ul> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> </ul>
  ##   body: JObject (required)
  var body_598115 = newJObject()
  if body != nil:
    body_598115 = body
  result = call_598114.call(nil, nil, nil, nil, body_598115)

var createEventSourceMapping* = Call_CreateEventSourceMapping_598102(
    name: "createEventSourceMapping", meth: HttpMethod.HttpPost,
    host: "lambda.amazonaws.com", route: "/2015-03-31/event-source-mappings/",
    validator: validate_CreateEventSourceMapping_598103, base: "/",
    url: url_CreateEventSourceMapping_598104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEventSourceMappings_598085 = ref object of OpenApiRestCall_597389
proc url_ListEventSourceMappings_598087(protocol: Scheme; host: string; base: string;
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

proc validate_ListEventSourceMappings_598086(path: JsonNode; query: JsonNode;
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
  var valid_598088 = query.getOrDefault("Marker")
  valid_598088 = validateParameter(valid_598088, JString, required = false,
                                 default = nil)
  if valid_598088 != nil:
    section.add "Marker", valid_598088
  var valid_598089 = query.getOrDefault("FunctionName")
  valid_598089 = validateParameter(valid_598089, JString, required = false,
                                 default = nil)
  if valid_598089 != nil:
    section.add "FunctionName", valid_598089
  var valid_598090 = query.getOrDefault("MaxItems")
  valid_598090 = validateParameter(valid_598090, JInt, required = false, default = nil)
  if valid_598090 != nil:
    section.add "MaxItems", valid_598090
  var valid_598091 = query.getOrDefault("EventSourceArn")
  valid_598091 = validateParameter(valid_598091, JString, required = false,
                                 default = nil)
  if valid_598091 != nil:
    section.add "EventSourceArn", valid_598091
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
  var valid_598092 = header.getOrDefault("X-Amz-Signature")
  valid_598092 = validateParameter(valid_598092, JString, required = false,
                                 default = nil)
  if valid_598092 != nil:
    section.add "X-Amz-Signature", valid_598092
  var valid_598093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598093 = validateParameter(valid_598093, JString, required = false,
                                 default = nil)
  if valid_598093 != nil:
    section.add "X-Amz-Content-Sha256", valid_598093
  var valid_598094 = header.getOrDefault("X-Amz-Date")
  valid_598094 = validateParameter(valid_598094, JString, required = false,
                                 default = nil)
  if valid_598094 != nil:
    section.add "X-Amz-Date", valid_598094
  var valid_598095 = header.getOrDefault("X-Amz-Credential")
  valid_598095 = validateParameter(valid_598095, JString, required = false,
                                 default = nil)
  if valid_598095 != nil:
    section.add "X-Amz-Credential", valid_598095
  var valid_598096 = header.getOrDefault("X-Amz-Security-Token")
  valid_598096 = validateParameter(valid_598096, JString, required = false,
                                 default = nil)
  if valid_598096 != nil:
    section.add "X-Amz-Security-Token", valid_598096
  var valid_598097 = header.getOrDefault("X-Amz-Algorithm")
  valid_598097 = validateParameter(valid_598097, JString, required = false,
                                 default = nil)
  if valid_598097 != nil:
    section.add "X-Amz-Algorithm", valid_598097
  var valid_598098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598098 = validateParameter(valid_598098, JString, required = false,
                                 default = nil)
  if valid_598098 != nil:
    section.add "X-Amz-SignedHeaders", valid_598098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598099: Call_ListEventSourceMappings_598085; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists event source mappings. Specify an <code>EventSourceArn</code> to only show event source mappings for a single event source.
  ## 
  let valid = call_598099.validator(path, query, header, formData, body)
  let scheme = call_598099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598099.url(scheme.get, call_598099.host, call_598099.base,
                         call_598099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598099, url, valid)

proc call*(call_598100: Call_ListEventSourceMappings_598085; Marker: string = "";
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
  var query_598101 = newJObject()
  add(query_598101, "Marker", newJString(Marker))
  add(query_598101, "FunctionName", newJString(FunctionName))
  add(query_598101, "MaxItems", newJInt(MaxItems))
  add(query_598101, "EventSourceArn", newJString(EventSourceArn))
  result = call_598100.call(nil, query_598101, nil, nil, nil)

var listEventSourceMappings* = Call_ListEventSourceMappings_598085(
    name: "listEventSourceMappings", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com", route: "/2015-03-31/event-source-mappings/",
    validator: validate_ListEventSourceMappings_598086, base: "/",
    url: url_ListEventSourceMappings_598087, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFunction_598116 = ref object of OpenApiRestCall_597389
proc url_CreateFunction_598118(protocol: Scheme; host: string; base: string;
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

proc validate_CreateFunction_598117(path: JsonNode; query: JsonNode;
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
  var valid_598119 = header.getOrDefault("X-Amz-Signature")
  valid_598119 = validateParameter(valid_598119, JString, required = false,
                                 default = nil)
  if valid_598119 != nil:
    section.add "X-Amz-Signature", valid_598119
  var valid_598120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598120 = validateParameter(valid_598120, JString, required = false,
                                 default = nil)
  if valid_598120 != nil:
    section.add "X-Amz-Content-Sha256", valid_598120
  var valid_598121 = header.getOrDefault("X-Amz-Date")
  valid_598121 = validateParameter(valid_598121, JString, required = false,
                                 default = nil)
  if valid_598121 != nil:
    section.add "X-Amz-Date", valid_598121
  var valid_598122 = header.getOrDefault("X-Amz-Credential")
  valid_598122 = validateParameter(valid_598122, JString, required = false,
                                 default = nil)
  if valid_598122 != nil:
    section.add "X-Amz-Credential", valid_598122
  var valid_598123 = header.getOrDefault("X-Amz-Security-Token")
  valid_598123 = validateParameter(valid_598123, JString, required = false,
                                 default = nil)
  if valid_598123 != nil:
    section.add "X-Amz-Security-Token", valid_598123
  var valid_598124 = header.getOrDefault("X-Amz-Algorithm")
  valid_598124 = validateParameter(valid_598124, JString, required = false,
                                 default = nil)
  if valid_598124 != nil:
    section.add "X-Amz-Algorithm", valid_598124
  var valid_598125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598125 = validateParameter(valid_598125, JString, required = false,
                                 default = nil)
  if valid_598125 != nil:
    section.add "X-Amz-SignedHeaders", valid_598125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598127: Call_CreateFunction_598116; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a Lambda function. To create a function, you need a <a href="https://docs.aws.amazon.com/lambda/latest/dg/deployment-package-v2.html">deployment package</a> and an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-permission-model.html#lambda-intro-execution-role">execution role</a>. The deployment package contains your function code. The execution role grants the function permission to use AWS services, such as Amazon CloudWatch Logs for log streaming and AWS X-Ray for request tracing.</p> <p>When you create a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute or so. During this time, you can't invoke or modify the function. The <code>State</code>, <code>StateReason</code>, and <code>StateReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the function is ready to invoke. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Function States</a>.</p> <p>A function has an unpublished version, and can have published versions and aliases. The unpublished version changes when you update your function's code and configuration. A published version is a snapshot of your function code and configuration that can't be changed. An alias is a named resource that maps to a version, and can be changed to map to a different version. Use the <code>Publish</code> parameter to create version <code>1</code> of your function from its initial configuration.</p> <p>The other parameters let you configure version-specific and function-level settings. You can modify version-specific settings later with <a>UpdateFunctionConfiguration</a>. Function-level settings apply to both the unpublished and published versions of the function, and include tags (<a>TagResource</a>) and per-function concurrency limits (<a>PutFunctionConcurrency</a>).</p> <p>If another account or an AWS service invokes your function, use <a>AddPermission</a> to grant permission by creating a resource-based IAM policy. You can grant permissions at the function level, on a version, or on an alias.</p> <p>To invoke your function directly, use <a>Invoke</a>. To invoke your function in response to events in other AWS services, create an event source mapping (<a>CreateEventSourceMapping</a>), or configure a function trigger in the other service. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-invocation.html">Invoking Functions</a>.</p>
  ## 
  let valid = call_598127.validator(path, query, header, formData, body)
  let scheme = call_598127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598127.url(scheme.get, call_598127.host, call_598127.base,
                         call_598127.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598127, url, valid)

proc call*(call_598128: Call_CreateFunction_598116; body: JsonNode): Recallable =
  ## createFunction
  ## <p>Creates a Lambda function. To create a function, you need a <a href="https://docs.aws.amazon.com/lambda/latest/dg/deployment-package-v2.html">deployment package</a> and an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-permission-model.html#lambda-intro-execution-role">execution role</a>. The deployment package contains your function code. The execution role grants the function permission to use AWS services, such as Amazon CloudWatch Logs for log streaming and AWS X-Ray for request tracing.</p> <p>When you create a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute or so. During this time, you can't invoke or modify the function. The <code>State</code>, <code>StateReason</code>, and <code>StateReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the function is ready to invoke. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Function States</a>.</p> <p>A function has an unpublished version, and can have published versions and aliases. The unpublished version changes when you update your function's code and configuration. A published version is a snapshot of your function code and configuration that can't be changed. An alias is a named resource that maps to a version, and can be changed to map to a different version. Use the <code>Publish</code> parameter to create version <code>1</code> of your function from its initial configuration.</p> <p>The other parameters let you configure version-specific and function-level settings. You can modify version-specific settings later with <a>UpdateFunctionConfiguration</a>. Function-level settings apply to both the unpublished and published versions of the function, and include tags (<a>TagResource</a>) and per-function concurrency limits (<a>PutFunctionConcurrency</a>).</p> <p>If another account or an AWS service invokes your function, use <a>AddPermission</a> to grant permission by creating a resource-based IAM policy. You can grant permissions at the function level, on a version, or on an alias.</p> <p>To invoke your function directly, use <a>Invoke</a>. To invoke your function in response to events in other AWS services, create an event source mapping (<a>CreateEventSourceMapping</a>), or configure a function trigger in the other service. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-invocation.html">Invoking Functions</a>.</p>
  ##   body: JObject (required)
  var body_598129 = newJObject()
  if body != nil:
    body_598129 = body
  result = call_598128.call(nil, nil, nil, nil, body_598129)

var createFunction* = Call_CreateFunction_598116(name: "createFunction",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions", validator: validate_CreateFunction_598117,
    base: "/", url: url_CreateFunction_598118, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAlias_598145 = ref object of OpenApiRestCall_597389
proc url_UpdateAlias_598147(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateAlias_598146(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598148 = path.getOrDefault("FunctionName")
  valid_598148 = validateParameter(valid_598148, JString, required = true,
                                 default = nil)
  if valid_598148 != nil:
    section.add "FunctionName", valid_598148
  var valid_598149 = path.getOrDefault("Name")
  valid_598149 = validateParameter(valid_598149, JString, required = true,
                                 default = nil)
  if valid_598149 != nil:
    section.add "Name", valid_598149
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
  var valid_598150 = header.getOrDefault("X-Amz-Signature")
  valid_598150 = validateParameter(valid_598150, JString, required = false,
                                 default = nil)
  if valid_598150 != nil:
    section.add "X-Amz-Signature", valid_598150
  var valid_598151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598151 = validateParameter(valid_598151, JString, required = false,
                                 default = nil)
  if valid_598151 != nil:
    section.add "X-Amz-Content-Sha256", valid_598151
  var valid_598152 = header.getOrDefault("X-Amz-Date")
  valid_598152 = validateParameter(valid_598152, JString, required = false,
                                 default = nil)
  if valid_598152 != nil:
    section.add "X-Amz-Date", valid_598152
  var valid_598153 = header.getOrDefault("X-Amz-Credential")
  valid_598153 = validateParameter(valid_598153, JString, required = false,
                                 default = nil)
  if valid_598153 != nil:
    section.add "X-Amz-Credential", valid_598153
  var valid_598154 = header.getOrDefault("X-Amz-Security-Token")
  valid_598154 = validateParameter(valid_598154, JString, required = false,
                                 default = nil)
  if valid_598154 != nil:
    section.add "X-Amz-Security-Token", valid_598154
  var valid_598155 = header.getOrDefault("X-Amz-Algorithm")
  valid_598155 = validateParameter(valid_598155, JString, required = false,
                                 default = nil)
  if valid_598155 != nil:
    section.add "X-Amz-Algorithm", valid_598155
  var valid_598156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598156 = validateParameter(valid_598156, JString, required = false,
                                 default = nil)
  if valid_598156 != nil:
    section.add "X-Amz-SignedHeaders", valid_598156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598158: Call_UpdateAlias_598145; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the configuration of a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ## 
  let valid = call_598158.validator(path, query, header, formData, body)
  let scheme = call_598158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598158.url(scheme.get, call_598158.host, call_598158.base,
                         call_598158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598158, url, valid)

proc call*(call_598159: Call_UpdateAlias_598145; FunctionName: string; Name: string;
          body: JsonNode): Recallable =
  ## updateAlias
  ## Updates the configuration of a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Name: string (required)
  ##       : The name of the alias.
  ##   body: JObject (required)
  var path_598160 = newJObject()
  var body_598161 = newJObject()
  add(path_598160, "FunctionName", newJString(FunctionName))
  add(path_598160, "Name", newJString(Name))
  if body != nil:
    body_598161 = body
  result = call_598159.call(path_598160, nil, nil, nil, body_598161)

var updateAlias* = Call_UpdateAlias_598145(name: "updateAlias",
                                        meth: HttpMethod.HttpPut,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases/{Name}",
                                        validator: validate_UpdateAlias_598146,
                                        base: "/", url: url_UpdateAlias_598147,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAlias_598130 = ref object of OpenApiRestCall_597389
proc url_GetAlias_598132(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetAlias_598131(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598133 = path.getOrDefault("FunctionName")
  valid_598133 = validateParameter(valid_598133, JString, required = true,
                                 default = nil)
  if valid_598133 != nil:
    section.add "FunctionName", valid_598133
  var valid_598134 = path.getOrDefault("Name")
  valid_598134 = validateParameter(valid_598134, JString, required = true,
                                 default = nil)
  if valid_598134 != nil:
    section.add "Name", valid_598134
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
  var valid_598135 = header.getOrDefault("X-Amz-Signature")
  valid_598135 = validateParameter(valid_598135, JString, required = false,
                                 default = nil)
  if valid_598135 != nil:
    section.add "X-Amz-Signature", valid_598135
  var valid_598136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598136 = validateParameter(valid_598136, JString, required = false,
                                 default = nil)
  if valid_598136 != nil:
    section.add "X-Amz-Content-Sha256", valid_598136
  var valid_598137 = header.getOrDefault("X-Amz-Date")
  valid_598137 = validateParameter(valid_598137, JString, required = false,
                                 default = nil)
  if valid_598137 != nil:
    section.add "X-Amz-Date", valid_598137
  var valid_598138 = header.getOrDefault("X-Amz-Credential")
  valid_598138 = validateParameter(valid_598138, JString, required = false,
                                 default = nil)
  if valid_598138 != nil:
    section.add "X-Amz-Credential", valid_598138
  var valid_598139 = header.getOrDefault("X-Amz-Security-Token")
  valid_598139 = validateParameter(valid_598139, JString, required = false,
                                 default = nil)
  if valid_598139 != nil:
    section.add "X-Amz-Security-Token", valid_598139
  var valid_598140 = header.getOrDefault("X-Amz-Algorithm")
  valid_598140 = validateParameter(valid_598140, JString, required = false,
                                 default = nil)
  if valid_598140 != nil:
    section.add "X-Amz-Algorithm", valid_598140
  var valid_598141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598141 = validateParameter(valid_598141, JString, required = false,
                                 default = nil)
  if valid_598141 != nil:
    section.add "X-Amz-SignedHeaders", valid_598141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598142: Call_GetAlias_598130; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns details about a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ## 
  let valid = call_598142.validator(path, query, header, formData, body)
  let scheme = call_598142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598142.url(scheme.get, call_598142.host, call_598142.base,
                         call_598142.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598142, url, valid)

proc call*(call_598143: Call_GetAlias_598130; FunctionName: string; Name: string): Recallable =
  ## getAlias
  ## Returns details about a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Name: string (required)
  ##       : The name of the alias.
  var path_598144 = newJObject()
  add(path_598144, "FunctionName", newJString(FunctionName))
  add(path_598144, "Name", newJString(Name))
  result = call_598143.call(path_598144, nil, nil, nil, nil)

var getAlias* = Call_GetAlias_598130(name: "getAlias", meth: HttpMethod.HttpGet,
                                  host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases/{Name}",
                                  validator: validate_GetAlias_598131, base: "/",
                                  url: url_GetAlias_598132,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAlias_598162 = ref object of OpenApiRestCall_597389
proc url_DeleteAlias_598164(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteAlias_598163(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598165 = path.getOrDefault("FunctionName")
  valid_598165 = validateParameter(valid_598165, JString, required = true,
                                 default = nil)
  if valid_598165 != nil:
    section.add "FunctionName", valid_598165
  var valid_598166 = path.getOrDefault("Name")
  valid_598166 = validateParameter(valid_598166, JString, required = true,
                                 default = nil)
  if valid_598166 != nil:
    section.add "Name", valid_598166
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
  var valid_598167 = header.getOrDefault("X-Amz-Signature")
  valid_598167 = validateParameter(valid_598167, JString, required = false,
                                 default = nil)
  if valid_598167 != nil:
    section.add "X-Amz-Signature", valid_598167
  var valid_598168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598168 = validateParameter(valid_598168, JString, required = false,
                                 default = nil)
  if valid_598168 != nil:
    section.add "X-Amz-Content-Sha256", valid_598168
  var valid_598169 = header.getOrDefault("X-Amz-Date")
  valid_598169 = validateParameter(valid_598169, JString, required = false,
                                 default = nil)
  if valid_598169 != nil:
    section.add "X-Amz-Date", valid_598169
  var valid_598170 = header.getOrDefault("X-Amz-Credential")
  valid_598170 = validateParameter(valid_598170, JString, required = false,
                                 default = nil)
  if valid_598170 != nil:
    section.add "X-Amz-Credential", valid_598170
  var valid_598171 = header.getOrDefault("X-Amz-Security-Token")
  valid_598171 = validateParameter(valid_598171, JString, required = false,
                                 default = nil)
  if valid_598171 != nil:
    section.add "X-Amz-Security-Token", valid_598171
  var valid_598172 = header.getOrDefault("X-Amz-Algorithm")
  valid_598172 = validateParameter(valid_598172, JString, required = false,
                                 default = nil)
  if valid_598172 != nil:
    section.add "X-Amz-Algorithm", valid_598172
  var valid_598173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598173 = validateParameter(valid_598173, JString, required = false,
                                 default = nil)
  if valid_598173 != nil:
    section.add "X-Amz-SignedHeaders", valid_598173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598174: Call_DeleteAlias_598162; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ## 
  let valid = call_598174.validator(path, query, header, formData, body)
  let scheme = call_598174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598174.url(scheme.get, call_598174.host, call_598174.base,
                         call_598174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598174, url, valid)

proc call*(call_598175: Call_DeleteAlias_598162; FunctionName: string; Name: string): Recallable =
  ## deleteAlias
  ## Deletes a Lambda function <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">alias</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Name: string (required)
  ##       : The name of the alias.
  var path_598176 = newJObject()
  add(path_598176, "FunctionName", newJString(FunctionName))
  add(path_598176, "Name", newJString(Name))
  result = call_598175.call(path_598176, nil, nil, nil, nil)

var deleteAlias* = Call_DeleteAlias_598162(name: "deleteAlias",
                                        meth: HttpMethod.HttpDelete,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/aliases/{Name}",
                                        validator: validate_DeleteAlias_598163,
                                        base: "/", url: url_DeleteAlias_598164,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateEventSourceMapping_598191 = ref object of OpenApiRestCall_597389
proc url_UpdateEventSourceMapping_598193(protocol: Scheme; host: string;
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

proc validate_UpdateEventSourceMapping_598192(path: JsonNode; query: JsonNode;
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
  var valid_598194 = path.getOrDefault("UUID")
  valid_598194 = validateParameter(valid_598194, JString, required = true,
                                 default = nil)
  if valid_598194 != nil:
    section.add "UUID", valid_598194
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
  var valid_598195 = header.getOrDefault("X-Amz-Signature")
  valid_598195 = validateParameter(valid_598195, JString, required = false,
                                 default = nil)
  if valid_598195 != nil:
    section.add "X-Amz-Signature", valid_598195
  var valid_598196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598196 = validateParameter(valid_598196, JString, required = false,
                                 default = nil)
  if valid_598196 != nil:
    section.add "X-Amz-Content-Sha256", valid_598196
  var valid_598197 = header.getOrDefault("X-Amz-Date")
  valid_598197 = validateParameter(valid_598197, JString, required = false,
                                 default = nil)
  if valid_598197 != nil:
    section.add "X-Amz-Date", valid_598197
  var valid_598198 = header.getOrDefault("X-Amz-Credential")
  valid_598198 = validateParameter(valid_598198, JString, required = false,
                                 default = nil)
  if valid_598198 != nil:
    section.add "X-Amz-Credential", valid_598198
  var valid_598199 = header.getOrDefault("X-Amz-Security-Token")
  valid_598199 = validateParameter(valid_598199, JString, required = false,
                                 default = nil)
  if valid_598199 != nil:
    section.add "X-Amz-Security-Token", valid_598199
  var valid_598200 = header.getOrDefault("X-Amz-Algorithm")
  valid_598200 = validateParameter(valid_598200, JString, required = false,
                                 default = nil)
  if valid_598200 != nil:
    section.add "X-Amz-Algorithm", valid_598200
  var valid_598201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598201 = validateParameter(valid_598201, JString, required = false,
                                 default = nil)
  if valid_598201 != nil:
    section.add "X-Amz-SignedHeaders", valid_598201
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598203: Call_UpdateEventSourceMapping_598191; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an event source mapping. You can change the function that AWS Lambda invokes, or pause invocation and resume later from the same location.</p> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> </ul>
  ## 
  let valid = call_598203.validator(path, query, header, formData, body)
  let scheme = call_598203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598203.url(scheme.get, call_598203.host, call_598203.base,
                         call_598203.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598203, url, valid)

proc call*(call_598204: Call_UpdateEventSourceMapping_598191; UUID: string;
          body: JsonNode): Recallable =
  ## updateEventSourceMapping
  ## <p>Updates an event source mapping. You can change the function that AWS Lambda invokes, or pause invocation and resume later from the same location.</p> <p>The following error handling options are only available for stream sources (DynamoDB and Kinesis):</p> <ul> <li> <p> <code>BisectBatchOnFunctionError</code> - If the function returns an error, split the batch in two and retry.</p> </li> <li> <p> <code>DestinationConfig</code> - Send discarded records to an Amazon SQS queue or Amazon SNS topic.</p> </li> <li> <p> <code>MaximumRecordAgeInSeconds</code> - Discard records older than the specified age.</p> </li> <li> <p> <code>MaximumRetryAttempts</code> - Discard records after the specified number of retries.</p> </li> </ul>
  ##   UUID: string (required)
  ##       : The identifier of the event source mapping.
  ##   body: JObject (required)
  var path_598205 = newJObject()
  var body_598206 = newJObject()
  add(path_598205, "UUID", newJString(UUID))
  if body != nil:
    body_598206 = body
  result = call_598204.call(path_598205, nil, nil, nil, body_598206)

var updateEventSourceMapping* = Call_UpdateEventSourceMapping_598191(
    name: "updateEventSourceMapping", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/event-source-mappings/{UUID}",
    validator: validate_UpdateEventSourceMapping_598192, base: "/",
    url: url_UpdateEventSourceMapping_598193, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEventSourceMapping_598177 = ref object of OpenApiRestCall_597389
proc url_GetEventSourceMapping_598179(protocol: Scheme; host: string; base: string;
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

proc validate_GetEventSourceMapping_598178(path: JsonNode; query: JsonNode;
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
  var valid_598180 = path.getOrDefault("UUID")
  valid_598180 = validateParameter(valid_598180, JString, required = true,
                                 default = nil)
  if valid_598180 != nil:
    section.add "UUID", valid_598180
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
  var valid_598181 = header.getOrDefault("X-Amz-Signature")
  valid_598181 = validateParameter(valid_598181, JString, required = false,
                                 default = nil)
  if valid_598181 != nil:
    section.add "X-Amz-Signature", valid_598181
  var valid_598182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598182 = validateParameter(valid_598182, JString, required = false,
                                 default = nil)
  if valid_598182 != nil:
    section.add "X-Amz-Content-Sha256", valid_598182
  var valid_598183 = header.getOrDefault("X-Amz-Date")
  valid_598183 = validateParameter(valid_598183, JString, required = false,
                                 default = nil)
  if valid_598183 != nil:
    section.add "X-Amz-Date", valid_598183
  var valid_598184 = header.getOrDefault("X-Amz-Credential")
  valid_598184 = validateParameter(valid_598184, JString, required = false,
                                 default = nil)
  if valid_598184 != nil:
    section.add "X-Amz-Credential", valid_598184
  var valid_598185 = header.getOrDefault("X-Amz-Security-Token")
  valid_598185 = validateParameter(valid_598185, JString, required = false,
                                 default = nil)
  if valid_598185 != nil:
    section.add "X-Amz-Security-Token", valid_598185
  var valid_598186 = header.getOrDefault("X-Amz-Algorithm")
  valid_598186 = validateParameter(valid_598186, JString, required = false,
                                 default = nil)
  if valid_598186 != nil:
    section.add "X-Amz-Algorithm", valid_598186
  var valid_598187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598187 = validateParameter(valid_598187, JString, required = false,
                                 default = nil)
  if valid_598187 != nil:
    section.add "X-Amz-SignedHeaders", valid_598187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598188: Call_GetEventSourceMapping_598177; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns details about an event source mapping. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.
  ## 
  let valid = call_598188.validator(path, query, header, formData, body)
  let scheme = call_598188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598188.url(scheme.get, call_598188.host, call_598188.base,
                         call_598188.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598188, url, valid)

proc call*(call_598189: Call_GetEventSourceMapping_598177; UUID: string): Recallable =
  ## getEventSourceMapping
  ## Returns details about an event source mapping. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.
  ##   UUID: string (required)
  ##       : The identifier of the event source mapping.
  var path_598190 = newJObject()
  add(path_598190, "UUID", newJString(UUID))
  result = call_598189.call(path_598190, nil, nil, nil, nil)

var getEventSourceMapping* = Call_GetEventSourceMapping_598177(
    name: "getEventSourceMapping", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/event-source-mappings/{UUID}",
    validator: validate_GetEventSourceMapping_598178, base: "/",
    url: url_GetEventSourceMapping_598179, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEventSourceMapping_598207 = ref object of OpenApiRestCall_597389
proc url_DeleteEventSourceMapping_598209(protocol: Scheme; host: string;
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

proc validate_DeleteEventSourceMapping_598208(path: JsonNode; query: JsonNode;
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
  var valid_598210 = path.getOrDefault("UUID")
  valid_598210 = validateParameter(valid_598210, JString, required = true,
                                 default = nil)
  if valid_598210 != nil:
    section.add "UUID", valid_598210
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
  var valid_598211 = header.getOrDefault("X-Amz-Signature")
  valid_598211 = validateParameter(valid_598211, JString, required = false,
                                 default = nil)
  if valid_598211 != nil:
    section.add "X-Amz-Signature", valid_598211
  var valid_598212 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598212 = validateParameter(valid_598212, JString, required = false,
                                 default = nil)
  if valid_598212 != nil:
    section.add "X-Amz-Content-Sha256", valid_598212
  var valid_598213 = header.getOrDefault("X-Amz-Date")
  valid_598213 = validateParameter(valid_598213, JString, required = false,
                                 default = nil)
  if valid_598213 != nil:
    section.add "X-Amz-Date", valid_598213
  var valid_598214 = header.getOrDefault("X-Amz-Credential")
  valid_598214 = validateParameter(valid_598214, JString, required = false,
                                 default = nil)
  if valid_598214 != nil:
    section.add "X-Amz-Credential", valid_598214
  var valid_598215 = header.getOrDefault("X-Amz-Security-Token")
  valid_598215 = validateParameter(valid_598215, JString, required = false,
                                 default = nil)
  if valid_598215 != nil:
    section.add "X-Amz-Security-Token", valid_598215
  var valid_598216 = header.getOrDefault("X-Amz-Algorithm")
  valid_598216 = validateParameter(valid_598216, JString, required = false,
                                 default = nil)
  if valid_598216 != nil:
    section.add "X-Amz-Algorithm", valid_598216
  var valid_598217 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598217 = validateParameter(valid_598217, JString, required = false,
                                 default = nil)
  if valid_598217 != nil:
    section.add "X-Amz-SignedHeaders", valid_598217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598218: Call_DeleteEventSourceMapping_598207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-invocation-modes.html">event source mapping</a>. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.</p> <p>When you delete an event source mapping, it enters a <code>Deleting</code> state and might not be completely deleted for several seconds.</p>
  ## 
  let valid = call_598218.validator(path, query, header, formData, body)
  let scheme = call_598218.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598218.url(scheme.get, call_598218.host, call_598218.base,
                         call_598218.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598218, url, valid)

proc call*(call_598219: Call_DeleteEventSourceMapping_598207; UUID: string): Recallable =
  ## deleteEventSourceMapping
  ## <p>Deletes an <a href="https://docs.aws.amazon.com/lambda/latest/dg/intro-invocation-modes.html">event source mapping</a>. You can get the identifier of a mapping from the output of <a>ListEventSourceMappings</a>.</p> <p>When you delete an event source mapping, it enters a <code>Deleting</code> state and might not be completely deleted for several seconds.</p>
  ##   UUID: string (required)
  ##       : The identifier of the event source mapping.
  var path_598220 = newJObject()
  add(path_598220, "UUID", newJString(UUID))
  result = call_598219.call(path_598220, nil, nil, nil, nil)

var deleteEventSourceMapping* = Call_DeleteEventSourceMapping_598207(
    name: "deleteEventSourceMapping", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/event-source-mappings/{UUID}",
    validator: validate_DeleteEventSourceMapping_598208, base: "/",
    url: url_DeleteEventSourceMapping_598209, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunction_598221 = ref object of OpenApiRestCall_597389
proc url_GetFunction_598223(protocol: Scheme; host: string; base: string;
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

proc validate_GetFunction_598222(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598224 = path.getOrDefault("FunctionName")
  valid_598224 = validateParameter(valid_598224, JString, required = true,
                                 default = nil)
  if valid_598224 != nil:
    section.add "FunctionName", valid_598224
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to get details about a published version of the function.
  section = newJObject()
  var valid_598225 = query.getOrDefault("Qualifier")
  valid_598225 = validateParameter(valid_598225, JString, required = false,
                                 default = nil)
  if valid_598225 != nil:
    section.add "Qualifier", valid_598225
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
  var valid_598226 = header.getOrDefault("X-Amz-Signature")
  valid_598226 = validateParameter(valid_598226, JString, required = false,
                                 default = nil)
  if valid_598226 != nil:
    section.add "X-Amz-Signature", valid_598226
  var valid_598227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598227 = validateParameter(valid_598227, JString, required = false,
                                 default = nil)
  if valid_598227 != nil:
    section.add "X-Amz-Content-Sha256", valid_598227
  var valid_598228 = header.getOrDefault("X-Amz-Date")
  valid_598228 = validateParameter(valid_598228, JString, required = false,
                                 default = nil)
  if valid_598228 != nil:
    section.add "X-Amz-Date", valid_598228
  var valid_598229 = header.getOrDefault("X-Amz-Credential")
  valid_598229 = validateParameter(valid_598229, JString, required = false,
                                 default = nil)
  if valid_598229 != nil:
    section.add "X-Amz-Credential", valid_598229
  var valid_598230 = header.getOrDefault("X-Amz-Security-Token")
  valid_598230 = validateParameter(valid_598230, JString, required = false,
                                 default = nil)
  if valid_598230 != nil:
    section.add "X-Amz-Security-Token", valid_598230
  var valid_598231 = header.getOrDefault("X-Amz-Algorithm")
  valid_598231 = validateParameter(valid_598231, JString, required = false,
                                 default = nil)
  if valid_598231 != nil:
    section.add "X-Amz-Algorithm", valid_598231
  var valid_598232 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598232 = validateParameter(valid_598232, JString, required = false,
                                 default = nil)
  if valid_598232 != nil:
    section.add "X-Amz-SignedHeaders", valid_598232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598233: Call_GetFunction_598221; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about the function or function version, with a link to download the deployment package that's valid for 10 minutes. If you specify a function version, only details that are specific to that version are returned.
  ## 
  let valid = call_598233.validator(path, query, header, formData, body)
  let scheme = call_598233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598233.url(scheme.get, call_598233.host, call_598233.base,
                         call_598233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598233, url, valid)

proc call*(call_598234: Call_GetFunction_598221; FunctionName: string;
          Qualifier: string = ""): Recallable =
  ## getFunction
  ## Returns information about the function or function version, with a link to download the deployment package that's valid for 10 minutes. If you specify a function version, only details that are specific to that version are returned.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to get details about a published version of the function.
  var path_598235 = newJObject()
  var query_598236 = newJObject()
  add(path_598235, "FunctionName", newJString(FunctionName))
  add(query_598236, "Qualifier", newJString(Qualifier))
  result = call_598234.call(path_598235, query_598236, nil, nil, nil)

var getFunction* = Call_GetFunction_598221(name: "getFunction",
                                        meth: HttpMethod.HttpGet,
                                        host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}",
                                        validator: validate_GetFunction_598222,
                                        base: "/", url: url_GetFunction_598223,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunction_598237 = ref object of OpenApiRestCall_597389
proc url_DeleteFunction_598239(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFunction_598238(path: JsonNode; query: JsonNode;
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
  var valid_598240 = path.getOrDefault("FunctionName")
  valid_598240 = validateParameter(valid_598240, JString, required = true,
                                 default = nil)
  if valid_598240 != nil:
    section.add "FunctionName", valid_598240
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version to delete. You can't delete a version that's referenced by an alias.
  section = newJObject()
  var valid_598241 = query.getOrDefault("Qualifier")
  valid_598241 = validateParameter(valid_598241, JString, required = false,
                                 default = nil)
  if valid_598241 != nil:
    section.add "Qualifier", valid_598241
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
  var valid_598242 = header.getOrDefault("X-Amz-Signature")
  valid_598242 = validateParameter(valid_598242, JString, required = false,
                                 default = nil)
  if valid_598242 != nil:
    section.add "X-Amz-Signature", valid_598242
  var valid_598243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598243 = validateParameter(valid_598243, JString, required = false,
                                 default = nil)
  if valid_598243 != nil:
    section.add "X-Amz-Content-Sha256", valid_598243
  var valid_598244 = header.getOrDefault("X-Amz-Date")
  valid_598244 = validateParameter(valid_598244, JString, required = false,
                                 default = nil)
  if valid_598244 != nil:
    section.add "X-Amz-Date", valid_598244
  var valid_598245 = header.getOrDefault("X-Amz-Credential")
  valid_598245 = validateParameter(valid_598245, JString, required = false,
                                 default = nil)
  if valid_598245 != nil:
    section.add "X-Amz-Credential", valid_598245
  var valid_598246 = header.getOrDefault("X-Amz-Security-Token")
  valid_598246 = validateParameter(valid_598246, JString, required = false,
                                 default = nil)
  if valid_598246 != nil:
    section.add "X-Amz-Security-Token", valid_598246
  var valid_598247 = header.getOrDefault("X-Amz-Algorithm")
  valid_598247 = validateParameter(valid_598247, JString, required = false,
                                 default = nil)
  if valid_598247 != nil:
    section.add "X-Amz-Algorithm", valid_598247
  var valid_598248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598248 = validateParameter(valid_598248, JString, required = false,
                                 default = nil)
  if valid_598248 != nil:
    section.add "X-Amz-SignedHeaders", valid_598248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598249: Call_DeleteFunction_598237; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a Lambda function. To delete a specific function version, use the <code>Qualifier</code> parameter. Otherwise, all versions and aliases are deleted.</p> <p>To delete Lambda event source mappings that invoke a function, use <a>DeleteEventSourceMapping</a>. For AWS services and resources that invoke your function directly, delete the trigger in the service where you originally configured it.</p>
  ## 
  let valid = call_598249.validator(path, query, header, formData, body)
  let scheme = call_598249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598249.url(scheme.get, call_598249.host, call_598249.base,
                         call_598249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598249, url, valid)

proc call*(call_598250: Call_DeleteFunction_598237; FunctionName: string;
          Qualifier: string = ""): Recallable =
  ## deleteFunction
  ## <p>Deletes a Lambda function. To delete a specific function version, use the <code>Qualifier</code> parameter. Otherwise, all versions and aliases are deleted.</p> <p>To delete Lambda event source mappings that invoke a function, use <a>DeleteEventSourceMapping</a>. For AWS services and resources that invoke your function directly, delete the trigger in the service where you originally configured it.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function or version.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:1</code> (with version).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version to delete. You can't delete a version that's referenced by an alias.
  var path_598251 = newJObject()
  var query_598252 = newJObject()
  add(path_598251, "FunctionName", newJString(FunctionName))
  add(query_598252, "Qualifier", newJString(Qualifier))
  result = call_598250.call(path_598251, query_598252, nil, nil, nil)

var deleteFunction* = Call_DeleteFunction_598237(name: "deleteFunction",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}",
    validator: validate_DeleteFunction_598238, base: "/", url: url_DeleteFunction_598239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutFunctionConcurrency_598253 = ref object of OpenApiRestCall_597389
proc url_PutFunctionConcurrency_598255(protocol: Scheme; host: string; base: string;
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

proc validate_PutFunctionConcurrency_598254(path: JsonNode; query: JsonNode;
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
  var valid_598256 = path.getOrDefault("FunctionName")
  valid_598256 = validateParameter(valid_598256, JString, required = true,
                                 default = nil)
  if valid_598256 != nil:
    section.add "FunctionName", valid_598256
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
  var valid_598257 = header.getOrDefault("X-Amz-Signature")
  valid_598257 = validateParameter(valid_598257, JString, required = false,
                                 default = nil)
  if valid_598257 != nil:
    section.add "X-Amz-Signature", valid_598257
  var valid_598258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598258 = validateParameter(valid_598258, JString, required = false,
                                 default = nil)
  if valid_598258 != nil:
    section.add "X-Amz-Content-Sha256", valid_598258
  var valid_598259 = header.getOrDefault("X-Amz-Date")
  valid_598259 = validateParameter(valid_598259, JString, required = false,
                                 default = nil)
  if valid_598259 != nil:
    section.add "X-Amz-Date", valid_598259
  var valid_598260 = header.getOrDefault("X-Amz-Credential")
  valid_598260 = validateParameter(valid_598260, JString, required = false,
                                 default = nil)
  if valid_598260 != nil:
    section.add "X-Amz-Credential", valid_598260
  var valid_598261 = header.getOrDefault("X-Amz-Security-Token")
  valid_598261 = validateParameter(valid_598261, JString, required = false,
                                 default = nil)
  if valid_598261 != nil:
    section.add "X-Amz-Security-Token", valid_598261
  var valid_598262 = header.getOrDefault("X-Amz-Algorithm")
  valid_598262 = validateParameter(valid_598262, JString, required = false,
                                 default = nil)
  if valid_598262 != nil:
    section.add "X-Amz-Algorithm", valid_598262
  var valid_598263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598263 = validateParameter(valid_598263, JString, required = false,
                                 default = nil)
  if valid_598263 != nil:
    section.add "X-Amz-SignedHeaders", valid_598263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598265: Call_PutFunctionConcurrency_598253; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Sets the maximum number of simultaneous executions for a function, and reserves capacity for that concurrency level.</p> <p>Concurrency settings apply to the function as a whole, including all published versions and the unpublished version. Reserving concurrency both ensures that your function has capacity to process the specified number of events simultaneously, and prevents it from scaling beyond that level. Use <a>GetFunction</a> to see the current setting for a function.</p> <p>Use <a>GetAccountSettings</a> to see your Regional concurrency limit. You can reserve concurrency for as many functions as you like, as long as you leave at least 100 simultaneous executions unreserved for functions that aren't configured with a per-function limit. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/concurrent-executions.html">Managing Concurrency</a>.</p>
  ## 
  let valid = call_598265.validator(path, query, header, formData, body)
  let scheme = call_598265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598265.url(scheme.get, call_598265.host, call_598265.base,
                         call_598265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598265, url, valid)

proc call*(call_598266: Call_PutFunctionConcurrency_598253; FunctionName: string;
          body: JsonNode): Recallable =
  ## putFunctionConcurrency
  ## <p>Sets the maximum number of simultaneous executions for a function, and reserves capacity for that concurrency level.</p> <p>Concurrency settings apply to the function as a whole, including all published versions and the unpublished version. Reserving concurrency both ensures that your function has capacity to process the specified number of events simultaneously, and prevents it from scaling beyond that level. Use <a>GetFunction</a> to see the current setting for a function.</p> <p>Use <a>GetAccountSettings</a> to see your Regional concurrency limit. You can reserve concurrency for as many functions as you like, as long as you leave at least 100 simultaneous executions unreserved for functions that aren't configured with a per-function limit. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/concurrent-executions.html">Managing Concurrency</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_598267 = newJObject()
  var body_598268 = newJObject()
  add(path_598267, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_598268 = body
  result = call_598266.call(path_598267, nil, nil, nil, body_598268)

var putFunctionConcurrency* = Call_PutFunctionConcurrency_598253(
    name: "putFunctionConcurrency", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2017-10-31/functions/{FunctionName}/concurrency",
    validator: validate_PutFunctionConcurrency_598254, base: "/",
    url: url_PutFunctionConcurrency_598255, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunctionConcurrency_598269 = ref object of OpenApiRestCall_597389
proc url_DeleteFunctionConcurrency_598271(protocol: Scheme; host: string;
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

proc validate_DeleteFunctionConcurrency_598270(path: JsonNode; query: JsonNode;
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
  var valid_598272 = path.getOrDefault("FunctionName")
  valid_598272 = validateParameter(valid_598272, JString, required = true,
                                 default = nil)
  if valid_598272 != nil:
    section.add "FunctionName", valid_598272
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
  var valid_598273 = header.getOrDefault("X-Amz-Signature")
  valid_598273 = validateParameter(valid_598273, JString, required = false,
                                 default = nil)
  if valid_598273 != nil:
    section.add "X-Amz-Signature", valid_598273
  var valid_598274 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598274 = validateParameter(valid_598274, JString, required = false,
                                 default = nil)
  if valid_598274 != nil:
    section.add "X-Amz-Content-Sha256", valid_598274
  var valid_598275 = header.getOrDefault("X-Amz-Date")
  valid_598275 = validateParameter(valid_598275, JString, required = false,
                                 default = nil)
  if valid_598275 != nil:
    section.add "X-Amz-Date", valid_598275
  var valid_598276 = header.getOrDefault("X-Amz-Credential")
  valid_598276 = validateParameter(valid_598276, JString, required = false,
                                 default = nil)
  if valid_598276 != nil:
    section.add "X-Amz-Credential", valid_598276
  var valid_598277 = header.getOrDefault("X-Amz-Security-Token")
  valid_598277 = validateParameter(valid_598277, JString, required = false,
                                 default = nil)
  if valid_598277 != nil:
    section.add "X-Amz-Security-Token", valid_598277
  var valid_598278 = header.getOrDefault("X-Amz-Algorithm")
  valid_598278 = validateParameter(valid_598278, JString, required = false,
                                 default = nil)
  if valid_598278 != nil:
    section.add "X-Amz-Algorithm", valid_598278
  var valid_598279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598279 = validateParameter(valid_598279, JString, required = false,
                                 default = nil)
  if valid_598279 != nil:
    section.add "X-Amz-SignedHeaders", valid_598279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598280: Call_DeleteFunctionConcurrency_598269; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a concurrent execution limit from a function.
  ## 
  let valid = call_598280.validator(path, query, header, formData, body)
  let scheme = call_598280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598280.url(scheme.get, call_598280.host, call_598280.base,
                         call_598280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598280, url, valid)

proc call*(call_598281: Call_DeleteFunctionConcurrency_598269; FunctionName: string): Recallable =
  ## deleteFunctionConcurrency
  ## Removes a concurrent execution limit from a function.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  var path_598282 = newJObject()
  add(path_598282, "FunctionName", newJString(FunctionName))
  result = call_598281.call(path_598282, nil, nil, nil, nil)

var deleteFunctionConcurrency* = Call_DeleteFunctionConcurrency_598269(
    name: "deleteFunctionConcurrency", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com",
    route: "/2017-10-31/functions/{FunctionName}/concurrency",
    validator: validate_DeleteFunctionConcurrency_598270, base: "/",
    url: url_DeleteFunctionConcurrency_598271,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutFunctionEventInvokeConfig_598299 = ref object of OpenApiRestCall_597389
proc url_PutFunctionEventInvokeConfig_598301(protocol: Scheme; host: string;
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

proc validate_PutFunctionEventInvokeConfig_598300(path: JsonNode; query: JsonNode;
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
  var valid_598302 = path.getOrDefault("FunctionName")
  valid_598302 = validateParameter(valid_598302, JString, required = true,
                                 default = nil)
  if valid_598302 != nil:
    section.add "FunctionName", valid_598302
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : A version number or alias name.
  section = newJObject()
  var valid_598303 = query.getOrDefault("Qualifier")
  valid_598303 = validateParameter(valid_598303, JString, required = false,
                                 default = nil)
  if valid_598303 != nil:
    section.add "Qualifier", valid_598303
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
  var valid_598304 = header.getOrDefault("X-Amz-Signature")
  valid_598304 = validateParameter(valid_598304, JString, required = false,
                                 default = nil)
  if valid_598304 != nil:
    section.add "X-Amz-Signature", valid_598304
  var valid_598305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598305 = validateParameter(valid_598305, JString, required = false,
                                 default = nil)
  if valid_598305 != nil:
    section.add "X-Amz-Content-Sha256", valid_598305
  var valid_598306 = header.getOrDefault("X-Amz-Date")
  valid_598306 = validateParameter(valid_598306, JString, required = false,
                                 default = nil)
  if valid_598306 != nil:
    section.add "X-Amz-Date", valid_598306
  var valid_598307 = header.getOrDefault("X-Amz-Credential")
  valid_598307 = validateParameter(valid_598307, JString, required = false,
                                 default = nil)
  if valid_598307 != nil:
    section.add "X-Amz-Credential", valid_598307
  var valid_598308 = header.getOrDefault("X-Amz-Security-Token")
  valid_598308 = validateParameter(valid_598308, JString, required = false,
                                 default = nil)
  if valid_598308 != nil:
    section.add "X-Amz-Security-Token", valid_598308
  var valid_598309 = header.getOrDefault("X-Amz-Algorithm")
  valid_598309 = validateParameter(valid_598309, JString, required = false,
                                 default = nil)
  if valid_598309 != nil:
    section.add "X-Amz-Algorithm", valid_598309
  var valid_598310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598310 = validateParameter(valid_598310, JString, required = false,
                                 default = nil)
  if valid_598310 != nil:
    section.add "X-Amz-SignedHeaders", valid_598310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598312: Call_PutFunctionEventInvokeConfig_598299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Configures options for <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a> on a function, version, or alias.</p> <p>By default, Lambda retries an asynchronous invocation twice if the function returns an error. It retains events in a queue for up to six hours. When an event fails all processing attempts or stays in the asynchronous invocation queue for too long, Lambda discards it. To retain discarded events, configure a dead-letter queue with <a>UpdateFunctionConfiguration</a>.</p>
  ## 
  let valid = call_598312.validator(path, query, header, formData, body)
  let scheme = call_598312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598312.url(scheme.get, call_598312.host, call_598312.base,
                         call_598312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598312, url, valid)

proc call*(call_598313: Call_PutFunctionEventInvokeConfig_598299;
          FunctionName: string; body: JsonNode; Qualifier: string = ""): Recallable =
  ## putFunctionEventInvokeConfig
  ## <p>Configures options for <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a> on a function, version, or alias.</p> <p>By default, Lambda retries an asynchronous invocation twice if the function returns an error. It retains events in a queue for up to six hours. When an event fails all processing attempts or stays in the asynchronous invocation queue for too long, Lambda discards it. To retain discarded events, configure a dead-letter queue with <a>UpdateFunctionConfiguration</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : A version number or alias name.
  ##   body: JObject (required)
  var path_598314 = newJObject()
  var query_598315 = newJObject()
  var body_598316 = newJObject()
  add(path_598314, "FunctionName", newJString(FunctionName))
  add(query_598315, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_598316 = body
  result = call_598313.call(path_598314, query_598315, nil, nil, body_598316)

var putFunctionEventInvokeConfig* = Call_PutFunctionEventInvokeConfig_598299(
    name: "putFunctionEventInvokeConfig", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config",
    validator: validate_PutFunctionEventInvokeConfig_598300, base: "/",
    url: url_PutFunctionEventInvokeConfig_598301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionEventInvokeConfig_598317 = ref object of OpenApiRestCall_597389
proc url_UpdateFunctionEventInvokeConfig_598319(protocol: Scheme; host: string;
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

proc validate_UpdateFunctionEventInvokeConfig_598318(path: JsonNode;
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
  var valid_598320 = path.getOrDefault("FunctionName")
  valid_598320 = validateParameter(valid_598320, JString, required = true,
                                 default = nil)
  if valid_598320 != nil:
    section.add "FunctionName", valid_598320
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : A version number or alias name.
  section = newJObject()
  var valid_598321 = query.getOrDefault("Qualifier")
  valid_598321 = validateParameter(valid_598321, JString, required = false,
                                 default = nil)
  if valid_598321 != nil:
    section.add "Qualifier", valid_598321
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
  var valid_598322 = header.getOrDefault("X-Amz-Signature")
  valid_598322 = validateParameter(valid_598322, JString, required = false,
                                 default = nil)
  if valid_598322 != nil:
    section.add "X-Amz-Signature", valid_598322
  var valid_598323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598323 = validateParameter(valid_598323, JString, required = false,
                                 default = nil)
  if valid_598323 != nil:
    section.add "X-Amz-Content-Sha256", valid_598323
  var valid_598324 = header.getOrDefault("X-Amz-Date")
  valid_598324 = validateParameter(valid_598324, JString, required = false,
                                 default = nil)
  if valid_598324 != nil:
    section.add "X-Amz-Date", valid_598324
  var valid_598325 = header.getOrDefault("X-Amz-Credential")
  valid_598325 = validateParameter(valid_598325, JString, required = false,
                                 default = nil)
  if valid_598325 != nil:
    section.add "X-Amz-Credential", valid_598325
  var valid_598326 = header.getOrDefault("X-Amz-Security-Token")
  valid_598326 = validateParameter(valid_598326, JString, required = false,
                                 default = nil)
  if valid_598326 != nil:
    section.add "X-Amz-Security-Token", valid_598326
  var valid_598327 = header.getOrDefault("X-Amz-Algorithm")
  valid_598327 = validateParameter(valid_598327, JString, required = false,
                                 default = nil)
  if valid_598327 != nil:
    section.add "X-Amz-Algorithm", valid_598327
  var valid_598328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598328 = validateParameter(valid_598328, JString, required = false,
                                 default = nil)
  if valid_598328 != nil:
    section.add "X-Amz-SignedHeaders", valid_598328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598330: Call_UpdateFunctionEventInvokeConfig_598317;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Updates the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  let valid = call_598330.validator(path, query, header, formData, body)
  let scheme = call_598330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598330.url(scheme.get, call_598330.host, call_598330.base,
                         call_598330.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598330, url, valid)

proc call*(call_598331: Call_UpdateFunctionEventInvokeConfig_598317;
          FunctionName: string; body: JsonNode; Qualifier: string = ""): Recallable =
  ## updateFunctionEventInvokeConfig
  ## <p>Updates the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : A version number or alias name.
  ##   body: JObject (required)
  var path_598332 = newJObject()
  var query_598333 = newJObject()
  var body_598334 = newJObject()
  add(path_598332, "FunctionName", newJString(FunctionName))
  add(query_598333, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_598334 = body
  result = call_598331.call(path_598332, query_598333, nil, nil, body_598334)

var updateFunctionEventInvokeConfig* = Call_UpdateFunctionEventInvokeConfig_598317(
    name: "updateFunctionEventInvokeConfig", meth: HttpMethod.HttpPost,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config",
    validator: validate_UpdateFunctionEventInvokeConfig_598318, base: "/",
    url: url_UpdateFunctionEventInvokeConfig_598319,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionEventInvokeConfig_598283 = ref object of OpenApiRestCall_597389
proc url_GetFunctionEventInvokeConfig_598285(protocol: Scheme; host: string;
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

proc validate_GetFunctionEventInvokeConfig_598284(path: JsonNode; query: JsonNode;
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
  var valid_598286 = path.getOrDefault("FunctionName")
  valid_598286 = validateParameter(valid_598286, JString, required = true,
                                 default = nil)
  if valid_598286 != nil:
    section.add "FunctionName", valid_598286
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : A version number or alias name.
  section = newJObject()
  var valid_598287 = query.getOrDefault("Qualifier")
  valid_598287 = validateParameter(valid_598287, JString, required = false,
                                 default = nil)
  if valid_598287 != nil:
    section.add "Qualifier", valid_598287
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
  var valid_598288 = header.getOrDefault("X-Amz-Signature")
  valid_598288 = validateParameter(valid_598288, JString, required = false,
                                 default = nil)
  if valid_598288 != nil:
    section.add "X-Amz-Signature", valid_598288
  var valid_598289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598289 = validateParameter(valid_598289, JString, required = false,
                                 default = nil)
  if valid_598289 != nil:
    section.add "X-Amz-Content-Sha256", valid_598289
  var valid_598290 = header.getOrDefault("X-Amz-Date")
  valid_598290 = validateParameter(valid_598290, JString, required = false,
                                 default = nil)
  if valid_598290 != nil:
    section.add "X-Amz-Date", valid_598290
  var valid_598291 = header.getOrDefault("X-Amz-Credential")
  valid_598291 = validateParameter(valid_598291, JString, required = false,
                                 default = nil)
  if valid_598291 != nil:
    section.add "X-Amz-Credential", valid_598291
  var valid_598292 = header.getOrDefault("X-Amz-Security-Token")
  valid_598292 = validateParameter(valid_598292, JString, required = false,
                                 default = nil)
  if valid_598292 != nil:
    section.add "X-Amz-Security-Token", valid_598292
  var valid_598293 = header.getOrDefault("X-Amz-Algorithm")
  valid_598293 = validateParameter(valid_598293, JString, required = false,
                                 default = nil)
  if valid_598293 != nil:
    section.add "X-Amz-Algorithm", valid_598293
  var valid_598294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598294 = validateParameter(valid_598294, JString, required = false,
                                 default = nil)
  if valid_598294 != nil:
    section.add "X-Amz-SignedHeaders", valid_598294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598295: Call_GetFunctionEventInvokeConfig_598283; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  let valid = call_598295.validator(path, query, header, formData, body)
  let scheme = call_598295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598295.url(scheme.get, call_598295.host, call_598295.base,
                         call_598295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598295, url, valid)

proc call*(call_598296: Call_GetFunctionEventInvokeConfig_598283;
          FunctionName: string; Qualifier: string = ""): Recallable =
  ## getFunctionEventInvokeConfig
  ## <p>Retrieves the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : A version number or alias name.
  var path_598297 = newJObject()
  var query_598298 = newJObject()
  add(path_598297, "FunctionName", newJString(FunctionName))
  add(query_598298, "Qualifier", newJString(Qualifier))
  result = call_598296.call(path_598297, query_598298, nil, nil, nil)

var getFunctionEventInvokeConfig* = Call_GetFunctionEventInvokeConfig_598283(
    name: "getFunctionEventInvokeConfig", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config",
    validator: validate_GetFunctionEventInvokeConfig_598284, base: "/",
    url: url_GetFunctionEventInvokeConfig_598285,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFunctionEventInvokeConfig_598335 = ref object of OpenApiRestCall_597389
proc url_DeleteFunctionEventInvokeConfig_598337(protocol: Scheme; host: string;
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

proc validate_DeleteFunctionEventInvokeConfig_598336(path: JsonNode;
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
  var valid_598338 = path.getOrDefault("FunctionName")
  valid_598338 = validateParameter(valid_598338, JString, required = true,
                                 default = nil)
  if valid_598338 != nil:
    section.add "FunctionName", valid_598338
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : A version number or alias name.
  section = newJObject()
  var valid_598339 = query.getOrDefault("Qualifier")
  valid_598339 = validateParameter(valid_598339, JString, required = false,
                                 default = nil)
  if valid_598339 != nil:
    section.add "Qualifier", valid_598339
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
  var valid_598340 = header.getOrDefault("X-Amz-Signature")
  valid_598340 = validateParameter(valid_598340, JString, required = false,
                                 default = nil)
  if valid_598340 != nil:
    section.add "X-Amz-Signature", valid_598340
  var valid_598341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598341 = validateParameter(valid_598341, JString, required = false,
                                 default = nil)
  if valid_598341 != nil:
    section.add "X-Amz-Content-Sha256", valid_598341
  var valid_598342 = header.getOrDefault("X-Amz-Date")
  valid_598342 = validateParameter(valid_598342, JString, required = false,
                                 default = nil)
  if valid_598342 != nil:
    section.add "X-Amz-Date", valid_598342
  var valid_598343 = header.getOrDefault("X-Amz-Credential")
  valid_598343 = validateParameter(valid_598343, JString, required = false,
                                 default = nil)
  if valid_598343 != nil:
    section.add "X-Amz-Credential", valid_598343
  var valid_598344 = header.getOrDefault("X-Amz-Security-Token")
  valid_598344 = validateParameter(valid_598344, JString, required = false,
                                 default = nil)
  if valid_598344 != nil:
    section.add "X-Amz-Security-Token", valid_598344
  var valid_598345 = header.getOrDefault("X-Amz-Algorithm")
  valid_598345 = validateParameter(valid_598345, JString, required = false,
                                 default = nil)
  if valid_598345 != nil:
    section.add "X-Amz-Algorithm", valid_598345
  var valid_598346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598346 = validateParameter(valid_598346, JString, required = false,
                                 default = nil)
  if valid_598346 != nil:
    section.add "X-Amz-SignedHeaders", valid_598346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598347: Call_DeleteFunctionEventInvokeConfig_598335;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Deletes the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  let valid = call_598347.validator(path, query, header, formData, body)
  let scheme = call_598347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598347.url(scheme.get, call_598347.host, call_598347.base,
                         call_598347.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598347, url, valid)

proc call*(call_598348: Call_DeleteFunctionEventInvokeConfig_598335;
          FunctionName: string; Qualifier: string = ""): Recallable =
  ## deleteFunctionEventInvokeConfig
  ## <p>Deletes the configuration for asynchronous invocation for a function, version, or alias.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : A version number or alias name.
  var path_598349 = newJObject()
  var query_598350 = newJObject()
  add(path_598349, "FunctionName", newJString(FunctionName))
  add(query_598350, "Qualifier", newJString(Qualifier))
  result = call_598348.call(path_598349, query_598350, nil, nil, nil)

var deleteFunctionEventInvokeConfig* = Call_DeleteFunctionEventInvokeConfig_598335(
    name: "deleteFunctionEventInvokeConfig", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config",
    validator: validate_DeleteFunctionEventInvokeConfig_598336, base: "/",
    url: url_DeleteFunctionEventInvokeConfig_598337,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLayerVersion_598351 = ref object of OpenApiRestCall_597389
proc url_GetLayerVersion_598353(protocol: Scheme; host: string; base: string;
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

proc validate_GetLayerVersion_598352(path: JsonNode; query: JsonNode;
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
  var valid_598354 = path.getOrDefault("VersionNumber")
  valid_598354 = validateParameter(valid_598354, JInt, required = true, default = nil)
  if valid_598354 != nil:
    section.add "VersionNumber", valid_598354
  var valid_598355 = path.getOrDefault("LayerName")
  valid_598355 = validateParameter(valid_598355, JString, required = true,
                                 default = nil)
  if valid_598355 != nil:
    section.add "LayerName", valid_598355
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
  var valid_598356 = header.getOrDefault("X-Amz-Signature")
  valid_598356 = validateParameter(valid_598356, JString, required = false,
                                 default = nil)
  if valid_598356 != nil:
    section.add "X-Amz-Signature", valid_598356
  var valid_598357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598357 = validateParameter(valid_598357, JString, required = false,
                                 default = nil)
  if valid_598357 != nil:
    section.add "X-Amz-Content-Sha256", valid_598357
  var valid_598358 = header.getOrDefault("X-Amz-Date")
  valid_598358 = validateParameter(valid_598358, JString, required = false,
                                 default = nil)
  if valid_598358 != nil:
    section.add "X-Amz-Date", valid_598358
  var valid_598359 = header.getOrDefault("X-Amz-Credential")
  valid_598359 = validateParameter(valid_598359, JString, required = false,
                                 default = nil)
  if valid_598359 != nil:
    section.add "X-Amz-Credential", valid_598359
  var valid_598360 = header.getOrDefault("X-Amz-Security-Token")
  valid_598360 = validateParameter(valid_598360, JString, required = false,
                                 default = nil)
  if valid_598360 != nil:
    section.add "X-Amz-Security-Token", valid_598360
  var valid_598361 = header.getOrDefault("X-Amz-Algorithm")
  valid_598361 = validateParameter(valid_598361, JString, required = false,
                                 default = nil)
  if valid_598361 != nil:
    section.add "X-Amz-Algorithm", valid_598361
  var valid_598362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598362 = validateParameter(valid_598362, JString, required = false,
                                 default = nil)
  if valid_598362 != nil:
    section.add "X-Amz-SignedHeaders", valid_598362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598363: Call_GetLayerVersion_598351; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ## 
  let valid = call_598363.validator(path, query, header, formData, body)
  let scheme = call_598363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598363.url(scheme.get, call_598363.host, call_598363.base,
                         call_598363.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598363, url, valid)

proc call*(call_598364: Call_GetLayerVersion_598351; VersionNumber: int;
          LayerName: string): Recallable =
  ## getLayerVersion
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ##   VersionNumber: int (required)
  ##                : The version number.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  var path_598365 = newJObject()
  add(path_598365, "VersionNumber", newJInt(VersionNumber))
  add(path_598365, "LayerName", newJString(LayerName))
  result = call_598364.call(path_598365, nil, nil, nil, nil)

var getLayerVersion* = Call_GetLayerVersion_598351(name: "getLayerVersion",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}",
    validator: validate_GetLayerVersion_598352, base: "/", url: url_GetLayerVersion_598353,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteLayerVersion_598366 = ref object of OpenApiRestCall_597389
proc url_DeleteLayerVersion_598368(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteLayerVersion_598367(path: JsonNode; query: JsonNode;
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
  var valid_598369 = path.getOrDefault("VersionNumber")
  valid_598369 = validateParameter(valid_598369, JInt, required = true, default = nil)
  if valid_598369 != nil:
    section.add "VersionNumber", valid_598369
  var valid_598370 = path.getOrDefault("LayerName")
  valid_598370 = validateParameter(valid_598370, JString, required = true,
                                 default = nil)
  if valid_598370 != nil:
    section.add "LayerName", valid_598370
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
  var valid_598371 = header.getOrDefault("X-Amz-Signature")
  valid_598371 = validateParameter(valid_598371, JString, required = false,
                                 default = nil)
  if valid_598371 != nil:
    section.add "X-Amz-Signature", valid_598371
  var valid_598372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598372 = validateParameter(valid_598372, JString, required = false,
                                 default = nil)
  if valid_598372 != nil:
    section.add "X-Amz-Content-Sha256", valid_598372
  var valid_598373 = header.getOrDefault("X-Amz-Date")
  valid_598373 = validateParameter(valid_598373, JString, required = false,
                                 default = nil)
  if valid_598373 != nil:
    section.add "X-Amz-Date", valid_598373
  var valid_598374 = header.getOrDefault("X-Amz-Credential")
  valid_598374 = validateParameter(valid_598374, JString, required = false,
                                 default = nil)
  if valid_598374 != nil:
    section.add "X-Amz-Credential", valid_598374
  var valid_598375 = header.getOrDefault("X-Amz-Security-Token")
  valid_598375 = validateParameter(valid_598375, JString, required = false,
                                 default = nil)
  if valid_598375 != nil:
    section.add "X-Amz-Security-Token", valid_598375
  var valid_598376 = header.getOrDefault("X-Amz-Algorithm")
  valid_598376 = validateParameter(valid_598376, JString, required = false,
                                 default = nil)
  if valid_598376 != nil:
    section.add "X-Amz-Algorithm", valid_598376
  var valid_598377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598377 = validateParameter(valid_598377, JString, required = false,
                                 default = nil)
  if valid_598377 != nil:
    section.add "X-Amz-SignedHeaders", valid_598377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598378: Call_DeleteLayerVersion_598366; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Deleted versions can no longer be viewed or added to functions. To avoid breaking functions, a copy of the version remains in Lambda until no functions refer to it.
  ## 
  let valid = call_598378.validator(path, query, header, formData, body)
  let scheme = call_598378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598378.url(scheme.get, call_598378.host, call_598378.base,
                         call_598378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598378, url, valid)

proc call*(call_598379: Call_DeleteLayerVersion_598366; VersionNumber: int;
          LayerName: string): Recallable =
  ## deleteLayerVersion
  ## Deletes a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Deleted versions can no longer be viewed or added to functions. To avoid breaking functions, a copy of the version remains in Lambda until no functions refer to it.
  ##   VersionNumber: int (required)
  ##                : The version number.
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  var path_598380 = newJObject()
  add(path_598380, "VersionNumber", newJInt(VersionNumber))
  add(path_598380, "LayerName", newJString(LayerName))
  result = call_598379.call(path_598380, nil, nil, nil, nil)

var deleteLayerVersion* = Call_DeleteLayerVersion_598366(
    name: "deleteLayerVersion", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}",
    validator: validate_DeleteLayerVersion_598367, base: "/",
    url: url_DeleteLayerVersion_598368, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutProvisionedConcurrencyConfig_598397 = ref object of OpenApiRestCall_597389
proc url_PutProvisionedConcurrencyConfig_598399(protocol: Scheme; host: string;
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

proc validate_PutProvisionedConcurrencyConfig_598398(path: JsonNode;
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
  var valid_598400 = path.getOrDefault("FunctionName")
  valid_598400 = validateParameter(valid_598400, JString, required = true,
                                 default = nil)
  if valid_598400 != nil:
    section.add "FunctionName", valid_598400
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString (required)
  ##            : The version number or alias name.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Qualifier` field"
  var valid_598401 = query.getOrDefault("Qualifier")
  valid_598401 = validateParameter(valid_598401, JString, required = true,
                                 default = nil)
  if valid_598401 != nil:
    section.add "Qualifier", valid_598401
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
  var valid_598402 = header.getOrDefault("X-Amz-Signature")
  valid_598402 = validateParameter(valid_598402, JString, required = false,
                                 default = nil)
  if valid_598402 != nil:
    section.add "X-Amz-Signature", valid_598402
  var valid_598403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598403 = validateParameter(valid_598403, JString, required = false,
                                 default = nil)
  if valid_598403 != nil:
    section.add "X-Amz-Content-Sha256", valid_598403
  var valid_598404 = header.getOrDefault("X-Amz-Date")
  valid_598404 = validateParameter(valid_598404, JString, required = false,
                                 default = nil)
  if valid_598404 != nil:
    section.add "X-Amz-Date", valid_598404
  var valid_598405 = header.getOrDefault("X-Amz-Credential")
  valid_598405 = validateParameter(valid_598405, JString, required = false,
                                 default = nil)
  if valid_598405 != nil:
    section.add "X-Amz-Credential", valid_598405
  var valid_598406 = header.getOrDefault("X-Amz-Security-Token")
  valid_598406 = validateParameter(valid_598406, JString, required = false,
                                 default = nil)
  if valid_598406 != nil:
    section.add "X-Amz-Security-Token", valid_598406
  var valid_598407 = header.getOrDefault("X-Amz-Algorithm")
  valid_598407 = validateParameter(valid_598407, JString, required = false,
                                 default = nil)
  if valid_598407 != nil:
    section.add "X-Amz-Algorithm", valid_598407
  var valid_598408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598408 = validateParameter(valid_598408, JString, required = false,
                                 default = nil)
  if valid_598408 != nil:
    section.add "X-Amz-SignedHeaders", valid_598408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598410: Call_PutProvisionedConcurrencyConfig_598397;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Adds a provisioned concurrency configuration to a function's alias or version.
  ## 
  let valid = call_598410.validator(path, query, header, formData, body)
  let scheme = call_598410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598410.url(scheme.get, call_598410.host, call_598410.base,
                         call_598410.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598410, url, valid)

proc call*(call_598411: Call_PutProvisionedConcurrencyConfig_598397;
          FunctionName: string; Qualifier: string; body: JsonNode): Recallable =
  ## putProvisionedConcurrencyConfig
  ## Adds a provisioned concurrency configuration to a function's alias or version.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string (required)
  ##            : The version number or alias name.
  ##   body: JObject (required)
  var path_598412 = newJObject()
  var query_598413 = newJObject()
  var body_598414 = newJObject()
  add(path_598412, "FunctionName", newJString(FunctionName))
  add(query_598413, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_598414 = body
  result = call_598411.call(path_598412, query_598413, nil, nil, body_598414)

var putProvisionedConcurrencyConfig* = Call_PutProvisionedConcurrencyConfig_598397(
    name: "putProvisionedConcurrencyConfig", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com", route: "/2019-09-30/functions/{FunctionName}/provisioned-concurrency#Qualifier",
    validator: validate_PutProvisionedConcurrencyConfig_598398, base: "/",
    url: url_PutProvisionedConcurrencyConfig_598399,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProvisionedConcurrencyConfig_598381 = ref object of OpenApiRestCall_597389
proc url_GetProvisionedConcurrencyConfig_598383(protocol: Scheme; host: string;
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

proc validate_GetProvisionedConcurrencyConfig_598382(path: JsonNode;
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
  var valid_598384 = path.getOrDefault("FunctionName")
  valid_598384 = validateParameter(valid_598384, JString, required = true,
                                 default = nil)
  if valid_598384 != nil:
    section.add "FunctionName", valid_598384
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString (required)
  ##            : The version number or alias name.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Qualifier` field"
  var valid_598385 = query.getOrDefault("Qualifier")
  valid_598385 = validateParameter(valid_598385, JString, required = true,
                                 default = nil)
  if valid_598385 != nil:
    section.add "Qualifier", valid_598385
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
  var valid_598386 = header.getOrDefault("X-Amz-Signature")
  valid_598386 = validateParameter(valid_598386, JString, required = false,
                                 default = nil)
  if valid_598386 != nil:
    section.add "X-Amz-Signature", valid_598386
  var valid_598387 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598387 = validateParameter(valid_598387, JString, required = false,
                                 default = nil)
  if valid_598387 != nil:
    section.add "X-Amz-Content-Sha256", valid_598387
  var valid_598388 = header.getOrDefault("X-Amz-Date")
  valid_598388 = validateParameter(valid_598388, JString, required = false,
                                 default = nil)
  if valid_598388 != nil:
    section.add "X-Amz-Date", valid_598388
  var valid_598389 = header.getOrDefault("X-Amz-Credential")
  valid_598389 = validateParameter(valid_598389, JString, required = false,
                                 default = nil)
  if valid_598389 != nil:
    section.add "X-Amz-Credential", valid_598389
  var valid_598390 = header.getOrDefault("X-Amz-Security-Token")
  valid_598390 = validateParameter(valid_598390, JString, required = false,
                                 default = nil)
  if valid_598390 != nil:
    section.add "X-Amz-Security-Token", valid_598390
  var valid_598391 = header.getOrDefault("X-Amz-Algorithm")
  valid_598391 = validateParameter(valid_598391, JString, required = false,
                                 default = nil)
  if valid_598391 != nil:
    section.add "X-Amz-Algorithm", valid_598391
  var valid_598392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598392 = validateParameter(valid_598392, JString, required = false,
                                 default = nil)
  if valid_598392 != nil:
    section.add "X-Amz-SignedHeaders", valid_598392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598393: Call_GetProvisionedConcurrencyConfig_598381;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves the provisioned concurrency configuration for a function's alias or version.
  ## 
  let valid = call_598393.validator(path, query, header, formData, body)
  let scheme = call_598393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598393.url(scheme.get, call_598393.host, call_598393.base,
                         call_598393.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598393, url, valid)

proc call*(call_598394: Call_GetProvisionedConcurrencyConfig_598381;
          FunctionName: string; Qualifier: string): Recallable =
  ## getProvisionedConcurrencyConfig
  ## Retrieves the provisioned concurrency configuration for a function's alias or version.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string (required)
  ##            : The version number or alias name.
  var path_598395 = newJObject()
  var query_598396 = newJObject()
  add(path_598395, "FunctionName", newJString(FunctionName))
  add(query_598396, "Qualifier", newJString(Qualifier))
  result = call_598394.call(path_598395, query_598396, nil, nil, nil)

var getProvisionedConcurrencyConfig* = Call_GetProvisionedConcurrencyConfig_598381(
    name: "getProvisionedConcurrencyConfig", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com", route: "/2019-09-30/functions/{FunctionName}/provisioned-concurrency#Qualifier",
    validator: validate_GetProvisionedConcurrencyConfig_598382, base: "/",
    url: url_GetProvisionedConcurrencyConfig_598383,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProvisionedConcurrencyConfig_598415 = ref object of OpenApiRestCall_597389
proc url_DeleteProvisionedConcurrencyConfig_598417(protocol: Scheme; host: string;
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

proc validate_DeleteProvisionedConcurrencyConfig_598416(path: JsonNode;
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
  var valid_598418 = path.getOrDefault("FunctionName")
  valid_598418 = validateParameter(valid_598418, JString, required = true,
                                 default = nil)
  if valid_598418 != nil:
    section.add "FunctionName", valid_598418
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString (required)
  ##            : The version number or alias name.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Qualifier` field"
  var valid_598419 = query.getOrDefault("Qualifier")
  valid_598419 = validateParameter(valid_598419, JString, required = true,
                                 default = nil)
  if valid_598419 != nil:
    section.add "Qualifier", valid_598419
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
  var valid_598420 = header.getOrDefault("X-Amz-Signature")
  valid_598420 = validateParameter(valid_598420, JString, required = false,
                                 default = nil)
  if valid_598420 != nil:
    section.add "X-Amz-Signature", valid_598420
  var valid_598421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598421 = validateParameter(valid_598421, JString, required = false,
                                 default = nil)
  if valid_598421 != nil:
    section.add "X-Amz-Content-Sha256", valid_598421
  var valid_598422 = header.getOrDefault("X-Amz-Date")
  valid_598422 = validateParameter(valid_598422, JString, required = false,
                                 default = nil)
  if valid_598422 != nil:
    section.add "X-Amz-Date", valid_598422
  var valid_598423 = header.getOrDefault("X-Amz-Credential")
  valid_598423 = validateParameter(valid_598423, JString, required = false,
                                 default = nil)
  if valid_598423 != nil:
    section.add "X-Amz-Credential", valid_598423
  var valid_598424 = header.getOrDefault("X-Amz-Security-Token")
  valid_598424 = validateParameter(valid_598424, JString, required = false,
                                 default = nil)
  if valid_598424 != nil:
    section.add "X-Amz-Security-Token", valid_598424
  var valid_598425 = header.getOrDefault("X-Amz-Algorithm")
  valid_598425 = validateParameter(valid_598425, JString, required = false,
                                 default = nil)
  if valid_598425 != nil:
    section.add "X-Amz-Algorithm", valid_598425
  var valid_598426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598426 = validateParameter(valid_598426, JString, required = false,
                                 default = nil)
  if valid_598426 != nil:
    section.add "X-Amz-SignedHeaders", valid_598426
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598427: Call_DeleteProvisionedConcurrencyConfig_598415;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes the provisioned concurrency configuration for a function.
  ## 
  let valid = call_598427.validator(path, query, header, formData, body)
  let scheme = call_598427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598427.url(scheme.get, call_598427.host, call_598427.base,
                         call_598427.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598427, url, valid)

proc call*(call_598428: Call_DeleteProvisionedConcurrencyConfig_598415;
          FunctionName: string; Qualifier: string): Recallable =
  ## deleteProvisionedConcurrencyConfig
  ## Deletes the provisioned concurrency configuration for a function.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string (required)
  ##            : The version number or alias name.
  var path_598429 = newJObject()
  var query_598430 = newJObject()
  add(path_598429, "FunctionName", newJString(FunctionName))
  add(query_598430, "Qualifier", newJString(Qualifier))
  result = call_598428.call(path_598429, query_598430, nil, nil, nil)

var deleteProvisionedConcurrencyConfig* = Call_DeleteProvisionedConcurrencyConfig_598415(
    name: "deleteProvisionedConcurrencyConfig", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com", route: "/2019-09-30/functions/{FunctionName}/provisioned-concurrency#Qualifier",
    validator: validate_DeleteProvisionedConcurrencyConfig_598416, base: "/",
    url: url_DeleteProvisionedConcurrencyConfig_598417,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAccountSettings_598431 = ref object of OpenApiRestCall_597389
proc url_GetAccountSettings_598433(protocol: Scheme; host: string; base: string;
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

proc validate_GetAccountSettings_598432(path: JsonNode; query: JsonNode;
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
  var valid_598434 = header.getOrDefault("X-Amz-Signature")
  valid_598434 = validateParameter(valid_598434, JString, required = false,
                                 default = nil)
  if valid_598434 != nil:
    section.add "X-Amz-Signature", valid_598434
  var valid_598435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598435 = validateParameter(valid_598435, JString, required = false,
                                 default = nil)
  if valid_598435 != nil:
    section.add "X-Amz-Content-Sha256", valid_598435
  var valid_598436 = header.getOrDefault("X-Amz-Date")
  valid_598436 = validateParameter(valid_598436, JString, required = false,
                                 default = nil)
  if valid_598436 != nil:
    section.add "X-Amz-Date", valid_598436
  var valid_598437 = header.getOrDefault("X-Amz-Credential")
  valid_598437 = validateParameter(valid_598437, JString, required = false,
                                 default = nil)
  if valid_598437 != nil:
    section.add "X-Amz-Credential", valid_598437
  var valid_598438 = header.getOrDefault("X-Amz-Security-Token")
  valid_598438 = validateParameter(valid_598438, JString, required = false,
                                 default = nil)
  if valid_598438 != nil:
    section.add "X-Amz-Security-Token", valid_598438
  var valid_598439 = header.getOrDefault("X-Amz-Algorithm")
  valid_598439 = validateParameter(valid_598439, JString, required = false,
                                 default = nil)
  if valid_598439 != nil:
    section.add "X-Amz-Algorithm", valid_598439
  var valid_598440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598440 = validateParameter(valid_598440, JString, required = false,
                                 default = nil)
  if valid_598440 != nil:
    section.add "X-Amz-SignedHeaders", valid_598440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598441: Call_GetAccountSettings_598431; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves details about your account's <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limits</a> and usage in an AWS Region.
  ## 
  let valid = call_598441.validator(path, query, header, formData, body)
  let scheme = call_598441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598441.url(scheme.get, call_598441.host, call_598441.base,
                         call_598441.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598441, url, valid)

proc call*(call_598442: Call_GetAccountSettings_598431): Recallable =
  ## getAccountSettings
  ## Retrieves details about your account's <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limits</a> and usage in an AWS Region.
  result = call_598442.call(nil, nil, nil, nil, nil)

var getAccountSettings* = Call_GetAccountSettings_598431(
    name: "getAccountSettings", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com", route: "/2016-08-19/account-settings/",
    validator: validate_GetAccountSettings_598432, base: "/",
    url: url_GetAccountSettings_598433, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionConcurrency_598443 = ref object of OpenApiRestCall_597389
proc url_GetFunctionConcurrency_598445(protocol: Scheme; host: string; base: string;
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

proc validate_GetFunctionConcurrency_598444(path: JsonNode; query: JsonNode;
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
  var valid_598446 = path.getOrDefault("FunctionName")
  valid_598446 = validateParameter(valid_598446, JString, required = true,
                                 default = nil)
  if valid_598446 != nil:
    section.add "FunctionName", valid_598446
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
  var valid_598447 = header.getOrDefault("X-Amz-Signature")
  valid_598447 = validateParameter(valid_598447, JString, required = false,
                                 default = nil)
  if valid_598447 != nil:
    section.add "X-Amz-Signature", valid_598447
  var valid_598448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598448 = validateParameter(valid_598448, JString, required = false,
                                 default = nil)
  if valid_598448 != nil:
    section.add "X-Amz-Content-Sha256", valid_598448
  var valid_598449 = header.getOrDefault("X-Amz-Date")
  valid_598449 = validateParameter(valid_598449, JString, required = false,
                                 default = nil)
  if valid_598449 != nil:
    section.add "X-Amz-Date", valid_598449
  var valid_598450 = header.getOrDefault("X-Amz-Credential")
  valid_598450 = validateParameter(valid_598450, JString, required = false,
                                 default = nil)
  if valid_598450 != nil:
    section.add "X-Amz-Credential", valid_598450
  var valid_598451 = header.getOrDefault("X-Amz-Security-Token")
  valid_598451 = validateParameter(valid_598451, JString, required = false,
                                 default = nil)
  if valid_598451 != nil:
    section.add "X-Amz-Security-Token", valid_598451
  var valid_598452 = header.getOrDefault("X-Amz-Algorithm")
  valid_598452 = validateParameter(valid_598452, JString, required = false,
                                 default = nil)
  if valid_598452 != nil:
    section.add "X-Amz-Algorithm", valid_598452
  var valid_598453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598453 = validateParameter(valid_598453, JString, required = false,
                                 default = nil)
  if valid_598453 != nil:
    section.add "X-Amz-SignedHeaders", valid_598453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598454: Call_GetFunctionConcurrency_598443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns details about the concurrency configuration for a function. To set a concurrency limit for a function, use <a>PutFunctionConcurrency</a>.
  ## 
  let valid = call_598454.validator(path, query, header, formData, body)
  let scheme = call_598454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598454.url(scheme.get, call_598454.host, call_598454.base,
                         call_598454.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598454, url, valid)

proc call*(call_598455: Call_GetFunctionConcurrency_598443; FunctionName: string): Recallable =
  ## getFunctionConcurrency
  ## Returns details about the concurrency configuration for a function. To set a concurrency limit for a function, use <a>PutFunctionConcurrency</a>.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  var path_598456 = newJObject()
  add(path_598456, "FunctionName", newJString(FunctionName))
  result = call_598455.call(path_598456, nil, nil, nil, nil)

var getFunctionConcurrency* = Call_GetFunctionConcurrency_598443(
    name: "getFunctionConcurrency", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2019-09-30/functions/{FunctionName}/concurrency",
    validator: validate_GetFunctionConcurrency_598444, base: "/",
    url: url_GetFunctionConcurrency_598445, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionConfiguration_598473 = ref object of OpenApiRestCall_597389
proc url_UpdateFunctionConfiguration_598475(protocol: Scheme; host: string;
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

proc validate_UpdateFunctionConfiguration_598474(path: JsonNode; query: JsonNode;
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
  var valid_598476 = path.getOrDefault("FunctionName")
  valid_598476 = validateParameter(valid_598476, JString, required = true,
                                 default = nil)
  if valid_598476 != nil:
    section.add "FunctionName", valid_598476
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
  var valid_598477 = header.getOrDefault("X-Amz-Signature")
  valid_598477 = validateParameter(valid_598477, JString, required = false,
                                 default = nil)
  if valid_598477 != nil:
    section.add "X-Amz-Signature", valid_598477
  var valid_598478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598478 = validateParameter(valid_598478, JString, required = false,
                                 default = nil)
  if valid_598478 != nil:
    section.add "X-Amz-Content-Sha256", valid_598478
  var valid_598479 = header.getOrDefault("X-Amz-Date")
  valid_598479 = validateParameter(valid_598479, JString, required = false,
                                 default = nil)
  if valid_598479 != nil:
    section.add "X-Amz-Date", valid_598479
  var valid_598480 = header.getOrDefault("X-Amz-Credential")
  valid_598480 = validateParameter(valid_598480, JString, required = false,
                                 default = nil)
  if valid_598480 != nil:
    section.add "X-Amz-Credential", valid_598480
  var valid_598481 = header.getOrDefault("X-Amz-Security-Token")
  valid_598481 = validateParameter(valid_598481, JString, required = false,
                                 default = nil)
  if valid_598481 != nil:
    section.add "X-Amz-Security-Token", valid_598481
  var valid_598482 = header.getOrDefault("X-Amz-Algorithm")
  valid_598482 = validateParameter(valid_598482, JString, required = false,
                                 default = nil)
  if valid_598482 != nil:
    section.add "X-Amz-Algorithm", valid_598482
  var valid_598483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598483 = validateParameter(valid_598483, JString, required = false,
                                 default = nil)
  if valid_598483 != nil:
    section.add "X-Amz-SignedHeaders", valid_598483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598485: Call_UpdateFunctionConfiguration_598473; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modify the version-specific settings of a Lambda function.</p> <p>When you update a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute. During this time, you can't modify the function, but you can still invoke it. The <code>LastUpdateStatus</code>, <code>LastUpdateStatusReason</code>, and <code>LastUpdateStatusReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the update is complete and the function is processing events with the new configuration. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Function States</a>.</p> <p>These settings can vary between versions of a function and are locked when you publish a version. You can't modify the configuration of a published version, only the unpublished version.</p> <p>To configure function concurrency, use <a>PutFunctionConcurrency</a>. To grant invoke permissions to an account or AWS service, use <a>AddPermission</a>.</p>
  ## 
  let valid = call_598485.validator(path, query, header, formData, body)
  let scheme = call_598485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598485.url(scheme.get, call_598485.host, call_598485.base,
                         call_598485.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598485, url, valid)

proc call*(call_598486: Call_UpdateFunctionConfiguration_598473;
          FunctionName: string; body: JsonNode): Recallable =
  ## updateFunctionConfiguration
  ## <p>Modify the version-specific settings of a Lambda function.</p> <p>When you update a function, Lambda provisions an instance of the function and its supporting resources. If your function connects to a VPC, this process can take a minute. During this time, you can't modify the function, but you can still invoke it. The <code>LastUpdateStatus</code>, <code>LastUpdateStatusReason</code>, and <code>LastUpdateStatusReasonCode</code> fields in the response from <a>GetFunctionConfiguration</a> indicate when the update is complete and the function is processing events with the new configuration. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/functions-states.html">Function States</a>.</p> <p>These settings can vary between versions of a function and are locked when you publish a version. You can't modify the configuration of a published version, only the unpublished version.</p> <p>To configure function concurrency, use <a>PutFunctionConcurrency</a>. To grant invoke permissions to an account or AWS service, use <a>AddPermission</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_598487 = newJObject()
  var body_598488 = newJObject()
  add(path_598487, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_598488 = body
  result = call_598486.call(path_598487, nil, nil, nil, body_598488)

var updateFunctionConfiguration* = Call_UpdateFunctionConfiguration_598473(
    name: "updateFunctionConfiguration", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/configuration",
    validator: validate_UpdateFunctionConfiguration_598474, base: "/",
    url: url_UpdateFunctionConfiguration_598475,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetFunctionConfiguration_598457 = ref object of OpenApiRestCall_597389
proc url_GetFunctionConfiguration_598459(protocol: Scheme; host: string;
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

proc validate_GetFunctionConfiguration_598458(path: JsonNode; query: JsonNode;
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
  var valid_598460 = path.getOrDefault("FunctionName")
  valid_598460 = validateParameter(valid_598460, JString, required = true,
                                 default = nil)
  if valid_598460 != nil:
    section.add "FunctionName", valid_598460
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to get details about a published version of the function.
  section = newJObject()
  var valid_598461 = query.getOrDefault("Qualifier")
  valid_598461 = validateParameter(valid_598461, JString, required = false,
                                 default = nil)
  if valid_598461 != nil:
    section.add "Qualifier", valid_598461
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
  var valid_598462 = header.getOrDefault("X-Amz-Signature")
  valid_598462 = validateParameter(valid_598462, JString, required = false,
                                 default = nil)
  if valid_598462 != nil:
    section.add "X-Amz-Signature", valid_598462
  var valid_598463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598463 = validateParameter(valid_598463, JString, required = false,
                                 default = nil)
  if valid_598463 != nil:
    section.add "X-Amz-Content-Sha256", valid_598463
  var valid_598464 = header.getOrDefault("X-Amz-Date")
  valid_598464 = validateParameter(valid_598464, JString, required = false,
                                 default = nil)
  if valid_598464 != nil:
    section.add "X-Amz-Date", valid_598464
  var valid_598465 = header.getOrDefault("X-Amz-Credential")
  valid_598465 = validateParameter(valid_598465, JString, required = false,
                                 default = nil)
  if valid_598465 != nil:
    section.add "X-Amz-Credential", valid_598465
  var valid_598466 = header.getOrDefault("X-Amz-Security-Token")
  valid_598466 = validateParameter(valid_598466, JString, required = false,
                                 default = nil)
  if valid_598466 != nil:
    section.add "X-Amz-Security-Token", valid_598466
  var valid_598467 = header.getOrDefault("X-Amz-Algorithm")
  valid_598467 = validateParameter(valid_598467, JString, required = false,
                                 default = nil)
  if valid_598467 != nil:
    section.add "X-Amz-Algorithm", valid_598467
  var valid_598468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598468 = validateParameter(valid_598468, JString, required = false,
                                 default = nil)
  if valid_598468 != nil:
    section.add "X-Amz-SignedHeaders", valid_598468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598469: Call_GetFunctionConfiguration_598457; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the version-specific settings of a Lambda function or version. The output includes only options that can vary between versions of a function. To modify these settings, use <a>UpdateFunctionConfiguration</a>.</p> <p>To get all of a function's details, including function-level settings, use <a>GetFunction</a>.</p>
  ## 
  let valid = call_598469.validator(path, query, header, formData, body)
  let scheme = call_598469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598469.url(scheme.get, call_598469.host, call_598469.base,
                         call_598469.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598469, url, valid)

proc call*(call_598470: Call_GetFunctionConfiguration_598457; FunctionName: string;
          Qualifier: string = ""): Recallable =
  ## getFunctionConfiguration
  ## <p>Returns the version-specific settings of a Lambda function or version. The output includes only options that can vary between versions of a function. To modify these settings, use <a>UpdateFunctionConfiguration</a>.</p> <p>To get all of a function's details, including function-level settings, use <a>GetFunction</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to get details about a published version of the function.
  var path_598471 = newJObject()
  var query_598472 = newJObject()
  add(path_598471, "FunctionName", newJString(FunctionName))
  add(query_598472, "Qualifier", newJString(Qualifier))
  result = call_598470.call(path_598471, query_598472, nil, nil, nil)

var getFunctionConfiguration* = Call_GetFunctionConfiguration_598457(
    name: "getFunctionConfiguration", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/configuration",
    validator: validate_GetFunctionConfiguration_598458, base: "/",
    url: url_GetFunctionConfiguration_598459, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetLayerVersionByArn_598489 = ref object of OpenApiRestCall_597389
proc url_GetLayerVersionByArn_598491(protocol: Scheme; host: string; base: string;
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

proc validate_GetLayerVersionByArn_598490(path: JsonNode; query: JsonNode;
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
  var valid_598505 = query.getOrDefault("find")
  valid_598505 = validateParameter(valid_598505, JString, required = true,
                                 default = newJString("LayerVersion"))
  if valid_598505 != nil:
    section.add "find", valid_598505
  var valid_598506 = query.getOrDefault("Arn")
  valid_598506 = validateParameter(valid_598506, JString, required = true,
                                 default = nil)
  if valid_598506 != nil:
    section.add "Arn", valid_598506
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
  var valid_598507 = header.getOrDefault("X-Amz-Signature")
  valid_598507 = validateParameter(valid_598507, JString, required = false,
                                 default = nil)
  if valid_598507 != nil:
    section.add "X-Amz-Signature", valid_598507
  var valid_598508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598508 = validateParameter(valid_598508, JString, required = false,
                                 default = nil)
  if valid_598508 != nil:
    section.add "X-Amz-Content-Sha256", valid_598508
  var valid_598509 = header.getOrDefault("X-Amz-Date")
  valid_598509 = validateParameter(valid_598509, JString, required = false,
                                 default = nil)
  if valid_598509 != nil:
    section.add "X-Amz-Date", valid_598509
  var valid_598510 = header.getOrDefault("X-Amz-Credential")
  valid_598510 = validateParameter(valid_598510, JString, required = false,
                                 default = nil)
  if valid_598510 != nil:
    section.add "X-Amz-Credential", valid_598510
  var valid_598511 = header.getOrDefault("X-Amz-Security-Token")
  valid_598511 = validateParameter(valid_598511, JString, required = false,
                                 default = nil)
  if valid_598511 != nil:
    section.add "X-Amz-Security-Token", valid_598511
  var valid_598512 = header.getOrDefault("X-Amz-Algorithm")
  valid_598512 = validateParameter(valid_598512, JString, required = false,
                                 default = nil)
  if valid_598512 != nil:
    section.add "X-Amz-Algorithm", valid_598512
  var valid_598513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598513 = validateParameter(valid_598513, JString, required = false,
                                 default = nil)
  if valid_598513 != nil:
    section.add "X-Amz-SignedHeaders", valid_598513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598514: Call_GetLayerVersionByArn_598489; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ## 
  let valid = call_598514.validator(path, query, header, formData, body)
  let scheme = call_598514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598514.url(scheme.get, call_598514.host, call_598514.base,
                         call_598514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598514, url, valid)

proc call*(call_598515: Call_GetLayerVersionByArn_598489; Arn: string;
          find: string = "LayerVersion"): Recallable =
  ## getLayerVersionByArn
  ## Returns information about a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>, with a link to download the layer archive that's valid for 10 minutes.
  ##   find: string (required)
  ##   Arn: string (required)
  ##      : The ARN of the layer version.
  var query_598516 = newJObject()
  add(query_598516, "find", newJString(find))
  add(query_598516, "Arn", newJString(Arn))
  result = call_598515.call(nil, query_598516, nil, nil, nil)

var getLayerVersionByArn* = Call_GetLayerVersionByArn_598489(
    name: "getLayerVersionByArn", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers#find=LayerVersion&Arn",
    validator: validate_GetLayerVersionByArn_598490, base: "/",
    url: url_GetLayerVersionByArn_598491, schemes: {Scheme.Https, Scheme.Http})
type
  Call_Invoke_598517 = ref object of OpenApiRestCall_597389
proc url_Invoke_598519(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_Invoke_598518(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598520 = path.getOrDefault("FunctionName")
  valid_598520 = validateParameter(valid_598520, JString, required = true,
                                 default = nil)
  if valid_598520 != nil:
    section.add "FunctionName", valid_598520
  result.add "path", section
  ## parameters in `query` object:
  ##   Qualifier: JString
  ##            : Specify a version or alias to invoke a published version of the function.
  section = newJObject()
  var valid_598521 = query.getOrDefault("Qualifier")
  valid_598521 = validateParameter(valid_598521, JString, required = false,
                                 default = nil)
  if valid_598521 != nil:
    section.add "Qualifier", valid_598521
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
  var valid_598522 = header.getOrDefault("X-Amz-Invocation-Type")
  valid_598522 = validateParameter(valid_598522, JString, required = false,
                                 default = newJString("Event"))
  if valid_598522 != nil:
    section.add "X-Amz-Invocation-Type", valid_598522
  var valid_598523 = header.getOrDefault("X-Amz-Signature")
  valid_598523 = validateParameter(valid_598523, JString, required = false,
                                 default = nil)
  if valid_598523 != nil:
    section.add "X-Amz-Signature", valid_598523
  var valid_598524 = header.getOrDefault("X-Amz-Client-Context")
  valid_598524 = validateParameter(valid_598524, JString, required = false,
                                 default = nil)
  if valid_598524 != nil:
    section.add "X-Amz-Client-Context", valid_598524
  var valid_598525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598525 = validateParameter(valid_598525, JString, required = false,
                                 default = nil)
  if valid_598525 != nil:
    section.add "X-Amz-Content-Sha256", valid_598525
  var valid_598526 = header.getOrDefault("X-Amz-Date")
  valid_598526 = validateParameter(valid_598526, JString, required = false,
                                 default = nil)
  if valid_598526 != nil:
    section.add "X-Amz-Date", valid_598526
  var valid_598527 = header.getOrDefault("X-Amz-Credential")
  valid_598527 = validateParameter(valid_598527, JString, required = false,
                                 default = nil)
  if valid_598527 != nil:
    section.add "X-Amz-Credential", valid_598527
  var valid_598528 = header.getOrDefault("X-Amz-Security-Token")
  valid_598528 = validateParameter(valid_598528, JString, required = false,
                                 default = nil)
  if valid_598528 != nil:
    section.add "X-Amz-Security-Token", valid_598528
  var valid_598529 = header.getOrDefault("X-Amz-Log-Type")
  valid_598529 = validateParameter(valid_598529, JString, required = false,
                                 default = newJString("None"))
  if valid_598529 != nil:
    section.add "X-Amz-Log-Type", valid_598529
  var valid_598530 = header.getOrDefault("X-Amz-Algorithm")
  valid_598530 = validateParameter(valid_598530, JString, required = false,
                                 default = nil)
  if valid_598530 != nil:
    section.add "X-Amz-Algorithm", valid_598530
  var valid_598531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598531 = validateParameter(valid_598531, JString, required = false,
                                 default = nil)
  if valid_598531 != nil:
    section.add "X-Amz-SignedHeaders", valid_598531
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598533: Call_Invoke_598517; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Invokes a Lambda function. You can invoke a function synchronously (and wait for the response), or asynchronously. To invoke a function asynchronously, set <code>InvocationType</code> to <code>Event</code>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-sync.html">synchronous invocation</a>, details about the function response, including errors, are included in the response body and headers. For either invocation type, you can find more information in the <a href="https://docs.aws.amazon.com/lambda/latest/dg/monitoring-functions.html">execution log</a> and <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-x-ray.html">trace</a>.</p> <p>When an error occurs, your function may be invoked multiple times. Retry behavior varies by error type, client, event source, and invocation type. For example, if you invoke a function asynchronously and it returns an error, Lambda executes the function up to two more times. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/retries-on-errors.html">Retry Behavior</a>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a>, Lambda adds events to a queue before sending them to your function. If your function does not have enough capacity to keep up with the queue, events may be lost. Occasionally, your function may receive the same event multiple times, even if no error occurs. To retain events that were not processed, configure your function with a <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#dlq">dead-letter queue</a>.</p> <p>The status code in the API response doesn't reflect function errors. Error codes are reserved for errors that prevent your function from executing, such as permissions errors, <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limit errors</a>, or issues with your function's code and configuration. For example, Lambda returns <code>TooManyRequestsException</code> if executing the function would cause you to exceed a concurrency limit at either the account level (<code>ConcurrentInvocationLimitExceeded</code>) or function level (<code>ReservedFunctionConcurrentInvocationLimitExceeded</code>).</p> <p>For functions with a long timeout, your client might be disconnected during synchronous invocation while it waits for a response. Configure your HTTP client, SDK, firewall, proxy, or operating system to allow for long connections with timeout or keep-alive settings.</p> <p>This operation requires permission for the <code>lambda:InvokeFunction</code> action.</p>
  ## 
  let valid = call_598533.validator(path, query, header, formData, body)
  let scheme = call_598533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598533.url(scheme.get, call_598533.host, call_598533.base,
                         call_598533.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598533, url, valid)

proc call*(call_598534: Call_Invoke_598517; FunctionName: string; body: JsonNode;
          Qualifier: string = ""): Recallable =
  ## invoke
  ## <p>Invokes a Lambda function. You can invoke a function synchronously (and wait for the response), or asynchronously. To invoke a function asynchronously, set <code>InvocationType</code> to <code>Event</code>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-sync.html">synchronous invocation</a>, details about the function response, including errors, are included in the response body and headers. For either invocation type, you can find more information in the <a href="https://docs.aws.amazon.com/lambda/latest/dg/monitoring-functions.html">execution log</a> and <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-x-ray.html">trace</a>.</p> <p>When an error occurs, your function may be invoked multiple times. Retry behavior varies by error type, client, event source, and invocation type. For example, if you invoke a function asynchronously and it returns an error, Lambda executes the function up to two more times. For more information, see <a href="https://docs.aws.amazon.com/lambda/latest/dg/retries-on-errors.html">Retry Behavior</a>.</p> <p>For <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html">asynchronous invocation</a>, Lambda adds events to a queue before sending them to your function. If your function does not have enough capacity to keep up with the queue, events may be lost. Occasionally, your function may receive the same event multiple times, even if no error occurs. To retain events that were not processed, configure your function with a <a href="https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html#dlq">dead-letter queue</a>.</p> <p>The status code in the API response doesn't reflect function errors. Error codes are reserved for errors that prevent your function from executing, such as permissions errors, <a href="https://docs.aws.amazon.com/lambda/latest/dg/limits.html">limit errors</a>, or issues with your function's code and configuration. For example, Lambda returns <code>TooManyRequestsException</code> if executing the function would cause you to exceed a concurrency limit at either the account level (<code>ConcurrentInvocationLimitExceeded</code>) or function level (<code>ReservedFunctionConcurrentInvocationLimitExceeded</code>).</p> <p>For functions with a long timeout, your client might be disconnected during synchronous invocation while it waits for a response. Configure your HTTP client, SDK, firewall, proxy, or operating system to allow for long connections with timeout or keep-alive settings.</p> <p>This operation requires permission for the <code>lambda:InvokeFunction</code> action.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function, version, or alias.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code> (name-only), <code>my-function:v1</code> (with alias).</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>You can append a version number or alias to any of the formats. The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   Qualifier: string
  ##            : Specify a version or alias to invoke a published version of the function.
  ##   body: JObject (required)
  var path_598535 = newJObject()
  var query_598536 = newJObject()
  var body_598537 = newJObject()
  add(path_598535, "FunctionName", newJString(FunctionName))
  add(query_598536, "Qualifier", newJString(Qualifier))
  if body != nil:
    body_598537 = body
  result = call_598534.call(path_598535, query_598536, nil, nil, body_598537)

var invoke* = Call_Invoke_598517(name: "invoke", meth: HttpMethod.HttpPost,
                              host: "lambda.amazonaws.com", route: "/2015-03-31/functions/{FunctionName}/invocations",
                              validator: validate_Invoke_598518, base: "/",
                              url: url_Invoke_598519,
                              schemes: {Scheme.Https, Scheme.Http})
type
  Call_InvokeAsync_598538 = ref object of OpenApiRestCall_597389
proc url_InvokeAsync_598540(protocol: Scheme; host: string; base: string;
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

proc validate_InvokeAsync_598539(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598541 = path.getOrDefault("FunctionName")
  valid_598541 = validateParameter(valid_598541, JString, required = true,
                                 default = nil)
  if valid_598541 != nil:
    section.add "FunctionName", valid_598541
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
  var valid_598542 = header.getOrDefault("X-Amz-Signature")
  valid_598542 = validateParameter(valid_598542, JString, required = false,
                                 default = nil)
  if valid_598542 != nil:
    section.add "X-Amz-Signature", valid_598542
  var valid_598543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598543 = validateParameter(valid_598543, JString, required = false,
                                 default = nil)
  if valid_598543 != nil:
    section.add "X-Amz-Content-Sha256", valid_598543
  var valid_598544 = header.getOrDefault("X-Amz-Date")
  valid_598544 = validateParameter(valid_598544, JString, required = false,
                                 default = nil)
  if valid_598544 != nil:
    section.add "X-Amz-Date", valid_598544
  var valid_598545 = header.getOrDefault("X-Amz-Credential")
  valid_598545 = validateParameter(valid_598545, JString, required = false,
                                 default = nil)
  if valid_598545 != nil:
    section.add "X-Amz-Credential", valid_598545
  var valid_598546 = header.getOrDefault("X-Amz-Security-Token")
  valid_598546 = validateParameter(valid_598546, JString, required = false,
                                 default = nil)
  if valid_598546 != nil:
    section.add "X-Amz-Security-Token", valid_598546
  var valid_598547 = header.getOrDefault("X-Amz-Algorithm")
  valid_598547 = validateParameter(valid_598547, JString, required = false,
                                 default = nil)
  if valid_598547 != nil:
    section.add "X-Amz-Algorithm", valid_598547
  var valid_598548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598548 = validateParameter(valid_598548, JString, required = false,
                                 default = nil)
  if valid_598548 != nil:
    section.add "X-Amz-SignedHeaders", valid_598548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598550: Call_InvokeAsync_598538; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <important> <p>For asynchronous function invocation, use <a>Invoke</a>.</p> </important> <p>Invokes a function asynchronously.</p>
  ## 
  let valid = call_598550.validator(path, query, header, formData, body)
  let scheme = call_598550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598550.url(scheme.get, call_598550.host, call_598550.base,
                         call_598550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598550, url, valid)

proc call*(call_598551: Call_InvokeAsync_598538; FunctionName: string; body: JsonNode): Recallable =
  ## invokeAsync
  ## <important> <p>For asynchronous function invocation, use <a>Invoke</a>.</p> </important> <p>Invokes a function asynchronously.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_598552 = newJObject()
  var body_598553 = newJObject()
  add(path_598552, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_598553 = body
  result = call_598551.call(path_598552, nil, nil, nil, body_598553)

var invokeAsync* = Call_InvokeAsync_598538(name: "invokeAsync",
                                        meth: HttpMethod.HttpPost,
                                        host: "lambda.amazonaws.com", route: "/2014-11-13/functions/{FunctionName}/invoke-async/",
                                        validator: validate_InvokeAsync_598539,
                                        base: "/", url: url_InvokeAsync_598540,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctionEventInvokeConfigs_598554 = ref object of OpenApiRestCall_597389
proc url_ListFunctionEventInvokeConfigs_598556(protocol: Scheme; host: string;
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

proc validate_ListFunctionEventInvokeConfigs_598555(path: JsonNode;
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
  var valid_598557 = path.getOrDefault("FunctionName")
  valid_598557 = validateParameter(valid_598557, JString, required = true,
                                 default = nil)
  if valid_598557 != nil:
    section.add "FunctionName", valid_598557
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: JInt
  ##           : The maximum number of configurations to return.
  section = newJObject()
  var valid_598558 = query.getOrDefault("Marker")
  valid_598558 = validateParameter(valid_598558, JString, required = false,
                                 default = nil)
  if valid_598558 != nil:
    section.add "Marker", valid_598558
  var valid_598559 = query.getOrDefault("MaxItems")
  valid_598559 = validateParameter(valid_598559, JInt, required = false, default = nil)
  if valid_598559 != nil:
    section.add "MaxItems", valid_598559
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
  var valid_598560 = header.getOrDefault("X-Amz-Signature")
  valid_598560 = validateParameter(valid_598560, JString, required = false,
                                 default = nil)
  if valid_598560 != nil:
    section.add "X-Amz-Signature", valid_598560
  var valid_598561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598561 = validateParameter(valid_598561, JString, required = false,
                                 default = nil)
  if valid_598561 != nil:
    section.add "X-Amz-Content-Sha256", valid_598561
  var valid_598562 = header.getOrDefault("X-Amz-Date")
  valid_598562 = validateParameter(valid_598562, JString, required = false,
                                 default = nil)
  if valid_598562 != nil:
    section.add "X-Amz-Date", valid_598562
  var valid_598563 = header.getOrDefault("X-Amz-Credential")
  valid_598563 = validateParameter(valid_598563, JString, required = false,
                                 default = nil)
  if valid_598563 != nil:
    section.add "X-Amz-Credential", valid_598563
  var valid_598564 = header.getOrDefault("X-Amz-Security-Token")
  valid_598564 = validateParameter(valid_598564, JString, required = false,
                                 default = nil)
  if valid_598564 != nil:
    section.add "X-Amz-Security-Token", valid_598564
  var valid_598565 = header.getOrDefault("X-Amz-Algorithm")
  valid_598565 = validateParameter(valid_598565, JString, required = false,
                                 default = nil)
  if valid_598565 != nil:
    section.add "X-Amz-Algorithm", valid_598565
  var valid_598566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598566 = validateParameter(valid_598566, JString, required = false,
                                 default = nil)
  if valid_598566 != nil:
    section.add "X-Amz-SignedHeaders", valid_598566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598567: Call_ListFunctionEventInvokeConfigs_598554; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves a list of configurations for asynchronous invocation for a function.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ## 
  let valid = call_598567.validator(path, query, header, formData, body)
  let scheme = call_598567.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598567.url(scheme.get, call_598567.host, call_598567.base,
                         call_598567.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598567, url, valid)

proc call*(call_598568: Call_ListFunctionEventInvokeConfigs_598554;
          FunctionName: string; Marker: string = ""; MaxItems: int = 0): Recallable =
  ## listFunctionEventInvokeConfigs
  ## <p>Retrieves a list of configurations for asynchronous invocation for a function.</p> <p>To configure options for asynchronous invocation, use <a>PutFunctionEventInvokeConfig</a>.</p>
  ##   Marker: string
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   MaxItems: int
  ##           : The maximum number of configurations to return.
  var path_598569 = newJObject()
  var query_598570 = newJObject()
  add(query_598570, "Marker", newJString(Marker))
  add(path_598569, "FunctionName", newJString(FunctionName))
  add(query_598570, "MaxItems", newJInt(MaxItems))
  result = call_598568.call(path_598569, query_598570, nil, nil, nil)

var listFunctionEventInvokeConfigs* = Call_ListFunctionEventInvokeConfigs_598554(
    name: "listFunctionEventInvokeConfigs", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2019-09-25/functions/{FunctionName}/event-invoke-config/list",
    validator: validate_ListFunctionEventInvokeConfigs_598555, base: "/",
    url: url_ListFunctionEventInvokeConfigs_598556,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFunctions_598571 = ref object of OpenApiRestCall_597389
proc url_ListFunctions_598573(protocol: Scheme; host: string; base: string;
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

proc validate_ListFunctions_598572(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598574 = query.getOrDefault("Marker")
  valid_598574 = validateParameter(valid_598574, JString, required = false,
                                 default = nil)
  if valid_598574 != nil:
    section.add "Marker", valid_598574
  var valid_598575 = query.getOrDefault("FunctionVersion")
  valid_598575 = validateParameter(valid_598575, JString, required = false,
                                 default = newJString("ALL"))
  if valid_598575 != nil:
    section.add "FunctionVersion", valid_598575
  var valid_598576 = query.getOrDefault("MaxItems")
  valid_598576 = validateParameter(valid_598576, JInt, required = false, default = nil)
  if valid_598576 != nil:
    section.add "MaxItems", valid_598576
  var valid_598577 = query.getOrDefault("MasterRegion")
  valid_598577 = validateParameter(valid_598577, JString, required = false,
                                 default = nil)
  if valid_598577 != nil:
    section.add "MasterRegion", valid_598577
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
  var valid_598578 = header.getOrDefault("X-Amz-Signature")
  valid_598578 = validateParameter(valid_598578, JString, required = false,
                                 default = nil)
  if valid_598578 != nil:
    section.add "X-Amz-Signature", valid_598578
  var valid_598579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598579 = validateParameter(valid_598579, JString, required = false,
                                 default = nil)
  if valid_598579 != nil:
    section.add "X-Amz-Content-Sha256", valid_598579
  var valid_598580 = header.getOrDefault("X-Amz-Date")
  valid_598580 = validateParameter(valid_598580, JString, required = false,
                                 default = nil)
  if valid_598580 != nil:
    section.add "X-Amz-Date", valid_598580
  var valid_598581 = header.getOrDefault("X-Amz-Credential")
  valid_598581 = validateParameter(valid_598581, JString, required = false,
                                 default = nil)
  if valid_598581 != nil:
    section.add "X-Amz-Credential", valid_598581
  var valid_598582 = header.getOrDefault("X-Amz-Security-Token")
  valid_598582 = validateParameter(valid_598582, JString, required = false,
                                 default = nil)
  if valid_598582 != nil:
    section.add "X-Amz-Security-Token", valid_598582
  var valid_598583 = header.getOrDefault("X-Amz-Algorithm")
  valid_598583 = validateParameter(valid_598583, JString, required = false,
                                 default = nil)
  if valid_598583 != nil:
    section.add "X-Amz-Algorithm", valid_598583
  var valid_598584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598584 = validateParameter(valid_598584, JString, required = false,
                                 default = nil)
  if valid_598584 != nil:
    section.add "X-Amz-SignedHeaders", valid_598584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598585: Call_ListFunctions_598571; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of Lambda functions, with the version-specific configuration of each.</p> <p>Set <code>FunctionVersion</code> to <code>ALL</code> to include all published versions of each function in addition to the unpublished version. To get more information about a function or version, use <a>GetFunction</a>.</p>
  ## 
  let valid = call_598585.validator(path, query, header, formData, body)
  let scheme = call_598585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598585.url(scheme.get, call_598585.host, call_598585.base,
                         call_598585.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598585, url, valid)

proc call*(call_598586: Call_ListFunctions_598571; Marker: string = "";
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
  var query_598587 = newJObject()
  add(query_598587, "Marker", newJString(Marker))
  add(query_598587, "FunctionVersion", newJString(FunctionVersion))
  add(query_598587, "MaxItems", newJInt(MaxItems))
  add(query_598587, "MasterRegion", newJString(MasterRegion))
  result = call_598586.call(nil, query_598587, nil, nil, nil)

var listFunctions* = Call_ListFunctions_598571(name: "listFunctions",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/", validator: validate_ListFunctions_598572,
    base: "/", url: url_ListFunctions_598573, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PublishLayerVersion_598606 = ref object of OpenApiRestCall_597389
proc url_PublishLayerVersion_598608(protocol: Scheme; host: string; base: string;
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

proc validate_PublishLayerVersion_598607(path: JsonNode; query: JsonNode;
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
  var valid_598609 = path.getOrDefault("LayerName")
  valid_598609 = validateParameter(valid_598609, JString, required = true,
                                 default = nil)
  if valid_598609 != nil:
    section.add "LayerName", valid_598609
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
  var valid_598610 = header.getOrDefault("X-Amz-Signature")
  valid_598610 = validateParameter(valid_598610, JString, required = false,
                                 default = nil)
  if valid_598610 != nil:
    section.add "X-Amz-Signature", valid_598610
  var valid_598611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598611 = validateParameter(valid_598611, JString, required = false,
                                 default = nil)
  if valid_598611 != nil:
    section.add "X-Amz-Content-Sha256", valid_598611
  var valid_598612 = header.getOrDefault("X-Amz-Date")
  valid_598612 = validateParameter(valid_598612, JString, required = false,
                                 default = nil)
  if valid_598612 != nil:
    section.add "X-Amz-Date", valid_598612
  var valid_598613 = header.getOrDefault("X-Amz-Credential")
  valid_598613 = validateParameter(valid_598613, JString, required = false,
                                 default = nil)
  if valid_598613 != nil:
    section.add "X-Amz-Credential", valid_598613
  var valid_598614 = header.getOrDefault("X-Amz-Security-Token")
  valid_598614 = validateParameter(valid_598614, JString, required = false,
                                 default = nil)
  if valid_598614 != nil:
    section.add "X-Amz-Security-Token", valid_598614
  var valid_598615 = header.getOrDefault("X-Amz-Algorithm")
  valid_598615 = validateParameter(valid_598615, JString, required = false,
                                 default = nil)
  if valid_598615 != nil:
    section.add "X-Amz-Algorithm", valid_598615
  var valid_598616 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598616 = validateParameter(valid_598616, JString, required = false,
                                 default = nil)
  if valid_598616 != nil:
    section.add "X-Amz-SignedHeaders", valid_598616
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598618: Call_PublishLayerVersion_598606; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a> from a ZIP archive. Each time you call <code>PublishLayerVersion</code> with the same layer name, a new version is created.</p> <p>Add layers to your function with <a>CreateFunction</a> or <a>UpdateFunctionConfiguration</a>.</p>
  ## 
  let valid = call_598618.validator(path, query, header, formData, body)
  let scheme = call_598618.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598618.url(scheme.get, call_598618.host, call_598618.base,
                         call_598618.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598618, url, valid)

proc call*(call_598619: Call_PublishLayerVersion_598606; LayerName: string;
          body: JsonNode): Recallable =
  ## publishLayerVersion
  ## <p>Creates an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a> from a ZIP archive. Each time you call <code>PublishLayerVersion</code> with the same layer name, a new version is created.</p> <p>Add layers to your function with <a>CreateFunction</a> or <a>UpdateFunctionConfiguration</a>.</p>
  ##   LayerName: string (required)
  ##            : The name or Amazon Resource Name (ARN) of the layer.
  ##   body: JObject (required)
  var path_598620 = newJObject()
  var body_598621 = newJObject()
  add(path_598620, "LayerName", newJString(LayerName))
  if body != nil:
    body_598621 = body
  result = call_598619.call(path_598620, nil, nil, nil, body_598621)

var publishLayerVersion* = Call_PublishLayerVersion_598606(
    name: "publishLayerVersion", meth: HttpMethod.HttpPost,
    host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions",
    validator: validate_PublishLayerVersion_598607, base: "/",
    url: url_PublishLayerVersion_598608, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLayerVersions_598588 = ref object of OpenApiRestCall_597389
proc url_ListLayerVersions_598590(protocol: Scheme; host: string; base: string;
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

proc validate_ListLayerVersions_598589(path: JsonNode; query: JsonNode;
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
  var valid_598591 = path.getOrDefault("LayerName")
  valid_598591 = validateParameter(valid_598591, JString, required = true,
                                 default = nil)
  if valid_598591 != nil:
    section.add "LayerName", valid_598591
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : A pagination token returned by a previous call.
  ##   CompatibleRuntime: JString
  ##                    : A runtime identifier. For example, <code>go1.x</code>.
  ##   MaxItems: JInt
  ##           : The maximum number of versions to return.
  section = newJObject()
  var valid_598592 = query.getOrDefault("Marker")
  valid_598592 = validateParameter(valid_598592, JString, required = false,
                                 default = nil)
  if valid_598592 != nil:
    section.add "Marker", valid_598592
  var valid_598593 = query.getOrDefault("CompatibleRuntime")
  valid_598593 = validateParameter(valid_598593, JString, required = false,
                                 default = newJString("nodejs"))
  if valid_598593 != nil:
    section.add "CompatibleRuntime", valid_598593
  var valid_598594 = query.getOrDefault("MaxItems")
  valid_598594 = validateParameter(valid_598594, JInt, required = false, default = nil)
  if valid_598594 != nil:
    section.add "MaxItems", valid_598594
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
  var valid_598595 = header.getOrDefault("X-Amz-Signature")
  valid_598595 = validateParameter(valid_598595, JString, required = false,
                                 default = nil)
  if valid_598595 != nil:
    section.add "X-Amz-Signature", valid_598595
  var valid_598596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598596 = validateParameter(valid_598596, JString, required = false,
                                 default = nil)
  if valid_598596 != nil:
    section.add "X-Amz-Content-Sha256", valid_598596
  var valid_598597 = header.getOrDefault("X-Amz-Date")
  valid_598597 = validateParameter(valid_598597, JString, required = false,
                                 default = nil)
  if valid_598597 != nil:
    section.add "X-Amz-Date", valid_598597
  var valid_598598 = header.getOrDefault("X-Amz-Credential")
  valid_598598 = validateParameter(valid_598598, JString, required = false,
                                 default = nil)
  if valid_598598 != nil:
    section.add "X-Amz-Credential", valid_598598
  var valid_598599 = header.getOrDefault("X-Amz-Security-Token")
  valid_598599 = validateParameter(valid_598599, JString, required = false,
                                 default = nil)
  if valid_598599 != nil:
    section.add "X-Amz-Security-Token", valid_598599
  var valid_598600 = header.getOrDefault("X-Amz-Algorithm")
  valid_598600 = validateParameter(valid_598600, JString, required = false,
                                 default = nil)
  if valid_598600 != nil:
    section.add "X-Amz-Algorithm", valid_598600
  var valid_598601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598601 = validateParameter(valid_598601, JString, required = false,
                                 default = nil)
  if valid_598601 != nil:
    section.add "X-Amz-SignedHeaders", valid_598601
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598602: Call_ListLayerVersions_598588; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the versions of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. Versions that have been deleted aren't listed. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only versions that indicate that they're compatible with that runtime.
  ## 
  let valid = call_598602.validator(path, query, header, formData, body)
  let scheme = call_598602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598602.url(scheme.get, call_598602.host, call_598602.base,
                         call_598602.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598602, url, valid)

proc call*(call_598603: Call_ListLayerVersions_598588; LayerName: string;
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
  var path_598604 = newJObject()
  var query_598605 = newJObject()
  add(query_598605, "Marker", newJString(Marker))
  add(query_598605, "CompatibleRuntime", newJString(CompatibleRuntime))
  add(query_598605, "MaxItems", newJInt(MaxItems))
  add(path_598604, "LayerName", newJString(LayerName))
  result = call_598603.call(path_598604, query_598605, nil, nil, nil)

var listLayerVersions* = Call_ListLayerVersions_598588(name: "listLayerVersions",
    meth: HttpMethod.HttpGet, host: "lambda.amazonaws.com",
    route: "/2018-10-31/layers/{LayerName}/versions",
    validator: validate_ListLayerVersions_598589, base: "/",
    url: url_ListLayerVersions_598590, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListLayers_598622 = ref object of OpenApiRestCall_597389
proc url_ListLayers_598624(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListLayers_598623(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598625 = query.getOrDefault("Marker")
  valid_598625 = validateParameter(valid_598625, JString, required = false,
                                 default = nil)
  if valid_598625 != nil:
    section.add "Marker", valid_598625
  var valid_598626 = query.getOrDefault("CompatibleRuntime")
  valid_598626 = validateParameter(valid_598626, JString, required = false,
                                 default = newJString("nodejs"))
  if valid_598626 != nil:
    section.add "CompatibleRuntime", valid_598626
  var valid_598627 = query.getOrDefault("MaxItems")
  valid_598627 = validateParameter(valid_598627, JInt, required = false, default = nil)
  if valid_598627 != nil:
    section.add "MaxItems", valid_598627
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
  var valid_598628 = header.getOrDefault("X-Amz-Signature")
  valid_598628 = validateParameter(valid_598628, JString, required = false,
                                 default = nil)
  if valid_598628 != nil:
    section.add "X-Amz-Signature", valid_598628
  var valid_598629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598629 = validateParameter(valid_598629, JString, required = false,
                                 default = nil)
  if valid_598629 != nil:
    section.add "X-Amz-Content-Sha256", valid_598629
  var valid_598630 = header.getOrDefault("X-Amz-Date")
  valid_598630 = validateParameter(valid_598630, JString, required = false,
                                 default = nil)
  if valid_598630 != nil:
    section.add "X-Amz-Date", valid_598630
  var valid_598631 = header.getOrDefault("X-Amz-Credential")
  valid_598631 = validateParameter(valid_598631, JString, required = false,
                                 default = nil)
  if valid_598631 != nil:
    section.add "X-Amz-Credential", valid_598631
  var valid_598632 = header.getOrDefault("X-Amz-Security-Token")
  valid_598632 = validateParameter(valid_598632, JString, required = false,
                                 default = nil)
  if valid_598632 != nil:
    section.add "X-Amz-Security-Token", valid_598632
  var valid_598633 = header.getOrDefault("X-Amz-Algorithm")
  valid_598633 = validateParameter(valid_598633, JString, required = false,
                                 default = nil)
  if valid_598633 != nil:
    section.add "X-Amz-Algorithm", valid_598633
  var valid_598634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598634 = validateParameter(valid_598634, JString, required = false,
                                 default = nil)
  if valid_598634 != nil:
    section.add "X-Amz-SignedHeaders", valid_598634
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598635: Call_ListLayers_598622; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layers</a> and shows information about the latest version of each. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only layers that indicate that they're compatible with that runtime.
  ## 
  let valid = call_598635.validator(path, query, header, formData, body)
  let scheme = call_598635.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598635.url(scheme.get, call_598635.host, call_598635.base,
                         call_598635.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598635, url, valid)

proc call*(call_598636: Call_ListLayers_598622; Marker: string = "";
          CompatibleRuntime: string = "nodejs"; MaxItems: int = 0): Recallable =
  ## listLayers
  ## Lists <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layers</a> and shows information about the latest version of each. Specify a <a href="https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html">runtime identifier</a> to list only layers that indicate that they're compatible with that runtime.
  ##   Marker: string
  ##         : A pagination token returned by a previous call.
  ##   CompatibleRuntime: string
  ##                    : A runtime identifier. For example, <code>go1.x</code>.
  ##   MaxItems: int
  ##           : The maximum number of layers to return.
  var query_598637 = newJObject()
  add(query_598637, "Marker", newJString(Marker))
  add(query_598637, "CompatibleRuntime", newJString(CompatibleRuntime))
  add(query_598637, "MaxItems", newJInt(MaxItems))
  result = call_598636.call(nil, query_598637, nil, nil, nil)

var listLayers* = Call_ListLayers_598622(name: "listLayers",
                                      meth: HttpMethod.HttpGet,
                                      host: "lambda.amazonaws.com",
                                      route: "/2018-10-31/layers",
                                      validator: validate_ListLayers_598623,
                                      base: "/", url: url_ListLayers_598624,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProvisionedConcurrencyConfigs_598638 = ref object of OpenApiRestCall_597389
proc url_ListProvisionedConcurrencyConfigs_598640(protocol: Scheme; host: string;
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

proc validate_ListProvisionedConcurrencyConfigs_598639(path: JsonNode;
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
  var valid_598641 = path.getOrDefault("FunctionName")
  valid_598641 = validateParameter(valid_598641, JString, required = true,
                                 default = nil)
  if valid_598641 != nil:
    section.add "FunctionName", valid_598641
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: JInt
  ##           : Specify a number to limit the number of configurations returned.
  ##   List: JString (required)
  section = newJObject()
  var valid_598642 = query.getOrDefault("Marker")
  valid_598642 = validateParameter(valid_598642, JString, required = false,
                                 default = nil)
  if valid_598642 != nil:
    section.add "Marker", valid_598642
  var valid_598643 = query.getOrDefault("MaxItems")
  valid_598643 = validateParameter(valid_598643, JInt, required = false, default = nil)
  if valid_598643 != nil:
    section.add "MaxItems", valid_598643
  assert query != nil, "query argument is necessary due to required `List` field"
  var valid_598644 = query.getOrDefault("List")
  valid_598644 = validateParameter(valid_598644, JString, required = true,
                                 default = newJString("ALL"))
  if valid_598644 != nil:
    section.add "List", valid_598644
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
  var valid_598645 = header.getOrDefault("X-Amz-Signature")
  valid_598645 = validateParameter(valid_598645, JString, required = false,
                                 default = nil)
  if valid_598645 != nil:
    section.add "X-Amz-Signature", valid_598645
  var valid_598646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598646 = validateParameter(valid_598646, JString, required = false,
                                 default = nil)
  if valid_598646 != nil:
    section.add "X-Amz-Content-Sha256", valid_598646
  var valid_598647 = header.getOrDefault("X-Amz-Date")
  valid_598647 = validateParameter(valid_598647, JString, required = false,
                                 default = nil)
  if valid_598647 != nil:
    section.add "X-Amz-Date", valid_598647
  var valid_598648 = header.getOrDefault("X-Amz-Credential")
  valid_598648 = validateParameter(valid_598648, JString, required = false,
                                 default = nil)
  if valid_598648 != nil:
    section.add "X-Amz-Credential", valid_598648
  var valid_598649 = header.getOrDefault("X-Amz-Security-Token")
  valid_598649 = validateParameter(valid_598649, JString, required = false,
                                 default = nil)
  if valid_598649 != nil:
    section.add "X-Amz-Security-Token", valid_598649
  var valid_598650 = header.getOrDefault("X-Amz-Algorithm")
  valid_598650 = validateParameter(valid_598650, JString, required = false,
                                 default = nil)
  if valid_598650 != nil:
    section.add "X-Amz-Algorithm", valid_598650
  var valid_598651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598651 = validateParameter(valid_598651, JString, required = false,
                                 default = nil)
  if valid_598651 != nil:
    section.add "X-Amz-SignedHeaders", valid_598651
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598652: Call_ListProvisionedConcurrencyConfigs_598638;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Retrieves a list of provisioned concurrency configurations for a function.
  ## 
  let valid = call_598652.validator(path, query, header, formData, body)
  let scheme = call_598652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598652.url(scheme.get, call_598652.host, call_598652.base,
                         call_598652.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598652, url, valid)

proc call*(call_598653: Call_ListProvisionedConcurrencyConfigs_598638;
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
  var path_598654 = newJObject()
  var query_598655 = newJObject()
  add(query_598655, "Marker", newJString(Marker))
  add(path_598654, "FunctionName", newJString(FunctionName))
  add(query_598655, "MaxItems", newJInt(MaxItems))
  add(query_598655, "List", newJString(List))
  result = call_598653.call(path_598654, query_598655, nil, nil, nil)

var listProvisionedConcurrencyConfigs* = Call_ListProvisionedConcurrencyConfigs_598638(
    name: "listProvisionedConcurrencyConfigs", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com", route: "/2019-09-30/functions/{FunctionName}/provisioned-concurrency#List=ALL",
    validator: validate_ListProvisionedConcurrencyConfigs_598639, base: "/",
    url: url_ListProvisionedConcurrencyConfigs_598640,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_598670 = ref object of OpenApiRestCall_597389
proc url_TagResource_598672(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_598671(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598673 = path.getOrDefault("ARN")
  valid_598673 = validateParameter(valid_598673, JString, required = true,
                                 default = nil)
  if valid_598673 != nil:
    section.add "ARN", valid_598673
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
  var valid_598674 = header.getOrDefault("X-Amz-Signature")
  valid_598674 = validateParameter(valid_598674, JString, required = false,
                                 default = nil)
  if valid_598674 != nil:
    section.add "X-Amz-Signature", valid_598674
  var valid_598675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598675 = validateParameter(valid_598675, JString, required = false,
                                 default = nil)
  if valid_598675 != nil:
    section.add "X-Amz-Content-Sha256", valid_598675
  var valid_598676 = header.getOrDefault("X-Amz-Date")
  valid_598676 = validateParameter(valid_598676, JString, required = false,
                                 default = nil)
  if valid_598676 != nil:
    section.add "X-Amz-Date", valid_598676
  var valid_598677 = header.getOrDefault("X-Amz-Credential")
  valid_598677 = validateParameter(valid_598677, JString, required = false,
                                 default = nil)
  if valid_598677 != nil:
    section.add "X-Amz-Credential", valid_598677
  var valid_598678 = header.getOrDefault("X-Amz-Security-Token")
  valid_598678 = validateParameter(valid_598678, JString, required = false,
                                 default = nil)
  if valid_598678 != nil:
    section.add "X-Amz-Security-Token", valid_598678
  var valid_598679 = header.getOrDefault("X-Amz-Algorithm")
  valid_598679 = validateParameter(valid_598679, JString, required = false,
                                 default = nil)
  if valid_598679 != nil:
    section.add "X-Amz-Algorithm", valid_598679
  var valid_598680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598680 = validateParameter(valid_598680, JString, required = false,
                                 default = nil)
  if valid_598680 != nil:
    section.add "X-Amz-SignedHeaders", valid_598680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598682: Call_TagResource_598670; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> to a function.
  ## 
  let valid = call_598682.validator(path, query, header, formData, body)
  let scheme = call_598682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598682.url(scheme.get, call_598682.host, call_598682.base,
                         call_598682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598682, url, valid)

proc call*(call_598683: Call_TagResource_598670; ARN: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> to a function.
  ##   ARN: string (required)
  ##      : The function's Amazon Resource Name (ARN).
  ##   body: JObject (required)
  var path_598684 = newJObject()
  var body_598685 = newJObject()
  add(path_598684, "ARN", newJString(ARN))
  if body != nil:
    body_598685 = body
  result = call_598683.call(path_598684, nil, nil, nil, body_598685)

var tagResource* = Call_TagResource_598670(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "lambda.amazonaws.com",
                                        route: "/2017-03-31/tags/{ARN}",
                                        validator: validate_TagResource_598671,
                                        base: "/", url: url_TagResource_598672,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTags_598656 = ref object of OpenApiRestCall_597389
proc url_ListTags_598658(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListTags_598657(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598659 = path.getOrDefault("ARN")
  valid_598659 = validateParameter(valid_598659, JString, required = true,
                                 default = nil)
  if valid_598659 != nil:
    section.add "ARN", valid_598659
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
  var valid_598660 = header.getOrDefault("X-Amz-Signature")
  valid_598660 = validateParameter(valid_598660, JString, required = false,
                                 default = nil)
  if valid_598660 != nil:
    section.add "X-Amz-Signature", valid_598660
  var valid_598661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598661 = validateParameter(valid_598661, JString, required = false,
                                 default = nil)
  if valid_598661 != nil:
    section.add "X-Amz-Content-Sha256", valid_598661
  var valid_598662 = header.getOrDefault("X-Amz-Date")
  valid_598662 = validateParameter(valid_598662, JString, required = false,
                                 default = nil)
  if valid_598662 != nil:
    section.add "X-Amz-Date", valid_598662
  var valid_598663 = header.getOrDefault("X-Amz-Credential")
  valid_598663 = validateParameter(valid_598663, JString, required = false,
                                 default = nil)
  if valid_598663 != nil:
    section.add "X-Amz-Credential", valid_598663
  var valid_598664 = header.getOrDefault("X-Amz-Security-Token")
  valid_598664 = validateParameter(valid_598664, JString, required = false,
                                 default = nil)
  if valid_598664 != nil:
    section.add "X-Amz-Security-Token", valid_598664
  var valid_598665 = header.getOrDefault("X-Amz-Algorithm")
  valid_598665 = validateParameter(valid_598665, JString, required = false,
                                 default = nil)
  if valid_598665 != nil:
    section.add "X-Amz-Algorithm", valid_598665
  var valid_598666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598666 = validateParameter(valid_598666, JString, required = false,
                                 default = nil)
  if valid_598666 != nil:
    section.add "X-Amz-SignedHeaders", valid_598666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598667: Call_ListTags_598656; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a function's <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a>. You can also view tags with <a>GetFunction</a>.
  ## 
  let valid = call_598667.validator(path, query, header, formData, body)
  let scheme = call_598667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598667.url(scheme.get, call_598667.host, call_598667.base,
                         call_598667.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598667, url, valid)

proc call*(call_598668: Call_ListTags_598656; ARN: string): Recallable =
  ## listTags
  ## Returns a function's <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a>. You can also view tags with <a>GetFunction</a>.
  ##   ARN: string (required)
  ##      : The function's Amazon Resource Name (ARN).
  var path_598669 = newJObject()
  add(path_598669, "ARN", newJString(ARN))
  result = call_598668.call(path_598669, nil, nil, nil, nil)

var listTags* = Call_ListTags_598656(name: "listTags", meth: HttpMethod.HttpGet,
                                  host: "lambda.amazonaws.com",
                                  route: "/2017-03-31/tags/{ARN}",
                                  validator: validate_ListTags_598657, base: "/",
                                  url: url_ListTags_598658,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_PublishVersion_598703 = ref object of OpenApiRestCall_597389
proc url_PublishVersion_598705(protocol: Scheme; host: string; base: string;
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

proc validate_PublishVersion_598704(path: JsonNode; query: JsonNode;
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
  var valid_598706 = path.getOrDefault("FunctionName")
  valid_598706 = validateParameter(valid_598706, JString, required = true,
                                 default = nil)
  if valid_598706 != nil:
    section.add "FunctionName", valid_598706
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
  var valid_598707 = header.getOrDefault("X-Amz-Signature")
  valid_598707 = validateParameter(valid_598707, JString, required = false,
                                 default = nil)
  if valid_598707 != nil:
    section.add "X-Amz-Signature", valid_598707
  var valid_598708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598708 = validateParameter(valid_598708, JString, required = false,
                                 default = nil)
  if valid_598708 != nil:
    section.add "X-Amz-Content-Sha256", valid_598708
  var valid_598709 = header.getOrDefault("X-Amz-Date")
  valid_598709 = validateParameter(valid_598709, JString, required = false,
                                 default = nil)
  if valid_598709 != nil:
    section.add "X-Amz-Date", valid_598709
  var valid_598710 = header.getOrDefault("X-Amz-Credential")
  valid_598710 = validateParameter(valid_598710, JString, required = false,
                                 default = nil)
  if valid_598710 != nil:
    section.add "X-Amz-Credential", valid_598710
  var valid_598711 = header.getOrDefault("X-Amz-Security-Token")
  valid_598711 = validateParameter(valid_598711, JString, required = false,
                                 default = nil)
  if valid_598711 != nil:
    section.add "X-Amz-Security-Token", valid_598711
  var valid_598712 = header.getOrDefault("X-Amz-Algorithm")
  valid_598712 = validateParameter(valid_598712, JString, required = false,
                                 default = nil)
  if valid_598712 != nil:
    section.add "X-Amz-Algorithm", valid_598712
  var valid_598713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598713 = validateParameter(valid_598713, JString, required = false,
                                 default = nil)
  if valid_598713 != nil:
    section.add "X-Amz-SignedHeaders", valid_598713
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598715: Call_PublishVersion_598703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">version</a> from the current code and configuration of a function. Use versions to create a snapshot of your function code and configuration that doesn't change.</p> <p>AWS Lambda doesn't publish a version if the function's configuration and code haven't changed since the last version. Use <a>UpdateFunctionCode</a> or <a>UpdateFunctionConfiguration</a> to update the function before publishing a version.</p> <p>Clients can invoke versions directly or with an alias. To create an alias, use <a>CreateAlias</a>.</p>
  ## 
  let valid = call_598715.validator(path, query, header, formData, body)
  let scheme = call_598715.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598715.url(scheme.get, call_598715.host, call_598715.base,
                         call_598715.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598715, url, valid)

proc call*(call_598716: Call_PublishVersion_598703; FunctionName: string;
          body: JsonNode): Recallable =
  ## publishVersion
  ## <p>Creates a <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">version</a> from the current code and configuration of a function. Use versions to create a snapshot of your function code and configuration that doesn't change.</p> <p>AWS Lambda doesn't publish a version if the function's configuration and code haven't changed since the last version. Use <a>UpdateFunctionCode</a> or <a>UpdateFunctionConfiguration</a> to update the function before publishing a version.</p> <p>Clients can invoke versions directly or with an alias. To create an alias, use <a>CreateAlias</a>.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_598717 = newJObject()
  var body_598718 = newJObject()
  add(path_598717, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_598718 = body
  result = call_598716.call(path_598717, nil, nil, nil, body_598718)

var publishVersion* = Call_PublishVersion_598703(name: "publishVersion",
    meth: HttpMethod.HttpPost, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/versions",
    validator: validate_PublishVersion_598704, base: "/", url: url_PublishVersion_598705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListVersionsByFunction_598686 = ref object of OpenApiRestCall_597389
proc url_ListVersionsByFunction_598688(protocol: Scheme; host: string; base: string;
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

proc validate_ListVersionsByFunction_598687(path: JsonNode; query: JsonNode;
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
  var valid_598689 = path.getOrDefault("FunctionName")
  valid_598689 = validateParameter(valid_598689, JString, required = true,
                                 default = nil)
  if valid_598689 != nil:
    section.add "FunctionName", valid_598689
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   MaxItems: JInt
  ##           : Limit the number of versions that are returned.
  section = newJObject()
  var valid_598690 = query.getOrDefault("Marker")
  valid_598690 = validateParameter(valid_598690, JString, required = false,
                                 default = nil)
  if valid_598690 != nil:
    section.add "Marker", valid_598690
  var valid_598691 = query.getOrDefault("MaxItems")
  valid_598691 = validateParameter(valid_598691, JInt, required = false, default = nil)
  if valid_598691 != nil:
    section.add "MaxItems", valid_598691
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
  var valid_598692 = header.getOrDefault("X-Amz-Signature")
  valid_598692 = validateParameter(valid_598692, JString, required = false,
                                 default = nil)
  if valid_598692 != nil:
    section.add "X-Amz-Signature", valid_598692
  var valid_598693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598693 = validateParameter(valid_598693, JString, required = false,
                                 default = nil)
  if valid_598693 != nil:
    section.add "X-Amz-Content-Sha256", valid_598693
  var valid_598694 = header.getOrDefault("X-Amz-Date")
  valid_598694 = validateParameter(valid_598694, JString, required = false,
                                 default = nil)
  if valid_598694 != nil:
    section.add "X-Amz-Date", valid_598694
  var valid_598695 = header.getOrDefault("X-Amz-Credential")
  valid_598695 = validateParameter(valid_598695, JString, required = false,
                                 default = nil)
  if valid_598695 != nil:
    section.add "X-Amz-Credential", valid_598695
  var valid_598696 = header.getOrDefault("X-Amz-Security-Token")
  valid_598696 = validateParameter(valid_598696, JString, required = false,
                                 default = nil)
  if valid_598696 != nil:
    section.add "X-Amz-Security-Token", valid_598696
  var valid_598697 = header.getOrDefault("X-Amz-Algorithm")
  valid_598697 = validateParameter(valid_598697, JString, required = false,
                                 default = nil)
  if valid_598697 != nil:
    section.add "X-Amz-Algorithm", valid_598697
  var valid_598698 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598698 = validateParameter(valid_598698, JString, required = false,
                                 default = nil)
  if valid_598698 != nil:
    section.add "X-Amz-SignedHeaders", valid_598698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598699: Call_ListVersionsByFunction_598686; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">versions</a>, with the version-specific configuration of each. 
  ## 
  let valid = call_598699.validator(path, query, header, formData, body)
  let scheme = call_598699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598699.url(scheme.get, call_598699.host, call_598699.base,
                         call_598699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598699, url, valid)

proc call*(call_598700: Call_ListVersionsByFunction_598686; FunctionName: string;
          Marker: string = ""; MaxItems: int = 0): Recallable =
  ## listVersionsByFunction
  ## Returns a list of <a href="https://docs.aws.amazon.com/lambda/latest/dg/versioning-aliases.html">versions</a>, with the version-specific configuration of each. 
  ##   Marker: string
  ##         : Specify the pagination token that's returned by a previous request to retrieve the next page of results.
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>MyFunction</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:MyFunction</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:MyFunction</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   MaxItems: int
  ##           : Limit the number of versions that are returned.
  var path_598701 = newJObject()
  var query_598702 = newJObject()
  add(query_598702, "Marker", newJString(Marker))
  add(path_598701, "FunctionName", newJString(FunctionName))
  add(query_598702, "MaxItems", newJInt(MaxItems))
  result = call_598700.call(path_598701, query_598702, nil, nil, nil)

var listVersionsByFunction* = Call_ListVersionsByFunction_598686(
    name: "listVersionsByFunction", meth: HttpMethod.HttpGet,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/versions",
    validator: validate_ListVersionsByFunction_598687, base: "/",
    url: url_ListVersionsByFunction_598688, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveLayerVersionPermission_598719 = ref object of OpenApiRestCall_597389
proc url_RemoveLayerVersionPermission_598721(protocol: Scheme; host: string;
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

proc validate_RemoveLayerVersionPermission_598720(path: JsonNode; query: JsonNode;
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
  var valid_598722 = path.getOrDefault("VersionNumber")
  valid_598722 = validateParameter(valid_598722, JInt, required = true, default = nil)
  if valid_598722 != nil:
    section.add "VersionNumber", valid_598722
  var valid_598723 = path.getOrDefault("StatementId")
  valid_598723 = validateParameter(valid_598723, JString, required = true,
                                 default = nil)
  if valid_598723 != nil:
    section.add "StatementId", valid_598723
  var valid_598724 = path.getOrDefault("LayerName")
  valid_598724 = validateParameter(valid_598724, JString, required = true,
                                 default = nil)
  if valid_598724 != nil:
    section.add "LayerName", valid_598724
  result.add "path", section
  ## parameters in `query` object:
  ##   RevisionId: JString
  ##             : Only update the policy if the revision ID matches the ID specified. Use this option to avoid modifying a policy that has changed since you last read it.
  section = newJObject()
  var valid_598725 = query.getOrDefault("RevisionId")
  valid_598725 = validateParameter(valid_598725, JString, required = false,
                                 default = nil)
  if valid_598725 != nil:
    section.add "RevisionId", valid_598725
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
  var valid_598726 = header.getOrDefault("X-Amz-Signature")
  valid_598726 = validateParameter(valid_598726, JString, required = false,
                                 default = nil)
  if valid_598726 != nil:
    section.add "X-Amz-Signature", valid_598726
  var valid_598727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598727 = validateParameter(valid_598727, JString, required = false,
                                 default = nil)
  if valid_598727 != nil:
    section.add "X-Amz-Content-Sha256", valid_598727
  var valid_598728 = header.getOrDefault("X-Amz-Date")
  valid_598728 = validateParameter(valid_598728, JString, required = false,
                                 default = nil)
  if valid_598728 != nil:
    section.add "X-Amz-Date", valid_598728
  var valid_598729 = header.getOrDefault("X-Amz-Credential")
  valid_598729 = validateParameter(valid_598729, JString, required = false,
                                 default = nil)
  if valid_598729 != nil:
    section.add "X-Amz-Credential", valid_598729
  var valid_598730 = header.getOrDefault("X-Amz-Security-Token")
  valid_598730 = validateParameter(valid_598730, JString, required = false,
                                 default = nil)
  if valid_598730 != nil:
    section.add "X-Amz-Security-Token", valid_598730
  var valid_598731 = header.getOrDefault("X-Amz-Algorithm")
  valid_598731 = validateParameter(valid_598731, JString, required = false,
                                 default = nil)
  if valid_598731 != nil:
    section.add "X-Amz-Algorithm", valid_598731
  var valid_598732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598732 = validateParameter(valid_598732, JString, required = false,
                                 default = nil)
  if valid_598732 != nil:
    section.add "X-Amz-SignedHeaders", valid_598732
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598733: Call_RemoveLayerVersionPermission_598719; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a statement from the permissions policy for a version of an <a href="https://docs.aws.amazon.com/lambda/latest/dg/configuration-layers.html">AWS Lambda layer</a>. For more information, see <a>AddLayerVersionPermission</a>.
  ## 
  let valid = call_598733.validator(path, query, header, formData, body)
  let scheme = call_598733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598733.url(scheme.get, call_598733.host, call_598733.base,
                         call_598733.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598733, url, valid)

proc call*(call_598734: Call_RemoveLayerVersionPermission_598719;
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
  var path_598735 = newJObject()
  var query_598736 = newJObject()
  add(query_598736, "RevisionId", newJString(RevisionId))
  add(path_598735, "VersionNumber", newJInt(VersionNumber))
  add(path_598735, "StatementId", newJString(StatementId))
  add(path_598735, "LayerName", newJString(LayerName))
  result = call_598734.call(path_598735, query_598736, nil, nil, nil)

var removeLayerVersionPermission* = Call_RemoveLayerVersionPermission_598719(
    name: "removeLayerVersionPermission", meth: HttpMethod.HttpDelete,
    host: "lambda.amazonaws.com", route: "/2018-10-31/layers/{LayerName}/versions/{VersionNumber}/policy/{StatementId}",
    validator: validate_RemoveLayerVersionPermission_598720, base: "/",
    url: url_RemoveLayerVersionPermission_598721,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemovePermission_598737 = ref object of OpenApiRestCall_597389
proc url_RemovePermission_598739(protocol: Scheme; host: string; base: string;
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

proc validate_RemovePermission_598738(path: JsonNode; query: JsonNode;
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
  var valid_598740 = path.getOrDefault("FunctionName")
  valid_598740 = validateParameter(valid_598740, JString, required = true,
                                 default = nil)
  if valid_598740 != nil:
    section.add "FunctionName", valid_598740
  var valid_598741 = path.getOrDefault("StatementId")
  valid_598741 = validateParameter(valid_598741, JString, required = true,
                                 default = nil)
  if valid_598741 != nil:
    section.add "StatementId", valid_598741
  result.add "path", section
  ## parameters in `query` object:
  ##   RevisionId: JString
  ##             : Only update the policy if the revision ID matches the ID that's specified. Use this option to avoid modifying a policy that has changed since you last read it.
  ##   Qualifier: JString
  ##            : Specify a version or alias to remove permissions from a published version of the function.
  section = newJObject()
  var valid_598742 = query.getOrDefault("RevisionId")
  valid_598742 = validateParameter(valid_598742, JString, required = false,
                                 default = nil)
  if valid_598742 != nil:
    section.add "RevisionId", valid_598742
  var valid_598743 = query.getOrDefault("Qualifier")
  valid_598743 = validateParameter(valid_598743, JString, required = false,
                                 default = nil)
  if valid_598743 != nil:
    section.add "Qualifier", valid_598743
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
  var valid_598744 = header.getOrDefault("X-Amz-Signature")
  valid_598744 = validateParameter(valid_598744, JString, required = false,
                                 default = nil)
  if valid_598744 != nil:
    section.add "X-Amz-Signature", valid_598744
  var valid_598745 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598745 = validateParameter(valid_598745, JString, required = false,
                                 default = nil)
  if valid_598745 != nil:
    section.add "X-Amz-Content-Sha256", valid_598745
  var valid_598746 = header.getOrDefault("X-Amz-Date")
  valid_598746 = validateParameter(valid_598746, JString, required = false,
                                 default = nil)
  if valid_598746 != nil:
    section.add "X-Amz-Date", valid_598746
  var valid_598747 = header.getOrDefault("X-Amz-Credential")
  valid_598747 = validateParameter(valid_598747, JString, required = false,
                                 default = nil)
  if valid_598747 != nil:
    section.add "X-Amz-Credential", valid_598747
  var valid_598748 = header.getOrDefault("X-Amz-Security-Token")
  valid_598748 = validateParameter(valid_598748, JString, required = false,
                                 default = nil)
  if valid_598748 != nil:
    section.add "X-Amz-Security-Token", valid_598748
  var valid_598749 = header.getOrDefault("X-Amz-Algorithm")
  valid_598749 = validateParameter(valid_598749, JString, required = false,
                                 default = nil)
  if valid_598749 != nil:
    section.add "X-Amz-Algorithm", valid_598749
  var valid_598750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598750 = validateParameter(valid_598750, JString, required = false,
                                 default = nil)
  if valid_598750 != nil:
    section.add "X-Amz-SignedHeaders", valid_598750
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598751: Call_RemovePermission_598737; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Revokes function-use permission from an AWS service or another account. You can get the ID of the statement from the output of <a>GetPolicy</a>.
  ## 
  let valid = call_598751.validator(path, query, header, formData, body)
  let scheme = call_598751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598751.url(scheme.get, call_598751.host, call_598751.base,
                         call_598751.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598751, url, valid)

proc call*(call_598752: Call_RemovePermission_598737; FunctionName: string;
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
  var path_598753 = newJObject()
  var query_598754 = newJObject()
  add(query_598754, "RevisionId", newJString(RevisionId))
  add(path_598753, "FunctionName", newJString(FunctionName))
  add(path_598753, "StatementId", newJString(StatementId))
  add(query_598754, "Qualifier", newJString(Qualifier))
  result = call_598752.call(path_598753, query_598754, nil, nil, nil)

var removePermission* = Call_RemovePermission_598737(name: "removePermission",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/policy/{StatementId}",
    validator: validate_RemovePermission_598738, base: "/",
    url: url_RemovePermission_598739, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_598755 = ref object of OpenApiRestCall_597389
proc url_UntagResource_598757(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_598756(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598758 = path.getOrDefault("ARN")
  valid_598758 = validateParameter(valid_598758, JString, required = true,
                                 default = nil)
  if valid_598758 != nil:
    section.add "ARN", valid_598758
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A list of tag keys to remove from the function.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_598759 = query.getOrDefault("tagKeys")
  valid_598759 = validateParameter(valid_598759, JArray, required = true, default = nil)
  if valid_598759 != nil:
    section.add "tagKeys", valid_598759
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
  var valid_598760 = header.getOrDefault("X-Amz-Signature")
  valid_598760 = validateParameter(valid_598760, JString, required = false,
                                 default = nil)
  if valid_598760 != nil:
    section.add "X-Amz-Signature", valid_598760
  var valid_598761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598761 = validateParameter(valid_598761, JString, required = false,
                                 default = nil)
  if valid_598761 != nil:
    section.add "X-Amz-Content-Sha256", valid_598761
  var valid_598762 = header.getOrDefault("X-Amz-Date")
  valid_598762 = validateParameter(valid_598762, JString, required = false,
                                 default = nil)
  if valid_598762 != nil:
    section.add "X-Amz-Date", valid_598762
  var valid_598763 = header.getOrDefault("X-Amz-Credential")
  valid_598763 = validateParameter(valid_598763, JString, required = false,
                                 default = nil)
  if valid_598763 != nil:
    section.add "X-Amz-Credential", valid_598763
  var valid_598764 = header.getOrDefault("X-Amz-Security-Token")
  valid_598764 = validateParameter(valid_598764, JString, required = false,
                                 default = nil)
  if valid_598764 != nil:
    section.add "X-Amz-Security-Token", valid_598764
  var valid_598765 = header.getOrDefault("X-Amz-Algorithm")
  valid_598765 = validateParameter(valid_598765, JString, required = false,
                                 default = nil)
  if valid_598765 != nil:
    section.add "X-Amz-Algorithm", valid_598765
  var valid_598766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598766 = validateParameter(valid_598766, JString, required = false,
                                 default = nil)
  if valid_598766 != nil:
    section.add "X-Amz-SignedHeaders", valid_598766
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598767: Call_UntagResource_598755; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> from a function.
  ## 
  let valid = call_598767.validator(path, query, header, formData, body)
  let scheme = call_598767.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598767.url(scheme.get, call_598767.host, call_598767.base,
                         call_598767.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598767, url, valid)

proc call*(call_598768: Call_UntagResource_598755; ARN: string; tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes <a href="https://docs.aws.amazon.com/lambda/latest/dg/tagging.html">tags</a> from a function.
  ##   ARN: string (required)
  ##      : The function's Amazon Resource Name (ARN).
  ##   tagKeys: JArray (required)
  ##          : A list of tag keys to remove from the function.
  var path_598769 = newJObject()
  var query_598770 = newJObject()
  add(path_598769, "ARN", newJString(ARN))
  if tagKeys != nil:
    query_598770.add "tagKeys", tagKeys
  result = call_598768.call(path_598769, query_598770, nil, nil, nil)

var untagResource* = Call_UntagResource_598755(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "lambda.amazonaws.com",
    route: "/2017-03-31/tags/{ARN}#tagKeys", validator: validate_UntagResource_598756,
    base: "/", url: url_UntagResource_598757, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFunctionCode_598771 = ref object of OpenApiRestCall_597389
proc url_UpdateFunctionCode_598773(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateFunctionCode_598772(path: JsonNode; query: JsonNode;
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
  var valid_598774 = path.getOrDefault("FunctionName")
  valid_598774 = validateParameter(valid_598774, JString, required = true,
                                 default = nil)
  if valid_598774 != nil:
    section.add "FunctionName", valid_598774
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
  var valid_598775 = header.getOrDefault("X-Amz-Signature")
  valid_598775 = validateParameter(valid_598775, JString, required = false,
                                 default = nil)
  if valid_598775 != nil:
    section.add "X-Amz-Signature", valid_598775
  var valid_598776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598776 = validateParameter(valid_598776, JString, required = false,
                                 default = nil)
  if valid_598776 != nil:
    section.add "X-Amz-Content-Sha256", valid_598776
  var valid_598777 = header.getOrDefault("X-Amz-Date")
  valid_598777 = validateParameter(valid_598777, JString, required = false,
                                 default = nil)
  if valid_598777 != nil:
    section.add "X-Amz-Date", valid_598777
  var valid_598778 = header.getOrDefault("X-Amz-Credential")
  valid_598778 = validateParameter(valid_598778, JString, required = false,
                                 default = nil)
  if valid_598778 != nil:
    section.add "X-Amz-Credential", valid_598778
  var valid_598779 = header.getOrDefault("X-Amz-Security-Token")
  valid_598779 = validateParameter(valid_598779, JString, required = false,
                                 default = nil)
  if valid_598779 != nil:
    section.add "X-Amz-Security-Token", valid_598779
  var valid_598780 = header.getOrDefault("X-Amz-Algorithm")
  valid_598780 = validateParameter(valid_598780, JString, required = false,
                                 default = nil)
  if valid_598780 != nil:
    section.add "X-Amz-Algorithm", valid_598780
  var valid_598781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598781 = validateParameter(valid_598781, JString, required = false,
                                 default = nil)
  if valid_598781 != nil:
    section.add "X-Amz-SignedHeaders", valid_598781
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598783: Call_UpdateFunctionCode_598771; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a Lambda function's code.</p> <p>The function's code is locked when you publish a version. You can't modify the code of a published version, only the unpublished version.</p>
  ## 
  let valid = call_598783.validator(path, query, header, formData, body)
  let scheme = call_598783.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598783.url(scheme.get, call_598783.host, call_598783.base,
                         call_598783.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598783, url, valid)

proc call*(call_598784: Call_UpdateFunctionCode_598771; FunctionName: string;
          body: JsonNode): Recallable =
  ## updateFunctionCode
  ## <p>Updates a Lambda function's code.</p> <p>The function's code is locked when you publish a version. You can't modify the code of a published version, only the unpublished version.</p>
  ##   FunctionName: string (required)
  ##               : <p>The name of the Lambda function.</p> <p class="title"> <b>Name formats</b> </p> <ul> <li> <p> <b>Function name</b> - <code>my-function</code>.</p> </li> <li> <p> <b>Function ARN</b> - <code>arn:aws:lambda:us-west-2:123456789012:function:my-function</code>.</p> </li> <li> <p> <b>Partial ARN</b> - <code>123456789012:function:my-function</code>.</p> </li> </ul> <p>The length constraint applies only to the full ARN. If you specify only the function name, it is limited to 64 characters in length.</p>
  ##   body: JObject (required)
  var path_598785 = newJObject()
  var body_598786 = newJObject()
  add(path_598785, "FunctionName", newJString(FunctionName))
  if body != nil:
    body_598786 = body
  result = call_598784.call(path_598785, nil, nil, nil, body_598786)

var updateFunctionCode* = Call_UpdateFunctionCode_598771(
    name: "updateFunctionCode", meth: HttpMethod.HttpPut,
    host: "lambda.amazonaws.com",
    route: "/2015-03-31/functions/{FunctionName}/code",
    validator: validate_UpdateFunctionCode_598772, base: "/",
    url: url_UpdateFunctionCode_598773, schemes: {Scheme.Https, Scheme.Http})
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
