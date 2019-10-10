
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Config
## version: 2014-11-12
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Config</fullname> <p>AWS Config provides a way to keep track of the configurations of all the AWS resources associated with your AWS account. You can use AWS Config to get the current and historical configurations of each AWS resource and also to get information about the relationship between the resources. An AWS resource can be an Amazon Compute Cloud (Amazon EC2) instance, an Elastic Block Store (EBS) volume, an elastic network Interface (ENI), or a security group. For a complete list of resources currently supported by AWS Config, see <a href="https://docs.aws.amazon.com/config/latest/developerguide/resource-config-reference.html#supported-resources">Supported AWS Resources</a>.</p> <p>You can access and manage AWS Config through the AWS Management Console, the AWS Command Line Interface (AWS CLI), the AWS Config API, or the AWS SDKs for AWS Config. This reference guide contains documentation for the AWS Config API and the AWS CLI commands that you can use to manage AWS Config. The AWS Config API uses the Signature Version 4 protocol for signing requests. For more information about how to sign a request with this protocol, see <a href="https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html">Signature Version 4 Signing Process</a>. For detailed information about AWS Config features and their associated actions or commands, as well as how to work with AWS Management Console, see <a href="https://docs.aws.amazon.com/config/latest/developerguide/WhatIsConfig.html">What Is AWS Config</a> in the <i>AWS Config Developer Guide</i>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/config/
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

  OpenApiRestCall_602466 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602466](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602466): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "config.ap-northeast-1.amazonaws.com", "ap-southeast-1": "config.ap-southeast-1.amazonaws.com",
                           "us-west-2": "config.us-west-2.amazonaws.com",
                           "eu-west-2": "config.eu-west-2.amazonaws.com", "ap-northeast-3": "config.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "config.eu-central-1.amazonaws.com",
                           "us-east-2": "config.us-east-2.amazonaws.com",
                           "us-east-1": "config.us-east-1.amazonaws.com", "cn-northwest-1": "config.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "config.ap-south-1.amazonaws.com",
                           "eu-north-1": "config.eu-north-1.amazonaws.com", "ap-northeast-2": "config.ap-northeast-2.amazonaws.com",
                           "us-west-1": "config.us-west-1.amazonaws.com", "us-gov-east-1": "config.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "config.eu-west-3.amazonaws.com",
                           "cn-north-1": "config.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "config.sa-east-1.amazonaws.com",
                           "eu-west-1": "config.eu-west-1.amazonaws.com", "us-gov-west-1": "config.us-gov-west-1.amazonaws.com", "ap-southeast-2": "config.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "config.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "config.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "config.ap-southeast-1.amazonaws.com",
      "us-west-2": "config.us-west-2.amazonaws.com",
      "eu-west-2": "config.eu-west-2.amazonaws.com",
      "ap-northeast-3": "config.ap-northeast-3.amazonaws.com",
      "eu-central-1": "config.eu-central-1.amazonaws.com",
      "us-east-2": "config.us-east-2.amazonaws.com",
      "us-east-1": "config.us-east-1.amazonaws.com",
      "cn-northwest-1": "config.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "config.ap-south-1.amazonaws.com",
      "eu-north-1": "config.eu-north-1.amazonaws.com",
      "ap-northeast-2": "config.ap-northeast-2.amazonaws.com",
      "us-west-1": "config.us-west-1.amazonaws.com",
      "us-gov-east-1": "config.us-gov-east-1.amazonaws.com",
      "eu-west-3": "config.eu-west-3.amazonaws.com",
      "cn-north-1": "config.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "config.sa-east-1.amazonaws.com",
      "eu-west-1": "config.eu-west-1.amazonaws.com",
      "us-gov-west-1": "config.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "config.ap-southeast-2.amazonaws.com",
      "ca-central-1": "config.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "config"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchGetAggregateResourceConfig_602803 = ref object of OpenApiRestCall_602466
proc url_BatchGetAggregateResourceConfig_602805(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetAggregateResourceConfig_602804(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the current configuration items for resources that are present in your AWS Config aggregator. The operation also returns a list of resources that are not processed in the current request. If there are no unprocessed resources, the operation returns an empty <code>unprocessedResourceIdentifiers</code> list. </p> <note> <ul> <li> <p>The API does not return results for deleted resources.</p> </li> <li> <p> The API does not return tags and relationships.</p> </li> </ul> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602917 = header.getOrDefault("X-Amz-Date")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Date", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-Security-Token")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Security-Token", valid_602918
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_602932 = header.getOrDefault("X-Amz-Target")
  valid_602932 = validateParameter(valid_602932, JString, required = true, default = newJString(
      "StarlingDoveService.BatchGetAggregateResourceConfig"))
  if valid_602932 != nil:
    section.add "X-Amz-Target", valid_602932
  var valid_602933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Content-Sha256", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Algorithm")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Algorithm", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Signature")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Signature", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-SignedHeaders", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Credential")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Credential", valid_602937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602961: Call_BatchGetAggregateResourceConfig_602803;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns the current configuration items for resources that are present in your AWS Config aggregator. The operation also returns a list of resources that are not processed in the current request. If there are no unprocessed resources, the operation returns an empty <code>unprocessedResourceIdentifiers</code> list. </p> <note> <ul> <li> <p>The API does not return results for deleted resources.</p> </li> <li> <p> The API does not return tags and relationships.</p> </li> </ul> </note>
  ## 
  let valid = call_602961.validator(path, query, header, formData, body)
  let scheme = call_602961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602961.url(scheme.get, call_602961.host, call_602961.base,
                         call_602961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602961, url, valid)

proc call*(call_603032: Call_BatchGetAggregateResourceConfig_602803; body: JsonNode): Recallable =
  ## batchGetAggregateResourceConfig
  ## <p>Returns the current configuration items for resources that are present in your AWS Config aggregator. The operation also returns a list of resources that are not processed in the current request. If there are no unprocessed resources, the operation returns an empty <code>unprocessedResourceIdentifiers</code> list. </p> <note> <ul> <li> <p>The API does not return results for deleted resources.</p> </li> <li> <p> The API does not return tags and relationships.</p> </li> </ul> </note>
  ##   body: JObject (required)
  var body_603033 = newJObject()
  if body != nil:
    body_603033 = body
  result = call_603032.call(nil, nil, nil, nil, body_603033)

var batchGetAggregateResourceConfig* = Call_BatchGetAggregateResourceConfig_602803(
    name: "batchGetAggregateResourceConfig", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.BatchGetAggregateResourceConfig",
    validator: validate_BatchGetAggregateResourceConfig_602804, base: "/",
    url: url_BatchGetAggregateResourceConfig_602805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetResourceConfig_603072 = ref object of OpenApiRestCall_602466
proc url_BatchGetResourceConfig_603074(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchGetResourceConfig_603073(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the current configuration for one or more requested resources. The operation also returns a list of resources that are not processed in the current request. If there are no unprocessed resources, the operation returns an empty unprocessedResourceKeys list. </p> <note> <ul> <li> <p>The API does not return results for deleted resources.</p> </li> <li> <p> The API does not return any tags for the requested resources. This information is filtered out of the supplementaryConfiguration section of the API response.</p> </li> </ul> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603075 = header.getOrDefault("X-Amz-Date")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Date", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Security-Token")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Security-Token", valid_603076
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603077 = header.getOrDefault("X-Amz-Target")
  valid_603077 = validateParameter(valid_603077, JString, required = true, default = newJString(
      "StarlingDoveService.BatchGetResourceConfig"))
  if valid_603077 != nil:
    section.add "X-Amz-Target", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Content-Sha256", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Algorithm")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Algorithm", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Signature")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Signature", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-SignedHeaders", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Credential")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Credential", valid_603082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603084: Call_BatchGetResourceConfig_603072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the current configuration for one or more requested resources. The operation also returns a list of resources that are not processed in the current request. If there are no unprocessed resources, the operation returns an empty unprocessedResourceKeys list. </p> <note> <ul> <li> <p>The API does not return results for deleted resources.</p> </li> <li> <p> The API does not return any tags for the requested resources. This information is filtered out of the supplementaryConfiguration section of the API response.</p> </li> </ul> </note>
  ## 
  let valid = call_603084.validator(path, query, header, formData, body)
  let scheme = call_603084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603084.url(scheme.get, call_603084.host, call_603084.base,
                         call_603084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603084, url, valid)

proc call*(call_603085: Call_BatchGetResourceConfig_603072; body: JsonNode): Recallable =
  ## batchGetResourceConfig
  ## <p>Returns the current configuration for one or more requested resources. The operation also returns a list of resources that are not processed in the current request. If there are no unprocessed resources, the operation returns an empty unprocessedResourceKeys list. </p> <note> <ul> <li> <p>The API does not return results for deleted resources.</p> </li> <li> <p> The API does not return any tags for the requested resources. This information is filtered out of the supplementaryConfiguration section of the API response.</p> </li> </ul> </note>
  ##   body: JObject (required)
  var body_603086 = newJObject()
  if body != nil:
    body_603086 = body
  result = call_603085.call(nil, nil, nil, nil, body_603086)

var batchGetResourceConfig* = Call_BatchGetResourceConfig_603072(
    name: "batchGetResourceConfig", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.BatchGetResourceConfig",
    validator: validate_BatchGetResourceConfig_603073, base: "/",
    url: url_BatchGetResourceConfig_603074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAggregationAuthorization_603087 = ref object of OpenApiRestCall_602466
proc url_DeleteAggregationAuthorization_603089(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteAggregationAuthorization_603088(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the authorization granted to the specified configuration aggregator account in a specified region.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603090 = header.getOrDefault("X-Amz-Date")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Date", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Security-Token")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Security-Token", valid_603091
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603092 = header.getOrDefault("X-Amz-Target")
  valid_603092 = validateParameter(valid_603092, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteAggregationAuthorization"))
  if valid_603092 != nil:
    section.add "X-Amz-Target", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Content-Sha256", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-Algorithm")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-Algorithm", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Signature")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Signature", valid_603095
  var valid_603096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-SignedHeaders", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Credential")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Credential", valid_603097
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603099: Call_DeleteAggregationAuthorization_603087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the authorization granted to the specified configuration aggregator account in a specified region.
  ## 
  let valid = call_603099.validator(path, query, header, formData, body)
  let scheme = call_603099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603099.url(scheme.get, call_603099.host, call_603099.base,
                         call_603099.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603099, url, valid)

proc call*(call_603100: Call_DeleteAggregationAuthorization_603087; body: JsonNode): Recallable =
  ## deleteAggregationAuthorization
  ## Deletes the authorization granted to the specified configuration aggregator account in a specified region.
  ##   body: JObject (required)
  var body_603101 = newJObject()
  if body != nil:
    body_603101 = body
  result = call_603100.call(nil, nil, nil, nil, body_603101)

var deleteAggregationAuthorization* = Call_DeleteAggregationAuthorization_603087(
    name: "deleteAggregationAuthorization", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteAggregationAuthorization",
    validator: validate_DeleteAggregationAuthorization_603088, base: "/",
    url: url_DeleteAggregationAuthorization_603089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigRule_603102 = ref object of OpenApiRestCall_602466
proc url_DeleteConfigRule_603104(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteConfigRule_603103(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes the specified AWS Config rule and all of its evaluation results.</p> <p>AWS Config sets the state of a rule to <code>DELETING</code> until the deletion is complete. You cannot update a rule while it is in this state. If you make a <code>PutConfigRule</code> or <code>DeleteConfigRule</code> request for the rule, you will receive a <code>ResourceInUseException</code>.</p> <p>You can check the state of a rule by using the <code>DescribeConfigRules</code> request.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603105 = header.getOrDefault("X-Amz-Date")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Date", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Security-Token")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Security-Token", valid_603106
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603107 = header.getOrDefault("X-Amz-Target")
  valid_603107 = validateParameter(valid_603107, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteConfigRule"))
  if valid_603107 != nil:
    section.add "X-Amz-Target", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Content-Sha256", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-Algorithm")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-Algorithm", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Signature")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Signature", valid_603110
  var valid_603111 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-SignedHeaders", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Credential")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Credential", valid_603112
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603114: Call_DeleteConfigRule_603102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified AWS Config rule and all of its evaluation results.</p> <p>AWS Config sets the state of a rule to <code>DELETING</code> until the deletion is complete. You cannot update a rule while it is in this state. If you make a <code>PutConfigRule</code> or <code>DeleteConfigRule</code> request for the rule, you will receive a <code>ResourceInUseException</code>.</p> <p>You can check the state of a rule by using the <code>DescribeConfigRules</code> request.</p>
  ## 
  let valid = call_603114.validator(path, query, header, formData, body)
  let scheme = call_603114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603114.url(scheme.get, call_603114.host, call_603114.base,
                         call_603114.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603114, url, valid)

proc call*(call_603115: Call_DeleteConfigRule_603102; body: JsonNode): Recallable =
  ## deleteConfigRule
  ## <p>Deletes the specified AWS Config rule and all of its evaluation results.</p> <p>AWS Config sets the state of a rule to <code>DELETING</code> until the deletion is complete. You cannot update a rule while it is in this state. If you make a <code>PutConfigRule</code> or <code>DeleteConfigRule</code> request for the rule, you will receive a <code>ResourceInUseException</code>.</p> <p>You can check the state of a rule by using the <code>DescribeConfigRules</code> request.</p>
  ##   body: JObject (required)
  var body_603116 = newJObject()
  if body != nil:
    body_603116 = body
  result = call_603115.call(nil, nil, nil, nil, body_603116)

var deleteConfigRule* = Call_DeleteConfigRule_603102(name: "deleteConfigRule",
    meth: HttpMethod.HttpPost, host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteConfigRule",
    validator: validate_DeleteConfigRule_603103, base: "/",
    url: url_DeleteConfigRule_603104, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationAggregator_603117 = ref object of OpenApiRestCall_602466
proc url_DeleteConfigurationAggregator_603119(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteConfigurationAggregator_603118(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the specified configuration aggregator and the aggregated data associated with the aggregator.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603120 = header.getOrDefault("X-Amz-Date")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "X-Amz-Date", valid_603120
  var valid_603121 = header.getOrDefault("X-Amz-Security-Token")
  valid_603121 = validateParameter(valid_603121, JString, required = false,
                                 default = nil)
  if valid_603121 != nil:
    section.add "X-Amz-Security-Token", valid_603121
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603122 = header.getOrDefault("X-Amz-Target")
  valid_603122 = validateParameter(valid_603122, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteConfigurationAggregator"))
  if valid_603122 != nil:
    section.add "X-Amz-Target", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Content-Sha256", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Algorithm")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Algorithm", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Signature")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Signature", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-SignedHeaders", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Credential")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Credential", valid_603127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603129: Call_DeleteConfigurationAggregator_603117; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the specified configuration aggregator and the aggregated data associated with the aggregator.
  ## 
  let valid = call_603129.validator(path, query, header, formData, body)
  let scheme = call_603129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603129.url(scheme.get, call_603129.host, call_603129.base,
                         call_603129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603129, url, valid)

proc call*(call_603130: Call_DeleteConfigurationAggregator_603117; body: JsonNode): Recallable =
  ## deleteConfigurationAggregator
  ## Deletes the specified configuration aggregator and the aggregated data associated with the aggregator.
  ##   body: JObject (required)
  var body_603131 = newJObject()
  if body != nil:
    body_603131 = body
  result = call_603130.call(nil, nil, nil, nil, body_603131)

var deleteConfigurationAggregator* = Call_DeleteConfigurationAggregator_603117(
    name: "deleteConfigurationAggregator", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteConfigurationAggregator",
    validator: validate_DeleteConfigurationAggregator_603118, base: "/",
    url: url_DeleteConfigurationAggregator_603119,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfigurationRecorder_603132 = ref object of OpenApiRestCall_602466
proc url_DeleteConfigurationRecorder_603134(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteConfigurationRecorder_603133(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the configuration recorder.</p> <p>After the configuration recorder is deleted, AWS Config will not record resource configuration changes until you create a new configuration recorder.</p> <p>This action does not delete the configuration information that was previously recorded. You will be able to access the previously recorded information by using the <code>GetResourceConfigHistory</code> action, but you will not be able to access this information in the AWS Config console until you create a new configuration recorder.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603135 = header.getOrDefault("X-Amz-Date")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Date", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Security-Token")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Security-Token", valid_603136
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603137 = header.getOrDefault("X-Amz-Target")
  valid_603137 = validateParameter(valid_603137, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteConfigurationRecorder"))
  if valid_603137 != nil:
    section.add "X-Amz-Target", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Content-Sha256", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Algorithm")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Algorithm", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Signature")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Signature", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-SignedHeaders", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-Credential")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Credential", valid_603142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603144: Call_DeleteConfigurationRecorder_603132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the configuration recorder.</p> <p>After the configuration recorder is deleted, AWS Config will not record resource configuration changes until you create a new configuration recorder.</p> <p>This action does not delete the configuration information that was previously recorded. You will be able to access the previously recorded information by using the <code>GetResourceConfigHistory</code> action, but you will not be able to access this information in the AWS Config console until you create a new configuration recorder.</p>
  ## 
  let valid = call_603144.validator(path, query, header, formData, body)
  let scheme = call_603144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603144.url(scheme.get, call_603144.host, call_603144.base,
                         call_603144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603144, url, valid)

proc call*(call_603145: Call_DeleteConfigurationRecorder_603132; body: JsonNode): Recallable =
  ## deleteConfigurationRecorder
  ## <p>Deletes the configuration recorder.</p> <p>After the configuration recorder is deleted, AWS Config will not record resource configuration changes until you create a new configuration recorder.</p> <p>This action does not delete the configuration information that was previously recorded. You will be able to access the previously recorded information by using the <code>GetResourceConfigHistory</code> action, but you will not be able to access this information in the AWS Config console until you create a new configuration recorder.</p>
  ##   body: JObject (required)
  var body_603146 = newJObject()
  if body != nil:
    body_603146 = body
  result = call_603145.call(nil, nil, nil, nil, body_603146)

var deleteConfigurationRecorder* = Call_DeleteConfigurationRecorder_603132(
    name: "deleteConfigurationRecorder", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteConfigurationRecorder",
    validator: validate_DeleteConfigurationRecorder_603133, base: "/",
    url: url_DeleteConfigurationRecorder_603134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeliveryChannel_603147 = ref object of OpenApiRestCall_602466
proc url_DeleteDeliveryChannel_603149(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteDeliveryChannel_603148(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the delivery channel.</p> <p>Before you can delete the delivery channel, you must stop the configuration recorder by using the <a>StopConfigurationRecorder</a> action.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603150 = header.getOrDefault("X-Amz-Date")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Date", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Security-Token")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Security-Token", valid_603151
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603152 = header.getOrDefault("X-Amz-Target")
  valid_603152 = validateParameter(valid_603152, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteDeliveryChannel"))
  if valid_603152 != nil:
    section.add "X-Amz-Target", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Content-Sha256", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-Algorithm")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-Algorithm", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Signature")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Signature", valid_603155
  var valid_603156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603156 = validateParameter(valid_603156, JString, required = false,
                                 default = nil)
  if valid_603156 != nil:
    section.add "X-Amz-SignedHeaders", valid_603156
  var valid_603157 = header.getOrDefault("X-Amz-Credential")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "X-Amz-Credential", valid_603157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603159: Call_DeleteDeliveryChannel_603147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the delivery channel.</p> <p>Before you can delete the delivery channel, you must stop the configuration recorder by using the <a>StopConfigurationRecorder</a> action.</p>
  ## 
  let valid = call_603159.validator(path, query, header, formData, body)
  let scheme = call_603159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603159.url(scheme.get, call_603159.host, call_603159.base,
                         call_603159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603159, url, valid)

proc call*(call_603160: Call_DeleteDeliveryChannel_603147; body: JsonNode): Recallable =
  ## deleteDeliveryChannel
  ## <p>Deletes the delivery channel.</p> <p>Before you can delete the delivery channel, you must stop the configuration recorder by using the <a>StopConfigurationRecorder</a> action.</p>
  ##   body: JObject (required)
  var body_603161 = newJObject()
  if body != nil:
    body_603161 = body
  result = call_603160.call(nil, nil, nil, nil, body_603161)

var deleteDeliveryChannel* = Call_DeleteDeliveryChannel_603147(
    name: "deleteDeliveryChannel", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteDeliveryChannel",
    validator: validate_DeleteDeliveryChannel_603148, base: "/",
    url: url_DeleteDeliveryChannel_603149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteEvaluationResults_603162 = ref object of OpenApiRestCall_602466
proc url_DeleteEvaluationResults_603164(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteEvaluationResults_603163(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the evaluation results for the specified AWS Config rule. You can specify one AWS Config rule per request. After you delete the evaluation results, you can call the <a>StartConfigRulesEvaluation</a> API to start evaluating your AWS resources against the rule.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603165 = header.getOrDefault("X-Amz-Date")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Date", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Security-Token")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Security-Token", valid_603166
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603167 = header.getOrDefault("X-Amz-Target")
  valid_603167 = validateParameter(valid_603167, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteEvaluationResults"))
  if valid_603167 != nil:
    section.add "X-Amz-Target", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Content-Sha256", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Algorithm")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Algorithm", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Signature")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Signature", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-SignedHeaders", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-Credential")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-Credential", valid_603172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603174: Call_DeleteEvaluationResults_603162; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the evaluation results for the specified AWS Config rule. You can specify one AWS Config rule per request. After you delete the evaluation results, you can call the <a>StartConfigRulesEvaluation</a> API to start evaluating your AWS resources against the rule.
  ## 
  let valid = call_603174.validator(path, query, header, formData, body)
  let scheme = call_603174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603174.url(scheme.get, call_603174.host, call_603174.base,
                         call_603174.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603174, url, valid)

proc call*(call_603175: Call_DeleteEvaluationResults_603162; body: JsonNode): Recallable =
  ## deleteEvaluationResults
  ## Deletes the evaluation results for the specified AWS Config rule. You can specify one AWS Config rule per request. After you delete the evaluation results, you can call the <a>StartConfigRulesEvaluation</a> API to start evaluating your AWS resources against the rule.
  ##   body: JObject (required)
  var body_603176 = newJObject()
  if body != nil:
    body_603176 = body
  result = call_603175.call(nil, nil, nil, nil, body_603176)

var deleteEvaluationResults* = Call_DeleteEvaluationResults_603162(
    name: "deleteEvaluationResults", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteEvaluationResults",
    validator: validate_DeleteEvaluationResults_603163, base: "/",
    url: url_DeleteEvaluationResults_603164, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteOrganizationConfigRule_603177 = ref object of OpenApiRestCall_602466
proc url_DeleteOrganizationConfigRule_603179(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteOrganizationConfigRule_603178(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the specified organization config rule and all of its evaluation results from all member accounts in that organization. Only a master account can delete an organization config rule.</p> <p>AWS Config sets the state of a rule to DELETE_IN_PROGRESS until the deletion is complete. You cannot update a rule while it is in this state.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603180 = header.getOrDefault("X-Amz-Date")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Date", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Security-Token")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Security-Token", valid_603181
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603182 = header.getOrDefault("X-Amz-Target")
  valid_603182 = validateParameter(valid_603182, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteOrganizationConfigRule"))
  if valid_603182 != nil:
    section.add "X-Amz-Target", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Content-Sha256", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Algorithm")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Algorithm", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Signature")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Signature", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-SignedHeaders", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Credential")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Credential", valid_603187
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603189: Call_DeleteOrganizationConfigRule_603177; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the specified organization config rule and all of its evaluation results from all member accounts in that organization. Only a master account can delete an organization config rule.</p> <p>AWS Config sets the state of a rule to DELETE_IN_PROGRESS until the deletion is complete. You cannot update a rule while it is in this state.</p>
  ## 
  let valid = call_603189.validator(path, query, header, formData, body)
  let scheme = call_603189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603189.url(scheme.get, call_603189.host, call_603189.base,
                         call_603189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603189, url, valid)

proc call*(call_603190: Call_DeleteOrganizationConfigRule_603177; body: JsonNode): Recallable =
  ## deleteOrganizationConfigRule
  ## <p>Deletes the specified organization config rule and all of its evaluation results from all member accounts in that organization. Only a master account can delete an organization config rule.</p> <p>AWS Config sets the state of a rule to DELETE_IN_PROGRESS until the deletion is complete. You cannot update a rule while it is in this state.</p>
  ##   body: JObject (required)
  var body_603191 = newJObject()
  if body != nil:
    body_603191 = body
  result = call_603190.call(nil, nil, nil, nil, body_603191)

var deleteOrganizationConfigRule* = Call_DeleteOrganizationConfigRule_603177(
    name: "deleteOrganizationConfigRule", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteOrganizationConfigRule",
    validator: validate_DeleteOrganizationConfigRule_603178, base: "/",
    url: url_DeleteOrganizationConfigRule_603179,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePendingAggregationRequest_603192 = ref object of OpenApiRestCall_602466
proc url_DeletePendingAggregationRequest_603194(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeletePendingAggregationRequest_603193(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes pending authorization requests for a specified aggregator account in a specified region.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603195 = header.getOrDefault("X-Amz-Date")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Date", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Security-Token")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Security-Token", valid_603196
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603197 = header.getOrDefault("X-Amz-Target")
  valid_603197 = validateParameter(valid_603197, JString, required = true, default = newJString(
      "StarlingDoveService.DeletePendingAggregationRequest"))
  if valid_603197 != nil:
    section.add "X-Amz-Target", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Content-Sha256", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Algorithm")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Algorithm", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Signature")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Signature", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-SignedHeaders", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Credential")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Credential", valid_603202
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603204: Call_DeletePendingAggregationRequest_603192;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Deletes pending authorization requests for a specified aggregator account in a specified region.
  ## 
  let valid = call_603204.validator(path, query, header, formData, body)
  let scheme = call_603204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603204.url(scheme.get, call_603204.host, call_603204.base,
                         call_603204.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603204, url, valid)

proc call*(call_603205: Call_DeletePendingAggregationRequest_603192; body: JsonNode): Recallable =
  ## deletePendingAggregationRequest
  ## Deletes pending authorization requests for a specified aggregator account in a specified region.
  ##   body: JObject (required)
  var body_603206 = newJObject()
  if body != nil:
    body_603206 = body
  result = call_603205.call(nil, nil, nil, nil, body_603206)

var deletePendingAggregationRequest* = Call_DeletePendingAggregationRequest_603192(
    name: "deletePendingAggregationRequest", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DeletePendingAggregationRequest",
    validator: validate_DeletePendingAggregationRequest_603193, base: "/",
    url: url_DeletePendingAggregationRequest_603194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRemediationConfiguration_603207 = ref object of OpenApiRestCall_602466
proc url_DeleteRemediationConfiguration_603209(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRemediationConfiguration_603208(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the remediation configuration.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603210 = header.getOrDefault("X-Amz-Date")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-Date", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Security-Token")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Security-Token", valid_603211
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603212 = header.getOrDefault("X-Amz-Target")
  valid_603212 = validateParameter(valid_603212, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteRemediationConfiguration"))
  if valid_603212 != nil:
    section.add "X-Amz-Target", valid_603212
  var valid_603213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "X-Amz-Content-Sha256", valid_603213
  var valid_603214 = header.getOrDefault("X-Amz-Algorithm")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "X-Amz-Algorithm", valid_603214
  var valid_603215 = header.getOrDefault("X-Amz-Signature")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Signature", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-SignedHeaders", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Credential")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Credential", valid_603217
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603219: Call_DeleteRemediationConfiguration_603207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the remediation configuration.
  ## 
  let valid = call_603219.validator(path, query, header, formData, body)
  let scheme = call_603219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603219.url(scheme.get, call_603219.host, call_603219.base,
                         call_603219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603219, url, valid)

proc call*(call_603220: Call_DeleteRemediationConfiguration_603207; body: JsonNode): Recallable =
  ## deleteRemediationConfiguration
  ## Deletes the remediation configuration.
  ##   body: JObject (required)
  var body_603221 = newJObject()
  if body != nil:
    body_603221 = body
  result = call_603220.call(nil, nil, nil, nil, body_603221)

var deleteRemediationConfiguration* = Call_DeleteRemediationConfiguration_603207(
    name: "deleteRemediationConfiguration", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteRemediationConfiguration",
    validator: validate_DeleteRemediationConfiguration_603208, base: "/",
    url: url_DeleteRemediationConfiguration_603209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRemediationExceptions_603222 = ref object of OpenApiRestCall_602466
proc url_DeleteRemediationExceptions_603224(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRemediationExceptions_603223(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes one or more remediation exceptions mentioned in the resource keys.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603225 = header.getOrDefault("X-Amz-Date")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-Date", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Security-Token")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Security-Token", valid_603226
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603227 = header.getOrDefault("X-Amz-Target")
  valid_603227 = validateParameter(valid_603227, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteRemediationExceptions"))
  if valid_603227 != nil:
    section.add "X-Amz-Target", valid_603227
  var valid_603228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "X-Amz-Content-Sha256", valid_603228
  var valid_603229 = header.getOrDefault("X-Amz-Algorithm")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "X-Amz-Algorithm", valid_603229
  var valid_603230 = header.getOrDefault("X-Amz-Signature")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Signature", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-SignedHeaders", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Credential")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Credential", valid_603232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603234: Call_DeleteRemediationExceptions_603222; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes one or more remediation exceptions mentioned in the resource keys.
  ## 
  let valid = call_603234.validator(path, query, header, formData, body)
  let scheme = call_603234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603234.url(scheme.get, call_603234.host, call_603234.base,
                         call_603234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603234, url, valid)

proc call*(call_603235: Call_DeleteRemediationExceptions_603222; body: JsonNode): Recallable =
  ## deleteRemediationExceptions
  ## Deletes one or more remediation exceptions mentioned in the resource keys.
  ##   body: JObject (required)
  var body_603236 = newJObject()
  if body != nil:
    body_603236 = body
  result = call_603235.call(nil, nil, nil, nil, body_603236)

var deleteRemediationExceptions* = Call_DeleteRemediationExceptions_603222(
    name: "deleteRemediationExceptions", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteRemediationExceptions",
    validator: validate_DeleteRemediationExceptions_603223, base: "/",
    url: url_DeleteRemediationExceptions_603224,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRetentionConfiguration_603237 = ref object of OpenApiRestCall_602466
proc url_DeleteRetentionConfiguration_603239(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRetentionConfiguration_603238(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the retention configuration.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603240 = header.getOrDefault("X-Amz-Date")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Date", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Security-Token")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Security-Token", valid_603241
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603242 = header.getOrDefault("X-Amz-Target")
  valid_603242 = validateParameter(valid_603242, JString, required = true, default = newJString(
      "StarlingDoveService.DeleteRetentionConfiguration"))
  if valid_603242 != nil:
    section.add "X-Amz-Target", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-Content-Sha256", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Algorithm")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Algorithm", valid_603244
  var valid_603245 = header.getOrDefault("X-Amz-Signature")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "X-Amz-Signature", valid_603245
  var valid_603246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "X-Amz-SignedHeaders", valid_603246
  var valid_603247 = header.getOrDefault("X-Amz-Credential")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "X-Amz-Credential", valid_603247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603249: Call_DeleteRetentionConfiguration_603237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the retention configuration.
  ## 
  let valid = call_603249.validator(path, query, header, formData, body)
  let scheme = call_603249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603249.url(scheme.get, call_603249.host, call_603249.base,
                         call_603249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603249, url, valid)

proc call*(call_603250: Call_DeleteRetentionConfiguration_603237; body: JsonNode): Recallable =
  ## deleteRetentionConfiguration
  ## Deletes the retention configuration.
  ##   body: JObject (required)
  var body_603251 = newJObject()
  if body != nil:
    body_603251 = body
  result = call_603250.call(nil, nil, nil, nil, body_603251)

var deleteRetentionConfiguration* = Call_DeleteRetentionConfiguration_603237(
    name: "deleteRetentionConfiguration", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeleteRetentionConfiguration",
    validator: validate_DeleteRetentionConfiguration_603238, base: "/",
    url: url_DeleteRetentionConfiguration_603239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeliverConfigSnapshot_603252 = ref object of OpenApiRestCall_602466
proc url_DeliverConfigSnapshot_603254(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeliverConfigSnapshot_603253(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Schedules delivery of a configuration snapshot to the Amazon S3 bucket in the specified delivery channel. After the delivery has started, AWS Config sends the following notifications using an Amazon SNS topic that you have specified.</p> <ul> <li> <p>Notification of the start of the delivery.</p> </li> <li> <p>Notification of the completion of the delivery, if the delivery was successfully completed.</p> </li> <li> <p>Notification of delivery failure, if the delivery failed.</p> </li> </ul>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603255 = header.getOrDefault("X-Amz-Date")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Date", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Security-Token")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Security-Token", valid_603256
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603257 = header.getOrDefault("X-Amz-Target")
  valid_603257 = validateParameter(valid_603257, JString, required = true, default = newJString(
      "StarlingDoveService.DeliverConfigSnapshot"))
  if valid_603257 != nil:
    section.add "X-Amz-Target", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Content-Sha256", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Algorithm")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Algorithm", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Signature")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Signature", valid_603260
  var valid_603261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "X-Amz-SignedHeaders", valid_603261
  var valid_603262 = header.getOrDefault("X-Amz-Credential")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "X-Amz-Credential", valid_603262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603264: Call_DeliverConfigSnapshot_603252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Schedules delivery of a configuration snapshot to the Amazon S3 bucket in the specified delivery channel. After the delivery has started, AWS Config sends the following notifications using an Amazon SNS topic that you have specified.</p> <ul> <li> <p>Notification of the start of the delivery.</p> </li> <li> <p>Notification of the completion of the delivery, if the delivery was successfully completed.</p> </li> <li> <p>Notification of delivery failure, if the delivery failed.</p> </li> </ul>
  ## 
  let valid = call_603264.validator(path, query, header, formData, body)
  let scheme = call_603264.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603264.url(scheme.get, call_603264.host, call_603264.base,
                         call_603264.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603264, url, valid)

proc call*(call_603265: Call_DeliverConfigSnapshot_603252; body: JsonNode): Recallable =
  ## deliverConfigSnapshot
  ## <p>Schedules delivery of a configuration snapshot to the Amazon S3 bucket in the specified delivery channel. After the delivery has started, AWS Config sends the following notifications using an Amazon SNS topic that you have specified.</p> <ul> <li> <p>Notification of the start of the delivery.</p> </li> <li> <p>Notification of the completion of the delivery, if the delivery was successfully completed.</p> </li> <li> <p>Notification of delivery failure, if the delivery failed.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603266 = newJObject()
  if body != nil:
    body_603266 = body
  result = call_603265.call(nil, nil, nil, nil, body_603266)

var deliverConfigSnapshot* = Call_DeliverConfigSnapshot_603252(
    name: "deliverConfigSnapshot", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DeliverConfigSnapshot",
    validator: validate_DeliverConfigSnapshot_603253, base: "/",
    url: url_DeliverConfigSnapshot_603254, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAggregateComplianceByConfigRules_603267 = ref object of OpenApiRestCall_602466
proc url_DescribeAggregateComplianceByConfigRules_603269(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAggregateComplianceByConfigRules_603268(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of compliant and noncompliant rules with the number of resources for compliant and noncompliant rules. </p> <note> <p>The results can return an empty result page, but if you have a <code>nextToken</code>, the results are displayed on the next page.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603270 = header.getOrDefault("X-Amz-Date")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Date", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Security-Token")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Security-Token", valid_603271
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603272 = header.getOrDefault("X-Amz-Target")
  valid_603272 = validateParameter(valid_603272, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeAggregateComplianceByConfigRules"))
  if valid_603272 != nil:
    section.add "X-Amz-Target", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Content-Sha256", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Algorithm")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Algorithm", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Signature")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Signature", valid_603275
  var valid_603276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "X-Amz-SignedHeaders", valid_603276
  var valid_603277 = header.getOrDefault("X-Amz-Credential")
  valid_603277 = validateParameter(valid_603277, JString, required = false,
                                 default = nil)
  if valid_603277 != nil:
    section.add "X-Amz-Credential", valid_603277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603279: Call_DescribeAggregateComplianceByConfigRules_603267;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of compliant and noncompliant rules with the number of resources for compliant and noncompliant rules. </p> <note> <p>The results can return an empty result page, but if you have a <code>nextToken</code>, the results are displayed on the next page.</p> </note>
  ## 
  let valid = call_603279.validator(path, query, header, formData, body)
  let scheme = call_603279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603279.url(scheme.get, call_603279.host, call_603279.base,
                         call_603279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603279, url, valid)

proc call*(call_603280: Call_DescribeAggregateComplianceByConfigRules_603267;
          body: JsonNode): Recallable =
  ## describeAggregateComplianceByConfigRules
  ## <p>Returns a list of compliant and noncompliant rules with the number of resources for compliant and noncompliant rules. </p> <note> <p>The results can return an empty result page, but if you have a <code>nextToken</code>, the results are displayed on the next page.</p> </note>
  ##   body: JObject (required)
  var body_603281 = newJObject()
  if body != nil:
    body_603281 = body
  result = call_603280.call(nil, nil, nil, nil, body_603281)

var describeAggregateComplianceByConfigRules* = Call_DescribeAggregateComplianceByConfigRules_603267(
    name: "describeAggregateComplianceByConfigRules", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeAggregateComplianceByConfigRules",
    validator: validate_DescribeAggregateComplianceByConfigRules_603268,
    base: "/", url: url_DescribeAggregateComplianceByConfigRules_603269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAggregationAuthorizations_603282 = ref object of OpenApiRestCall_602466
proc url_DescribeAggregationAuthorizations_603284(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeAggregationAuthorizations_603283(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of authorizations granted to various aggregator accounts and regions.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603285 = header.getOrDefault("X-Amz-Date")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Date", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Security-Token")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Security-Token", valid_603286
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603287 = header.getOrDefault("X-Amz-Target")
  valid_603287 = validateParameter(valid_603287, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeAggregationAuthorizations"))
  if valid_603287 != nil:
    section.add "X-Amz-Target", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Content-Sha256", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Algorithm")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Algorithm", valid_603289
  var valid_603290 = header.getOrDefault("X-Amz-Signature")
  valid_603290 = validateParameter(valid_603290, JString, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "X-Amz-Signature", valid_603290
  var valid_603291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-SignedHeaders", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Credential")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Credential", valid_603292
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603294: Call_DescribeAggregationAuthorizations_603282;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of authorizations granted to various aggregator accounts and regions.
  ## 
  let valid = call_603294.validator(path, query, header, formData, body)
  let scheme = call_603294.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603294.url(scheme.get, call_603294.host, call_603294.base,
                         call_603294.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603294, url, valid)

proc call*(call_603295: Call_DescribeAggregationAuthorizations_603282;
          body: JsonNode): Recallable =
  ## describeAggregationAuthorizations
  ## Returns a list of authorizations granted to various aggregator accounts and regions.
  ##   body: JObject (required)
  var body_603296 = newJObject()
  if body != nil:
    body_603296 = body
  result = call_603295.call(nil, nil, nil, nil, body_603296)

var describeAggregationAuthorizations* = Call_DescribeAggregationAuthorizations_603282(
    name: "describeAggregationAuthorizations", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeAggregationAuthorizations",
    validator: validate_DescribeAggregationAuthorizations_603283, base: "/",
    url: url_DescribeAggregationAuthorizations_603284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComplianceByConfigRule_603297 = ref object of OpenApiRestCall_602466
proc url_DescribeComplianceByConfigRule_603299(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeComplianceByConfigRule_603298(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Indicates whether the specified AWS Config rules are compliant. If a rule is noncompliant, this action returns the number of AWS resources that do not comply with the rule.</p> <p>A rule is compliant if all of the evaluated resources comply with it. It is noncompliant if any of these resources do not comply.</p> <p>If AWS Config has no current evaluation results for the rule, it returns <code>INSUFFICIENT_DATA</code>. This result might indicate one of the following conditions:</p> <ul> <li> <p>AWS Config has never invoked an evaluation for the rule. To check whether it has, use the <code>DescribeConfigRuleEvaluationStatus</code> action to get the <code>LastSuccessfulInvocationTime</code> and <code>LastFailedInvocationTime</code>.</p> </li> <li> <p>The rule's AWS Lambda function is failing to send evaluation results to AWS Config. Verify that the role you assigned to your configuration recorder includes the <code>config:PutEvaluations</code> permission. If the rule is a custom rule, verify that the AWS Lambda execution role includes the <code>config:PutEvaluations</code> permission.</p> </li> <li> <p>The rule's AWS Lambda function has returned <code>NOT_APPLICABLE</code> for all evaluation results. This can occur if the resources were deleted or removed from the rule's scope.</p> </li> </ul>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603300 = header.getOrDefault("X-Amz-Date")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Date", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Security-Token")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Security-Token", valid_603301
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603302 = header.getOrDefault("X-Amz-Target")
  valid_603302 = validateParameter(valid_603302, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeComplianceByConfigRule"))
  if valid_603302 != nil:
    section.add "X-Amz-Target", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-Content-Sha256", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Algorithm")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Algorithm", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-Signature")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-Signature", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-SignedHeaders", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-Credential")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Credential", valid_603307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603309: Call_DescribeComplianceByConfigRule_603297; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Indicates whether the specified AWS Config rules are compliant. If a rule is noncompliant, this action returns the number of AWS resources that do not comply with the rule.</p> <p>A rule is compliant if all of the evaluated resources comply with it. It is noncompliant if any of these resources do not comply.</p> <p>If AWS Config has no current evaluation results for the rule, it returns <code>INSUFFICIENT_DATA</code>. This result might indicate one of the following conditions:</p> <ul> <li> <p>AWS Config has never invoked an evaluation for the rule. To check whether it has, use the <code>DescribeConfigRuleEvaluationStatus</code> action to get the <code>LastSuccessfulInvocationTime</code> and <code>LastFailedInvocationTime</code>.</p> </li> <li> <p>The rule's AWS Lambda function is failing to send evaluation results to AWS Config. Verify that the role you assigned to your configuration recorder includes the <code>config:PutEvaluations</code> permission. If the rule is a custom rule, verify that the AWS Lambda execution role includes the <code>config:PutEvaluations</code> permission.</p> </li> <li> <p>The rule's AWS Lambda function has returned <code>NOT_APPLICABLE</code> for all evaluation results. This can occur if the resources were deleted or removed from the rule's scope.</p> </li> </ul>
  ## 
  let valid = call_603309.validator(path, query, header, formData, body)
  let scheme = call_603309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603309.url(scheme.get, call_603309.host, call_603309.base,
                         call_603309.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603309, url, valid)

proc call*(call_603310: Call_DescribeComplianceByConfigRule_603297; body: JsonNode): Recallable =
  ## describeComplianceByConfigRule
  ## <p>Indicates whether the specified AWS Config rules are compliant. If a rule is noncompliant, this action returns the number of AWS resources that do not comply with the rule.</p> <p>A rule is compliant if all of the evaluated resources comply with it. It is noncompliant if any of these resources do not comply.</p> <p>If AWS Config has no current evaluation results for the rule, it returns <code>INSUFFICIENT_DATA</code>. This result might indicate one of the following conditions:</p> <ul> <li> <p>AWS Config has never invoked an evaluation for the rule. To check whether it has, use the <code>DescribeConfigRuleEvaluationStatus</code> action to get the <code>LastSuccessfulInvocationTime</code> and <code>LastFailedInvocationTime</code>.</p> </li> <li> <p>The rule's AWS Lambda function is failing to send evaluation results to AWS Config. Verify that the role you assigned to your configuration recorder includes the <code>config:PutEvaluations</code> permission. If the rule is a custom rule, verify that the AWS Lambda execution role includes the <code>config:PutEvaluations</code> permission.</p> </li> <li> <p>The rule's AWS Lambda function has returned <code>NOT_APPLICABLE</code> for all evaluation results. This can occur if the resources were deleted or removed from the rule's scope.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603311 = newJObject()
  if body != nil:
    body_603311 = body
  result = call_603310.call(nil, nil, nil, nil, body_603311)

var describeComplianceByConfigRule* = Call_DescribeComplianceByConfigRule_603297(
    name: "describeComplianceByConfigRule", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DescribeComplianceByConfigRule",
    validator: validate_DescribeComplianceByConfigRule_603298, base: "/",
    url: url_DescribeComplianceByConfigRule_603299,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeComplianceByResource_603312 = ref object of OpenApiRestCall_602466
proc url_DescribeComplianceByResource_603314(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeComplianceByResource_603313(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Indicates whether the specified AWS resources are compliant. If a resource is noncompliant, this action returns the number of AWS Config rules that the resource does not comply with.</p> <p>A resource is compliant if it complies with all the AWS Config rules that evaluate it. It is noncompliant if it does not comply with one or more of these rules.</p> <p>If AWS Config has no current evaluation results for the resource, it returns <code>INSUFFICIENT_DATA</code>. This result might indicate one of the following conditions about the rules that evaluate the resource:</p> <ul> <li> <p>AWS Config has never invoked an evaluation for the rule. To check whether it has, use the <code>DescribeConfigRuleEvaluationStatus</code> action to get the <code>LastSuccessfulInvocationTime</code> and <code>LastFailedInvocationTime</code>.</p> </li> <li> <p>The rule's AWS Lambda function is failing to send evaluation results to AWS Config. Verify that the role that you assigned to your configuration recorder includes the <code>config:PutEvaluations</code> permission. If the rule is a custom rule, verify that the AWS Lambda execution role includes the <code>config:PutEvaluations</code> permission.</p> </li> <li> <p>The rule's AWS Lambda function has returned <code>NOT_APPLICABLE</code> for all evaluation results. This can occur if the resources were deleted or removed from the rule's scope.</p> </li> </ul>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603315 = header.getOrDefault("X-Amz-Date")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Date", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-Security-Token")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Security-Token", valid_603316
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603317 = header.getOrDefault("X-Amz-Target")
  valid_603317 = validateParameter(valid_603317, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeComplianceByResource"))
  if valid_603317 != nil:
    section.add "X-Amz-Target", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Content-Sha256", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Algorithm")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Algorithm", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-Signature")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-Signature", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-SignedHeaders", valid_603321
  var valid_603322 = header.getOrDefault("X-Amz-Credential")
  valid_603322 = validateParameter(valid_603322, JString, required = false,
                                 default = nil)
  if valid_603322 != nil:
    section.add "X-Amz-Credential", valid_603322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603324: Call_DescribeComplianceByResource_603312; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Indicates whether the specified AWS resources are compliant. If a resource is noncompliant, this action returns the number of AWS Config rules that the resource does not comply with.</p> <p>A resource is compliant if it complies with all the AWS Config rules that evaluate it. It is noncompliant if it does not comply with one or more of these rules.</p> <p>If AWS Config has no current evaluation results for the resource, it returns <code>INSUFFICIENT_DATA</code>. This result might indicate one of the following conditions about the rules that evaluate the resource:</p> <ul> <li> <p>AWS Config has never invoked an evaluation for the rule. To check whether it has, use the <code>DescribeConfigRuleEvaluationStatus</code> action to get the <code>LastSuccessfulInvocationTime</code> and <code>LastFailedInvocationTime</code>.</p> </li> <li> <p>The rule's AWS Lambda function is failing to send evaluation results to AWS Config. Verify that the role that you assigned to your configuration recorder includes the <code>config:PutEvaluations</code> permission. If the rule is a custom rule, verify that the AWS Lambda execution role includes the <code>config:PutEvaluations</code> permission.</p> </li> <li> <p>The rule's AWS Lambda function has returned <code>NOT_APPLICABLE</code> for all evaluation results. This can occur if the resources were deleted or removed from the rule's scope.</p> </li> </ul>
  ## 
  let valid = call_603324.validator(path, query, header, formData, body)
  let scheme = call_603324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603324.url(scheme.get, call_603324.host, call_603324.base,
                         call_603324.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603324, url, valid)

proc call*(call_603325: Call_DescribeComplianceByResource_603312; body: JsonNode): Recallable =
  ## describeComplianceByResource
  ## <p>Indicates whether the specified AWS resources are compliant. If a resource is noncompliant, this action returns the number of AWS Config rules that the resource does not comply with.</p> <p>A resource is compliant if it complies with all the AWS Config rules that evaluate it. It is noncompliant if it does not comply with one or more of these rules.</p> <p>If AWS Config has no current evaluation results for the resource, it returns <code>INSUFFICIENT_DATA</code>. This result might indicate one of the following conditions about the rules that evaluate the resource:</p> <ul> <li> <p>AWS Config has never invoked an evaluation for the rule. To check whether it has, use the <code>DescribeConfigRuleEvaluationStatus</code> action to get the <code>LastSuccessfulInvocationTime</code> and <code>LastFailedInvocationTime</code>.</p> </li> <li> <p>The rule's AWS Lambda function is failing to send evaluation results to AWS Config. Verify that the role that you assigned to your configuration recorder includes the <code>config:PutEvaluations</code> permission. If the rule is a custom rule, verify that the AWS Lambda execution role includes the <code>config:PutEvaluations</code> permission.</p> </li> <li> <p>The rule's AWS Lambda function has returned <code>NOT_APPLICABLE</code> for all evaluation results. This can occur if the resources were deleted or removed from the rule's scope.</p> </li> </ul>
  ##   body: JObject (required)
  var body_603326 = newJObject()
  if body != nil:
    body_603326 = body
  result = call_603325.call(nil, nil, nil, nil, body_603326)

var describeComplianceByResource* = Call_DescribeComplianceByResource_603312(
    name: "describeComplianceByResource", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DescribeComplianceByResource",
    validator: validate_DescribeComplianceByResource_603313, base: "/",
    url: url_DescribeComplianceByResource_603314,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigRuleEvaluationStatus_603327 = ref object of OpenApiRestCall_602466
proc url_DescribeConfigRuleEvaluationStatus_603329(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeConfigRuleEvaluationStatus_603328(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns status information for each of your AWS managed Config rules. The status includes information such as the last time AWS Config invoked the rule, the last time AWS Config failed to invoke the rule, and the related error for the last failure.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603330 = header.getOrDefault("X-Amz-Date")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Date", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Security-Token")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Security-Token", valid_603331
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603332 = header.getOrDefault("X-Amz-Target")
  valid_603332 = validateParameter(valid_603332, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeConfigRuleEvaluationStatus"))
  if valid_603332 != nil:
    section.add "X-Amz-Target", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Content-Sha256", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Algorithm")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Algorithm", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-Signature")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-Signature", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-SignedHeaders", valid_603336
  var valid_603337 = header.getOrDefault("X-Amz-Credential")
  valid_603337 = validateParameter(valid_603337, JString, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "X-Amz-Credential", valid_603337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603339: Call_DescribeConfigRuleEvaluationStatus_603327;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns status information for each of your AWS managed Config rules. The status includes information such as the last time AWS Config invoked the rule, the last time AWS Config failed to invoke the rule, and the related error for the last failure.
  ## 
  let valid = call_603339.validator(path, query, header, formData, body)
  let scheme = call_603339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603339.url(scheme.get, call_603339.host, call_603339.base,
                         call_603339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603339, url, valid)

proc call*(call_603340: Call_DescribeConfigRuleEvaluationStatus_603327;
          body: JsonNode): Recallable =
  ## describeConfigRuleEvaluationStatus
  ## Returns status information for each of your AWS managed Config rules. The status includes information such as the last time AWS Config invoked the rule, the last time AWS Config failed to invoke the rule, and the related error for the last failure.
  ##   body: JObject (required)
  var body_603341 = newJObject()
  if body != nil:
    body_603341 = body
  result = call_603340.call(nil, nil, nil, nil, body_603341)

var describeConfigRuleEvaluationStatus* = Call_DescribeConfigRuleEvaluationStatus_603327(
    name: "describeConfigRuleEvaluationStatus", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeConfigRuleEvaluationStatus",
    validator: validate_DescribeConfigRuleEvaluationStatus_603328, base: "/",
    url: url_DescribeConfigRuleEvaluationStatus_603329,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigRules_603342 = ref object of OpenApiRestCall_602466
proc url_DescribeConfigRules_603344(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeConfigRules_603343(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns details about your AWS Config rules.
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
  ##   X-Amz-Target: JString (required)
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
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603347 = header.getOrDefault("X-Amz-Target")
  valid_603347 = validateParameter(valid_603347, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeConfigRules"))
  if valid_603347 != nil:
    section.add "X-Amz-Target", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-Content-Sha256", valid_603348
  var valid_603349 = header.getOrDefault("X-Amz-Algorithm")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Algorithm", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Signature")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Signature", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-SignedHeaders", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Credential")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Credential", valid_603352
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603354: Call_DescribeConfigRules_603342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns details about your AWS Config rules.
  ## 
  let valid = call_603354.validator(path, query, header, formData, body)
  let scheme = call_603354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603354.url(scheme.get, call_603354.host, call_603354.base,
                         call_603354.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603354, url, valid)

proc call*(call_603355: Call_DescribeConfigRules_603342; body: JsonNode): Recallable =
  ## describeConfigRules
  ## Returns details about your AWS Config rules.
  ##   body: JObject (required)
  var body_603356 = newJObject()
  if body != nil:
    body_603356 = body
  result = call_603355.call(nil, nil, nil, nil, body_603356)

var describeConfigRules* = Call_DescribeConfigRules_603342(
    name: "describeConfigRules", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DescribeConfigRules",
    validator: validate_DescribeConfigRules_603343, base: "/",
    url: url_DescribeConfigRules_603344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigurationAggregatorSourcesStatus_603357 = ref object of OpenApiRestCall_602466
proc url_DescribeConfigurationAggregatorSourcesStatus_603359(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeConfigurationAggregatorSourcesStatus_603358(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns status information for sources within an aggregator. The status includes information about the last time AWS Config verified authorization between the source account and an aggregator account. In case of a failure, the status contains the related error code or message. 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603360 = header.getOrDefault("X-Amz-Date")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Date", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Security-Token")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Security-Token", valid_603361
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603362 = header.getOrDefault("X-Amz-Target")
  valid_603362 = validateParameter(valid_603362, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeConfigurationAggregatorSourcesStatus"))
  if valid_603362 != nil:
    section.add "X-Amz-Target", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-Content-Sha256", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-Algorithm")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Algorithm", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Signature")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Signature", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-SignedHeaders", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-Credential")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-Credential", valid_603367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603369: Call_DescribeConfigurationAggregatorSourcesStatus_603357;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns status information for sources within an aggregator. The status includes information about the last time AWS Config verified authorization between the source account and an aggregator account. In case of a failure, the status contains the related error code or message. 
  ## 
  let valid = call_603369.validator(path, query, header, formData, body)
  let scheme = call_603369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603369.url(scheme.get, call_603369.host, call_603369.base,
                         call_603369.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603369, url, valid)

proc call*(call_603370: Call_DescribeConfigurationAggregatorSourcesStatus_603357;
          body: JsonNode): Recallable =
  ## describeConfigurationAggregatorSourcesStatus
  ## Returns status information for sources within an aggregator. The status includes information about the last time AWS Config verified authorization between the source account and an aggregator account. In case of a failure, the status contains the related error code or message. 
  ##   body: JObject (required)
  var body_603371 = newJObject()
  if body != nil:
    body_603371 = body
  result = call_603370.call(nil, nil, nil, nil, body_603371)

var describeConfigurationAggregatorSourcesStatus* = Call_DescribeConfigurationAggregatorSourcesStatus_603357(
    name: "describeConfigurationAggregatorSourcesStatus",
    meth: HttpMethod.HttpPost, host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeConfigurationAggregatorSourcesStatus",
    validator: validate_DescribeConfigurationAggregatorSourcesStatus_603358,
    base: "/", url: url_DescribeConfigurationAggregatorSourcesStatus_603359,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigurationAggregators_603372 = ref object of OpenApiRestCall_602466
proc url_DescribeConfigurationAggregators_603374(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeConfigurationAggregators_603373(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the details of one or more configuration aggregators. If the configuration aggregator is not specified, this action returns the details for all the configuration aggregators associated with the account. 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603375 = header.getOrDefault("X-Amz-Date")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Date", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Security-Token")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Security-Token", valid_603376
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603377 = header.getOrDefault("X-Amz-Target")
  valid_603377 = validateParameter(valid_603377, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeConfigurationAggregators"))
  if valid_603377 != nil:
    section.add "X-Amz-Target", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-Content-Sha256", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-Algorithm")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Algorithm", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-Signature")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-Signature", valid_603380
  var valid_603381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "X-Amz-SignedHeaders", valid_603381
  var valid_603382 = header.getOrDefault("X-Amz-Credential")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-Credential", valid_603382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603384: Call_DescribeConfigurationAggregators_603372;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the details of one or more configuration aggregators. If the configuration aggregator is not specified, this action returns the details for all the configuration aggregators associated with the account. 
  ## 
  let valid = call_603384.validator(path, query, header, formData, body)
  let scheme = call_603384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603384.url(scheme.get, call_603384.host, call_603384.base,
                         call_603384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603384, url, valid)

proc call*(call_603385: Call_DescribeConfigurationAggregators_603372;
          body: JsonNode): Recallable =
  ## describeConfigurationAggregators
  ## Returns the details of one or more configuration aggregators. If the configuration aggregator is not specified, this action returns the details for all the configuration aggregators associated with the account. 
  ##   body: JObject (required)
  var body_603386 = newJObject()
  if body != nil:
    body_603386 = body
  result = call_603385.call(nil, nil, nil, nil, body_603386)

var describeConfigurationAggregators* = Call_DescribeConfigurationAggregators_603372(
    name: "describeConfigurationAggregators", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeConfigurationAggregators",
    validator: validate_DescribeConfigurationAggregators_603373, base: "/",
    url: url_DescribeConfigurationAggregators_603374,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigurationRecorderStatus_603387 = ref object of OpenApiRestCall_602466
proc url_DescribeConfigurationRecorderStatus_603389(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeConfigurationRecorderStatus_603388(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the current status of the specified configuration recorder. If a configuration recorder is not specified, this action returns the status of all configuration recorders associated with the account.</p> <note> <p>Currently, you can specify only one configuration recorder per region in your account.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603390 = header.getOrDefault("X-Amz-Date")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Date", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-Security-Token")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Security-Token", valid_603391
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603392 = header.getOrDefault("X-Amz-Target")
  valid_603392 = validateParameter(valid_603392, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeConfigurationRecorderStatus"))
  if valid_603392 != nil:
    section.add "X-Amz-Target", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Content-Sha256", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-Algorithm")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-Algorithm", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-Signature")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Signature", valid_603395
  var valid_603396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-SignedHeaders", valid_603396
  var valid_603397 = header.getOrDefault("X-Amz-Credential")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-Credential", valid_603397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603399: Call_DescribeConfigurationRecorderStatus_603387;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns the current status of the specified configuration recorder. If a configuration recorder is not specified, this action returns the status of all configuration recorders associated with the account.</p> <note> <p>Currently, you can specify only one configuration recorder per region in your account.</p> </note>
  ## 
  let valid = call_603399.validator(path, query, header, formData, body)
  let scheme = call_603399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603399.url(scheme.get, call_603399.host, call_603399.base,
                         call_603399.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603399, url, valid)

proc call*(call_603400: Call_DescribeConfigurationRecorderStatus_603387;
          body: JsonNode): Recallable =
  ## describeConfigurationRecorderStatus
  ## <p>Returns the current status of the specified configuration recorder. If a configuration recorder is not specified, this action returns the status of all configuration recorders associated with the account.</p> <note> <p>Currently, you can specify only one configuration recorder per region in your account.</p> </note>
  ##   body: JObject (required)
  var body_603401 = newJObject()
  if body != nil:
    body_603401 = body
  result = call_603400.call(nil, nil, nil, nil, body_603401)

var describeConfigurationRecorderStatus* = Call_DescribeConfigurationRecorderStatus_603387(
    name: "describeConfigurationRecorderStatus", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeConfigurationRecorderStatus",
    validator: validate_DescribeConfigurationRecorderStatus_603388, base: "/",
    url: url_DescribeConfigurationRecorderStatus_603389,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeConfigurationRecorders_603402 = ref object of OpenApiRestCall_602466
proc url_DescribeConfigurationRecorders_603404(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeConfigurationRecorders_603403(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the details for the specified configuration recorders. If the configuration recorder is not specified, this action returns the details for all configuration recorders associated with the account.</p> <note> <p>Currently, you can specify only one configuration recorder per region in your account.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603405 = header.getOrDefault("X-Amz-Date")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "X-Amz-Date", valid_603405
  var valid_603406 = header.getOrDefault("X-Amz-Security-Token")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-Security-Token", valid_603406
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603407 = header.getOrDefault("X-Amz-Target")
  valid_603407 = validateParameter(valid_603407, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeConfigurationRecorders"))
  if valid_603407 != nil:
    section.add "X-Amz-Target", valid_603407
  var valid_603408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603408 = validateParameter(valid_603408, JString, required = false,
                                 default = nil)
  if valid_603408 != nil:
    section.add "X-Amz-Content-Sha256", valid_603408
  var valid_603409 = header.getOrDefault("X-Amz-Algorithm")
  valid_603409 = validateParameter(valid_603409, JString, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "X-Amz-Algorithm", valid_603409
  var valid_603410 = header.getOrDefault("X-Amz-Signature")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Signature", valid_603410
  var valid_603411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-SignedHeaders", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-Credential")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-Credential", valid_603412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603414: Call_DescribeConfigurationRecorders_603402; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the details for the specified configuration recorders. If the configuration recorder is not specified, this action returns the details for all configuration recorders associated with the account.</p> <note> <p>Currently, you can specify only one configuration recorder per region in your account.</p> </note>
  ## 
  let valid = call_603414.validator(path, query, header, formData, body)
  let scheme = call_603414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603414.url(scheme.get, call_603414.host, call_603414.base,
                         call_603414.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603414, url, valid)

proc call*(call_603415: Call_DescribeConfigurationRecorders_603402; body: JsonNode): Recallable =
  ## describeConfigurationRecorders
  ## <p>Returns the details for the specified configuration recorders. If the configuration recorder is not specified, this action returns the details for all configuration recorders associated with the account.</p> <note> <p>Currently, you can specify only one configuration recorder per region in your account.</p> </note>
  ##   body: JObject (required)
  var body_603416 = newJObject()
  if body != nil:
    body_603416 = body
  result = call_603415.call(nil, nil, nil, nil, body_603416)

var describeConfigurationRecorders* = Call_DescribeConfigurationRecorders_603402(
    name: "describeConfigurationRecorders", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DescribeConfigurationRecorders",
    validator: validate_DescribeConfigurationRecorders_603403, base: "/",
    url: url_DescribeConfigurationRecorders_603404,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDeliveryChannelStatus_603417 = ref object of OpenApiRestCall_602466
proc url_DescribeDeliveryChannelStatus_603419(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDeliveryChannelStatus_603418(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the current status of the specified delivery channel. If a delivery channel is not specified, this action returns the current status of all delivery channels associated with the account.</p> <note> <p>Currently, you can specify only one delivery channel per region in your account.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603420 = header.getOrDefault("X-Amz-Date")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "X-Amz-Date", valid_603420
  var valid_603421 = header.getOrDefault("X-Amz-Security-Token")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Security-Token", valid_603421
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603422 = header.getOrDefault("X-Amz-Target")
  valid_603422 = validateParameter(valid_603422, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeDeliveryChannelStatus"))
  if valid_603422 != nil:
    section.add "X-Amz-Target", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-Content-Sha256", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Algorithm")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Algorithm", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Signature")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Signature", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-SignedHeaders", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-Credential")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-Credential", valid_603427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603429: Call_DescribeDeliveryChannelStatus_603417; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the current status of the specified delivery channel. If a delivery channel is not specified, this action returns the current status of all delivery channels associated with the account.</p> <note> <p>Currently, you can specify only one delivery channel per region in your account.</p> </note>
  ## 
  let valid = call_603429.validator(path, query, header, formData, body)
  let scheme = call_603429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603429.url(scheme.get, call_603429.host, call_603429.base,
                         call_603429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603429, url, valid)

proc call*(call_603430: Call_DescribeDeliveryChannelStatus_603417; body: JsonNode): Recallable =
  ## describeDeliveryChannelStatus
  ## <p>Returns the current status of the specified delivery channel. If a delivery channel is not specified, this action returns the current status of all delivery channels associated with the account.</p> <note> <p>Currently, you can specify only one delivery channel per region in your account.</p> </note>
  ##   body: JObject (required)
  var body_603431 = newJObject()
  if body != nil:
    body_603431 = body
  result = call_603430.call(nil, nil, nil, nil, body_603431)

var describeDeliveryChannelStatus* = Call_DescribeDeliveryChannelStatus_603417(
    name: "describeDeliveryChannelStatus", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DescribeDeliveryChannelStatus",
    validator: validate_DescribeDeliveryChannelStatus_603418, base: "/",
    url: url_DescribeDeliveryChannelStatus_603419,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDeliveryChannels_603432 = ref object of OpenApiRestCall_602466
proc url_DescribeDeliveryChannels_603434(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDeliveryChannels_603433(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns details about the specified delivery channel. If a delivery channel is not specified, this action returns the details of all delivery channels associated with the account.</p> <note> <p>Currently, you can specify only one delivery channel per region in your account.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603435 = header.getOrDefault("X-Amz-Date")
  valid_603435 = validateParameter(valid_603435, JString, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "X-Amz-Date", valid_603435
  var valid_603436 = header.getOrDefault("X-Amz-Security-Token")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Security-Token", valid_603436
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603437 = header.getOrDefault("X-Amz-Target")
  valid_603437 = validateParameter(valid_603437, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeDeliveryChannels"))
  if valid_603437 != nil:
    section.add "X-Amz-Target", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Content-Sha256", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-Algorithm")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Algorithm", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Signature")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Signature", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-SignedHeaders", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-Credential")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Credential", valid_603442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603444: Call_DescribeDeliveryChannels_603432; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns details about the specified delivery channel. If a delivery channel is not specified, this action returns the details of all delivery channels associated with the account.</p> <note> <p>Currently, you can specify only one delivery channel per region in your account.</p> </note>
  ## 
  let valid = call_603444.validator(path, query, header, formData, body)
  let scheme = call_603444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603444.url(scheme.get, call_603444.host, call_603444.base,
                         call_603444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603444, url, valid)

proc call*(call_603445: Call_DescribeDeliveryChannels_603432; body: JsonNode): Recallable =
  ## describeDeliveryChannels
  ## <p>Returns details about the specified delivery channel. If a delivery channel is not specified, this action returns the details of all delivery channels associated with the account.</p> <note> <p>Currently, you can specify only one delivery channel per region in your account.</p> </note>
  ##   body: JObject (required)
  var body_603446 = newJObject()
  if body != nil:
    body_603446 = body
  result = call_603445.call(nil, nil, nil, nil, body_603446)

var describeDeliveryChannels* = Call_DescribeDeliveryChannels_603432(
    name: "describeDeliveryChannels", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DescribeDeliveryChannels",
    validator: validate_DescribeDeliveryChannels_603433, base: "/",
    url: url_DescribeDeliveryChannels_603434, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOrganizationConfigRuleStatuses_603447 = ref object of OpenApiRestCall_602466
proc url_DescribeOrganizationConfigRuleStatuses_603449(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeOrganizationConfigRuleStatuses_603448(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Provides organization config rule deployment status for an organization.</p> <note> <p>The status is not considered successful until organization config rule is successfully deployed in all the member accounts with an exception of excluded accounts.</p> <p>When you specify the limit and the next token, you receive a paginated response. Limit and next token are not applicable if you specify organization config rule names. It is only applicable, when you request all the organization config rules.</p> <p>Only a master account can call this API.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603450 = header.getOrDefault("X-Amz-Date")
  valid_603450 = validateParameter(valid_603450, JString, required = false,
                                 default = nil)
  if valid_603450 != nil:
    section.add "X-Amz-Date", valid_603450
  var valid_603451 = header.getOrDefault("X-Amz-Security-Token")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-Security-Token", valid_603451
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603452 = header.getOrDefault("X-Amz-Target")
  valid_603452 = validateParameter(valid_603452, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeOrganizationConfigRuleStatuses"))
  if valid_603452 != nil:
    section.add "X-Amz-Target", valid_603452
  var valid_603453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-Content-Sha256", valid_603453
  var valid_603454 = header.getOrDefault("X-Amz-Algorithm")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-Algorithm", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-Signature")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Signature", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-SignedHeaders", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Credential")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Credential", valid_603457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603459: Call_DescribeOrganizationConfigRuleStatuses_603447;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Provides organization config rule deployment status for an organization.</p> <note> <p>The status is not considered successful until organization config rule is successfully deployed in all the member accounts with an exception of excluded accounts.</p> <p>When you specify the limit and the next token, you receive a paginated response. Limit and next token are not applicable if you specify organization config rule names. It is only applicable, when you request all the organization config rules.</p> <p>Only a master account can call this API.</p> </note>
  ## 
  let valid = call_603459.validator(path, query, header, formData, body)
  let scheme = call_603459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603459.url(scheme.get, call_603459.host, call_603459.base,
                         call_603459.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603459, url, valid)

proc call*(call_603460: Call_DescribeOrganizationConfigRuleStatuses_603447;
          body: JsonNode): Recallable =
  ## describeOrganizationConfigRuleStatuses
  ## <p>Provides organization config rule deployment status for an organization.</p> <note> <p>The status is not considered successful until organization config rule is successfully deployed in all the member accounts with an exception of excluded accounts.</p> <p>When you specify the limit and the next token, you receive a paginated response. Limit and next token are not applicable if you specify organization config rule names. It is only applicable, when you request all the organization config rules.</p> <p>Only a master account can call this API.</p> </note>
  ##   body: JObject (required)
  var body_603461 = newJObject()
  if body != nil:
    body_603461 = body
  result = call_603460.call(nil, nil, nil, nil, body_603461)

var describeOrganizationConfigRuleStatuses* = Call_DescribeOrganizationConfigRuleStatuses_603447(
    name: "describeOrganizationConfigRuleStatuses", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeOrganizationConfigRuleStatuses",
    validator: validate_DescribeOrganizationConfigRuleStatuses_603448, base: "/",
    url: url_DescribeOrganizationConfigRuleStatuses_603449,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOrganizationConfigRules_603462 = ref object of OpenApiRestCall_602466
proc url_DescribeOrganizationConfigRules_603464(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeOrganizationConfigRules_603463(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of organization config rules.</p> <note> <p>When you specify the limit and the next token, you receive a paginated response. Limit and next token are not applicable if you specify organization config rule names. It is only applicable, when you request all the organization config rules.</p> <p>Only a master account can call this API.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603465 = header.getOrDefault("X-Amz-Date")
  valid_603465 = validateParameter(valid_603465, JString, required = false,
                                 default = nil)
  if valid_603465 != nil:
    section.add "X-Amz-Date", valid_603465
  var valid_603466 = header.getOrDefault("X-Amz-Security-Token")
  valid_603466 = validateParameter(valid_603466, JString, required = false,
                                 default = nil)
  if valid_603466 != nil:
    section.add "X-Amz-Security-Token", valid_603466
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603467 = header.getOrDefault("X-Amz-Target")
  valid_603467 = validateParameter(valid_603467, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeOrganizationConfigRules"))
  if valid_603467 != nil:
    section.add "X-Amz-Target", valid_603467
  var valid_603468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603468 = validateParameter(valid_603468, JString, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "X-Amz-Content-Sha256", valid_603468
  var valid_603469 = header.getOrDefault("X-Amz-Algorithm")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-Algorithm", valid_603469
  var valid_603470 = header.getOrDefault("X-Amz-Signature")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Signature", valid_603470
  var valid_603471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-SignedHeaders", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-Credential")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Credential", valid_603472
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603474: Call_DescribeOrganizationConfigRules_603462;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns a list of organization config rules.</p> <note> <p>When you specify the limit and the next token, you receive a paginated response. Limit and next token are not applicable if you specify organization config rule names. It is only applicable, when you request all the organization config rules.</p> <p>Only a master account can call this API.</p> </note>
  ## 
  let valid = call_603474.validator(path, query, header, formData, body)
  let scheme = call_603474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603474.url(scheme.get, call_603474.host, call_603474.base,
                         call_603474.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603474, url, valid)

proc call*(call_603475: Call_DescribeOrganizationConfigRules_603462; body: JsonNode): Recallable =
  ## describeOrganizationConfigRules
  ## <p>Returns a list of organization config rules.</p> <note> <p>When you specify the limit and the next token, you receive a paginated response. Limit and next token are not applicable if you specify organization config rule names. It is only applicable, when you request all the organization config rules.</p> <p>Only a master account can call this API.</p> </note>
  ##   body: JObject (required)
  var body_603476 = newJObject()
  if body != nil:
    body_603476 = body
  result = call_603475.call(nil, nil, nil, nil, body_603476)

var describeOrganizationConfigRules* = Call_DescribeOrganizationConfigRules_603462(
    name: "describeOrganizationConfigRules", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeOrganizationConfigRules",
    validator: validate_DescribeOrganizationConfigRules_603463, base: "/",
    url: url_DescribeOrganizationConfigRules_603464,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePendingAggregationRequests_603477 = ref object of OpenApiRestCall_602466
proc url_DescribePendingAggregationRequests_603479(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribePendingAggregationRequests_603478(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of all pending aggregation requests.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603480 = header.getOrDefault("X-Amz-Date")
  valid_603480 = validateParameter(valid_603480, JString, required = false,
                                 default = nil)
  if valid_603480 != nil:
    section.add "X-Amz-Date", valid_603480
  var valid_603481 = header.getOrDefault("X-Amz-Security-Token")
  valid_603481 = validateParameter(valid_603481, JString, required = false,
                                 default = nil)
  if valid_603481 != nil:
    section.add "X-Amz-Security-Token", valid_603481
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603482 = header.getOrDefault("X-Amz-Target")
  valid_603482 = validateParameter(valid_603482, JString, required = true, default = newJString(
      "StarlingDoveService.DescribePendingAggregationRequests"))
  if valid_603482 != nil:
    section.add "X-Amz-Target", valid_603482
  var valid_603483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "X-Amz-Content-Sha256", valid_603483
  var valid_603484 = header.getOrDefault("X-Amz-Algorithm")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "X-Amz-Algorithm", valid_603484
  var valid_603485 = header.getOrDefault("X-Amz-Signature")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-Signature", valid_603485
  var valid_603486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-SignedHeaders", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-Credential")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Credential", valid_603487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603489: Call_DescribePendingAggregationRequests_603477;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns a list of all pending aggregation requests.
  ## 
  let valid = call_603489.validator(path, query, header, formData, body)
  let scheme = call_603489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603489.url(scheme.get, call_603489.host, call_603489.base,
                         call_603489.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603489, url, valid)

proc call*(call_603490: Call_DescribePendingAggregationRequests_603477;
          body: JsonNode): Recallable =
  ## describePendingAggregationRequests
  ## Returns a list of all pending aggregation requests.
  ##   body: JObject (required)
  var body_603491 = newJObject()
  if body != nil:
    body_603491 = body
  result = call_603490.call(nil, nil, nil, nil, body_603491)

var describePendingAggregationRequests* = Call_DescribePendingAggregationRequests_603477(
    name: "describePendingAggregationRequests", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribePendingAggregationRequests",
    validator: validate_DescribePendingAggregationRequests_603478, base: "/",
    url: url_DescribePendingAggregationRequests_603479,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRemediationConfigurations_603492 = ref object of OpenApiRestCall_602466
proc url_DescribeRemediationConfigurations_603494(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeRemediationConfigurations_603493(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the details of one or more remediation configurations.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603495 = header.getOrDefault("X-Amz-Date")
  valid_603495 = validateParameter(valid_603495, JString, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "X-Amz-Date", valid_603495
  var valid_603496 = header.getOrDefault("X-Amz-Security-Token")
  valid_603496 = validateParameter(valid_603496, JString, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "X-Amz-Security-Token", valid_603496
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603497 = header.getOrDefault("X-Amz-Target")
  valid_603497 = validateParameter(valid_603497, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeRemediationConfigurations"))
  if valid_603497 != nil:
    section.add "X-Amz-Target", valid_603497
  var valid_603498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-Content-Sha256", valid_603498
  var valid_603499 = header.getOrDefault("X-Amz-Algorithm")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Algorithm", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Signature")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Signature", valid_603500
  var valid_603501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603501 = validateParameter(valid_603501, JString, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "X-Amz-SignedHeaders", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-Credential")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Credential", valid_603502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603504: Call_DescribeRemediationConfigurations_603492;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the details of one or more remediation configurations.
  ## 
  let valid = call_603504.validator(path, query, header, formData, body)
  let scheme = call_603504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603504.url(scheme.get, call_603504.host, call_603504.base,
                         call_603504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603504, url, valid)

proc call*(call_603505: Call_DescribeRemediationConfigurations_603492;
          body: JsonNode): Recallable =
  ## describeRemediationConfigurations
  ## Returns the details of one or more remediation configurations.
  ##   body: JObject (required)
  var body_603506 = newJObject()
  if body != nil:
    body_603506 = body
  result = call_603505.call(nil, nil, nil, nil, body_603506)

var describeRemediationConfigurations* = Call_DescribeRemediationConfigurations_603492(
    name: "describeRemediationConfigurations", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeRemediationConfigurations",
    validator: validate_DescribeRemediationConfigurations_603493, base: "/",
    url: url_DescribeRemediationConfigurations_603494,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRemediationExceptions_603507 = ref object of OpenApiRestCall_602466
proc url_DescribeRemediationExceptions_603509(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeRemediationExceptions_603508(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the details of one or more remediation exceptions. A detailed view of a remediation exception for a set of resources that includes an explanation of an exception and the time when the exception will be deleted. When you specify the limit and the next token, you receive a paginated response. </p> <note> <p>When you specify the limit and the next token, you receive a paginated response. </p> <p>Limit and next token are not applicable if you request resources in batch. It is only applicable, when you request all resources.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603510 = query.getOrDefault("Limit")
  valid_603510 = validateParameter(valid_603510, JString, required = false,
                                 default = nil)
  if valid_603510 != nil:
    section.add "Limit", valid_603510
  var valid_603511 = query.getOrDefault("NextToken")
  valid_603511 = validateParameter(valid_603511, JString, required = false,
                                 default = nil)
  if valid_603511 != nil:
    section.add "NextToken", valid_603511
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603512 = header.getOrDefault("X-Amz-Date")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "X-Amz-Date", valid_603512
  var valid_603513 = header.getOrDefault("X-Amz-Security-Token")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "X-Amz-Security-Token", valid_603513
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603514 = header.getOrDefault("X-Amz-Target")
  valid_603514 = validateParameter(valid_603514, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeRemediationExceptions"))
  if valid_603514 != nil:
    section.add "X-Amz-Target", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Content-Sha256", valid_603515
  var valid_603516 = header.getOrDefault("X-Amz-Algorithm")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "X-Amz-Algorithm", valid_603516
  var valid_603517 = header.getOrDefault("X-Amz-Signature")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Signature", valid_603517
  var valid_603518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-SignedHeaders", valid_603518
  var valid_603519 = header.getOrDefault("X-Amz-Credential")
  valid_603519 = validateParameter(valid_603519, JString, required = false,
                                 default = nil)
  if valid_603519 != nil:
    section.add "X-Amz-Credential", valid_603519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603521: Call_DescribeRemediationExceptions_603507; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the details of one or more remediation exceptions. A detailed view of a remediation exception for a set of resources that includes an explanation of an exception and the time when the exception will be deleted. When you specify the limit and the next token, you receive a paginated response. </p> <note> <p>When you specify the limit and the next token, you receive a paginated response. </p> <p>Limit and next token are not applicable if you request resources in batch. It is only applicable, when you request all resources.</p> </note>
  ## 
  let valid = call_603521.validator(path, query, header, formData, body)
  let scheme = call_603521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603521.url(scheme.get, call_603521.host, call_603521.base,
                         call_603521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603521, url, valid)

proc call*(call_603522: Call_DescribeRemediationExceptions_603507; body: JsonNode;
          Limit: string = ""; NextToken: string = ""): Recallable =
  ## describeRemediationExceptions
  ## <p>Returns the details of one or more remediation exceptions. A detailed view of a remediation exception for a set of resources that includes an explanation of an exception and the time when the exception will be deleted. When you specify the limit and the next token, you receive a paginated response. </p> <note> <p>When you specify the limit and the next token, you receive a paginated response. </p> <p>Limit and next token are not applicable if you request resources in batch. It is only applicable, when you request all resources.</p> </note>
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603523 = newJObject()
  var body_603524 = newJObject()
  add(query_603523, "Limit", newJString(Limit))
  add(query_603523, "NextToken", newJString(NextToken))
  if body != nil:
    body_603524 = body
  result = call_603522.call(nil, query_603523, nil, nil, body_603524)

var describeRemediationExceptions* = Call_DescribeRemediationExceptions_603507(
    name: "describeRemediationExceptions", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.DescribeRemediationExceptions",
    validator: validate_DescribeRemediationExceptions_603508, base: "/",
    url: url_DescribeRemediationExceptions_603509,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRemediationExecutionStatus_603526 = ref object of OpenApiRestCall_602466
proc url_DescribeRemediationExecutionStatus_603528(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeRemediationExecutionStatus_603527(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Provides a detailed view of a Remediation Execution for a set of resources including state, timestamps for when steps for the remediation execution occur, and any error messages for steps that have failed. When you specify the limit and the next token, you receive a paginated response.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Limit: JString
  ##        : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_603529 = query.getOrDefault("Limit")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "Limit", valid_603529
  var valid_603530 = query.getOrDefault("NextToken")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "NextToken", valid_603530
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603531 = header.getOrDefault("X-Amz-Date")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "X-Amz-Date", valid_603531
  var valid_603532 = header.getOrDefault("X-Amz-Security-Token")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-Security-Token", valid_603532
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603533 = header.getOrDefault("X-Amz-Target")
  valid_603533 = validateParameter(valid_603533, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeRemediationExecutionStatus"))
  if valid_603533 != nil:
    section.add "X-Amz-Target", valid_603533
  var valid_603534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603534 = validateParameter(valid_603534, JString, required = false,
                                 default = nil)
  if valid_603534 != nil:
    section.add "X-Amz-Content-Sha256", valid_603534
  var valid_603535 = header.getOrDefault("X-Amz-Algorithm")
  valid_603535 = validateParameter(valid_603535, JString, required = false,
                                 default = nil)
  if valid_603535 != nil:
    section.add "X-Amz-Algorithm", valid_603535
  var valid_603536 = header.getOrDefault("X-Amz-Signature")
  valid_603536 = validateParameter(valid_603536, JString, required = false,
                                 default = nil)
  if valid_603536 != nil:
    section.add "X-Amz-Signature", valid_603536
  var valid_603537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603537 = validateParameter(valid_603537, JString, required = false,
                                 default = nil)
  if valid_603537 != nil:
    section.add "X-Amz-SignedHeaders", valid_603537
  var valid_603538 = header.getOrDefault("X-Amz-Credential")
  valid_603538 = validateParameter(valid_603538, JString, required = false,
                                 default = nil)
  if valid_603538 != nil:
    section.add "X-Amz-Credential", valid_603538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603540: Call_DescribeRemediationExecutionStatus_603526;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Provides a detailed view of a Remediation Execution for a set of resources including state, timestamps for when steps for the remediation execution occur, and any error messages for steps that have failed. When you specify the limit and the next token, you receive a paginated response.
  ## 
  let valid = call_603540.validator(path, query, header, formData, body)
  let scheme = call_603540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603540.url(scheme.get, call_603540.host, call_603540.base,
                         call_603540.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603540, url, valid)

proc call*(call_603541: Call_DescribeRemediationExecutionStatus_603526;
          body: JsonNode; Limit: string = ""; NextToken: string = ""): Recallable =
  ## describeRemediationExecutionStatus
  ## Provides a detailed view of a Remediation Execution for a set of resources including state, timestamps for when steps for the remediation execution occur, and any error messages for steps that have failed. When you specify the limit and the next token, you receive a paginated response.
  ##   Limit: string
  ##        : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_603542 = newJObject()
  var body_603543 = newJObject()
  add(query_603542, "Limit", newJString(Limit))
  add(query_603542, "NextToken", newJString(NextToken))
  if body != nil:
    body_603543 = body
  result = call_603541.call(nil, query_603542, nil, nil, body_603543)

var describeRemediationExecutionStatus* = Call_DescribeRemediationExecutionStatus_603526(
    name: "describeRemediationExecutionStatus", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeRemediationExecutionStatus",
    validator: validate_DescribeRemediationExecutionStatus_603527, base: "/",
    url: url_DescribeRemediationExecutionStatus_603528,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRetentionConfigurations_603544 = ref object of OpenApiRestCall_602466
proc url_DescribeRetentionConfigurations_603546(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeRetentionConfigurations_603545(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the details of one or more retention configurations. If the retention configuration name is not specified, this action returns the details for all the retention configurations for that account.</p> <note> <p>Currently, AWS Config supports only one retention configuration per region in your account.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603547 = header.getOrDefault("X-Amz-Date")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Date", valid_603547
  var valid_603548 = header.getOrDefault("X-Amz-Security-Token")
  valid_603548 = validateParameter(valid_603548, JString, required = false,
                                 default = nil)
  if valid_603548 != nil:
    section.add "X-Amz-Security-Token", valid_603548
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603549 = header.getOrDefault("X-Amz-Target")
  valid_603549 = validateParameter(valid_603549, JString, required = true, default = newJString(
      "StarlingDoveService.DescribeRetentionConfigurations"))
  if valid_603549 != nil:
    section.add "X-Amz-Target", valid_603549
  var valid_603550 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603550 = validateParameter(valid_603550, JString, required = false,
                                 default = nil)
  if valid_603550 != nil:
    section.add "X-Amz-Content-Sha256", valid_603550
  var valid_603551 = header.getOrDefault("X-Amz-Algorithm")
  valid_603551 = validateParameter(valid_603551, JString, required = false,
                                 default = nil)
  if valid_603551 != nil:
    section.add "X-Amz-Algorithm", valid_603551
  var valid_603552 = header.getOrDefault("X-Amz-Signature")
  valid_603552 = validateParameter(valid_603552, JString, required = false,
                                 default = nil)
  if valid_603552 != nil:
    section.add "X-Amz-Signature", valid_603552
  var valid_603553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603553 = validateParameter(valid_603553, JString, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "X-Amz-SignedHeaders", valid_603553
  var valid_603554 = header.getOrDefault("X-Amz-Credential")
  valid_603554 = validateParameter(valid_603554, JString, required = false,
                                 default = nil)
  if valid_603554 != nil:
    section.add "X-Amz-Credential", valid_603554
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603556: Call_DescribeRetentionConfigurations_603544;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns the details of one or more retention configurations. If the retention configuration name is not specified, this action returns the details for all the retention configurations for that account.</p> <note> <p>Currently, AWS Config supports only one retention configuration per region in your account.</p> </note>
  ## 
  let valid = call_603556.validator(path, query, header, formData, body)
  let scheme = call_603556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603556.url(scheme.get, call_603556.host, call_603556.base,
                         call_603556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603556, url, valid)

proc call*(call_603557: Call_DescribeRetentionConfigurations_603544; body: JsonNode): Recallable =
  ## describeRetentionConfigurations
  ## <p>Returns the details of one or more retention configurations. If the retention configuration name is not specified, this action returns the details for all the retention configurations for that account.</p> <note> <p>Currently, AWS Config supports only one retention configuration per region in your account.</p> </note>
  ##   body: JObject (required)
  var body_603558 = newJObject()
  if body != nil:
    body_603558 = body
  result = call_603557.call(nil, nil, nil, nil, body_603558)

var describeRetentionConfigurations* = Call_DescribeRetentionConfigurations_603544(
    name: "describeRetentionConfigurations", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.DescribeRetentionConfigurations",
    validator: validate_DescribeRetentionConfigurations_603545, base: "/",
    url: url_DescribeRetentionConfigurations_603546,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAggregateComplianceDetailsByConfigRule_603559 = ref object of OpenApiRestCall_602466
proc url_GetAggregateComplianceDetailsByConfigRule_603561(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAggregateComplianceDetailsByConfigRule_603560(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the evaluation results for the specified AWS Config rule for a specific resource in a rule. The results indicate which AWS resources were evaluated by the rule, when each resource was last evaluated, and whether each resource complies with the rule. </p> <note> <p>The results can return an empty result page. But if you have a <code>nextToken</code>, the results are displayed on the next page.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603562 = header.getOrDefault("X-Amz-Date")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-Date", valid_603562
  var valid_603563 = header.getOrDefault("X-Amz-Security-Token")
  valid_603563 = validateParameter(valid_603563, JString, required = false,
                                 default = nil)
  if valid_603563 != nil:
    section.add "X-Amz-Security-Token", valid_603563
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603564 = header.getOrDefault("X-Amz-Target")
  valid_603564 = validateParameter(valid_603564, JString, required = true, default = newJString(
      "StarlingDoveService.GetAggregateComplianceDetailsByConfigRule"))
  if valid_603564 != nil:
    section.add "X-Amz-Target", valid_603564
  var valid_603565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "X-Amz-Content-Sha256", valid_603565
  var valid_603566 = header.getOrDefault("X-Amz-Algorithm")
  valid_603566 = validateParameter(valid_603566, JString, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "X-Amz-Algorithm", valid_603566
  var valid_603567 = header.getOrDefault("X-Amz-Signature")
  valid_603567 = validateParameter(valid_603567, JString, required = false,
                                 default = nil)
  if valid_603567 != nil:
    section.add "X-Amz-Signature", valid_603567
  var valid_603568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603568 = validateParameter(valid_603568, JString, required = false,
                                 default = nil)
  if valid_603568 != nil:
    section.add "X-Amz-SignedHeaders", valid_603568
  var valid_603569 = header.getOrDefault("X-Amz-Credential")
  valid_603569 = validateParameter(valid_603569, JString, required = false,
                                 default = nil)
  if valid_603569 != nil:
    section.add "X-Amz-Credential", valid_603569
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603571: Call_GetAggregateComplianceDetailsByConfigRule_603559;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns the evaluation results for the specified AWS Config rule for a specific resource in a rule. The results indicate which AWS resources were evaluated by the rule, when each resource was last evaluated, and whether each resource complies with the rule. </p> <note> <p>The results can return an empty result page. But if you have a <code>nextToken</code>, the results are displayed on the next page.</p> </note>
  ## 
  let valid = call_603571.validator(path, query, header, formData, body)
  let scheme = call_603571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603571.url(scheme.get, call_603571.host, call_603571.base,
                         call_603571.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603571, url, valid)

proc call*(call_603572: Call_GetAggregateComplianceDetailsByConfigRule_603559;
          body: JsonNode): Recallable =
  ## getAggregateComplianceDetailsByConfigRule
  ## <p>Returns the evaluation results for the specified AWS Config rule for a specific resource in a rule. The results indicate which AWS resources were evaluated by the rule, when each resource was last evaluated, and whether each resource complies with the rule. </p> <note> <p>The results can return an empty result page. But if you have a <code>nextToken</code>, the results are displayed on the next page.</p> </note>
  ##   body: JObject (required)
  var body_603573 = newJObject()
  if body != nil:
    body_603573 = body
  result = call_603572.call(nil, nil, nil, nil, body_603573)

var getAggregateComplianceDetailsByConfigRule* = Call_GetAggregateComplianceDetailsByConfigRule_603559(
    name: "getAggregateComplianceDetailsByConfigRule", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.GetAggregateComplianceDetailsByConfigRule",
    validator: validate_GetAggregateComplianceDetailsByConfigRule_603560,
    base: "/", url: url_GetAggregateComplianceDetailsByConfigRule_603561,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAggregateConfigRuleComplianceSummary_603574 = ref object of OpenApiRestCall_602466
proc url_GetAggregateConfigRuleComplianceSummary_603576(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAggregateConfigRuleComplianceSummary_603575(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the number of compliant and noncompliant rules for one or more accounts and regions in an aggregator.</p> <note> <p>The results can return an empty result page, but if you have a nextToken, the results are displayed on the next page.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603577 = header.getOrDefault("X-Amz-Date")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-Date", valid_603577
  var valid_603578 = header.getOrDefault("X-Amz-Security-Token")
  valid_603578 = validateParameter(valid_603578, JString, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "X-Amz-Security-Token", valid_603578
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603579 = header.getOrDefault("X-Amz-Target")
  valid_603579 = validateParameter(valid_603579, JString, required = true, default = newJString(
      "StarlingDoveService.GetAggregateConfigRuleComplianceSummary"))
  if valid_603579 != nil:
    section.add "X-Amz-Target", valid_603579
  var valid_603580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603580 = validateParameter(valid_603580, JString, required = false,
                                 default = nil)
  if valid_603580 != nil:
    section.add "X-Amz-Content-Sha256", valid_603580
  var valid_603581 = header.getOrDefault("X-Amz-Algorithm")
  valid_603581 = validateParameter(valid_603581, JString, required = false,
                                 default = nil)
  if valid_603581 != nil:
    section.add "X-Amz-Algorithm", valid_603581
  var valid_603582 = header.getOrDefault("X-Amz-Signature")
  valid_603582 = validateParameter(valid_603582, JString, required = false,
                                 default = nil)
  if valid_603582 != nil:
    section.add "X-Amz-Signature", valid_603582
  var valid_603583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603583 = validateParameter(valid_603583, JString, required = false,
                                 default = nil)
  if valid_603583 != nil:
    section.add "X-Amz-SignedHeaders", valid_603583
  var valid_603584 = header.getOrDefault("X-Amz-Credential")
  valid_603584 = validateParameter(valid_603584, JString, required = false,
                                 default = nil)
  if valid_603584 != nil:
    section.add "X-Amz-Credential", valid_603584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603586: Call_GetAggregateConfigRuleComplianceSummary_603574;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns the number of compliant and noncompliant rules for one or more accounts and regions in an aggregator.</p> <note> <p>The results can return an empty result page, but if you have a nextToken, the results are displayed on the next page.</p> </note>
  ## 
  let valid = call_603586.validator(path, query, header, formData, body)
  let scheme = call_603586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603586.url(scheme.get, call_603586.host, call_603586.base,
                         call_603586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603586, url, valid)

proc call*(call_603587: Call_GetAggregateConfigRuleComplianceSummary_603574;
          body: JsonNode): Recallable =
  ## getAggregateConfigRuleComplianceSummary
  ## <p>Returns the number of compliant and noncompliant rules for one or more accounts and regions in an aggregator.</p> <note> <p>The results can return an empty result page, but if you have a nextToken, the results are displayed on the next page.</p> </note>
  ##   body: JObject (required)
  var body_603588 = newJObject()
  if body != nil:
    body_603588 = body
  result = call_603587.call(nil, nil, nil, nil, body_603588)

var getAggregateConfigRuleComplianceSummary* = Call_GetAggregateConfigRuleComplianceSummary_603574(
    name: "getAggregateConfigRuleComplianceSummary", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.GetAggregateConfigRuleComplianceSummary",
    validator: validate_GetAggregateConfigRuleComplianceSummary_603575, base: "/",
    url: url_GetAggregateConfigRuleComplianceSummary_603576,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAggregateDiscoveredResourceCounts_603589 = ref object of OpenApiRestCall_602466
proc url_GetAggregateDiscoveredResourceCounts_603591(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAggregateDiscoveredResourceCounts_603590(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the resource counts across accounts and regions that are present in your AWS Config aggregator. You can request the resource counts by providing filters and GroupByKey.</p> <p>For example, if the input contains accountID 12345678910 and region us-east-1 in filters, the API returns the count of resources in account ID 12345678910 and region us-east-1. If the input contains ACCOUNT_ID as a GroupByKey, the API returns resource counts for all source accounts that are present in your aggregator.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603592 = header.getOrDefault("X-Amz-Date")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "X-Amz-Date", valid_603592
  var valid_603593 = header.getOrDefault("X-Amz-Security-Token")
  valid_603593 = validateParameter(valid_603593, JString, required = false,
                                 default = nil)
  if valid_603593 != nil:
    section.add "X-Amz-Security-Token", valid_603593
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603594 = header.getOrDefault("X-Amz-Target")
  valid_603594 = validateParameter(valid_603594, JString, required = true, default = newJString(
      "StarlingDoveService.GetAggregateDiscoveredResourceCounts"))
  if valid_603594 != nil:
    section.add "X-Amz-Target", valid_603594
  var valid_603595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603595 = validateParameter(valid_603595, JString, required = false,
                                 default = nil)
  if valid_603595 != nil:
    section.add "X-Amz-Content-Sha256", valid_603595
  var valid_603596 = header.getOrDefault("X-Amz-Algorithm")
  valid_603596 = validateParameter(valid_603596, JString, required = false,
                                 default = nil)
  if valid_603596 != nil:
    section.add "X-Amz-Algorithm", valid_603596
  var valid_603597 = header.getOrDefault("X-Amz-Signature")
  valid_603597 = validateParameter(valid_603597, JString, required = false,
                                 default = nil)
  if valid_603597 != nil:
    section.add "X-Amz-Signature", valid_603597
  var valid_603598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603598 = validateParameter(valid_603598, JString, required = false,
                                 default = nil)
  if valid_603598 != nil:
    section.add "X-Amz-SignedHeaders", valid_603598
  var valid_603599 = header.getOrDefault("X-Amz-Credential")
  valid_603599 = validateParameter(valid_603599, JString, required = false,
                                 default = nil)
  if valid_603599 != nil:
    section.add "X-Amz-Credential", valid_603599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603601: Call_GetAggregateDiscoveredResourceCounts_603589;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns the resource counts across accounts and regions that are present in your AWS Config aggregator. You can request the resource counts by providing filters and GroupByKey.</p> <p>For example, if the input contains accountID 12345678910 and region us-east-1 in filters, the API returns the count of resources in account ID 12345678910 and region us-east-1. If the input contains ACCOUNT_ID as a GroupByKey, the API returns resource counts for all source accounts that are present in your aggregator.</p>
  ## 
  let valid = call_603601.validator(path, query, header, formData, body)
  let scheme = call_603601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603601.url(scheme.get, call_603601.host, call_603601.base,
                         call_603601.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603601, url, valid)

proc call*(call_603602: Call_GetAggregateDiscoveredResourceCounts_603589;
          body: JsonNode): Recallable =
  ## getAggregateDiscoveredResourceCounts
  ## <p>Returns the resource counts across accounts and regions that are present in your AWS Config aggregator. You can request the resource counts by providing filters and GroupByKey.</p> <p>For example, if the input contains accountID 12345678910 and region us-east-1 in filters, the API returns the count of resources in account ID 12345678910 and region us-east-1. If the input contains ACCOUNT_ID as a GroupByKey, the API returns resource counts for all source accounts that are present in your aggregator.</p>
  ##   body: JObject (required)
  var body_603603 = newJObject()
  if body != nil:
    body_603603 = body
  result = call_603602.call(nil, nil, nil, nil, body_603603)

var getAggregateDiscoveredResourceCounts* = Call_GetAggregateDiscoveredResourceCounts_603589(
    name: "getAggregateDiscoveredResourceCounts", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.GetAggregateDiscoveredResourceCounts",
    validator: validate_GetAggregateDiscoveredResourceCounts_603590, base: "/",
    url: url_GetAggregateDiscoveredResourceCounts_603591,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAggregateResourceConfig_603604 = ref object of OpenApiRestCall_602466
proc url_GetAggregateResourceConfig_603606(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAggregateResourceConfig_603605(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns configuration item that is aggregated for your specific resource in a specific source account and region.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603607 = header.getOrDefault("X-Amz-Date")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "X-Amz-Date", valid_603607
  var valid_603608 = header.getOrDefault("X-Amz-Security-Token")
  valid_603608 = validateParameter(valid_603608, JString, required = false,
                                 default = nil)
  if valid_603608 != nil:
    section.add "X-Amz-Security-Token", valid_603608
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603609 = header.getOrDefault("X-Amz-Target")
  valid_603609 = validateParameter(valid_603609, JString, required = true, default = newJString(
      "StarlingDoveService.GetAggregateResourceConfig"))
  if valid_603609 != nil:
    section.add "X-Amz-Target", valid_603609
  var valid_603610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603610 = validateParameter(valid_603610, JString, required = false,
                                 default = nil)
  if valid_603610 != nil:
    section.add "X-Amz-Content-Sha256", valid_603610
  var valid_603611 = header.getOrDefault("X-Amz-Algorithm")
  valid_603611 = validateParameter(valid_603611, JString, required = false,
                                 default = nil)
  if valid_603611 != nil:
    section.add "X-Amz-Algorithm", valid_603611
  var valid_603612 = header.getOrDefault("X-Amz-Signature")
  valid_603612 = validateParameter(valid_603612, JString, required = false,
                                 default = nil)
  if valid_603612 != nil:
    section.add "X-Amz-Signature", valid_603612
  var valid_603613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603613 = validateParameter(valid_603613, JString, required = false,
                                 default = nil)
  if valid_603613 != nil:
    section.add "X-Amz-SignedHeaders", valid_603613
  var valid_603614 = header.getOrDefault("X-Amz-Credential")
  valid_603614 = validateParameter(valid_603614, JString, required = false,
                                 default = nil)
  if valid_603614 != nil:
    section.add "X-Amz-Credential", valid_603614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603616: Call_GetAggregateResourceConfig_603604; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns configuration item that is aggregated for your specific resource in a specific source account and region.
  ## 
  let valid = call_603616.validator(path, query, header, formData, body)
  let scheme = call_603616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603616.url(scheme.get, call_603616.host, call_603616.base,
                         call_603616.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603616, url, valid)

proc call*(call_603617: Call_GetAggregateResourceConfig_603604; body: JsonNode): Recallable =
  ## getAggregateResourceConfig
  ## Returns configuration item that is aggregated for your specific resource in a specific source account and region.
  ##   body: JObject (required)
  var body_603618 = newJObject()
  if body != nil:
    body_603618 = body
  result = call_603617.call(nil, nil, nil, nil, body_603618)

var getAggregateResourceConfig* = Call_GetAggregateResourceConfig_603604(
    name: "getAggregateResourceConfig", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.GetAggregateResourceConfig",
    validator: validate_GetAggregateResourceConfig_603605, base: "/",
    url: url_GetAggregateResourceConfig_603606,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComplianceDetailsByConfigRule_603619 = ref object of OpenApiRestCall_602466
proc url_GetComplianceDetailsByConfigRule_603621(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetComplianceDetailsByConfigRule_603620(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the evaluation results for the specified AWS Config rule. The results indicate which AWS resources were evaluated by the rule, when each resource was last evaluated, and whether each resource complies with the rule.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603622 = header.getOrDefault("X-Amz-Date")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "X-Amz-Date", valid_603622
  var valid_603623 = header.getOrDefault("X-Amz-Security-Token")
  valid_603623 = validateParameter(valid_603623, JString, required = false,
                                 default = nil)
  if valid_603623 != nil:
    section.add "X-Amz-Security-Token", valid_603623
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603624 = header.getOrDefault("X-Amz-Target")
  valid_603624 = validateParameter(valid_603624, JString, required = true, default = newJString(
      "StarlingDoveService.GetComplianceDetailsByConfigRule"))
  if valid_603624 != nil:
    section.add "X-Amz-Target", valid_603624
  var valid_603625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603625 = validateParameter(valid_603625, JString, required = false,
                                 default = nil)
  if valid_603625 != nil:
    section.add "X-Amz-Content-Sha256", valid_603625
  var valid_603626 = header.getOrDefault("X-Amz-Algorithm")
  valid_603626 = validateParameter(valid_603626, JString, required = false,
                                 default = nil)
  if valid_603626 != nil:
    section.add "X-Amz-Algorithm", valid_603626
  var valid_603627 = header.getOrDefault("X-Amz-Signature")
  valid_603627 = validateParameter(valid_603627, JString, required = false,
                                 default = nil)
  if valid_603627 != nil:
    section.add "X-Amz-Signature", valid_603627
  var valid_603628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603628 = validateParameter(valid_603628, JString, required = false,
                                 default = nil)
  if valid_603628 != nil:
    section.add "X-Amz-SignedHeaders", valid_603628
  var valid_603629 = header.getOrDefault("X-Amz-Credential")
  valid_603629 = validateParameter(valid_603629, JString, required = false,
                                 default = nil)
  if valid_603629 != nil:
    section.add "X-Amz-Credential", valid_603629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603631: Call_GetComplianceDetailsByConfigRule_603619;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the evaluation results for the specified AWS Config rule. The results indicate which AWS resources were evaluated by the rule, when each resource was last evaluated, and whether each resource complies with the rule.
  ## 
  let valid = call_603631.validator(path, query, header, formData, body)
  let scheme = call_603631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603631.url(scheme.get, call_603631.host, call_603631.base,
                         call_603631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603631, url, valid)

proc call*(call_603632: Call_GetComplianceDetailsByConfigRule_603619;
          body: JsonNode): Recallable =
  ## getComplianceDetailsByConfigRule
  ## Returns the evaluation results for the specified AWS Config rule. The results indicate which AWS resources were evaluated by the rule, when each resource was last evaluated, and whether each resource complies with the rule.
  ##   body: JObject (required)
  var body_603633 = newJObject()
  if body != nil:
    body_603633 = body
  result = call_603632.call(nil, nil, nil, nil, body_603633)

var getComplianceDetailsByConfigRule* = Call_GetComplianceDetailsByConfigRule_603619(
    name: "getComplianceDetailsByConfigRule", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.GetComplianceDetailsByConfigRule",
    validator: validate_GetComplianceDetailsByConfigRule_603620, base: "/",
    url: url_GetComplianceDetailsByConfigRule_603621,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComplianceDetailsByResource_603634 = ref object of OpenApiRestCall_602466
proc url_GetComplianceDetailsByResource_603636(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetComplianceDetailsByResource_603635(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the evaluation results for the specified AWS resource. The results indicate which AWS Config rules were used to evaluate the resource, when each rule was last used, and whether the resource complies with each rule.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603637 = header.getOrDefault("X-Amz-Date")
  valid_603637 = validateParameter(valid_603637, JString, required = false,
                                 default = nil)
  if valid_603637 != nil:
    section.add "X-Amz-Date", valid_603637
  var valid_603638 = header.getOrDefault("X-Amz-Security-Token")
  valid_603638 = validateParameter(valid_603638, JString, required = false,
                                 default = nil)
  if valid_603638 != nil:
    section.add "X-Amz-Security-Token", valid_603638
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603639 = header.getOrDefault("X-Amz-Target")
  valid_603639 = validateParameter(valid_603639, JString, required = true, default = newJString(
      "StarlingDoveService.GetComplianceDetailsByResource"))
  if valid_603639 != nil:
    section.add "X-Amz-Target", valid_603639
  var valid_603640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603640 = validateParameter(valid_603640, JString, required = false,
                                 default = nil)
  if valid_603640 != nil:
    section.add "X-Amz-Content-Sha256", valid_603640
  var valid_603641 = header.getOrDefault("X-Amz-Algorithm")
  valid_603641 = validateParameter(valid_603641, JString, required = false,
                                 default = nil)
  if valid_603641 != nil:
    section.add "X-Amz-Algorithm", valid_603641
  var valid_603642 = header.getOrDefault("X-Amz-Signature")
  valid_603642 = validateParameter(valid_603642, JString, required = false,
                                 default = nil)
  if valid_603642 != nil:
    section.add "X-Amz-Signature", valid_603642
  var valid_603643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603643 = validateParameter(valid_603643, JString, required = false,
                                 default = nil)
  if valid_603643 != nil:
    section.add "X-Amz-SignedHeaders", valid_603643
  var valid_603644 = header.getOrDefault("X-Amz-Credential")
  valid_603644 = validateParameter(valid_603644, JString, required = false,
                                 default = nil)
  if valid_603644 != nil:
    section.add "X-Amz-Credential", valid_603644
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603646: Call_GetComplianceDetailsByResource_603634; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns the evaluation results for the specified AWS resource. The results indicate which AWS Config rules were used to evaluate the resource, when each rule was last used, and whether the resource complies with each rule.
  ## 
  let valid = call_603646.validator(path, query, header, formData, body)
  let scheme = call_603646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603646.url(scheme.get, call_603646.host, call_603646.base,
                         call_603646.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603646, url, valid)

proc call*(call_603647: Call_GetComplianceDetailsByResource_603634; body: JsonNode): Recallable =
  ## getComplianceDetailsByResource
  ## Returns the evaluation results for the specified AWS resource. The results indicate which AWS Config rules were used to evaluate the resource, when each rule was last used, and whether the resource complies with each rule.
  ##   body: JObject (required)
  var body_603648 = newJObject()
  if body != nil:
    body_603648 = body
  result = call_603647.call(nil, nil, nil, nil, body_603648)

var getComplianceDetailsByResource* = Call_GetComplianceDetailsByResource_603634(
    name: "getComplianceDetailsByResource", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.GetComplianceDetailsByResource",
    validator: validate_GetComplianceDetailsByResource_603635, base: "/",
    url: url_GetComplianceDetailsByResource_603636,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComplianceSummaryByConfigRule_603649 = ref object of OpenApiRestCall_602466
proc url_GetComplianceSummaryByConfigRule_603651(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetComplianceSummaryByConfigRule_603650(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the number of AWS Config rules that are compliant and noncompliant, up to a maximum of 25 for each.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603652 = header.getOrDefault("X-Amz-Date")
  valid_603652 = validateParameter(valid_603652, JString, required = false,
                                 default = nil)
  if valid_603652 != nil:
    section.add "X-Amz-Date", valid_603652
  var valid_603653 = header.getOrDefault("X-Amz-Security-Token")
  valid_603653 = validateParameter(valid_603653, JString, required = false,
                                 default = nil)
  if valid_603653 != nil:
    section.add "X-Amz-Security-Token", valid_603653
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603654 = header.getOrDefault("X-Amz-Target")
  valid_603654 = validateParameter(valid_603654, JString, required = true, default = newJString(
      "StarlingDoveService.GetComplianceSummaryByConfigRule"))
  if valid_603654 != nil:
    section.add "X-Amz-Target", valid_603654
  var valid_603655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603655 = validateParameter(valid_603655, JString, required = false,
                                 default = nil)
  if valid_603655 != nil:
    section.add "X-Amz-Content-Sha256", valid_603655
  var valid_603656 = header.getOrDefault("X-Amz-Algorithm")
  valid_603656 = validateParameter(valid_603656, JString, required = false,
                                 default = nil)
  if valid_603656 != nil:
    section.add "X-Amz-Algorithm", valid_603656
  var valid_603657 = header.getOrDefault("X-Amz-Signature")
  valid_603657 = validateParameter(valid_603657, JString, required = false,
                                 default = nil)
  if valid_603657 != nil:
    section.add "X-Amz-Signature", valid_603657
  var valid_603658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603658 = validateParameter(valid_603658, JString, required = false,
                                 default = nil)
  if valid_603658 != nil:
    section.add "X-Amz-SignedHeaders", valid_603658
  var valid_603659 = header.getOrDefault("X-Amz-Credential")
  valid_603659 = validateParameter(valid_603659, JString, required = false,
                                 default = nil)
  if valid_603659 != nil:
    section.add "X-Amz-Credential", valid_603659
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603660: Call_GetComplianceSummaryByConfigRule_603649;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the number of AWS Config rules that are compliant and noncompliant, up to a maximum of 25 for each.
  ## 
  let valid = call_603660.validator(path, query, header, formData, body)
  let scheme = call_603660.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603660.url(scheme.get, call_603660.host, call_603660.base,
                         call_603660.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603660, url, valid)

proc call*(call_603661: Call_GetComplianceSummaryByConfigRule_603649): Recallable =
  ## getComplianceSummaryByConfigRule
  ## Returns the number of AWS Config rules that are compliant and noncompliant, up to a maximum of 25 for each.
  result = call_603661.call(nil, nil, nil, nil, nil)

var getComplianceSummaryByConfigRule* = Call_GetComplianceSummaryByConfigRule_603649(
    name: "getComplianceSummaryByConfigRule", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.GetComplianceSummaryByConfigRule",
    validator: validate_GetComplianceSummaryByConfigRule_603650, base: "/",
    url: url_GetComplianceSummaryByConfigRule_603651,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetComplianceSummaryByResourceType_603662 = ref object of OpenApiRestCall_602466
proc url_GetComplianceSummaryByResourceType_603664(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetComplianceSummaryByResourceType_603663(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the number of resources that are compliant and the number that are noncompliant. You can specify one or more resource types to get these numbers for each resource type. The maximum number returned is 100.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603665 = header.getOrDefault("X-Amz-Date")
  valid_603665 = validateParameter(valid_603665, JString, required = false,
                                 default = nil)
  if valid_603665 != nil:
    section.add "X-Amz-Date", valid_603665
  var valid_603666 = header.getOrDefault("X-Amz-Security-Token")
  valid_603666 = validateParameter(valid_603666, JString, required = false,
                                 default = nil)
  if valid_603666 != nil:
    section.add "X-Amz-Security-Token", valid_603666
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603667 = header.getOrDefault("X-Amz-Target")
  valid_603667 = validateParameter(valid_603667, JString, required = true, default = newJString(
      "StarlingDoveService.GetComplianceSummaryByResourceType"))
  if valid_603667 != nil:
    section.add "X-Amz-Target", valid_603667
  var valid_603668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603668 = validateParameter(valid_603668, JString, required = false,
                                 default = nil)
  if valid_603668 != nil:
    section.add "X-Amz-Content-Sha256", valid_603668
  var valid_603669 = header.getOrDefault("X-Amz-Algorithm")
  valid_603669 = validateParameter(valid_603669, JString, required = false,
                                 default = nil)
  if valid_603669 != nil:
    section.add "X-Amz-Algorithm", valid_603669
  var valid_603670 = header.getOrDefault("X-Amz-Signature")
  valid_603670 = validateParameter(valid_603670, JString, required = false,
                                 default = nil)
  if valid_603670 != nil:
    section.add "X-Amz-Signature", valid_603670
  var valid_603671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603671 = validateParameter(valid_603671, JString, required = false,
                                 default = nil)
  if valid_603671 != nil:
    section.add "X-Amz-SignedHeaders", valid_603671
  var valid_603672 = header.getOrDefault("X-Amz-Credential")
  valid_603672 = validateParameter(valid_603672, JString, required = false,
                                 default = nil)
  if valid_603672 != nil:
    section.add "X-Amz-Credential", valid_603672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603674: Call_GetComplianceSummaryByResourceType_603662;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the number of resources that are compliant and the number that are noncompliant. You can specify one or more resource types to get these numbers for each resource type. The maximum number returned is 100.
  ## 
  let valid = call_603674.validator(path, query, header, formData, body)
  let scheme = call_603674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603674.url(scheme.get, call_603674.host, call_603674.base,
                         call_603674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603674, url, valid)

proc call*(call_603675: Call_GetComplianceSummaryByResourceType_603662;
          body: JsonNode): Recallable =
  ## getComplianceSummaryByResourceType
  ## Returns the number of resources that are compliant and the number that are noncompliant. You can specify one or more resource types to get these numbers for each resource type. The maximum number returned is 100.
  ##   body: JObject (required)
  var body_603676 = newJObject()
  if body != nil:
    body_603676 = body
  result = call_603675.call(nil, nil, nil, nil, body_603676)

var getComplianceSummaryByResourceType* = Call_GetComplianceSummaryByResourceType_603662(
    name: "getComplianceSummaryByResourceType", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.GetComplianceSummaryByResourceType",
    validator: validate_GetComplianceSummaryByResourceType_603663, base: "/",
    url: url_GetComplianceSummaryByResourceType_603664,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDiscoveredResourceCounts_603677 = ref object of OpenApiRestCall_602466
proc url_GetDiscoveredResourceCounts_603679(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDiscoveredResourceCounts_603678(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns the resource types, the number of each resource type, and the total number of resources that AWS Config is recording in this region for your AWS account. </p> <p class="title"> <b>Example</b> </p> <ol> <li> <p>AWS Config is recording three resource types in the US East (Ohio) Region for your account: 25 EC2 instances, 20 IAM users, and 15 S3 buckets.</p> </li> <li> <p>You make a call to the <code>GetDiscoveredResourceCounts</code> action and specify that you want all resource types. </p> </li> <li> <p>AWS Config returns the following:</p> <ul> <li> <p>The resource types (EC2 instances, IAM users, and S3 buckets).</p> </li> <li> <p>The number of each resource type (25, 20, and 15).</p> </li> <li> <p>The total number of all resources (60).</p> </li> </ul> </li> </ol> <p>The response is paginated. By default, AWS Config lists 100 <a>ResourceCount</a> objects on each page. You can customize this number with the <code>limit</code> parameter. The response includes a <code>nextToken</code> string. To get the next page of results, run the request again and specify the string for the <code>nextToken</code> parameter.</p> <note> <p>If you make a call to the <a>GetDiscoveredResourceCounts</a> action, you might not immediately receive resource counts in the following situations:</p> <ul> <li> <p>You are a new AWS Config customer.</p> </li> <li> <p>You just enabled resource recording.</p> </li> </ul> <p>It might take a few minutes for AWS Config to record and count your resources. Wait a few minutes and then retry the <a>GetDiscoveredResourceCounts</a> action. </p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603680 = header.getOrDefault("X-Amz-Date")
  valid_603680 = validateParameter(valid_603680, JString, required = false,
                                 default = nil)
  if valid_603680 != nil:
    section.add "X-Amz-Date", valid_603680
  var valid_603681 = header.getOrDefault("X-Amz-Security-Token")
  valid_603681 = validateParameter(valid_603681, JString, required = false,
                                 default = nil)
  if valid_603681 != nil:
    section.add "X-Amz-Security-Token", valid_603681
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603682 = header.getOrDefault("X-Amz-Target")
  valid_603682 = validateParameter(valid_603682, JString, required = true, default = newJString(
      "StarlingDoveService.GetDiscoveredResourceCounts"))
  if valid_603682 != nil:
    section.add "X-Amz-Target", valid_603682
  var valid_603683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603683 = validateParameter(valid_603683, JString, required = false,
                                 default = nil)
  if valid_603683 != nil:
    section.add "X-Amz-Content-Sha256", valid_603683
  var valid_603684 = header.getOrDefault("X-Amz-Algorithm")
  valid_603684 = validateParameter(valid_603684, JString, required = false,
                                 default = nil)
  if valid_603684 != nil:
    section.add "X-Amz-Algorithm", valid_603684
  var valid_603685 = header.getOrDefault("X-Amz-Signature")
  valid_603685 = validateParameter(valid_603685, JString, required = false,
                                 default = nil)
  if valid_603685 != nil:
    section.add "X-Amz-Signature", valid_603685
  var valid_603686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603686 = validateParameter(valid_603686, JString, required = false,
                                 default = nil)
  if valid_603686 != nil:
    section.add "X-Amz-SignedHeaders", valid_603686
  var valid_603687 = header.getOrDefault("X-Amz-Credential")
  valid_603687 = validateParameter(valid_603687, JString, required = false,
                                 default = nil)
  if valid_603687 != nil:
    section.add "X-Amz-Credential", valid_603687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603689: Call_GetDiscoveredResourceCounts_603677; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns the resource types, the number of each resource type, and the total number of resources that AWS Config is recording in this region for your AWS account. </p> <p class="title"> <b>Example</b> </p> <ol> <li> <p>AWS Config is recording three resource types in the US East (Ohio) Region for your account: 25 EC2 instances, 20 IAM users, and 15 S3 buckets.</p> </li> <li> <p>You make a call to the <code>GetDiscoveredResourceCounts</code> action and specify that you want all resource types. </p> </li> <li> <p>AWS Config returns the following:</p> <ul> <li> <p>The resource types (EC2 instances, IAM users, and S3 buckets).</p> </li> <li> <p>The number of each resource type (25, 20, and 15).</p> </li> <li> <p>The total number of all resources (60).</p> </li> </ul> </li> </ol> <p>The response is paginated. By default, AWS Config lists 100 <a>ResourceCount</a> objects on each page. You can customize this number with the <code>limit</code> parameter. The response includes a <code>nextToken</code> string. To get the next page of results, run the request again and specify the string for the <code>nextToken</code> parameter.</p> <note> <p>If you make a call to the <a>GetDiscoveredResourceCounts</a> action, you might not immediately receive resource counts in the following situations:</p> <ul> <li> <p>You are a new AWS Config customer.</p> </li> <li> <p>You just enabled resource recording.</p> </li> </ul> <p>It might take a few minutes for AWS Config to record and count your resources. Wait a few minutes and then retry the <a>GetDiscoveredResourceCounts</a> action. </p> </note>
  ## 
  let valid = call_603689.validator(path, query, header, formData, body)
  let scheme = call_603689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603689.url(scheme.get, call_603689.host, call_603689.base,
                         call_603689.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603689, url, valid)

proc call*(call_603690: Call_GetDiscoveredResourceCounts_603677; body: JsonNode): Recallable =
  ## getDiscoveredResourceCounts
  ## <p>Returns the resource types, the number of each resource type, and the total number of resources that AWS Config is recording in this region for your AWS account. </p> <p class="title"> <b>Example</b> </p> <ol> <li> <p>AWS Config is recording three resource types in the US East (Ohio) Region for your account: 25 EC2 instances, 20 IAM users, and 15 S3 buckets.</p> </li> <li> <p>You make a call to the <code>GetDiscoveredResourceCounts</code> action and specify that you want all resource types. </p> </li> <li> <p>AWS Config returns the following:</p> <ul> <li> <p>The resource types (EC2 instances, IAM users, and S3 buckets).</p> </li> <li> <p>The number of each resource type (25, 20, and 15).</p> </li> <li> <p>The total number of all resources (60).</p> </li> </ul> </li> </ol> <p>The response is paginated. By default, AWS Config lists 100 <a>ResourceCount</a> objects on each page. You can customize this number with the <code>limit</code> parameter. The response includes a <code>nextToken</code> string. To get the next page of results, run the request again and specify the string for the <code>nextToken</code> parameter.</p> <note> <p>If you make a call to the <a>GetDiscoveredResourceCounts</a> action, you might not immediately receive resource counts in the following situations:</p> <ul> <li> <p>You are a new AWS Config customer.</p> </li> <li> <p>You just enabled resource recording.</p> </li> </ul> <p>It might take a few minutes for AWS Config to record and count your resources. Wait a few minutes and then retry the <a>GetDiscoveredResourceCounts</a> action. </p> </note>
  ##   body: JObject (required)
  var body_603691 = newJObject()
  if body != nil:
    body_603691 = body
  result = call_603690.call(nil, nil, nil, nil, body_603691)

var getDiscoveredResourceCounts* = Call_GetDiscoveredResourceCounts_603677(
    name: "getDiscoveredResourceCounts", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.GetDiscoveredResourceCounts",
    validator: validate_GetDiscoveredResourceCounts_603678, base: "/",
    url: url_GetDiscoveredResourceCounts_603679,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOrganizationConfigRuleDetailedStatus_603692 = ref object of OpenApiRestCall_602466
proc url_GetOrganizationConfigRuleDetailedStatus_603694(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetOrganizationConfigRuleDetailedStatus_603693(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns detailed status for each member account within an organization for a given organization config rule.</p> <note> <p>Only a master account can call this API.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603695 = header.getOrDefault("X-Amz-Date")
  valid_603695 = validateParameter(valid_603695, JString, required = false,
                                 default = nil)
  if valid_603695 != nil:
    section.add "X-Amz-Date", valid_603695
  var valid_603696 = header.getOrDefault("X-Amz-Security-Token")
  valid_603696 = validateParameter(valid_603696, JString, required = false,
                                 default = nil)
  if valid_603696 != nil:
    section.add "X-Amz-Security-Token", valid_603696
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603697 = header.getOrDefault("X-Amz-Target")
  valid_603697 = validateParameter(valid_603697, JString, required = true, default = newJString(
      "StarlingDoveService.GetOrganizationConfigRuleDetailedStatus"))
  if valid_603697 != nil:
    section.add "X-Amz-Target", valid_603697
  var valid_603698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603698 = validateParameter(valid_603698, JString, required = false,
                                 default = nil)
  if valid_603698 != nil:
    section.add "X-Amz-Content-Sha256", valid_603698
  var valid_603699 = header.getOrDefault("X-Amz-Algorithm")
  valid_603699 = validateParameter(valid_603699, JString, required = false,
                                 default = nil)
  if valid_603699 != nil:
    section.add "X-Amz-Algorithm", valid_603699
  var valid_603700 = header.getOrDefault("X-Amz-Signature")
  valid_603700 = validateParameter(valid_603700, JString, required = false,
                                 default = nil)
  if valid_603700 != nil:
    section.add "X-Amz-Signature", valid_603700
  var valid_603701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603701 = validateParameter(valid_603701, JString, required = false,
                                 default = nil)
  if valid_603701 != nil:
    section.add "X-Amz-SignedHeaders", valid_603701
  var valid_603702 = header.getOrDefault("X-Amz-Credential")
  valid_603702 = validateParameter(valid_603702, JString, required = false,
                                 default = nil)
  if valid_603702 != nil:
    section.add "X-Amz-Credential", valid_603702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603704: Call_GetOrganizationConfigRuleDetailedStatus_603692;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Returns detailed status for each member account within an organization for a given organization config rule.</p> <note> <p>Only a master account can call this API.</p> </note>
  ## 
  let valid = call_603704.validator(path, query, header, formData, body)
  let scheme = call_603704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603704.url(scheme.get, call_603704.host, call_603704.base,
                         call_603704.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603704, url, valid)

proc call*(call_603705: Call_GetOrganizationConfigRuleDetailedStatus_603692;
          body: JsonNode): Recallable =
  ## getOrganizationConfigRuleDetailedStatus
  ## <p>Returns detailed status for each member account within an organization for a given organization config rule.</p> <note> <p>Only a master account can call this API.</p> </note>
  ##   body: JObject (required)
  var body_603706 = newJObject()
  if body != nil:
    body_603706 = body
  result = call_603705.call(nil, nil, nil, nil, body_603706)

var getOrganizationConfigRuleDetailedStatus* = Call_GetOrganizationConfigRuleDetailedStatus_603692(
    name: "getOrganizationConfigRuleDetailedStatus", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.GetOrganizationConfigRuleDetailedStatus",
    validator: validate_GetOrganizationConfigRuleDetailedStatus_603693, base: "/",
    url: url_GetOrganizationConfigRuleDetailedStatus_603694,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResourceConfigHistory_603707 = ref object of OpenApiRestCall_602466
proc url_GetResourceConfigHistory_603709(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResourceConfigHistory_603708(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of configuration items for the specified resource. The list contains details about each state of the resource during the specified time interval. If you specified a retention period to retain your <code>ConfigurationItems</code> between a minimum of 30 days and a maximum of 7 years (2557 days), AWS Config returns the <code>ConfigurationItems</code> for the specified retention period. </p> <p>The response is paginated. By default, AWS Config returns a limit of 10 configuration items per page. You can customize this number with the <code>limit</code> parameter. The response includes a <code>nextToken</code> string. To get the next page of results, run the request again and specify the string for the <code>nextToken</code> parameter.</p> <note> <p>Each call to the API is limited to span a duration of seven days. It is likely that the number of records returned is smaller than the specified <code>limit</code>. In such cases, you can make another call, using the <code>nextToken</code>.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   limit: JString
  ##        : Pagination limit
  section = newJObject()
  var valid_603710 = query.getOrDefault("nextToken")
  valid_603710 = validateParameter(valid_603710, JString, required = false,
                                 default = nil)
  if valid_603710 != nil:
    section.add "nextToken", valid_603710
  var valid_603711 = query.getOrDefault("limit")
  valid_603711 = validateParameter(valid_603711, JString, required = false,
                                 default = nil)
  if valid_603711 != nil:
    section.add "limit", valid_603711
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603712 = header.getOrDefault("X-Amz-Date")
  valid_603712 = validateParameter(valid_603712, JString, required = false,
                                 default = nil)
  if valid_603712 != nil:
    section.add "X-Amz-Date", valid_603712
  var valid_603713 = header.getOrDefault("X-Amz-Security-Token")
  valid_603713 = validateParameter(valid_603713, JString, required = false,
                                 default = nil)
  if valid_603713 != nil:
    section.add "X-Amz-Security-Token", valid_603713
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603714 = header.getOrDefault("X-Amz-Target")
  valid_603714 = validateParameter(valid_603714, JString, required = true, default = newJString(
      "StarlingDoveService.GetResourceConfigHistory"))
  if valid_603714 != nil:
    section.add "X-Amz-Target", valid_603714
  var valid_603715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603715 = validateParameter(valid_603715, JString, required = false,
                                 default = nil)
  if valid_603715 != nil:
    section.add "X-Amz-Content-Sha256", valid_603715
  var valid_603716 = header.getOrDefault("X-Amz-Algorithm")
  valid_603716 = validateParameter(valid_603716, JString, required = false,
                                 default = nil)
  if valid_603716 != nil:
    section.add "X-Amz-Algorithm", valid_603716
  var valid_603717 = header.getOrDefault("X-Amz-Signature")
  valid_603717 = validateParameter(valid_603717, JString, required = false,
                                 default = nil)
  if valid_603717 != nil:
    section.add "X-Amz-Signature", valid_603717
  var valid_603718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603718 = validateParameter(valid_603718, JString, required = false,
                                 default = nil)
  if valid_603718 != nil:
    section.add "X-Amz-SignedHeaders", valid_603718
  var valid_603719 = header.getOrDefault("X-Amz-Credential")
  valid_603719 = validateParameter(valid_603719, JString, required = false,
                                 default = nil)
  if valid_603719 != nil:
    section.add "X-Amz-Credential", valid_603719
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603721: Call_GetResourceConfigHistory_603707; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of configuration items for the specified resource. The list contains details about each state of the resource during the specified time interval. If you specified a retention period to retain your <code>ConfigurationItems</code> between a minimum of 30 days and a maximum of 7 years (2557 days), AWS Config returns the <code>ConfigurationItems</code> for the specified retention period. </p> <p>The response is paginated. By default, AWS Config returns a limit of 10 configuration items per page. You can customize this number with the <code>limit</code> parameter. The response includes a <code>nextToken</code> string. To get the next page of results, run the request again and specify the string for the <code>nextToken</code> parameter.</p> <note> <p>Each call to the API is limited to span a duration of seven days. It is likely that the number of records returned is smaller than the specified <code>limit</code>. In such cases, you can make another call, using the <code>nextToken</code>.</p> </note>
  ## 
  let valid = call_603721.validator(path, query, header, formData, body)
  let scheme = call_603721.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603721.url(scheme.get, call_603721.host, call_603721.base,
                         call_603721.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603721, url, valid)

proc call*(call_603722: Call_GetResourceConfigHistory_603707; body: JsonNode;
          nextToken: string = ""; limit: string = ""): Recallable =
  ## getResourceConfigHistory
  ## <p>Returns a list of configuration items for the specified resource. The list contains details about each state of the resource during the specified time interval. If you specified a retention period to retain your <code>ConfigurationItems</code> between a minimum of 30 days and a maximum of 7 years (2557 days), AWS Config returns the <code>ConfigurationItems</code> for the specified retention period. </p> <p>The response is paginated. By default, AWS Config returns a limit of 10 configuration items per page. You can customize this number with the <code>limit</code> parameter. The response includes a <code>nextToken</code> string. To get the next page of results, run the request again and specify the string for the <code>nextToken</code> parameter.</p> <note> <p>Each call to the API is limited to span a duration of seven days. It is likely that the number of records returned is smaller than the specified <code>limit</code>. In such cases, you can make another call, using the <code>nextToken</code>.</p> </note>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   limit: string
  ##        : Pagination limit
  var query_603723 = newJObject()
  var body_603724 = newJObject()
  add(query_603723, "nextToken", newJString(nextToken))
  if body != nil:
    body_603724 = body
  add(query_603723, "limit", newJString(limit))
  result = call_603722.call(nil, query_603723, nil, nil, body_603724)

var getResourceConfigHistory* = Call_GetResourceConfigHistory_603707(
    name: "getResourceConfigHistory", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.GetResourceConfigHistory",
    validator: validate_GetResourceConfigHistory_603708, base: "/",
    url: url_GetResourceConfigHistory_603709, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAggregateDiscoveredResources_603725 = ref object of OpenApiRestCall_602466
proc url_ListAggregateDiscoveredResources_603727(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListAggregateDiscoveredResources_603726(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Accepts a resource type and returns a list of resource identifiers that are aggregated for a specific resource type across accounts and regions. A resource identifier includes the resource type, ID, (if available) the custom resource name, source account, and source region. You can narrow the results to include only resources that have specific resource IDs, or a resource name, or source account ID, or source region.</p> <p>For example, if the input consists of accountID 12345678910 and the region is us-east-1 for resource type <code>AWS::EC2::Instance</code> then the API returns all the EC2 instance identifiers of accountID 12345678910 and region us-east-1.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603728 = header.getOrDefault("X-Amz-Date")
  valid_603728 = validateParameter(valid_603728, JString, required = false,
                                 default = nil)
  if valid_603728 != nil:
    section.add "X-Amz-Date", valid_603728
  var valid_603729 = header.getOrDefault("X-Amz-Security-Token")
  valid_603729 = validateParameter(valid_603729, JString, required = false,
                                 default = nil)
  if valid_603729 != nil:
    section.add "X-Amz-Security-Token", valid_603729
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603730 = header.getOrDefault("X-Amz-Target")
  valid_603730 = validateParameter(valid_603730, JString, required = true, default = newJString(
      "StarlingDoveService.ListAggregateDiscoveredResources"))
  if valid_603730 != nil:
    section.add "X-Amz-Target", valid_603730
  var valid_603731 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603731 = validateParameter(valid_603731, JString, required = false,
                                 default = nil)
  if valid_603731 != nil:
    section.add "X-Amz-Content-Sha256", valid_603731
  var valid_603732 = header.getOrDefault("X-Amz-Algorithm")
  valid_603732 = validateParameter(valid_603732, JString, required = false,
                                 default = nil)
  if valid_603732 != nil:
    section.add "X-Amz-Algorithm", valid_603732
  var valid_603733 = header.getOrDefault("X-Amz-Signature")
  valid_603733 = validateParameter(valid_603733, JString, required = false,
                                 default = nil)
  if valid_603733 != nil:
    section.add "X-Amz-Signature", valid_603733
  var valid_603734 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603734 = validateParameter(valid_603734, JString, required = false,
                                 default = nil)
  if valid_603734 != nil:
    section.add "X-Amz-SignedHeaders", valid_603734
  var valid_603735 = header.getOrDefault("X-Amz-Credential")
  valid_603735 = validateParameter(valid_603735, JString, required = false,
                                 default = nil)
  if valid_603735 != nil:
    section.add "X-Amz-Credential", valid_603735
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603737: Call_ListAggregateDiscoveredResources_603725;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Accepts a resource type and returns a list of resource identifiers that are aggregated for a specific resource type across accounts and regions. A resource identifier includes the resource type, ID, (if available) the custom resource name, source account, and source region. You can narrow the results to include only resources that have specific resource IDs, or a resource name, or source account ID, or source region.</p> <p>For example, if the input consists of accountID 12345678910 and the region is us-east-1 for resource type <code>AWS::EC2::Instance</code> then the API returns all the EC2 instance identifiers of accountID 12345678910 and region us-east-1.</p>
  ## 
  let valid = call_603737.validator(path, query, header, formData, body)
  let scheme = call_603737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603737.url(scheme.get, call_603737.host, call_603737.base,
                         call_603737.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603737, url, valid)

proc call*(call_603738: Call_ListAggregateDiscoveredResources_603725;
          body: JsonNode): Recallable =
  ## listAggregateDiscoveredResources
  ## <p>Accepts a resource type and returns a list of resource identifiers that are aggregated for a specific resource type across accounts and regions. A resource identifier includes the resource type, ID, (if available) the custom resource name, source account, and source region. You can narrow the results to include only resources that have specific resource IDs, or a resource name, or source account ID, or source region.</p> <p>For example, if the input consists of accountID 12345678910 and the region is us-east-1 for resource type <code>AWS::EC2::Instance</code> then the API returns all the EC2 instance identifiers of accountID 12345678910 and region us-east-1.</p>
  ##   body: JObject (required)
  var body_603739 = newJObject()
  if body != nil:
    body_603739 = body
  result = call_603738.call(nil, nil, nil, nil, body_603739)

var listAggregateDiscoveredResources* = Call_ListAggregateDiscoveredResources_603725(
    name: "listAggregateDiscoveredResources", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.ListAggregateDiscoveredResources",
    validator: validate_ListAggregateDiscoveredResources_603726, base: "/",
    url: url_ListAggregateDiscoveredResources_603727,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDiscoveredResources_603740 = ref object of OpenApiRestCall_602466
proc url_ListDiscoveredResources_603742(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDiscoveredResources_603741(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Accepts a resource type and returns a list of resource identifiers for the resources of that type. A resource identifier includes the resource type, ID, and (if available) the custom resource name. The results consist of resources that AWS Config has discovered, including those that AWS Config is not currently recording. You can narrow the results to include only resources that have specific resource IDs or a resource name.</p> <note> <p>You can specify either resource IDs or a resource name, but not both, in the same request.</p> </note> <p>The response is paginated. By default, AWS Config lists 100 resource identifiers on each page. You can customize this number with the <code>limit</code> parameter. The response includes a <code>nextToken</code> string. To get the next page of results, run the request again and specify the string for the <code>nextToken</code> parameter.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603743 = header.getOrDefault("X-Amz-Date")
  valid_603743 = validateParameter(valid_603743, JString, required = false,
                                 default = nil)
  if valid_603743 != nil:
    section.add "X-Amz-Date", valid_603743
  var valid_603744 = header.getOrDefault("X-Amz-Security-Token")
  valid_603744 = validateParameter(valid_603744, JString, required = false,
                                 default = nil)
  if valid_603744 != nil:
    section.add "X-Amz-Security-Token", valid_603744
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603745 = header.getOrDefault("X-Amz-Target")
  valid_603745 = validateParameter(valid_603745, JString, required = true, default = newJString(
      "StarlingDoveService.ListDiscoveredResources"))
  if valid_603745 != nil:
    section.add "X-Amz-Target", valid_603745
  var valid_603746 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603746 = validateParameter(valid_603746, JString, required = false,
                                 default = nil)
  if valid_603746 != nil:
    section.add "X-Amz-Content-Sha256", valid_603746
  var valid_603747 = header.getOrDefault("X-Amz-Algorithm")
  valid_603747 = validateParameter(valid_603747, JString, required = false,
                                 default = nil)
  if valid_603747 != nil:
    section.add "X-Amz-Algorithm", valid_603747
  var valid_603748 = header.getOrDefault("X-Amz-Signature")
  valid_603748 = validateParameter(valid_603748, JString, required = false,
                                 default = nil)
  if valid_603748 != nil:
    section.add "X-Amz-Signature", valid_603748
  var valid_603749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603749 = validateParameter(valid_603749, JString, required = false,
                                 default = nil)
  if valid_603749 != nil:
    section.add "X-Amz-SignedHeaders", valid_603749
  var valid_603750 = header.getOrDefault("X-Amz-Credential")
  valid_603750 = validateParameter(valid_603750, JString, required = false,
                                 default = nil)
  if valid_603750 != nil:
    section.add "X-Amz-Credential", valid_603750
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603752: Call_ListDiscoveredResources_603740; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Accepts a resource type and returns a list of resource identifiers for the resources of that type. A resource identifier includes the resource type, ID, and (if available) the custom resource name. The results consist of resources that AWS Config has discovered, including those that AWS Config is not currently recording. You can narrow the results to include only resources that have specific resource IDs or a resource name.</p> <note> <p>You can specify either resource IDs or a resource name, but not both, in the same request.</p> </note> <p>The response is paginated. By default, AWS Config lists 100 resource identifiers on each page. You can customize this number with the <code>limit</code> parameter. The response includes a <code>nextToken</code> string. To get the next page of results, run the request again and specify the string for the <code>nextToken</code> parameter.</p>
  ## 
  let valid = call_603752.validator(path, query, header, formData, body)
  let scheme = call_603752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603752.url(scheme.get, call_603752.host, call_603752.base,
                         call_603752.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603752, url, valid)

proc call*(call_603753: Call_ListDiscoveredResources_603740; body: JsonNode): Recallable =
  ## listDiscoveredResources
  ## <p>Accepts a resource type and returns a list of resource identifiers for the resources of that type. A resource identifier includes the resource type, ID, and (if available) the custom resource name. The results consist of resources that AWS Config has discovered, including those that AWS Config is not currently recording. You can narrow the results to include only resources that have specific resource IDs or a resource name.</p> <note> <p>You can specify either resource IDs or a resource name, but not both, in the same request.</p> </note> <p>The response is paginated. By default, AWS Config lists 100 resource identifiers on each page. You can customize this number with the <code>limit</code> parameter. The response includes a <code>nextToken</code> string. To get the next page of results, run the request again and specify the string for the <code>nextToken</code> parameter.</p>
  ##   body: JObject (required)
  var body_603754 = newJObject()
  if body != nil:
    body_603754 = body
  result = call_603753.call(nil, nil, nil, nil, body_603754)

var listDiscoveredResources* = Call_ListDiscoveredResources_603740(
    name: "listDiscoveredResources", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.ListDiscoveredResources",
    validator: validate_ListDiscoveredResources_603741, base: "/",
    url: url_ListDiscoveredResources_603742, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_603755 = ref object of OpenApiRestCall_602466
proc url_ListTagsForResource_603757(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListTagsForResource_603756(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## List the tags for AWS Config resource.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603758 = header.getOrDefault("X-Amz-Date")
  valid_603758 = validateParameter(valid_603758, JString, required = false,
                                 default = nil)
  if valid_603758 != nil:
    section.add "X-Amz-Date", valid_603758
  var valid_603759 = header.getOrDefault("X-Amz-Security-Token")
  valid_603759 = validateParameter(valid_603759, JString, required = false,
                                 default = nil)
  if valid_603759 != nil:
    section.add "X-Amz-Security-Token", valid_603759
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603760 = header.getOrDefault("X-Amz-Target")
  valid_603760 = validateParameter(valid_603760, JString, required = true, default = newJString(
      "StarlingDoveService.ListTagsForResource"))
  if valid_603760 != nil:
    section.add "X-Amz-Target", valid_603760
  var valid_603761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603761 = validateParameter(valid_603761, JString, required = false,
                                 default = nil)
  if valid_603761 != nil:
    section.add "X-Amz-Content-Sha256", valid_603761
  var valid_603762 = header.getOrDefault("X-Amz-Algorithm")
  valid_603762 = validateParameter(valid_603762, JString, required = false,
                                 default = nil)
  if valid_603762 != nil:
    section.add "X-Amz-Algorithm", valid_603762
  var valid_603763 = header.getOrDefault("X-Amz-Signature")
  valid_603763 = validateParameter(valid_603763, JString, required = false,
                                 default = nil)
  if valid_603763 != nil:
    section.add "X-Amz-Signature", valid_603763
  var valid_603764 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603764 = validateParameter(valid_603764, JString, required = false,
                                 default = nil)
  if valid_603764 != nil:
    section.add "X-Amz-SignedHeaders", valid_603764
  var valid_603765 = header.getOrDefault("X-Amz-Credential")
  valid_603765 = validateParameter(valid_603765, JString, required = false,
                                 default = nil)
  if valid_603765 != nil:
    section.add "X-Amz-Credential", valid_603765
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603767: Call_ListTagsForResource_603755; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the tags for AWS Config resource.
  ## 
  let valid = call_603767.validator(path, query, header, formData, body)
  let scheme = call_603767.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603767.url(scheme.get, call_603767.host, call_603767.base,
                         call_603767.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603767, url, valid)

proc call*(call_603768: Call_ListTagsForResource_603755; body: JsonNode): Recallable =
  ## listTagsForResource
  ## List the tags for AWS Config resource.
  ##   body: JObject (required)
  var body_603769 = newJObject()
  if body != nil:
    body_603769 = body
  result = call_603768.call(nil, nil, nil, nil, body_603769)

var listTagsForResource* = Call_ListTagsForResource_603755(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.ListTagsForResource",
    validator: validate_ListTagsForResource_603756, base: "/",
    url: url_ListTagsForResource_603757, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAggregationAuthorization_603770 = ref object of OpenApiRestCall_602466
proc url_PutAggregationAuthorization_603772(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutAggregationAuthorization_603771(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Authorizes the aggregator account and region to collect data from the source account and region. 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603773 = header.getOrDefault("X-Amz-Date")
  valid_603773 = validateParameter(valid_603773, JString, required = false,
                                 default = nil)
  if valid_603773 != nil:
    section.add "X-Amz-Date", valid_603773
  var valid_603774 = header.getOrDefault("X-Amz-Security-Token")
  valid_603774 = validateParameter(valid_603774, JString, required = false,
                                 default = nil)
  if valid_603774 != nil:
    section.add "X-Amz-Security-Token", valid_603774
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603775 = header.getOrDefault("X-Amz-Target")
  valid_603775 = validateParameter(valid_603775, JString, required = true, default = newJString(
      "StarlingDoveService.PutAggregationAuthorization"))
  if valid_603775 != nil:
    section.add "X-Amz-Target", valid_603775
  var valid_603776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603776 = validateParameter(valid_603776, JString, required = false,
                                 default = nil)
  if valid_603776 != nil:
    section.add "X-Amz-Content-Sha256", valid_603776
  var valid_603777 = header.getOrDefault("X-Amz-Algorithm")
  valid_603777 = validateParameter(valid_603777, JString, required = false,
                                 default = nil)
  if valid_603777 != nil:
    section.add "X-Amz-Algorithm", valid_603777
  var valid_603778 = header.getOrDefault("X-Amz-Signature")
  valid_603778 = validateParameter(valid_603778, JString, required = false,
                                 default = nil)
  if valid_603778 != nil:
    section.add "X-Amz-Signature", valid_603778
  var valid_603779 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603779 = validateParameter(valid_603779, JString, required = false,
                                 default = nil)
  if valid_603779 != nil:
    section.add "X-Amz-SignedHeaders", valid_603779
  var valid_603780 = header.getOrDefault("X-Amz-Credential")
  valid_603780 = validateParameter(valid_603780, JString, required = false,
                                 default = nil)
  if valid_603780 != nil:
    section.add "X-Amz-Credential", valid_603780
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603782: Call_PutAggregationAuthorization_603770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Authorizes the aggregator account and region to collect data from the source account and region. 
  ## 
  let valid = call_603782.validator(path, query, header, formData, body)
  let scheme = call_603782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603782.url(scheme.get, call_603782.host, call_603782.base,
                         call_603782.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603782, url, valid)

proc call*(call_603783: Call_PutAggregationAuthorization_603770; body: JsonNode): Recallable =
  ## putAggregationAuthorization
  ## Authorizes the aggregator account and region to collect data from the source account and region. 
  ##   body: JObject (required)
  var body_603784 = newJObject()
  if body != nil:
    body_603784 = body
  result = call_603783.call(nil, nil, nil, nil, body_603784)

var putAggregationAuthorization* = Call_PutAggregationAuthorization_603770(
    name: "putAggregationAuthorization", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutAggregationAuthorization",
    validator: validate_PutAggregationAuthorization_603771, base: "/",
    url: url_PutAggregationAuthorization_603772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigRule_603785 = ref object of OpenApiRestCall_602466
proc url_PutConfigRule_603787(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutConfigRule_603786(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds or updates an AWS Config rule for evaluating whether your AWS resources comply with your desired configurations.</p> <p>You can use this action for custom AWS Config rules and AWS managed Config rules. A custom AWS Config rule is a rule that you develop and maintain. An AWS managed Config rule is a customizable, predefined rule that AWS Config provides.</p> <p>If you are adding a new custom AWS Config rule, you must first create the AWS Lambda function that the rule invokes to evaluate your resources. When you use the <code>PutConfigRule</code> action to add the rule to AWS Config, you must specify the Amazon Resource Name (ARN) that AWS Lambda assigns to the function. Specify the ARN for the <code>SourceIdentifier</code> key. This key is part of the <code>Source</code> object, which is part of the <code>ConfigRule</code> object. </p> <p>If you are adding an AWS managed Config rule, specify the rule's identifier for the <code>SourceIdentifier</code> key. To reference AWS managed Config rule identifiers, see <a href="https://docs.aws.amazon.com/config/latest/developerguide/evaluate-config_use-managed-rules.html">About AWS Managed Config Rules</a>.</p> <p>For any new rule that you add, specify the <code>ConfigRuleName</code> in the <code>ConfigRule</code> object. Do not specify the <code>ConfigRuleArn</code> or the <code>ConfigRuleId</code>. These values are generated by AWS Config for new rules.</p> <p>If you are updating a rule that you added previously, you can specify the rule by <code>ConfigRuleName</code>, <code>ConfigRuleId</code>, or <code>ConfigRuleArn</code> in the <code>ConfigRule</code> data type that you use in this request.</p> <p>The maximum number of rules that AWS Config supports is 150.</p> <p>For information about requesting a rule limit increase, see <a href="http://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits_config">AWS Config Limits</a> in the <i>AWS General Reference Guide</i>.</p> <p>For more information about developing and using AWS Config rules, see <a href="https://docs.aws.amazon.com/config/latest/developerguide/evaluate-config.html">Evaluating AWS Resource Configurations with AWS Config</a> in the <i>AWS Config Developer Guide</i>.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603788 = header.getOrDefault("X-Amz-Date")
  valid_603788 = validateParameter(valid_603788, JString, required = false,
                                 default = nil)
  if valid_603788 != nil:
    section.add "X-Amz-Date", valid_603788
  var valid_603789 = header.getOrDefault("X-Amz-Security-Token")
  valid_603789 = validateParameter(valid_603789, JString, required = false,
                                 default = nil)
  if valid_603789 != nil:
    section.add "X-Amz-Security-Token", valid_603789
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603790 = header.getOrDefault("X-Amz-Target")
  valid_603790 = validateParameter(valid_603790, JString, required = true, default = newJString(
      "StarlingDoveService.PutConfigRule"))
  if valid_603790 != nil:
    section.add "X-Amz-Target", valid_603790
  var valid_603791 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603791 = validateParameter(valid_603791, JString, required = false,
                                 default = nil)
  if valid_603791 != nil:
    section.add "X-Amz-Content-Sha256", valid_603791
  var valid_603792 = header.getOrDefault("X-Amz-Algorithm")
  valid_603792 = validateParameter(valid_603792, JString, required = false,
                                 default = nil)
  if valid_603792 != nil:
    section.add "X-Amz-Algorithm", valid_603792
  var valid_603793 = header.getOrDefault("X-Amz-Signature")
  valid_603793 = validateParameter(valid_603793, JString, required = false,
                                 default = nil)
  if valid_603793 != nil:
    section.add "X-Amz-Signature", valid_603793
  var valid_603794 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603794 = validateParameter(valid_603794, JString, required = false,
                                 default = nil)
  if valid_603794 != nil:
    section.add "X-Amz-SignedHeaders", valid_603794
  var valid_603795 = header.getOrDefault("X-Amz-Credential")
  valid_603795 = validateParameter(valid_603795, JString, required = false,
                                 default = nil)
  if valid_603795 != nil:
    section.add "X-Amz-Credential", valid_603795
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603797: Call_PutConfigRule_603785; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or updates an AWS Config rule for evaluating whether your AWS resources comply with your desired configurations.</p> <p>You can use this action for custom AWS Config rules and AWS managed Config rules. A custom AWS Config rule is a rule that you develop and maintain. An AWS managed Config rule is a customizable, predefined rule that AWS Config provides.</p> <p>If you are adding a new custom AWS Config rule, you must first create the AWS Lambda function that the rule invokes to evaluate your resources. When you use the <code>PutConfigRule</code> action to add the rule to AWS Config, you must specify the Amazon Resource Name (ARN) that AWS Lambda assigns to the function. Specify the ARN for the <code>SourceIdentifier</code> key. This key is part of the <code>Source</code> object, which is part of the <code>ConfigRule</code> object. </p> <p>If you are adding an AWS managed Config rule, specify the rule's identifier for the <code>SourceIdentifier</code> key. To reference AWS managed Config rule identifiers, see <a href="https://docs.aws.amazon.com/config/latest/developerguide/evaluate-config_use-managed-rules.html">About AWS Managed Config Rules</a>.</p> <p>For any new rule that you add, specify the <code>ConfigRuleName</code> in the <code>ConfigRule</code> object. Do not specify the <code>ConfigRuleArn</code> or the <code>ConfigRuleId</code>. These values are generated by AWS Config for new rules.</p> <p>If you are updating a rule that you added previously, you can specify the rule by <code>ConfigRuleName</code>, <code>ConfigRuleId</code>, or <code>ConfigRuleArn</code> in the <code>ConfigRule</code> data type that you use in this request.</p> <p>The maximum number of rules that AWS Config supports is 150.</p> <p>For information about requesting a rule limit increase, see <a href="http://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits_config">AWS Config Limits</a> in the <i>AWS General Reference Guide</i>.</p> <p>For more information about developing and using AWS Config rules, see <a href="https://docs.aws.amazon.com/config/latest/developerguide/evaluate-config.html">Evaluating AWS Resource Configurations with AWS Config</a> in the <i>AWS Config Developer Guide</i>.</p>
  ## 
  let valid = call_603797.validator(path, query, header, formData, body)
  let scheme = call_603797.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603797.url(scheme.get, call_603797.host, call_603797.base,
                         call_603797.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603797, url, valid)

proc call*(call_603798: Call_PutConfigRule_603785; body: JsonNode): Recallable =
  ## putConfigRule
  ## <p>Adds or updates an AWS Config rule for evaluating whether your AWS resources comply with your desired configurations.</p> <p>You can use this action for custom AWS Config rules and AWS managed Config rules. A custom AWS Config rule is a rule that you develop and maintain. An AWS managed Config rule is a customizable, predefined rule that AWS Config provides.</p> <p>If you are adding a new custom AWS Config rule, you must first create the AWS Lambda function that the rule invokes to evaluate your resources. When you use the <code>PutConfigRule</code> action to add the rule to AWS Config, you must specify the Amazon Resource Name (ARN) that AWS Lambda assigns to the function. Specify the ARN for the <code>SourceIdentifier</code> key. This key is part of the <code>Source</code> object, which is part of the <code>ConfigRule</code> object. </p> <p>If you are adding an AWS managed Config rule, specify the rule's identifier for the <code>SourceIdentifier</code> key. To reference AWS managed Config rule identifiers, see <a href="https://docs.aws.amazon.com/config/latest/developerguide/evaluate-config_use-managed-rules.html">About AWS Managed Config Rules</a>.</p> <p>For any new rule that you add, specify the <code>ConfigRuleName</code> in the <code>ConfigRule</code> object. Do not specify the <code>ConfigRuleArn</code> or the <code>ConfigRuleId</code>. These values are generated by AWS Config for new rules.</p> <p>If you are updating a rule that you added previously, you can specify the rule by <code>ConfigRuleName</code>, <code>ConfigRuleId</code>, or <code>ConfigRuleArn</code> in the <code>ConfigRule</code> data type that you use in this request.</p> <p>The maximum number of rules that AWS Config supports is 150.</p> <p>For information about requesting a rule limit increase, see <a href="http://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits_config">AWS Config Limits</a> in the <i>AWS General Reference Guide</i>.</p> <p>For more information about developing and using AWS Config rules, see <a href="https://docs.aws.amazon.com/config/latest/developerguide/evaluate-config.html">Evaluating AWS Resource Configurations with AWS Config</a> in the <i>AWS Config Developer Guide</i>.</p>
  ##   body: JObject (required)
  var body_603799 = newJObject()
  if body != nil:
    body_603799 = body
  result = call_603798.call(nil, nil, nil, nil, body_603799)

var putConfigRule* = Call_PutConfigRule_603785(name: "putConfigRule",
    meth: HttpMethod.HttpPost, host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutConfigRule",
    validator: validate_PutConfigRule_603786, base: "/", url: url_PutConfigRule_603787,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationAggregator_603800 = ref object of OpenApiRestCall_602466
proc url_PutConfigurationAggregator_603802(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutConfigurationAggregator_603801(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates and updates the configuration aggregator with the selected source accounts and regions. The source account can be individual account(s) or an organization.</p> <note> <p>AWS Config should be enabled in source accounts and regions you want to aggregate.</p> <p>If your source type is an organization, you must be signed in to the master account and all features must be enabled in your organization. AWS Config calls <code>EnableAwsServiceAccess</code> API to enable integration between AWS Config and AWS Organizations. </p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603803 = header.getOrDefault("X-Amz-Date")
  valid_603803 = validateParameter(valid_603803, JString, required = false,
                                 default = nil)
  if valid_603803 != nil:
    section.add "X-Amz-Date", valid_603803
  var valid_603804 = header.getOrDefault("X-Amz-Security-Token")
  valid_603804 = validateParameter(valid_603804, JString, required = false,
                                 default = nil)
  if valid_603804 != nil:
    section.add "X-Amz-Security-Token", valid_603804
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603805 = header.getOrDefault("X-Amz-Target")
  valid_603805 = validateParameter(valid_603805, JString, required = true, default = newJString(
      "StarlingDoveService.PutConfigurationAggregator"))
  if valid_603805 != nil:
    section.add "X-Amz-Target", valid_603805
  var valid_603806 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603806 = validateParameter(valid_603806, JString, required = false,
                                 default = nil)
  if valid_603806 != nil:
    section.add "X-Amz-Content-Sha256", valid_603806
  var valid_603807 = header.getOrDefault("X-Amz-Algorithm")
  valid_603807 = validateParameter(valid_603807, JString, required = false,
                                 default = nil)
  if valid_603807 != nil:
    section.add "X-Amz-Algorithm", valid_603807
  var valid_603808 = header.getOrDefault("X-Amz-Signature")
  valid_603808 = validateParameter(valid_603808, JString, required = false,
                                 default = nil)
  if valid_603808 != nil:
    section.add "X-Amz-Signature", valid_603808
  var valid_603809 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603809 = validateParameter(valid_603809, JString, required = false,
                                 default = nil)
  if valid_603809 != nil:
    section.add "X-Amz-SignedHeaders", valid_603809
  var valid_603810 = header.getOrDefault("X-Amz-Credential")
  valid_603810 = validateParameter(valid_603810, JString, required = false,
                                 default = nil)
  if valid_603810 != nil:
    section.add "X-Amz-Credential", valid_603810
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603812: Call_PutConfigurationAggregator_603800; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates and updates the configuration aggregator with the selected source accounts and regions. The source account can be individual account(s) or an organization.</p> <note> <p>AWS Config should be enabled in source accounts and regions you want to aggregate.</p> <p>If your source type is an organization, you must be signed in to the master account and all features must be enabled in your organization. AWS Config calls <code>EnableAwsServiceAccess</code> API to enable integration between AWS Config and AWS Organizations. </p> </note>
  ## 
  let valid = call_603812.validator(path, query, header, formData, body)
  let scheme = call_603812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603812.url(scheme.get, call_603812.host, call_603812.base,
                         call_603812.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603812, url, valid)

proc call*(call_603813: Call_PutConfigurationAggregator_603800; body: JsonNode): Recallable =
  ## putConfigurationAggregator
  ## <p>Creates and updates the configuration aggregator with the selected source accounts and regions. The source account can be individual account(s) or an organization.</p> <note> <p>AWS Config should be enabled in source accounts and regions you want to aggregate.</p> <p>If your source type is an organization, you must be signed in to the master account and all features must be enabled in your organization. AWS Config calls <code>EnableAwsServiceAccess</code> API to enable integration between AWS Config and AWS Organizations. </p> </note>
  ##   body: JObject (required)
  var body_603814 = newJObject()
  if body != nil:
    body_603814 = body
  result = call_603813.call(nil, nil, nil, nil, body_603814)

var putConfigurationAggregator* = Call_PutConfigurationAggregator_603800(
    name: "putConfigurationAggregator", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutConfigurationAggregator",
    validator: validate_PutConfigurationAggregator_603801, base: "/",
    url: url_PutConfigurationAggregator_603802,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutConfigurationRecorder_603815 = ref object of OpenApiRestCall_602466
proc url_PutConfigurationRecorder_603817(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutConfigurationRecorder_603816(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a new configuration recorder to record the selected resource configurations.</p> <p>You can use this action to change the role <code>roleARN</code> or the <code>recordingGroup</code> of an existing recorder. To change the role, call the action on the existing configuration recorder and specify a role.</p> <note> <p>Currently, you can specify only one configuration recorder per region in your account.</p> <p>If <code>ConfigurationRecorder</code> does not have the <b>recordingGroup</b> parameter specified, the default is to record all supported resource types.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603818 = header.getOrDefault("X-Amz-Date")
  valid_603818 = validateParameter(valid_603818, JString, required = false,
                                 default = nil)
  if valid_603818 != nil:
    section.add "X-Amz-Date", valid_603818
  var valid_603819 = header.getOrDefault("X-Amz-Security-Token")
  valid_603819 = validateParameter(valid_603819, JString, required = false,
                                 default = nil)
  if valid_603819 != nil:
    section.add "X-Amz-Security-Token", valid_603819
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603820 = header.getOrDefault("X-Amz-Target")
  valid_603820 = validateParameter(valid_603820, JString, required = true, default = newJString(
      "StarlingDoveService.PutConfigurationRecorder"))
  if valid_603820 != nil:
    section.add "X-Amz-Target", valid_603820
  var valid_603821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603821 = validateParameter(valid_603821, JString, required = false,
                                 default = nil)
  if valid_603821 != nil:
    section.add "X-Amz-Content-Sha256", valid_603821
  var valid_603822 = header.getOrDefault("X-Amz-Algorithm")
  valid_603822 = validateParameter(valid_603822, JString, required = false,
                                 default = nil)
  if valid_603822 != nil:
    section.add "X-Amz-Algorithm", valid_603822
  var valid_603823 = header.getOrDefault("X-Amz-Signature")
  valid_603823 = validateParameter(valid_603823, JString, required = false,
                                 default = nil)
  if valid_603823 != nil:
    section.add "X-Amz-Signature", valid_603823
  var valid_603824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603824 = validateParameter(valid_603824, JString, required = false,
                                 default = nil)
  if valid_603824 != nil:
    section.add "X-Amz-SignedHeaders", valid_603824
  var valid_603825 = header.getOrDefault("X-Amz-Credential")
  valid_603825 = validateParameter(valid_603825, JString, required = false,
                                 default = nil)
  if valid_603825 != nil:
    section.add "X-Amz-Credential", valid_603825
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603827: Call_PutConfigurationRecorder_603815; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a new configuration recorder to record the selected resource configurations.</p> <p>You can use this action to change the role <code>roleARN</code> or the <code>recordingGroup</code> of an existing recorder. To change the role, call the action on the existing configuration recorder and specify a role.</p> <note> <p>Currently, you can specify only one configuration recorder per region in your account.</p> <p>If <code>ConfigurationRecorder</code> does not have the <b>recordingGroup</b> parameter specified, the default is to record all supported resource types.</p> </note>
  ## 
  let valid = call_603827.validator(path, query, header, formData, body)
  let scheme = call_603827.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603827.url(scheme.get, call_603827.host, call_603827.base,
                         call_603827.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603827, url, valid)

proc call*(call_603828: Call_PutConfigurationRecorder_603815; body: JsonNode): Recallable =
  ## putConfigurationRecorder
  ## <p>Creates a new configuration recorder to record the selected resource configurations.</p> <p>You can use this action to change the role <code>roleARN</code> or the <code>recordingGroup</code> of an existing recorder. To change the role, call the action on the existing configuration recorder and specify a role.</p> <note> <p>Currently, you can specify only one configuration recorder per region in your account.</p> <p>If <code>ConfigurationRecorder</code> does not have the <b>recordingGroup</b> parameter specified, the default is to record all supported resource types.</p> </note>
  ##   body: JObject (required)
  var body_603829 = newJObject()
  if body != nil:
    body_603829 = body
  result = call_603828.call(nil, nil, nil, nil, body_603829)

var putConfigurationRecorder* = Call_PutConfigurationRecorder_603815(
    name: "putConfigurationRecorder", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutConfigurationRecorder",
    validator: validate_PutConfigurationRecorder_603816, base: "/",
    url: url_PutConfigurationRecorder_603817, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutDeliveryChannel_603830 = ref object of OpenApiRestCall_602466
proc url_PutDeliveryChannel_603832(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutDeliveryChannel_603831(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Creates a delivery channel object to deliver configuration information to an Amazon S3 bucket and Amazon SNS topic.</p> <p>Before you can create a delivery channel, you must create a configuration recorder.</p> <p>You can use this action to change the Amazon S3 bucket or an Amazon SNS topic of the existing delivery channel. To change the Amazon S3 bucket or an Amazon SNS topic, call this action and specify the changed values for the S3 bucket and the SNS topic. If you specify a different value for either the S3 bucket or the SNS topic, this action will keep the existing value for the parameter that is not changed.</p> <note> <p>You can have only one delivery channel per region in your account.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603833 = header.getOrDefault("X-Amz-Date")
  valid_603833 = validateParameter(valid_603833, JString, required = false,
                                 default = nil)
  if valid_603833 != nil:
    section.add "X-Amz-Date", valid_603833
  var valid_603834 = header.getOrDefault("X-Amz-Security-Token")
  valid_603834 = validateParameter(valid_603834, JString, required = false,
                                 default = nil)
  if valid_603834 != nil:
    section.add "X-Amz-Security-Token", valid_603834
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603835 = header.getOrDefault("X-Amz-Target")
  valid_603835 = validateParameter(valid_603835, JString, required = true, default = newJString(
      "StarlingDoveService.PutDeliveryChannel"))
  if valid_603835 != nil:
    section.add "X-Amz-Target", valid_603835
  var valid_603836 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603836 = validateParameter(valid_603836, JString, required = false,
                                 default = nil)
  if valid_603836 != nil:
    section.add "X-Amz-Content-Sha256", valid_603836
  var valid_603837 = header.getOrDefault("X-Amz-Algorithm")
  valid_603837 = validateParameter(valid_603837, JString, required = false,
                                 default = nil)
  if valid_603837 != nil:
    section.add "X-Amz-Algorithm", valid_603837
  var valid_603838 = header.getOrDefault("X-Amz-Signature")
  valid_603838 = validateParameter(valid_603838, JString, required = false,
                                 default = nil)
  if valid_603838 != nil:
    section.add "X-Amz-Signature", valid_603838
  var valid_603839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603839 = validateParameter(valid_603839, JString, required = false,
                                 default = nil)
  if valid_603839 != nil:
    section.add "X-Amz-SignedHeaders", valid_603839
  var valid_603840 = header.getOrDefault("X-Amz-Credential")
  valid_603840 = validateParameter(valid_603840, JString, required = false,
                                 default = nil)
  if valid_603840 != nil:
    section.add "X-Amz-Credential", valid_603840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603842: Call_PutDeliveryChannel_603830; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a delivery channel object to deliver configuration information to an Amazon S3 bucket and Amazon SNS topic.</p> <p>Before you can create a delivery channel, you must create a configuration recorder.</p> <p>You can use this action to change the Amazon S3 bucket or an Amazon SNS topic of the existing delivery channel. To change the Amazon S3 bucket or an Amazon SNS topic, call this action and specify the changed values for the S3 bucket and the SNS topic. If you specify a different value for either the S3 bucket or the SNS topic, this action will keep the existing value for the parameter that is not changed.</p> <note> <p>You can have only one delivery channel per region in your account.</p> </note>
  ## 
  let valid = call_603842.validator(path, query, header, formData, body)
  let scheme = call_603842.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603842.url(scheme.get, call_603842.host, call_603842.base,
                         call_603842.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603842, url, valid)

proc call*(call_603843: Call_PutDeliveryChannel_603830; body: JsonNode): Recallable =
  ## putDeliveryChannel
  ## <p>Creates a delivery channel object to deliver configuration information to an Amazon S3 bucket and Amazon SNS topic.</p> <p>Before you can create a delivery channel, you must create a configuration recorder.</p> <p>You can use this action to change the Amazon S3 bucket or an Amazon SNS topic of the existing delivery channel. To change the Amazon S3 bucket or an Amazon SNS topic, call this action and specify the changed values for the S3 bucket and the SNS topic. If you specify a different value for either the S3 bucket or the SNS topic, this action will keep the existing value for the parameter that is not changed.</p> <note> <p>You can have only one delivery channel per region in your account.</p> </note>
  ##   body: JObject (required)
  var body_603844 = newJObject()
  if body != nil:
    body_603844 = body
  result = call_603843.call(nil, nil, nil, nil, body_603844)

var putDeliveryChannel* = Call_PutDeliveryChannel_603830(
    name: "putDeliveryChannel", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutDeliveryChannel",
    validator: validate_PutDeliveryChannel_603831, base: "/",
    url: url_PutDeliveryChannel_603832, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEvaluations_603845 = ref object of OpenApiRestCall_602466
proc url_PutEvaluations_603847(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutEvaluations_603846(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Used by an AWS Lambda function to deliver evaluation results to AWS Config. This action is required in every AWS Lambda function that is invoked by an AWS Config rule.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603848 = header.getOrDefault("X-Amz-Date")
  valid_603848 = validateParameter(valid_603848, JString, required = false,
                                 default = nil)
  if valid_603848 != nil:
    section.add "X-Amz-Date", valid_603848
  var valid_603849 = header.getOrDefault("X-Amz-Security-Token")
  valid_603849 = validateParameter(valid_603849, JString, required = false,
                                 default = nil)
  if valid_603849 != nil:
    section.add "X-Amz-Security-Token", valid_603849
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603850 = header.getOrDefault("X-Amz-Target")
  valid_603850 = validateParameter(valid_603850, JString, required = true, default = newJString(
      "StarlingDoveService.PutEvaluations"))
  if valid_603850 != nil:
    section.add "X-Amz-Target", valid_603850
  var valid_603851 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603851 = validateParameter(valid_603851, JString, required = false,
                                 default = nil)
  if valid_603851 != nil:
    section.add "X-Amz-Content-Sha256", valid_603851
  var valid_603852 = header.getOrDefault("X-Amz-Algorithm")
  valid_603852 = validateParameter(valid_603852, JString, required = false,
                                 default = nil)
  if valid_603852 != nil:
    section.add "X-Amz-Algorithm", valid_603852
  var valid_603853 = header.getOrDefault("X-Amz-Signature")
  valid_603853 = validateParameter(valid_603853, JString, required = false,
                                 default = nil)
  if valid_603853 != nil:
    section.add "X-Amz-Signature", valid_603853
  var valid_603854 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603854 = validateParameter(valid_603854, JString, required = false,
                                 default = nil)
  if valid_603854 != nil:
    section.add "X-Amz-SignedHeaders", valid_603854
  var valid_603855 = header.getOrDefault("X-Amz-Credential")
  valid_603855 = validateParameter(valid_603855, JString, required = false,
                                 default = nil)
  if valid_603855 != nil:
    section.add "X-Amz-Credential", valid_603855
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603857: Call_PutEvaluations_603845; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used by an AWS Lambda function to deliver evaluation results to AWS Config. This action is required in every AWS Lambda function that is invoked by an AWS Config rule.
  ## 
  let valid = call_603857.validator(path, query, header, formData, body)
  let scheme = call_603857.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603857.url(scheme.get, call_603857.host, call_603857.base,
                         call_603857.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603857, url, valid)

proc call*(call_603858: Call_PutEvaluations_603845; body: JsonNode): Recallable =
  ## putEvaluations
  ## Used by an AWS Lambda function to deliver evaluation results to AWS Config. This action is required in every AWS Lambda function that is invoked by an AWS Config rule.
  ##   body: JObject (required)
  var body_603859 = newJObject()
  if body != nil:
    body_603859 = body
  result = call_603858.call(nil, nil, nil, nil, body_603859)

var putEvaluations* = Call_PutEvaluations_603845(name: "putEvaluations",
    meth: HttpMethod.HttpPost, host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutEvaluations",
    validator: validate_PutEvaluations_603846, base: "/", url: url_PutEvaluations_603847,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutOrganizationConfigRule_603860 = ref object of OpenApiRestCall_602466
proc url_PutOrganizationConfigRule_603862(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutOrganizationConfigRule_603861(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds or updates organization config rule for your entire organization evaluating whether your AWS resources comply with your desired configurations. Only a master account can create or update an organization config rule.</p> <p>This API enables organization service access through the <code>EnableAWSServiceAccess</code> action and creates a service linked role <code>AWSServiceRoleForConfigMultiAccountSetup</code> in the master account of your organization. The service linked role is created only when the role does not exist in the master account. AWS Config verifies the existence of role with <code>GetRole</code> action.</p> <p>You can use this action to create both custom AWS Config rules and AWS managed Config rules. If you are adding a new custom AWS Config rule, you must first create AWS Lambda function in the master account that the rule invokes to evaluate your resources. When you use the <code>PutOrganizationConfigRule</code> action to add the rule to AWS Config, you must specify the Amazon Resource Name (ARN) that AWS Lambda assigns to the function. If you are adding an AWS managed Config rule, specify the rule's identifier for the <code>RuleIdentifier</code> key.</p> <p>The maximum number of organization config rules that AWS Config supports is 150.</p> <note> <p>Specify either <code>OrganizationCustomRuleMetadata</code> or <code>OrganizationManagedRuleMetadata</code>.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603863 = header.getOrDefault("X-Amz-Date")
  valid_603863 = validateParameter(valid_603863, JString, required = false,
                                 default = nil)
  if valid_603863 != nil:
    section.add "X-Amz-Date", valid_603863
  var valid_603864 = header.getOrDefault("X-Amz-Security-Token")
  valid_603864 = validateParameter(valid_603864, JString, required = false,
                                 default = nil)
  if valid_603864 != nil:
    section.add "X-Amz-Security-Token", valid_603864
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603865 = header.getOrDefault("X-Amz-Target")
  valid_603865 = validateParameter(valid_603865, JString, required = true, default = newJString(
      "StarlingDoveService.PutOrganizationConfigRule"))
  if valid_603865 != nil:
    section.add "X-Amz-Target", valid_603865
  var valid_603866 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603866 = validateParameter(valid_603866, JString, required = false,
                                 default = nil)
  if valid_603866 != nil:
    section.add "X-Amz-Content-Sha256", valid_603866
  var valid_603867 = header.getOrDefault("X-Amz-Algorithm")
  valid_603867 = validateParameter(valid_603867, JString, required = false,
                                 default = nil)
  if valid_603867 != nil:
    section.add "X-Amz-Algorithm", valid_603867
  var valid_603868 = header.getOrDefault("X-Amz-Signature")
  valid_603868 = validateParameter(valid_603868, JString, required = false,
                                 default = nil)
  if valid_603868 != nil:
    section.add "X-Amz-Signature", valid_603868
  var valid_603869 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603869 = validateParameter(valid_603869, JString, required = false,
                                 default = nil)
  if valid_603869 != nil:
    section.add "X-Amz-SignedHeaders", valid_603869
  var valid_603870 = header.getOrDefault("X-Amz-Credential")
  valid_603870 = validateParameter(valid_603870, JString, required = false,
                                 default = nil)
  if valid_603870 != nil:
    section.add "X-Amz-Credential", valid_603870
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603872: Call_PutOrganizationConfigRule_603860; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or updates organization config rule for your entire organization evaluating whether your AWS resources comply with your desired configurations. Only a master account can create or update an organization config rule.</p> <p>This API enables organization service access through the <code>EnableAWSServiceAccess</code> action and creates a service linked role <code>AWSServiceRoleForConfigMultiAccountSetup</code> in the master account of your organization. The service linked role is created only when the role does not exist in the master account. AWS Config verifies the existence of role with <code>GetRole</code> action.</p> <p>You can use this action to create both custom AWS Config rules and AWS managed Config rules. If you are adding a new custom AWS Config rule, you must first create AWS Lambda function in the master account that the rule invokes to evaluate your resources. When you use the <code>PutOrganizationConfigRule</code> action to add the rule to AWS Config, you must specify the Amazon Resource Name (ARN) that AWS Lambda assigns to the function. If you are adding an AWS managed Config rule, specify the rule's identifier for the <code>RuleIdentifier</code> key.</p> <p>The maximum number of organization config rules that AWS Config supports is 150.</p> <note> <p>Specify either <code>OrganizationCustomRuleMetadata</code> or <code>OrganizationManagedRuleMetadata</code>.</p> </note>
  ## 
  let valid = call_603872.validator(path, query, header, formData, body)
  let scheme = call_603872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603872.url(scheme.get, call_603872.host, call_603872.base,
                         call_603872.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603872, url, valid)

proc call*(call_603873: Call_PutOrganizationConfigRule_603860; body: JsonNode): Recallable =
  ## putOrganizationConfigRule
  ## <p>Adds or updates organization config rule for your entire organization evaluating whether your AWS resources comply with your desired configurations. Only a master account can create or update an organization config rule.</p> <p>This API enables organization service access through the <code>EnableAWSServiceAccess</code> action and creates a service linked role <code>AWSServiceRoleForConfigMultiAccountSetup</code> in the master account of your organization. The service linked role is created only when the role does not exist in the master account. AWS Config verifies the existence of role with <code>GetRole</code> action.</p> <p>You can use this action to create both custom AWS Config rules and AWS managed Config rules. If you are adding a new custom AWS Config rule, you must first create AWS Lambda function in the master account that the rule invokes to evaluate your resources. When you use the <code>PutOrganizationConfigRule</code> action to add the rule to AWS Config, you must specify the Amazon Resource Name (ARN) that AWS Lambda assigns to the function. If you are adding an AWS managed Config rule, specify the rule's identifier for the <code>RuleIdentifier</code> key.</p> <p>The maximum number of organization config rules that AWS Config supports is 150.</p> <note> <p>Specify either <code>OrganizationCustomRuleMetadata</code> or <code>OrganizationManagedRuleMetadata</code>.</p> </note>
  ##   body: JObject (required)
  var body_603874 = newJObject()
  if body != nil:
    body_603874 = body
  result = call_603873.call(nil, nil, nil, nil, body_603874)

var putOrganizationConfigRule* = Call_PutOrganizationConfigRule_603860(
    name: "putOrganizationConfigRule", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutOrganizationConfigRule",
    validator: validate_PutOrganizationConfigRule_603861, base: "/",
    url: url_PutOrganizationConfigRule_603862,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRemediationConfigurations_603875 = ref object of OpenApiRestCall_602466
proc url_PutRemediationConfigurations_603877(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutRemediationConfigurations_603876(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds or updates the remediation configuration with a specific AWS Config rule with the selected target or action. The API creates the <code>RemediationConfiguration</code> object for the AWS Config rule. The AWS Config rule must already exist for you to add a remediation configuration. The target (SSM document) must exist and have permissions to use the target. 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603878 = header.getOrDefault("X-Amz-Date")
  valid_603878 = validateParameter(valid_603878, JString, required = false,
                                 default = nil)
  if valid_603878 != nil:
    section.add "X-Amz-Date", valid_603878
  var valid_603879 = header.getOrDefault("X-Amz-Security-Token")
  valid_603879 = validateParameter(valid_603879, JString, required = false,
                                 default = nil)
  if valid_603879 != nil:
    section.add "X-Amz-Security-Token", valid_603879
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603880 = header.getOrDefault("X-Amz-Target")
  valid_603880 = validateParameter(valid_603880, JString, required = true, default = newJString(
      "StarlingDoveService.PutRemediationConfigurations"))
  if valid_603880 != nil:
    section.add "X-Amz-Target", valid_603880
  var valid_603881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603881 = validateParameter(valid_603881, JString, required = false,
                                 default = nil)
  if valid_603881 != nil:
    section.add "X-Amz-Content-Sha256", valid_603881
  var valid_603882 = header.getOrDefault("X-Amz-Algorithm")
  valid_603882 = validateParameter(valid_603882, JString, required = false,
                                 default = nil)
  if valid_603882 != nil:
    section.add "X-Amz-Algorithm", valid_603882
  var valid_603883 = header.getOrDefault("X-Amz-Signature")
  valid_603883 = validateParameter(valid_603883, JString, required = false,
                                 default = nil)
  if valid_603883 != nil:
    section.add "X-Amz-Signature", valid_603883
  var valid_603884 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603884 = validateParameter(valid_603884, JString, required = false,
                                 default = nil)
  if valid_603884 != nil:
    section.add "X-Amz-SignedHeaders", valid_603884
  var valid_603885 = header.getOrDefault("X-Amz-Credential")
  valid_603885 = validateParameter(valid_603885, JString, required = false,
                                 default = nil)
  if valid_603885 != nil:
    section.add "X-Amz-Credential", valid_603885
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603887: Call_PutRemediationConfigurations_603875; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds or updates the remediation configuration with a specific AWS Config rule with the selected target or action. The API creates the <code>RemediationConfiguration</code> object for the AWS Config rule. The AWS Config rule must already exist for you to add a remediation configuration. The target (SSM document) must exist and have permissions to use the target. 
  ## 
  let valid = call_603887.validator(path, query, header, formData, body)
  let scheme = call_603887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603887.url(scheme.get, call_603887.host, call_603887.base,
                         call_603887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603887, url, valid)

proc call*(call_603888: Call_PutRemediationConfigurations_603875; body: JsonNode): Recallable =
  ## putRemediationConfigurations
  ## Adds or updates the remediation configuration with a specific AWS Config rule with the selected target or action. The API creates the <code>RemediationConfiguration</code> object for the AWS Config rule. The AWS Config rule must already exist for you to add a remediation configuration. The target (SSM document) must exist and have permissions to use the target. 
  ##   body: JObject (required)
  var body_603889 = newJObject()
  if body != nil:
    body_603889 = body
  result = call_603888.call(nil, nil, nil, nil, body_603889)

var putRemediationConfigurations* = Call_PutRemediationConfigurations_603875(
    name: "putRemediationConfigurations", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutRemediationConfigurations",
    validator: validate_PutRemediationConfigurations_603876, base: "/",
    url: url_PutRemediationConfigurations_603877,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRemediationExceptions_603890 = ref object of OpenApiRestCall_602466
proc url_PutRemediationExceptions_603892(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutRemediationExceptions_603891(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## A remediation exception is when a specific resource is no longer considered for auto-remediation. This API adds a new exception or updates an exisiting exception for a specific resource with a specific AWS Config rule. 
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603893 = header.getOrDefault("X-Amz-Date")
  valid_603893 = validateParameter(valid_603893, JString, required = false,
                                 default = nil)
  if valid_603893 != nil:
    section.add "X-Amz-Date", valid_603893
  var valid_603894 = header.getOrDefault("X-Amz-Security-Token")
  valid_603894 = validateParameter(valid_603894, JString, required = false,
                                 default = nil)
  if valid_603894 != nil:
    section.add "X-Amz-Security-Token", valid_603894
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603895 = header.getOrDefault("X-Amz-Target")
  valid_603895 = validateParameter(valid_603895, JString, required = true, default = newJString(
      "StarlingDoveService.PutRemediationExceptions"))
  if valid_603895 != nil:
    section.add "X-Amz-Target", valid_603895
  var valid_603896 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603896 = validateParameter(valid_603896, JString, required = false,
                                 default = nil)
  if valid_603896 != nil:
    section.add "X-Amz-Content-Sha256", valid_603896
  var valid_603897 = header.getOrDefault("X-Amz-Algorithm")
  valid_603897 = validateParameter(valid_603897, JString, required = false,
                                 default = nil)
  if valid_603897 != nil:
    section.add "X-Amz-Algorithm", valid_603897
  var valid_603898 = header.getOrDefault("X-Amz-Signature")
  valid_603898 = validateParameter(valid_603898, JString, required = false,
                                 default = nil)
  if valid_603898 != nil:
    section.add "X-Amz-Signature", valid_603898
  var valid_603899 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603899 = validateParameter(valid_603899, JString, required = false,
                                 default = nil)
  if valid_603899 != nil:
    section.add "X-Amz-SignedHeaders", valid_603899
  var valid_603900 = header.getOrDefault("X-Amz-Credential")
  valid_603900 = validateParameter(valid_603900, JString, required = false,
                                 default = nil)
  if valid_603900 != nil:
    section.add "X-Amz-Credential", valid_603900
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603902: Call_PutRemediationExceptions_603890; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## A remediation exception is when a specific resource is no longer considered for auto-remediation. This API adds a new exception or updates an exisiting exception for a specific resource with a specific AWS Config rule. 
  ## 
  let valid = call_603902.validator(path, query, header, formData, body)
  let scheme = call_603902.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603902.url(scheme.get, call_603902.host, call_603902.base,
                         call_603902.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603902, url, valid)

proc call*(call_603903: Call_PutRemediationExceptions_603890; body: JsonNode): Recallable =
  ## putRemediationExceptions
  ## A remediation exception is when a specific resource is no longer considered for auto-remediation. This API adds a new exception or updates an exisiting exception for a specific resource with a specific AWS Config rule. 
  ##   body: JObject (required)
  var body_603904 = newJObject()
  if body != nil:
    body_603904 = body
  result = call_603903.call(nil, nil, nil, nil, body_603904)

var putRemediationExceptions* = Call_PutRemediationExceptions_603890(
    name: "putRemediationExceptions", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutRemediationExceptions",
    validator: validate_PutRemediationExceptions_603891, base: "/",
    url: url_PutRemediationExceptions_603892, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutRetentionConfiguration_603905 = ref object of OpenApiRestCall_602466
proc url_PutRetentionConfiguration_603907(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutRetentionConfiguration_603906(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates and updates the retention configuration with details about retention period (number of days) that AWS Config stores your historical information. The API creates the <code>RetentionConfiguration</code> object and names the object as <b>default</b>. When you have a <code>RetentionConfiguration</code> object named <b>default</b>, calling the API modifies the default object. </p> <note> <p>Currently, AWS Config supports only one retention configuration per region in your account.</p> </note>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603908 = header.getOrDefault("X-Amz-Date")
  valid_603908 = validateParameter(valid_603908, JString, required = false,
                                 default = nil)
  if valid_603908 != nil:
    section.add "X-Amz-Date", valid_603908
  var valid_603909 = header.getOrDefault("X-Amz-Security-Token")
  valid_603909 = validateParameter(valid_603909, JString, required = false,
                                 default = nil)
  if valid_603909 != nil:
    section.add "X-Amz-Security-Token", valid_603909
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603910 = header.getOrDefault("X-Amz-Target")
  valid_603910 = validateParameter(valid_603910, JString, required = true, default = newJString(
      "StarlingDoveService.PutRetentionConfiguration"))
  if valid_603910 != nil:
    section.add "X-Amz-Target", valid_603910
  var valid_603911 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603911 = validateParameter(valid_603911, JString, required = false,
                                 default = nil)
  if valid_603911 != nil:
    section.add "X-Amz-Content-Sha256", valid_603911
  var valid_603912 = header.getOrDefault("X-Amz-Algorithm")
  valid_603912 = validateParameter(valid_603912, JString, required = false,
                                 default = nil)
  if valid_603912 != nil:
    section.add "X-Amz-Algorithm", valid_603912
  var valid_603913 = header.getOrDefault("X-Amz-Signature")
  valid_603913 = validateParameter(valid_603913, JString, required = false,
                                 default = nil)
  if valid_603913 != nil:
    section.add "X-Amz-Signature", valid_603913
  var valid_603914 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603914 = validateParameter(valid_603914, JString, required = false,
                                 default = nil)
  if valid_603914 != nil:
    section.add "X-Amz-SignedHeaders", valid_603914
  var valid_603915 = header.getOrDefault("X-Amz-Credential")
  valid_603915 = validateParameter(valid_603915, JString, required = false,
                                 default = nil)
  if valid_603915 != nil:
    section.add "X-Amz-Credential", valid_603915
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603917: Call_PutRetentionConfiguration_603905; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates and updates the retention configuration with details about retention period (number of days) that AWS Config stores your historical information. The API creates the <code>RetentionConfiguration</code> object and names the object as <b>default</b>. When you have a <code>RetentionConfiguration</code> object named <b>default</b>, calling the API modifies the default object. </p> <note> <p>Currently, AWS Config supports only one retention configuration per region in your account.</p> </note>
  ## 
  let valid = call_603917.validator(path, query, header, formData, body)
  let scheme = call_603917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603917.url(scheme.get, call_603917.host, call_603917.base,
                         call_603917.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603917, url, valid)

proc call*(call_603918: Call_PutRetentionConfiguration_603905; body: JsonNode): Recallable =
  ## putRetentionConfiguration
  ## <p>Creates and updates the retention configuration with details about retention period (number of days) that AWS Config stores your historical information. The API creates the <code>RetentionConfiguration</code> object and names the object as <b>default</b>. When you have a <code>RetentionConfiguration</code> object named <b>default</b>, calling the API modifies the default object. </p> <note> <p>Currently, AWS Config supports only one retention configuration per region in your account.</p> </note>
  ##   body: JObject (required)
  var body_603919 = newJObject()
  if body != nil:
    body_603919 = body
  result = call_603918.call(nil, nil, nil, nil, body_603919)

var putRetentionConfiguration* = Call_PutRetentionConfiguration_603905(
    name: "putRetentionConfiguration", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.PutRetentionConfiguration",
    validator: validate_PutRetentionConfiguration_603906, base: "/",
    url: url_PutRetentionConfiguration_603907,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SelectResourceConfig_603920 = ref object of OpenApiRestCall_602466
proc url_SelectResourceConfig_603922(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SelectResourceConfig_603921(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Accepts a structured query language (SQL) <code>SELECT</code> command, performs the corresponding search, and returns resource configurations matching the properties.</p> <p>For more information about query components, see the <a href="https://docs.aws.amazon.com/config/latest/developerguide/query-components.html"> <b>Query Components</b> </a> section in the AWS Config Developer Guide.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603923 = header.getOrDefault("X-Amz-Date")
  valid_603923 = validateParameter(valid_603923, JString, required = false,
                                 default = nil)
  if valid_603923 != nil:
    section.add "X-Amz-Date", valid_603923
  var valid_603924 = header.getOrDefault("X-Amz-Security-Token")
  valid_603924 = validateParameter(valid_603924, JString, required = false,
                                 default = nil)
  if valid_603924 != nil:
    section.add "X-Amz-Security-Token", valid_603924
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603925 = header.getOrDefault("X-Amz-Target")
  valid_603925 = validateParameter(valid_603925, JString, required = true, default = newJString(
      "StarlingDoveService.SelectResourceConfig"))
  if valid_603925 != nil:
    section.add "X-Amz-Target", valid_603925
  var valid_603926 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603926 = validateParameter(valid_603926, JString, required = false,
                                 default = nil)
  if valid_603926 != nil:
    section.add "X-Amz-Content-Sha256", valid_603926
  var valid_603927 = header.getOrDefault("X-Amz-Algorithm")
  valid_603927 = validateParameter(valid_603927, JString, required = false,
                                 default = nil)
  if valid_603927 != nil:
    section.add "X-Amz-Algorithm", valid_603927
  var valid_603928 = header.getOrDefault("X-Amz-Signature")
  valid_603928 = validateParameter(valid_603928, JString, required = false,
                                 default = nil)
  if valid_603928 != nil:
    section.add "X-Amz-Signature", valid_603928
  var valid_603929 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603929 = validateParameter(valid_603929, JString, required = false,
                                 default = nil)
  if valid_603929 != nil:
    section.add "X-Amz-SignedHeaders", valid_603929
  var valid_603930 = header.getOrDefault("X-Amz-Credential")
  valid_603930 = validateParameter(valid_603930, JString, required = false,
                                 default = nil)
  if valid_603930 != nil:
    section.add "X-Amz-Credential", valid_603930
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603932: Call_SelectResourceConfig_603920; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Accepts a structured query language (SQL) <code>SELECT</code> command, performs the corresponding search, and returns resource configurations matching the properties.</p> <p>For more information about query components, see the <a href="https://docs.aws.amazon.com/config/latest/developerguide/query-components.html"> <b>Query Components</b> </a> section in the AWS Config Developer Guide.</p>
  ## 
  let valid = call_603932.validator(path, query, header, formData, body)
  let scheme = call_603932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603932.url(scheme.get, call_603932.host, call_603932.base,
                         call_603932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603932, url, valid)

proc call*(call_603933: Call_SelectResourceConfig_603920; body: JsonNode): Recallable =
  ## selectResourceConfig
  ## <p>Accepts a structured query language (SQL) <code>SELECT</code> command, performs the corresponding search, and returns resource configurations matching the properties.</p> <p>For more information about query components, see the <a href="https://docs.aws.amazon.com/config/latest/developerguide/query-components.html"> <b>Query Components</b> </a> section in the AWS Config Developer Guide.</p>
  ##   body: JObject (required)
  var body_603934 = newJObject()
  if body != nil:
    body_603934 = body
  result = call_603933.call(nil, nil, nil, nil, body_603934)

var selectResourceConfig* = Call_SelectResourceConfig_603920(
    name: "selectResourceConfig", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.SelectResourceConfig",
    validator: validate_SelectResourceConfig_603921, base: "/",
    url: url_SelectResourceConfig_603922, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartConfigRulesEvaluation_603935 = ref object of OpenApiRestCall_602466
proc url_StartConfigRulesEvaluation_603937(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartConfigRulesEvaluation_603936(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Runs an on-demand evaluation for the specified AWS Config rules against the last known configuration state of the resources. Use <code>StartConfigRulesEvaluation</code> when you want to test that a rule you updated is working as expected. <code>StartConfigRulesEvaluation</code> does not re-record the latest configuration state for your resources. It re-runs an evaluation against the last known state of your resources. </p> <p>You can specify up to 25 AWS Config rules per request. </p> <p>An existing <code>StartConfigRulesEvaluation</code> call for the specified rules must complete before you can call the API again. If you chose to have AWS Config stream to an Amazon SNS topic, you will receive a <code>ConfigRuleEvaluationStarted</code> notification when the evaluation starts.</p> <note> <p>You don't need to call the <code>StartConfigRulesEvaluation</code> API to run an evaluation for a new rule. When you create a rule, AWS Config evaluates your resources against the rule automatically. </p> </note> <p>The <code>StartConfigRulesEvaluation</code> API is useful if you want to run on-demand evaluations, such as the following example:</p> <ol> <li> <p>You have a custom rule that evaluates your IAM resources every 24 hours.</p> </li> <li> <p>You update your Lambda function to add additional conditions to your rule.</p> </li> <li> <p>Instead of waiting for the next periodic evaluation, you call the <code>StartConfigRulesEvaluation</code> API.</p> </li> <li> <p>AWS Config invokes your Lambda function and evaluates your IAM resources.</p> </li> <li> <p>Your custom rule will still run periodic evaluations every 24 hours.</p> </li> </ol>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603938 = header.getOrDefault("X-Amz-Date")
  valid_603938 = validateParameter(valid_603938, JString, required = false,
                                 default = nil)
  if valid_603938 != nil:
    section.add "X-Amz-Date", valid_603938
  var valid_603939 = header.getOrDefault("X-Amz-Security-Token")
  valid_603939 = validateParameter(valid_603939, JString, required = false,
                                 default = nil)
  if valid_603939 != nil:
    section.add "X-Amz-Security-Token", valid_603939
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603940 = header.getOrDefault("X-Amz-Target")
  valid_603940 = validateParameter(valid_603940, JString, required = true, default = newJString(
      "StarlingDoveService.StartConfigRulesEvaluation"))
  if valid_603940 != nil:
    section.add "X-Amz-Target", valid_603940
  var valid_603941 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603941 = validateParameter(valid_603941, JString, required = false,
                                 default = nil)
  if valid_603941 != nil:
    section.add "X-Amz-Content-Sha256", valid_603941
  var valid_603942 = header.getOrDefault("X-Amz-Algorithm")
  valid_603942 = validateParameter(valid_603942, JString, required = false,
                                 default = nil)
  if valid_603942 != nil:
    section.add "X-Amz-Algorithm", valid_603942
  var valid_603943 = header.getOrDefault("X-Amz-Signature")
  valid_603943 = validateParameter(valid_603943, JString, required = false,
                                 default = nil)
  if valid_603943 != nil:
    section.add "X-Amz-Signature", valid_603943
  var valid_603944 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603944 = validateParameter(valid_603944, JString, required = false,
                                 default = nil)
  if valid_603944 != nil:
    section.add "X-Amz-SignedHeaders", valid_603944
  var valid_603945 = header.getOrDefault("X-Amz-Credential")
  valid_603945 = validateParameter(valid_603945, JString, required = false,
                                 default = nil)
  if valid_603945 != nil:
    section.add "X-Amz-Credential", valid_603945
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603947: Call_StartConfigRulesEvaluation_603935; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Runs an on-demand evaluation for the specified AWS Config rules against the last known configuration state of the resources. Use <code>StartConfigRulesEvaluation</code> when you want to test that a rule you updated is working as expected. <code>StartConfigRulesEvaluation</code> does not re-record the latest configuration state for your resources. It re-runs an evaluation against the last known state of your resources. </p> <p>You can specify up to 25 AWS Config rules per request. </p> <p>An existing <code>StartConfigRulesEvaluation</code> call for the specified rules must complete before you can call the API again. If you chose to have AWS Config stream to an Amazon SNS topic, you will receive a <code>ConfigRuleEvaluationStarted</code> notification when the evaluation starts.</p> <note> <p>You don't need to call the <code>StartConfigRulesEvaluation</code> API to run an evaluation for a new rule. When you create a rule, AWS Config evaluates your resources against the rule automatically. </p> </note> <p>The <code>StartConfigRulesEvaluation</code> API is useful if you want to run on-demand evaluations, such as the following example:</p> <ol> <li> <p>You have a custom rule that evaluates your IAM resources every 24 hours.</p> </li> <li> <p>You update your Lambda function to add additional conditions to your rule.</p> </li> <li> <p>Instead of waiting for the next periodic evaluation, you call the <code>StartConfigRulesEvaluation</code> API.</p> </li> <li> <p>AWS Config invokes your Lambda function and evaluates your IAM resources.</p> </li> <li> <p>Your custom rule will still run periodic evaluations every 24 hours.</p> </li> </ol>
  ## 
  let valid = call_603947.validator(path, query, header, formData, body)
  let scheme = call_603947.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603947.url(scheme.get, call_603947.host, call_603947.base,
                         call_603947.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603947, url, valid)

proc call*(call_603948: Call_StartConfigRulesEvaluation_603935; body: JsonNode): Recallable =
  ## startConfigRulesEvaluation
  ## <p>Runs an on-demand evaluation for the specified AWS Config rules against the last known configuration state of the resources. Use <code>StartConfigRulesEvaluation</code> when you want to test that a rule you updated is working as expected. <code>StartConfigRulesEvaluation</code> does not re-record the latest configuration state for your resources. It re-runs an evaluation against the last known state of your resources. </p> <p>You can specify up to 25 AWS Config rules per request. </p> <p>An existing <code>StartConfigRulesEvaluation</code> call for the specified rules must complete before you can call the API again. If you chose to have AWS Config stream to an Amazon SNS topic, you will receive a <code>ConfigRuleEvaluationStarted</code> notification when the evaluation starts.</p> <note> <p>You don't need to call the <code>StartConfigRulesEvaluation</code> API to run an evaluation for a new rule. When you create a rule, AWS Config evaluates your resources against the rule automatically. </p> </note> <p>The <code>StartConfigRulesEvaluation</code> API is useful if you want to run on-demand evaluations, such as the following example:</p> <ol> <li> <p>You have a custom rule that evaluates your IAM resources every 24 hours.</p> </li> <li> <p>You update your Lambda function to add additional conditions to your rule.</p> </li> <li> <p>Instead of waiting for the next periodic evaluation, you call the <code>StartConfigRulesEvaluation</code> API.</p> </li> <li> <p>AWS Config invokes your Lambda function and evaluates your IAM resources.</p> </li> <li> <p>Your custom rule will still run periodic evaluations every 24 hours.</p> </li> </ol>
  ##   body: JObject (required)
  var body_603949 = newJObject()
  if body != nil:
    body_603949 = body
  result = call_603948.call(nil, nil, nil, nil, body_603949)

var startConfigRulesEvaluation* = Call_StartConfigRulesEvaluation_603935(
    name: "startConfigRulesEvaluation", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.StartConfigRulesEvaluation",
    validator: validate_StartConfigRulesEvaluation_603936, base: "/",
    url: url_StartConfigRulesEvaluation_603937,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartConfigurationRecorder_603950 = ref object of OpenApiRestCall_602466
proc url_StartConfigurationRecorder_603952(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartConfigurationRecorder_603951(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Starts recording configurations of the AWS resources you have selected to record in your AWS account.</p> <p>You must have created at least one delivery channel to successfully start the configuration recorder.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603953 = header.getOrDefault("X-Amz-Date")
  valid_603953 = validateParameter(valid_603953, JString, required = false,
                                 default = nil)
  if valid_603953 != nil:
    section.add "X-Amz-Date", valid_603953
  var valid_603954 = header.getOrDefault("X-Amz-Security-Token")
  valid_603954 = validateParameter(valid_603954, JString, required = false,
                                 default = nil)
  if valid_603954 != nil:
    section.add "X-Amz-Security-Token", valid_603954
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603955 = header.getOrDefault("X-Amz-Target")
  valid_603955 = validateParameter(valid_603955, JString, required = true, default = newJString(
      "StarlingDoveService.StartConfigurationRecorder"))
  if valid_603955 != nil:
    section.add "X-Amz-Target", valid_603955
  var valid_603956 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603956 = validateParameter(valid_603956, JString, required = false,
                                 default = nil)
  if valid_603956 != nil:
    section.add "X-Amz-Content-Sha256", valid_603956
  var valid_603957 = header.getOrDefault("X-Amz-Algorithm")
  valid_603957 = validateParameter(valid_603957, JString, required = false,
                                 default = nil)
  if valid_603957 != nil:
    section.add "X-Amz-Algorithm", valid_603957
  var valid_603958 = header.getOrDefault("X-Amz-Signature")
  valid_603958 = validateParameter(valid_603958, JString, required = false,
                                 default = nil)
  if valid_603958 != nil:
    section.add "X-Amz-Signature", valid_603958
  var valid_603959 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603959 = validateParameter(valid_603959, JString, required = false,
                                 default = nil)
  if valid_603959 != nil:
    section.add "X-Amz-SignedHeaders", valid_603959
  var valid_603960 = header.getOrDefault("X-Amz-Credential")
  valid_603960 = validateParameter(valid_603960, JString, required = false,
                                 default = nil)
  if valid_603960 != nil:
    section.add "X-Amz-Credential", valid_603960
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603962: Call_StartConfigurationRecorder_603950; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Starts recording configurations of the AWS resources you have selected to record in your AWS account.</p> <p>You must have created at least one delivery channel to successfully start the configuration recorder.</p>
  ## 
  let valid = call_603962.validator(path, query, header, formData, body)
  let scheme = call_603962.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603962.url(scheme.get, call_603962.host, call_603962.base,
                         call_603962.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603962, url, valid)

proc call*(call_603963: Call_StartConfigurationRecorder_603950; body: JsonNode): Recallable =
  ## startConfigurationRecorder
  ## <p>Starts recording configurations of the AWS resources you have selected to record in your AWS account.</p> <p>You must have created at least one delivery channel to successfully start the configuration recorder.</p>
  ##   body: JObject (required)
  var body_603964 = newJObject()
  if body != nil:
    body_603964 = body
  result = call_603963.call(nil, nil, nil, nil, body_603964)

var startConfigurationRecorder* = Call_StartConfigurationRecorder_603950(
    name: "startConfigurationRecorder", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.StartConfigurationRecorder",
    validator: validate_StartConfigurationRecorder_603951, base: "/",
    url: url_StartConfigurationRecorder_603952,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartRemediationExecution_603965 = ref object of OpenApiRestCall_602466
proc url_StartRemediationExecution_603967(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StartRemediationExecution_603966(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Runs an on-demand remediation for the specified AWS Config rules against the last known remediation configuration. It runs an execution against the current state of your resources. Remediation execution is asynchronous.</p> <p>You can specify up to 100 resource keys per request. An existing StartRemediationExecution call for the specified resource keys must complete before you can call the API again.</p>
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603968 = header.getOrDefault("X-Amz-Date")
  valid_603968 = validateParameter(valid_603968, JString, required = false,
                                 default = nil)
  if valid_603968 != nil:
    section.add "X-Amz-Date", valid_603968
  var valid_603969 = header.getOrDefault("X-Amz-Security-Token")
  valid_603969 = validateParameter(valid_603969, JString, required = false,
                                 default = nil)
  if valid_603969 != nil:
    section.add "X-Amz-Security-Token", valid_603969
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603970 = header.getOrDefault("X-Amz-Target")
  valid_603970 = validateParameter(valid_603970, JString, required = true, default = newJString(
      "StarlingDoveService.StartRemediationExecution"))
  if valid_603970 != nil:
    section.add "X-Amz-Target", valid_603970
  var valid_603971 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603971 = validateParameter(valid_603971, JString, required = false,
                                 default = nil)
  if valid_603971 != nil:
    section.add "X-Amz-Content-Sha256", valid_603971
  var valid_603972 = header.getOrDefault("X-Amz-Algorithm")
  valid_603972 = validateParameter(valid_603972, JString, required = false,
                                 default = nil)
  if valid_603972 != nil:
    section.add "X-Amz-Algorithm", valid_603972
  var valid_603973 = header.getOrDefault("X-Amz-Signature")
  valid_603973 = validateParameter(valid_603973, JString, required = false,
                                 default = nil)
  if valid_603973 != nil:
    section.add "X-Amz-Signature", valid_603973
  var valid_603974 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603974 = validateParameter(valid_603974, JString, required = false,
                                 default = nil)
  if valid_603974 != nil:
    section.add "X-Amz-SignedHeaders", valid_603974
  var valid_603975 = header.getOrDefault("X-Amz-Credential")
  valid_603975 = validateParameter(valid_603975, JString, required = false,
                                 default = nil)
  if valid_603975 != nil:
    section.add "X-Amz-Credential", valid_603975
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603977: Call_StartRemediationExecution_603965; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Runs an on-demand remediation for the specified AWS Config rules against the last known remediation configuration. It runs an execution against the current state of your resources. Remediation execution is asynchronous.</p> <p>You can specify up to 100 resource keys per request. An existing StartRemediationExecution call for the specified resource keys must complete before you can call the API again.</p>
  ## 
  let valid = call_603977.validator(path, query, header, formData, body)
  let scheme = call_603977.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603977.url(scheme.get, call_603977.host, call_603977.base,
                         call_603977.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603977, url, valid)

proc call*(call_603978: Call_StartRemediationExecution_603965; body: JsonNode): Recallable =
  ## startRemediationExecution
  ## <p>Runs an on-demand remediation for the specified AWS Config rules against the last known remediation configuration. It runs an execution against the current state of your resources. Remediation execution is asynchronous.</p> <p>You can specify up to 100 resource keys per request. An existing StartRemediationExecution call for the specified resource keys must complete before you can call the API again.</p>
  ##   body: JObject (required)
  var body_603979 = newJObject()
  if body != nil:
    body_603979 = body
  result = call_603978.call(nil, nil, nil, nil, body_603979)

var startRemediationExecution* = Call_StartRemediationExecution_603965(
    name: "startRemediationExecution", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.StartRemediationExecution",
    validator: validate_StartRemediationExecution_603966, base: "/",
    url: url_StartRemediationExecution_603967,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopConfigurationRecorder_603980 = ref object of OpenApiRestCall_602466
proc url_StopConfigurationRecorder_603982(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_StopConfigurationRecorder_603981(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Stops recording configurations of the AWS resources you have selected to record in your AWS account.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603983 = header.getOrDefault("X-Amz-Date")
  valid_603983 = validateParameter(valid_603983, JString, required = false,
                                 default = nil)
  if valid_603983 != nil:
    section.add "X-Amz-Date", valid_603983
  var valid_603984 = header.getOrDefault("X-Amz-Security-Token")
  valid_603984 = validateParameter(valid_603984, JString, required = false,
                                 default = nil)
  if valid_603984 != nil:
    section.add "X-Amz-Security-Token", valid_603984
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_603985 = header.getOrDefault("X-Amz-Target")
  valid_603985 = validateParameter(valid_603985, JString, required = true, default = newJString(
      "StarlingDoveService.StopConfigurationRecorder"))
  if valid_603985 != nil:
    section.add "X-Amz-Target", valid_603985
  var valid_603986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603986 = validateParameter(valid_603986, JString, required = false,
                                 default = nil)
  if valid_603986 != nil:
    section.add "X-Amz-Content-Sha256", valid_603986
  var valid_603987 = header.getOrDefault("X-Amz-Algorithm")
  valid_603987 = validateParameter(valid_603987, JString, required = false,
                                 default = nil)
  if valid_603987 != nil:
    section.add "X-Amz-Algorithm", valid_603987
  var valid_603988 = header.getOrDefault("X-Amz-Signature")
  valid_603988 = validateParameter(valid_603988, JString, required = false,
                                 default = nil)
  if valid_603988 != nil:
    section.add "X-Amz-Signature", valid_603988
  var valid_603989 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603989 = validateParameter(valid_603989, JString, required = false,
                                 default = nil)
  if valid_603989 != nil:
    section.add "X-Amz-SignedHeaders", valid_603989
  var valid_603990 = header.getOrDefault("X-Amz-Credential")
  valid_603990 = validateParameter(valid_603990, JString, required = false,
                                 default = nil)
  if valid_603990 != nil:
    section.add "X-Amz-Credential", valid_603990
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_603992: Call_StopConfigurationRecorder_603980; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops recording configurations of the AWS resources you have selected to record in your AWS account.
  ## 
  let valid = call_603992.validator(path, query, header, formData, body)
  let scheme = call_603992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603992.url(scheme.get, call_603992.host, call_603992.base,
                         call_603992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603992, url, valid)

proc call*(call_603993: Call_StopConfigurationRecorder_603980; body: JsonNode): Recallable =
  ## stopConfigurationRecorder
  ## Stops recording configurations of the AWS resources you have selected to record in your AWS account.
  ##   body: JObject (required)
  var body_603994 = newJObject()
  if body != nil:
    body_603994 = body
  result = call_603993.call(nil, nil, nil, nil, body_603994)

var stopConfigurationRecorder* = Call_StopConfigurationRecorder_603980(
    name: "stopConfigurationRecorder", meth: HttpMethod.HttpPost,
    host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.StopConfigurationRecorder",
    validator: validate_StopConfigurationRecorder_603981, base: "/",
    url: url_StopConfigurationRecorder_603982,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_603995 = ref object of OpenApiRestCall_602466
proc url_TagResource_603997(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_TagResource_603996(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603998 = header.getOrDefault("X-Amz-Date")
  valid_603998 = validateParameter(valid_603998, JString, required = false,
                                 default = nil)
  if valid_603998 != nil:
    section.add "X-Amz-Date", valid_603998
  var valid_603999 = header.getOrDefault("X-Amz-Security-Token")
  valid_603999 = validateParameter(valid_603999, JString, required = false,
                                 default = nil)
  if valid_603999 != nil:
    section.add "X-Amz-Security-Token", valid_603999
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604000 = header.getOrDefault("X-Amz-Target")
  valid_604000 = validateParameter(valid_604000, JString, required = true, default = newJString(
      "StarlingDoveService.TagResource"))
  if valid_604000 != nil:
    section.add "X-Amz-Target", valid_604000
  var valid_604001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604001 = validateParameter(valid_604001, JString, required = false,
                                 default = nil)
  if valid_604001 != nil:
    section.add "X-Amz-Content-Sha256", valid_604001
  var valid_604002 = header.getOrDefault("X-Amz-Algorithm")
  valid_604002 = validateParameter(valid_604002, JString, required = false,
                                 default = nil)
  if valid_604002 != nil:
    section.add "X-Amz-Algorithm", valid_604002
  var valid_604003 = header.getOrDefault("X-Amz-Signature")
  valid_604003 = validateParameter(valid_604003, JString, required = false,
                                 default = nil)
  if valid_604003 != nil:
    section.add "X-Amz-Signature", valid_604003
  var valid_604004 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604004 = validateParameter(valid_604004, JString, required = false,
                                 default = nil)
  if valid_604004 != nil:
    section.add "X-Amz-SignedHeaders", valid_604004
  var valid_604005 = header.getOrDefault("X-Amz-Credential")
  valid_604005 = validateParameter(valid_604005, JString, required = false,
                                 default = nil)
  if valid_604005 != nil:
    section.add "X-Amz-Credential", valid_604005
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604007: Call_TagResource_603995; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ## 
  let valid = call_604007.validator(path, query, header, formData, body)
  let scheme = call_604007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604007.url(scheme.get, call_604007.host, call_604007.base,
                         call_604007.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604007, url, valid)

proc call*(call_604008: Call_TagResource_603995; body: JsonNode): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ##   body: JObject (required)
  var body_604009 = newJObject()
  if body != nil:
    body_604009 = body
  result = call_604008.call(nil, nil, nil, nil, body_604009)

var tagResource* = Call_TagResource_603995(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "config.amazonaws.com", route: "/#X-Amz-Target=StarlingDoveService.TagResource",
                                        validator: validate_TagResource_603996,
                                        base: "/", url: url_TagResource_603997,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_604010 = ref object of OpenApiRestCall_602466
proc url_UntagResource_604012(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UntagResource_604011(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes specified tags from a resource.
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
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604013 = header.getOrDefault("X-Amz-Date")
  valid_604013 = validateParameter(valid_604013, JString, required = false,
                                 default = nil)
  if valid_604013 != nil:
    section.add "X-Amz-Date", valid_604013
  var valid_604014 = header.getOrDefault("X-Amz-Security-Token")
  valid_604014 = validateParameter(valid_604014, JString, required = false,
                                 default = nil)
  if valid_604014 != nil:
    section.add "X-Amz-Security-Token", valid_604014
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_604015 = header.getOrDefault("X-Amz-Target")
  valid_604015 = validateParameter(valid_604015, JString, required = true, default = newJString(
      "StarlingDoveService.UntagResource"))
  if valid_604015 != nil:
    section.add "X-Amz-Target", valid_604015
  var valid_604016 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604016 = validateParameter(valid_604016, JString, required = false,
                                 default = nil)
  if valid_604016 != nil:
    section.add "X-Amz-Content-Sha256", valid_604016
  var valid_604017 = header.getOrDefault("X-Amz-Algorithm")
  valid_604017 = validateParameter(valid_604017, JString, required = false,
                                 default = nil)
  if valid_604017 != nil:
    section.add "X-Amz-Algorithm", valid_604017
  var valid_604018 = header.getOrDefault("X-Amz-Signature")
  valid_604018 = validateParameter(valid_604018, JString, required = false,
                                 default = nil)
  if valid_604018 != nil:
    section.add "X-Amz-Signature", valid_604018
  var valid_604019 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604019 = validateParameter(valid_604019, JString, required = false,
                                 default = nil)
  if valid_604019 != nil:
    section.add "X-Amz-SignedHeaders", valid_604019
  var valid_604020 = header.getOrDefault("X-Amz-Credential")
  valid_604020 = validateParameter(valid_604020, JString, required = false,
                                 default = nil)
  if valid_604020 != nil:
    section.add "X-Amz-Credential", valid_604020
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_604022: Call_UntagResource_604010; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_604022.validator(path, query, header, formData, body)
  let scheme = call_604022.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604022.url(scheme.get, call_604022.host, call_604022.base,
                         call_604022.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604022, url, valid)

proc call*(call_604023: Call_UntagResource_604010; body: JsonNode): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   body: JObject (required)
  var body_604024 = newJObject()
  if body != nil:
    body_604024 = body
  result = call_604023.call(nil, nil, nil, nil, body_604024)

var untagResource* = Call_UntagResource_604010(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "config.amazonaws.com",
    route: "/#X-Amz-Target=StarlingDoveService.UntagResource",
    validator: validate_UntagResource_604011, base: "/", url: url_UntagResource_604012,
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
