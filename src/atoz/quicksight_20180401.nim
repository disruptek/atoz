
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon QuickSight
## version: 2018-04-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon QuickSight API Reference</fullname> <p>Amazon QuickSight is a fully managed, serverless business intelligence service for the AWS Cloud that makes it easy to extend data and insights to every user in your organization. This API reference contains documentation for a programming interface that you can use to manage Amazon QuickSight. </p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/quicksight/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "quicksight.ap-northeast-1.amazonaws.com", "ap-southeast-1": "quicksight.ap-southeast-1.amazonaws.com",
                           "us-west-2": "quicksight.us-west-2.amazonaws.com",
                           "eu-west-2": "quicksight.eu-west-2.amazonaws.com", "ap-northeast-3": "quicksight.ap-northeast-3.amazonaws.com", "eu-central-1": "quicksight.eu-central-1.amazonaws.com",
                           "us-east-2": "quicksight.us-east-2.amazonaws.com",
                           "us-east-1": "quicksight.us-east-1.amazonaws.com", "cn-northwest-1": "quicksight.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "quicksight.ap-south-1.amazonaws.com",
                           "eu-north-1": "quicksight.eu-north-1.amazonaws.com", "ap-northeast-2": "quicksight.ap-northeast-2.amazonaws.com",
                           "us-west-1": "quicksight.us-west-1.amazonaws.com", "us-gov-east-1": "quicksight.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "quicksight.eu-west-3.amazonaws.com", "cn-north-1": "quicksight.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "quicksight.sa-east-1.amazonaws.com",
                           "eu-west-1": "quicksight.eu-west-1.amazonaws.com", "us-gov-west-1": "quicksight.us-gov-west-1.amazonaws.com", "ap-southeast-2": "quicksight.ap-southeast-2.amazonaws.com", "ca-central-1": "quicksight.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "quicksight.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "quicksight.ap-southeast-1.amazonaws.com",
      "us-west-2": "quicksight.us-west-2.amazonaws.com",
      "eu-west-2": "quicksight.eu-west-2.amazonaws.com",
      "ap-northeast-3": "quicksight.ap-northeast-3.amazonaws.com",
      "eu-central-1": "quicksight.eu-central-1.amazonaws.com",
      "us-east-2": "quicksight.us-east-2.amazonaws.com",
      "us-east-1": "quicksight.us-east-1.amazonaws.com",
      "cn-northwest-1": "quicksight.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "quicksight.ap-south-1.amazonaws.com",
      "eu-north-1": "quicksight.eu-north-1.amazonaws.com",
      "ap-northeast-2": "quicksight.ap-northeast-2.amazonaws.com",
      "us-west-1": "quicksight.us-west-1.amazonaws.com",
      "us-gov-east-1": "quicksight.us-gov-east-1.amazonaws.com",
      "eu-west-3": "quicksight.eu-west-3.amazonaws.com",
      "cn-north-1": "quicksight.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "quicksight.sa-east-1.amazonaws.com",
      "eu-west-1": "quicksight.eu-west-1.amazonaws.com",
      "us-gov-west-1": "quicksight.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "quicksight.ap-southeast-2.amazonaws.com",
      "ca-central-1": "quicksight.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "quicksight"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateIngestion_606199 = ref object of OpenApiRestCall_605589
proc url_CreateIngestion_606201(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "IngestionId" in path, "`IngestionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/ingestions/"),
               (kind: VariableSegment, value: "IngestionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateIngestion_606200(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Creates and starts a new SPICE ingestion on a dataset</p> <p>Any ingestions operating on tagged datasets inherit the same tags automatically for use in access control. For an example, see <a href="https://aws.example.com/premiumsupport/knowledge-center/iam-ec2-resource-tags/">How do I create an IAM policy to control access to Amazon EC2 resources using tags?</a> in the AWS Knowledge Center. Tags are visible on the tagged dataset, but not on the ingestion resource.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  ##   DataSetId: JString (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   IngestionId: JString (required)
  ##              : An ID for the ingestion.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606202 = path.getOrDefault("AwsAccountId")
  valid_606202 = validateParameter(valid_606202, JString, required = true,
                                 default = nil)
  if valid_606202 != nil:
    section.add "AwsAccountId", valid_606202
  var valid_606203 = path.getOrDefault("DataSetId")
  valid_606203 = validateParameter(valid_606203, JString, required = true,
                                 default = nil)
  if valid_606203 != nil:
    section.add "DataSetId", valid_606203
  var valid_606204 = path.getOrDefault("IngestionId")
  valid_606204 = validateParameter(valid_606204, JString, required = true,
                                 default = nil)
  if valid_606204 != nil:
    section.add "IngestionId", valid_606204
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
  var valid_606205 = header.getOrDefault("X-Amz-Signature")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Signature", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Content-Sha256", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-Date")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Date", valid_606207
  var valid_606208 = header.getOrDefault("X-Amz-Credential")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-Credential", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-Security-Token")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-Security-Token", valid_606209
  var valid_606210 = header.getOrDefault("X-Amz-Algorithm")
  valid_606210 = validateParameter(valid_606210, JString, required = false,
                                 default = nil)
  if valid_606210 != nil:
    section.add "X-Amz-Algorithm", valid_606210
  var valid_606211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606211 = validateParameter(valid_606211, JString, required = false,
                                 default = nil)
  if valid_606211 != nil:
    section.add "X-Amz-SignedHeaders", valid_606211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606212: Call_CreateIngestion_606199; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates and starts a new SPICE ingestion on a dataset</p> <p>Any ingestions operating on tagged datasets inherit the same tags automatically for use in access control. For an example, see <a href="https://aws.example.com/premiumsupport/knowledge-center/iam-ec2-resource-tags/">How do I create an IAM policy to control access to Amazon EC2 resources using tags?</a> in the AWS Knowledge Center. Tags are visible on the tagged dataset, but not on the ingestion resource.</p>
  ## 
  let valid = call_606212.validator(path, query, header, formData, body)
  let scheme = call_606212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606212.url(scheme.get, call_606212.host, call_606212.base,
                         call_606212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606212, url, valid)

proc call*(call_606213: Call_CreateIngestion_606199; AwsAccountId: string;
          DataSetId: string; IngestionId: string): Recallable =
  ## createIngestion
  ## <p>Creates and starts a new SPICE ingestion on a dataset</p> <p>Any ingestions operating on tagged datasets inherit the same tags automatically for use in access control. For an example, see <a href="https://aws.example.com/premiumsupport/knowledge-center/iam-ec2-resource-tags/">How do I create an IAM policy to control access to Amazon EC2 resources using tags?</a> in the AWS Knowledge Center. Tags are visible on the tagged dataset, but not on the ingestion resource.</p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   IngestionId: string (required)
  ##              : An ID for the ingestion.
  var path_606214 = newJObject()
  add(path_606214, "AwsAccountId", newJString(AwsAccountId))
  add(path_606214, "DataSetId", newJString(DataSetId))
  add(path_606214, "IngestionId", newJString(IngestionId))
  result = call_606213.call(path_606214, nil, nil, nil, nil)

var createIngestion* = Call_CreateIngestion_606199(name: "createIngestion",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}",
    validator: validate_CreateIngestion_606200, base: "/", url: url_CreateIngestion_606201,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIngestion_605927 = ref object of OpenApiRestCall_605589
proc url_DescribeIngestion_605929(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "IngestionId" in path, "`IngestionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/ingestions/"),
               (kind: VariableSegment, value: "IngestionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeIngestion_605928(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Describes a SPICE ingestion.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  ##   DataSetId: JString (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   IngestionId: JString (required)
  ##              : An ID for the ingestion.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606055 = path.getOrDefault("AwsAccountId")
  valid_606055 = validateParameter(valid_606055, JString, required = true,
                                 default = nil)
  if valid_606055 != nil:
    section.add "AwsAccountId", valid_606055
  var valid_606056 = path.getOrDefault("DataSetId")
  valid_606056 = validateParameter(valid_606056, JString, required = true,
                                 default = nil)
  if valid_606056 != nil:
    section.add "DataSetId", valid_606056
  var valid_606057 = path.getOrDefault("IngestionId")
  valid_606057 = validateParameter(valid_606057, JString, required = true,
                                 default = nil)
  if valid_606057 != nil:
    section.add "IngestionId", valid_606057
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
  var valid_606058 = header.getOrDefault("X-Amz-Signature")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Signature", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Content-Sha256", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Date")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Date", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-Credential")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-Credential", valid_606061
  var valid_606062 = header.getOrDefault("X-Amz-Security-Token")
  valid_606062 = validateParameter(valid_606062, JString, required = false,
                                 default = nil)
  if valid_606062 != nil:
    section.add "X-Amz-Security-Token", valid_606062
  var valid_606063 = header.getOrDefault("X-Amz-Algorithm")
  valid_606063 = validateParameter(valid_606063, JString, required = false,
                                 default = nil)
  if valid_606063 != nil:
    section.add "X-Amz-Algorithm", valid_606063
  var valid_606064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606064 = validateParameter(valid_606064, JString, required = false,
                                 default = nil)
  if valid_606064 != nil:
    section.add "X-Amz-SignedHeaders", valid_606064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606087: Call_DescribeIngestion_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a SPICE ingestion.
  ## 
  let valid = call_606087.validator(path, query, header, formData, body)
  let scheme = call_606087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606087.url(scheme.get, call_606087.host, call_606087.base,
                         call_606087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606087, url, valid)

proc call*(call_606158: Call_DescribeIngestion_605927; AwsAccountId: string;
          DataSetId: string; IngestionId: string): Recallable =
  ## describeIngestion
  ## Describes a SPICE ingestion.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   IngestionId: string (required)
  ##              : An ID for the ingestion.
  var path_606159 = newJObject()
  add(path_606159, "AwsAccountId", newJString(AwsAccountId))
  add(path_606159, "DataSetId", newJString(DataSetId))
  add(path_606159, "IngestionId", newJString(IngestionId))
  result = call_606158.call(path_606159, nil, nil, nil, nil)

var describeIngestion* = Call_DescribeIngestion_605927(name: "describeIngestion",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}",
    validator: validate_DescribeIngestion_605928, base: "/",
    url: url_DescribeIngestion_605929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelIngestion_606215 = ref object of OpenApiRestCall_605589
proc url_CancelIngestion_606217(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  assert "IngestionId" in path, "`IngestionId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/ingestions/"),
               (kind: VariableSegment, value: "IngestionId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CancelIngestion_606216(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Cancels an ongoing ingestion of data into SPICE.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  ##   DataSetId: JString (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   IngestionId: JString (required)
  ##              : An ID for the ingestion.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606218 = path.getOrDefault("AwsAccountId")
  valid_606218 = validateParameter(valid_606218, JString, required = true,
                                 default = nil)
  if valid_606218 != nil:
    section.add "AwsAccountId", valid_606218
  var valid_606219 = path.getOrDefault("DataSetId")
  valid_606219 = validateParameter(valid_606219, JString, required = true,
                                 default = nil)
  if valid_606219 != nil:
    section.add "DataSetId", valid_606219
  var valid_606220 = path.getOrDefault("IngestionId")
  valid_606220 = validateParameter(valid_606220, JString, required = true,
                                 default = nil)
  if valid_606220 != nil:
    section.add "IngestionId", valid_606220
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
  var valid_606221 = header.getOrDefault("X-Amz-Signature")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-Signature", valid_606221
  var valid_606222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "X-Amz-Content-Sha256", valid_606222
  var valid_606223 = header.getOrDefault("X-Amz-Date")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-Date", valid_606223
  var valid_606224 = header.getOrDefault("X-Amz-Credential")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Credential", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-Security-Token")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-Security-Token", valid_606225
  var valid_606226 = header.getOrDefault("X-Amz-Algorithm")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "X-Amz-Algorithm", valid_606226
  var valid_606227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "X-Amz-SignedHeaders", valid_606227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606228: Call_CancelIngestion_606215; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels an ongoing ingestion of data into SPICE.
  ## 
  let valid = call_606228.validator(path, query, header, formData, body)
  let scheme = call_606228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606228.url(scheme.get, call_606228.host, call_606228.base,
                         call_606228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606228, url, valid)

proc call*(call_606229: Call_CancelIngestion_606215; AwsAccountId: string;
          DataSetId: string; IngestionId: string): Recallable =
  ## cancelIngestion
  ## Cancels an ongoing ingestion of data into SPICE.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   IngestionId: string (required)
  ##              : An ID for the ingestion.
  var path_606230 = newJObject()
  add(path_606230, "AwsAccountId", newJString(AwsAccountId))
  add(path_606230, "DataSetId", newJString(DataSetId))
  add(path_606230, "IngestionId", newJString(IngestionId))
  result = call_606229.call(path_606230, nil, nil, nil, nil)

var cancelIngestion* = Call_CancelIngestion_606215(name: "cancelIngestion",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}",
    validator: validate_CancelIngestion_606216, base: "/", url: url_CancelIngestion_606217,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDashboard_606249 = ref object of OpenApiRestCall_605589
proc url_UpdateDashboard_606251(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DashboardId" in path, "`DashboardId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/dashboards/"),
               (kind: VariableSegment, value: "DashboardId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDashboard_606250(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Updates a dashboard in an AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the dashboard that you're updating.
  ##   DashboardId: JString (required)
  ##              : The ID for the dashboard.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606252 = path.getOrDefault("AwsAccountId")
  valid_606252 = validateParameter(valid_606252, JString, required = true,
                                 default = nil)
  if valid_606252 != nil:
    section.add "AwsAccountId", valid_606252
  var valid_606253 = path.getOrDefault("DashboardId")
  valid_606253 = validateParameter(valid_606253, JString, required = true,
                                 default = nil)
  if valid_606253 != nil:
    section.add "DashboardId", valid_606253
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
  var valid_606254 = header.getOrDefault("X-Amz-Signature")
  valid_606254 = validateParameter(valid_606254, JString, required = false,
                                 default = nil)
  if valid_606254 != nil:
    section.add "X-Amz-Signature", valid_606254
  var valid_606255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606255 = validateParameter(valid_606255, JString, required = false,
                                 default = nil)
  if valid_606255 != nil:
    section.add "X-Amz-Content-Sha256", valid_606255
  var valid_606256 = header.getOrDefault("X-Amz-Date")
  valid_606256 = validateParameter(valid_606256, JString, required = false,
                                 default = nil)
  if valid_606256 != nil:
    section.add "X-Amz-Date", valid_606256
  var valid_606257 = header.getOrDefault("X-Amz-Credential")
  valid_606257 = validateParameter(valid_606257, JString, required = false,
                                 default = nil)
  if valid_606257 != nil:
    section.add "X-Amz-Credential", valid_606257
  var valid_606258 = header.getOrDefault("X-Amz-Security-Token")
  valid_606258 = validateParameter(valid_606258, JString, required = false,
                                 default = nil)
  if valid_606258 != nil:
    section.add "X-Amz-Security-Token", valid_606258
  var valid_606259 = header.getOrDefault("X-Amz-Algorithm")
  valid_606259 = validateParameter(valid_606259, JString, required = false,
                                 default = nil)
  if valid_606259 != nil:
    section.add "X-Amz-Algorithm", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-SignedHeaders", valid_606260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606262: Call_UpdateDashboard_606249; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a dashboard in an AWS account.
  ## 
  let valid = call_606262.validator(path, query, header, formData, body)
  let scheme = call_606262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606262.url(scheme.get, call_606262.host, call_606262.base,
                         call_606262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606262, url, valid)

proc call*(call_606263: Call_UpdateDashboard_606249; AwsAccountId: string;
          body: JsonNode; DashboardId: string): Recallable =
  ## updateDashboard
  ## Updates a dashboard in an AWS account.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're updating.
  ##   body: JObject (required)
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  var path_606264 = newJObject()
  var body_606265 = newJObject()
  add(path_606264, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_606265 = body
  add(path_606264, "DashboardId", newJString(DashboardId))
  result = call_606263.call(path_606264, nil, nil, nil, body_606265)

var updateDashboard* = Call_UpdateDashboard_606249(name: "updateDashboard",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}",
    validator: validate_UpdateDashboard_606250, base: "/", url: url_UpdateDashboard_606251,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDashboard_606266 = ref object of OpenApiRestCall_605589
proc url_CreateDashboard_606268(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DashboardId" in path, "`DashboardId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/dashboards/"),
               (kind: VariableSegment, value: "DashboardId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDashboard_606267(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Creates a dashboard from a template. To first create a template, see the CreateTemplate API operation.</p> <p>A dashboard is an entity in QuickSight that identifies QuickSight reports, created from analyses. You can share QuickSight dashboards. With the right permissions, you can create scheduled email reports from them. The <code>CreateDashboard</code>, <code>DescribeDashboard</code>, and <code>ListDashboardsByUser</code> API operations act on the dashboard entity. If you have the correct permissions, you can create a dashboard from a template that exists in a different AWS account.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account where you want to create the dashboard.
  ##   DashboardId: JString (required)
  ##              : The ID for the dashboard, also added to the IAM policy.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606269 = path.getOrDefault("AwsAccountId")
  valid_606269 = validateParameter(valid_606269, JString, required = true,
                                 default = nil)
  if valid_606269 != nil:
    section.add "AwsAccountId", valid_606269
  var valid_606270 = path.getOrDefault("DashboardId")
  valid_606270 = validateParameter(valid_606270, JString, required = true,
                                 default = nil)
  if valid_606270 != nil:
    section.add "DashboardId", valid_606270
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
  var valid_606271 = header.getOrDefault("X-Amz-Signature")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "X-Amz-Signature", valid_606271
  var valid_606272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "X-Amz-Content-Sha256", valid_606272
  var valid_606273 = header.getOrDefault("X-Amz-Date")
  valid_606273 = validateParameter(valid_606273, JString, required = false,
                                 default = nil)
  if valid_606273 != nil:
    section.add "X-Amz-Date", valid_606273
  var valid_606274 = header.getOrDefault("X-Amz-Credential")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "X-Amz-Credential", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Security-Token")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Security-Token", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Algorithm")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Algorithm", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-SignedHeaders", valid_606277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606279: Call_CreateDashboard_606266; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a dashboard from a template. To first create a template, see the CreateTemplate API operation.</p> <p>A dashboard is an entity in QuickSight that identifies QuickSight reports, created from analyses. You can share QuickSight dashboards. With the right permissions, you can create scheduled email reports from them. The <code>CreateDashboard</code>, <code>DescribeDashboard</code>, and <code>ListDashboardsByUser</code> API operations act on the dashboard entity. If you have the correct permissions, you can create a dashboard from a template that exists in a different AWS account.</p>
  ## 
  let valid = call_606279.validator(path, query, header, formData, body)
  let scheme = call_606279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606279.url(scheme.get, call_606279.host, call_606279.base,
                         call_606279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606279, url, valid)

proc call*(call_606280: Call_CreateDashboard_606266; AwsAccountId: string;
          body: JsonNode; DashboardId: string): Recallable =
  ## createDashboard
  ## <p>Creates a dashboard from a template. To first create a template, see the CreateTemplate API operation.</p> <p>A dashboard is an entity in QuickSight that identifies QuickSight reports, created from analyses. You can share QuickSight dashboards. With the right permissions, you can create scheduled email reports from them. The <code>CreateDashboard</code>, <code>DescribeDashboard</code>, and <code>ListDashboardsByUser</code> API operations act on the dashboard entity. If you have the correct permissions, you can create a dashboard from a template that exists in a different AWS account.</p>
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account where you want to create the dashboard.
  ##   body: JObject (required)
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard, also added to the IAM policy.
  var path_606281 = newJObject()
  var body_606282 = newJObject()
  add(path_606281, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_606282 = body
  add(path_606281, "DashboardId", newJString(DashboardId))
  result = call_606280.call(path_606281, nil, nil, nil, body_606282)

var createDashboard* = Call_CreateDashboard_606266(name: "createDashboard",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}",
    validator: validate_CreateDashboard_606267, base: "/", url: url_CreateDashboard_606268,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDashboard_606231 = ref object of OpenApiRestCall_605589
proc url_DescribeDashboard_606233(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DashboardId" in path, "`DashboardId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/dashboards/"),
               (kind: VariableSegment, value: "DashboardId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDashboard_606232(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Provides a summary for a dashboard.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the dashboard that you're describing.
  ##   DashboardId: JString (required)
  ##              : The ID for the dashboard.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606234 = path.getOrDefault("AwsAccountId")
  valid_606234 = validateParameter(valid_606234, JString, required = true,
                                 default = nil)
  if valid_606234 != nil:
    section.add "AwsAccountId", valid_606234
  var valid_606235 = path.getOrDefault("DashboardId")
  valid_606235 = validateParameter(valid_606235, JString, required = true,
                                 default = nil)
  if valid_606235 != nil:
    section.add "DashboardId", valid_606235
  result.add "path", section
  ## parameters in `query` object:
  ##   version-number: JInt
  ##                 : The version number for the dashboard. If a version number isn't passed, the latest published dashboard version is described. 
  ##   alias-name: JString
  ##             : The alias name.
  section = newJObject()
  var valid_606236 = query.getOrDefault("version-number")
  valid_606236 = validateParameter(valid_606236, JInt, required = false, default = nil)
  if valid_606236 != nil:
    section.add "version-number", valid_606236
  var valid_606237 = query.getOrDefault("alias-name")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "alias-name", valid_606237
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
  if body != nil:
    result.add "body", body

proc call*(call_606245: Call_DescribeDashboard_606231; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a summary for a dashboard.
  ## 
  let valid = call_606245.validator(path, query, header, formData, body)
  let scheme = call_606245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606245.url(scheme.get, call_606245.host, call_606245.base,
                         call_606245.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606245, url, valid)

proc call*(call_606246: Call_DescribeDashboard_606231; AwsAccountId: string;
          DashboardId: string; versionNumber: int = 0; aliasName: string = ""): Recallable =
  ## describeDashboard
  ## Provides a summary for a dashboard.
  ##   versionNumber: int
  ##                : The version number for the dashboard. If a version number isn't passed, the latest published dashboard version is described. 
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're describing.
  ##   aliasName: string
  ##            : The alias name.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  var path_606247 = newJObject()
  var query_606248 = newJObject()
  add(query_606248, "version-number", newJInt(versionNumber))
  add(path_606247, "AwsAccountId", newJString(AwsAccountId))
  add(query_606248, "alias-name", newJString(aliasName))
  add(path_606247, "DashboardId", newJString(DashboardId))
  result = call_606246.call(path_606247, query_606248, nil, nil, nil)

var describeDashboard* = Call_DescribeDashboard_606231(name: "describeDashboard",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}",
    validator: validate_DescribeDashboard_606232, base: "/",
    url: url_DescribeDashboard_606233, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDashboard_606283 = ref object of OpenApiRestCall_605589
proc url_DeleteDashboard_606285(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DashboardId" in path, "`DashboardId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/dashboards/"),
               (kind: VariableSegment, value: "DashboardId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDashboard_606284(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Deletes a dashboard.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the dashboard that you're deleting.
  ##   DashboardId: JString (required)
  ##              : The ID for the dashboard.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606286 = path.getOrDefault("AwsAccountId")
  valid_606286 = validateParameter(valid_606286, JString, required = true,
                                 default = nil)
  if valid_606286 != nil:
    section.add "AwsAccountId", valid_606286
  var valid_606287 = path.getOrDefault("DashboardId")
  valid_606287 = validateParameter(valid_606287, JString, required = true,
                                 default = nil)
  if valid_606287 != nil:
    section.add "DashboardId", valid_606287
  result.add "path", section
  ## parameters in `query` object:
  ##   version-number: JInt
  ##                 : The version number of the dashboard. If the version number property is provided, only the specified version of the dashboard is deleted.
  section = newJObject()
  var valid_606288 = query.getOrDefault("version-number")
  valid_606288 = validateParameter(valid_606288, JInt, required = false, default = nil)
  if valid_606288 != nil:
    section.add "version-number", valid_606288
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
  var valid_606289 = header.getOrDefault("X-Amz-Signature")
  valid_606289 = validateParameter(valid_606289, JString, required = false,
                                 default = nil)
  if valid_606289 != nil:
    section.add "X-Amz-Signature", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Content-Sha256", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Date")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Date", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-Credential")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-Credential", valid_606292
  var valid_606293 = header.getOrDefault("X-Amz-Security-Token")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Security-Token", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Algorithm")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Algorithm", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-SignedHeaders", valid_606295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606296: Call_DeleteDashboard_606283; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a dashboard.
  ## 
  let valid = call_606296.validator(path, query, header, formData, body)
  let scheme = call_606296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606296.url(scheme.get, call_606296.host, call_606296.base,
                         call_606296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606296, url, valid)

proc call*(call_606297: Call_DeleteDashboard_606283; AwsAccountId: string;
          DashboardId: string; versionNumber: int = 0): Recallable =
  ## deleteDashboard
  ## Deletes a dashboard.
  ##   versionNumber: int
  ##                : The version number of the dashboard. If the version number property is provided, only the specified version of the dashboard is deleted.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're deleting.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  var path_606298 = newJObject()
  var query_606299 = newJObject()
  add(query_606299, "version-number", newJInt(versionNumber))
  add(path_606298, "AwsAccountId", newJString(AwsAccountId))
  add(path_606298, "DashboardId", newJString(DashboardId))
  result = call_606297.call(path_606298, query_606299, nil, nil, nil)

var deleteDashboard* = Call_DeleteDashboard_606283(name: "deleteDashboard",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}",
    validator: validate_DeleteDashboard_606284, base: "/", url: url_DeleteDashboard_606285,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSet_606319 = ref object of OpenApiRestCall_605589
proc url_CreateDataSet_606321(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sets")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDataSet_606320(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a dataset.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606322 = path.getOrDefault("AwsAccountId")
  valid_606322 = validateParameter(valid_606322, JString, required = true,
                                 default = nil)
  if valid_606322 != nil:
    section.add "AwsAccountId", valid_606322
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
  var valid_606323 = header.getOrDefault("X-Amz-Signature")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Signature", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Content-Sha256", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-Date")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-Date", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-Credential")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-Credential", valid_606326
  var valid_606327 = header.getOrDefault("X-Amz-Security-Token")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "X-Amz-Security-Token", valid_606327
  var valid_606328 = header.getOrDefault("X-Amz-Algorithm")
  valid_606328 = validateParameter(valid_606328, JString, required = false,
                                 default = nil)
  if valid_606328 != nil:
    section.add "X-Amz-Algorithm", valid_606328
  var valid_606329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606329 = validateParameter(valid_606329, JString, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "X-Amz-SignedHeaders", valid_606329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606331: Call_CreateDataSet_606319; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a dataset.
  ## 
  let valid = call_606331.validator(path, query, header, formData, body)
  let scheme = call_606331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606331.url(scheme.get, call_606331.host, call_606331.base,
                         call_606331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606331, url, valid)

proc call*(call_606332: Call_CreateDataSet_606319; AwsAccountId: string;
          body: JsonNode): Recallable =
  ## createDataSet
  ## Creates a dataset.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   body: JObject (required)
  var path_606333 = newJObject()
  var body_606334 = newJObject()
  add(path_606333, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_606334 = body
  result = call_606332.call(path_606333, nil, nil, nil, body_606334)

var createDataSet* = Call_CreateDataSet_606319(name: "createDataSet",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets",
    validator: validate_CreateDataSet_606320, base: "/", url: url_CreateDataSet_606321,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSets_606300 = ref object of OpenApiRestCall_605589
proc url_ListDataSets_606302(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sets")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDataSets_606301(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists all of the datasets belonging to the current AWS account in an AWS Region.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/*</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606303 = path.getOrDefault("AwsAccountId")
  valid_606303 = validateParameter(valid_606303, JString, required = true,
                                 default = nil)
  if valid_606303 != nil:
    section.add "AwsAccountId", valid_606303
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_606304 = query.getOrDefault("MaxResults")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "MaxResults", valid_606304
  var valid_606305 = query.getOrDefault("NextToken")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "NextToken", valid_606305
  var valid_606306 = query.getOrDefault("max-results")
  valid_606306 = validateParameter(valid_606306, JInt, required = false, default = nil)
  if valid_606306 != nil:
    section.add "max-results", valid_606306
  var valid_606307 = query.getOrDefault("next-token")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "next-token", valid_606307
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
  var valid_606308 = header.getOrDefault("X-Amz-Signature")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Signature", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Content-Sha256", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Date")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Date", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-Credential")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-Credential", valid_606311
  var valid_606312 = header.getOrDefault("X-Amz-Security-Token")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "X-Amz-Security-Token", valid_606312
  var valid_606313 = header.getOrDefault("X-Amz-Algorithm")
  valid_606313 = validateParameter(valid_606313, JString, required = false,
                                 default = nil)
  if valid_606313 != nil:
    section.add "X-Amz-Algorithm", valid_606313
  var valid_606314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606314 = validateParameter(valid_606314, JString, required = false,
                                 default = nil)
  if valid_606314 != nil:
    section.add "X-Amz-SignedHeaders", valid_606314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606315: Call_ListDataSets_606300; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all of the datasets belonging to the current AWS account in an AWS Region.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/*</code>.</p>
  ## 
  let valid = call_606315.validator(path, query, header, formData, body)
  let scheme = call_606315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606315.url(scheme.get, call_606315.host, call_606315.base,
                         call_606315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606315, url, valid)

proc call*(call_606316: Call_ListDataSets_606300; AwsAccountId: string;
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listDataSets
  ## <p>Lists all of the datasets belonging to the current AWS account in an AWS Region.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/*</code>.</p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  var path_606317 = newJObject()
  var query_606318 = newJObject()
  add(path_606317, "AwsAccountId", newJString(AwsAccountId))
  add(query_606318, "MaxResults", newJString(MaxResults))
  add(query_606318, "NextToken", newJString(NextToken))
  add(query_606318, "max-results", newJInt(maxResults))
  add(query_606318, "next-token", newJString(nextToken))
  result = call_606316.call(path_606317, query_606318, nil, nil, nil)

var listDataSets* = Call_ListDataSets_606300(name: "listDataSets",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets", validator: validate_ListDataSets_606301,
    base: "/", url: url_ListDataSets_606302, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSource_606354 = ref object of OpenApiRestCall_605589
proc url_CreateDataSource_606356(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sources")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDataSource_606355(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a data source.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606357 = path.getOrDefault("AwsAccountId")
  valid_606357 = validateParameter(valid_606357, JString, required = true,
                                 default = nil)
  if valid_606357 != nil:
    section.add "AwsAccountId", valid_606357
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
  var valid_606358 = header.getOrDefault("X-Amz-Signature")
  valid_606358 = validateParameter(valid_606358, JString, required = false,
                                 default = nil)
  if valid_606358 != nil:
    section.add "X-Amz-Signature", valid_606358
  var valid_606359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606359 = validateParameter(valid_606359, JString, required = false,
                                 default = nil)
  if valid_606359 != nil:
    section.add "X-Amz-Content-Sha256", valid_606359
  var valid_606360 = header.getOrDefault("X-Amz-Date")
  valid_606360 = validateParameter(valid_606360, JString, required = false,
                                 default = nil)
  if valid_606360 != nil:
    section.add "X-Amz-Date", valid_606360
  var valid_606361 = header.getOrDefault("X-Amz-Credential")
  valid_606361 = validateParameter(valid_606361, JString, required = false,
                                 default = nil)
  if valid_606361 != nil:
    section.add "X-Amz-Credential", valid_606361
  var valid_606362 = header.getOrDefault("X-Amz-Security-Token")
  valid_606362 = validateParameter(valid_606362, JString, required = false,
                                 default = nil)
  if valid_606362 != nil:
    section.add "X-Amz-Security-Token", valid_606362
  var valid_606363 = header.getOrDefault("X-Amz-Algorithm")
  valid_606363 = validateParameter(valid_606363, JString, required = false,
                                 default = nil)
  if valid_606363 != nil:
    section.add "X-Amz-Algorithm", valid_606363
  var valid_606364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606364 = validateParameter(valid_606364, JString, required = false,
                                 default = nil)
  if valid_606364 != nil:
    section.add "X-Amz-SignedHeaders", valid_606364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606366: Call_CreateDataSource_606354; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a data source.
  ## 
  let valid = call_606366.validator(path, query, header, formData, body)
  let scheme = call_606366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606366.url(scheme.get, call_606366.host, call_606366.base,
                         call_606366.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606366, url, valid)

proc call*(call_606367: Call_CreateDataSource_606354; AwsAccountId: string;
          body: JsonNode): Recallable =
  ## createDataSource
  ## Creates a data source.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   body: JObject (required)
  var path_606368 = newJObject()
  var body_606369 = newJObject()
  add(path_606368, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_606369 = body
  result = call_606367.call(path_606368, nil, nil, nil, body_606369)

var createDataSource* = Call_CreateDataSource_606354(name: "createDataSource",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources",
    validator: validate_CreateDataSource_606355, base: "/",
    url: url_CreateDataSource_606356, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSources_606335 = ref object of OpenApiRestCall_605589
proc url_ListDataSources_606337(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sources")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDataSources_606336(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Lists data sources in current AWS Region that belong to this AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606338 = path.getOrDefault("AwsAccountId")
  valid_606338 = validateParameter(valid_606338, JString, required = true,
                                 default = nil)
  if valid_606338 != nil:
    section.add "AwsAccountId", valid_606338
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_606339 = query.getOrDefault("MaxResults")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "MaxResults", valid_606339
  var valid_606340 = query.getOrDefault("NextToken")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "NextToken", valid_606340
  var valid_606341 = query.getOrDefault("max-results")
  valid_606341 = validateParameter(valid_606341, JInt, required = false, default = nil)
  if valid_606341 != nil:
    section.add "max-results", valid_606341
  var valid_606342 = query.getOrDefault("next-token")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "next-token", valid_606342
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
  var valid_606343 = header.getOrDefault("X-Amz-Signature")
  valid_606343 = validateParameter(valid_606343, JString, required = false,
                                 default = nil)
  if valid_606343 != nil:
    section.add "X-Amz-Signature", valid_606343
  var valid_606344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "X-Amz-Content-Sha256", valid_606344
  var valid_606345 = header.getOrDefault("X-Amz-Date")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "X-Amz-Date", valid_606345
  var valid_606346 = header.getOrDefault("X-Amz-Credential")
  valid_606346 = validateParameter(valid_606346, JString, required = false,
                                 default = nil)
  if valid_606346 != nil:
    section.add "X-Amz-Credential", valid_606346
  var valid_606347 = header.getOrDefault("X-Amz-Security-Token")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "X-Amz-Security-Token", valid_606347
  var valid_606348 = header.getOrDefault("X-Amz-Algorithm")
  valid_606348 = validateParameter(valid_606348, JString, required = false,
                                 default = nil)
  if valid_606348 != nil:
    section.add "X-Amz-Algorithm", valid_606348
  var valid_606349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606349 = validateParameter(valid_606349, JString, required = false,
                                 default = nil)
  if valid_606349 != nil:
    section.add "X-Amz-SignedHeaders", valid_606349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606350: Call_ListDataSources_606335; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists data sources in current AWS Region that belong to this AWS account.
  ## 
  let valid = call_606350.validator(path, query, header, formData, body)
  let scheme = call_606350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606350.url(scheme.get, call_606350.host, call_606350.base,
                         call_606350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606350, url, valid)

proc call*(call_606351: Call_ListDataSources_606335; AwsAccountId: string;
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listDataSources
  ## Lists data sources in current AWS Region that belong to this AWS account.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  var path_606352 = newJObject()
  var query_606353 = newJObject()
  add(path_606352, "AwsAccountId", newJString(AwsAccountId))
  add(query_606353, "MaxResults", newJString(MaxResults))
  add(query_606353, "NextToken", newJString(NextToken))
  add(query_606353, "max-results", newJInt(maxResults))
  add(query_606353, "next-token", newJString(nextToken))
  result = call_606351.call(path_606352, query_606353, nil, nil, nil)

var listDataSources* = Call_ListDataSources_606335(name: "listDataSources",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources",
    validator: validate_ListDataSources_606336, base: "/", url: url_ListDataSources_606337,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroup_606388 = ref object of OpenApiRestCall_605589
proc url_CreateGroup_606390(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/groups")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateGroup_606389(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an Amazon QuickSight group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;relevant-aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a group object.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606391 = path.getOrDefault("AwsAccountId")
  valid_606391 = validateParameter(valid_606391, JString, required = true,
                                 default = nil)
  if valid_606391 != nil:
    section.add "AwsAccountId", valid_606391
  var valid_606392 = path.getOrDefault("Namespace")
  valid_606392 = validateParameter(valid_606392, JString, required = true,
                                 default = nil)
  if valid_606392 != nil:
    section.add "Namespace", valid_606392
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
  var valid_606393 = header.getOrDefault("X-Amz-Signature")
  valid_606393 = validateParameter(valid_606393, JString, required = false,
                                 default = nil)
  if valid_606393 != nil:
    section.add "X-Amz-Signature", valid_606393
  var valid_606394 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606394 = validateParameter(valid_606394, JString, required = false,
                                 default = nil)
  if valid_606394 != nil:
    section.add "X-Amz-Content-Sha256", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-Date")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-Date", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-Credential")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-Credential", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-Security-Token")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Security-Token", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Algorithm")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Algorithm", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-SignedHeaders", valid_606399
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606401: Call_CreateGroup_606388; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon QuickSight group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;relevant-aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a group object.</p>
  ## 
  let valid = call_606401.validator(path, query, header, formData, body)
  let scheme = call_606401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606401.url(scheme.get, call_606401.host, call_606401.base,
                         call_606401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606401, url, valid)

proc call*(call_606402: Call_CreateGroup_606388; AwsAccountId: string;
          Namespace: string; body: JsonNode): Recallable =
  ## createGroup
  ## <p>Creates an Amazon QuickSight group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;relevant-aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a group object.</p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   body: JObject (required)
  var path_606403 = newJObject()
  var body_606404 = newJObject()
  add(path_606403, "AwsAccountId", newJString(AwsAccountId))
  add(path_606403, "Namespace", newJString(Namespace))
  if body != nil:
    body_606404 = body
  result = call_606402.call(path_606403, nil, nil, nil, body_606404)

var createGroup* = Call_CreateGroup_606388(name: "createGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups",
                                        validator: validate_CreateGroup_606389,
                                        base: "/", url: url_CreateGroup_606390,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_606370 = ref object of OpenApiRestCall_605589
proc url_ListGroups_606372(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/groups")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListGroups_606371(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all user groups in Amazon QuickSight. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606373 = path.getOrDefault("AwsAccountId")
  valid_606373 = validateParameter(valid_606373, JString, required = true,
                                 default = nil)
  if valid_606373 != nil:
    section.add "AwsAccountId", valid_606373
  var valid_606374 = path.getOrDefault("Namespace")
  valid_606374 = validateParameter(valid_606374, JString, required = true,
                                 default = nil)
  if valid_606374 != nil:
    section.add "Namespace", valid_606374
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_606375 = query.getOrDefault("max-results")
  valid_606375 = validateParameter(valid_606375, JInt, required = false, default = nil)
  if valid_606375 != nil:
    section.add "max-results", valid_606375
  var valid_606376 = query.getOrDefault("next-token")
  valid_606376 = validateParameter(valid_606376, JString, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "next-token", valid_606376
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
  var valid_606377 = header.getOrDefault("X-Amz-Signature")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "X-Amz-Signature", valid_606377
  var valid_606378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "X-Amz-Content-Sha256", valid_606378
  var valid_606379 = header.getOrDefault("X-Amz-Date")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "X-Amz-Date", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Credential")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Credential", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-Security-Token")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Security-Token", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Algorithm")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Algorithm", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-SignedHeaders", valid_606383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606384: Call_ListGroups_606370; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all user groups in Amazon QuickSight. 
  ## 
  let valid = call_606384.validator(path, query, header, formData, body)
  let scheme = call_606384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606384.url(scheme.get, call_606384.host, call_606384.base,
                         call_606384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606384, url, valid)

proc call*(call_606385: Call_ListGroups_606370; AwsAccountId: string;
          Namespace: string; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listGroups
  ## Lists all user groups in Amazon QuickSight. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   maxResults: int
  ##             : The maximum number of results to return.
  ##   nextToken: string
  ##            : A pagination token that can be used in a subsequent request.
  var path_606386 = newJObject()
  var query_606387 = newJObject()
  add(path_606386, "AwsAccountId", newJString(AwsAccountId))
  add(path_606386, "Namespace", newJString(Namespace))
  add(query_606387, "max-results", newJInt(maxResults))
  add(query_606387, "next-token", newJString(nextToken))
  result = call_606385.call(path_606386, query_606387, nil, nil, nil)

var listGroups* = Call_ListGroups_606370(name: "listGroups",
                                      meth: HttpMethod.HttpGet,
                                      host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups",
                                      validator: validate_ListGroups_606371,
                                      base: "/", url: url_ListGroups_606372,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroupMembership_606405 = ref object of OpenApiRestCall_605589
proc url_CreateGroupMembership_606407(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  assert "MemberName" in path, "`MemberName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName"),
               (kind: ConstantSegment, value: "/members/"),
               (kind: VariableSegment, value: "MemberName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateGroupMembership_606406(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds an Amazon QuickSight user to an Amazon QuickSight group. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the group that you want to add the user to.
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   MemberName: JString (required)
  ##             : The name of the user that you want to add to the group membership.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_606408 = path.getOrDefault("GroupName")
  valid_606408 = validateParameter(valid_606408, JString, required = true,
                                 default = nil)
  if valid_606408 != nil:
    section.add "GroupName", valid_606408
  var valid_606409 = path.getOrDefault("AwsAccountId")
  valid_606409 = validateParameter(valid_606409, JString, required = true,
                                 default = nil)
  if valid_606409 != nil:
    section.add "AwsAccountId", valid_606409
  var valid_606410 = path.getOrDefault("Namespace")
  valid_606410 = validateParameter(valid_606410, JString, required = true,
                                 default = nil)
  if valid_606410 != nil:
    section.add "Namespace", valid_606410
  var valid_606411 = path.getOrDefault("MemberName")
  valid_606411 = validateParameter(valid_606411, JString, required = true,
                                 default = nil)
  if valid_606411 != nil:
    section.add "MemberName", valid_606411
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
  var valid_606412 = header.getOrDefault("X-Amz-Signature")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Signature", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Content-Sha256", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-Date")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Date", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-Credential")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Credential", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-Security-Token")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-Security-Token", valid_606416
  var valid_606417 = header.getOrDefault("X-Amz-Algorithm")
  valid_606417 = validateParameter(valid_606417, JString, required = false,
                                 default = nil)
  if valid_606417 != nil:
    section.add "X-Amz-Algorithm", valid_606417
  var valid_606418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "X-Amz-SignedHeaders", valid_606418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606419: Call_CreateGroupMembership_606405; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds an Amazon QuickSight user to an Amazon QuickSight group. 
  ## 
  let valid = call_606419.validator(path, query, header, formData, body)
  let scheme = call_606419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606419.url(scheme.get, call_606419.host, call_606419.base,
                         call_606419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606419, url, valid)

proc call*(call_606420: Call_CreateGroupMembership_606405; GroupName: string;
          AwsAccountId: string; Namespace: string; MemberName: string): Recallable =
  ## createGroupMembership
  ## Adds an Amazon QuickSight user to an Amazon QuickSight group. 
  ##   GroupName: string (required)
  ##            : The name of the group that you want to add the user to.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   MemberName: string (required)
  ##             : The name of the user that you want to add to the group membership.
  var path_606421 = newJObject()
  add(path_606421, "GroupName", newJString(GroupName))
  add(path_606421, "AwsAccountId", newJString(AwsAccountId))
  add(path_606421, "Namespace", newJString(Namespace))
  add(path_606421, "MemberName", newJString(MemberName))
  result = call_606420.call(path_606421, nil, nil, nil, nil)

var createGroupMembership* = Call_CreateGroupMembership_606405(
    name: "createGroupMembership", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members/{MemberName}",
    validator: validate_CreateGroupMembership_606406, base: "/",
    url: url_CreateGroupMembership_606407, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroupMembership_606422 = ref object of OpenApiRestCall_605589
proc url_DeleteGroupMembership_606424(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  assert "MemberName" in path, "`MemberName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName"),
               (kind: ConstantSegment, value: "/members/"),
               (kind: VariableSegment, value: "MemberName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteGroupMembership_606423(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a user from a group so that the user is no longer a member of the group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the group that you want to delete the user from.
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   MemberName: JString (required)
  ##             : The name of the user that you want to delete from the group membership.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_606425 = path.getOrDefault("GroupName")
  valid_606425 = validateParameter(valid_606425, JString, required = true,
                                 default = nil)
  if valid_606425 != nil:
    section.add "GroupName", valid_606425
  var valid_606426 = path.getOrDefault("AwsAccountId")
  valid_606426 = validateParameter(valid_606426, JString, required = true,
                                 default = nil)
  if valid_606426 != nil:
    section.add "AwsAccountId", valid_606426
  var valid_606427 = path.getOrDefault("Namespace")
  valid_606427 = validateParameter(valid_606427, JString, required = true,
                                 default = nil)
  if valid_606427 != nil:
    section.add "Namespace", valid_606427
  var valid_606428 = path.getOrDefault("MemberName")
  valid_606428 = validateParameter(valid_606428, JString, required = true,
                                 default = nil)
  if valid_606428 != nil:
    section.add "MemberName", valid_606428
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
  var valid_606429 = header.getOrDefault("X-Amz-Signature")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-Signature", valid_606429
  var valid_606430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Content-Sha256", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-Date")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-Date", valid_606431
  var valid_606432 = header.getOrDefault("X-Amz-Credential")
  valid_606432 = validateParameter(valid_606432, JString, required = false,
                                 default = nil)
  if valid_606432 != nil:
    section.add "X-Amz-Credential", valid_606432
  var valid_606433 = header.getOrDefault("X-Amz-Security-Token")
  valid_606433 = validateParameter(valid_606433, JString, required = false,
                                 default = nil)
  if valid_606433 != nil:
    section.add "X-Amz-Security-Token", valid_606433
  var valid_606434 = header.getOrDefault("X-Amz-Algorithm")
  valid_606434 = validateParameter(valid_606434, JString, required = false,
                                 default = nil)
  if valid_606434 != nil:
    section.add "X-Amz-Algorithm", valid_606434
  var valid_606435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "X-Amz-SignedHeaders", valid_606435
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606436: Call_DeleteGroupMembership_606422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a user from a group so that the user is no longer a member of the group.
  ## 
  let valid = call_606436.validator(path, query, header, formData, body)
  let scheme = call_606436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606436.url(scheme.get, call_606436.host, call_606436.base,
                         call_606436.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606436, url, valid)

proc call*(call_606437: Call_DeleteGroupMembership_606422; GroupName: string;
          AwsAccountId: string; Namespace: string; MemberName: string): Recallable =
  ## deleteGroupMembership
  ## Removes a user from a group so that the user is no longer a member of the group.
  ##   GroupName: string (required)
  ##            : The name of the group that you want to delete the user from.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   MemberName: string (required)
  ##             : The name of the user that you want to delete from the group membership.
  var path_606438 = newJObject()
  add(path_606438, "GroupName", newJString(GroupName))
  add(path_606438, "AwsAccountId", newJString(AwsAccountId))
  add(path_606438, "Namespace", newJString(Namespace))
  add(path_606438, "MemberName", newJString(MemberName))
  result = call_606437.call(path_606438, nil, nil, nil, nil)

var deleteGroupMembership* = Call_DeleteGroupMembership_606422(
    name: "deleteGroupMembership", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members/{MemberName}",
    validator: validate_DeleteGroupMembership_606423, base: "/",
    url: url_DeleteGroupMembership_606424, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIAMPolicyAssignment_606439 = ref object of OpenApiRestCall_605589
proc url_CreateIAMPolicyAssignment_606441(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/iam-policy-assignments/")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateIAMPolicyAssignment_606440(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an assignment with one specified IAM policy, identified by its Amazon Resource Name (ARN). This policy will be assigned to specified groups or users of Amazon QuickSight. The users and groups need to be in the same namespace. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account where you want to assign an IAM policy to QuickSight users or groups.
  ##   Namespace: JString (required)
  ##            : The namespace that contains the assignment.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606442 = path.getOrDefault("AwsAccountId")
  valid_606442 = validateParameter(valid_606442, JString, required = true,
                                 default = nil)
  if valid_606442 != nil:
    section.add "AwsAccountId", valid_606442
  var valid_606443 = path.getOrDefault("Namespace")
  valid_606443 = validateParameter(valid_606443, JString, required = true,
                                 default = nil)
  if valid_606443 != nil:
    section.add "Namespace", valid_606443
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
  var valid_606444 = header.getOrDefault("X-Amz-Signature")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-Signature", valid_606444
  var valid_606445 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-Content-Sha256", valid_606445
  var valid_606446 = header.getOrDefault("X-Amz-Date")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-Date", valid_606446
  var valid_606447 = header.getOrDefault("X-Amz-Credential")
  valid_606447 = validateParameter(valid_606447, JString, required = false,
                                 default = nil)
  if valid_606447 != nil:
    section.add "X-Amz-Credential", valid_606447
  var valid_606448 = header.getOrDefault("X-Amz-Security-Token")
  valid_606448 = validateParameter(valid_606448, JString, required = false,
                                 default = nil)
  if valid_606448 != nil:
    section.add "X-Amz-Security-Token", valid_606448
  var valid_606449 = header.getOrDefault("X-Amz-Algorithm")
  valid_606449 = validateParameter(valid_606449, JString, required = false,
                                 default = nil)
  if valid_606449 != nil:
    section.add "X-Amz-Algorithm", valid_606449
  var valid_606450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "X-Amz-SignedHeaders", valid_606450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606452: Call_CreateIAMPolicyAssignment_606439; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an assignment with one specified IAM policy, identified by its Amazon Resource Name (ARN). This policy will be assigned to specified groups or users of Amazon QuickSight. The users and groups need to be in the same namespace. 
  ## 
  let valid = call_606452.validator(path, query, header, formData, body)
  let scheme = call_606452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606452.url(scheme.get, call_606452.host, call_606452.base,
                         call_606452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606452, url, valid)

proc call*(call_606453: Call_CreateIAMPolicyAssignment_606439;
          AwsAccountId: string; Namespace: string; body: JsonNode): Recallable =
  ## createIAMPolicyAssignment
  ## Creates an assignment with one specified IAM policy, identified by its Amazon Resource Name (ARN). This policy will be assigned to specified groups or users of Amazon QuickSight. The users and groups need to be in the same namespace. 
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account where you want to assign an IAM policy to QuickSight users or groups.
  ##   Namespace: string (required)
  ##            : The namespace that contains the assignment.
  ##   body: JObject (required)
  var path_606454 = newJObject()
  var body_606455 = newJObject()
  add(path_606454, "AwsAccountId", newJString(AwsAccountId))
  add(path_606454, "Namespace", newJString(Namespace))
  if body != nil:
    body_606455 = body
  result = call_606453.call(path_606454, nil, nil, nil, body_606455)

var createIAMPolicyAssignment* = Call_CreateIAMPolicyAssignment_606439(
    name: "createIAMPolicyAssignment", meth: HttpMethod.HttpPost,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/",
    validator: validate_CreateIAMPolicyAssignment_606440, base: "/",
    url: url_CreateIAMPolicyAssignment_606441,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTemplate_606474 = ref object of OpenApiRestCall_605589
proc url_UpdateTemplate_606476(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "TemplateId" in path, "`TemplateId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/templates/"),
               (kind: VariableSegment, value: "TemplateId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateTemplate_606475(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Updates a template from an existing Amazon QuickSight analysis or another template.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the template that you're updating.
  ##   TemplateId: JString (required)
  ##             : The ID for the template.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606477 = path.getOrDefault("AwsAccountId")
  valid_606477 = validateParameter(valid_606477, JString, required = true,
                                 default = nil)
  if valid_606477 != nil:
    section.add "AwsAccountId", valid_606477
  var valid_606478 = path.getOrDefault("TemplateId")
  valid_606478 = validateParameter(valid_606478, JString, required = true,
                                 default = nil)
  if valid_606478 != nil:
    section.add "TemplateId", valid_606478
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
  var valid_606479 = header.getOrDefault("X-Amz-Signature")
  valid_606479 = validateParameter(valid_606479, JString, required = false,
                                 default = nil)
  if valid_606479 != nil:
    section.add "X-Amz-Signature", valid_606479
  var valid_606480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606480 = validateParameter(valid_606480, JString, required = false,
                                 default = nil)
  if valid_606480 != nil:
    section.add "X-Amz-Content-Sha256", valid_606480
  var valid_606481 = header.getOrDefault("X-Amz-Date")
  valid_606481 = validateParameter(valid_606481, JString, required = false,
                                 default = nil)
  if valid_606481 != nil:
    section.add "X-Amz-Date", valid_606481
  var valid_606482 = header.getOrDefault("X-Amz-Credential")
  valid_606482 = validateParameter(valid_606482, JString, required = false,
                                 default = nil)
  if valid_606482 != nil:
    section.add "X-Amz-Credential", valid_606482
  var valid_606483 = header.getOrDefault("X-Amz-Security-Token")
  valid_606483 = validateParameter(valid_606483, JString, required = false,
                                 default = nil)
  if valid_606483 != nil:
    section.add "X-Amz-Security-Token", valid_606483
  var valid_606484 = header.getOrDefault("X-Amz-Algorithm")
  valid_606484 = validateParameter(valid_606484, JString, required = false,
                                 default = nil)
  if valid_606484 != nil:
    section.add "X-Amz-Algorithm", valid_606484
  var valid_606485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "X-Amz-SignedHeaders", valid_606485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606487: Call_UpdateTemplate_606474; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a template from an existing Amazon QuickSight analysis or another template.
  ## 
  let valid = call_606487.validator(path, query, header, formData, body)
  let scheme = call_606487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606487.url(scheme.get, call_606487.host, call_606487.base,
                         call_606487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606487, url, valid)

proc call*(call_606488: Call_UpdateTemplate_606474; AwsAccountId: string;
          TemplateId: string; body: JsonNode): Recallable =
  ## updateTemplate
  ## Updates a template from an existing Amazon QuickSight analysis or another template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template that you're updating.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  ##   body: JObject (required)
  var path_606489 = newJObject()
  var body_606490 = newJObject()
  add(path_606489, "AwsAccountId", newJString(AwsAccountId))
  add(path_606489, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_606490 = body
  result = call_606488.call(path_606489, nil, nil, nil, body_606490)

var updateTemplate* = Call_UpdateTemplate_606474(name: "updateTemplate",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}",
    validator: validate_UpdateTemplate_606475, base: "/", url: url_UpdateTemplate_606476,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTemplate_606491 = ref object of OpenApiRestCall_605589
proc url_CreateTemplate_606493(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "TemplateId" in path, "`TemplateId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/templates/"),
               (kind: VariableSegment, value: "TemplateId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateTemplate_606492(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates a template from an existing QuickSight analysis or template. You can use the resulting template to create a dashboard.</p> <p>A <i>template</i> is an entity in QuickSight that encapsulates the metadata required to create an analysis and that you can use to create s dashboard. A template adds a layer of abstraction by using placeholders to replace the dataset associated with the analysis. You can use templates to create dashboards by replacing dataset placeholders with datasets that follow the same schema that was used to create the source analysis and template.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   TemplateId: JString (required)
  ##             : An ID for the template that you want to create. This template is unique per AWS Region in each AWS account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606494 = path.getOrDefault("AwsAccountId")
  valid_606494 = validateParameter(valid_606494, JString, required = true,
                                 default = nil)
  if valid_606494 != nil:
    section.add "AwsAccountId", valid_606494
  var valid_606495 = path.getOrDefault("TemplateId")
  valid_606495 = validateParameter(valid_606495, JString, required = true,
                                 default = nil)
  if valid_606495 != nil:
    section.add "TemplateId", valid_606495
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
  var valid_606496 = header.getOrDefault("X-Amz-Signature")
  valid_606496 = validateParameter(valid_606496, JString, required = false,
                                 default = nil)
  if valid_606496 != nil:
    section.add "X-Amz-Signature", valid_606496
  var valid_606497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606497 = validateParameter(valid_606497, JString, required = false,
                                 default = nil)
  if valid_606497 != nil:
    section.add "X-Amz-Content-Sha256", valid_606497
  var valid_606498 = header.getOrDefault("X-Amz-Date")
  valid_606498 = validateParameter(valid_606498, JString, required = false,
                                 default = nil)
  if valid_606498 != nil:
    section.add "X-Amz-Date", valid_606498
  var valid_606499 = header.getOrDefault("X-Amz-Credential")
  valid_606499 = validateParameter(valid_606499, JString, required = false,
                                 default = nil)
  if valid_606499 != nil:
    section.add "X-Amz-Credential", valid_606499
  var valid_606500 = header.getOrDefault("X-Amz-Security-Token")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-Security-Token", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-Algorithm")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-Algorithm", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-SignedHeaders", valid_606502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606504: Call_CreateTemplate_606491; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a template from an existing QuickSight analysis or template. You can use the resulting template to create a dashboard.</p> <p>A <i>template</i> is an entity in QuickSight that encapsulates the metadata required to create an analysis and that you can use to create s dashboard. A template adds a layer of abstraction by using placeholders to replace the dataset associated with the analysis. You can use templates to create dashboards by replacing dataset placeholders with datasets that follow the same schema that was used to create the source analysis and template.</p>
  ## 
  let valid = call_606504.validator(path, query, header, formData, body)
  let scheme = call_606504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606504.url(scheme.get, call_606504.host, call_606504.base,
                         call_606504.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606504, url, valid)

proc call*(call_606505: Call_CreateTemplate_606491; AwsAccountId: string;
          TemplateId: string; body: JsonNode): Recallable =
  ## createTemplate
  ## <p>Creates a template from an existing QuickSight analysis or template. You can use the resulting template to create a dashboard.</p> <p>A <i>template</i> is an entity in QuickSight that encapsulates the metadata required to create an analysis and that you can use to create s dashboard. A template adds a layer of abstraction by using placeholders to replace the dataset associated with the analysis. You can use templates to create dashboards by replacing dataset placeholders with datasets that follow the same schema that was used to create the source analysis and template.</p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   TemplateId: string (required)
  ##             : An ID for the template that you want to create. This template is unique per AWS Region in each AWS account.
  ##   body: JObject (required)
  var path_606506 = newJObject()
  var body_606507 = newJObject()
  add(path_606506, "AwsAccountId", newJString(AwsAccountId))
  add(path_606506, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_606507 = body
  result = call_606505.call(path_606506, nil, nil, nil, body_606507)

var createTemplate* = Call_CreateTemplate_606491(name: "createTemplate",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}",
    validator: validate_CreateTemplate_606492, base: "/", url: url_CreateTemplate_606493,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTemplate_606456 = ref object of OpenApiRestCall_605589
proc url_DescribeTemplate_606458(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "TemplateId" in path, "`TemplateId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/templates/"),
               (kind: VariableSegment, value: "TemplateId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeTemplate_606457(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Describes a template's metadata.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the template that you're describing.
  ##   TemplateId: JString (required)
  ##             : The ID for the template.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606459 = path.getOrDefault("AwsAccountId")
  valid_606459 = validateParameter(valid_606459, JString, required = true,
                                 default = nil)
  if valid_606459 != nil:
    section.add "AwsAccountId", valid_606459
  var valid_606460 = path.getOrDefault("TemplateId")
  valid_606460 = validateParameter(valid_606460, JString, required = true,
                                 default = nil)
  if valid_606460 != nil:
    section.add "TemplateId", valid_606460
  result.add "path", section
  ## parameters in `query` object:
  ##   version-number: JInt
  ##                 : (Optional) The number for the version to describe. If a <code>VersionNumber</code> parameter value isn't provided, the latest version of the template is described.
  ##   alias-name: JString
  ##             : The alias of the template that you want to describe. If you name a specific alias, you describe the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. The keyword <code>$PUBLISHED</code> doesn't apply to templates.
  section = newJObject()
  var valid_606461 = query.getOrDefault("version-number")
  valid_606461 = validateParameter(valid_606461, JInt, required = false, default = nil)
  if valid_606461 != nil:
    section.add "version-number", valid_606461
  var valid_606462 = query.getOrDefault("alias-name")
  valid_606462 = validateParameter(valid_606462, JString, required = false,
                                 default = nil)
  if valid_606462 != nil:
    section.add "alias-name", valid_606462
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
  var valid_606463 = header.getOrDefault("X-Amz-Signature")
  valid_606463 = validateParameter(valid_606463, JString, required = false,
                                 default = nil)
  if valid_606463 != nil:
    section.add "X-Amz-Signature", valid_606463
  var valid_606464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606464 = validateParameter(valid_606464, JString, required = false,
                                 default = nil)
  if valid_606464 != nil:
    section.add "X-Amz-Content-Sha256", valid_606464
  var valid_606465 = header.getOrDefault("X-Amz-Date")
  valid_606465 = validateParameter(valid_606465, JString, required = false,
                                 default = nil)
  if valid_606465 != nil:
    section.add "X-Amz-Date", valid_606465
  var valid_606466 = header.getOrDefault("X-Amz-Credential")
  valid_606466 = validateParameter(valid_606466, JString, required = false,
                                 default = nil)
  if valid_606466 != nil:
    section.add "X-Amz-Credential", valid_606466
  var valid_606467 = header.getOrDefault("X-Amz-Security-Token")
  valid_606467 = validateParameter(valid_606467, JString, required = false,
                                 default = nil)
  if valid_606467 != nil:
    section.add "X-Amz-Security-Token", valid_606467
  var valid_606468 = header.getOrDefault("X-Amz-Algorithm")
  valid_606468 = validateParameter(valid_606468, JString, required = false,
                                 default = nil)
  if valid_606468 != nil:
    section.add "X-Amz-Algorithm", valid_606468
  var valid_606469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606469 = validateParameter(valid_606469, JString, required = false,
                                 default = nil)
  if valid_606469 != nil:
    section.add "X-Amz-SignedHeaders", valid_606469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606470: Call_DescribeTemplate_606456; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a template's metadata.
  ## 
  let valid = call_606470.validator(path, query, header, formData, body)
  let scheme = call_606470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606470.url(scheme.get, call_606470.host, call_606470.base,
                         call_606470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606470, url, valid)

proc call*(call_606471: Call_DescribeTemplate_606456; AwsAccountId: string;
          TemplateId: string; versionNumber: int = 0; aliasName: string = ""): Recallable =
  ## describeTemplate
  ## Describes a template's metadata.
  ##   versionNumber: int
  ##                : (Optional) The number for the version to describe. If a <code>VersionNumber</code> parameter value isn't provided, the latest version of the template is described.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template that you're describing.
  ##   aliasName: string
  ##            : The alias of the template that you want to describe. If you name a specific alias, you describe the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. The keyword <code>$PUBLISHED</code> doesn't apply to templates.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  var path_606472 = newJObject()
  var query_606473 = newJObject()
  add(query_606473, "version-number", newJInt(versionNumber))
  add(path_606472, "AwsAccountId", newJString(AwsAccountId))
  add(query_606473, "alias-name", newJString(aliasName))
  add(path_606472, "TemplateId", newJString(TemplateId))
  result = call_606471.call(path_606472, query_606473, nil, nil, nil)

var describeTemplate* = Call_DescribeTemplate_606456(name: "describeTemplate",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}",
    validator: validate_DescribeTemplate_606457, base: "/",
    url: url_DescribeTemplate_606458, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTemplate_606508 = ref object of OpenApiRestCall_605589
proc url_DeleteTemplate_606510(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "TemplateId" in path, "`TemplateId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/templates/"),
               (kind: VariableSegment, value: "TemplateId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteTemplate_606509(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Deletes a template.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the template that you're deleting.
  ##   TemplateId: JString (required)
  ##             : An ID for the template you want to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606511 = path.getOrDefault("AwsAccountId")
  valid_606511 = validateParameter(valid_606511, JString, required = true,
                                 default = nil)
  if valid_606511 != nil:
    section.add "AwsAccountId", valid_606511
  var valid_606512 = path.getOrDefault("TemplateId")
  valid_606512 = validateParameter(valid_606512, JString, required = true,
                                 default = nil)
  if valid_606512 != nil:
    section.add "TemplateId", valid_606512
  result.add "path", section
  ## parameters in `query` object:
  ##   version-number: JInt
  ##                 : Specifies the version of the template that you want to delete. If you don't provide a version number, <code>DeleteTemplate</code> deletes all versions of the template. 
  section = newJObject()
  var valid_606513 = query.getOrDefault("version-number")
  valid_606513 = validateParameter(valid_606513, JInt, required = false, default = nil)
  if valid_606513 != nil:
    section.add "version-number", valid_606513
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
  var valid_606514 = header.getOrDefault("X-Amz-Signature")
  valid_606514 = validateParameter(valid_606514, JString, required = false,
                                 default = nil)
  if valid_606514 != nil:
    section.add "X-Amz-Signature", valid_606514
  var valid_606515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "X-Amz-Content-Sha256", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-Date")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-Date", valid_606516
  var valid_606517 = header.getOrDefault("X-Amz-Credential")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-Credential", valid_606517
  var valid_606518 = header.getOrDefault("X-Amz-Security-Token")
  valid_606518 = validateParameter(valid_606518, JString, required = false,
                                 default = nil)
  if valid_606518 != nil:
    section.add "X-Amz-Security-Token", valid_606518
  var valid_606519 = header.getOrDefault("X-Amz-Algorithm")
  valid_606519 = validateParameter(valid_606519, JString, required = false,
                                 default = nil)
  if valid_606519 != nil:
    section.add "X-Amz-Algorithm", valid_606519
  var valid_606520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606520 = validateParameter(valid_606520, JString, required = false,
                                 default = nil)
  if valid_606520 != nil:
    section.add "X-Amz-SignedHeaders", valid_606520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606521: Call_DeleteTemplate_606508; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a template.
  ## 
  let valid = call_606521.validator(path, query, header, formData, body)
  let scheme = call_606521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606521.url(scheme.get, call_606521.host, call_606521.base,
                         call_606521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606521, url, valid)

proc call*(call_606522: Call_DeleteTemplate_606508; AwsAccountId: string;
          TemplateId: string; versionNumber: int = 0): Recallable =
  ## deleteTemplate
  ## Deletes a template.
  ##   versionNumber: int
  ##                : Specifies the version of the template that you want to delete. If you don't provide a version number, <code>DeleteTemplate</code> deletes all versions of the template. 
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template that you're deleting.
  ##   TemplateId: string (required)
  ##             : An ID for the template you want to delete.
  var path_606523 = newJObject()
  var query_606524 = newJObject()
  add(query_606524, "version-number", newJInt(versionNumber))
  add(path_606523, "AwsAccountId", newJString(AwsAccountId))
  add(path_606523, "TemplateId", newJString(TemplateId))
  result = call_606522.call(path_606523, query_606524, nil, nil, nil)

var deleteTemplate* = Call_DeleteTemplate_606508(name: "deleteTemplate",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}",
    validator: validate_DeleteTemplate_606509, base: "/", url: url_DeleteTemplate_606510,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTemplateAlias_606541 = ref object of OpenApiRestCall_605589
proc url_UpdateTemplateAlias_606543(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "TemplateId" in path, "`TemplateId` is a required path parameter"
  assert "AliasName" in path, "`AliasName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/templates/"),
               (kind: VariableSegment, value: "TemplateId"),
               (kind: ConstantSegment, value: "/aliases/"),
               (kind: VariableSegment, value: "AliasName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateTemplateAlias_606542(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Updates the template alias of a template.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the template alias that you're updating.
  ##   AliasName: JString (required)
  ##            : The alias of the template that you want to update. If you name a specific alias, you update the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. The keyword <code>$PUBLISHED</code> doesn't apply to templates.
  ##   TemplateId: JString (required)
  ##             : The ID for the template.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606544 = path.getOrDefault("AwsAccountId")
  valid_606544 = validateParameter(valid_606544, JString, required = true,
                                 default = nil)
  if valid_606544 != nil:
    section.add "AwsAccountId", valid_606544
  var valid_606545 = path.getOrDefault("AliasName")
  valid_606545 = validateParameter(valid_606545, JString, required = true,
                                 default = nil)
  if valid_606545 != nil:
    section.add "AliasName", valid_606545
  var valid_606546 = path.getOrDefault("TemplateId")
  valid_606546 = validateParameter(valid_606546, JString, required = true,
                                 default = nil)
  if valid_606546 != nil:
    section.add "TemplateId", valid_606546
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
  var valid_606547 = header.getOrDefault("X-Amz-Signature")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Signature", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-Content-Sha256", valid_606548
  var valid_606549 = header.getOrDefault("X-Amz-Date")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-Date", valid_606549
  var valid_606550 = header.getOrDefault("X-Amz-Credential")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "X-Amz-Credential", valid_606550
  var valid_606551 = header.getOrDefault("X-Amz-Security-Token")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "X-Amz-Security-Token", valid_606551
  var valid_606552 = header.getOrDefault("X-Amz-Algorithm")
  valid_606552 = validateParameter(valid_606552, JString, required = false,
                                 default = nil)
  if valid_606552 != nil:
    section.add "X-Amz-Algorithm", valid_606552
  var valid_606553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606553 = validateParameter(valid_606553, JString, required = false,
                                 default = nil)
  if valid_606553 != nil:
    section.add "X-Amz-SignedHeaders", valid_606553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606555: Call_UpdateTemplateAlias_606541; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the template alias of a template.
  ## 
  let valid = call_606555.validator(path, query, header, formData, body)
  let scheme = call_606555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606555.url(scheme.get, call_606555.host, call_606555.base,
                         call_606555.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606555, url, valid)

proc call*(call_606556: Call_UpdateTemplateAlias_606541; AwsAccountId: string;
          AliasName: string; TemplateId: string; body: JsonNode): Recallable =
  ## updateTemplateAlias
  ## Updates the template alias of a template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template alias that you're updating.
  ##   AliasName: string (required)
  ##            : The alias of the template that you want to update. If you name a specific alias, you update the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. The keyword <code>$PUBLISHED</code> doesn't apply to templates.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  ##   body: JObject (required)
  var path_606557 = newJObject()
  var body_606558 = newJObject()
  add(path_606557, "AwsAccountId", newJString(AwsAccountId))
  add(path_606557, "AliasName", newJString(AliasName))
  add(path_606557, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_606558 = body
  result = call_606556.call(path_606557, nil, nil, nil, body_606558)

var updateTemplateAlias* = Call_UpdateTemplateAlias_606541(
    name: "updateTemplateAlias", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}",
    validator: validate_UpdateTemplateAlias_606542, base: "/",
    url: url_UpdateTemplateAlias_606543, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTemplateAlias_606559 = ref object of OpenApiRestCall_605589
proc url_CreateTemplateAlias_606561(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "TemplateId" in path, "`TemplateId` is a required path parameter"
  assert "AliasName" in path, "`AliasName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/templates/"),
               (kind: VariableSegment, value: "TemplateId"),
               (kind: ConstantSegment, value: "/aliases/"),
               (kind: VariableSegment, value: "AliasName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateTemplateAlias_606560(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Creates a template alias for a template.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the template that you creating an alias for.
  ##   AliasName: JString (required)
  ##            : The name that you want to give to the template alias that you're creating. Don't start the alias name with the <code>$</code> character. Alias names that start with <code>$</code> are reserved by QuickSight. 
  ##   TemplateId: JString (required)
  ##             : An ID for the template.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606562 = path.getOrDefault("AwsAccountId")
  valid_606562 = validateParameter(valid_606562, JString, required = true,
                                 default = nil)
  if valid_606562 != nil:
    section.add "AwsAccountId", valid_606562
  var valid_606563 = path.getOrDefault("AliasName")
  valid_606563 = validateParameter(valid_606563, JString, required = true,
                                 default = nil)
  if valid_606563 != nil:
    section.add "AliasName", valid_606563
  var valid_606564 = path.getOrDefault("TemplateId")
  valid_606564 = validateParameter(valid_606564, JString, required = true,
                                 default = nil)
  if valid_606564 != nil:
    section.add "TemplateId", valid_606564
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
  var valid_606565 = header.getOrDefault("X-Amz-Signature")
  valid_606565 = validateParameter(valid_606565, JString, required = false,
                                 default = nil)
  if valid_606565 != nil:
    section.add "X-Amz-Signature", valid_606565
  var valid_606566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "X-Amz-Content-Sha256", valid_606566
  var valid_606567 = header.getOrDefault("X-Amz-Date")
  valid_606567 = validateParameter(valid_606567, JString, required = false,
                                 default = nil)
  if valid_606567 != nil:
    section.add "X-Amz-Date", valid_606567
  var valid_606568 = header.getOrDefault("X-Amz-Credential")
  valid_606568 = validateParameter(valid_606568, JString, required = false,
                                 default = nil)
  if valid_606568 != nil:
    section.add "X-Amz-Credential", valid_606568
  var valid_606569 = header.getOrDefault("X-Amz-Security-Token")
  valid_606569 = validateParameter(valid_606569, JString, required = false,
                                 default = nil)
  if valid_606569 != nil:
    section.add "X-Amz-Security-Token", valid_606569
  var valid_606570 = header.getOrDefault("X-Amz-Algorithm")
  valid_606570 = validateParameter(valid_606570, JString, required = false,
                                 default = nil)
  if valid_606570 != nil:
    section.add "X-Amz-Algorithm", valid_606570
  var valid_606571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606571 = validateParameter(valid_606571, JString, required = false,
                                 default = nil)
  if valid_606571 != nil:
    section.add "X-Amz-SignedHeaders", valid_606571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606573: Call_CreateTemplateAlias_606559; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a template alias for a template.
  ## 
  let valid = call_606573.validator(path, query, header, formData, body)
  let scheme = call_606573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606573.url(scheme.get, call_606573.host, call_606573.base,
                         call_606573.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606573, url, valid)

proc call*(call_606574: Call_CreateTemplateAlias_606559; AwsAccountId: string;
          AliasName: string; TemplateId: string; body: JsonNode): Recallable =
  ## createTemplateAlias
  ## Creates a template alias for a template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template that you creating an alias for.
  ##   AliasName: string (required)
  ##            : The name that you want to give to the template alias that you're creating. Don't start the alias name with the <code>$</code> character. Alias names that start with <code>$</code> are reserved by QuickSight. 
  ##   TemplateId: string (required)
  ##             : An ID for the template.
  ##   body: JObject (required)
  var path_606575 = newJObject()
  var body_606576 = newJObject()
  add(path_606575, "AwsAccountId", newJString(AwsAccountId))
  add(path_606575, "AliasName", newJString(AliasName))
  add(path_606575, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_606576 = body
  result = call_606574.call(path_606575, nil, nil, nil, body_606576)

var createTemplateAlias* = Call_CreateTemplateAlias_606559(
    name: "createTemplateAlias", meth: HttpMethod.HttpPost,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}",
    validator: validate_CreateTemplateAlias_606560, base: "/",
    url: url_CreateTemplateAlias_606561, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTemplateAlias_606525 = ref object of OpenApiRestCall_605589
proc url_DescribeTemplateAlias_606527(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "TemplateId" in path, "`TemplateId` is a required path parameter"
  assert "AliasName" in path, "`AliasName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/templates/"),
               (kind: VariableSegment, value: "TemplateId"),
               (kind: ConstantSegment, value: "/aliases/"),
               (kind: VariableSegment, value: "AliasName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeTemplateAlias_606526(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the template alias for a template.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the template alias that you're describing.
  ##   AliasName: JString (required)
  ##            : The name of the template alias that you want to describe. If you name a specific alias, you describe the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. The keyword <code>$PUBLISHED</code> doesn't apply to templates.
  ##   TemplateId: JString (required)
  ##             : The ID for the template.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606528 = path.getOrDefault("AwsAccountId")
  valid_606528 = validateParameter(valid_606528, JString, required = true,
                                 default = nil)
  if valid_606528 != nil:
    section.add "AwsAccountId", valid_606528
  var valid_606529 = path.getOrDefault("AliasName")
  valid_606529 = validateParameter(valid_606529, JString, required = true,
                                 default = nil)
  if valid_606529 != nil:
    section.add "AliasName", valid_606529
  var valid_606530 = path.getOrDefault("TemplateId")
  valid_606530 = validateParameter(valid_606530, JString, required = true,
                                 default = nil)
  if valid_606530 != nil:
    section.add "TemplateId", valid_606530
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
  var valid_606531 = header.getOrDefault("X-Amz-Signature")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "X-Amz-Signature", valid_606531
  var valid_606532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Content-Sha256", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-Date")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-Date", valid_606533
  var valid_606534 = header.getOrDefault("X-Amz-Credential")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "X-Amz-Credential", valid_606534
  var valid_606535 = header.getOrDefault("X-Amz-Security-Token")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "X-Amz-Security-Token", valid_606535
  var valid_606536 = header.getOrDefault("X-Amz-Algorithm")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-Algorithm", valid_606536
  var valid_606537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606537 = validateParameter(valid_606537, JString, required = false,
                                 default = nil)
  if valid_606537 != nil:
    section.add "X-Amz-SignedHeaders", valid_606537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606538: Call_DescribeTemplateAlias_606525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the template alias for a template.
  ## 
  let valid = call_606538.validator(path, query, header, formData, body)
  let scheme = call_606538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606538.url(scheme.get, call_606538.host, call_606538.base,
                         call_606538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606538, url, valid)

proc call*(call_606539: Call_DescribeTemplateAlias_606525; AwsAccountId: string;
          AliasName: string; TemplateId: string): Recallable =
  ## describeTemplateAlias
  ## Describes the template alias for a template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template alias that you're describing.
  ##   AliasName: string (required)
  ##            : The name of the template alias that you want to describe. If you name a specific alias, you describe the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. The keyword <code>$PUBLISHED</code> doesn't apply to templates.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  var path_606540 = newJObject()
  add(path_606540, "AwsAccountId", newJString(AwsAccountId))
  add(path_606540, "AliasName", newJString(AliasName))
  add(path_606540, "TemplateId", newJString(TemplateId))
  result = call_606539.call(path_606540, nil, nil, nil, nil)

var describeTemplateAlias* = Call_DescribeTemplateAlias_606525(
    name: "describeTemplateAlias", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}",
    validator: validate_DescribeTemplateAlias_606526, base: "/",
    url: url_DescribeTemplateAlias_606527, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTemplateAlias_606577 = ref object of OpenApiRestCall_605589
proc url_DeleteTemplateAlias_606579(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "TemplateId" in path, "`TemplateId` is a required path parameter"
  assert "AliasName" in path, "`AliasName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/templates/"),
               (kind: VariableSegment, value: "TemplateId"),
               (kind: ConstantSegment, value: "/aliases/"),
               (kind: VariableSegment, value: "AliasName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteTemplateAlias_606578(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Deletes the item that the specified template alias points to. If you provide a specific alias, you delete the version of the template that the alias points to.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the item to delete.
  ##   AliasName: JString (required)
  ##            : The name for the template alias. If you name a specific alias, you delete the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. 
  ##   TemplateId: JString (required)
  ##             : The ID for the template that the specified alias is for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606580 = path.getOrDefault("AwsAccountId")
  valid_606580 = validateParameter(valid_606580, JString, required = true,
                                 default = nil)
  if valid_606580 != nil:
    section.add "AwsAccountId", valid_606580
  var valid_606581 = path.getOrDefault("AliasName")
  valid_606581 = validateParameter(valid_606581, JString, required = true,
                                 default = nil)
  if valid_606581 != nil:
    section.add "AliasName", valid_606581
  var valid_606582 = path.getOrDefault("TemplateId")
  valid_606582 = validateParameter(valid_606582, JString, required = true,
                                 default = nil)
  if valid_606582 != nil:
    section.add "TemplateId", valid_606582
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
  var valid_606583 = header.getOrDefault("X-Amz-Signature")
  valid_606583 = validateParameter(valid_606583, JString, required = false,
                                 default = nil)
  if valid_606583 != nil:
    section.add "X-Amz-Signature", valid_606583
  var valid_606584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606584 = validateParameter(valid_606584, JString, required = false,
                                 default = nil)
  if valid_606584 != nil:
    section.add "X-Amz-Content-Sha256", valid_606584
  var valid_606585 = header.getOrDefault("X-Amz-Date")
  valid_606585 = validateParameter(valid_606585, JString, required = false,
                                 default = nil)
  if valid_606585 != nil:
    section.add "X-Amz-Date", valid_606585
  var valid_606586 = header.getOrDefault("X-Amz-Credential")
  valid_606586 = validateParameter(valid_606586, JString, required = false,
                                 default = nil)
  if valid_606586 != nil:
    section.add "X-Amz-Credential", valid_606586
  var valid_606587 = header.getOrDefault("X-Amz-Security-Token")
  valid_606587 = validateParameter(valid_606587, JString, required = false,
                                 default = nil)
  if valid_606587 != nil:
    section.add "X-Amz-Security-Token", valid_606587
  var valid_606588 = header.getOrDefault("X-Amz-Algorithm")
  valid_606588 = validateParameter(valid_606588, JString, required = false,
                                 default = nil)
  if valid_606588 != nil:
    section.add "X-Amz-Algorithm", valid_606588
  var valid_606589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606589 = validateParameter(valid_606589, JString, required = false,
                                 default = nil)
  if valid_606589 != nil:
    section.add "X-Amz-SignedHeaders", valid_606589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606590: Call_DeleteTemplateAlias_606577; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the item that the specified template alias points to. If you provide a specific alias, you delete the version of the template that the alias points to.
  ## 
  let valid = call_606590.validator(path, query, header, formData, body)
  let scheme = call_606590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606590.url(scheme.get, call_606590.host, call_606590.base,
                         call_606590.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606590, url, valid)

proc call*(call_606591: Call_DeleteTemplateAlias_606577; AwsAccountId: string;
          AliasName: string; TemplateId: string): Recallable =
  ## deleteTemplateAlias
  ## Deletes the item that the specified template alias points to. If you provide a specific alias, you delete the version of the template that the alias points to.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the item to delete.
  ##   AliasName: string (required)
  ##            : The name for the template alias. If you name a specific alias, you delete the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. 
  ##   TemplateId: string (required)
  ##             : The ID for the template that the specified alias is for.
  var path_606592 = newJObject()
  add(path_606592, "AwsAccountId", newJString(AwsAccountId))
  add(path_606592, "AliasName", newJString(AliasName))
  add(path_606592, "TemplateId", newJString(TemplateId))
  result = call_606591.call(path_606592, nil, nil, nil, nil)

var deleteTemplateAlias* = Call_DeleteTemplateAlias_606577(
    name: "deleteTemplateAlias", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}",
    validator: validate_DeleteTemplateAlias_606578, base: "/",
    url: url_DeleteTemplateAlias_606579, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSet_606608 = ref object of OpenApiRestCall_605589
proc url_UpdateDataSet_606610(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sets/"),
               (kind: VariableSegment, value: "DataSetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDataSet_606609(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a dataset.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  ##   DataSetId: JString (required)
  ##            : The ID for the dataset that you want to update. This ID is unique per AWS Region for each AWS account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606611 = path.getOrDefault("AwsAccountId")
  valid_606611 = validateParameter(valid_606611, JString, required = true,
                                 default = nil)
  if valid_606611 != nil:
    section.add "AwsAccountId", valid_606611
  var valid_606612 = path.getOrDefault("DataSetId")
  valid_606612 = validateParameter(valid_606612, JString, required = true,
                                 default = nil)
  if valid_606612 != nil:
    section.add "DataSetId", valid_606612
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
  var valid_606613 = header.getOrDefault("X-Amz-Signature")
  valid_606613 = validateParameter(valid_606613, JString, required = false,
                                 default = nil)
  if valid_606613 != nil:
    section.add "X-Amz-Signature", valid_606613
  var valid_606614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606614 = validateParameter(valid_606614, JString, required = false,
                                 default = nil)
  if valid_606614 != nil:
    section.add "X-Amz-Content-Sha256", valid_606614
  var valid_606615 = header.getOrDefault("X-Amz-Date")
  valid_606615 = validateParameter(valid_606615, JString, required = false,
                                 default = nil)
  if valid_606615 != nil:
    section.add "X-Amz-Date", valid_606615
  var valid_606616 = header.getOrDefault("X-Amz-Credential")
  valid_606616 = validateParameter(valid_606616, JString, required = false,
                                 default = nil)
  if valid_606616 != nil:
    section.add "X-Amz-Credential", valid_606616
  var valid_606617 = header.getOrDefault("X-Amz-Security-Token")
  valid_606617 = validateParameter(valid_606617, JString, required = false,
                                 default = nil)
  if valid_606617 != nil:
    section.add "X-Amz-Security-Token", valid_606617
  var valid_606618 = header.getOrDefault("X-Amz-Algorithm")
  valid_606618 = validateParameter(valid_606618, JString, required = false,
                                 default = nil)
  if valid_606618 != nil:
    section.add "X-Amz-Algorithm", valid_606618
  var valid_606619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606619 = validateParameter(valid_606619, JString, required = false,
                                 default = nil)
  if valid_606619 != nil:
    section.add "X-Amz-SignedHeaders", valid_606619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606621: Call_UpdateDataSet_606608; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a dataset.
  ## 
  let valid = call_606621.validator(path, query, header, formData, body)
  let scheme = call_606621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606621.url(scheme.get, call_606621.host, call_606621.base,
                         call_606621.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606621, url, valid)

proc call*(call_606622: Call_UpdateDataSet_606608; AwsAccountId: string;
          DataSetId: string; body: JsonNode): Recallable =
  ## updateDataSet
  ## Updates a dataset.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset that you want to update. This ID is unique per AWS Region for each AWS account.
  ##   body: JObject (required)
  var path_606623 = newJObject()
  var body_606624 = newJObject()
  add(path_606623, "AwsAccountId", newJString(AwsAccountId))
  add(path_606623, "DataSetId", newJString(DataSetId))
  if body != nil:
    body_606624 = body
  result = call_606622.call(path_606623, nil, nil, nil, body_606624)

var updateDataSet* = Call_UpdateDataSet_606608(name: "updateDataSet",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}",
    validator: validate_UpdateDataSet_606609, base: "/", url: url_UpdateDataSet_606610,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSet_606593 = ref object of OpenApiRestCall_605589
proc url_DescribeDataSet_606595(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sets/"),
               (kind: VariableSegment, value: "DataSetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDataSet_606594(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Describes a dataset. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  ##   DataSetId: JString (required)
  ##            : The ID for the dataset that you want to create. This ID is unique per AWS Region for each AWS account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606596 = path.getOrDefault("AwsAccountId")
  valid_606596 = validateParameter(valid_606596, JString, required = true,
                                 default = nil)
  if valid_606596 != nil:
    section.add "AwsAccountId", valid_606596
  var valid_606597 = path.getOrDefault("DataSetId")
  valid_606597 = validateParameter(valid_606597, JString, required = true,
                                 default = nil)
  if valid_606597 != nil:
    section.add "DataSetId", valid_606597
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
  var valid_606598 = header.getOrDefault("X-Amz-Signature")
  valid_606598 = validateParameter(valid_606598, JString, required = false,
                                 default = nil)
  if valid_606598 != nil:
    section.add "X-Amz-Signature", valid_606598
  var valid_606599 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606599 = validateParameter(valid_606599, JString, required = false,
                                 default = nil)
  if valid_606599 != nil:
    section.add "X-Amz-Content-Sha256", valid_606599
  var valid_606600 = header.getOrDefault("X-Amz-Date")
  valid_606600 = validateParameter(valid_606600, JString, required = false,
                                 default = nil)
  if valid_606600 != nil:
    section.add "X-Amz-Date", valid_606600
  var valid_606601 = header.getOrDefault("X-Amz-Credential")
  valid_606601 = validateParameter(valid_606601, JString, required = false,
                                 default = nil)
  if valid_606601 != nil:
    section.add "X-Amz-Credential", valid_606601
  var valid_606602 = header.getOrDefault("X-Amz-Security-Token")
  valid_606602 = validateParameter(valid_606602, JString, required = false,
                                 default = nil)
  if valid_606602 != nil:
    section.add "X-Amz-Security-Token", valid_606602
  var valid_606603 = header.getOrDefault("X-Amz-Algorithm")
  valid_606603 = validateParameter(valid_606603, JString, required = false,
                                 default = nil)
  if valid_606603 != nil:
    section.add "X-Amz-Algorithm", valid_606603
  var valid_606604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606604 = validateParameter(valid_606604, JString, required = false,
                                 default = nil)
  if valid_606604 != nil:
    section.add "X-Amz-SignedHeaders", valid_606604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606605: Call_DescribeDataSet_606593; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a dataset. 
  ## 
  let valid = call_606605.validator(path, query, header, formData, body)
  let scheme = call_606605.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606605.url(scheme.get, call_606605.host, call_606605.base,
                         call_606605.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606605, url, valid)

proc call*(call_606606: Call_DescribeDataSet_606593; AwsAccountId: string;
          DataSetId: string): Recallable =
  ## describeDataSet
  ## Describes a dataset. 
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset that you want to create. This ID is unique per AWS Region for each AWS account.
  var path_606607 = newJObject()
  add(path_606607, "AwsAccountId", newJString(AwsAccountId))
  add(path_606607, "DataSetId", newJString(DataSetId))
  result = call_606606.call(path_606607, nil, nil, nil, nil)

var describeDataSet* = Call_DescribeDataSet_606593(name: "describeDataSet",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}",
    validator: validate_DescribeDataSet_606594, base: "/", url: url_DescribeDataSet_606595,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSet_606625 = ref object of OpenApiRestCall_605589
proc url_DeleteDataSet_606627(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sets/"),
               (kind: VariableSegment, value: "DataSetId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDataSet_606626(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a dataset.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  ##   DataSetId: JString (required)
  ##            : The ID for the dataset that you want to create. This ID is unique per AWS Region for each AWS account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606628 = path.getOrDefault("AwsAccountId")
  valid_606628 = validateParameter(valid_606628, JString, required = true,
                                 default = nil)
  if valid_606628 != nil:
    section.add "AwsAccountId", valid_606628
  var valid_606629 = path.getOrDefault("DataSetId")
  valid_606629 = validateParameter(valid_606629, JString, required = true,
                                 default = nil)
  if valid_606629 != nil:
    section.add "DataSetId", valid_606629
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
  var valid_606630 = header.getOrDefault("X-Amz-Signature")
  valid_606630 = validateParameter(valid_606630, JString, required = false,
                                 default = nil)
  if valid_606630 != nil:
    section.add "X-Amz-Signature", valid_606630
  var valid_606631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606631 = validateParameter(valid_606631, JString, required = false,
                                 default = nil)
  if valid_606631 != nil:
    section.add "X-Amz-Content-Sha256", valid_606631
  var valid_606632 = header.getOrDefault("X-Amz-Date")
  valid_606632 = validateParameter(valid_606632, JString, required = false,
                                 default = nil)
  if valid_606632 != nil:
    section.add "X-Amz-Date", valid_606632
  var valid_606633 = header.getOrDefault("X-Amz-Credential")
  valid_606633 = validateParameter(valid_606633, JString, required = false,
                                 default = nil)
  if valid_606633 != nil:
    section.add "X-Amz-Credential", valid_606633
  var valid_606634 = header.getOrDefault("X-Amz-Security-Token")
  valid_606634 = validateParameter(valid_606634, JString, required = false,
                                 default = nil)
  if valid_606634 != nil:
    section.add "X-Amz-Security-Token", valid_606634
  var valid_606635 = header.getOrDefault("X-Amz-Algorithm")
  valid_606635 = validateParameter(valid_606635, JString, required = false,
                                 default = nil)
  if valid_606635 != nil:
    section.add "X-Amz-Algorithm", valid_606635
  var valid_606636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606636 = validateParameter(valid_606636, JString, required = false,
                                 default = nil)
  if valid_606636 != nil:
    section.add "X-Amz-SignedHeaders", valid_606636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606637: Call_DeleteDataSet_606625; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a dataset.
  ## 
  let valid = call_606637.validator(path, query, header, formData, body)
  let scheme = call_606637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606637.url(scheme.get, call_606637.host, call_606637.base,
                         call_606637.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606637, url, valid)

proc call*(call_606638: Call_DeleteDataSet_606625; AwsAccountId: string;
          DataSetId: string): Recallable =
  ## deleteDataSet
  ## Deletes a dataset.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset that you want to create. This ID is unique per AWS Region for each AWS account.
  var path_606639 = newJObject()
  add(path_606639, "AwsAccountId", newJString(AwsAccountId))
  add(path_606639, "DataSetId", newJString(DataSetId))
  result = call_606638.call(path_606639, nil, nil, nil, nil)

var deleteDataSet* = Call_DeleteDataSet_606625(name: "deleteDataSet",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}",
    validator: validate_DeleteDataSet_606626, base: "/", url: url_DeleteDataSet_606627,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSource_606655 = ref object of OpenApiRestCall_605589
proc url_UpdateDataSource_606657(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DataSourceId" in path, "`DataSourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sources/"),
               (kind: VariableSegment, value: "DataSourceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDataSource_606656(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Updates a data source.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSourceId: JString (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account. 
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DataSourceId` field"
  var valid_606658 = path.getOrDefault("DataSourceId")
  valid_606658 = validateParameter(valid_606658, JString, required = true,
                                 default = nil)
  if valid_606658 != nil:
    section.add "DataSourceId", valid_606658
  var valid_606659 = path.getOrDefault("AwsAccountId")
  valid_606659 = validateParameter(valid_606659, JString, required = true,
                                 default = nil)
  if valid_606659 != nil:
    section.add "AwsAccountId", valid_606659
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
  var valid_606660 = header.getOrDefault("X-Amz-Signature")
  valid_606660 = validateParameter(valid_606660, JString, required = false,
                                 default = nil)
  if valid_606660 != nil:
    section.add "X-Amz-Signature", valid_606660
  var valid_606661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606661 = validateParameter(valid_606661, JString, required = false,
                                 default = nil)
  if valid_606661 != nil:
    section.add "X-Amz-Content-Sha256", valid_606661
  var valid_606662 = header.getOrDefault("X-Amz-Date")
  valid_606662 = validateParameter(valid_606662, JString, required = false,
                                 default = nil)
  if valid_606662 != nil:
    section.add "X-Amz-Date", valid_606662
  var valid_606663 = header.getOrDefault("X-Amz-Credential")
  valid_606663 = validateParameter(valid_606663, JString, required = false,
                                 default = nil)
  if valid_606663 != nil:
    section.add "X-Amz-Credential", valid_606663
  var valid_606664 = header.getOrDefault("X-Amz-Security-Token")
  valid_606664 = validateParameter(valid_606664, JString, required = false,
                                 default = nil)
  if valid_606664 != nil:
    section.add "X-Amz-Security-Token", valid_606664
  var valid_606665 = header.getOrDefault("X-Amz-Algorithm")
  valid_606665 = validateParameter(valid_606665, JString, required = false,
                                 default = nil)
  if valid_606665 != nil:
    section.add "X-Amz-Algorithm", valid_606665
  var valid_606666 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606666 = validateParameter(valid_606666, JString, required = false,
                                 default = nil)
  if valid_606666 != nil:
    section.add "X-Amz-SignedHeaders", valid_606666
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606668: Call_UpdateDataSource_606655; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a data source.
  ## 
  let valid = call_606668.validator(path, query, header, formData, body)
  let scheme = call_606668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606668.url(scheme.get, call_606668.host, call_606668.base,
                         call_606668.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606668, url, valid)

proc call*(call_606669: Call_UpdateDataSource_606655; DataSourceId: string;
          AwsAccountId: string; body: JsonNode): Recallable =
  ## updateDataSource
  ## Updates a data source.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account. 
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   body: JObject (required)
  var path_606670 = newJObject()
  var body_606671 = newJObject()
  add(path_606670, "DataSourceId", newJString(DataSourceId))
  add(path_606670, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_606671 = body
  result = call_606669.call(path_606670, nil, nil, nil, body_606671)

var updateDataSource* = Call_UpdateDataSource_606655(name: "updateDataSource",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}",
    validator: validate_UpdateDataSource_606656, base: "/",
    url: url_UpdateDataSource_606657, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSource_606640 = ref object of OpenApiRestCall_605589
proc url_DescribeDataSource_606642(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DataSourceId" in path, "`DataSourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sources/"),
               (kind: VariableSegment, value: "DataSourceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDataSource_606641(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Describes a data source.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSourceId: JString (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account.
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DataSourceId` field"
  var valid_606643 = path.getOrDefault("DataSourceId")
  valid_606643 = validateParameter(valid_606643, JString, required = true,
                                 default = nil)
  if valid_606643 != nil:
    section.add "DataSourceId", valid_606643
  var valid_606644 = path.getOrDefault("AwsAccountId")
  valid_606644 = validateParameter(valid_606644, JString, required = true,
                                 default = nil)
  if valid_606644 != nil:
    section.add "AwsAccountId", valid_606644
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
  var valid_606645 = header.getOrDefault("X-Amz-Signature")
  valid_606645 = validateParameter(valid_606645, JString, required = false,
                                 default = nil)
  if valid_606645 != nil:
    section.add "X-Amz-Signature", valid_606645
  var valid_606646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606646 = validateParameter(valid_606646, JString, required = false,
                                 default = nil)
  if valid_606646 != nil:
    section.add "X-Amz-Content-Sha256", valid_606646
  var valid_606647 = header.getOrDefault("X-Amz-Date")
  valid_606647 = validateParameter(valid_606647, JString, required = false,
                                 default = nil)
  if valid_606647 != nil:
    section.add "X-Amz-Date", valid_606647
  var valid_606648 = header.getOrDefault("X-Amz-Credential")
  valid_606648 = validateParameter(valid_606648, JString, required = false,
                                 default = nil)
  if valid_606648 != nil:
    section.add "X-Amz-Credential", valid_606648
  var valid_606649 = header.getOrDefault("X-Amz-Security-Token")
  valid_606649 = validateParameter(valid_606649, JString, required = false,
                                 default = nil)
  if valid_606649 != nil:
    section.add "X-Amz-Security-Token", valid_606649
  var valid_606650 = header.getOrDefault("X-Amz-Algorithm")
  valid_606650 = validateParameter(valid_606650, JString, required = false,
                                 default = nil)
  if valid_606650 != nil:
    section.add "X-Amz-Algorithm", valid_606650
  var valid_606651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606651 = validateParameter(valid_606651, JString, required = false,
                                 default = nil)
  if valid_606651 != nil:
    section.add "X-Amz-SignedHeaders", valid_606651
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606652: Call_DescribeDataSource_606640; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a data source.
  ## 
  let valid = call_606652.validator(path, query, header, formData, body)
  let scheme = call_606652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606652.url(scheme.get, call_606652.host, call_606652.base,
                         call_606652.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606652, url, valid)

proc call*(call_606653: Call_DescribeDataSource_606640; DataSourceId: string;
          AwsAccountId: string): Recallable =
  ## describeDataSource
  ## Describes a data source.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  var path_606654 = newJObject()
  add(path_606654, "DataSourceId", newJString(DataSourceId))
  add(path_606654, "AwsAccountId", newJString(AwsAccountId))
  result = call_606653.call(path_606654, nil, nil, nil, nil)

var describeDataSource* = Call_DescribeDataSource_606640(
    name: "describeDataSource", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}",
    validator: validate_DescribeDataSource_606641, base: "/",
    url: url_DescribeDataSource_606642, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSource_606672 = ref object of OpenApiRestCall_605589
proc url_DeleteDataSource_606674(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DataSourceId" in path, "`DataSourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sources/"),
               (kind: VariableSegment, value: "DataSourceId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDataSource_606673(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deletes the data source permanently. This action breaks all the datasets that reference the deleted data source.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSourceId: JString (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account.
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DataSourceId` field"
  var valid_606675 = path.getOrDefault("DataSourceId")
  valid_606675 = validateParameter(valid_606675, JString, required = true,
                                 default = nil)
  if valid_606675 != nil:
    section.add "DataSourceId", valid_606675
  var valid_606676 = path.getOrDefault("AwsAccountId")
  valid_606676 = validateParameter(valid_606676, JString, required = true,
                                 default = nil)
  if valid_606676 != nil:
    section.add "AwsAccountId", valid_606676
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
  if body != nil:
    result.add "body", body

proc call*(call_606684: Call_DeleteDataSource_606672; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the data source permanently. This action breaks all the datasets that reference the deleted data source.
  ## 
  let valid = call_606684.validator(path, query, header, formData, body)
  let scheme = call_606684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606684.url(scheme.get, call_606684.host, call_606684.base,
                         call_606684.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606684, url, valid)

proc call*(call_606685: Call_DeleteDataSource_606672; DataSourceId: string;
          AwsAccountId: string): Recallable =
  ## deleteDataSource
  ## Deletes the data source permanently. This action breaks all the datasets that reference the deleted data source.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  var path_606686 = newJObject()
  add(path_606686, "DataSourceId", newJString(DataSourceId))
  add(path_606686, "AwsAccountId", newJString(AwsAccountId))
  result = call_606685.call(path_606686, nil, nil, nil, nil)

var deleteDataSource* = Call_DeleteDataSource_606672(name: "deleteDataSource",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}",
    validator: validate_DeleteDataSource_606673, base: "/",
    url: url_DeleteDataSource_606674, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_606703 = ref object of OpenApiRestCall_605589
proc url_UpdateGroup_606705(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateGroup_606704(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Changes a group description. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the group that you want to update.
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_606706 = path.getOrDefault("GroupName")
  valid_606706 = validateParameter(valid_606706, JString, required = true,
                                 default = nil)
  if valid_606706 != nil:
    section.add "GroupName", valid_606706
  var valid_606707 = path.getOrDefault("AwsAccountId")
  valid_606707 = validateParameter(valid_606707, JString, required = true,
                                 default = nil)
  if valid_606707 != nil:
    section.add "AwsAccountId", valid_606707
  var valid_606708 = path.getOrDefault("Namespace")
  valid_606708 = validateParameter(valid_606708, JString, required = true,
                                 default = nil)
  if valid_606708 != nil:
    section.add "Namespace", valid_606708
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
  var valid_606709 = header.getOrDefault("X-Amz-Signature")
  valid_606709 = validateParameter(valid_606709, JString, required = false,
                                 default = nil)
  if valid_606709 != nil:
    section.add "X-Amz-Signature", valid_606709
  var valid_606710 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606710 = validateParameter(valid_606710, JString, required = false,
                                 default = nil)
  if valid_606710 != nil:
    section.add "X-Amz-Content-Sha256", valid_606710
  var valid_606711 = header.getOrDefault("X-Amz-Date")
  valid_606711 = validateParameter(valid_606711, JString, required = false,
                                 default = nil)
  if valid_606711 != nil:
    section.add "X-Amz-Date", valid_606711
  var valid_606712 = header.getOrDefault("X-Amz-Credential")
  valid_606712 = validateParameter(valid_606712, JString, required = false,
                                 default = nil)
  if valid_606712 != nil:
    section.add "X-Amz-Credential", valid_606712
  var valid_606713 = header.getOrDefault("X-Amz-Security-Token")
  valid_606713 = validateParameter(valid_606713, JString, required = false,
                                 default = nil)
  if valid_606713 != nil:
    section.add "X-Amz-Security-Token", valid_606713
  var valid_606714 = header.getOrDefault("X-Amz-Algorithm")
  valid_606714 = validateParameter(valid_606714, JString, required = false,
                                 default = nil)
  if valid_606714 != nil:
    section.add "X-Amz-Algorithm", valid_606714
  var valid_606715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606715 = validateParameter(valid_606715, JString, required = false,
                                 default = nil)
  if valid_606715 != nil:
    section.add "X-Amz-SignedHeaders", valid_606715
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606717: Call_UpdateGroup_606703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes a group description. 
  ## 
  let valid = call_606717.validator(path, query, header, formData, body)
  let scheme = call_606717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606717.url(scheme.get, call_606717.host, call_606717.base,
                         call_606717.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606717, url, valid)

proc call*(call_606718: Call_UpdateGroup_606703; GroupName: string;
          AwsAccountId: string; Namespace: string; body: JsonNode): Recallable =
  ## updateGroup
  ## Changes a group description. 
  ##   GroupName: string (required)
  ##            : The name of the group that you want to update.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   body: JObject (required)
  var path_606719 = newJObject()
  var body_606720 = newJObject()
  add(path_606719, "GroupName", newJString(GroupName))
  add(path_606719, "AwsAccountId", newJString(AwsAccountId))
  add(path_606719, "Namespace", newJString(Namespace))
  if body != nil:
    body_606720 = body
  result = call_606718.call(path_606719, nil, nil, nil, body_606720)

var updateGroup* = Call_UpdateGroup_606703(name: "updateGroup",
                                        meth: HttpMethod.HttpPut,
                                        host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}",
                                        validator: validate_UpdateGroup_606704,
                                        base: "/", url: url_UpdateGroup_606705,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGroup_606687 = ref object of OpenApiRestCall_605589
proc url_DescribeGroup_606689(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeGroup_606688(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns an Amazon QuickSight group's description and Amazon Resource Name (ARN). 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the group that you want to describe.
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_606690 = path.getOrDefault("GroupName")
  valid_606690 = validateParameter(valid_606690, JString, required = true,
                                 default = nil)
  if valid_606690 != nil:
    section.add "GroupName", valid_606690
  var valid_606691 = path.getOrDefault("AwsAccountId")
  valid_606691 = validateParameter(valid_606691, JString, required = true,
                                 default = nil)
  if valid_606691 != nil:
    section.add "AwsAccountId", valid_606691
  var valid_606692 = path.getOrDefault("Namespace")
  valid_606692 = validateParameter(valid_606692, JString, required = true,
                                 default = nil)
  if valid_606692 != nil:
    section.add "Namespace", valid_606692
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
  var valid_606693 = header.getOrDefault("X-Amz-Signature")
  valid_606693 = validateParameter(valid_606693, JString, required = false,
                                 default = nil)
  if valid_606693 != nil:
    section.add "X-Amz-Signature", valid_606693
  var valid_606694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606694 = validateParameter(valid_606694, JString, required = false,
                                 default = nil)
  if valid_606694 != nil:
    section.add "X-Amz-Content-Sha256", valid_606694
  var valid_606695 = header.getOrDefault("X-Amz-Date")
  valid_606695 = validateParameter(valid_606695, JString, required = false,
                                 default = nil)
  if valid_606695 != nil:
    section.add "X-Amz-Date", valid_606695
  var valid_606696 = header.getOrDefault("X-Amz-Credential")
  valid_606696 = validateParameter(valid_606696, JString, required = false,
                                 default = nil)
  if valid_606696 != nil:
    section.add "X-Amz-Credential", valid_606696
  var valid_606697 = header.getOrDefault("X-Amz-Security-Token")
  valid_606697 = validateParameter(valid_606697, JString, required = false,
                                 default = nil)
  if valid_606697 != nil:
    section.add "X-Amz-Security-Token", valid_606697
  var valid_606698 = header.getOrDefault("X-Amz-Algorithm")
  valid_606698 = validateParameter(valid_606698, JString, required = false,
                                 default = nil)
  if valid_606698 != nil:
    section.add "X-Amz-Algorithm", valid_606698
  var valid_606699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606699 = validateParameter(valid_606699, JString, required = false,
                                 default = nil)
  if valid_606699 != nil:
    section.add "X-Amz-SignedHeaders", valid_606699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606700: Call_DescribeGroup_606687; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an Amazon QuickSight group's description and Amazon Resource Name (ARN). 
  ## 
  let valid = call_606700.validator(path, query, header, formData, body)
  let scheme = call_606700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606700.url(scheme.get, call_606700.host, call_606700.base,
                         call_606700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606700, url, valid)

proc call*(call_606701: Call_DescribeGroup_606687; GroupName: string;
          AwsAccountId: string; Namespace: string): Recallable =
  ## describeGroup
  ## Returns an Amazon QuickSight group's description and Amazon Resource Name (ARN). 
  ##   GroupName: string (required)
  ##            : The name of the group that you want to describe.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_606702 = newJObject()
  add(path_606702, "GroupName", newJString(GroupName))
  add(path_606702, "AwsAccountId", newJString(AwsAccountId))
  add(path_606702, "Namespace", newJString(Namespace))
  result = call_606701.call(path_606702, nil, nil, nil, nil)

var describeGroup* = Call_DescribeGroup_606687(name: "describeGroup",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}",
    validator: validate_DescribeGroup_606688, base: "/", url: url_DescribeGroup_606689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_606721 = ref object of OpenApiRestCall_605589
proc url_DeleteGroup_606723(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteGroup_606722(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a user group from Amazon QuickSight. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the group that you want to delete.
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_606724 = path.getOrDefault("GroupName")
  valid_606724 = validateParameter(valid_606724, JString, required = true,
                                 default = nil)
  if valid_606724 != nil:
    section.add "GroupName", valid_606724
  var valid_606725 = path.getOrDefault("AwsAccountId")
  valid_606725 = validateParameter(valid_606725, JString, required = true,
                                 default = nil)
  if valid_606725 != nil:
    section.add "AwsAccountId", valid_606725
  var valid_606726 = path.getOrDefault("Namespace")
  valid_606726 = validateParameter(valid_606726, JString, required = true,
                                 default = nil)
  if valid_606726 != nil:
    section.add "Namespace", valid_606726
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
  var valid_606727 = header.getOrDefault("X-Amz-Signature")
  valid_606727 = validateParameter(valid_606727, JString, required = false,
                                 default = nil)
  if valid_606727 != nil:
    section.add "X-Amz-Signature", valid_606727
  var valid_606728 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606728 = validateParameter(valid_606728, JString, required = false,
                                 default = nil)
  if valid_606728 != nil:
    section.add "X-Amz-Content-Sha256", valid_606728
  var valid_606729 = header.getOrDefault("X-Amz-Date")
  valid_606729 = validateParameter(valid_606729, JString, required = false,
                                 default = nil)
  if valid_606729 != nil:
    section.add "X-Amz-Date", valid_606729
  var valid_606730 = header.getOrDefault("X-Amz-Credential")
  valid_606730 = validateParameter(valid_606730, JString, required = false,
                                 default = nil)
  if valid_606730 != nil:
    section.add "X-Amz-Credential", valid_606730
  var valid_606731 = header.getOrDefault("X-Amz-Security-Token")
  valid_606731 = validateParameter(valid_606731, JString, required = false,
                                 default = nil)
  if valid_606731 != nil:
    section.add "X-Amz-Security-Token", valid_606731
  var valid_606732 = header.getOrDefault("X-Amz-Algorithm")
  valid_606732 = validateParameter(valid_606732, JString, required = false,
                                 default = nil)
  if valid_606732 != nil:
    section.add "X-Amz-Algorithm", valid_606732
  var valid_606733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606733 = validateParameter(valid_606733, JString, required = false,
                                 default = nil)
  if valid_606733 != nil:
    section.add "X-Amz-SignedHeaders", valid_606733
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606734: Call_DeleteGroup_606721; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a user group from Amazon QuickSight. 
  ## 
  let valid = call_606734.validator(path, query, header, formData, body)
  let scheme = call_606734.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606734.url(scheme.get, call_606734.host, call_606734.base,
                         call_606734.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606734, url, valid)

proc call*(call_606735: Call_DeleteGroup_606721; GroupName: string;
          AwsAccountId: string; Namespace: string): Recallable =
  ## deleteGroup
  ## Removes a user group from Amazon QuickSight. 
  ##   GroupName: string (required)
  ##            : The name of the group that you want to delete.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_606736 = newJObject()
  add(path_606736, "GroupName", newJString(GroupName))
  add(path_606736, "AwsAccountId", newJString(AwsAccountId))
  add(path_606736, "Namespace", newJString(Namespace))
  result = call_606735.call(path_606736, nil, nil, nil, nil)

var deleteGroup* = Call_DeleteGroup_606721(name: "deleteGroup",
                                        meth: HttpMethod.HttpDelete,
                                        host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}",
                                        validator: validate_DeleteGroup_606722,
                                        base: "/", url: url_DeleteGroup_606723,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIAMPolicyAssignment_606737 = ref object of OpenApiRestCall_605589
proc url_DeleteIAMPolicyAssignment_606739(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "AssignmentName" in path, "`AssignmentName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespace/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/iam-policy-assignments/"),
               (kind: VariableSegment, value: "AssignmentName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteIAMPolicyAssignment_606738(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing IAM policy assignment.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID where you want to delete the IAM policy assignment.
  ##   Namespace: JString (required)
  ##            : The namespace that contains the assignment.
  ##   AssignmentName: JString (required)
  ##                 : The name of the assignment. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606740 = path.getOrDefault("AwsAccountId")
  valid_606740 = validateParameter(valid_606740, JString, required = true,
                                 default = nil)
  if valid_606740 != nil:
    section.add "AwsAccountId", valid_606740
  var valid_606741 = path.getOrDefault("Namespace")
  valid_606741 = validateParameter(valid_606741, JString, required = true,
                                 default = nil)
  if valid_606741 != nil:
    section.add "Namespace", valid_606741
  var valid_606742 = path.getOrDefault("AssignmentName")
  valid_606742 = validateParameter(valid_606742, JString, required = true,
                                 default = nil)
  if valid_606742 != nil:
    section.add "AssignmentName", valid_606742
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
  var valid_606743 = header.getOrDefault("X-Amz-Signature")
  valid_606743 = validateParameter(valid_606743, JString, required = false,
                                 default = nil)
  if valid_606743 != nil:
    section.add "X-Amz-Signature", valid_606743
  var valid_606744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606744 = validateParameter(valid_606744, JString, required = false,
                                 default = nil)
  if valid_606744 != nil:
    section.add "X-Amz-Content-Sha256", valid_606744
  var valid_606745 = header.getOrDefault("X-Amz-Date")
  valid_606745 = validateParameter(valid_606745, JString, required = false,
                                 default = nil)
  if valid_606745 != nil:
    section.add "X-Amz-Date", valid_606745
  var valid_606746 = header.getOrDefault("X-Amz-Credential")
  valid_606746 = validateParameter(valid_606746, JString, required = false,
                                 default = nil)
  if valid_606746 != nil:
    section.add "X-Amz-Credential", valid_606746
  var valid_606747 = header.getOrDefault("X-Amz-Security-Token")
  valid_606747 = validateParameter(valid_606747, JString, required = false,
                                 default = nil)
  if valid_606747 != nil:
    section.add "X-Amz-Security-Token", valid_606747
  var valid_606748 = header.getOrDefault("X-Amz-Algorithm")
  valid_606748 = validateParameter(valid_606748, JString, required = false,
                                 default = nil)
  if valid_606748 != nil:
    section.add "X-Amz-Algorithm", valid_606748
  var valid_606749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606749 = validateParameter(valid_606749, JString, required = false,
                                 default = nil)
  if valid_606749 != nil:
    section.add "X-Amz-SignedHeaders", valid_606749
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606750: Call_DeleteIAMPolicyAssignment_606737; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing IAM policy assignment.
  ## 
  let valid = call_606750.validator(path, query, header, formData, body)
  let scheme = call_606750.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606750.url(scheme.get, call_606750.host, call_606750.base,
                         call_606750.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606750, url, valid)

proc call*(call_606751: Call_DeleteIAMPolicyAssignment_606737;
          AwsAccountId: string; Namespace: string; AssignmentName: string): Recallable =
  ## deleteIAMPolicyAssignment
  ## Deletes an existing IAM policy assignment.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID where you want to delete the IAM policy assignment.
  ##   Namespace: string (required)
  ##            : The namespace that contains the assignment.
  ##   AssignmentName: string (required)
  ##                 : The name of the assignment. 
  var path_606752 = newJObject()
  add(path_606752, "AwsAccountId", newJString(AwsAccountId))
  add(path_606752, "Namespace", newJString(Namespace))
  add(path_606752, "AssignmentName", newJString(AssignmentName))
  result = call_606751.call(path_606752, nil, nil, nil, nil)

var deleteIAMPolicyAssignment* = Call_DeleteIAMPolicyAssignment_606737(
    name: "deleteIAMPolicyAssignment", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespace/{Namespace}/iam-policy-assignments/{AssignmentName}",
    validator: validate_DeleteIAMPolicyAssignment_606738, base: "/",
    url: url_DeleteIAMPolicyAssignment_606739,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_606769 = ref object of OpenApiRestCall_605589
proc url_UpdateUser_606771(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "UserName" in path, "`UserName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "UserName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUser_606770(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an Amazon QuickSight user.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: JString (required)
  ##           : The Amazon QuickSight user name that you want to update.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606772 = path.getOrDefault("AwsAccountId")
  valid_606772 = validateParameter(valid_606772, JString, required = true,
                                 default = nil)
  if valid_606772 != nil:
    section.add "AwsAccountId", valid_606772
  var valid_606773 = path.getOrDefault("Namespace")
  valid_606773 = validateParameter(valid_606773, JString, required = true,
                                 default = nil)
  if valid_606773 != nil:
    section.add "Namespace", valid_606773
  var valid_606774 = path.getOrDefault("UserName")
  valid_606774 = validateParameter(valid_606774, JString, required = true,
                                 default = nil)
  if valid_606774 != nil:
    section.add "UserName", valid_606774
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
  var valid_606775 = header.getOrDefault("X-Amz-Signature")
  valid_606775 = validateParameter(valid_606775, JString, required = false,
                                 default = nil)
  if valid_606775 != nil:
    section.add "X-Amz-Signature", valid_606775
  var valid_606776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606776 = validateParameter(valid_606776, JString, required = false,
                                 default = nil)
  if valid_606776 != nil:
    section.add "X-Amz-Content-Sha256", valid_606776
  var valid_606777 = header.getOrDefault("X-Amz-Date")
  valid_606777 = validateParameter(valid_606777, JString, required = false,
                                 default = nil)
  if valid_606777 != nil:
    section.add "X-Amz-Date", valid_606777
  var valid_606778 = header.getOrDefault("X-Amz-Credential")
  valid_606778 = validateParameter(valid_606778, JString, required = false,
                                 default = nil)
  if valid_606778 != nil:
    section.add "X-Amz-Credential", valid_606778
  var valid_606779 = header.getOrDefault("X-Amz-Security-Token")
  valid_606779 = validateParameter(valid_606779, JString, required = false,
                                 default = nil)
  if valid_606779 != nil:
    section.add "X-Amz-Security-Token", valid_606779
  var valid_606780 = header.getOrDefault("X-Amz-Algorithm")
  valid_606780 = validateParameter(valid_606780, JString, required = false,
                                 default = nil)
  if valid_606780 != nil:
    section.add "X-Amz-Algorithm", valid_606780
  var valid_606781 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606781 = validateParameter(valid_606781, JString, required = false,
                                 default = nil)
  if valid_606781 != nil:
    section.add "X-Amz-SignedHeaders", valid_606781
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606783: Call_UpdateUser_606769; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Amazon QuickSight user.
  ## 
  let valid = call_606783.validator(path, query, header, formData, body)
  let scheme = call_606783.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606783.url(scheme.get, call_606783.host, call_606783.base,
                         call_606783.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606783, url, valid)

proc call*(call_606784: Call_UpdateUser_606769; AwsAccountId: string;
          Namespace: string; UserName: string; body: JsonNode): Recallable =
  ## updateUser
  ## Updates an Amazon QuickSight user.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: string (required)
  ##           : The Amazon QuickSight user name that you want to update.
  ##   body: JObject (required)
  var path_606785 = newJObject()
  var body_606786 = newJObject()
  add(path_606785, "AwsAccountId", newJString(AwsAccountId))
  add(path_606785, "Namespace", newJString(Namespace))
  add(path_606785, "UserName", newJString(UserName))
  if body != nil:
    body_606786 = body
  result = call_606784.call(path_606785, nil, nil, nil, body_606786)

var updateUser* = Call_UpdateUser_606769(name: "updateUser",
                                      meth: HttpMethod.HttpPut,
                                      host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}",
                                      validator: validate_UpdateUser_606770,
                                      base: "/", url: url_UpdateUser_606771,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_606753 = ref object of OpenApiRestCall_605589
proc url_DescribeUser_606755(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "UserName" in path, "`UserName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "UserName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeUser_606754(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns information about a user, given the user name. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: JString (required)
  ##           : The name of the user that you want to describe.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606756 = path.getOrDefault("AwsAccountId")
  valid_606756 = validateParameter(valid_606756, JString, required = true,
                                 default = nil)
  if valid_606756 != nil:
    section.add "AwsAccountId", valid_606756
  var valid_606757 = path.getOrDefault("Namespace")
  valid_606757 = validateParameter(valid_606757, JString, required = true,
                                 default = nil)
  if valid_606757 != nil:
    section.add "Namespace", valid_606757
  var valid_606758 = path.getOrDefault("UserName")
  valid_606758 = validateParameter(valid_606758, JString, required = true,
                                 default = nil)
  if valid_606758 != nil:
    section.add "UserName", valid_606758
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
  var valid_606759 = header.getOrDefault("X-Amz-Signature")
  valid_606759 = validateParameter(valid_606759, JString, required = false,
                                 default = nil)
  if valid_606759 != nil:
    section.add "X-Amz-Signature", valid_606759
  var valid_606760 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606760 = validateParameter(valid_606760, JString, required = false,
                                 default = nil)
  if valid_606760 != nil:
    section.add "X-Amz-Content-Sha256", valid_606760
  var valid_606761 = header.getOrDefault("X-Amz-Date")
  valid_606761 = validateParameter(valid_606761, JString, required = false,
                                 default = nil)
  if valid_606761 != nil:
    section.add "X-Amz-Date", valid_606761
  var valid_606762 = header.getOrDefault("X-Amz-Credential")
  valid_606762 = validateParameter(valid_606762, JString, required = false,
                                 default = nil)
  if valid_606762 != nil:
    section.add "X-Amz-Credential", valid_606762
  var valid_606763 = header.getOrDefault("X-Amz-Security-Token")
  valid_606763 = validateParameter(valid_606763, JString, required = false,
                                 default = nil)
  if valid_606763 != nil:
    section.add "X-Amz-Security-Token", valid_606763
  var valid_606764 = header.getOrDefault("X-Amz-Algorithm")
  valid_606764 = validateParameter(valid_606764, JString, required = false,
                                 default = nil)
  if valid_606764 != nil:
    section.add "X-Amz-Algorithm", valid_606764
  var valid_606765 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606765 = validateParameter(valid_606765, JString, required = false,
                                 default = nil)
  if valid_606765 != nil:
    section.add "X-Amz-SignedHeaders", valid_606765
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606766: Call_DescribeUser_606753; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a user, given the user name. 
  ## 
  let valid = call_606766.validator(path, query, header, formData, body)
  let scheme = call_606766.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606766.url(scheme.get, call_606766.host, call_606766.base,
                         call_606766.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606766, url, valid)

proc call*(call_606767: Call_DescribeUser_606753; AwsAccountId: string;
          Namespace: string; UserName: string): Recallable =
  ## describeUser
  ## Returns information about a user, given the user name. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: string (required)
  ##           : The name of the user that you want to describe.
  var path_606768 = newJObject()
  add(path_606768, "AwsAccountId", newJString(AwsAccountId))
  add(path_606768, "Namespace", newJString(Namespace))
  add(path_606768, "UserName", newJString(UserName))
  result = call_606767.call(path_606768, nil, nil, nil, nil)

var describeUser* = Call_DescribeUser_606753(name: "describeUser",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}",
    validator: validate_DescribeUser_606754, base: "/", url: url_DescribeUser_606755,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_606787 = ref object of OpenApiRestCall_605589
proc url_DeleteUser_606789(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "UserName" in path, "`UserName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "UserName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteUser_606788(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the Amazon QuickSight user that is associated with the identity of the AWS Identity and Access Management (IAM) user or role that's making the call. The IAM user isn't deleted as a result of this call. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: JString (required)
  ##           : The name of the user that you want to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606790 = path.getOrDefault("AwsAccountId")
  valid_606790 = validateParameter(valid_606790, JString, required = true,
                                 default = nil)
  if valid_606790 != nil:
    section.add "AwsAccountId", valid_606790
  var valid_606791 = path.getOrDefault("Namespace")
  valid_606791 = validateParameter(valid_606791, JString, required = true,
                                 default = nil)
  if valid_606791 != nil:
    section.add "Namespace", valid_606791
  var valid_606792 = path.getOrDefault("UserName")
  valid_606792 = validateParameter(valid_606792, JString, required = true,
                                 default = nil)
  if valid_606792 != nil:
    section.add "UserName", valid_606792
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
  var valid_606793 = header.getOrDefault("X-Amz-Signature")
  valid_606793 = validateParameter(valid_606793, JString, required = false,
                                 default = nil)
  if valid_606793 != nil:
    section.add "X-Amz-Signature", valid_606793
  var valid_606794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606794 = validateParameter(valid_606794, JString, required = false,
                                 default = nil)
  if valid_606794 != nil:
    section.add "X-Amz-Content-Sha256", valid_606794
  var valid_606795 = header.getOrDefault("X-Amz-Date")
  valid_606795 = validateParameter(valid_606795, JString, required = false,
                                 default = nil)
  if valid_606795 != nil:
    section.add "X-Amz-Date", valid_606795
  var valid_606796 = header.getOrDefault("X-Amz-Credential")
  valid_606796 = validateParameter(valid_606796, JString, required = false,
                                 default = nil)
  if valid_606796 != nil:
    section.add "X-Amz-Credential", valid_606796
  var valid_606797 = header.getOrDefault("X-Amz-Security-Token")
  valid_606797 = validateParameter(valid_606797, JString, required = false,
                                 default = nil)
  if valid_606797 != nil:
    section.add "X-Amz-Security-Token", valid_606797
  var valid_606798 = header.getOrDefault("X-Amz-Algorithm")
  valid_606798 = validateParameter(valid_606798, JString, required = false,
                                 default = nil)
  if valid_606798 != nil:
    section.add "X-Amz-Algorithm", valid_606798
  var valid_606799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606799 = validateParameter(valid_606799, JString, required = false,
                                 default = nil)
  if valid_606799 != nil:
    section.add "X-Amz-SignedHeaders", valid_606799
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606800: Call_DeleteUser_606787; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the Amazon QuickSight user that is associated with the identity of the AWS Identity and Access Management (IAM) user or role that's making the call. The IAM user isn't deleted as a result of this call. 
  ## 
  let valid = call_606800.validator(path, query, header, formData, body)
  let scheme = call_606800.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606800.url(scheme.get, call_606800.host, call_606800.base,
                         call_606800.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606800, url, valid)

proc call*(call_606801: Call_DeleteUser_606787; AwsAccountId: string;
          Namespace: string; UserName: string): Recallable =
  ## deleteUser
  ## Deletes the Amazon QuickSight user that is associated with the identity of the AWS Identity and Access Management (IAM) user or role that's making the call. The IAM user isn't deleted as a result of this call. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: string (required)
  ##           : The name of the user that you want to delete.
  var path_606802 = newJObject()
  add(path_606802, "AwsAccountId", newJString(AwsAccountId))
  add(path_606802, "Namespace", newJString(Namespace))
  add(path_606802, "UserName", newJString(UserName))
  result = call_606801.call(path_606802, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_606787(name: "deleteUser",
                                      meth: HttpMethod.HttpDelete,
                                      host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}",
                                      validator: validate_DeleteUser_606788,
                                      base: "/", url: url_DeleteUser_606789,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserByPrincipalId_606803 = ref object of OpenApiRestCall_605589
proc url_DeleteUserByPrincipalId_606805(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "PrincipalId" in path, "`PrincipalId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/user-principals/"),
               (kind: VariableSegment, value: "PrincipalId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteUserByPrincipalId_606804(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a user identified by its principal ID. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   PrincipalId: JString (required)
  ##              : The principal ID of the user.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606806 = path.getOrDefault("AwsAccountId")
  valid_606806 = validateParameter(valid_606806, JString, required = true,
                                 default = nil)
  if valid_606806 != nil:
    section.add "AwsAccountId", valid_606806
  var valid_606807 = path.getOrDefault("Namespace")
  valid_606807 = validateParameter(valid_606807, JString, required = true,
                                 default = nil)
  if valid_606807 != nil:
    section.add "Namespace", valid_606807
  var valid_606808 = path.getOrDefault("PrincipalId")
  valid_606808 = validateParameter(valid_606808, JString, required = true,
                                 default = nil)
  if valid_606808 != nil:
    section.add "PrincipalId", valid_606808
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
  var valid_606809 = header.getOrDefault("X-Amz-Signature")
  valid_606809 = validateParameter(valid_606809, JString, required = false,
                                 default = nil)
  if valid_606809 != nil:
    section.add "X-Amz-Signature", valid_606809
  var valid_606810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606810 = validateParameter(valid_606810, JString, required = false,
                                 default = nil)
  if valid_606810 != nil:
    section.add "X-Amz-Content-Sha256", valid_606810
  var valid_606811 = header.getOrDefault("X-Amz-Date")
  valid_606811 = validateParameter(valid_606811, JString, required = false,
                                 default = nil)
  if valid_606811 != nil:
    section.add "X-Amz-Date", valid_606811
  var valid_606812 = header.getOrDefault("X-Amz-Credential")
  valid_606812 = validateParameter(valid_606812, JString, required = false,
                                 default = nil)
  if valid_606812 != nil:
    section.add "X-Amz-Credential", valid_606812
  var valid_606813 = header.getOrDefault("X-Amz-Security-Token")
  valid_606813 = validateParameter(valid_606813, JString, required = false,
                                 default = nil)
  if valid_606813 != nil:
    section.add "X-Amz-Security-Token", valid_606813
  var valid_606814 = header.getOrDefault("X-Amz-Algorithm")
  valid_606814 = validateParameter(valid_606814, JString, required = false,
                                 default = nil)
  if valid_606814 != nil:
    section.add "X-Amz-Algorithm", valid_606814
  var valid_606815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606815 = validateParameter(valid_606815, JString, required = false,
                                 default = nil)
  if valid_606815 != nil:
    section.add "X-Amz-SignedHeaders", valid_606815
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606816: Call_DeleteUserByPrincipalId_606803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a user identified by its principal ID. 
  ## 
  let valid = call_606816.validator(path, query, header, formData, body)
  let scheme = call_606816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606816.url(scheme.get, call_606816.host, call_606816.base,
                         call_606816.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606816, url, valid)

proc call*(call_606817: Call_DeleteUserByPrincipalId_606803; AwsAccountId: string;
          Namespace: string; PrincipalId: string): Recallable =
  ## deleteUserByPrincipalId
  ## Deletes a user identified by its principal ID. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   PrincipalId: string (required)
  ##              : The principal ID of the user.
  var path_606818 = newJObject()
  add(path_606818, "AwsAccountId", newJString(AwsAccountId))
  add(path_606818, "Namespace", newJString(Namespace))
  add(path_606818, "PrincipalId", newJString(PrincipalId))
  result = call_606817.call(path_606818, nil, nil, nil, nil)

var deleteUserByPrincipalId* = Call_DeleteUserByPrincipalId_606803(
    name: "deleteUserByPrincipalId", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/user-principals/{PrincipalId}",
    validator: validate_DeleteUserByPrincipalId_606804, base: "/",
    url: url_DeleteUserByPrincipalId_606805, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDashboardPermissions_606834 = ref object of OpenApiRestCall_605589
proc url_UpdateDashboardPermissions_606836(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DashboardId" in path, "`DashboardId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/dashboards/"),
               (kind: VariableSegment, value: "DashboardId"),
               (kind: ConstantSegment, value: "/permissions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDashboardPermissions_606835(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates read and write permissions on a dashboard.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the dashboard whose permissions you're updating.
  ##   DashboardId: JString (required)
  ##              : The ID for the dashboard.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606837 = path.getOrDefault("AwsAccountId")
  valid_606837 = validateParameter(valid_606837, JString, required = true,
                                 default = nil)
  if valid_606837 != nil:
    section.add "AwsAccountId", valid_606837
  var valid_606838 = path.getOrDefault("DashboardId")
  valid_606838 = validateParameter(valid_606838, JString, required = true,
                                 default = nil)
  if valid_606838 != nil:
    section.add "DashboardId", valid_606838
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
  var valid_606839 = header.getOrDefault("X-Amz-Signature")
  valid_606839 = validateParameter(valid_606839, JString, required = false,
                                 default = nil)
  if valid_606839 != nil:
    section.add "X-Amz-Signature", valid_606839
  var valid_606840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606840 = validateParameter(valid_606840, JString, required = false,
                                 default = nil)
  if valid_606840 != nil:
    section.add "X-Amz-Content-Sha256", valid_606840
  var valid_606841 = header.getOrDefault("X-Amz-Date")
  valid_606841 = validateParameter(valid_606841, JString, required = false,
                                 default = nil)
  if valid_606841 != nil:
    section.add "X-Amz-Date", valid_606841
  var valid_606842 = header.getOrDefault("X-Amz-Credential")
  valid_606842 = validateParameter(valid_606842, JString, required = false,
                                 default = nil)
  if valid_606842 != nil:
    section.add "X-Amz-Credential", valid_606842
  var valid_606843 = header.getOrDefault("X-Amz-Security-Token")
  valid_606843 = validateParameter(valid_606843, JString, required = false,
                                 default = nil)
  if valid_606843 != nil:
    section.add "X-Amz-Security-Token", valid_606843
  var valid_606844 = header.getOrDefault("X-Amz-Algorithm")
  valid_606844 = validateParameter(valid_606844, JString, required = false,
                                 default = nil)
  if valid_606844 != nil:
    section.add "X-Amz-Algorithm", valid_606844
  var valid_606845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606845 = validateParameter(valid_606845, JString, required = false,
                                 default = nil)
  if valid_606845 != nil:
    section.add "X-Amz-SignedHeaders", valid_606845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606847: Call_UpdateDashboardPermissions_606834; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates read and write permissions on a dashboard.
  ## 
  let valid = call_606847.validator(path, query, header, formData, body)
  let scheme = call_606847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606847.url(scheme.get, call_606847.host, call_606847.base,
                         call_606847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606847, url, valid)

proc call*(call_606848: Call_UpdateDashboardPermissions_606834;
          AwsAccountId: string; body: JsonNode; DashboardId: string): Recallable =
  ## updateDashboardPermissions
  ## Updates read and write permissions on a dashboard.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard whose permissions you're updating.
  ##   body: JObject (required)
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  var path_606849 = newJObject()
  var body_606850 = newJObject()
  add(path_606849, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_606850 = body
  add(path_606849, "DashboardId", newJString(DashboardId))
  result = call_606848.call(path_606849, nil, nil, nil, body_606850)

var updateDashboardPermissions* = Call_UpdateDashboardPermissions_606834(
    name: "updateDashboardPermissions", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/permissions",
    validator: validate_UpdateDashboardPermissions_606835, base: "/",
    url: url_UpdateDashboardPermissions_606836,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDashboardPermissions_606819 = ref object of OpenApiRestCall_605589
proc url_DescribeDashboardPermissions_606821(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DashboardId" in path, "`DashboardId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/dashboards/"),
               (kind: VariableSegment, value: "DashboardId"),
               (kind: ConstantSegment, value: "/permissions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDashboardPermissions_606820(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes read and write permissions for a dashboard.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the dashboard that you're describing permissions for.
  ##   DashboardId: JString (required)
  ##              : The ID for the dashboard, also added to the IAM policy.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606822 = path.getOrDefault("AwsAccountId")
  valid_606822 = validateParameter(valid_606822, JString, required = true,
                                 default = nil)
  if valid_606822 != nil:
    section.add "AwsAccountId", valid_606822
  var valid_606823 = path.getOrDefault("DashboardId")
  valid_606823 = validateParameter(valid_606823, JString, required = true,
                                 default = nil)
  if valid_606823 != nil:
    section.add "DashboardId", valid_606823
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
  var valid_606824 = header.getOrDefault("X-Amz-Signature")
  valid_606824 = validateParameter(valid_606824, JString, required = false,
                                 default = nil)
  if valid_606824 != nil:
    section.add "X-Amz-Signature", valid_606824
  var valid_606825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606825 = validateParameter(valid_606825, JString, required = false,
                                 default = nil)
  if valid_606825 != nil:
    section.add "X-Amz-Content-Sha256", valid_606825
  var valid_606826 = header.getOrDefault("X-Amz-Date")
  valid_606826 = validateParameter(valid_606826, JString, required = false,
                                 default = nil)
  if valid_606826 != nil:
    section.add "X-Amz-Date", valid_606826
  var valid_606827 = header.getOrDefault("X-Amz-Credential")
  valid_606827 = validateParameter(valid_606827, JString, required = false,
                                 default = nil)
  if valid_606827 != nil:
    section.add "X-Amz-Credential", valid_606827
  var valid_606828 = header.getOrDefault("X-Amz-Security-Token")
  valid_606828 = validateParameter(valid_606828, JString, required = false,
                                 default = nil)
  if valid_606828 != nil:
    section.add "X-Amz-Security-Token", valid_606828
  var valid_606829 = header.getOrDefault("X-Amz-Algorithm")
  valid_606829 = validateParameter(valid_606829, JString, required = false,
                                 default = nil)
  if valid_606829 != nil:
    section.add "X-Amz-Algorithm", valid_606829
  var valid_606830 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606830 = validateParameter(valid_606830, JString, required = false,
                                 default = nil)
  if valid_606830 != nil:
    section.add "X-Amz-SignedHeaders", valid_606830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606831: Call_DescribeDashboardPermissions_606819; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes read and write permissions for a dashboard.
  ## 
  let valid = call_606831.validator(path, query, header, formData, body)
  let scheme = call_606831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606831.url(scheme.get, call_606831.host, call_606831.base,
                         call_606831.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606831, url, valid)

proc call*(call_606832: Call_DescribeDashboardPermissions_606819;
          AwsAccountId: string; DashboardId: string): Recallable =
  ## describeDashboardPermissions
  ## Describes read and write permissions for a dashboard.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're describing permissions for.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard, also added to the IAM policy.
  var path_606833 = newJObject()
  add(path_606833, "AwsAccountId", newJString(AwsAccountId))
  add(path_606833, "DashboardId", newJString(DashboardId))
  result = call_606832.call(path_606833, nil, nil, nil, nil)

var describeDashboardPermissions* = Call_DescribeDashboardPermissions_606819(
    name: "describeDashboardPermissions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/permissions",
    validator: validate_DescribeDashboardPermissions_606820, base: "/",
    url: url_DescribeDashboardPermissions_606821,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSetPermissions_606866 = ref object of OpenApiRestCall_605589
proc url_UpdateDataSetPermissions_606868(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/permissions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDataSetPermissions_606867(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  ##   DataSetId: JString (required)
  ##            : The ID for the dataset whose permissions you want to update. This ID is unique per AWS Region for each AWS account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606869 = path.getOrDefault("AwsAccountId")
  valid_606869 = validateParameter(valid_606869, JString, required = true,
                                 default = nil)
  if valid_606869 != nil:
    section.add "AwsAccountId", valid_606869
  var valid_606870 = path.getOrDefault("DataSetId")
  valid_606870 = validateParameter(valid_606870, JString, required = true,
                                 default = nil)
  if valid_606870 != nil:
    section.add "DataSetId", valid_606870
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
  var valid_606871 = header.getOrDefault("X-Amz-Signature")
  valid_606871 = validateParameter(valid_606871, JString, required = false,
                                 default = nil)
  if valid_606871 != nil:
    section.add "X-Amz-Signature", valid_606871
  var valid_606872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606872 = validateParameter(valid_606872, JString, required = false,
                                 default = nil)
  if valid_606872 != nil:
    section.add "X-Amz-Content-Sha256", valid_606872
  var valid_606873 = header.getOrDefault("X-Amz-Date")
  valid_606873 = validateParameter(valid_606873, JString, required = false,
                                 default = nil)
  if valid_606873 != nil:
    section.add "X-Amz-Date", valid_606873
  var valid_606874 = header.getOrDefault("X-Amz-Credential")
  valid_606874 = validateParameter(valid_606874, JString, required = false,
                                 default = nil)
  if valid_606874 != nil:
    section.add "X-Amz-Credential", valid_606874
  var valid_606875 = header.getOrDefault("X-Amz-Security-Token")
  valid_606875 = validateParameter(valid_606875, JString, required = false,
                                 default = nil)
  if valid_606875 != nil:
    section.add "X-Amz-Security-Token", valid_606875
  var valid_606876 = header.getOrDefault("X-Amz-Algorithm")
  valid_606876 = validateParameter(valid_606876, JString, required = false,
                                 default = nil)
  if valid_606876 != nil:
    section.add "X-Amz-Algorithm", valid_606876
  var valid_606877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606877 = validateParameter(valid_606877, JString, required = false,
                                 default = nil)
  if valid_606877 != nil:
    section.add "X-Amz-SignedHeaders", valid_606877
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606879: Call_UpdateDataSetPermissions_606866; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
  ## 
  let valid = call_606879.validator(path, query, header, formData, body)
  let scheme = call_606879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606879.url(scheme.get, call_606879.host, call_606879.base,
                         call_606879.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606879, url, valid)

proc call*(call_606880: Call_UpdateDataSetPermissions_606866; AwsAccountId: string;
          DataSetId: string; body: JsonNode): Recallable =
  ## updateDataSetPermissions
  ## <p>Updates the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset whose permissions you want to update. This ID is unique per AWS Region for each AWS account.
  ##   body: JObject (required)
  var path_606881 = newJObject()
  var body_606882 = newJObject()
  add(path_606881, "AwsAccountId", newJString(AwsAccountId))
  add(path_606881, "DataSetId", newJString(DataSetId))
  if body != nil:
    body_606882 = body
  result = call_606880.call(path_606881, nil, nil, nil, body_606882)

var updateDataSetPermissions* = Call_UpdateDataSetPermissions_606866(
    name: "updateDataSetPermissions", meth: HttpMethod.HttpPost,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/permissions",
    validator: validate_UpdateDataSetPermissions_606867, base: "/",
    url: url_UpdateDataSetPermissions_606868, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSetPermissions_606851 = ref object of OpenApiRestCall_605589
proc url_DescribeDataSetPermissions_606853(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/permissions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDataSetPermissions_606852(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  ##   DataSetId: JString (required)
  ##            : The ID for the dataset that you want to create. This ID is unique per AWS Region for each AWS account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606854 = path.getOrDefault("AwsAccountId")
  valid_606854 = validateParameter(valid_606854, JString, required = true,
                                 default = nil)
  if valid_606854 != nil:
    section.add "AwsAccountId", valid_606854
  var valid_606855 = path.getOrDefault("DataSetId")
  valid_606855 = validateParameter(valid_606855, JString, required = true,
                                 default = nil)
  if valid_606855 != nil:
    section.add "DataSetId", valid_606855
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
  var valid_606856 = header.getOrDefault("X-Amz-Signature")
  valid_606856 = validateParameter(valid_606856, JString, required = false,
                                 default = nil)
  if valid_606856 != nil:
    section.add "X-Amz-Signature", valid_606856
  var valid_606857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606857 = validateParameter(valid_606857, JString, required = false,
                                 default = nil)
  if valid_606857 != nil:
    section.add "X-Amz-Content-Sha256", valid_606857
  var valid_606858 = header.getOrDefault("X-Amz-Date")
  valid_606858 = validateParameter(valid_606858, JString, required = false,
                                 default = nil)
  if valid_606858 != nil:
    section.add "X-Amz-Date", valid_606858
  var valid_606859 = header.getOrDefault("X-Amz-Credential")
  valid_606859 = validateParameter(valid_606859, JString, required = false,
                                 default = nil)
  if valid_606859 != nil:
    section.add "X-Amz-Credential", valid_606859
  var valid_606860 = header.getOrDefault("X-Amz-Security-Token")
  valid_606860 = validateParameter(valid_606860, JString, required = false,
                                 default = nil)
  if valid_606860 != nil:
    section.add "X-Amz-Security-Token", valid_606860
  var valid_606861 = header.getOrDefault("X-Amz-Algorithm")
  valid_606861 = validateParameter(valid_606861, JString, required = false,
                                 default = nil)
  if valid_606861 != nil:
    section.add "X-Amz-Algorithm", valid_606861
  var valid_606862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606862 = validateParameter(valid_606862, JString, required = false,
                                 default = nil)
  if valid_606862 != nil:
    section.add "X-Amz-SignedHeaders", valid_606862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606863: Call_DescribeDataSetPermissions_606851; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
  ## 
  let valid = call_606863.validator(path, query, header, formData, body)
  let scheme = call_606863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606863.url(scheme.get, call_606863.host, call_606863.base,
                         call_606863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606863, url, valid)

proc call*(call_606864: Call_DescribeDataSetPermissions_606851;
          AwsAccountId: string; DataSetId: string): Recallable =
  ## describeDataSetPermissions
  ## <p>Describes the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset that you want to create. This ID is unique per AWS Region for each AWS account.
  var path_606865 = newJObject()
  add(path_606865, "AwsAccountId", newJString(AwsAccountId))
  add(path_606865, "DataSetId", newJString(DataSetId))
  result = call_606864.call(path_606865, nil, nil, nil, nil)

var describeDataSetPermissions* = Call_DescribeDataSetPermissions_606851(
    name: "describeDataSetPermissions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/permissions",
    validator: validate_DescribeDataSetPermissions_606852, base: "/",
    url: url_DescribeDataSetPermissions_606853,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSourcePermissions_606898 = ref object of OpenApiRestCall_605589
proc url_UpdateDataSourcePermissions_606900(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DataSourceId" in path, "`DataSourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sources/"),
               (kind: VariableSegment, value: "DataSourceId"),
               (kind: ConstantSegment, value: "/permissions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDataSourcePermissions_606899(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the permissions to a data source.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSourceId: JString (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account. 
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DataSourceId` field"
  var valid_606901 = path.getOrDefault("DataSourceId")
  valid_606901 = validateParameter(valid_606901, JString, required = true,
                                 default = nil)
  if valid_606901 != nil:
    section.add "DataSourceId", valid_606901
  var valid_606902 = path.getOrDefault("AwsAccountId")
  valid_606902 = validateParameter(valid_606902, JString, required = true,
                                 default = nil)
  if valid_606902 != nil:
    section.add "AwsAccountId", valid_606902
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
  var valid_606903 = header.getOrDefault("X-Amz-Signature")
  valid_606903 = validateParameter(valid_606903, JString, required = false,
                                 default = nil)
  if valid_606903 != nil:
    section.add "X-Amz-Signature", valid_606903
  var valid_606904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606904 = validateParameter(valid_606904, JString, required = false,
                                 default = nil)
  if valid_606904 != nil:
    section.add "X-Amz-Content-Sha256", valid_606904
  var valid_606905 = header.getOrDefault("X-Amz-Date")
  valid_606905 = validateParameter(valid_606905, JString, required = false,
                                 default = nil)
  if valid_606905 != nil:
    section.add "X-Amz-Date", valid_606905
  var valid_606906 = header.getOrDefault("X-Amz-Credential")
  valid_606906 = validateParameter(valid_606906, JString, required = false,
                                 default = nil)
  if valid_606906 != nil:
    section.add "X-Amz-Credential", valid_606906
  var valid_606907 = header.getOrDefault("X-Amz-Security-Token")
  valid_606907 = validateParameter(valid_606907, JString, required = false,
                                 default = nil)
  if valid_606907 != nil:
    section.add "X-Amz-Security-Token", valid_606907
  var valid_606908 = header.getOrDefault("X-Amz-Algorithm")
  valid_606908 = validateParameter(valid_606908, JString, required = false,
                                 default = nil)
  if valid_606908 != nil:
    section.add "X-Amz-Algorithm", valid_606908
  var valid_606909 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606909 = validateParameter(valid_606909, JString, required = false,
                                 default = nil)
  if valid_606909 != nil:
    section.add "X-Amz-SignedHeaders", valid_606909
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606911: Call_UpdateDataSourcePermissions_606898; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the permissions to a data source.
  ## 
  let valid = call_606911.validator(path, query, header, formData, body)
  let scheme = call_606911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606911.url(scheme.get, call_606911.host, call_606911.base,
                         call_606911.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606911, url, valid)

proc call*(call_606912: Call_UpdateDataSourcePermissions_606898;
          DataSourceId: string; AwsAccountId: string; body: JsonNode): Recallable =
  ## updateDataSourcePermissions
  ## Updates the permissions to a data source.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account. 
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   body: JObject (required)
  var path_606913 = newJObject()
  var body_606914 = newJObject()
  add(path_606913, "DataSourceId", newJString(DataSourceId))
  add(path_606913, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_606914 = body
  result = call_606912.call(path_606913, nil, nil, nil, body_606914)

var updateDataSourcePermissions* = Call_UpdateDataSourcePermissions_606898(
    name: "updateDataSourcePermissions", meth: HttpMethod.HttpPost,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}/permissions",
    validator: validate_UpdateDataSourcePermissions_606899, base: "/",
    url: url_UpdateDataSourcePermissions_606900,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSourcePermissions_606883 = ref object of OpenApiRestCall_605589
proc url_DescribeDataSourcePermissions_606885(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DataSourceId" in path, "`DataSourceId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sources/"),
               (kind: VariableSegment, value: "DataSourceId"),
               (kind: ConstantSegment, value: "/permissions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDataSourcePermissions_606884(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes the resource permissions for a data source.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   DataSourceId: JString (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account.
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `DataSourceId` field"
  var valid_606886 = path.getOrDefault("DataSourceId")
  valid_606886 = validateParameter(valid_606886, JString, required = true,
                                 default = nil)
  if valid_606886 != nil:
    section.add "DataSourceId", valid_606886
  var valid_606887 = path.getOrDefault("AwsAccountId")
  valid_606887 = validateParameter(valid_606887, JString, required = true,
                                 default = nil)
  if valid_606887 != nil:
    section.add "AwsAccountId", valid_606887
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
  var valid_606888 = header.getOrDefault("X-Amz-Signature")
  valid_606888 = validateParameter(valid_606888, JString, required = false,
                                 default = nil)
  if valid_606888 != nil:
    section.add "X-Amz-Signature", valid_606888
  var valid_606889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606889 = validateParameter(valid_606889, JString, required = false,
                                 default = nil)
  if valid_606889 != nil:
    section.add "X-Amz-Content-Sha256", valid_606889
  var valid_606890 = header.getOrDefault("X-Amz-Date")
  valid_606890 = validateParameter(valid_606890, JString, required = false,
                                 default = nil)
  if valid_606890 != nil:
    section.add "X-Amz-Date", valid_606890
  var valid_606891 = header.getOrDefault("X-Amz-Credential")
  valid_606891 = validateParameter(valid_606891, JString, required = false,
                                 default = nil)
  if valid_606891 != nil:
    section.add "X-Amz-Credential", valid_606891
  var valid_606892 = header.getOrDefault("X-Amz-Security-Token")
  valid_606892 = validateParameter(valid_606892, JString, required = false,
                                 default = nil)
  if valid_606892 != nil:
    section.add "X-Amz-Security-Token", valid_606892
  var valid_606893 = header.getOrDefault("X-Amz-Algorithm")
  valid_606893 = validateParameter(valid_606893, JString, required = false,
                                 default = nil)
  if valid_606893 != nil:
    section.add "X-Amz-Algorithm", valid_606893
  var valid_606894 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606894 = validateParameter(valid_606894, JString, required = false,
                                 default = nil)
  if valid_606894 != nil:
    section.add "X-Amz-SignedHeaders", valid_606894
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606895: Call_DescribeDataSourcePermissions_606883; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the resource permissions for a data source.
  ## 
  let valid = call_606895.validator(path, query, header, formData, body)
  let scheme = call_606895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606895.url(scheme.get, call_606895.host, call_606895.base,
                         call_606895.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606895, url, valid)

proc call*(call_606896: Call_DescribeDataSourcePermissions_606883;
          DataSourceId: string; AwsAccountId: string): Recallable =
  ## describeDataSourcePermissions
  ## Describes the resource permissions for a data source.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  var path_606897 = newJObject()
  add(path_606897, "DataSourceId", newJString(DataSourceId))
  add(path_606897, "AwsAccountId", newJString(AwsAccountId))
  result = call_606896.call(path_606897, nil, nil, nil, nil)

var describeDataSourcePermissions* = Call_DescribeDataSourcePermissions_606883(
    name: "describeDataSourcePermissions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}/permissions",
    validator: validate_DescribeDataSourcePermissions_606884, base: "/",
    url: url_DescribeDataSourcePermissions_606885,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIAMPolicyAssignment_606931 = ref object of OpenApiRestCall_605589
proc url_UpdateIAMPolicyAssignment_606933(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "AssignmentName" in path, "`AssignmentName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/iam-policy-assignments/"),
               (kind: VariableSegment, value: "AssignmentName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateIAMPolicyAssignment_606932(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing IAM policy assignment. This operation updates only the optional parameter or parameters that are specified in the request.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the IAM policy assignment.
  ##   Namespace: JString (required)
  ##            : The namespace of the assignment.
  ##   AssignmentName: JString (required)
  ##                 : The name of the assignment. This name must be unique within an AWS account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606934 = path.getOrDefault("AwsAccountId")
  valid_606934 = validateParameter(valid_606934, JString, required = true,
                                 default = nil)
  if valid_606934 != nil:
    section.add "AwsAccountId", valid_606934
  var valid_606935 = path.getOrDefault("Namespace")
  valid_606935 = validateParameter(valid_606935, JString, required = true,
                                 default = nil)
  if valid_606935 != nil:
    section.add "Namespace", valid_606935
  var valid_606936 = path.getOrDefault("AssignmentName")
  valid_606936 = validateParameter(valid_606936, JString, required = true,
                                 default = nil)
  if valid_606936 != nil:
    section.add "AssignmentName", valid_606936
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
  var valid_606937 = header.getOrDefault("X-Amz-Signature")
  valid_606937 = validateParameter(valid_606937, JString, required = false,
                                 default = nil)
  if valid_606937 != nil:
    section.add "X-Amz-Signature", valid_606937
  var valid_606938 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606938 = validateParameter(valid_606938, JString, required = false,
                                 default = nil)
  if valid_606938 != nil:
    section.add "X-Amz-Content-Sha256", valid_606938
  var valid_606939 = header.getOrDefault("X-Amz-Date")
  valid_606939 = validateParameter(valid_606939, JString, required = false,
                                 default = nil)
  if valid_606939 != nil:
    section.add "X-Amz-Date", valid_606939
  var valid_606940 = header.getOrDefault("X-Amz-Credential")
  valid_606940 = validateParameter(valid_606940, JString, required = false,
                                 default = nil)
  if valid_606940 != nil:
    section.add "X-Amz-Credential", valid_606940
  var valid_606941 = header.getOrDefault("X-Amz-Security-Token")
  valid_606941 = validateParameter(valid_606941, JString, required = false,
                                 default = nil)
  if valid_606941 != nil:
    section.add "X-Amz-Security-Token", valid_606941
  var valid_606942 = header.getOrDefault("X-Amz-Algorithm")
  valid_606942 = validateParameter(valid_606942, JString, required = false,
                                 default = nil)
  if valid_606942 != nil:
    section.add "X-Amz-Algorithm", valid_606942
  var valid_606943 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606943 = validateParameter(valid_606943, JString, required = false,
                                 default = nil)
  if valid_606943 != nil:
    section.add "X-Amz-SignedHeaders", valid_606943
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606945: Call_UpdateIAMPolicyAssignment_606931; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing IAM policy assignment. This operation updates only the optional parameter or parameters that are specified in the request.
  ## 
  let valid = call_606945.validator(path, query, header, formData, body)
  let scheme = call_606945.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606945.url(scheme.get, call_606945.host, call_606945.base,
                         call_606945.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606945, url, valid)

proc call*(call_606946: Call_UpdateIAMPolicyAssignment_606931;
          AwsAccountId: string; Namespace: string; AssignmentName: string;
          body: JsonNode): Recallable =
  ## updateIAMPolicyAssignment
  ## Updates an existing IAM policy assignment. This operation updates only the optional parameter or parameters that are specified in the request.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the IAM policy assignment.
  ##   Namespace: string (required)
  ##            : The namespace of the assignment.
  ##   AssignmentName: string (required)
  ##                 : The name of the assignment. This name must be unique within an AWS account.
  ##   body: JObject (required)
  var path_606947 = newJObject()
  var body_606948 = newJObject()
  add(path_606947, "AwsAccountId", newJString(AwsAccountId))
  add(path_606947, "Namespace", newJString(Namespace))
  add(path_606947, "AssignmentName", newJString(AssignmentName))
  if body != nil:
    body_606948 = body
  result = call_606946.call(path_606947, nil, nil, nil, body_606948)

var updateIAMPolicyAssignment* = Call_UpdateIAMPolicyAssignment_606931(
    name: "updateIAMPolicyAssignment", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/{AssignmentName}",
    validator: validate_UpdateIAMPolicyAssignment_606932, base: "/",
    url: url_UpdateIAMPolicyAssignment_606933,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIAMPolicyAssignment_606915 = ref object of OpenApiRestCall_605589
proc url_DescribeIAMPolicyAssignment_606917(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "AssignmentName" in path, "`AssignmentName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/iam-policy-assignments/"),
               (kind: VariableSegment, value: "AssignmentName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeIAMPolicyAssignment_606916(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes an existing IAM policy assignment, as specified by the assignment name.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the assignment that you want to describe.
  ##   Namespace: JString (required)
  ##            : The namespace that contains the assignment.
  ##   AssignmentName: JString (required)
  ##                 : The name of the assignment. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606918 = path.getOrDefault("AwsAccountId")
  valid_606918 = validateParameter(valid_606918, JString, required = true,
                                 default = nil)
  if valid_606918 != nil:
    section.add "AwsAccountId", valid_606918
  var valid_606919 = path.getOrDefault("Namespace")
  valid_606919 = validateParameter(valid_606919, JString, required = true,
                                 default = nil)
  if valid_606919 != nil:
    section.add "Namespace", valid_606919
  var valid_606920 = path.getOrDefault("AssignmentName")
  valid_606920 = validateParameter(valid_606920, JString, required = true,
                                 default = nil)
  if valid_606920 != nil:
    section.add "AssignmentName", valid_606920
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
  var valid_606921 = header.getOrDefault("X-Amz-Signature")
  valid_606921 = validateParameter(valid_606921, JString, required = false,
                                 default = nil)
  if valid_606921 != nil:
    section.add "X-Amz-Signature", valid_606921
  var valid_606922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606922 = validateParameter(valid_606922, JString, required = false,
                                 default = nil)
  if valid_606922 != nil:
    section.add "X-Amz-Content-Sha256", valid_606922
  var valid_606923 = header.getOrDefault("X-Amz-Date")
  valid_606923 = validateParameter(valid_606923, JString, required = false,
                                 default = nil)
  if valid_606923 != nil:
    section.add "X-Amz-Date", valid_606923
  var valid_606924 = header.getOrDefault("X-Amz-Credential")
  valid_606924 = validateParameter(valid_606924, JString, required = false,
                                 default = nil)
  if valid_606924 != nil:
    section.add "X-Amz-Credential", valid_606924
  var valid_606925 = header.getOrDefault("X-Amz-Security-Token")
  valid_606925 = validateParameter(valid_606925, JString, required = false,
                                 default = nil)
  if valid_606925 != nil:
    section.add "X-Amz-Security-Token", valid_606925
  var valid_606926 = header.getOrDefault("X-Amz-Algorithm")
  valid_606926 = validateParameter(valid_606926, JString, required = false,
                                 default = nil)
  if valid_606926 != nil:
    section.add "X-Amz-Algorithm", valid_606926
  var valid_606927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606927 = validateParameter(valid_606927, JString, required = false,
                                 default = nil)
  if valid_606927 != nil:
    section.add "X-Amz-SignedHeaders", valid_606927
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606928: Call_DescribeIAMPolicyAssignment_606915; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing IAM policy assignment, as specified by the assignment name.
  ## 
  let valid = call_606928.validator(path, query, header, formData, body)
  let scheme = call_606928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606928.url(scheme.get, call_606928.host, call_606928.base,
                         call_606928.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606928, url, valid)

proc call*(call_606929: Call_DescribeIAMPolicyAssignment_606915;
          AwsAccountId: string; Namespace: string; AssignmentName: string): Recallable =
  ## describeIAMPolicyAssignment
  ## Describes an existing IAM policy assignment, as specified by the assignment name.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the assignment that you want to describe.
  ##   Namespace: string (required)
  ##            : The namespace that contains the assignment.
  ##   AssignmentName: string (required)
  ##                 : The name of the assignment. 
  var path_606930 = newJObject()
  add(path_606930, "AwsAccountId", newJString(AwsAccountId))
  add(path_606930, "Namespace", newJString(Namespace))
  add(path_606930, "AssignmentName", newJString(AssignmentName))
  result = call_606929.call(path_606930, nil, nil, nil, nil)

var describeIAMPolicyAssignment* = Call_DescribeIAMPolicyAssignment_606915(
    name: "describeIAMPolicyAssignment", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/{AssignmentName}",
    validator: validate_DescribeIAMPolicyAssignment_606916, base: "/",
    url: url_DescribeIAMPolicyAssignment_606917,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTemplatePermissions_606964 = ref object of OpenApiRestCall_605589
proc url_UpdateTemplatePermissions_606966(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "TemplateId" in path, "`TemplateId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/templates/"),
               (kind: VariableSegment, value: "TemplateId"),
               (kind: ConstantSegment, value: "/permissions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateTemplatePermissions_606965(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the resource permissions for a template.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the template.
  ##   TemplateId: JString (required)
  ##             : The ID for the template.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606967 = path.getOrDefault("AwsAccountId")
  valid_606967 = validateParameter(valid_606967, JString, required = true,
                                 default = nil)
  if valid_606967 != nil:
    section.add "AwsAccountId", valid_606967
  var valid_606968 = path.getOrDefault("TemplateId")
  valid_606968 = validateParameter(valid_606968, JString, required = true,
                                 default = nil)
  if valid_606968 != nil:
    section.add "TemplateId", valid_606968
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
  var valid_606969 = header.getOrDefault("X-Amz-Signature")
  valid_606969 = validateParameter(valid_606969, JString, required = false,
                                 default = nil)
  if valid_606969 != nil:
    section.add "X-Amz-Signature", valid_606969
  var valid_606970 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606970 = validateParameter(valid_606970, JString, required = false,
                                 default = nil)
  if valid_606970 != nil:
    section.add "X-Amz-Content-Sha256", valid_606970
  var valid_606971 = header.getOrDefault("X-Amz-Date")
  valid_606971 = validateParameter(valid_606971, JString, required = false,
                                 default = nil)
  if valid_606971 != nil:
    section.add "X-Amz-Date", valid_606971
  var valid_606972 = header.getOrDefault("X-Amz-Credential")
  valid_606972 = validateParameter(valid_606972, JString, required = false,
                                 default = nil)
  if valid_606972 != nil:
    section.add "X-Amz-Credential", valid_606972
  var valid_606973 = header.getOrDefault("X-Amz-Security-Token")
  valid_606973 = validateParameter(valid_606973, JString, required = false,
                                 default = nil)
  if valid_606973 != nil:
    section.add "X-Amz-Security-Token", valid_606973
  var valid_606974 = header.getOrDefault("X-Amz-Algorithm")
  valid_606974 = validateParameter(valid_606974, JString, required = false,
                                 default = nil)
  if valid_606974 != nil:
    section.add "X-Amz-Algorithm", valid_606974
  var valid_606975 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606975 = validateParameter(valid_606975, JString, required = false,
                                 default = nil)
  if valid_606975 != nil:
    section.add "X-Amz-SignedHeaders", valid_606975
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606977: Call_UpdateTemplatePermissions_606964; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the resource permissions for a template.
  ## 
  let valid = call_606977.validator(path, query, header, formData, body)
  let scheme = call_606977.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606977.url(scheme.get, call_606977.host, call_606977.base,
                         call_606977.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606977, url, valid)

proc call*(call_606978: Call_UpdateTemplatePermissions_606964;
          AwsAccountId: string; TemplateId: string; body: JsonNode): Recallable =
  ## updateTemplatePermissions
  ## Updates the resource permissions for a template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  ##   body: JObject (required)
  var path_606979 = newJObject()
  var body_606980 = newJObject()
  add(path_606979, "AwsAccountId", newJString(AwsAccountId))
  add(path_606979, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_606980 = body
  result = call_606978.call(path_606979, nil, nil, nil, body_606980)

var updateTemplatePermissions* = Call_UpdateTemplatePermissions_606964(
    name: "updateTemplatePermissions", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}/permissions",
    validator: validate_UpdateTemplatePermissions_606965, base: "/",
    url: url_UpdateTemplatePermissions_606966,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTemplatePermissions_606949 = ref object of OpenApiRestCall_605589
proc url_DescribeTemplatePermissions_606951(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "TemplateId" in path, "`TemplateId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/templates/"),
               (kind: VariableSegment, value: "TemplateId"),
               (kind: ConstantSegment, value: "/permissions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeTemplatePermissions_606950(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes read and write permissions on a template.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the template that you're describing.
  ##   TemplateId: JString (required)
  ##             : The ID for the template.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606952 = path.getOrDefault("AwsAccountId")
  valid_606952 = validateParameter(valid_606952, JString, required = true,
                                 default = nil)
  if valid_606952 != nil:
    section.add "AwsAccountId", valid_606952
  var valid_606953 = path.getOrDefault("TemplateId")
  valid_606953 = validateParameter(valid_606953, JString, required = true,
                                 default = nil)
  if valid_606953 != nil:
    section.add "TemplateId", valid_606953
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
  var valid_606954 = header.getOrDefault("X-Amz-Signature")
  valid_606954 = validateParameter(valid_606954, JString, required = false,
                                 default = nil)
  if valid_606954 != nil:
    section.add "X-Amz-Signature", valid_606954
  var valid_606955 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606955 = validateParameter(valid_606955, JString, required = false,
                                 default = nil)
  if valid_606955 != nil:
    section.add "X-Amz-Content-Sha256", valid_606955
  var valid_606956 = header.getOrDefault("X-Amz-Date")
  valid_606956 = validateParameter(valid_606956, JString, required = false,
                                 default = nil)
  if valid_606956 != nil:
    section.add "X-Amz-Date", valid_606956
  var valid_606957 = header.getOrDefault("X-Amz-Credential")
  valid_606957 = validateParameter(valid_606957, JString, required = false,
                                 default = nil)
  if valid_606957 != nil:
    section.add "X-Amz-Credential", valid_606957
  var valid_606958 = header.getOrDefault("X-Amz-Security-Token")
  valid_606958 = validateParameter(valid_606958, JString, required = false,
                                 default = nil)
  if valid_606958 != nil:
    section.add "X-Amz-Security-Token", valid_606958
  var valid_606959 = header.getOrDefault("X-Amz-Algorithm")
  valid_606959 = validateParameter(valid_606959, JString, required = false,
                                 default = nil)
  if valid_606959 != nil:
    section.add "X-Amz-Algorithm", valid_606959
  var valid_606960 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606960 = validateParameter(valid_606960, JString, required = false,
                                 default = nil)
  if valid_606960 != nil:
    section.add "X-Amz-SignedHeaders", valid_606960
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606961: Call_DescribeTemplatePermissions_606949; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes read and write permissions on a template.
  ## 
  let valid = call_606961.validator(path, query, header, formData, body)
  let scheme = call_606961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606961.url(scheme.get, call_606961.host, call_606961.base,
                         call_606961.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606961, url, valid)

proc call*(call_606962: Call_DescribeTemplatePermissions_606949;
          AwsAccountId: string; TemplateId: string): Recallable =
  ## describeTemplatePermissions
  ## Describes read and write permissions on a template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template that you're describing.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  var path_606963 = newJObject()
  add(path_606963, "AwsAccountId", newJString(AwsAccountId))
  add(path_606963, "TemplateId", newJString(TemplateId))
  result = call_606962.call(path_606963, nil, nil, nil, nil)

var describeTemplatePermissions* = Call_DescribeTemplatePermissions_606949(
    name: "describeTemplatePermissions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}/permissions",
    validator: validate_DescribeTemplatePermissions_606950, base: "/",
    url: url_DescribeTemplatePermissions_606951,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDashboardEmbedUrl_606981 = ref object of OpenApiRestCall_605589
proc url_GetDashboardEmbedUrl_606983(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DashboardId" in path, "`DashboardId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/dashboards/"),
               (kind: VariableSegment, value: "DashboardId"),
               (kind: ConstantSegment, value: "/embed-url#creds-type")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDashboardEmbedUrl_606982(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Generates a server-side embeddable URL and authorization code. For this process to work properly, first configure the dashboards and user permissions. For more information, see <a href="https://docs.aws.amazon.com/quicksight/latest/user/embedding-dashboards.html">Embedding Amazon QuickSight Dashboards</a> in the <i>Amazon QuickSight User Guide</i> or <a href="https://docs.aws.amazon.com/quicksight/latest/APIReference/qs-dev-embedded-dashboards.html">Embedding Amazon QuickSight Dashboards</a> in the <i>Amazon QuickSight API Reference</i>.</p> <p>Currently, you can use <code>GetDashboardEmbedURL</code> only from the server, not from the user’s browser.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that contains the dashboard that you're embedding.
  ##   DashboardId: JString (required)
  ##              : The ID for the dashboard, also added to the IAM policy.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_606984 = path.getOrDefault("AwsAccountId")
  valid_606984 = validateParameter(valid_606984, JString, required = true,
                                 default = nil)
  if valid_606984 != nil:
    section.add "AwsAccountId", valid_606984
  var valid_606985 = path.getOrDefault("DashboardId")
  valid_606985 = validateParameter(valid_606985, JString, required = true,
                                 default = nil)
  if valid_606985 != nil:
    section.add "DashboardId", valid_606985
  result.add "path", section
  ## parameters in `query` object:
  ##   reset-disabled: JBool
  ##                 : Remove the reset button on the embedded dashboard. The default is FALSE, which enables the reset button.
  ##   creds-type: JString (required)
  ##             : The authentication method that the user uses to sign in.
  ##   user-arn: JString
  ##           : <p>The Amazon QuickSight user's Amazon Resource Name (ARN), for use with <code>QUICKSIGHT</code> identity type. You can use this for any Amazon QuickSight users in your account (readers, authors, or admins) authenticated as one of the following:</p> <ul> <li> <p>Active Directory (AD) users or group members</p> </li> <li> <p>Invited nonfederated users</p> </li> <li> <p>IAM users and IAM role-based sessions authenticated through Federated Single Sign-On using SAML, OpenID Connect, or IAM federation.</p> </li> </ul>
  ##   session-lifetime: JInt
  ##                   : How many minutes the session is valid. The session lifetime must be 15-600 minutes.
  ##   undo-redo-disabled: JBool
  ##                     : Remove the undo/redo button on the embedded dashboard. The default is FALSE, which enables the undo/redo button.
  section = newJObject()
  var valid_606986 = query.getOrDefault("reset-disabled")
  valid_606986 = validateParameter(valid_606986, JBool, required = false, default = nil)
  if valid_606986 != nil:
    section.add "reset-disabled", valid_606986
  assert query != nil,
        "query argument is necessary due to required `creds-type` field"
  var valid_607000 = query.getOrDefault("creds-type")
  valid_607000 = validateParameter(valid_607000, JString, required = true,
                                 default = newJString("IAM"))
  if valid_607000 != nil:
    section.add "creds-type", valid_607000
  var valid_607001 = query.getOrDefault("user-arn")
  valid_607001 = validateParameter(valid_607001, JString, required = false,
                                 default = nil)
  if valid_607001 != nil:
    section.add "user-arn", valid_607001
  var valid_607002 = query.getOrDefault("session-lifetime")
  valid_607002 = validateParameter(valid_607002, JInt, required = false, default = nil)
  if valid_607002 != nil:
    section.add "session-lifetime", valid_607002
  var valid_607003 = query.getOrDefault("undo-redo-disabled")
  valid_607003 = validateParameter(valid_607003, JBool, required = false, default = nil)
  if valid_607003 != nil:
    section.add "undo-redo-disabled", valid_607003
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
  var valid_607004 = header.getOrDefault("X-Amz-Signature")
  valid_607004 = validateParameter(valid_607004, JString, required = false,
                                 default = nil)
  if valid_607004 != nil:
    section.add "X-Amz-Signature", valid_607004
  var valid_607005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607005 = validateParameter(valid_607005, JString, required = false,
                                 default = nil)
  if valid_607005 != nil:
    section.add "X-Amz-Content-Sha256", valid_607005
  var valid_607006 = header.getOrDefault("X-Amz-Date")
  valid_607006 = validateParameter(valid_607006, JString, required = false,
                                 default = nil)
  if valid_607006 != nil:
    section.add "X-Amz-Date", valid_607006
  var valid_607007 = header.getOrDefault("X-Amz-Credential")
  valid_607007 = validateParameter(valid_607007, JString, required = false,
                                 default = nil)
  if valid_607007 != nil:
    section.add "X-Amz-Credential", valid_607007
  var valid_607008 = header.getOrDefault("X-Amz-Security-Token")
  valid_607008 = validateParameter(valid_607008, JString, required = false,
                                 default = nil)
  if valid_607008 != nil:
    section.add "X-Amz-Security-Token", valid_607008
  var valid_607009 = header.getOrDefault("X-Amz-Algorithm")
  valid_607009 = validateParameter(valid_607009, JString, required = false,
                                 default = nil)
  if valid_607009 != nil:
    section.add "X-Amz-Algorithm", valid_607009
  var valid_607010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607010 = validateParameter(valid_607010, JString, required = false,
                                 default = nil)
  if valid_607010 != nil:
    section.add "X-Amz-SignedHeaders", valid_607010
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607011: Call_GetDashboardEmbedUrl_606981; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Generates a server-side embeddable URL and authorization code. For this process to work properly, first configure the dashboards and user permissions. For more information, see <a href="https://docs.aws.amazon.com/quicksight/latest/user/embedding-dashboards.html">Embedding Amazon QuickSight Dashboards</a> in the <i>Amazon QuickSight User Guide</i> or <a href="https://docs.aws.amazon.com/quicksight/latest/APIReference/qs-dev-embedded-dashboards.html">Embedding Amazon QuickSight Dashboards</a> in the <i>Amazon QuickSight API Reference</i>.</p> <p>Currently, you can use <code>GetDashboardEmbedURL</code> only from the server, not from the user’s browser.</p>
  ## 
  let valid = call_607011.validator(path, query, header, formData, body)
  let scheme = call_607011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607011.url(scheme.get, call_607011.host, call_607011.base,
                         call_607011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607011, url, valid)

proc call*(call_607012: Call_GetDashboardEmbedUrl_606981; AwsAccountId: string;
          DashboardId: string; resetDisabled: bool = false; credsType: string = "IAM";
          userArn: string = ""; sessionLifetime: int = 0; undoRedoDisabled: bool = false): Recallable =
  ## getDashboardEmbedUrl
  ## <p>Generates a server-side embeddable URL and authorization code. For this process to work properly, first configure the dashboards and user permissions. For more information, see <a href="https://docs.aws.amazon.com/quicksight/latest/user/embedding-dashboards.html">Embedding Amazon QuickSight Dashboards</a> in the <i>Amazon QuickSight User Guide</i> or <a href="https://docs.aws.amazon.com/quicksight/latest/APIReference/qs-dev-embedded-dashboards.html">Embedding Amazon QuickSight Dashboards</a> in the <i>Amazon QuickSight API Reference</i>.</p> <p>Currently, you can use <code>GetDashboardEmbedURL</code> only from the server, not from the user’s browser.</p>
  ##   resetDisabled: bool
  ##                : Remove the reset button on the embedded dashboard. The default is FALSE, which enables the reset button.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that contains the dashboard that you're embedding.
  ##   credsType: string (required)
  ##            : The authentication method that the user uses to sign in.
  ##   userArn: string
  ##          : <p>The Amazon QuickSight user's Amazon Resource Name (ARN), for use with <code>QUICKSIGHT</code> identity type. You can use this for any Amazon QuickSight users in your account (readers, authors, or admins) authenticated as one of the following:</p> <ul> <li> <p>Active Directory (AD) users or group members</p> </li> <li> <p>Invited nonfederated users</p> </li> <li> <p>IAM users and IAM role-based sessions authenticated through Federated Single Sign-On using SAML, OpenID Connect, or IAM federation.</p> </li> </ul>
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard, also added to the IAM policy.
  ##   sessionLifetime: int
  ##                  : How many minutes the session is valid. The session lifetime must be 15-600 minutes.
  ##   undoRedoDisabled: bool
  ##                   : Remove the undo/redo button on the embedded dashboard. The default is FALSE, which enables the undo/redo button.
  var path_607013 = newJObject()
  var query_607014 = newJObject()
  add(query_607014, "reset-disabled", newJBool(resetDisabled))
  add(path_607013, "AwsAccountId", newJString(AwsAccountId))
  add(query_607014, "creds-type", newJString(credsType))
  add(query_607014, "user-arn", newJString(userArn))
  add(path_607013, "DashboardId", newJString(DashboardId))
  add(query_607014, "session-lifetime", newJInt(sessionLifetime))
  add(query_607014, "undo-redo-disabled", newJBool(undoRedoDisabled))
  result = call_607012.call(path_607013, query_607014, nil, nil, nil)

var getDashboardEmbedUrl* = Call_GetDashboardEmbedUrl_606981(
    name: "getDashboardEmbedUrl", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/embed-url#creds-type",
    validator: validate_GetDashboardEmbedUrl_606982, base: "/",
    url: url_GetDashboardEmbedUrl_606983, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDashboardVersions_607015 = ref object of OpenApiRestCall_605589
proc url_ListDashboardVersions_607017(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DashboardId" in path, "`DashboardId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/dashboards/"),
               (kind: VariableSegment, value: "DashboardId"),
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

proc validate_ListDashboardVersions_607016(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all the versions of the dashboards in the QuickSight subscription.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the dashboard that you're listing versions for.
  ##   DashboardId: JString (required)
  ##              : The ID for the dashboard.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_607018 = path.getOrDefault("AwsAccountId")
  valid_607018 = validateParameter(valid_607018, JString, required = true,
                                 default = nil)
  if valid_607018 != nil:
    section.add "AwsAccountId", valid_607018
  var valid_607019 = path.getOrDefault("DashboardId")
  valid_607019 = validateParameter(valid_607019, JString, required = true,
                                 default = nil)
  if valid_607019 != nil:
    section.add "DashboardId", valid_607019
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_607020 = query.getOrDefault("MaxResults")
  valid_607020 = validateParameter(valid_607020, JString, required = false,
                                 default = nil)
  if valid_607020 != nil:
    section.add "MaxResults", valid_607020
  var valid_607021 = query.getOrDefault("NextToken")
  valid_607021 = validateParameter(valid_607021, JString, required = false,
                                 default = nil)
  if valid_607021 != nil:
    section.add "NextToken", valid_607021
  var valid_607022 = query.getOrDefault("max-results")
  valid_607022 = validateParameter(valid_607022, JInt, required = false, default = nil)
  if valid_607022 != nil:
    section.add "max-results", valid_607022
  var valid_607023 = query.getOrDefault("next-token")
  valid_607023 = validateParameter(valid_607023, JString, required = false,
                                 default = nil)
  if valid_607023 != nil:
    section.add "next-token", valid_607023
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
  var valid_607024 = header.getOrDefault("X-Amz-Signature")
  valid_607024 = validateParameter(valid_607024, JString, required = false,
                                 default = nil)
  if valid_607024 != nil:
    section.add "X-Amz-Signature", valid_607024
  var valid_607025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607025 = validateParameter(valid_607025, JString, required = false,
                                 default = nil)
  if valid_607025 != nil:
    section.add "X-Amz-Content-Sha256", valid_607025
  var valid_607026 = header.getOrDefault("X-Amz-Date")
  valid_607026 = validateParameter(valid_607026, JString, required = false,
                                 default = nil)
  if valid_607026 != nil:
    section.add "X-Amz-Date", valid_607026
  var valid_607027 = header.getOrDefault("X-Amz-Credential")
  valid_607027 = validateParameter(valid_607027, JString, required = false,
                                 default = nil)
  if valid_607027 != nil:
    section.add "X-Amz-Credential", valid_607027
  var valid_607028 = header.getOrDefault("X-Amz-Security-Token")
  valid_607028 = validateParameter(valid_607028, JString, required = false,
                                 default = nil)
  if valid_607028 != nil:
    section.add "X-Amz-Security-Token", valid_607028
  var valid_607029 = header.getOrDefault("X-Amz-Algorithm")
  valid_607029 = validateParameter(valid_607029, JString, required = false,
                                 default = nil)
  if valid_607029 != nil:
    section.add "X-Amz-Algorithm", valid_607029
  var valid_607030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607030 = validateParameter(valid_607030, JString, required = false,
                                 default = nil)
  if valid_607030 != nil:
    section.add "X-Amz-SignedHeaders", valid_607030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607031: Call_ListDashboardVersions_607015; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the versions of the dashboards in the QuickSight subscription.
  ## 
  let valid = call_607031.validator(path, query, header, formData, body)
  let scheme = call_607031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607031.url(scheme.get, call_607031.host, call_607031.base,
                         call_607031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607031, url, valid)

proc call*(call_607032: Call_ListDashboardVersions_607015; AwsAccountId: string;
          DashboardId: string; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listDashboardVersions
  ## Lists all the versions of the dashboards in the QuickSight subscription.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're listing versions for.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  var path_607033 = newJObject()
  var query_607034 = newJObject()
  add(path_607033, "AwsAccountId", newJString(AwsAccountId))
  add(query_607034, "MaxResults", newJString(MaxResults))
  add(query_607034, "NextToken", newJString(NextToken))
  add(query_607034, "max-results", newJInt(maxResults))
  add(path_607033, "DashboardId", newJString(DashboardId))
  add(query_607034, "next-token", newJString(nextToken))
  result = call_607032.call(path_607033, query_607034, nil, nil, nil)

var listDashboardVersions* = Call_ListDashboardVersions_607015(
    name: "listDashboardVersions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/versions",
    validator: validate_ListDashboardVersions_607016, base: "/",
    url: url_ListDashboardVersions_607017, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDashboards_607035 = ref object of OpenApiRestCall_605589
proc url_ListDashboards_607037(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/dashboards")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDashboards_607036(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists dashboards in an AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the dashboards that you're listing.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_607038 = path.getOrDefault("AwsAccountId")
  valid_607038 = validateParameter(valid_607038, JString, required = true,
                                 default = nil)
  if valid_607038 != nil:
    section.add "AwsAccountId", valid_607038
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_607039 = query.getOrDefault("MaxResults")
  valid_607039 = validateParameter(valid_607039, JString, required = false,
                                 default = nil)
  if valid_607039 != nil:
    section.add "MaxResults", valid_607039
  var valid_607040 = query.getOrDefault("NextToken")
  valid_607040 = validateParameter(valid_607040, JString, required = false,
                                 default = nil)
  if valid_607040 != nil:
    section.add "NextToken", valid_607040
  var valid_607041 = query.getOrDefault("max-results")
  valid_607041 = validateParameter(valid_607041, JInt, required = false, default = nil)
  if valid_607041 != nil:
    section.add "max-results", valid_607041
  var valid_607042 = query.getOrDefault("next-token")
  valid_607042 = validateParameter(valid_607042, JString, required = false,
                                 default = nil)
  if valid_607042 != nil:
    section.add "next-token", valid_607042
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
  var valid_607043 = header.getOrDefault("X-Amz-Signature")
  valid_607043 = validateParameter(valid_607043, JString, required = false,
                                 default = nil)
  if valid_607043 != nil:
    section.add "X-Amz-Signature", valid_607043
  var valid_607044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607044 = validateParameter(valid_607044, JString, required = false,
                                 default = nil)
  if valid_607044 != nil:
    section.add "X-Amz-Content-Sha256", valid_607044
  var valid_607045 = header.getOrDefault("X-Amz-Date")
  valid_607045 = validateParameter(valid_607045, JString, required = false,
                                 default = nil)
  if valid_607045 != nil:
    section.add "X-Amz-Date", valid_607045
  var valid_607046 = header.getOrDefault("X-Amz-Credential")
  valid_607046 = validateParameter(valid_607046, JString, required = false,
                                 default = nil)
  if valid_607046 != nil:
    section.add "X-Amz-Credential", valid_607046
  var valid_607047 = header.getOrDefault("X-Amz-Security-Token")
  valid_607047 = validateParameter(valid_607047, JString, required = false,
                                 default = nil)
  if valid_607047 != nil:
    section.add "X-Amz-Security-Token", valid_607047
  var valid_607048 = header.getOrDefault("X-Amz-Algorithm")
  valid_607048 = validateParameter(valid_607048, JString, required = false,
                                 default = nil)
  if valid_607048 != nil:
    section.add "X-Amz-Algorithm", valid_607048
  var valid_607049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607049 = validateParameter(valid_607049, JString, required = false,
                                 default = nil)
  if valid_607049 != nil:
    section.add "X-Amz-SignedHeaders", valid_607049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607050: Call_ListDashboards_607035; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists dashboards in an AWS account.
  ## 
  let valid = call_607050.validator(path, query, header, formData, body)
  let scheme = call_607050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607050.url(scheme.get, call_607050.host, call_607050.base,
                         call_607050.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607050, url, valid)

proc call*(call_607051: Call_ListDashboards_607035; AwsAccountId: string;
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listDashboards
  ## Lists dashboards in an AWS account.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboards that you're listing.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  var path_607052 = newJObject()
  var query_607053 = newJObject()
  add(path_607052, "AwsAccountId", newJString(AwsAccountId))
  add(query_607053, "MaxResults", newJString(MaxResults))
  add(query_607053, "NextToken", newJString(NextToken))
  add(query_607053, "max-results", newJInt(maxResults))
  add(query_607053, "next-token", newJString(nextToken))
  result = call_607051.call(path_607052, query_607053, nil, nil, nil)

var listDashboards* = Call_ListDashboards_607035(name: "listDashboards",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards",
    validator: validate_ListDashboards_607036, base: "/", url: url_ListDashboards_607037,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupMemberships_607054 = ref object of OpenApiRestCall_605589
proc url_ListGroupMemberships_607056(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "GroupName" in path, "`GroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/groups/"),
               (kind: VariableSegment, value: "GroupName"),
               (kind: ConstantSegment, value: "/members")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListGroupMemberships_607055(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists member users in a group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the group that you want to see a membership list of.
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_607057 = path.getOrDefault("GroupName")
  valid_607057 = validateParameter(valid_607057, JString, required = true,
                                 default = nil)
  if valid_607057 != nil:
    section.add "GroupName", valid_607057
  var valid_607058 = path.getOrDefault("AwsAccountId")
  valid_607058 = validateParameter(valid_607058, JString, required = true,
                                 default = nil)
  if valid_607058 != nil:
    section.add "AwsAccountId", valid_607058
  var valid_607059 = path.getOrDefault("Namespace")
  valid_607059 = validateParameter(valid_607059, JString, required = true,
                                 default = nil)
  if valid_607059 != nil:
    section.add "Namespace", valid_607059
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return from this request.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_607060 = query.getOrDefault("max-results")
  valid_607060 = validateParameter(valid_607060, JInt, required = false, default = nil)
  if valid_607060 != nil:
    section.add "max-results", valid_607060
  var valid_607061 = query.getOrDefault("next-token")
  valid_607061 = validateParameter(valid_607061, JString, required = false,
                                 default = nil)
  if valid_607061 != nil:
    section.add "next-token", valid_607061
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
  var valid_607062 = header.getOrDefault("X-Amz-Signature")
  valid_607062 = validateParameter(valid_607062, JString, required = false,
                                 default = nil)
  if valid_607062 != nil:
    section.add "X-Amz-Signature", valid_607062
  var valid_607063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607063 = validateParameter(valid_607063, JString, required = false,
                                 default = nil)
  if valid_607063 != nil:
    section.add "X-Amz-Content-Sha256", valid_607063
  var valid_607064 = header.getOrDefault("X-Amz-Date")
  valid_607064 = validateParameter(valid_607064, JString, required = false,
                                 default = nil)
  if valid_607064 != nil:
    section.add "X-Amz-Date", valid_607064
  var valid_607065 = header.getOrDefault("X-Amz-Credential")
  valid_607065 = validateParameter(valid_607065, JString, required = false,
                                 default = nil)
  if valid_607065 != nil:
    section.add "X-Amz-Credential", valid_607065
  var valid_607066 = header.getOrDefault("X-Amz-Security-Token")
  valid_607066 = validateParameter(valid_607066, JString, required = false,
                                 default = nil)
  if valid_607066 != nil:
    section.add "X-Amz-Security-Token", valid_607066
  var valid_607067 = header.getOrDefault("X-Amz-Algorithm")
  valid_607067 = validateParameter(valid_607067, JString, required = false,
                                 default = nil)
  if valid_607067 != nil:
    section.add "X-Amz-Algorithm", valid_607067
  var valid_607068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607068 = validateParameter(valid_607068, JString, required = false,
                                 default = nil)
  if valid_607068 != nil:
    section.add "X-Amz-SignedHeaders", valid_607068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607069: Call_ListGroupMemberships_607054; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists member users in a group.
  ## 
  let valid = call_607069.validator(path, query, header, formData, body)
  let scheme = call_607069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607069.url(scheme.get, call_607069.host, call_607069.base,
                         call_607069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607069, url, valid)

proc call*(call_607070: Call_ListGroupMemberships_607054; GroupName: string;
          AwsAccountId: string; Namespace: string; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listGroupMemberships
  ## Lists member users in a group.
  ##   GroupName: string (required)
  ##            : The name of the group that you want to see a membership list of.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   maxResults: int
  ##             : The maximum number of results to return from this request.
  ##   nextToken: string
  ##            : A pagination token that can be used in a subsequent request.
  var path_607071 = newJObject()
  var query_607072 = newJObject()
  add(path_607071, "GroupName", newJString(GroupName))
  add(path_607071, "AwsAccountId", newJString(AwsAccountId))
  add(path_607071, "Namespace", newJString(Namespace))
  add(query_607072, "max-results", newJInt(maxResults))
  add(query_607072, "next-token", newJString(nextToken))
  result = call_607070.call(path_607071, query_607072, nil, nil, nil)

var listGroupMemberships* = Call_ListGroupMemberships_607054(
    name: "listGroupMemberships", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members",
    validator: validate_ListGroupMemberships_607055, base: "/",
    url: url_ListGroupMemberships_607056, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIAMPolicyAssignments_607073 = ref object of OpenApiRestCall_605589
proc url_ListIAMPolicyAssignments_607075(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/iam-policy-assignments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListIAMPolicyAssignments_607074(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists IAM policy assignments in the current Amazon QuickSight account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains these IAM policy assignments.
  ##   Namespace: JString (required)
  ##            : The namespace for the assignments.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_607076 = path.getOrDefault("AwsAccountId")
  valid_607076 = validateParameter(valid_607076, JString, required = true,
                                 default = nil)
  if valid_607076 != nil:
    section.add "AwsAccountId", valid_607076
  var valid_607077 = path.getOrDefault("Namespace")
  valid_607077 = validateParameter(valid_607077, JString, required = true,
                                 default = nil)
  if valid_607077 != nil:
    section.add "Namespace", valid_607077
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_607078 = query.getOrDefault("max-results")
  valid_607078 = validateParameter(valid_607078, JInt, required = false, default = nil)
  if valid_607078 != nil:
    section.add "max-results", valid_607078
  var valid_607079 = query.getOrDefault("next-token")
  valid_607079 = validateParameter(valid_607079, JString, required = false,
                                 default = nil)
  if valid_607079 != nil:
    section.add "next-token", valid_607079
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
  var valid_607080 = header.getOrDefault("X-Amz-Signature")
  valid_607080 = validateParameter(valid_607080, JString, required = false,
                                 default = nil)
  if valid_607080 != nil:
    section.add "X-Amz-Signature", valid_607080
  var valid_607081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607081 = validateParameter(valid_607081, JString, required = false,
                                 default = nil)
  if valid_607081 != nil:
    section.add "X-Amz-Content-Sha256", valid_607081
  var valid_607082 = header.getOrDefault("X-Amz-Date")
  valid_607082 = validateParameter(valid_607082, JString, required = false,
                                 default = nil)
  if valid_607082 != nil:
    section.add "X-Amz-Date", valid_607082
  var valid_607083 = header.getOrDefault("X-Amz-Credential")
  valid_607083 = validateParameter(valid_607083, JString, required = false,
                                 default = nil)
  if valid_607083 != nil:
    section.add "X-Amz-Credential", valid_607083
  var valid_607084 = header.getOrDefault("X-Amz-Security-Token")
  valid_607084 = validateParameter(valid_607084, JString, required = false,
                                 default = nil)
  if valid_607084 != nil:
    section.add "X-Amz-Security-Token", valid_607084
  var valid_607085 = header.getOrDefault("X-Amz-Algorithm")
  valid_607085 = validateParameter(valid_607085, JString, required = false,
                                 default = nil)
  if valid_607085 != nil:
    section.add "X-Amz-Algorithm", valid_607085
  var valid_607086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607086 = validateParameter(valid_607086, JString, required = false,
                                 default = nil)
  if valid_607086 != nil:
    section.add "X-Amz-SignedHeaders", valid_607086
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607088: Call_ListIAMPolicyAssignments_607073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists IAM policy assignments in the current Amazon QuickSight account.
  ## 
  let valid = call_607088.validator(path, query, header, formData, body)
  let scheme = call_607088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607088.url(scheme.get, call_607088.host, call_607088.base,
                         call_607088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607088, url, valid)

proc call*(call_607089: Call_ListIAMPolicyAssignments_607073; AwsAccountId: string;
          Namespace: string; body: JsonNode; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listIAMPolicyAssignments
  ## Lists IAM policy assignments in the current Amazon QuickSight account.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains these IAM policy assignments.
  ##   Namespace: string (required)
  ##            : The namespace for the assignments.
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   body: JObject (required)
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  var path_607090 = newJObject()
  var query_607091 = newJObject()
  var body_607092 = newJObject()
  add(path_607090, "AwsAccountId", newJString(AwsAccountId))
  add(path_607090, "Namespace", newJString(Namespace))
  add(query_607091, "max-results", newJInt(maxResults))
  if body != nil:
    body_607092 = body
  add(query_607091, "next-token", newJString(nextToken))
  result = call_607089.call(path_607090, query_607091, nil, nil, body_607092)

var listIAMPolicyAssignments* = Call_ListIAMPolicyAssignments_607073(
    name: "listIAMPolicyAssignments", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments",
    validator: validate_ListIAMPolicyAssignments_607074, base: "/",
    url: url_ListIAMPolicyAssignments_607075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIAMPolicyAssignmentsForUser_607093 = ref object of OpenApiRestCall_605589
proc url_ListIAMPolicyAssignmentsForUser_607095(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "UserName" in path, "`UserName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "UserName"),
               (kind: ConstantSegment, value: "/iam-policy-assignments")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListIAMPolicyAssignmentsForUser_607094(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all the IAM policy assignments, including the Amazon Resource Names (ARNs) for the IAM policies assigned to the specified user and group or groups that the user belongs to.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the assignments.
  ##   Namespace: JString (required)
  ##            : The namespace of the assignment.
  ##   UserName: JString (required)
  ##           : The name of the user.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_607096 = path.getOrDefault("AwsAccountId")
  valid_607096 = validateParameter(valid_607096, JString, required = true,
                                 default = nil)
  if valid_607096 != nil:
    section.add "AwsAccountId", valid_607096
  var valid_607097 = path.getOrDefault("Namespace")
  valid_607097 = validateParameter(valid_607097, JString, required = true,
                                 default = nil)
  if valid_607097 != nil:
    section.add "Namespace", valid_607097
  var valid_607098 = path.getOrDefault("UserName")
  valid_607098 = validateParameter(valid_607098, JString, required = true,
                                 default = nil)
  if valid_607098 != nil:
    section.add "UserName", valid_607098
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_607099 = query.getOrDefault("max-results")
  valid_607099 = validateParameter(valid_607099, JInt, required = false, default = nil)
  if valid_607099 != nil:
    section.add "max-results", valid_607099
  var valid_607100 = query.getOrDefault("next-token")
  valid_607100 = validateParameter(valid_607100, JString, required = false,
                                 default = nil)
  if valid_607100 != nil:
    section.add "next-token", valid_607100
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
  var valid_607101 = header.getOrDefault("X-Amz-Signature")
  valid_607101 = validateParameter(valid_607101, JString, required = false,
                                 default = nil)
  if valid_607101 != nil:
    section.add "X-Amz-Signature", valid_607101
  var valid_607102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607102 = validateParameter(valid_607102, JString, required = false,
                                 default = nil)
  if valid_607102 != nil:
    section.add "X-Amz-Content-Sha256", valid_607102
  var valid_607103 = header.getOrDefault("X-Amz-Date")
  valid_607103 = validateParameter(valid_607103, JString, required = false,
                                 default = nil)
  if valid_607103 != nil:
    section.add "X-Amz-Date", valid_607103
  var valid_607104 = header.getOrDefault("X-Amz-Credential")
  valid_607104 = validateParameter(valid_607104, JString, required = false,
                                 default = nil)
  if valid_607104 != nil:
    section.add "X-Amz-Credential", valid_607104
  var valid_607105 = header.getOrDefault("X-Amz-Security-Token")
  valid_607105 = validateParameter(valid_607105, JString, required = false,
                                 default = nil)
  if valid_607105 != nil:
    section.add "X-Amz-Security-Token", valid_607105
  var valid_607106 = header.getOrDefault("X-Amz-Algorithm")
  valid_607106 = validateParameter(valid_607106, JString, required = false,
                                 default = nil)
  if valid_607106 != nil:
    section.add "X-Amz-Algorithm", valid_607106
  var valid_607107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607107 = validateParameter(valid_607107, JString, required = false,
                                 default = nil)
  if valid_607107 != nil:
    section.add "X-Amz-SignedHeaders", valid_607107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607108: Call_ListIAMPolicyAssignmentsForUser_607093;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists all the IAM policy assignments, including the Amazon Resource Names (ARNs) for the IAM policies assigned to the specified user and group or groups that the user belongs to.
  ## 
  let valid = call_607108.validator(path, query, header, formData, body)
  let scheme = call_607108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607108.url(scheme.get, call_607108.host, call_607108.base,
                         call_607108.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607108, url, valid)

proc call*(call_607109: Call_ListIAMPolicyAssignmentsForUser_607093;
          AwsAccountId: string; Namespace: string; UserName: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listIAMPolicyAssignmentsForUser
  ## Lists all the IAM policy assignments, including the Amazon Resource Names (ARNs) for the IAM policies assigned to the specified user and group or groups that the user belongs to.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the assignments.
  ##   Namespace: string (required)
  ##            : The namespace of the assignment.
  ##   UserName: string (required)
  ##           : The name of the user.
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  var path_607110 = newJObject()
  var query_607111 = newJObject()
  add(path_607110, "AwsAccountId", newJString(AwsAccountId))
  add(path_607110, "Namespace", newJString(Namespace))
  add(path_607110, "UserName", newJString(UserName))
  add(query_607111, "max-results", newJInt(maxResults))
  add(query_607111, "next-token", newJString(nextToken))
  result = call_607109.call(path_607110, query_607111, nil, nil, nil)

var listIAMPolicyAssignmentsForUser* = Call_ListIAMPolicyAssignmentsForUser_607093(
    name: "listIAMPolicyAssignmentsForUser", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}/iam-policy-assignments",
    validator: validate_ListIAMPolicyAssignmentsForUser_607094, base: "/",
    url: url_ListIAMPolicyAssignmentsForUser_607095,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIngestions_607112 = ref object of OpenApiRestCall_605589
proc url_ListIngestions_607114(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DataSetId" in path, "`DataSetId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/data-sets/"),
               (kind: VariableSegment, value: "DataSetId"),
               (kind: ConstantSegment, value: "/ingestions")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListIngestions_607113(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists the history of SPICE ingestions for a dataset.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  ##   DataSetId: JString (required)
  ##            : The ID of the dataset used in the ingestion.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_607115 = path.getOrDefault("AwsAccountId")
  valid_607115 = validateParameter(valid_607115, JString, required = true,
                                 default = nil)
  if valid_607115 != nil:
    section.add "AwsAccountId", valid_607115
  var valid_607116 = path.getOrDefault("DataSetId")
  valid_607116 = validateParameter(valid_607116, JString, required = true,
                                 default = nil)
  if valid_607116 != nil:
    section.add "DataSetId", valid_607116
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_607117 = query.getOrDefault("MaxResults")
  valid_607117 = validateParameter(valid_607117, JString, required = false,
                                 default = nil)
  if valid_607117 != nil:
    section.add "MaxResults", valid_607117
  var valid_607118 = query.getOrDefault("NextToken")
  valid_607118 = validateParameter(valid_607118, JString, required = false,
                                 default = nil)
  if valid_607118 != nil:
    section.add "NextToken", valid_607118
  var valid_607119 = query.getOrDefault("max-results")
  valid_607119 = validateParameter(valid_607119, JInt, required = false, default = nil)
  if valid_607119 != nil:
    section.add "max-results", valid_607119
  var valid_607120 = query.getOrDefault("next-token")
  valid_607120 = validateParameter(valid_607120, JString, required = false,
                                 default = nil)
  if valid_607120 != nil:
    section.add "next-token", valid_607120
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
  var valid_607121 = header.getOrDefault("X-Amz-Signature")
  valid_607121 = validateParameter(valid_607121, JString, required = false,
                                 default = nil)
  if valid_607121 != nil:
    section.add "X-Amz-Signature", valid_607121
  var valid_607122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607122 = validateParameter(valid_607122, JString, required = false,
                                 default = nil)
  if valid_607122 != nil:
    section.add "X-Amz-Content-Sha256", valid_607122
  var valid_607123 = header.getOrDefault("X-Amz-Date")
  valid_607123 = validateParameter(valid_607123, JString, required = false,
                                 default = nil)
  if valid_607123 != nil:
    section.add "X-Amz-Date", valid_607123
  var valid_607124 = header.getOrDefault("X-Amz-Credential")
  valid_607124 = validateParameter(valid_607124, JString, required = false,
                                 default = nil)
  if valid_607124 != nil:
    section.add "X-Amz-Credential", valid_607124
  var valid_607125 = header.getOrDefault("X-Amz-Security-Token")
  valid_607125 = validateParameter(valid_607125, JString, required = false,
                                 default = nil)
  if valid_607125 != nil:
    section.add "X-Amz-Security-Token", valid_607125
  var valid_607126 = header.getOrDefault("X-Amz-Algorithm")
  valid_607126 = validateParameter(valid_607126, JString, required = false,
                                 default = nil)
  if valid_607126 != nil:
    section.add "X-Amz-Algorithm", valid_607126
  var valid_607127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607127 = validateParameter(valid_607127, JString, required = false,
                                 default = nil)
  if valid_607127 != nil:
    section.add "X-Amz-SignedHeaders", valid_607127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607128: Call_ListIngestions_607112; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the history of SPICE ingestions for a dataset.
  ## 
  let valid = call_607128.validator(path, query, header, formData, body)
  let scheme = call_607128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607128.url(scheme.get, call_607128.host, call_607128.base,
                         call_607128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607128, url, valid)

proc call*(call_607129: Call_ListIngestions_607112; AwsAccountId: string;
          DataSetId: string; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listIngestions
  ## Lists the history of SPICE ingestions for a dataset.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   DataSetId: string (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  var path_607130 = newJObject()
  var query_607131 = newJObject()
  add(path_607130, "AwsAccountId", newJString(AwsAccountId))
  add(query_607131, "MaxResults", newJString(MaxResults))
  add(query_607131, "NextToken", newJString(NextToken))
  add(path_607130, "DataSetId", newJString(DataSetId))
  add(query_607131, "max-results", newJInt(maxResults))
  add(query_607131, "next-token", newJString(nextToken))
  result = call_607129.call(path_607130, query_607131, nil, nil, nil)

var listIngestions* = Call_ListIngestions_607112(name: "listIngestions",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions",
    validator: validate_ListIngestions_607113, base: "/", url: url_ListIngestions_607114,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_607146 = ref object of OpenApiRestCall_605589
proc url_TagResource_607148(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceArn" in path, "`ResourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "ResourceArn"),
               (kind: ConstantSegment, value: "/tags")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_607147(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Assigns one or more tags (key-value pairs) to the specified QuickSight resource. </p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. You can use the <code>TagResource</code> operation with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource. QuickSight supports tagging on data set, data source, dashboard, and template. </p> <p>Tagging for QuickSight works in a similar way to tagging for other AWS services, except for the following:</p> <ul> <li> <p>You can't use tags to track AWS costs for QuickSight. This restriction is because QuickSight costs are based on users and SPICE capacity, which aren't taggable resources.</p> </li> <li> <p>QuickSight doesn't currently support the Tag Editor for AWS Resource Groups.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to tag.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceArn` field"
  var valid_607149 = path.getOrDefault("ResourceArn")
  valid_607149 = validateParameter(valid_607149, JString, required = true,
                                 default = nil)
  if valid_607149 != nil:
    section.add "ResourceArn", valid_607149
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
  var valid_607150 = header.getOrDefault("X-Amz-Signature")
  valid_607150 = validateParameter(valid_607150, JString, required = false,
                                 default = nil)
  if valid_607150 != nil:
    section.add "X-Amz-Signature", valid_607150
  var valid_607151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607151 = validateParameter(valid_607151, JString, required = false,
                                 default = nil)
  if valid_607151 != nil:
    section.add "X-Amz-Content-Sha256", valid_607151
  var valid_607152 = header.getOrDefault("X-Amz-Date")
  valid_607152 = validateParameter(valid_607152, JString, required = false,
                                 default = nil)
  if valid_607152 != nil:
    section.add "X-Amz-Date", valid_607152
  var valid_607153 = header.getOrDefault("X-Amz-Credential")
  valid_607153 = validateParameter(valid_607153, JString, required = false,
                                 default = nil)
  if valid_607153 != nil:
    section.add "X-Amz-Credential", valid_607153
  var valid_607154 = header.getOrDefault("X-Amz-Security-Token")
  valid_607154 = validateParameter(valid_607154, JString, required = false,
                                 default = nil)
  if valid_607154 != nil:
    section.add "X-Amz-Security-Token", valid_607154
  var valid_607155 = header.getOrDefault("X-Amz-Algorithm")
  valid_607155 = validateParameter(valid_607155, JString, required = false,
                                 default = nil)
  if valid_607155 != nil:
    section.add "X-Amz-Algorithm", valid_607155
  var valid_607156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607156 = validateParameter(valid_607156, JString, required = false,
                                 default = nil)
  if valid_607156 != nil:
    section.add "X-Amz-SignedHeaders", valid_607156
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607158: Call_TagResource_607146; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns one or more tags (key-value pairs) to the specified QuickSight resource. </p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. You can use the <code>TagResource</code> operation with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource. QuickSight supports tagging on data set, data source, dashboard, and template. </p> <p>Tagging for QuickSight works in a similar way to tagging for other AWS services, except for the following:</p> <ul> <li> <p>You can't use tags to track AWS costs for QuickSight. This restriction is because QuickSight costs are based on users and SPICE capacity, which aren't taggable resources.</p> </li> <li> <p>QuickSight doesn't currently support the Tag Editor for AWS Resource Groups.</p> </li> </ul>
  ## 
  let valid = call_607158.validator(path, query, header, formData, body)
  let scheme = call_607158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607158.url(scheme.get, call_607158.host, call_607158.base,
                         call_607158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607158, url, valid)

proc call*(call_607159: Call_TagResource_607146; ResourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Assigns one or more tags (key-value pairs) to the specified QuickSight resource. </p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. You can use the <code>TagResource</code> operation with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource. QuickSight supports tagging on data set, data source, dashboard, and template. </p> <p>Tagging for QuickSight works in a similar way to tagging for other AWS services, except for the following:</p> <ul> <li> <p>You can't use tags to track AWS costs for QuickSight. This restriction is because QuickSight costs are based on users and SPICE capacity, which aren't taggable resources.</p> </li> <li> <p>QuickSight doesn't currently support the Tag Editor for AWS Resource Groups.</p> </li> </ul>
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to tag.
  ##   body: JObject (required)
  var path_607160 = newJObject()
  var body_607161 = newJObject()
  add(path_607160, "ResourceArn", newJString(ResourceArn))
  if body != nil:
    body_607161 = body
  result = call_607159.call(path_607160, nil, nil, nil, body_607161)

var tagResource* = Call_TagResource_607146(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "quicksight.amazonaws.com",
                                        route: "/resources/{ResourceArn}/tags",
                                        validator: validate_TagResource_607147,
                                        base: "/", url: url_TagResource_607148,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_607132 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_607134(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceArn" in path, "`ResourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "ResourceArn"),
               (kind: ConstantSegment, value: "/tags")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_607133(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the tags assigned to a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want a list of tags for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceArn` field"
  var valid_607135 = path.getOrDefault("ResourceArn")
  valid_607135 = validateParameter(valid_607135, JString, required = true,
                                 default = nil)
  if valid_607135 != nil:
    section.add "ResourceArn", valid_607135
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
  var valid_607136 = header.getOrDefault("X-Amz-Signature")
  valid_607136 = validateParameter(valid_607136, JString, required = false,
                                 default = nil)
  if valid_607136 != nil:
    section.add "X-Amz-Signature", valid_607136
  var valid_607137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607137 = validateParameter(valid_607137, JString, required = false,
                                 default = nil)
  if valid_607137 != nil:
    section.add "X-Amz-Content-Sha256", valid_607137
  var valid_607138 = header.getOrDefault("X-Amz-Date")
  valid_607138 = validateParameter(valid_607138, JString, required = false,
                                 default = nil)
  if valid_607138 != nil:
    section.add "X-Amz-Date", valid_607138
  var valid_607139 = header.getOrDefault("X-Amz-Credential")
  valid_607139 = validateParameter(valid_607139, JString, required = false,
                                 default = nil)
  if valid_607139 != nil:
    section.add "X-Amz-Credential", valid_607139
  var valid_607140 = header.getOrDefault("X-Amz-Security-Token")
  valid_607140 = validateParameter(valid_607140, JString, required = false,
                                 default = nil)
  if valid_607140 != nil:
    section.add "X-Amz-Security-Token", valid_607140
  var valid_607141 = header.getOrDefault("X-Amz-Algorithm")
  valid_607141 = validateParameter(valid_607141, JString, required = false,
                                 default = nil)
  if valid_607141 != nil:
    section.add "X-Amz-Algorithm", valid_607141
  var valid_607142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607142 = validateParameter(valid_607142, JString, required = false,
                                 default = nil)
  if valid_607142 != nil:
    section.add "X-Amz-SignedHeaders", valid_607142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607143: Call_ListTagsForResource_607132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags assigned to a resource.
  ## 
  let valid = call_607143.validator(path, query, header, formData, body)
  let scheme = call_607143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607143.url(scheme.get, call_607143.host, call_607143.base,
                         call_607143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607143, url, valid)

proc call*(call_607144: Call_ListTagsForResource_607132; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags assigned to a resource.
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want a list of tags for.
  var path_607145 = newJObject()
  add(path_607145, "ResourceArn", newJString(ResourceArn))
  result = call_607144.call(path_607145, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_607132(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/resources/{ResourceArn}/tags",
    validator: validate_ListTagsForResource_607133, base: "/",
    url: url_ListTagsForResource_607134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplateAliases_607162 = ref object of OpenApiRestCall_605589
proc url_ListTemplateAliases_607164(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "TemplateId" in path, "`TemplateId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/templates/"),
               (kind: VariableSegment, value: "TemplateId"),
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

proc validate_ListTemplateAliases_607163(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists all the aliases of a template.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the template aliases that you're listing.
  ##   TemplateId: JString (required)
  ##             : The ID for the template.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_607165 = path.getOrDefault("AwsAccountId")
  valid_607165 = validateParameter(valid_607165, JString, required = true,
                                 default = nil)
  if valid_607165 != nil:
    section.add "AwsAccountId", valid_607165
  var valid_607166 = path.getOrDefault("TemplateId")
  valid_607166 = validateParameter(valid_607166, JString, required = true,
                                 default = nil)
  if valid_607166 != nil:
    section.add "TemplateId", valid_607166
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-result: JInt
  ##             : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_607167 = query.getOrDefault("MaxResults")
  valid_607167 = validateParameter(valid_607167, JString, required = false,
                                 default = nil)
  if valid_607167 != nil:
    section.add "MaxResults", valid_607167
  var valid_607168 = query.getOrDefault("NextToken")
  valid_607168 = validateParameter(valid_607168, JString, required = false,
                                 default = nil)
  if valid_607168 != nil:
    section.add "NextToken", valid_607168
  var valid_607169 = query.getOrDefault("max-result")
  valid_607169 = validateParameter(valid_607169, JInt, required = false, default = nil)
  if valid_607169 != nil:
    section.add "max-result", valid_607169
  var valid_607170 = query.getOrDefault("next-token")
  valid_607170 = validateParameter(valid_607170, JString, required = false,
                                 default = nil)
  if valid_607170 != nil:
    section.add "next-token", valid_607170
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
  var valid_607171 = header.getOrDefault("X-Amz-Signature")
  valid_607171 = validateParameter(valid_607171, JString, required = false,
                                 default = nil)
  if valid_607171 != nil:
    section.add "X-Amz-Signature", valid_607171
  var valid_607172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607172 = validateParameter(valid_607172, JString, required = false,
                                 default = nil)
  if valid_607172 != nil:
    section.add "X-Amz-Content-Sha256", valid_607172
  var valid_607173 = header.getOrDefault("X-Amz-Date")
  valid_607173 = validateParameter(valid_607173, JString, required = false,
                                 default = nil)
  if valid_607173 != nil:
    section.add "X-Amz-Date", valid_607173
  var valid_607174 = header.getOrDefault("X-Amz-Credential")
  valid_607174 = validateParameter(valid_607174, JString, required = false,
                                 default = nil)
  if valid_607174 != nil:
    section.add "X-Amz-Credential", valid_607174
  var valid_607175 = header.getOrDefault("X-Amz-Security-Token")
  valid_607175 = validateParameter(valid_607175, JString, required = false,
                                 default = nil)
  if valid_607175 != nil:
    section.add "X-Amz-Security-Token", valid_607175
  var valid_607176 = header.getOrDefault("X-Amz-Algorithm")
  valid_607176 = validateParameter(valid_607176, JString, required = false,
                                 default = nil)
  if valid_607176 != nil:
    section.add "X-Amz-Algorithm", valid_607176
  var valid_607177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607177 = validateParameter(valid_607177, JString, required = false,
                                 default = nil)
  if valid_607177 != nil:
    section.add "X-Amz-SignedHeaders", valid_607177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607178: Call_ListTemplateAliases_607162; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the aliases of a template.
  ## 
  let valid = call_607178.validator(path, query, header, formData, body)
  let scheme = call_607178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607178.url(scheme.get, call_607178.host, call_607178.base,
                         call_607178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607178, url, valid)

proc call*(call_607179: Call_ListTemplateAliases_607162; AwsAccountId: string;
          TemplateId: string; MaxResults: string = ""; NextToken: string = "";
          maxResult: int = 0; nextToken: string = ""): Recallable =
  ## listTemplateAliases
  ## Lists all the aliases of a template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template aliases that you're listing.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResult: int
  ##            : The maximum number of results to be returned per request.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  var path_607180 = newJObject()
  var query_607181 = newJObject()
  add(path_607180, "AwsAccountId", newJString(AwsAccountId))
  add(query_607181, "MaxResults", newJString(MaxResults))
  add(query_607181, "NextToken", newJString(NextToken))
  add(query_607181, "max-result", newJInt(maxResult))
  add(path_607180, "TemplateId", newJString(TemplateId))
  add(query_607181, "next-token", newJString(nextToken))
  result = call_607179.call(path_607180, query_607181, nil, nil, nil)

var listTemplateAliases* = Call_ListTemplateAliases_607162(
    name: "listTemplateAliases", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases",
    validator: validate_ListTemplateAliases_607163, base: "/",
    url: url_ListTemplateAliases_607164, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplateVersions_607182 = ref object of OpenApiRestCall_605589
proc url_ListTemplateVersions_607184(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "TemplateId" in path, "`TemplateId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/templates/"),
               (kind: VariableSegment, value: "TemplateId"),
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

proc validate_ListTemplateVersions_607183(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all the versions of the templates in the current Amazon QuickSight account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the templates that you're listing.
  ##   TemplateId: JString (required)
  ##             : The ID for the template.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_607185 = path.getOrDefault("AwsAccountId")
  valid_607185 = validateParameter(valid_607185, JString, required = true,
                                 default = nil)
  if valid_607185 != nil:
    section.add "AwsAccountId", valid_607185
  var valid_607186 = path.getOrDefault("TemplateId")
  valid_607186 = validateParameter(valid_607186, JString, required = true,
                                 default = nil)
  if valid_607186 != nil:
    section.add "TemplateId", valid_607186
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_607187 = query.getOrDefault("MaxResults")
  valid_607187 = validateParameter(valid_607187, JString, required = false,
                                 default = nil)
  if valid_607187 != nil:
    section.add "MaxResults", valid_607187
  var valid_607188 = query.getOrDefault("NextToken")
  valid_607188 = validateParameter(valid_607188, JString, required = false,
                                 default = nil)
  if valid_607188 != nil:
    section.add "NextToken", valid_607188
  var valid_607189 = query.getOrDefault("max-results")
  valid_607189 = validateParameter(valid_607189, JInt, required = false, default = nil)
  if valid_607189 != nil:
    section.add "max-results", valid_607189
  var valid_607190 = query.getOrDefault("next-token")
  valid_607190 = validateParameter(valid_607190, JString, required = false,
                                 default = nil)
  if valid_607190 != nil:
    section.add "next-token", valid_607190
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
  var valid_607191 = header.getOrDefault("X-Amz-Signature")
  valid_607191 = validateParameter(valid_607191, JString, required = false,
                                 default = nil)
  if valid_607191 != nil:
    section.add "X-Amz-Signature", valid_607191
  var valid_607192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607192 = validateParameter(valid_607192, JString, required = false,
                                 default = nil)
  if valid_607192 != nil:
    section.add "X-Amz-Content-Sha256", valid_607192
  var valid_607193 = header.getOrDefault("X-Amz-Date")
  valid_607193 = validateParameter(valid_607193, JString, required = false,
                                 default = nil)
  if valid_607193 != nil:
    section.add "X-Amz-Date", valid_607193
  var valid_607194 = header.getOrDefault("X-Amz-Credential")
  valid_607194 = validateParameter(valid_607194, JString, required = false,
                                 default = nil)
  if valid_607194 != nil:
    section.add "X-Amz-Credential", valid_607194
  var valid_607195 = header.getOrDefault("X-Amz-Security-Token")
  valid_607195 = validateParameter(valid_607195, JString, required = false,
                                 default = nil)
  if valid_607195 != nil:
    section.add "X-Amz-Security-Token", valid_607195
  var valid_607196 = header.getOrDefault("X-Amz-Algorithm")
  valid_607196 = validateParameter(valid_607196, JString, required = false,
                                 default = nil)
  if valid_607196 != nil:
    section.add "X-Amz-Algorithm", valid_607196
  var valid_607197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607197 = validateParameter(valid_607197, JString, required = false,
                                 default = nil)
  if valid_607197 != nil:
    section.add "X-Amz-SignedHeaders", valid_607197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607198: Call_ListTemplateVersions_607182; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the versions of the templates in the current Amazon QuickSight account.
  ## 
  let valid = call_607198.validator(path, query, header, formData, body)
  let scheme = call_607198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607198.url(scheme.get, call_607198.host, call_607198.base,
                         call_607198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607198, url, valid)

proc call*(call_607199: Call_ListTemplateVersions_607182; AwsAccountId: string;
          TemplateId: string; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listTemplateVersions
  ## Lists all the versions of the templates in the current Amazon QuickSight account.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the templates that you're listing.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  var path_607200 = newJObject()
  var query_607201 = newJObject()
  add(path_607200, "AwsAccountId", newJString(AwsAccountId))
  add(query_607201, "MaxResults", newJString(MaxResults))
  add(query_607201, "NextToken", newJString(NextToken))
  add(query_607201, "max-results", newJInt(maxResults))
  add(path_607200, "TemplateId", newJString(TemplateId))
  add(query_607201, "next-token", newJString(nextToken))
  result = call_607199.call(path_607200, query_607201, nil, nil, nil)

var listTemplateVersions* = Call_ListTemplateVersions_607182(
    name: "listTemplateVersions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}/versions",
    validator: validate_ListTemplateVersions_607183, base: "/",
    url: url_ListTemplateVersions_607184, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplates_607202 = ref object of OpenApiRestCall_605589
proc url_ListTemplates_607204(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/templates")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTemplates_607203(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all the templates in the current Amazon QuickSight account.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the templates that you're listing.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_607205 = path.getOrDefault("AwsAccountId")
  valid_607205 = validateParameter(valid_607205, JString, required = true,
                                 default = nil)
  if valid_607205 != nil:
    section.add "AwsAccountId", valid_607205
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-result: JInt
  ##             : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_607206 = query.getOrDefault("MaxResults")
  valid_607206 = validateParameter(valid_607206, JString, required = false,
                                 default = nil)
  if valid_607206 != nil:
    section.add "MaxResults", valid_607206
  var valid_607207 = query.getOrDefault("NextToken")
  valid_607207 = validateParameter(valid_607207, JString, required = false,
                                 default = nil)
  if valid_607207 != nil:
    section.add "NextToken", valid_607207
  var valid_607208 = query.getOrDefault("max-result")
  valid_607208 = validateParameter(valid_607208, JInt, required = false, default = nil)
  if valid_607208 != nil:
    section.add "max-result", valid_607208
  var valid_607209 = query.getOrDefault("next-token")
  valid_607209 = validateParameter(valid_607209, JString, required = false,
                                 default = nil)
  if valid_607209 != nil:
    section.add "next-token", valid_607209
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
  var valid_607210 = header.getOrDefault("X-Amz-Signature")
  valid_607210 = validateParameter(valid_607210, JString, required = false,
                                 default = nil)
  if valid_607210 != nil:
    section.add "X-Amz-Signature", valid_607210
  var valid_607211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607211 = validateParameter(valid_607211, JString, required = false,
                                 default = nil)
  if valid_607211 != nil:
    section.add "X-Amz-Content-Sha256", valid_607211
  var valid_607212 = header.getOrDefault("X-Amz-Date")
  valid_607212 = validateParameter(valid_607212, JString, required = false,
                                 default = nil)
  if valid_607212 != nil:
    section.add "X-Amz-Date", valid_607212
  var valid_607213 = header.getOrDefault("X-Amz-Credential")
  valid_607213 = validateParameter(valid_607213, JString, required = false,
                                 default = nil)
  if valid_607213 != nil:
    section.add "X-Amz-Credential", valid_607213
  var valid_607214 = header.getOrDefault("X-Amz-Security-Token")
  valid_607214 = validateParameter(valid_607214, JString, required = false,
                                 default = nil)
  if valid_607214 != nil:
    section.add "X-Amz-Security-Token", valid_607214
  var valid_607215 = header.getOrDefault("X-Amz-Algorithm")
  valid_607215 = validateParameter(valid_607215, JString, required = false,
                                 default = nil)
  if valid_607215 != nil:
    section.add "X-Amz-Algorithm", valid_607215
  var valid_607216 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607216 = validateParameter(valid_607216, JString, required = false,
                                 default = nil)
  if valid_607216 != nil:
    section.add "X-Amz-SignedHeaders", valid_607216
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607217: Call_ListTemplates_607202; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the templates in the current Amazon QuickSight account.
  ## 
  let valid = call_607217.validator(path, query, header, formData, body)
  let scheme = call_607217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607217.url(scheme.get, call_607217.host, call_607217.base,
                         call_607217.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607217, url, valid)

proc call*(call_607218: Call_ListTemplates_607202; AwsAccountId: string;
          MaxResults: string = ""; NextToken: string = ""; maxResult: int = 0;
          nextToken: string = ""): Recallable =
  ## listTemplates
  ## Lists all the templates in the current Amazon QuickSight account.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the templates that you're listing.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResult: int
  ##            : The maximum number of results to be returned per request.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  var path_607219 = newJObject()
  var query_607220 = newJObject()
  add(path_607219, "AwsAccountId", newJString(AwsAccountId))
  add(query_607220, "MaxResults", newJString(MaxResults))
  add(query_607220, "NextToken", newJString(NextToken))
  add(query_607220, "max-result", newJInt(maxResult))
  add(query_607220, "next-token", newJString(nextToken))
  result = call_607218.call(path_607219, query_607220, nil, nil, nil)

var listTemplates* = Call_ListTemplates_607202(name: "listTemplates",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates",
    validator: validate_ListTemplates_607203, base: "/", url: url_ListTemplates_607204,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserGroups_607221 = ref object of OpenApiRestCall_605589
proc url_ListUserGroups_607223(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  assert "UserName" in path, "`UserName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/users/"),
               (kind: VariableSegment, value: "UserName"),
               (kind: ConstantSegment, value: "/groups")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListUserGroups_607222(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists the Amazon QuickSight groups that an Amazon QuickSight user is a member of.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: JString (required)
  ##           : The Amazon QuickSight user name that you want to list group memberships for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_607224 = path.getOrDefault("AwsAccountId")
  valid_607224 = validateParameter(valid_607224, JString, required = true,
                                 default = nil)
  if valid_607224 != nil:
    section.add "AwsAccountId", valid_607224
  var valid_607225 = path.getOrDefault("Namespace")
  valid_607225 = validateParameter(valid_607225, JString, required = true,
                                 default = nil)
  if valid_607225 != nil:
    section.add "Namespace", valid_607225
  var valid_607226 = path.getOrDefault("UserName")
  valid_607226 = validateParameter(valid_607226, JString, required = true,
                                 default = nil)
  if valid_607226 != nil:
    section.add "UserName", valid_607226
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return from this request.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_607227 = query.getOrDefault("max-results")
  valid_607227 = validateParameter(valid_607227, JInt, required = false, default = nil)
  if valid_607227 != nil:
    section.add "max-results", valid_607227
  var valid_607228 = query.getOrDefault("next-token")
  valid_607228 = validateParameter(valid_607228, JString, required = false,
                                 default = nil)
  if valid_607228 != nil:
    section.add "next-token", valid_607228
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
  var valid_607229 = header.getOrDefault("X-Amz-Signature")
  valid_607229 = validateParameter(valid_607229, JString, required = false,
                                 default = nil)
  if valid_607229 != nil:
    section.add "X-Amz-Signature", valid_607229
  var valid_607230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607230 = validateParameter(valid_607230, JString, required = false,
                                 default = nil)
  if valid_607230 != nil:
    section.add "X-Amz-Content-Sha256", valid_607230
  var valid_607231 = header.getOrDefault("X-Amz-Date")
  valid_607231 = validateParameter(valid_607231, JString, required = false,
                                 default = nil)
  if valid_607231 != nil:
    section.add "X-Amz-Date", valid_607231
  var valid_607232 = header.getOrDefault("X-Amz-Credential")
  valid_607232 = validateParameter(valid_607232, JString, required = false,
                                 default = nil)
  if valid_607232 != nil:
    section.add "X-Amz-Credential", valid_607232
  var valid_607233 = header.getOrDefault("X-Amz-Security-Token")
  valid_607233 = validateParameter(valid_607233, JString, required = false,
                                 default = nil)
  if valid_607233 != nil:
    section.add "X-Amz-Security-Token", valid_607233
  var valid_607234 = header.getOrDefault("X-Amz-Algorithm")
  valid_607234 = validateParameter(valid_607234, JString, required = false,
                                 default = nil)
  if valid_607234 != nil:
    section.add "X-Amz-Algorithm", valid_607234
  var valid_607235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607235 = validateParameter(valid_607235, JString, required = false,
                                 default = nil)
  if valid_607235 != nil:
    section.add "X-Amz-SignedHeaders", valid_607235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607236: Call_ListUserGroups_607221; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon QuickSight groups that an Amazon QuickSight user is a member of.
  ## 
  let valid = call_607236.validator(path, query, header, formData, body)
  let scheme = call_607236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607236.url(scheme.get, call_607236.host, call_607236.base,
                         call_607236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607236, url, valid)

proc call*(call_607237: Call_ListUserGroups_607221; AwsAccountId: string;
          Namespace: string; UserName: string; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listUserGroups
  ## Lists the Amazon QuickSight groups that an Amazon QuickSight user is a member of.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: string (required)
  ##           : The Amazon QuickSight user name that you want to list group memberships for.
  ##   maxResults: int
  ##             : The maximum number of results to return from this request.
  ##   nextToken: string
  ##            : A pagination token that can be used in a subsequent request.
  var path_607238 = newJObject()
  var query_607239 = newJObject()
  add(path_607238, "AwsAccountId", newJString(AwsAccountId))
  add(path_607238, "Namespace", newJString(Namespace))
  add(path_607238, "UserName", newJString(UserName))
  add(query_607239, "max-results", newJInt(maxResults))
  add(query_607239, "next-token", newJString(nextToken))
  result = call_607237.call(path_607238, query_607239, nil, nil, nil)

var listUserGroups* = Call_ListUserGroups_607221(name: "listUserGroups",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}/groups",
    validator: validate_ListUserGroups_607222, base: "/", url: url_ListUserGroups_607223,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterUser_607258 = ref object of OpenApiRestCall_605589
proc url_RegisterUser_607260(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/users")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RegisterUser_607259(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an Amazon QuickSight user, whose identity is associated with the AWS Identity and Access Management (IAM) identity or role specified in the request. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_607261 = path.getOrDefault("AwsAccountId")
  valid_607261 = validateParameter(valid_607261, JString, required = true,
                                 default = nil)
  if valid_607261 != nil:
    section.add "AwsAccountId", valid_607261
  var valid_607262 = path.getOrDefault("Namespace")
  valid_607262 = validateParameter(valid_607262, JString, required = true,
                                 default = nil)
  if valid_607262 != nil:
    section.add "Namespace", valid_607262
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
  var valid_607263 = header.getOrDefault("X-Amz-Signature")
  valid_607263 = validateParameter(valid_607263, JString, required = false,
                                 default = nil)
  if valid_607263 != nil:
    section.add "X-Amz-Signature", valid_607263
  var valid_607264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607264 = validateParameter(valid_607264, JString, required = false,
                                 default = nil)
  if valid_607264 != nil:
    section.add "X-Amz-Content-Sha256", valid_607264
  var valid_607265 = header.getOrDefault("X-Amz-Date")
  valid_607265 = validateParameter(valid_607265, JString, required = false,
                                 default = nil)
  if valid_607265 != nil:
    section.add "X-Amz-Date", valid_607265
  var valid_607266 = header.getOrDefault("X-Amz-Credential")
  valid_607266 = validateParameter(valid_607266, JString, required = false,
                                 default = nil)
  if valid_607266 != nil:
    section.add "X-Amz-Credential", valid_607266
  var valid_607267 = header.getOrDefault("X-Amz-Security-Token")
  valid_607267 = validateParameter(valid_607267, JString, required = false,
                                 default = nil)
  if valid_607267 != nil:
    section.add "X-Amz-Security-Token", valid_607267
  var valid_607268 = header.getOrDefault("X-Amz-Algorithm")
  valid_607268 = validateParameter(valid_607268, JString, required = false,
                                 default = nil)
  if valid_607268 != nil:
    section.add "X-Amz-Algorithm", valid_607268
  var valid_607269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607269 = validateParameter(valid_607269, JString, required = false,
                                 default = nil)
  if valid_607269 != nil:
    section.add "X-Amz-SignedHeaders", valid_607269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_607271: Call_RegisterUser_607258; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Amazon QuickSight user, whose identity is associated with the AWS Identity and Access Management (IAM) identity or role specified in the request. 
  ## 
  let valid = call_607271.validator(path, query, header, formData, body)
  let scheme = call_607271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607271.url(scheme.get, call_607271.host, call_607271.base,
                         call_607271.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607271, url, valid)

proc call*(call_607272: Call_RegisterUser_607258; AwsAccountId: string;
          Namespace: string; body: JsonNode): Recallable =
  ## registerUser
  ## Creates an Amazon QuickSight user, whose identity is associated with the AWS Identity and Access Management (IAM) identity or role specified in the request. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   body: JObject (required)
  var path_607273 = newJObject()
  var body_607274 = newJObject()
  add(path_607273, "AwsAccountId", newJString(AwsAccountId))
  add(path_607273, "Namespace", newJString(Namespace))
  if body != nil:
    body_607274 = body
  result = call_607272.call(path_607273, nil, nil, nil, body_607274)

var registerUser* = Call_RegisterUser_607258(name: "registerUser",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users",
    validator: validate_RegisterUser_607259, base: "/", url: url_RegisterUser_607260,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_607240 = ref object of OpenApiRestCall_605589
proc url_ListUsers_607242(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "Namespace" in path, "`Namespace` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/namespaces/"),
               (kind: VariableSegment, value: "Namespace"),
               (kind: ConstantSegment, value: "/users")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListUsers_607241(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of all of the Amazon QuickSight users belonging to this account. 
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_607243 = path.getOrDefault("AwsAccountId")
  valid_607243 = validateParameter(valid_607243, JString, required = true,
                                 default = nil)
  if valid_607243 != nil:
    section.add "AwsAccountId", valid_607243
  var valid_607244 = path.getOrDefault("Namespace")
  valid_607244 = validateParameter(valid_607244, JString, required = true,
                                 default = nil)
  if valid_607244 != nil:
    section.add "Namespace", valid_607244
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return from this request.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_607245 = query.getOrDefault("max-results")
  valid_607245 = validateParameter(valid_607245, JInt, required = false, default = nil)
  if valid_607245 != nil:
    section.add "max-results", valid_607245
  var valid_607246 = query.getOrDefault("next-token")
  valid_607246 = validateParameter(valid_607246, JString, required = false,
                                 default = nil)
  if valid_607246 != nil:
    section.add "next-token", valid_607246
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
  var valid_607247 = header.getOrDefault("X-Amz-Signature")
  valid_607247 = validateParameter(valid_607247, JString, required = false,
                                 default = nil)
  if valid_607247 != nil:
    section.add "X-Amz-Signature", valid_607247
  var valid_607248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607248 = validateParameter(valid_607248, JString, required = false,
                                 default = nil)
  if valid_607248 != nil:
    section.add "X-Amz-Content-Sha256", valid_607248
  var valid_607249 = header.getOrDefault("X-Amz-Date")
  valid_607249 = validateParameter(valid_607249, JString, required = false,
                                 default = nil)
  if valid_607249 != nil:
    section.add "X-Amz-Date", valid_607249
  var valid_607250 = header.getOrDefault("X-Amz-Credential")
  valid_607250 = validateParameter(valid_607250, JString, required = false,
                                 default = nil)
  if valid_607250 != nil:
    section.add "X-Amz-Credential", valid_607250
  var valid_607251 = header.getOrDefault("X-Amz-Security-Token")
  valid_607251 = validateParameter(valid_607251, JString, required = false,
                                 default = nil)
  if valid_607251 != nil:
    section.add "X-Amz-Security-Token", valid_607251
  var valid_607252 = header.getOrDefault("X-Amz-Algorithm")
  valid_607252 = validateParameter(valid_607252, JString, required = false,
                                 default = nil)
  if valid_607252 != nil:
    section.add "X-Amz-Algorithm", valid_607252
  var valid_607253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607253 = validateParameter(valid_607253, JString, required = false,
                                 default = nil)
  if valid_607253 != nil:
    section.add "X-Amz-SignedHeaders", valid_607253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607254: Call_ListUsers_607240; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all of the Amazon QuickSight users belonging to this account. 
  ## 
  let valid = call_607254.validator(path, query, header, formData, body)
  let scheme = call_607254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607254.url(scheme.get, call_607254.host, call_607254.base,
                         call_607254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607254, url, valid)

proc call*(call_607255: Call_ListUsers_607240; AwsAccountId: string;
          Namespace: string; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listUsers
  ## Returns a list of all of the Amazon QuickSight users belonging to this account. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   maxResults: int
  ##             : The maximum number of results to return from this request.
  ##   nextToken: string
  ##            : A pagination token that can be used in a subsequent request.
  var path_607256 = newJObject()
  var query_607257 = newJObject()
  add(path_607256, "AwsAccountId", newJString(AwsAccountId))
  add(path_607256, "Namespace", newJString(Namespace))
  add(query_607257, "max-results", newJInt(maxResults))
  add(query_607257, "next-token", newJString(nextToken))
  result = call_607255.call(path_607256, query_607257, nil, nil, nil)

var listUsers* = Call_ListUsers_607240(name: "listUsers", meth: HttpMethod.HttpGet,
                                    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users",
                                    validator: validate_ListUsers_607241,
                                    base: "/", url: url_ListUsers_607242,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_607275 = ref object of OpenApiRestCall_605589
proc url_UntagResource_607277(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "ResourceArn" in path, "`ResourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/resources/"),
               (kind: VariableSegment, value: "ResourceArn"),
               (kind: ConstantSegment, value: "/tags#keys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_607276(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a tag or tags from a resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to untag.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceArn` field"
  var valid_607278 = path.getOrDefault("ResourceArn")
  valid_607278 = validateParameter(valid_607278, JString, required = true,
                                 default = nil)
  if valid_607278 != nil:
    section.add "ResourceArn", valid_607278
  result.add "path", section
  ## parameters in `query` object:
  ##   keys: JArray (required)
  ##       : The keys of the key-value pairs for the resource tag or tags assigned to the resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `keys` field"
  var valid_607279 = query.getOrDefault("keys")
  valid_607279 = validateParameter(valid_607279, JArray, required = true, default = nil)
  if valid_607279 != nil:
    section.add "keys", valid_607279
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
  var valid_607280 = header.getOrDefault("X-Amz-Signature")
  valid_607280 = validateParameter(valid_607280, JString, required = false,
                                 default = nil)
  if valid_607280 != nil:
    section.add "X-Amz-Signature", valid_607280
  var valid_607281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607281 = validateParameter(valid_607281, JString, required = false,
                                 default = nil)
  if valid_607281 != nil:
    section.add "X-Amz-Content-Sha256", valid_607281
  var valid_607282 = header.getOrDefault("X-Amz-Date")
  valid_607282 = validateParameter(valid_607282, JString, required = false,
                                 default = nil)
  if valid_607282 != nil:
    section.add "X-Amz-Date", valid_607282
  var valid_607283 = header.getOrDefault("X-Amz-Credential")
  valid_607283 = validateParameter(valid_607283, JString, required = false,
                                 default = nil)
  if valid_607283 != nil:
    section.add "X-Amz-Credential", valid_607283
  var valid_607284 = header.getOrDefault("X-Amz-Security-Token")
  valid_607284 = validateParameter(valid_607284, JString, required = false,
                                 default = nil)
  if valid_607284 != nil:
    section.add "X-Amz-Security-Token", valid_607284
  var valid_607285 = header.getOrDefault("X-Amz-Algorithm")
  valid_607285 = validateParameter(valid_607285, JString, required = false,
                                 default = nil)
  if valid_607285 != nil:
    section.add "X-Amz-Algorithm", valid_607285
  var valid_607286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607286 = validateParameter(valid_607286, JString, required = false,
                                 default = nil)
  if valid_607286 != nil:
    section.add "X-Amz-SignedHeaders", valid_607286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607287: Call_UntagResource_607275; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag or tags from a resource.
  ## 
  let valid = call_607287.validator(path, query, header, formData, body)
  let scheme = call_607287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607287.url(scheme.get, call_607287.host, call_607287.base,
                         call_607287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607287, url, valid)

proc call*(call_607288: Call_UntagResource_607275; keys: JsonNode;
          ResourceArn: string): Recallable =
  ## untagResource
  ## Removes a tag or tags from a resource.
  ##   keys: JArray (required)
  ##       : The keys of the key-value pairs for the resource tag or tags assigned to the resource.
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to untag.
  var path_607289 = newJObject()
  var query_607290 = newJObject()
  if keys != nil:
    query_607290.add "keys", keys
  add(path_607289, "ResourceArn", newJString(ResourceArn))
  result = call_607288.call(path_607289, query_607290, nil, nil, nil)

var untagResource* = Call_UntagResource_607275(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/resources/{ResourceArn}/tags#keys",
    validator: validate_UntagResource_607276, base: "/", url: url_UntagResource_607277,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDashboardPublishedVersion_607291 = ref object of OpenApiRestCall_605589
proc url_UpdateDashboardPublishedVersion_607293(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "AwsAccountId" in path, "`AwsAccountId` is a required path parameter"
  assert "DashboardId" in path, "`DashboardId` is a required path parameter"
  assert "VersionNumber" in path, "`VersionNumber` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/accounts/"),
               (kind: VariableSegment, value: "AwsAccountId"),
               (kind: ConstantSegment, value: "/dashboards/"),
               (kind: VariableSegment, value: "DashboardId"),
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

proc validate_UpdateDashboardPublishedVersion_607292(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates the published version of a dashboard.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID of the AWS account that contains the dashboard that you're updating.
  ##   VersionNumber: JInt (required)
  ##                : The version number of the dashboard.
  ##   DashboardId: JString (required)
  ##              : The ID for the dashboard.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_607294 = path.getOrDefault("AwsAccountId")
  valid_607294 = validateParameter(valid_607294, JString, required = true,
                                 default = nil)
  if valid_607294 != nil:
    section.add "AwsAccountId", valid_607294
  var valid_607295 = path.getOrDefault("VersionNumber")
  valid_607295 = validateParameter(valid_607295, JInt, required = true, default = nil)
  if valid_607295 != nil:
    section.add "VersionNumber", valid_607295
  var valid_607296 = path.getOrDefault("DashboardId")
  valid_607296 = validateParameter(valid_607296, JString, required = true,
                                 default = nil)
  if valid_607296 != nil:
    section.add "DashboardId", valid_607296
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
  var valid_607297 = header.getOrDefault("X-Amz-Signature")
  valid_607297 = validateParameter(valid_607297, JString, required = false,
                                 default = nil)
  if valid_607297 != nil:
    section.add "X-Amz-Signature", valid_607297
  var valid_607298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_607298 = validateParameter(valid_607298, JString, required = false,
                                 default = nil)
  if valid_607298 != nil:
    section.add "X-Amz-Content-Sha256", valid_607298
  var valid_607299 = header.getOrDefault("X-Amz-Date")
  valid_607299 = validateParameter(valid_607299, JString, required = false,
                                 default = nil)
  if valid_607299 != nil:
    section.add "X-Amz-Date", valid_607299
  var valid_607300 = header.getOrDefault("X-Amz-Credential")
  valid_607300 = validateParameter(valid_607300, JString, required = false,
                                 default = nil)
  if valid_607300 != nil:
    section.add "X-Amz-Credential", valid_607300
  var valid_607301 = header.getOrDefault("X-Amz-Security-Token")
  valid_607301 = validateParameter(valid_607301, JString, required = false,
                                 default = nil)
  if valid_607301 != nil:
    section.add "X-Amz-Security-Token", valid_607301
  var valid_607302 = header.getOrDefault("X-Amz-Algorithm")
  valid_607302 = validateParameter(valid_607302, JString, required = false,
                                 default = nil)
  if valid_607302 != nil:
    section.add "X-Amz-Algorithm", valid_607302
  var valid_607303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_607303 = validateParameter(valid_607303, JString, required = false,
                                 default = nil)
  if valid_607303 != nil:
    section.add "X-Amz-SignedHeaders", valid_607303
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_607304: Call_UpdateDashboardPublishedVersion_607291;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the published version of a dashboard.
  ## 
  let valid = call_607304.validator(path, query, header, formData, body)
  let scheme = call_607304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_607304.url(scheme.get, call_607304.host, call_607304.base,
                         call_607304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_607304, url, valid)

proc call*(call_607305: Call_UpdateDashboardPublishedVersion_607291;
          AwsAccountId: string; VersionNumber: int; DashboardId: string): Recallable =
  ## updateDashboardPublishedVersion
  ## Updates the published version of a dashboard.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're updating.
  ##   VersionNumber: int (required)
  ##                : The version number of the dashboard.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  var path_607306 = newJObject()
  add(path_607306, "AwsAccountId", newJString(AwsAccountId))
  add(path_607306, "VersionNumber", newJInt(VersionNumber))
  add(path_607306, "DashboardId", newJString(DashboardId))
  result = call_607305.call(path_607306, nil, nil, nil, nil)

var updateDashboardPublishedVersion* = Call_UpdateDashboardPublishedVersion_607291(
    name: "updateDashboardPublishedVersion", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/versions/{VersionNumber}",
    validator: validate_UpdateDashboardPublishedVersion_607292, base: "/",
    url: url_UpdateDashboardPublishedVersion_607293,
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
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
