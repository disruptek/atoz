
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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
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
  Call_CreateIngestion_611268 = ref object of OpenApiRestCall_610658
proc url_CreateIngestion_611270(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateIngestion_611269(path: JsonNode; query: JsonNode;
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
  var valid_611271 = path.getOrDefault("AwsAccountId")
  valid_611271 = validateParameter(valid_611271, JString, required = true,
                                 default = nil)
  if valid_611271 != nil:
    section.add "AwsAccountId", valid_611271
  var valid_611272 = path.getOrDefault("DataSetId")
  valid_611272 = validateParameter(valid_611272, JString, required = true,
                                 default = nil)
  if valid_611272 != nil:
    section.add "DataSetId", valid_611272
  var valid_611273 = path.getOrDefault("IngestionId")
  valid_611273 = validateParameter(valid_611273, JString, required = true,
                                 default = nil)
  if valid_611273 != nil:
    section.add "IngestionId", valid_611273
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
  var valid_611274 = header.getOrDefault("X-Amz-Signature")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-Signature", valid_611274
  var valid_611275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-Content-Sha256", valid_611275
  var valid_611276 = header.getOrDefault("X-Amz-Date")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-Date", valid_611276
  var valid_611277 = header.getOrDefault("X-Amz-Credential")
  valid_611277 = validateParameter(valid_611277, JString, required = false,
                                 default = nil)
  if valid_611277 != nil:
    section.add "X-Amz-Credential", valid_611277
  var valid_611278 = header.getOrDefault("X-Amz-Security-Token")
  valid_611278 = validateParameter(valid_611278, JString, required = false,
                                 default = nil)
  if valid_611278 != nil:
    section.add "X-Amz-Security-Token", valid_611278
  var valid_611279 = header.getOrDefault("X-Amz-Algorithm")
  valid_611279 = validateParameter(valid_611279, JString, required = false,
                                 default = nil)
  if valid_611279 != nil:
    section.add "X-Amz-Algorithm", valid_611279
  var valid_611280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611280 = validateParameter(valid_611280, JString, required = false,
                                 default = nil)
  if valid_611280 != nil:
    section.add "X-Amz-SignedHeaders", valid_611280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611281: Call_CreateIngestion_611268; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates and starts a new SPICE ingestion on a dataset</p> <p>Any ingestions operating on tagged datasets inherit the same tags automatically for use in access control. For an example, see <a href="https://aws.example.com/premiumsupport/knowledge-center/iam-ec2-resource-tags/">How do I create an IAM policy to control access to Amazon EC2 resources using tags?</a> in the AWS Knowledge Center. Tags are visible on the tagged dataset, but not on the ingestion resource.</p>
  ## 
  let valid = call_611281.validator(path, query, header, formData, body)
  let scheme = call_611281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611281.url(scheme.get, call_611281.host, call_611281.base,
                         call_611281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611281, url, valid)

proc call*(call_611282: Call_CreateIngestion_611268; AwsAccountId: string;
          DataSetId: string; IngestionId: string): Recallable =
  ## createIngestion
  ## <p>Creates and starts a new SPICE ingestion on a dataset</p> <p>Any ingestions operating on tagged datasets inherit the same tags automatically for use in access control. For an example, see <a href="https://aws.example.com/premiumsupport/knowledge-center/iam-ec2-resource-tags/">How do I create an IAM policy to control access to Amazon EC2 resources using tags?</a> in the AWS Knowledge Center. Tags are visible on the tagged dataset, but not on the ingestion resource.</p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   IngestionId: string (required)
  ##              : An ID for the ingestion.
  var path_611283 = newJObject()
  add(path_611283, "AwsAccountId", newJString(AwsAccountId))
  add(path_611283, "DataSetId", newJString(DataSetId))
  add(path_611283, "IngestionId", newJString(IngestionId))
  result = call_611282.call(path_611283, nil, nil, nil, nil)

var createIngestion* = Call_CreateIngestion_611268(name: "createIngestion",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}",
    validator: validate_CreateIngestion_611269, base: "/", url: url_CreateIngestion_611270,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIngestion_610996 = ref object of OpenApiRestCall_610658
proc url_DescribeIngestion_610998(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeIngestion_610997(path: JsonNode; query: JsonNode;
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
  var valid_611124 = path.getOrDefault("AwsAccountId")
  valid_611124 = validateParameter(valid_611124, JString, required = true,
                                 default = nil)
  if valid_611124 != nil:
    section.add "AwsAccountId", valid_611124
  var valid_611125 = path.getOrDefault("DataSetId")
  valid_611125 = validateParameter(valid_611125, JString, required = true,
                                 default = nil)
  if valid_611125 != nil:
    section.add "DataSetId", valid_611125
  var valid_611126 = path.getOrDefault("IngestionId")
  valid_611126 = validateParameter(valid_611126, JString, required = true,
                                 default = nil)
  if valid_611126 != nil:
    section.add "IngestionId", valid_611126
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
  var valid_611127 = header.getOrDefault("X-Amz-Signature")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "X-Amz-Signature", valid_611127
  var valid_611128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611128 = validateParameter(valid_611128, JString, required = false,
                                 default = nil)
  if valid_611128 != nil:
    section.add "X-Amz-Content-Sha256", valid_611128
  var valid_611129 = header.getOrDefault("X-Amz-Date")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Date", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-Credential")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-Credential", valid_611130
  var valid_611131 = header.getOrDefault("X-Amz-Security-Token")
  valid_611131 = validateParameter(valid_611131, JString, required = false,
                                 default = nil)
  if valid_611131 != nil:
    section.add "X-Amz-Security-Token", valid_611131
  var valid_611132 = header.getOrDefault("X-Amz-Algorithm")
  valid_611132 = validateParameter(valid_611132, JString, required = false,
                                 default = nil)
  if valid_611132 != nil:
    section.add "X-Amz-Algorithm", valid_611132
  var valid_611133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611133 = validateParameter(valid_611133, JString, required = false,
                                 default = nil)
  if valid_611133 != nil:
    section.add "X-Amz-SignedHeaders", valid_611133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611156: Call_DescribeIngestion_610996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a SPICE ingestion.
  ## 
  let valid = call_611156.validator(path, query, header, formData, body)
  let scheme = call_611156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611156.url(scheme.get, call_611156.host, call_611156.base,
                         call_611156.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611156, url, valid)

proc call*(call_611227: Call_DescribeIngestion_610996; AwsAccountId: string;
          DataSetId: string; IngestionId: string): Recallable =
  ## describeIngestion
  ## Describes a SPICE ingestion.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   IngestionId: string (required)
  ##              : An ID for the ingestion.
  var path_611228 = newJObject()
  add(path_611228, "AwsAccountId", newJString(AwsAccountId))
  add(path_611228, "DataSetId", newJString(DataSetId))
  add(path_611228, "IngestionId", newJString(IngestionId))
  result = call_611227.call(path_611228, nil, nil, nil, nil)

var describeIngestion* = Call_DescribeIngestion_610996(name: "describeIngestion",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}",
    validator: validate_DescribeIngestion_610997, base: "/",
    url: url_DescribeIngestion_610998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelIngestion_611284 = ref object of OpenApiRestCall_610658
proc url_CancelIngestion_611286(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CancelIngestion_611285(path: JsonNode; query: JsonNode;
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
  var valid_611287 = path.getOrDefault("AwsAccountId")
  valid_611287 = validateParameter(valid_611287, JString, required = true,
                                 default = nil)
  if valid_611287 != nil:
    section.add "AwsAccountId", valid_611287
  var valid_611288 = path.getOrDefault("DataSetId")
  valid_611288 = validateParameter(valid_611288, JString, required = true,
                                 default = nil)
  if valid_611288 != nil:
    section.add "DataSetId", valid_611288
  var valid_611289 = path.getOrDefault("IngestionId")
  valid_611289 = validateParameter(valid_611289, JString, required = true,
                                 default = nil)
  if valid_611289 != nil:
    section.add "IngestionId", valid_611289
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
  var valid_611290 = header.getOrDefault("X-Amz-Signature")
  valid_611290 = validateParameter(valid_611290, JString, required = false,
                                 default = nil)
  if valid_611290 != nil:
    section.add "X-Amz-Signature", valid_611290
  var valid_611291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611291 = validateParameter(valid_611291, JString, required = false,
                                 default = nil)
  if valid_611291 != nil:
    section.add "X-Amz-Content-Sha256", valid_611291
  var valid_611292 = header.getOrDefault("X-Amz-Date")
  valid_611292 = validateParameter(valid_611292, JString, required = false,
                                 default = nil)
  if valid_611292 != nil:
    section.add "X-Amz-Date", valid_611292
  var valid_611293 = header.getOrDefault("X-Amz-Credential")
  valid_611293 = validateParameter(valid_611293, JString, required = false,
                                 default = nil)
  if valid_611293 != nil:
    section.add "X-Amz-Credential", valid_611293
  var valid_611294 = header.getOrDefault("X-Amz-Security-Token")
  valid_611294 = validateParameter(valid_611294, JString, required = false,
                                 default = nil)
  if valid_611294 != nil:
    section.add "X-Amz-Security-Token", valid_611294
  var valid_611295 = header.getOrDefault("X-Amz-Algorithm")
  valid_611295 = validateParameter(valid_611295, JString, required = false,
                                 default = nil)
  if valid_611295 != nil:
    section.add "X-Amz-Algorithm", valid_611295
  var valid_611296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611296 = validateParameter(valid_611296, JString, required = false,
                                 default = nil)
  if valid_611296 != nil:
    section.add "X-Amz-SignedHeaders", valid_611296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611297: Call_CancelIngestion_611284; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels an ongoing ingestion of data into SPICE.
  ## 
  let valid = call_611297.validator(path, query, header, formData, body)
  let scheme = call_611297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611297.url(scheme.get, call_611297.host, call_611297.base,
                         call_611297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611297, url, valid)

proc call*(call_611298: Call_CancelIngestion_611284; AwsAccountId: string;
          DataSetId: string; IngestionId: string): Recallable =
  ## cancelIngestion
  ## Cancels an ongoing ingestion of data into SPICE.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   IngestionId: string (required)
  ##              : An ID for the ingestion.
  var path_611299 = newJObject()
  add(path_611299, "AwsAccountId", newJString(AwsAccountId))
  add(path_611299, "DataSetId", newJString(DataSetId))
  add(path_611299, "IngestionId", newJString(IngestionId))
  result = call_611298.call(path_611299, nil, nil, nil, nil)

var cancelIngestion* = Call_CancelIngestion_611284(name: "cancelIngestion",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}",
    validator: validate_CancelIngestion_611285, base: "/", url: url_CancelIngestion_611286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDashboard_611318 = ref object of OpenApiRestCall_610658
proc url_UpdateDashboard_611320(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDashboard_611319(path: JsonNode; query: JsonNode;
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
  var valid_611321 = path.getOrDefault("AwsAccountId")
  valid_611321 = validateParameter(valid_611321, JString, required = true,
                                 default = nil)
  if valid_611321 != nil:
    section.add "AwsAccountId", valid_611321
  var valid_611322 = path.getOrDefault("DashboardId")
  valid_611322 = validateParameter(valid_611322, JString, required = true,
                                 default = nil)
  if valid_611322 != nil:
    section.add "DashboardId", valid_611322
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
  var valid_611323 = header.getOrDefault("X-Amz-Signature")
  valid_611323 = validateParameter(valid_611323, JString, required = false,
                                 default = nil)
  if valid_611323 != nil:
    section.add "X-Amz-Signature", valid_611323
  var valid_611324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611324 = validateParameter(valid_611324, JString, required = false,
                                 default = nil)
  if valid_611324 != nil:
    section.add "X-Amz-Content-Sha256", valid_611324
  var valid_611325 = header.getOrDefault("X-Amz-Date")
  valid_611325 = validateParameter(valid_611325, JString, required = false,
                                 default = nil)
  if valid_611325 != nil:
    section.add "X-Amz-Date", valid_611325
  var valid_611326 = header.getOrDefault("X-Amz-Credential")
  valid_611326 = validateParameter(valid_611326, JString, required = false,
                                 default = nil)
  if valid_611326 != nil:
    section.add "X-Amz-Credential", valid_611326
  var valid_611327 = header.getOrDefault("X-Amz-Security-Token")
  valid_611327 = validateParameter(valid_611327, JString, required = false,
                                 default = nil)
  if valid_611327 != nil:
    section.add "X-Amz-Security-Token", valid_611327
  var valid_611328 = header.getOrDefault("X-Amz-Algorithm")
  valid_611328 = validateParameter(valid_611328, JString, required = false,
                                 default = nil)
  if valid_611328 != nil:
    section.add "X-Amz-Algorithm", valid_611328
  var valid_611329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "X-Amz-SignedHeaders", valid_611329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611331: Call_UpdateDashboard_611318; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a dashboard in an AWS account.
  ## 
  let valid = call_611331.validator(path, query, header, formData, body)
  let scheme = call_611331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611331.url(scheme.get, call_611331.host, call_611331.base,
                         call_611331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611331, url, valid)

proc call*(call_611332: Call_UpdateDashboard_611318; AwsAccountId: string;
          body: JsonNode; DashboardId: string): Recallable =
  ## updateDashboard
  ## Updates a dashboard in an AWS account.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're updating.
  ##   body: JObject (required)
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  var path_611333 = newJObject()
  var body_611334 = newJObject()
  add(path_611333, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_611334 = body
  add(path_611333, "DashboardId", newJString(DashboardId))
  result = call_611332.call(path_611333, nil, nil, nil, body_611334)

var updateDashboard* = Call_UpdateDashboard_611318(name: "updateDashboard",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}",
    validator: validate_UpdateDashboard_611319, base: "/", url: url_UpdateDashboard_611320,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDashboard_611335 = ref object of OpenApiRestCall_610658
proc url_CreateDashboard_611337(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDashboard_611336(path: JsonNode; query: JsonNode;
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
  var valid_611338 = path.getOrDefault("AwsAccountId")
  valid_611338 = validateParameter(valid_611338, JString, required = true,
                                 default = nil)
  if valid_611338 != nil:
    section.add "AwsAccountId", valid_611338
  var valid_611339 = path.getOrDefault("DashboardId")
  valid_611339 = validateParameter(valid_611339, JString, required = true,
                                 default = nil)
  if valid_611339 != nil:
    section.add "DashboardId", valid_611339
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
  var valid_611340 = header.getOrDefault("X-Amz-Signature")
  valid_611340 = validateParameter(valid_611340, JString, required = false,
                                 default = nil)
  if valid_611340 != nil:
    section.add "X-Amz-Signature", valid_611340
  var valid_611341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611341 = validateParameter(valid_611341, JString, required = false,
                                 default = nil)
  if valid_611341 != nil:
    section.add "X-Amz-Content-Sha256", valid_611341
  var valid_611342 = header.getOrDefault("X-Amz-Date")
  valid_611342 = validateParameter(valid_611342, JString, required = false,
                                 default = nil)
  if valid_611342 != nil:
    section.add "X-Amz-Date", valid_611342
  var valid_611343 = header.getOrDefault("X-Amz-Credential")
  valid_611343 = validateParameter(valid_611343, JString, required = false,
                                 default = nil)
  if valid_611343 != nil:
    section.add "X-Amz-Credential", valid_611343
  var valid_611344 = header.getOrDefault("X-Amz-Security-Token")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "X-Amz-Security-Token", valid_611344
  var valid_611345 = header.getOrDefault("X-Amz-Algorithm")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "X-Amz-Algorithm", valid_611345
  var valid_611346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611346 = validateParameter(valid_611346, JString, required = false,
                                 default = nil)
  if valid_611346 != nil:
    section.add "X-Amz-SignedHeaders", valid_611346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611348: Call_CreateDashboard_611335; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a dashboard from a template. To first create a template, see the CreateTemplate API operation.</p> <p>A dashboard is an entity in QuickSight that identifies QuickSight reports, created from analyses. You can share QuickSight dashboards. With the right permissions, you can create scheduled email reports from them. The <code>CreateDashboard</code>, <code>DescribeDashboard</code>, and <code>ListDashboardsByUser</code> API operations act on the dashboard entity. If you have the correct permissions, you can create a dashboard from a template that exists in a different AWS account.</p>
  ## 
  let valid = call_611348.validator(path, query, header, formData, body)
  let scheme = call_611348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611348.url(scheme.get, call_611348.host, call_611348.base,
                         call_611348.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611348, url, valid)

proc call*(call_611349: Call_CreateDashboard_611335; AwsAccountId: string;
          body: JsonNode; DashboardId: string): Recallable =
  ## createDashboard
  ## <p>Creates a dashboard from a template. To first create a template, see the CreateTemplate API operation.</p> <p>A dashboard is an entity in QuickSight that identifies QuickSight reports, created from analyses. You can share QuickSight dashboards. With the right permissions, you can create scheduled email reports from them. The <code>CreateDashboard</code>, <code>DescribeDashboard</code>, and <code>ListDashboardsByUser</code> API operations act on the dashboard entity. If you have the correct permissions, you can create a dashboard from a template that exists in a different AWS account.</p>
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account where you want to create the dashboard.
  ##   body: JObject (required)
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard, also added to the IAM policy.
  var path_611350 = newJObject()
  var body_611351 = newJObject()
  add(path_611350, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_611351 = body
  add(path_611350, "DashboardId", newJString(DashboardId))
  result = call_611349.call(path_611350, nil, nil, nil, body_611351)

var createDashboard* = Call_CreateDashboard_611335(name: "createDashboard",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}",
    validator: validate_CreateDashboard_611336, base: "/", url: url_CreateDashboard_611337,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDashboard_611300 = ref object of OpenApiRestCall_610658
proc url_DescribeDashboard_611302(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDashboard_611301(path: JsonNode; query: JsonNode;
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
  var valid_611303 = path.getOrDefault("AwsAccountId")
  valid_611303 = validateParameter(valid_611303, JString, required = true,
                                 default = nil)
  if valid_611303 != nil:
    section.add "AwsAccountId", valid_611303
  var valid_611304 = path.getOrDefault("DashboardId")
  valid_611304 = validateParameter(valid_611304, JString, required = true,
                                 default = nil)
  if valid_611304 != nil:
    section.add "DashboardId", valid_611304
  result.add "path", section
  ## parameters in `query` object:
  ##   version-number: JInt
  ##                 : The version number for the dashboard. If a version number isn't passed, the latest published dashboard version is described. 
  ##   alias-name: JString
  ##             : The alias name.
  section = newJObject()
  var valid_611305 = query.getOrDefault("version-number")
  valid_611305 = validateParameter(valid_611305, JInt, required = false, default = nil)
  if valid_611305 != nil:
    section.add "version-number", valid_611305
  var valid_611306 = query.getOrDefault("alias-name")
  valid_611306 = validateParameter(valid_611306, JString, required = false,
                                 default = nil)
  if valid_611306 != nil:
    section.add "alias-name", valid_611306
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611307 = header.getOrDefault("X-Amz-Signature")
  valid_611307 = validateParameter(valid_611307, JString, required = false,
                                 default = nil)
  if valid_611307 != nil:
    section.add "X-Amz-Signature", valid_611307
  var valid_611308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611308 = validateParameter(valid_611308, JString, required = false,
                                 default = nil)
  if valid_611308 != nil:
    section.add "X-Amz-Content-Sha256", valid_611308
  var valid_611309 = header.getOrDefault("X-Amz-Date")
  valid_611309 = validateParameter(valid_611309, JString, required = false,
                                 default = nil)
  if valid_611309 != nil:
    section.add "X-Amz-Date", valid_611309
  var valid_611310 = header.getOrDefault("X-Amz-Credential")
  valid_611310 = validateParameter(valid_611310, JString, required = false,
                                 default = nil)
  if valid_611310 != nil:
    section.add "X-Amz-Credential", valid_611310
  var valid_611311 = header.getOrDefault("X-Amz-Security-Token")
  valid_611311 = validateParameter(valid_611311, JString, required = false,
                                 default = nil)
  if valid_611311 != nil:
    section.add "X-Amz-Security-Token", valid_611311
  var valid_611312 = header.getOrDefault("X-Amz-Algorithm")
  valid_611312 = validateParameter(valid_611312, JString, required = false,
                                 default = nil)
  if valid_611312 != nil:
    section.add "X-Amz-Algorithm", valid_611312
  var valid_611313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611313 = validateParameter(valid_611313, JString, required = false,
                                 default = nil)
  if valid_611313 != nil:
    section.add "X-Amz-SignedHeaders", valid_611313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611314: Call_DescribeDashboard_611300; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a summary for a dashboard.
  ## 
  let valid = call_611314.validator(path, query, header, formData, body)
  let scheme = call_611314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611314.url(scheme.get, call_611314.host, call_611314.base,
                         call_611314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611314, url, valid)

proc call*(call_611315: Call_DescribeDashboard_611300; AwsAccountId: string;
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
  var path_611316 = newJObject()
  var query_611317 = newJObject()
  add(query_611317, "version-number", newJInt(versionNumber))
  add(path_611316, "AwsAccountId", newJString(AwsAccountId))
  add(query_611317, "alias-name", newJString(aliasName))
  add(path_611316, "DashboardId", newJString(DashboardId))
  result = call_611315.call(path_611316, query_611317, nil, nil, nil)

var describeDashboard* = Call_DescribeDashboard_611300(name: "describeDashboard",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}",
    validator: validate_DescribeDashboard_611301, base: "/",
    url: url_DescribeDashboard_611302, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDashboard_611352 = ref object of OpenApiRestCall_610658
proc url_DeleteDashboard_611354(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDashboard_611353(path: JsonNode; query: JsonNode;
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
  var valid_611355 = path.getOrDefault("AwsAccountId")
  valid_611355 = validateParameter(valid_611355, JString, required = true,
                                 default = nil)
  if valid_611355 != nil:
    section.add "AwsAccountId", valid_611355
  var valid_611356 = path.getOrDefault("DashboardId")
  valid_611356 = validateParameter(valid_611356, JString, required = true,
                                 default = nil)
  if valid_611356 != nil:
    section.add "DashboardId", valid_611356
  result.add "path", section
  ## parameters in `query` object:
  ##   version-number: JInt
  ##                 : The version number of the dashboard. If the version number property is provided, only the specified version of the dashboard is deleted.
  section = newJObject()
  var valid_611357 = query.getOrDefault("version-number")
  valid_611357 = validateParameter(valid_611357, JInt, required = false, default = nil)
  if valid_611357 != nil:
    section.add "version-number", valid_611357
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611358 = header.getOrDefault("X-Amz-Signature")
  valid_611358 = validateParameter(valid_611358, JString, required = false,
                                 default = nil)
  if valid_611358 != nil:
    section.add "X-Amz-Signature", valid_611358
  var valid_611359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611359 = validateParameter(valid_611359, JString, required = false,
                                 default = nil)
  if valid_611359 != nil:
    section.add "X-Amz-Content-Sha256", valid_611359
  var valid_611360 = header.getOrDefault("X-Amz-Date")
  valid_611360 = validateParameter(valid_611360, JString, required = false,
                                 default = nil)
  if valid_611360 != nil:
    section.add "X-Amz-Date", valid_611360
  var valid_611361 = header.getOrDefault("X-Amz-Credential")
  valid_611361 = validateParameter(valid_611361, JString, required = false,
                                 default = nil)
  if valid_611361 != nil:
    section.add "X-Amz-Credential", valid_611361
  var valid_611362 = header.getOrDefault("X-Amz-Security-Token")
  valid_611362 = validateParameter(valid_611362, JString, required = false,
                                 default = nil)
  if valid_611362 != nil:
    section.add "X-Amz-Security-Token", valid_611362
  var valid_611363 = header.getOrDefault("X-Amz-Algorithm")
  valid_611363 = validateParameter(valid_611363, JString, required = false,
                                 default = nil)
  if valid_611363 != nil:
    section.add "X-Amz-Algorithm", valid_611363
  var valid_611364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611364 = validateParameter(valid_611364, JString, required = false,
                                 default = nil)
  if valid_611364 != nil:
    section.add "X-Amz-SignedHeaders", valid_611364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611365: Call_DeleteDashboard_611352; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a dashboard.
  ## 
  let valid = call_611365.validator(path, query, header, formData, body)
  let scheme = call_611365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611365.url(scheme.get, call_611365.host, call_611365.base,
                         call_611365.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611365, url, valid)

proc call*(call_611366: Call_DeleteDashboard_611352; AwsAccountId: string;
          DashboardId: string; versionNumber: int = 0): Recallable =
  ## deleteDashboard
  ## Deletes a dashboard.
  ##   versionNumber: int
  ##                : The version number of the dashboard. If the version number property is provided, only the specified version of the dashboard is deleted.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're deleting.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  var path_611367 = newJObject()
  var query_611368 = newJObject()
  add(query_611368, "version-number", newJInt(versionNumber))
  add(path_611367, "AwsAccountId", newJString(AwsAccountId))
  add(path_611367, "DashboardId", newJString(DashboardId))
  result = call_611366.call(path_611367, query_611368, nil, nil, nil)

var deleteDashboard* = Call_DeleteDashboard_611352(name: "deleteDashboard",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}",
    validator: validate_DeleteDashboard_611353, base: "/", url: url_DeleteDashboard_611354,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSet_611388 = ref object of OpenApiRestCall_610658
proc url_CreateDataSet_611390(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDataSet_611389(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611391 = path.getOrDefault("AwsAccountId")
  valid_611391 = validateParameter(valid_611391, JString, required = true,
                                 default = nil)
  if valid_611391 != nil:
    section.add "AwsAccountId", valid_611391
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
  var valid_611392 = header.getOrDefault("X-Amz-Signature")
  valid_611392 = validateParameter(valid_611392, JString, required = false,
                                 default = nil)
  if valid_611392 != nil:
    section.add "X-Amz-Signature", valid_611392
  var valid_611393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611393 = validateParameter(valid_611393, JString, required = false,
                                 default = nil)
  if valid_611393 != nil:
    section.add "X-Amz-Content-Sha256", valid_611393
  var valid_611394 = header.getOrDefault("X-Amz-Date")
  valid_611394 = validateParameter(valid_611394, JString, required = false,
                                 default = nil)
  if valid_611394 != nil:
    section.add "X-Amz-Date", valid_611394
  var valid_611395 = header.getOrDefault("X-Amz-Credential")
  valid_611395 = validateParameter(valid_611395, JString, required = false,
                                 default = nil)
  if valid_611395 != nil:
    section.add "X-Amz-Credential", valid_611395
  var valid_611396 = header.getOrDefault("X-Amz-Security-Token")
  valid_611396 = validateParameter(valid_611396, JString, required = false,
                                 default = nil)
  if valid_611396 != nil:
    section.add "X-Amz-Security-Token", valid_611396
  var valid_611397 = header.getOrDefault("X-Amz-Algorithm")
  valid_611397 = validateParameter(valid_611397, JString, required = false,
                                 default = nil)
  if valid_611397 != nil:
    section.add "X-Amz-Algorithm", valid_611397
  var valid_611398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611398 = validateParameter(valid_611398, JString, required = false,
                                 default = nil)
  if valid_611398 != nil:
    section.add "X-Amz-SignedHeaders", valid_611398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611400: Call_CreateDataSet_611388; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a dataset.
  ## 
  let valid = call_611400.validator(path, query, header, formData, body)
  let scheme = call_611400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611400.url(scheme.get, call_611400.host, call_611400.base,
                         call_611400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611400, url, valid)

proc call*(call_611401: Call_CreateDataSet_611388; AwsAccountId: string;
          body: JsonNode): Recallable =
  ## createDataSet
  ## Creates a dataset.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   body: JObject (required)
  var path_611402 = newJObject()
  var body_611403 = newJObject()
  add(path_611402, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_611403 = body
  result = call_611401.call(path_611402, nil, nil, nil, body_611403)

var createDataSet* = Call_CreateDataSet_611388(name: "createDataSet",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets",
    validator: validate_CreateDataSet_611389, base: "/", url: url_CreateDataSet_611390,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSets_611369 = ref object of OpenApiRestCall_610658
proc url_ListDataSets_611371(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDataSets_611370(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611372 = path.getOrDefault("AwsAccountId")
  valid_611372 = validateParameter(valid_611372, JString, required = true,
                                 default = nil)
  if valid_611372 != nil:
    section.add "AwsAccountId", valid_611372
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
  var valid_611373 = query.getOrDefault("MaxResults")
  valid_611373 = validateParameter(valid_611373, JString, required = false,
                                 default = nil)
  if valid_611373 != nil:
    section.add "MaxResults", valid_611373
  var valid_611374 = query.getOrDefault("NextToken")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "NextToken", valid_611374
  var valid_611375 = query.getOrDefault("max-results")
  valid_611375 = validateParameter(valid_611375, JInt, required = false, default = nil)
  if valid_611375 != nil:
    section.add "max-results", valid_611375
  var valid_611376 = query.getOrDefault("next-token")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "next-token", valid_611376
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611377 = header.getOrDefault("X-Amz-Signature")
  valid_611377 = validateParameter(valid_611377, JString, required = false,
                                 default = nil)
  if valid_611377 != nil:
    section.add "X-Amz-Signature", valid_611377
  var valid_611378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611378 = validateParameter(valid_611378, JString, required = false,
                                 default = nil)
  if valid_611378 != nil:
    section.add "X-Amz-Content-Sha256", valid_611378
  var valid_611379 = header.getOrDefault("X-Amz-Date")
  valid_611379 = validateParameter(valid_611379, JString, required = false,
                                 default = nil)
  if valid_611379 != nil:
    section.add "X-Amz-Date", valid_611379
  var valid_611380 = header.getOrDefault("X-Amz-Credential")
  valid_611380 = validateParameter(valid_611380, JString, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "X-Amz-Credential", valid_611380
  var valid_611381 = header.getOrDefault("X-Amz-Security-Token")
  valid_611381 = validateParameter(valid_611381, JString, required = false,
                                 default = nil)
  if valid_611381 != nil:
    section.add "X-Amz-Security-Token", valid_611381
  var valid_611382 = header.getOrDefault("X-Amz-Algorithm")
  valid_611382 = validateParameter(valid_611382, JString, required = false,
                                 default = nil)
  if valid_611382 != nil:
    section.add "X-Amz-Algorithm", valid_611382
  var valid_611383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611383 = validateParameter(valid_611383, JString, required = false,
                                 default = nil)
  if valid_611383 != nil:
    section.add "X-Amz-SignedHeaders", valid_611383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611384: Call_ListDataSets_611369; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all of the datasets belonging to the current AWS account in an AWS Region.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/*</code>.</p>
  ## 
  let valid = call_611384.validator(path, query, header, formData, body)
  let scheme = call_611384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611384.url(scheme.get, call_611384.host, call_611384.base,
                         call_611384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611384, url, valid)

proc call*(call_611385: Call_ListDataSets_611369; AwsAccountId: string;
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
  var path_611386 = newJObject()
  var query_611387 = newJObject()
  add(path_611386, "AwsAccountId", newJString(AwsAccountId))
  add(query_611387, "MaxResults", newJString(MaxResults))
  add(query_611387, "NextToken", newJString(NextToken))
  add(query_611387, "max-results", newJInt(maxResults))
  add(query_611387, "next-token", newJString(nextToken))
  result = call_611385.call(path_611386, query_611387, nil, nil, nil)

var listDataSets* = Call_ListDataSets_611369(name: "listDataSets",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets", validator: validate_ListDataSets_611370,
    base: "/", url: url_ListDataSets_611371, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSource_611423 = ref object of OpenApiRestCall_610658
proc url_CreateDataSource_611425(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateDataSource_611424(path: JsonNode; query: JsonNode;
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
  var valid_611426 = path.getOrDefault("AwsAccountId")
  valid_611426 = validateParameter(valid_611426, JString, required = true,
                                 default = nil)
  if valid_611426 != nil:
    section.add "AwsAccountId", valid_611426
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
  var valid_611427 = header.getOrDefault("X-Amz-Signature")
  valid_611427 = validateParameter(valid_611427, JString, required = false,
                                 default = nil)
  if valid_611427 != nil:
    section.add "X-Amz-Signature", valid_611427
  var valid_611428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611428 = validateParameter(valid_611428, JString, required = false,
                                 default = nil)
  if valid_611428 != nil:
    section.add "X-Amz-Content-Sha256", valid_611428
  var valid_611429 = header.getOrDefault("X-Amz-Date")
  valid_611429 = validateParameter(valid_611429, JString, required = false,
                                 default = nil)
  if valid_611429 != nil:
    section.add "X-Amz-Date", valid_611429
  var valid_611430 = header.getOrDefault("X-Amz-Credential")
  valid_611430 = validateParameter(valid_611430, JString, required = false,
                                 default = nil)
  if valid_611430 != nil:
    section.add "X-Amz-Credential", valid_611430
  var valid_611431 = header.getOrDefault("X-Amz-Security-Token")
  valid_611431 = validateParameter(valid_611431, JString, required = false,
                                 default = nil)
  if valid_611431 != nil:
    section.add "X-Amz-Security-Token", valid_611431
  var valid_611432 = header.getOrDefault("X-Amz-Algorithm")
  valid_611432 = validateParameter(valid_611432, JString, required = false,
                                 default = nil)
  if valid_611432 != nil:
    section.add "X-Amz-Algorithm", valid_611432
  var valid_611433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611433 = validateParameter(valid_611433, JString, required = false,
                                 default = nil)
  if valid_611433 != nil:
    section.add "X-Amz-SignedHeaders", valid_611433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611435: Call_CreateDataSource_611423; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a data source.
  ## 
  let valid = call_611435.validator(path, query, header, formData, body)
  let scheme = call_611435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611435.url(scheme.get, call_611435.host, call_611435.base,
                         call_611435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611435, url, valid)

proc call*(call_611436: Call_CreateDataSource_611423; AwsAccountId: string;
          body: JsonNode): Recallable =
  ## createDataSource
  ## Creates a data source.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   body: JObject (required)
  var path_611437 = newJObject()
  var body_611438 = newJObject()
  add(path_611437, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_611438 = body
  result = call_611436.call(path_611437, nil, nil, nil, body_611438)

var createDataSource* = Call_CreateDataSource_611423(name: "createDataSource",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources",
    validator: validate_CreateDataSource_611424, base: "/",
    url: url_CreateDataSource_611425, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSources_611404 = ref object of OpenApiRestCall_610658
proc url_ListDataSources_611406(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDataSources_611405(path: JsonNode; query: JsonNode;
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
  var valid_611407 = path.getOrDefault("AwsAccountId")
  valid_611407 = validateParameter(valid_611407, JString, required = true,
                                 default = nil)
  if valid_611407 != nil:
    section.add "AwsAccountId", valid_611407
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
  var valid_611408 = query.getOrDefault("MaxResults")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "MaxResults", valid_611408
  var valid_611409 = query.getOrDefault("NextToken")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "NextToken", valid_611409
  var valid_611410 = query.getOrDefault("max-results")
  valid_611410 = validateParameter(valid_611410, JInt, required = false, default = nil)
  if valid_611410 != nil:
    section.add "max-results", valid_611410
  var valid_611411 = query.getOrDefault("next-token")
  valid_611411 = validateParameter(valid_611411, JString, required = false,
                                 default = nil)
  if valid_611411 != nil:
    section.add "next-token", valid_611411
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611412 = header.getOrDefault("X-Amz-Signature")
  valid_611412 = validateParameter(valid_611412, JString, required = false,
                                 default = nil)
  if valid_611412 != nil:
    section.add "X-Amz-Signature", valid_611412
  var valid_611413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611413 = validateParameter(valid_611413, JString, required = false,
                                 default = nil)
  if valid_611413 != nil:
    section.add "X-Amz-Content-Sha256", valid_611413
  var valid_611414 = header.getOrDefault("X-Amz-Date")
  valid_611414 = validateParameter(valid_611414, JString, required = false,
                                 default = nil)
  if valid_611414 != nil:
    section.add "X-Amz-Date", valid_611414
  var valid_611415 = header.getOrDefault("X-Amz-Credential")
  valid_611415 = validateParameter(valid_611415, JString, required = false,
                                 default = nil)
  if valid_611415 != nil:
    section.add "X-Amz-Credential", valid_611415
  var valid_611416 = header.getOrDefault("X-Amz-Security-Token")
  valid_611416 = validateParameter(valid_611416, JString, required = false,
                                 default = nil)
  if valid_611416 != nil:
    section.add "X-Amz-Security-Token", valid_611416
  var valid_611417 = header.getOrDefault("X-Amz-Algorithm")
  valid_611417 = validateParameter(valid_611417, JString, required = false,
                                 default = nil)
  if valid_611417 != nil:
    section.add "X-Amz-Algorithm", valid_611417
  var valid_611418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611418 = validateParameter(valid_611418, JString, required = false,
                                 default = nil)
  if valid_611418 != nil:
    section.add "X-Amz-SignedHeaders", valid_611418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611419: Call_ListDataSources_611404; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists data sources in current AWS Region that belong to this AWS account.
  ## 
  let valid = call_611419.validator(path, query, header, formData, body)
  let scheme = call_611419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611419.url(scheme.get, call_611419.host, call_611419.base,
                         call_611419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611419, url, valid)

proc call*(call_611420: Call_ListDataSources_611404; AwsAccountId: string;
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
  var path_611421 = newJObject()
  var query_611422 = newJObject()
  add(path_611421, "AwsAccountId", newJString(AwsAccountId))
  add(query_611422, "MaxResults", newJString(MaxResults))
  add(query_611422, "NextToken", newJString(NextToken))
  add(query_611422, "max-results", newJInt(maxResults))
  add(query_611422, "next-token", newJString(nextToken))
  result = call_611420.call(path_611421, query_611422, nil, nil, nil)

var listDataSources* = Call_ListDataSources_611404(name: "listDataSources",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources",
    validator: validate_ListDataSources_611405, base: "/", url: url_ListDataSources_611406,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroup_611457 = ref object of OpenApiRestCall_610658
proc url_CreateGroup_611459(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateGroup_611458(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611460 = path.getOrDefault("AwsAccountId")
  valid_611460 = validateParameter(valid_611460, JString, required = true,
                                 default = nil)
  if valid_611460 != nil:
    section.add "AwsAccountId", valid_611460
  var valid_611461 = path.getOrDefault("Namespace")
  valid_611461 = validateParameter(valid_611461, JString, required = true,
                                 default = nil)
  if valid_611461 != nil:
    section.add "Namespace", valid_611461
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
  var valid_611462 = header.getOrDefault("X-Amz-Signature")
  valid_611462 = validateParameter(valid_611462, JString, required = false,
                                 default = nil)
  if valid_611462 != nil:
    section.add "X-Amz-Signature", valid_611462
  var valid_611463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611463 = validateParameter(valid_611463, JString, required = false,
                                 default = nil)
  if valid_611463 != nil:
    section.add "X-Amz-Content-Sha256", valid_611463
  var valid_611464 = header.getOrDefault("X-Amz-Date")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "X-Amz-Date", valid_611464
  var valid_611465 = header.getOrDefault("X-Amz-Credential")
  valid_611465 = validateParameter(valid_611465, JString, required = false,
                                 default = nil)
  if valid_611465 != nil:
    section.add "X-Amz-Credential", valid_611465
  var valid_611466 = header.getOrDefault("X-Amz-Security-Token")
  valid_611466 = validateParameter(valid_611466, JString, required = false,
                                 default = nil)
  if valid_611466 != nil:
    section.add "X-Amz-Security-Token", valid_611466
  var valid_611467 = header.getOrDefault("X-Amz-Algorithm")
  valid_611467 = validateParameter(valid_611467, JString, required = false,
                                 default = nil)
  if valid_611467 != nil:
    section.add "X-Amz-Algorithm", valid_611467
  var valid_611468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "X-Amz-SignedHeaders", valid_611468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611470: Call_CreateGroup_611457; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon QuickSight group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;relevant-aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a group object.</p>
  ## 
  let valid = call_611470.validator(path, query, header, formData, body)
  let scheme = call_611470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611470.url(scheme.get, call_611470.host, call_611470.base,
                         call_611470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611470, url, valid)

proc call*(call_611471: Call_CreateGroup_611457; AwsAccountId: string;
          Namespace: string; body: JsonNode): Recallable =
  ## createGroup
  ## <p>Creates an Amazon QuickSight group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;relevant-aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a group object.</p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   body: JObject (required)
  var path_611472 = newJObject()
  var body_611473 = newJObject()
  add(path_611472, "AwsAccountId", newJString(AwsAccountId))
  add(path_611472, "Namespace", newJString(Namespace))
  if body != nil:
    body_611473 = body
  result = call_611471.call(path_611472, nil, nil, nil, body_611473)

var createGroup* = Call_CreateGroup_611457(name: "createGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups",
                                        validator: validate_CreateGroup_611458,
                                        base: "/", url: url_CreateGroup_611459,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_611439 = ref object of OpenApiRestCall_610658
proc url_ListGroups_611441(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListGroups_611440(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611442 = path.getOrDefault("AwsAccountId")
  valid_611442 = validateParameter(valid_611442, JString, required = true,
                                 default = nil)
  if valid_611442 != nil:
    section.add "AwsAccountId", valid_611442
  var valid_611443 = path.getOrDefault("Namespace")
  valid_611443 = validateParameter(valid_611443, JString, required = true,
                                 default = nil)
  if valid_611443 != nil:
    section.add "Namespace", valid_611443
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_611444 = query.getOrDefault("max-results")
  valid_611444 = validateParameter(valid_611444, JInt, required = false, default = nil)
  if valid_611444 != nil:
    section.add "max-results", valid_611444
  var valid_611445 = query.getOrDefault("next-token")
  valid_611445 = validateParameter(valid_611445, JString, required = false,
                                 default = nil)
  if valid_611445 != nil:
    section.add "next-token", valid_611445
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611446 = header.getOrDefault("X-Amz-Signature")
  valid_611446 = validateParameter(valid_611446, JString, required = false,
                                 default = nil)
  if valid_611446 != nil:
    section.add "X-Amz-Signature", valid_611446
  var valid_611447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611447 = validateParameter(valid_611447, JString, required = false,
                                 default = nil)
  if valid_611447 != nil:
    section.add "X-Amz-Content-Sha256", valid_611447
  var valid_611448 = header.getOrDefault("X-Amz-Date")
  valid_611448 = validateParameter(valid_611448, JString, required = false,
                                 default = nil)
  if valid_611448 != nil:
    section.add "X-Amz-Date", valid_611448
  var valid_611449 = header.getOrDefault("X-Amz-Credential")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "X-Amz-Credential", valid_611449
  var valid_611450 = header.getOrDefault("X-Amz-Security-Token")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "X-Amz-Security-Token", valid_611450
  var valid_611451 = header.getOrDefault("X-Amz-Algorithm")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "X-Amz-Algorithm", valid_611451
  var valid_611452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "X-Amz-SignedHeaders", valid_611452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611453: Call_ListGroups_611439; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all user groups in Amazon QuickSight. 
  ## 
  let valid = call_611453.validator(path, query, header, formData, body)
  let scheme = call_611453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611453.url(scheme.get, call_611453.host, call_611453.base,
                         call_611453.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611453, url, valid)

proc call*(call_611454: Call_ListGroups_611439; AwsAccountId: string;
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
  var path_611455 = newJObject()
  var query_611456 = newJObject()
  add(path_611455, "AwsAccountId", newJString(AwsAccountId))
  add(path_611455, "Namespace", newJString(Namespace))
  add(query_611456, "max-results", newJInt(maxResults))
  add(query_611456, "next-token", newJString(nextToken))
  result = call_611454.call(path_611455, query_611456, nil, nil, nil)

var listGroups* = Call_ListGroups_611439(name: "listGroups",
                                      meth: HttpMethod.HttpGet,
                                      host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups",
                                      validator: validate_ListGroups_611440,
                                      base: "/", url: url_ListGroups_611441,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroupMembership_611474 = ref object of OpenApiRestCall_610658
proc url_CreateGroupMembership_611476(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateGroupMembership_611475(path: JsonNode; query: JsonNode;
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
  var valid_611477 = path.getOrDefault("GroupName")
  valid_611477 = validateParameter(valid_611477, JString, required = true,
                                 default = nil)
  if valid_611477 != nil:
    section.add "GroupName", valid_611477
  var valid_611478 = path.getOrDefault("AwsAccountId")
  valid_611478 = validateParameter(valid_611478, JString, required = true,
                                 default = nil)
  if valid_611478 != nil:
    section.add "AwsAccountId", valid_611478
  var valid_611479 = path.getOrDefault("Namespace")
  valid_611479 = validateParameter(valid_611479, JString, required = true,
                                 default = nil)
  if valid_611479 != nil:
    section.add "Namespace", valid_611479
  var valid_611480 = path.getOrDefault("MemberName")
  valid_611480 = validateParameter(valid_611480, JString, required = true,
                                 default = nil)
  if valid_611480 != nil:
    section.add "MemberName", valid_611480
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
  var valid_611481 = header.getOrDefault("X-Amz-Signature")
  valid_611481 = validateParameter(valid_611481, JString, required = false,
                                 default = nil)
  if valid_611481 != nil:
    section.add "X-Amz-Signature", valid_611481
  var valid_611482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611482 = validateParameter(valid_611482, JString, required = false,
                                 default = nil)
  if valid_611482 != nil:
    section.add "X-Amz-Content-Sha256", valid_611482
  var valid_611483 = header.getOrDefault("X-Amz-Date")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "X-Amz-Date", valid_611483
  var valid_611484 = header.getOrDefault("X-Amz-Credential")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "X-Amz-Credential", valid_611484
  var valid_611485 = header.getOrDefault("X-Amz-Security-Token")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "X-Amz-Security-Token", valid_611485
  var valid_611486 = header.getOrDefault("X-Amz-Algorithm")
  valid_611486 = validateParameter(valid_611486, JString, required = false,
                                 default = nil)
  if valid_611486 != nil:
    section.add "X-Amz-Algorithm", valid_611486
  var valid_611487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611487 = validateParameter(valid_611487, JString, required = false,
                                 default = nil)
  if valid_611487 != nil:
    section.add "X-Amz-SignedHeaders", valid_611487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611488: Call_CreateGroupMembership_611474; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds an Amazon QuickSight user to an Amazon QuickSight group. 
  ## 
  let valid = call_611488.validator(path, query, header, formData, body)
  let scheme = call_611488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611488.url(scheme.get, call_611488.host, call_611488.base,
                         call_611488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611488, url, valid)

proc call*(call_611489: Call_CreateGroupMembership_611474; GroupName: string;
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
  var path_611490 = newJObject()
  add(path_611490, "GroupName", newJString(GroupName))
  add(path_611490, "AwsAccountId", newJString(AwsAccountId))
  add(path_611490, "Namespace", newJString(Namespace))
  add(path_611490, "MemberName", newJString(MemberName))
  result = call_611489.call(path_611490, nil, nil, nil, nil)

var createGroupMembership* = Call_CreateGroupMembership_611474(
    name: "createGroupMembership", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members/{MemberName}",
    validator: validate_CreateGroupMembership_611475, base: "/",
    url: url_CreateGroupMembership_611476, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroupMembership_611491 = ref object of OpenApiRestCall_610658
proc url_DeleteGroupMembership_611493(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteGroupMembership_611492(path: JsonNode; query: JsonNode;
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
  var valid_611494 = path.getOrDefault("GroupName")
  valid_611494 = validateParameter(valid_611494, JString, required = true,
                                 default = nil)
  if valid_611494 != nil:
    section.add "GroupName", valid_611494
  var valid_611495 = path.getOrDefault("AwsAccountId")
  valid_611495 = validateParameter(valid_611495, JString, required = true,
                                 default = nil)
  if valid_611495 != nil:
    section.add "AwsAccountId", valid_611495
  var valid_611496 = path.getOrDefault("Namespace")
  valid_611496 = validateParameter(valid_611496, JString, required = true,
                                 default = nil)
  if valid_611496 != nil:
    section.add "Namespace", valid_611496
  var valid_611497 = path.getOrDefault("MemberName")
  valid_611497 = validateParameter(valid_611497, JString, required = true,
                                 default = nil)
  if valid_611497 != nil:
    section.add "MemberName", valid_611497
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
  var valid_611498 = header.getOrDefault("X-Amz-Signature")
  valid_611498 = validateParameter(valid_611498, JString, required = false,
                                 default = nil)
  if valid_611498 != nil:
    section.add "X-Amz-Signature", valid_611498
  var valid_611499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611499 = validateParameter(valid_611499, JString, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "X-Amz-Content-Sha256", valid_611499
  var valid_611500 = header.getOrDefault("X-Amz-Date")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "X-Amz-Date", valid_611500
  var valid_611501 = header.getOrDefault("X-Amz-Credential")
  valid_611501 = validateParameter(valid_611501, JString, required = false,
                                 default = nil)
  if valid_611501 != nil:
    section.add "X-Amz-Credential", valid_611501
  var valid_611502 = header.getOrDefault("X-Amz-Security-Token")
  valid_611502 = validateParameter(valid_611502, JString, required = false,
                                 default = nil)
  if valid_611502 != nil:
    section.add "X-Amz-Security-Token", valid_611502
  var valid_611503 = header.getOrDefault("X-Amz-Algorithm")
  valid_611503 = validateParameter(valid_611503, JString, required = false,
                                 default = nil)
  if valid_611503 != nil:
    section.add "X-Amz-Algorithm", valid_611503
  var valid_611504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611504 = validateParameter(valid_611504, JString, required = false,
                                 default = nil)
  if valid_611504 != nil:
    section.add "X-Amz-SignedHeaders", valid_611504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611505: Call_DeleteGroupMembership_611491; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a user from a group so that the user is no longer a member of the group.
  ## 
  let valid = call_611505.validator(path, query, header, formData, body)
  let scheme = call_611505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611505.url(scheme.get, call_611505.host, call_611505.base,
                         call_611505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611505, url, valid)

proc call*(call_611506: Call_DeleteGroupMembership_611491; GroupName: string;
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
  var path_611507 = newJObject()
  add(path_611507, "GroupName", newJString(GroupName))
  add(path_611507, "AwsAccountId", newJString(AwsAccountId))
  add(path_611507, "Namespace", newJString(Namespace))
  add(path_611507, "MemberName", newJString(MemberName))
  result = call_611506.call(path_611507, nil, nil, nil, nil)

var deleteGroupMembership* = Call_DeleteGroupMembership_611491(
    name: "deleteGroupMembership", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members/{MemberName}",
    validator: validate_DeleteGroupMembership_611492, base: "/",
    url: url_DeleteGroupMembership_611493, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIAMPolicyAssignment_611508 = ref object of OpenApiRestCall_610658
proc url_CreateIAMPolicyAssignment_611510(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateIAMPolicyAssignment_611509(path: JsonNode; query: JsonNode;
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
  var valid_611511 = path.getOrDefault("AwsAccountId")
  valid_611511 = validateParameter(valid_611511, JString, required = true,
                                 default = nil)
  if valid_611511 != nil:
    section.add "AwsAccountId", valid_611511
  var valid_611512 = path.getOrDefault("Namespace")
  valid_611512 = validateParameter(valid_611512, JString, required = true,
                                 default = nil)
  if valid_611512 != nil:
    section.add "Namespace", valid_611512
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
  var valid_611513 = header.getOrDefault("X-Amz-Signature")
  valid_611513 = validateParameter(valid_611513, JString, required = false,
                                 default = nil)
  if valid_611513 != nil:
    section.add "X-Amz-Signature", valid_611513
  var valid_611514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611514 = validateParameter(valid_611514, JString, required = false,
                                 default = nil)
  if valid_611514 != nil:
    section.add "X-Amz-Content-Sha256", valid_611514
  var valid_611515 = header.getOrDefault("X-Amz-Date")
  valid_611515 = validateParameter(valid_611515, JString, required = false,
                                 default = nil)
  if valid_611515 != nil:
    section.add "X-Amz-Date", valid_611515
  var valid_611516 = header.getOrDefault("X-Amz-Credential")
  valid_611516 = validateParameter(valid_611516, JString, required = false,
                                 default = nil)
  if valid_611516 != nil:
    section.add "X-Amz-Credential", valid_611516
  var valid_611517 = header.getOrDefault("X-Amz-Security-Token")
  valid_611517 = validateParameter(valid_611517, JString, required = false,
                                 default = nil)
  if valid_611517 != nil:
    section.add "X-Amz-Security-Token", valid_611517
  var valid_611518 = header.getOrDefault("X-Amz-Algorithm")
  valid_611518 = validateParameter(valid_611518, JString, required = false,
                                 default = nil)
  if valid_611518 != nil:
    section.add "X-Amz-Algorithm", valid_611518
  var valid_611519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611519 = validateParameter(valid_611519, JString, required = false,
                                 default = nil)
  if valid_611519 != nil:
    section.add "X-Amz-SignedHeaders", valid_611519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611521: Call_CreateIAMPolicyAssignment_611508; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an assignment with one specified IAM policy, identified by its Amazon Resource Name (ARN). This policy will be assigned to specified groups or users of Amazon QuickSight. The users and groups need to be in the same namespace. 
  ## 
  let valid = call_611521.validator(path, query, header, formData, body)
  let scheme = call_611521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611521.url(scheme.get, call_611521.host, call_611521.base,
                         call_611521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611521, url, valid)

proc call*(call_611522: Call_CreateIAMPolicyAssignment_611508;
          AwsAccountId: string; Namespace: string; body: JsonNode): Recallable =
  ## createIAMPolicyAssignment
  ## Creates an assignment with one specified IAM policy, identified by its Amazon Resource Name (ARN). This policy will be assigned to specified groups or users of Amazon QuickSight. The users and groups need to be in the same namespace. 
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account where you want to assign an IAM policy to QuickSight users or groups.
  ##   Namespace: string (required)
  ##            : The namespace that contains the assignment.
  ##   body: JObject (required)
  var path_611523 = newJObject()
  var body_611524 = newJObject()
  add(path_611523, "AwsAccountId", newJString(AwsAccountId))
  add(path_611523, "Namespace", newJString(Namespace))
  if body != nil:
    body_611524 = body
  result = call_611522.call(path_611523, nil, nil, nil, body_611524)

var createIAMPolicyAssignment* = Call_CreateIAMPolicyAssignment_611508(
    name: "createIAMPolicyAssignment", meth: HttpMethod.HttpPost,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/",
    validator: validate_CreateIAMPolicyAssignment_611509, base: "/",
    url: url_CreateIAMPolicyAssignment_611510,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTemplate_611543 = ref object of OpenApiRestCall_610658
proc url_UpdateTemplate_611545(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateTemplate_611544(path: JsonNode; query: JsonNode;
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
  var valid_611546 = path.getOrDefault("AwsAccountId")
  valid_611546 = validateParameter(valid_611546, JString, required = true,
                                 default = nil)
  if valid_611546 != nil:
    section.add "AwsAccountId", valid_611546
  var valid_611547 = path.getOrDefault("TemplateId")
  valid_611547 = validateParameter(valid_611547, JString, required = true,
                                 default = nil)
  if valid_611547 != nil:
    section.add "TemplateId", valid_611547
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
  var valid_611548 = header.getOrDefault("X-Amz-Signature")
  valid_611548 = validateParameter(valid_611548, JString, required = false,
                                 default = nil)
  if valid_611548 != nil:
    section.add "X-Amz-Signature", valid_611548
  var valid_611549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611549 = validateParameter(valid_611549, JString, required = false,
                                 default = nil)
  if valid_611549 != nil:
    section.add "X-Amz-Content-Sha256", valid_611549
  var valid_611550 = header.getOrDefault("X-Amz-Date")
  valid_611550 = validateParameter(valid_611550, JString, required = false,
                                 default = nil)
  if valid_611550 != nil:
    section.add "X-Amz-Date", valid_611550
  var valid_611551 = header.getOrDefault("X-Amz-Credential")
  valid_611551 = validateParameter(valid_611551, JString, required = false,
                                 default = nil)
  if valid_611551 != nil:
    section.add "X-Amz-Credential", valid_611551
  var valid_611552 = header.getOrDefault("X-Amz-Security-Token")
  valid_611552 = validateParameter(valid_611552, JString, required = false,
                                 default = nil)
  if valid_611552 != nil:
    section.add "X-Amz-Security-Token", valid_611552
  var valid_611553 = header.getOrDefault("X-Amz-Algorithm")
  valid_611553 = validateParameter(valid_611553, JString, required = false,
                                 default = nil)
  if valid_611553 != nil:
    section.add "X-Amz-Algorithm", valid_611553
  var valid_611554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611554 = validateParameter(valid_611554, JString, required = false,
                                 default = nil)
  if valid_611554 != nil:
    section.add "X-Amz-SignedHeaders", valid_611554
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611556: Call_UpdateTemplate_611543; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a template from an existing Amazon QuickSight analysis or another template.
  ## 
  let valid = call_611556.validator(path, query, header, formData, body)
  let scheme = call_611556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611556.url(scheme.get, call_611556.host, call_611556.base,
                         call_611556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611556, url, valid)

proc call*(call_611557: Call_UpdateTemplate_611543; AwsAccountId: string;
          TemplateId: string; body: JsonNode): Recallable =
  ## updateTemplate
  ## Updates a template from an existing Amazon QuickSight analysis or another template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template that you're updating.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  ##   body: JObject (required)
  var path_611558 = newJObject()
  var body_611559 = newJObject()
  add(path_611558, "AwsAccountId", newJString(AwsAccountId))
  add(path_611558, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_611559 = body
  result = call_611557.call(path_611558, nil, nil, nil, body_611559)

var updateTemplate* = Call_UpdateTemplate_611543(name: "updateTemplate",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}",
    validator: validate_UpdateTemplate_611544, base: "/", url: url_UpdateTemplate_611545,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTemplate_611560 = ref object of OpenApiRestCall_610658
proc url_CreateTemplate_611562(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateTemplate_611561(path: JsonNode; query: JsonNode;
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
  var valid_611563 = path.getOrDefault("AwsAccountId")
  valid_611563 = validateParameter(valid_611563, JString, required = true,
                                 default = nil)
  if valid_611563 != nil:
    section.add "AwsAccountId", valid_611563
  var valid_611564 = path.getOrDefault("TemplateId")
  valid_611564 = validateParameter(valid_611564, JString, required = true,
                                 default = nil)
  if valid_611564 != nil:
    section.add "TemplateId", valid_611564
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
  var valid_611565 = header.getOrDefault("X-Amz-Signature")
  valid_611565 = validateParameter(valid_611565, JString, required = false,
                                 default = nil)
  if valid_611565 != nil:
    section.add "X-Amz-Signature", valid_611565
  var valid_611566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611566 = validateParameter(valid_611566, JString, required = false,
                                 default = nil)
  if valid_611566 != nil:
    section.add "X-Amz-Content-Sha256", valid_611566
  var valid_611567 = header.getOrDefault("X-Amz-Date")
  valid_611567 = validateParameter(valid_611567, JString, required = false,
                                 default = nil)
  if valid_611567 != nil:
    section.add "X-Amz-Date", valid_611567
  var valid_611568 = header.getOrDefault("X-Amz-Credential")
  valid_611568 = validateParameter(valid_611568, JString, required = false,
                                 default = nil)
  if valid_611568 != nil:
    section.add "X-Amz-Credential", valid_611568
  var valid_611569 = header.getOrDefault("X-Amz-Security-Token")
  valid_611569 = validateParameter(valid_611569, JString, required = false,
                                 default = nil)
  if valid_611569 != nil:
    section.add "X-Amz-Security-Token", valid_611569
  var valid_611570 = header.getOrDefault("X-Amz-Algorithm")
  valid_611570 = validateParameter(valid_611570, JString, required = false,
                                 default = nil)
  if valid_611570 != nil:
    section.add "X-Amz-Algorithm", valid_611570
  var valid_611571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611571 = validateParameter(valid_611571, JString, required = false,
                                 default = nil)
  if valid_611571 != nil:
    section.add "X-Amz-SignedHeaders", valid_611571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611573: Call_CreateTemplate_611560; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a template from an existing QuickSight analysis or template. You can use the resulting template to create a dashboard.</p> <p>A <i>template</i> is an entity in QuickSight that encapsulates the metadata required to create an analysis and that you can use to create s dashboard. A template adds a layer of abstraction by using placeholders to replace the dataset associated with the analysis. You can use templates to create dashboards by replacing dataset placeholders with datasets that follow the same schema that was used to create the source analysis and template.</p>
  ## 
  let valid = call_611573.validator(path, query, header, formData, body)
  let scheme = call_611573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611573.url(scheme.get, call_611573.host, call_611573.base,
                         call_611573.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611573, url, valid)

proc call*(call_611574: Call_CreateTemplate_611560; AwsAccountId: string;
          TemplateId: string; body: JsonNode): Recallable =
  ## createTemplate
  ## <p>Creates a template from an existing QuickSight analysis or template. You can use the resulting template to create a dashboard.</p> <p>A <i>template</i> is an entity in QuickSight that encapsulates the metadata required to create an analysis and that you can use to create s dashboard. A template adds a layer of abstraction by using placeholders to replace the dataset associated with the analysis. You can use templates to create dashboards by replacing dataset placeholders with datasets that follow the same schema that was used to create the source analysis and template.</p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   TemplateId: string (required)
  ##             : An ID for the template that you want to create. This template is unique per AWS Region in each AWS account.
  ##   body: JObject (required)
  var path_611575 = newJObject()
  var body_611576 = newJObject()
  add(path_611575, "AwsAccountId", newJString(AwsAccountId))
  add(path_611575, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_611576 = body
  result = call_611574.call(path_611575, nil, nil, nil, body_611576)

var createTemplate* = Call_CreateTemplate_611560(name: "createTemplate",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}",
    validator: validate_CreateTemplate_611561, base: "/", url: url_CreateTemplate_611562,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTemplate_611525 = ref object of OpenApiRestCall_610658
proc url_DescribeTemplate_611527(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeTemplate_611526(path: JsonNode; query: JsonNode;
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
  var valid_611528 = path.getOrDefault("AwsAccountId")
  valid_611528 = validateParameter(valid_611528, JString, required = true,
                                 default = nil)
  if valid_611528 != nil:
    section.add "AwsAccountId", valid_611528
  var valid_611529 = path.getOrDefault("TemplateId")
  valid_611529 = validateParameter(valid_611529, JString, required = true,
                                 default = nil)
  if valid_611529 != nil:
    section.add "TemplateId", valid_611529
  result.add "path", section
  ## parameters in `query` object:
  ##   version-number: JInt
  ##                 : (Optional) The number for the version to describe. If a <code>VersionNumber</code> parameter value isn't provided, the latest version of the template is described.
  ##   alias-name: JString
  ##             : The alias of the template that you want to describe. If you name a specific alias, you describe the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. The keyword <code>$PUBLISHED</code> doesn't apply to templates.
  section = newJObject()
  var valid_611530 = query.getOrDefault("version-number")
  valid_611530 = validateParameter(valid_611530, JInt, required = false, default = nil)
  if valid_611530 != nil:
    section.add "version-number", valid_611530
  var valid_611531 = query.getOrDefault("alias-name")
  valid_611531 = validateParameter(valid_611531, JString, required = false,
                                 default = nil)
  if valid_611531 != nil:
    section.add "alias-name", valid_611531
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611532 = header.getOrDefault("X-Amz-Signature")
  valid_611532 = validateParameter(valid_611532, JString, required = false,
                                 default = nil)
  if valid_611532 != nil:
    section.add "X-Amz-Signature", valid_611532
  var valid_611533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611533 = validateParameter(valid_611533, JString, required = false,
                                 default = nil)
  if valid_611533 != nil:
    section.add "X-Amz-Content-Sha256", valid_611533
  var valid_611534 = header.getOrDefault("X-Amz-Date")
  valid_611534 = validateParameter(valid_611534, JString, required = false,
                                 default = nil)
  if valid_611534 != nil:
    section.add "X-Amz-Date", valid_611534
  var valid_611535 = header.getOrDefault("X-Amz-Credential")
  valid_611535 = validateParameter(valid_611535, JString, required = false,
                                 default = nil)
  if valid_611535 != nil:
    section.add "X-Amz-Credential", valid_611535
  var valid_611536 = header.getOrDefault("X-Amz-Security-Token")
  valid_611536 = validateParameter(valid_611536, JString, required = false,
                                 default = nil)
  if valid_611536 != nil:
    section.add "X-Amz-Security-Token", valid_611536
  var valid_611537 = header.getOrDefault("X-Amz-Algorithm")
  valid_611537 = validateParameter(valid_611537, JString, required = false,
                                 default = nil)
  if valid_611537 != nil:
    section.add "X-Amz-Algorithm", valid_611537
  var valid_611538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611538 = validateParameter(valid_611538, JString, required = false,
                                 default = nil)
  if valid_611538 != nil:
    section.add "X-Amz-SignedHeaders", valid_611538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611539: Call_DescribeTemplate_611525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a template's metadata.
  ## 
  let valid = call_611539.validator(path, query, header, formData, body)
  let scheme = call_611539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611539.url(scheme.get, call_611539.host, call_611539.base,
                         call_611539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611539, url, valid)

proc call*(call_611540: Call_DescribeTemplate_611525; AwsAccountId: string;
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
  var path_611541 = newJObject()
  var query_611542 = newJObject()
  add(query_611542, "version-number", newJInt(versionNumber))
  add(path_611541, "AwsAccountId", newJString(AwsAccountId))
  add(query_611542, "alias-name", newJString(aliasName))
  add(path_611541, "TemplateId", newJString(TemplateId))
  result = call_611540.call(path_611541, query_611542, nil, nil, nil)

var describeTemplate* = Call_DescribeTemplate_611525(name: "describeTemplate",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}",
    validator: validate_DescribeTemplate_611526, base: "/",
    url: url_DescribeTemplate_611527, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTemplate_611577 = ref object of OpenApiRestCall_610658
proc url_DeleteTemplate_611579(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteTemplate_611578(path: JsonNode; query: JsonNode;
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
  var valid_611580 = path.getOrDefault("AwsAccountId")
  valid_611580 = validateParameter(valid_611580, JString, required = true,
                                 default = nil)
  if valid_611580 != nil:
    section.add "AwsAccountId", valid_611580
  var valid_611581 = path.getOrDefault("TemplateId")
  valid_611581 = validateParameter(valid_611581, JString, required = true,
                                 default = nil)
  if valid_611581 != nil:
    section.add "TemplateId", valid_611581
  result.add "path", section
  ## parameters in `query` object:
  ##   version-number: JInt
  ##                 : Specifies the version of the template that you want to delete. If you don't provide a version number, <code>DeleteTemplate</code> deletes all versions of the template. 
  section = newJObject()
  var valid_611582 = query.getOrDefault("version-number")
  valid_611582 = validateParameter(valid_611582, JInt, required = false, default = nil)
  if valid_611582 != nil:
    section.add "version-number", valid_611582
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611583 = header.getOrDefault("X-Amz-Signature")
  valid_611583 = validateParameter(valid_611583, JString, required = false,
                                 default = nil)
  if valid_611583 != nil:
    section.add "X-Amz-Signature", valid_611583
  var valid_611584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611584 = validateParameter(valid_611584, JString, required = false,
                                 default = nil)
  if valid_611584 != nil:
    section.add "X-Amz-Content-Sha256", valid_611584
  var valid_611585 = header.getOrDefault("X-Amz-Date")
  valid_611585 = validateParameter(valid_611585, JString, required = false,
                                 default = nil)
  if valid_611585 != nil:
    section.add "X-Amz-Date", valid_611585
  var valid_611586 = header.getOrDefault("X-Amz-Credential")
  valid_611586 = validateParameter(valid_611586, JString, required = false,
                                 default = nil)
  if valid_611586 != nil:
    section.add "X-Amz-Credential", valid_611586
  var valid_611587 = header.getOrDefault("X-Amz-Security-Token")
  valid_611587 = validateParameter(valid_611587, JString, required = false,
                                 default = nil)
  if valid_611587 != nil:
    section.add "X-Amz-Security-Token", valid_611587
  var valid_611588 = header.getOrDefault("X-Amz-Algorithm")
  valid_611588 = validateParameter(valid_611588, JString, required = false,
                                 default = nil)
  if valid_611588 != nil:
    section.add "X-Amz-Algorithm", valid_611588
  var valid_611589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611589 = validateParameter(valid_611589, JString, required = false,
                                 default = nil)
  if valid_611589 != nil:
    section.add "X-Amz-SignedHeaders", valid_611589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611590: Call_DeleteTemplate_611577; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a template.
  ## 
  let valid = call_611590.validator(path, query, header, formData, body)
  let scheme = call_611590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611590.url(scheme.get, call_611590.host, call_611590.base,
                         call_611590.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611590, url, valid)

proc call*(call_611591: Call_DeleteTemplate_611577; AwsAccountId: string;
          TemplateId: string; versionNumber: int = 0): Recallable =
  ## deleteTemplate
  ## Deletes a template.
  ##   versionNumber: int
  ##                : Specifies the version of the template that you want to delete. If you don't provide a version number, <code>DeleteTemplate</code> deletes all versions of the template. 
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template that you're deleting.
  ##   TemplateId: string (required)
  ##             : An ID for the template you want to delete.
  var path_611592 = newJObject()
  var query_611593 = newJObject()
  add(query_611593, "version-number", newJInt(versionNumber))
  add(path_611592, "AwsAccountId", newJString(AwsAccountId))
  add(path_611592, "TemplateId", newJString(TemplateId))
  result = call_611591.call(path_611592, query_611593, nil, nil, nil)

var deleteTemplate* = Call_DeleteTemplate_611577(name: "deleteTemplate",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}",
    validator: validate_DeleteTemplate_611578, base: "/", url: url_DeleteTemplate_611579,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTemplateAlias_611610 = ref object of OpenApiRestCall_610658
proc url_UpdateTemplateAlias_611612(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateTemplateAlias_611611(path: JsonNode; query: JsonNode;
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
  var valid_611613 = path.getOrDefault("AwsAccountId")
  valid_611613 = validateParameter(valid_611613, JString, required = true,
                                 default = nil)
  if valid_611613 != nil:
    section.add "AwsAccountId", valid_611613
  var valid_611614 = path.getOrDefault("AliasName")
  valid_611614 = validateParameter(valid_611614, JString, required = true,
                                 default = nil)
  if valid_611614 != nil:
    section.add "AliasName", valid_611614
  var valid_611615 = path.getOrDefault("TemplateId")
  valid_611615 = validateParameter(valid_611615, JString, required = true,
                                 default = nil)
  if valid_611615 != nil:
    section.add "TemplateId", valid_611615
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
  var valid_611616 = header.getOrDefault("X-Amz-Signature")
  valid_611616 = validateParameter(valid_611616, JString, required = false,
                                 default = nil)
  if valid_611616 != nil:
    section.add "X-Amz-Signature", valid_611616
  var valid_611617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611617 = validateParameter(valid_611617, JString, required = false,
                                 default = nil)
  if valid_611617 != nil:
    section.add "X-Amz-Content-Sha256", valid_611617
  var valid_611618 = header.getOrDefault("X-Amz-Date")
  valid_611618 = validateParameter(valid_611618, JString, required = false,
                                 default = nil)
  if valid_611618 != nil:
    section.add "X-Amz-Date", valid_611618
  var valid_611619 = header.getOrDefault("X-Amz-Credential")
  valid_611619 = validateParameter(valid_611619, JString, required = false,
                                 default = nil)
  if valid_611619 != nil:
    section.add "X-Amz-Credential", valid_611619
  var valid_611620 = header.getOrDefault("X-Amz-Security-Token")
  valid_611620 = validateParameter(valid_611620, JString, required = false,
                                 default = nil)
  if valid_611620 != nil:
    section.add "X-Amz-Security-Token", valid_611620
  var valid_611621 = header.getOrDefault("X-Amz-Algorithm")
  valid_611621 = validateParameter(valid_611621, JString, required = false,
                                 default = nil)
  if valid_611621 != nil:
    section.add "X-Amz-Algorithm", valid_611621
  var valid_611622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611622 = validateParameter(valid_611622, JString, required = false,
                                 default = nil)
  if valid_611622 != nil:
    section.add "X-Amz-SignedHeaders", valid_611622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611624: Call_UpdateTemplateAlias_611610; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the template alias of a template.
  ## 
  let valid = call_611624.validator(path, query, header, formData, body)
  let scheme = call_611624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611624.url(scheme.get, call_611624.host, call_611624.base,
                         call_611624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611624, url, valid)

proc call*(call_611625: Call_UpdateTemplateAlias_611610; AwsAccountId: string;
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
  var path_611626 = newJObject()
  var body_611627 = newJObject()
  add(path_611626, "AwsAccountId", newJString(AwsAccountId))
  add(path_611626, "AliasName", newJString(AliasName))
  add(path_611626, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_611627 = body
  result = call_611625.call(path_611626, nil, nil, nil, body_611627)

var updateTemplateAlias* = Call_UpdateTemplateAlias_611610(
    name: "updateTemplateAlias", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}",
    validator: validate_UpdateTemplateAlias_611611, base: "/",
    url: url_UpdateTemplateAlias_611612, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTemplateAlias_611628 = ref object of OpenApiRestCall_610658
proc url_CreateTemplateAlias_611630(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateTemplateAlias_611629(path: JsonNode; query: JsonNode;
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
  var valid_611631 = path.getOrDefault("AwsAccountId")
  valid_611631 = validateParameter(valid_611631, JString, required = true,
                                 default = nil)
  if valid_611631 != nil:
    section.add "AwsAccountId", valid_611631
  var valid_611632 = path.getOrDefault("AliasName")
  valid_611632 = validateParameter(valid_611632, JString, required = true,
                                 default = nil)
  if valid_611632 != nil:
    section.add "AliasName", valid_611632
  var valid_611633 = path.getOrDefault("TemplateId")
  valid_611633 = validateParameter(valid_611633, JString, required = true,
                                 default = nil)
  if valid_611633 != nil:
    section.add "TemplateId", valid_611633
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
  var valid_611634 = header.getOrDefault("X-Amz-Signature")
  valid_611634 = validateParameter(valid_611634, JString, required = false,
                                 default = nil)
  if valid_611634 != nil:
    section.add "X-Amz-Signature", valid_611634
  var valid_611635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611635 = validateParameter(valid_611635, JString, required = false,
                                 default = nil)
  if valid_611635 != nil:
    section.add "X-Amz-Content-Sha256", valid_611635
  var valid_611636 = header.getOrDefault("X-Amz-Date")
  valid_611636 = validateParameter(valid_611636, JString, required = false,
                                 default = nil)
  if valid_611636 != nil:
    section.add "X-Amz-Date", valid_611636
  var valid_611637 = header.getOrDefault("X-Amz-Credential")
  valid_611637 = validateParameter(valid_611637, JString, required = false,
                                 default = nil)
  if valid_611637 != nil:
    section.add "X-Amz-Credential", valid_611637
  var valid_611638 = header.getOrDefault("X-Amz-Security-Token")
  valid_611638 = validateParameter(valid_611638, JString, required = false,
                                 default = nil)
  if valid_611638 != nil:
    section.add "X-Amz-Security-Token", valid_611638
  var valid_611639 = header.getOrDefault("X-Amz-Algorithm")
  valid_611639 = validateParameter(valid_611639, JString, required = false,
                                 default = nil)
  if valid_611639 != nil:
    section.add "X-Amz-Algorithm", valid_611639
  var valid_611640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611640 = validateParameter(valid_611640, JString, required = false,
                                 default = nil)
  if valid_611640 != nil:
    section.add "X-Amz-SignedHeaders", valid_611640
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611642: Call_CreateTemplateAlias_611628; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a template alias for a template.
  ## 
  let valid = call_611642.validator(path, query, header, formData, body)
  let scheme = call_611642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611642.url(scheme.get, call_611642.host, call_611642.base,
                         call_611642.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611642, url, valid)

proc call*(call_611643: Call_CreateTemplateAlias_611628; AwsAccountId: string;
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
  var path_611644 = newJObject()
  var body_611645 = newJObject()
  add(path_611644, "AwsAccountId", newJString(AwsAccountId))
  add(path_611644, "AliasName", newJString(AliasName))
  add(path_611644, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_611645 = body
  result = call_611643.call(path_611644, nil, nil, nil, body_611645)

var createTemplateAlias* = Call_CreateTemplateAlias_611628(
    name: "createTemplateAlias", meth: HttpMethod.HttpPost,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}",
    validator: validate_CreateTemplateAlias_611629, base: "/",
    url: url_CreateTemplateAlias_611630, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTemplateAlias_611594 = ref object of OpenApiRestCall_610658
proc url_DescribeTemplateAlias_611596(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeTemplateAlias_611595(path: JsonNode; query: JsonNode;
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
  var valid_611597 = path.getOrDefault("AwsAccountId")
  valid_611597 = validateParameter(valid_611597, JString, required = true,
                                 default = nil)
  if valid_611597 != nil:
    section.add "AwsAccountId", valid_611597
  var valid_611598 = path.getOrDefault("AliasName")
  valid_611598 = validateParameter(valid_611598, JString, required = true,
                                 default = nil)
  if valid_611598 != nil:
    section.add "AliasName", valid_611598
  var valid_611599 = path.getOrDefault("TemplateId")
  valid_611599 = validateParameter(valid_611599, JString, required = true,
                                 default = nil)
  if valid_611599 != nil:
    section.add "TemplateId", valid_611599
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
  var valid_611600 = header.getOrDefault("X-Amz-Signature")
  valid_611600 = validateParameter(valid_611600, JString, required = false,
                                 default = nil)
  if valid_611600 != nil:
    section.add "X-Amz-Signature", valid_611600
  var valid_611601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611601 = validateParameter(valid_611601, JString, required = false,
                                 default = nil)
  if valid_611601 != nil:
    section.add "X-Amz-Content-Sha256", valid_611601
  var valid_611602 = header.getOrDefault("X-Amz-Date")
  valid_611602 = validateParameter(valid_611602, JString, required = false,
                                 default = nil)
  if valid_611602 != nil:
    section.add "X-Amz-Date", valid_611602
  var valid_611603 = header.getOrDefault("X-Amz-Credential")
  valid_611603 = validateParameter(valid_611603, JString, required = false,
                                 default = nil)
  if valid_611603 != nil:
    section.add "X-Amz-Credential", valid_611603
  var valid_611604 = header.getOrDefault("X-Amz-Security-Token")
  valid_611604 = validateParameter(valid_611604, JString, required = false,
                                 default = nil)
  if valid_611604 != nil:
    section.add "X-Amz-Security-Token", valid_611604
  var valid_611605 = header.getOrDefault("X-Amz-Algorithm")
  valid_611605 = validateParameter(valid_611605, JString, required = false,
                                 default = nil)
  if valid_611605 != nil:
    section.add "X-Amz-Algorithm", valid_611605
  var valid_611606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611606 = validateParameter(valid_611606, JString, required = false,
                                 default = nil)
  if valid_611606 != nil:
    section.add "X-Amz-SignedHeaders", valid_611606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611607: Call_DescribeTemplateAlias_611594; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the template alias for a template.
  ## 
  let valid = call_611607.validator(path, query, header, formData, body)
  let scheme = call_611607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611607.url(scheme.get, call_611607.host, call_611607.base,
                         call_611607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611607, url, valid)

proc call*(call_611608: Call_DescribeTemplateAlias_611594; AwsAccountId: string;
          AliasName: string; TemplateId: string): Recallable =
  ## describeTemplateAlias
  ## Describes the template alias for a template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template alias that you're describing.
  ##   AliasName: string (required)
  ##            : The name of the template alias that you want to describe. If you name a specific alias, you describe the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. The keyword <code>$PUBLISHED</code> doesn't apply to templates.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  var path_611609 = newJObject()
  add(path_611609, "AwsAccountId", newJString(AwsAccountId))
  add(path_611609, "AliasName", newJString(AliasName))
  add(path_611609, "TemplateId", newJString(TemplateId))
  result = call_611608.call(path_611609, nil, nil, nil, nil)

var describeTemplateAlias* = Call_DescribeTemplateAlias_611594(
    name: "describeTemplateAlias", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}",
    validator: validate_DescribeTemplateAlias_611595, base: "/",
    url: url_DescribeTemplateAlias_611596, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTemplateAlias_611646 = ref object of OpenApiRestCall_610658
proc url_DeleteTemplateAlias_611648(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteTemplateAlias_611647(path: JsonNode; query: JsonNode;
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
  var valid_611649 = path.getOrDefault("AwsAccountId")
  valid_611649 = validateParameter(valid_611649, JString, required = true,
                                 default = nil)
  if valid_611649 != nil:
    section.add "AwsAccountId", valid_611649
  var valid_611650 = path.getOrDefault("AliasName")
  valid_611650 = validateParameter(valid_611650, JString, required = true,
                                 default = nil)
  if valid_611650 != nil:
    section.add "AliasName", valid_611650
  var valid_611651 = path.getOrDefault("TemplateId")
  valid_611651 = validateParameter(valid_611651, JString, required = true,
                                 default = nil)
  if valid_611651 != nil:
    section.add "TemplateId", valid_611651
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
  var valid_611652 = header.getOrDefault("X-Amz-Signature")
  valid_611652 = validateParameter(valid_611652, JString, required = false,
                                 default = nil)
  if valid_611652 != nil:
    section.add "X-Amz-Signature", valid_611652
  var valid_611653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611653 = validateParameter(valid_611653, JString, required = false,
                                 default = nil)
  if valid_611653 != nil:
    section.add "X-Amz-Content-Sha256", valid_611653
  var valid_611654 = header.getOrDefault("X-Amz-Date")
  valid_611654 = validateParameter(valid_611654, JString, required = false,
                                 default = nil)
  if valid_611654 != nil:
    section.add "X-Amz-Date", valid_611654
  var valid_611655 = header.getOrDefault("X-Amz-Credential")
  valid_611655 = validateParameter(valid_611655, JString, required = false,
                                 default = nil)
  if valid_611655 != nil:
    section.add "X-Amz-Credential", valid_611655
  var valid_611656 = header.getOrDefault("X-Amz-Security-Token")
  valid_611656 = validateParameter(valid_611656, JString, required = false,
                                 default = nil)
  if valid_611656 != nil:
    section.add "X-Amz-Security-Token", valid_611656
  var valid_611657 = header.getOrDefault("X-Amz-Algorithm")
  valid_611657 = validateParameter(valid_611657, JString, required = false,
                                 default = nil)
  if valid_611657 != nil:
    section.add "X-Amz-Algorithm", valid_611657
  var valid_611658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611658 = validateParameter(valid_611658, JString, required = false,
                                 default = nil)
  if valid_611658 != nil:
    section.add "X-Amz-SignedHeaders", valid_611658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611659: Call_DeleteTemplateAlias_611646; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the item that the specified template alias points to. If you provide a specific alias, you delete the version of the template that the alias points to.
  ## 
  let valid = call_611659.validator(path, query, header, formData, body)
  let scheme = call_611659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611659.url(scheme.get, call_611659.host, call_611659.base,
                         call_611659.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611659, url, valid)

proc call*(call_611660: Call_DeleteTemplateAlias_611646; AwsAccountId: string;
          AliasName: string; TemplateId: string): Recallable =
  ## deleteTemplateAlias
  ## Deletes the item that the specified template alias points to. If you provide a specific alias, you delete the version of the template that the alias points to.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the item to delete.
  ##   AliasName: string (required)
  ##            : The name for the template alias. If you name a specific alias, you delete the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. 
  ##   TemplateId: string (required)
  ##             : The ID for the template that the specified alias is for.
  var path_611661 = newJObject()
  add(path_611661, "AwsAccountId", newJString(AwsAccountId))
  add(path_611661, "AliasName", newJString(AliasName))
  add(path_611661, "TemplateId", newJString(TemplateId))
  result = call_611660.call(path_611661, nil, nil, nil, nil)

var deleteTemplateAlias* = Call_DeleteTemplateAlias_611646(
    name: "deleteTemplateAlias", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}",
    validator: validate_DeleteTemplateAlias_611647, base: "/",
    url: url_DeleteTemplateAlias_611648, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSet_611677 = ref object of OpenApiRestCall_610658
proc url_UpdateDataSet_611679(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDataSet_611678(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611680 = path.getOrDefault("AwsAccountId")
  valid_611680 = validateParameter(valid_611680, JString, required = true,
                                 default = nil)
  if valid_611680 != nil:
    section.add "AwsAccountId", valid_611680
  var valid_611681 = path.getOrDefault("DataSetId")
  valid_611681 = validateParameter(valid_611681, JString, required = true,
                                 default = nil)
  if valid_611681 != nil:
    section.add "DataSetId", valid_611681
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
  var valid_611682 = header.getOrDefault("X-Amz-Signature")
  valid_611682 = validateParameter(valid_611682, JString, required = false,
                                 default = nil)
  if valid_611682 != nil:
    section.add "X-Amz-Signature", valid_611682
  var valid_611683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611683 = validateParameter(valid_611683, JString, required = false,
                                 default = nil)
  if valid_611683 != nil:
    section.add "X-Amz-Content-Sha256", valid_611683
  var valid_611684 = header.getOrDefault("X-Amz-Date")
  valid_611684 = validateParameter(valid_611684, JString, required = false,
                                 default = nil)
  if valid_611684 != nil:
    section.add "X-Amz-Date", valid_611684
  var valid_611685 = header.getOrDefault("X-Amz-Credential")
  valid_611685 = validateParameter(valid_611685, JString, required = false,
                                 default = nil)
  if valid_611685 != nil:
    section.add "X-Amz-Credential", valid_611685
  var valid_611686 = header.getOrDefault("X-Amz-Security-Token")
  valid_611686 = validateParameter(valid_611686, JString, required = false,
                                 default = nil)
  if valid_611686 != nil:
    section.add "X-Amz-Security-Token", valid_611686
  var valid_611687 = header.getOrDefault("X-Amz-Algorithm")
  valid_611687 = validateParameter(valid_611687, JString, required = false,
                                 default = nil)
  if valid_611687 != nil:
    section.add "X-Amz-Algorithm", valid_611687
  var valid_611688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611688 = validateParameter(valid_611688, JString, required = false,
                                 default = nil)
  if valid_611688 != nil:
    section.add "X-Amz-SignedHeaders", valid_611688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611690: Call_UpdateDataSet_611677; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a dataset.
  ## 
  let valid = call_611690.validator(path, query, header, formData, body)
  let scheme = call_611690.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611690.url(scheme.get, call_611690.host, call_611690.base,
                         call_611690.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611690, url, valid)

proc call*(call_611691: Call_UpdateDataSet_611677; AwsAccountId: string;
          DataSetId: string; body: JsonNode): Recallable =
  ## updateDataSet
  ## Updates a dataset.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset that you want to update. This ID is unique per AWS Region for each AWS account.
  ##   body: JObject (required)
  var path_611692 = newJObject()
  var body_611693 = newJObject()
  add(path_611692, "AwsAccountId", newJString(AwsAccountId))
  add(path_611692, "DataSetId", newJString(DataSetId))
  if body != nil:
    body_611693 = body
  result = call_611691.call(path_611692, nil, nil, nil, body_611693)

var updateDataSet* = Call_UpdateDataSet_611677(name: "updateDataSet",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}",
    validator: validate_UpdateDataSet_611678, base: "/", url: url_UpdateDataSet_611679,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSet_611662 = ref object of OpenApiRestCall_610658
proc url_DescribeDataSet_611664(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDataSet_611663(path: JsonNode; query: JsonNode;
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
  var valid_611665 = path.getOrDefault("AwsAccountId")
  valid_611665 = validateParameter(valid_611665, JString, required = true,
                                 default = nil)
  if valid_611665 != nil:
    section.add "AwsAccountId", valid_611665
  var valid_611666 = path.getOrDefault("DataSetId")
  valid_611666 = validateParameter(valid_611666, JString, required = true,
                                 default = nil)
  if valid_611666 != nil:
    section.add "DataSetId", valid_611666
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
  var valid_611667 = header.getOrDefault("X-Amz-Signature")
  valid_611667 = validateParameter(valid_611667, JString, required = false,
                                 default = nil)
  if valid_611667 != nil:
    section.add "X-Amz-Signature", valid_611667
  var valid_611668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611668 = validateParameter(valid_611668, JString, required = false,
                                 default = nil)
  if valid_611668 != nil:
    section.add "X-Amz-Content-Sha256", valid_611668
  var valid_611669 = header.getOrDefault("X-Amz-Date")
  valid_611669 = validateParameter(valid_611669, JString, required = false,
                                 default = nil)
  if valid_611669 != nil:
    section.add "X-Amz-Date", valid_611669
  var valid_611670 = header.getOrDefault("X-Amz-Credential")
  valid_611670 = validateParameter(valid_611670, JString, required = false,
                                 default = nil)
  if valid_611670 != nil:
    section.add "X-Amz-Credential", valid_611670
  var valid_611671 = header.getOrDefault("X-Amz-Security-Token")
  valid_611671 = validateParameter(valid_611671, JString, required = false,
                                 default = nil)
  if valid_611671 != nil:
    section.add "X-Amz-Security-Token", valid_611671
  var valid_611672 = header.getOrDefault("X-Amz-Algorithm")
  valid_611672 = validateParameter(valid_611672, JString, required = false,
                                 default = nil)
  if valid_611672 != nil:
    section.add "X-Amz-Algorithm", valid_611672
  var valid_611673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611673 = validateParameter(valid_611673, JString, required = false,
                                 default = nil)
  if valid_611673 != nil:
    section.add "X-Amz-SignedHeaders", valid_611673
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611674: Call_DescribeDataSet_611662; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a dataset. 
  ## 
  let valid = call_611674.validator(path, query, header, formData, body)
  let scheme = call_611674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611674.url(scheme.get, call_611674.host, call_611674.base,
                         call_611674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611674, url, valid)

proc call*(call_611675: Call_DescribeDataSet_611662; AwsAccountId: string;
          DataSetId: string): Recallable =
  ## describeDataSet
  ## Describes a dataset. 
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset that you want to create. This ID is unique per AWS Region for each AWS account.
  var path_611676 = newJObject()
  add(path_611676, "AwsAccountId", newJString(AwsAccountId))
  add(path_611676, "DataSetId", newJString(DataSetId))
  result = call_611675.call(path_611676, nil, nil, nil, nil)

var describeDataSet* = Call_DescribeDataSet_611662(name: "describeDataSet",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}",
    validator: validate_DescribeDataSet_611663, base: "/", url: url_DescribeDataSet_611664,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSet_611694 = ref object of OpenApiRestCall_610658
proc url_DeleteDataSet_611696(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDataSet_611695(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611697 = path.getOrDefault("AwsAccountId")
  valid_611697 = validateParameter(valid_611697, JString, required = true,
                                 default = nil)
  if valid_611697 != nil:
    section.add "AwsAccountId", valid_611697
  var valid_611698 = path.getOrDefault("DataSetId")
  valid_611698 = validateParameter(valid_611698, JString, required = true,
                                 default = nil)
  if valid_611698 != nil:
    section.add "DataSetId", valid_611698
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
  var valid_611699 = header.getOrDefault("X-Amz-Signature")
  valid_611699 = validateParameter(valid_611699, JString, required = false,
                                 default = nil)
  if valid_611699 != nil:
    section.add "X-Amz-Signature", valid_611699
  var valid_611700 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611700 = validateParameter(valid_611700, JString, required = false,
                                 default = nil)
  if valid_611700 != nil:
    section.add "X-Amz-Content-Sha256", valid_611700
  var valid_611701 = header.getOrDefault("X-Amz-Date")
  valid_611701 = validateParameter(valid_611701, JString, required = false,
                                 default = nil)
  if valid_611701 != nil:
    section.add "X-Amz-Date", valid_611701
  var valid_611702 = header.getOrDefault("X-Amz-Credential")
  valid_611702 = validateParameter(valid_611702, JString, required = false,
                                 default = nil)
  if valid_611702 != nil:
    section.add "X-Amz-Credential", valid_611702
  var valid_611703 = header.getOrDefault("X-Amz-Security-Token")
  valid_611703 = validateParameter(valid_611703, JString, required = false,
                                 default = nil)
  if valid_611703 != nil:
    section.add "X-Amz-Security-Token", valid_611703
  var valid_611704 = header.getOrDefault("X-Amz-Algorithm")
  valid_611704 = validateParameter(valid_611704, JString, required = false,
                                 default = nil)
  if valid_611704 != nil:
    section.add "X-Amz-Algorithm", valid_611704
  var valid_611705 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611705 = validateParameter(valid_611705, JString, required = false,
                                 default = nil)
  if valid_611705 != nil:
    section.add "X-Amz-SignedHeaders", valid_611705
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611706: Call_DeleteDataSet_611694; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a dataset.
  ## 
  let valid = call_611706.validator(path, query, header, formData, body)
  let scheme = call_611706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611706.url(scheme.get, call_611706.host, call_611706.base,
                         call_611706.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611706, url, valid)

proc call*(call_611707: Call_DeleteDataSet_611694; AwsAccountId: string;
          DataSetId: string): Recallable =
  ## deleteDataSet
  ## Deletes a dataset.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset that you want to create. This ID is unique per AWS Region for each AWS account.
  var path_611708 = newJObject()
  add(path_611708, "AwsAccountId", newJString(AwsAccountId))
  add(path_611708, "DataSetId", newJString(DataSetId))
  result = call_611707.call(path_611708, nil, nil, nil, nil)

var deleteDataSet* = Call_DeleteDataSet_611694(name: "deleteDataSet",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}",
    validator: validate_DeleteDataSet_611695, base: "/", url: url_DeleteDataSet_611696,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSource_611724 = ref object of OpenApiRestCall_610658
proc url_UpdateDataSource_611726(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDataSource_611725(path: JsonNode; query: JsonNode;
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
  var valid_611727 = path.getOrDefault("DataSourceId")
  valid_611727 = validateParameter(valid_611727, JString, required = true,
                                 default = nil)
  if valid_611727 != nil:
    section.add "DataSourceId", valid_611727
  var valid_611728 = path.getOrDefault("AwsAccountId")
  valid_611728 = validateParameter(valid_611728, JString, required = true,
                                 default = nil)
  if valid_611728 != nil:
    section.add "AwsAccountId", valid_611728
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
  var valid_611729 = header.getOrDefault("X-Amz-Signature")
  valid_611729 = validateParameter(valid_611729, JString, required = false,
                                 default = nil)
  if valid_611729 != nil:
    section.add "X-Amz-Signature", valid_611729
  var valid_611730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611730 = validateParameter(valid_611730, JString, required = false,
                                 default = nil)
  if valid_611730 != nil:
    section.add "X-Amz-Content-Sha256", valid_611730
  var valid_611731 = header.getOrDefault("X-Amz-Date")
  valid_611731 = validateParameter(valid_611731, JString, required = false,
                                 default = nil)
  if valid_611731 != nil:
    section.add "X-Amz-Date", valid_611731
  var valid_611732 = header.getOrDefault("X-Amz-Credential")
  valid_611732 = validateParameter(valid_611732, JString, required = false,
                                 default = nil)
  if valid_611732 != nil:
    section.add "X-Amz-Credential", valid_611732
  var valid_611733 = header.getOrDefault("X-Amz-Security-Token")
  valid_611733 = validateParameter(valid_611733, JString, required = false,
                                 default = nil)
  if valid_611733 != nil:
    section.add "X-Amz-Security-Token", valid_611733
  var valid_611734 = header.getOrDefault("X-Amz-Algorithm")
  valid_611734 = validateParameter(valid_611734, JString, required = false,
                                 default = nil)
  if valid_611734 != nil:
    section.add "X-Amz-Algorithm", valid_611734
  var valid_611735 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611735 = validateParameter(valid_611735, JString, required = false,
                                 default = nil)
  if valid_611735 != nil:
    section.add "X-Amz-SignedHeaders", valid_611735
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611737: Call_UpdateDataSource_611724; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a data source.
  ## 
  let valid = call_611737.validator(path, query, header, formData, body)
  let scheme = call_611737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611737.url(scheme.get, call_611737.host, call_611737.base,
                         call_611737.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611737, url, valid)

proc call*(call_611738: Call_UpdateDataSource_611724; DataSourceId: string;
          AwsAccountId: string; body: JsonNode): Recallable =
  ## updateDataSource
  ## Updates a data source.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account. 
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   body: JObject (required)
  var path_611739 = newJObject()
  var body_611740 = newJObject()
  add(path_611739, "DataSourceId", newJString(DataSourceId))
  add(path_611739, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_611740 = body
  result = call_611738.call(path_611739, nil, nil, nil, body_611740)

var updateDataSource* = Call_UpdateDataSource_611724(name: "updateDataSource",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}",
    validator: validate_UpdateDataSource_611725, base: "/",
    url: url_UpdateDataSource_611726, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSource_611709 = ref object of OpenApiRestCall_610658
proc url_DescribeDataSource_611711(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDataSource_611710(path: JsonNode; query: JsonNode;
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
  var valid_611712 = path.getOrDefault("DataSourceId")
  valid_611712 = validateParameter(valid_611712, JString, required = true,
                                 default = nil)
  if valid_611712 != nil:
    section.add "DataSourceId", valid_611712
  var valid_611713 = path.getOrDefault("AwsAccountId")
  valid_611713 = validateParameter(valid_611713, JString, required = true,
                                 default = nil)
  if valid_611713 != nil:
    section.add "AwsAccountId", valid_611713
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
  var valid_611714 = header.getOrDefault("X-Amz-Signature")
  valid_611714 = validateParameter(valid_611714, JString, required = false,
                                 default = nil)
  if valid_611714 != nil:
    section.add "X-Amz-Signature", valid_611714
  var valid_611715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611715 = validateParameter(valid_611715, JString, required = false,
                                 default = nil)
  if valid_611715 != nil:
    section.add "X-Amz-Content-Sha256", valid_611715
  var valid_611716 = header.getOrDefault("X-Amz-Date")
  valid_611716 = validateParameter(valid_611716, JString, required = false,
                                 default = nil)
  if valid_611716 != nil:
    section.add "X-Amz-Date", valid_611716
  var valid_611717 = header.getOrDefault("X-Amz-Credential")
  valid_611717 = validateParameter(valid_611717, JString, required = false,
                                 default = nil)
  if valid_611717 != nil:
    section.add "X-Amz-Credential", valid_611717
  var valid_611718 = header.getOrDefault("X-Amz-Security-Token")
  valid_611718 = validateParameter(valid_611718, JString, required = false,
                                 default = nil)
  if valid_611718 != nil:
    section.add "X-Amz-Security-Token", valid_611718
  var valid_611719 = header.getOrDefault("X-Amz-Algorithm")
  valid_611719 = validateParameter(valid_611719, JString, required = false,
                                 default = nil)
  if valid_611719 != nil:
    section.add "X-Amz-Algorithm", valid_611719
  var valid_611720 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611720 = validateParameter(valid_611720, JString, required = false,
                                 default = nil)
  if valid_611720 != nil:
    section.add "X-Amz-SignedHeaders", valid_611720
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611721: Call_DescribeDataSource_611709; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a data source.
  ## 
  let valid = call_611721.validator(path, query, header, formData, body)
  let scheme = call_611721.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611721.url(scheme.get, call_611721.host, call_611721.base,
                         call_611721.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611721, url, valid)

proc call*(call_611722: Call_DescribeDataSource_611709; DataSourceId: string;
          AwsAccountId: string): Recallable =
  ## describeDataSource
  ## Describes a data source.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  var path_611723 = newJObject()
  add(path_611723, "DataSourceId", newJString(DataSourceId))
  add(path_611723, "AwsAccountId", newJString(AwsAccountId))
  result = call_611722.call(path_611723, nil, nil, nil, nil)

var describeDataSource* = Call_DescribeDataSource_611709(
    name: "describeDataSource", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}",
    validator: validate_DescribeDataSource_611710, base: "/",
    url: url_DescribeDataSource_611711, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSource_611741 = ref object of OpenApiRestCall_610658
proc url_DeleteDataSource_611743(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDataSource_611742(path: JsonNode; query: JsonNode;
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
  var valid_611744 = path.getOrDefault("DataSourceId")
  valid_611744 = validateParameter(valid_611744, JString, required = true,
                                 default = nil)
  if valid_611744 != nil:
    section.add "DataSourceId", valid_611744
  var valid_611745 = path.getOrDefault("AwsAccountId")
  valid_611745 = validateParameter(valid_611745, JString, required = true,
                                 default = nil)
  if valid_611745 != nil:
    section.add "AwsAccountId", valid_611745
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
  var valid_611746 = header.getOrDefault("X-Amz-Signature")
  valid_611746 = validateParameter(valid_611746, JString, required = false,
                                 default = nil)
  if valid_611746 != nil:
    section.add "X-Amz-Signature", valid_611746
  var valid_611747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611747 = validateParameter(valid_611747, JString, required = false,
                                 default = nil)
  if valid_611747 != nil:
    section.add "X-Amz-Content-Sha256", valid_611747
  var valid_611748 = header.getOrDefault("X-Amz-Date")
  valid_611748 = validateParameter(valid_611748, JString, required = false,
                                 default = nil)
  if valid_611748 != nil:
    section.add "X-Amz-Date", valid_611748
  var valid_611749 = header.getOrDefault("X-Amz-Credential")
  valid_611749 = validateParameter(valid_611749, JString, required = false,
                                 default = nil)
  if valid_611749 != nil:
    section.add "X-Amz-Credential", valid_611749
  var valid_611750 = header.getOrDefault("X-Amz-Security-Token")
  valid_611750 = validateParameter(valid_611750, JString, required = false,
                                 default = nil)
  if valid_611750 != nil:
    section.add "X-Amz-Security-Token", valid_611750
  var valid_611751 = header.getOrDefault("X-Amz-Algorithm")
  valid_611751 = validateParameter(valid_611751, JString, required = false,
                                 default = nil)
  if valid_611751 != nil:
    section.add "X-Amz-Algorithm", valid_611751
  var valid_611752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611752 = validateParameter(valid_611752, JString, required = false,
                                 default = nil)
  if valid_611752 != nil:
    section.add "X-Amz-SignedHeaders", valid_611752
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611753: Call_DeleteDataSource_611741; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the data source permanently. This action breaks all the datasets that reference the deleted data source.
  ## 
  let valid = call_611753.validator(path, query, header, formData, body)
  let scheme = call_611753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611753.url(scheme.get, call_611753.host, call_611753.base,
                         call_611753.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611753, url, valid)

proc call*(call_611754: Call_DeleteDataSource_611741; DataSourceId: string;
          AwsAccountId: string): Recallable =
  ## deleteDataSource
  ## Deletes the data source permanently. This action breaks all the datasets that reference the deleted data source.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  var path_611755 = newJObject()
  add(path_611755, "DataSourceId", newJString(DataSourceId))
  add(path_611755, "AwsAccountId", newJString(AwsAccountId))
  result = call_611754.call(path_611755, nil, nil, nil, nil)

var deleteDataSource* = Call_DeleteDataSource_611741(name: "deleteDataSource",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}",
    validator: validate_DeleteDataSource_611742, base: "/",
    url: url_DeleteDataSource_611743, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_611772 = ref object of OpenApiRestCall_610658
proc url_UpdateGroup_611774(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateGroup_611773(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611775 = path.getOrDefault("GroupName")
  valid_611775 = validateParameter(valid_611775, JString, required = true,
                                 default = nil)
  if valid_611775 != nil:
    section.add "GroupName", valid_611775
  var valid_611776 = path.getOrDefault("AwsAccountId")
  valid_611776 = validateParameter(valid_611776, JString, required = true,
                                 default = nil)
  if valid_611776 != nil:
    section.add "AwsAccountId", valid_611776
  var valid_611777 = path.getOrDefault("Namespace")
  valid_611777 = validateParameter(valid_611777, JString, required = true,
                                 default = nil)
  if valid_611777 != nil:
    section.add "Namespace", valid_611777
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
  var valid_611778 = header.getOrDefault("X-Amz-Signature")
  valid_611778 = validateParameter(valid_611778, JString, required = false,
                                 default = nil)
  if valid_611778 != nil:
    section.add "X-Amz-Signature", valid_611778
  var valid_611779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611779 = validateParameter(valid_611779, JString, required = false,
                                 default = nil)
  if valid_611779 != nil:
    section.add "X-Amz-Content-Sha256", valid_611779
  var valid_611780 = header.getOrDefault("X-Amz-Date")
  valid_611780 = validateParameter(valid_611780, JString, required = false,
                                 default = nil)
  if valid_611780 != nil:
    section.add "X-Amz-Date", valid_611780
  var valid_611781 = header.getOrDefault("X-Amz-Credential")
  valid_611781 = validateParameter(valid_611781, JString, required = false,
                                 default = nil)
  if valid_611781 != nil:
    section.add "X-Amz-Credential", valid_611781
  var valid_611782 = header.getOrDefault("X-Amz-Security-Token")
  valid_611782 = validateParameter(valid_611782, JString, required = false,
                                 default = nil)
  if valid_611782 != nil:
    section.add "X-Amz-Security-Token", valid_611782
  var valid_611783 = header.getOrDefault("X-Amz-Algorithm")
  valid_611783 = validateParameter(valid_611783, JString, required = false,
                                 default = nil)
  if valid_611783 != nil:
    section.add "X-Amz-Algorithm", valid_611783
  var valid_611784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611784 = validateParameter(valid_611784, JString, required = false,
                                 default = nil)
  if valid_611784 != nil:
    section.add "X-Amz-SignedHeaders", valid_611784
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611786: Call_UpdateGroup_611772; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes a group description. 
  ## 
  let valid = call_611786.validator(path, query, header, formData, body)
  let scheme = call_611786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611786.url(scheme.get, call_611786.host, call_611786.base,
                         call_611786.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611786, url, valid)

proc call*(call_611787: Call_UpdateGroup_611772; GroupName: string;
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
  var path_611788 = newJObject()
  var body_611789 = newJObject()
  add(path_611788, "GroupName", newJString(GroupName))
  add(path_611788, "AwsAccountId", newJString(AwsAccountId))
  add(path_611788, "Namespace", newJString(Namespace))
  if body != nil:
    body_611789 = body
  result = call_611787.call(path_611788, nil, nil, nil, body_611789)

var updateGroup* = Call_UpdateGroup_611772(name: "updateGroup",
                                        meth: HttpMethod.HttpPut,
                                        host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}",
                                        validator: validate_UpdateGroup_611773,
                                        base: "/", url: url_UpdateGroup_611774,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGroup_611756 = ref object of OpenApiRestCall_610658
proc url_DescribeGroup_611758(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeGroup_611757(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611759 = path.getOrDefault("GroupName")
  valid_611759 = validateParameter(valid_611759, JString, required = true,
                                 default = nil)
  if valid_611759 != nil:
    section.add "GroupName", valid_611759
  var valid_611760 = path.getOrDefault("AwsAccountId")
  valid_611760 = validateParameter(valid_611760, JString, required = true,
                                 default = nil)
  if valid_611760 != nil:
    section.add "AwsAccountId", valid_611760
  var valid_611761 = path.getOrDefault("Namespace")
  valid_611761 = validateParameter(valid_611761, JString, required = true,
                                 default = nil)
  if valid_611761 != nil:
    section.add "Namespace", valid_611761
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
  var valid_611762 = header.getOrDefault("X-Amz-Signature")
  valid_611762 = validateParameter(valid_611762, JString, required = false,
                                 default = nil)
  if valid_611762 != nil:
    section.add "X-Amz-Signature", valid_611762
  var valid_611763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611763 = validateParameter(valid_611763, JString, required = false,
                                 default = nil)
  if valid_611763 != nil:
    section.add "X-Amz-Content-Sha256", valid_611763
  var valid_611764 = header.getOrDefault("X-Amz-Date")
  valid_611764 = validateParameter(valid_611764, JString, required = false,
                                 default = nil)
  if valid_611764 != nil:
    section.add "X-Amz-Date", valid_611764
  var valid_611765 = header.getOrDefault("X-Amz-Credential")
  valid_611765 = validateParameter(valid_611765, JString, required = false,
                                 default = nil)
  if valid_611765 != nil:
    section.add "X-Amz-Credential", valid_611765
  var valid_611766 = header.getOrDefault("X-Amz-Security-Token")
  valid_611766 = validateParameter(valid_611766, JString, required = false,
                                 default = nil)
  if valid_611766 != nil:
    section.add "X-Amz-Security-Token", valid_611766
  var valid_611767 = header.getOrDefault("X-Amz-Algorithm")
  valid_611767 = validateParameter(valid_611767, JString, required = false,
                                 default = nil)
  if valid_611767 != nil:
    section.add "X-Amz-Algorithm", valid_611767
  var valid_611768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611768 = validateParameter(valid_611768, JString, required = false,
                                 default = nil)
  if valid_611768 != nil:
    section.add "X-Amz-SignedHeaders", valid_611768
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611769: Call_DescribeGroup_611756; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an Amazon QuickSight group's description and Amazon Resource Name (ARN). 
  ## 
  let valid = call_611769.validator(path, query, header, formData, body)
  let scheme = call_611769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611769.url(scheme.get, call_611769.host, call_611769.base,
                         call_611769.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611769, url, valid)

proc call*(call_611770: Call_DescribeGroup_611756; GroupName: string;
          AwsAccountId: string; Namespace: string): Recallable =
  ## describeGroup
  ## Returns an Amazon QuickSight group's description and Amazon Resource Name (ARN). 
  ##   GroupName: string (required)
  ##            : The name of the group that you want to describe.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_611771 = newJObject()
  add(path_611771, "GroupName", newJString(GroupName))
  add(path_611771, "AwsAccountId", newJString(AwsAccountId))
  add(path_611771, "Namespace", newJString(Namespace))
  result = call_611770.call(path_611771, nil, nil, nil, nil)

var describeGroup* = Call_DescribeGroup_611756(name: "describeGroup",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}",
    validator: validate_DescribeGroup_611757, base: "/", url: url_DescribeGroup_611758,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_611790 = ref object of OpenApiRestCall_610658
proc url_DeleteGroup_611792(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteGroup_611791(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611793 = path.getOrDefault("GroupName")
  valid_611793 = validateParameter(valid_611793, JString, required = true,
                                 default = nil)
  if valid_611793 != nil:
    section.add "GroupName", valid_611793
  var valid_611794 = path.getOrDefault("AwsAccountId")
  valid_611794 = validateParameter(valid_611794, JString, required = true,
                                 default = nil)
  if valid_611794 != nil:
    section.add "AwsAccountId", valid_611794
  var valid_611795 = path.getOrDefault("Namespace")
  valid_611795 = validateParameter(valid_611795, JString, required = true,
                                 default = nil)
  if valid_611795 != nil:
    section.add "Namespace", valid_611795
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
  var valid_611796 = header.getOrDefault("X-Amz-Signature")
  valid_611796 = validateParameter(valid_611796, JString, required = false,
                                 default = nil)
  if valid_611796 != nil:
    section.add "X-Amz-Signature", valid_611796
  var valid_611797 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611797 = validateParameter(valid_611797, JString, required = false,
                                 default = nil)
  if valid_611797 != nil:
    section.add "X-Amz-Content-Sha256", valid_611797
  var valid_611798 = header.getOrDefault("X-Amz-Date")
  valid_611798 = validateParameter(valid_611798, JString, required = false,
                                 default = nil)
  if valid_611798 != nil:
    section.add "X-Amz-Date", valid_611798
  var valid_611799 = header.getOrDefault("X-Amz-Credential")
  valid_611799 = validateParameter(valid_611799, JString, required = false,
                                 default = nil)
  if valid_611799 != nil:
    section.add "X-Amz-Credential", valid_611799
  var valid_611800 = header.getOrDefault("X-Amz-Security-Token")
  valid_611800 = validateParameter(valid_611800, JString, required = false,
                                 default = nil)
  if valid_611800 != nil:
    section.add "X-Amz-Security-Token", valid_611800
  var valid_611801 = header.getOrDefault("X-Amz-Algorithm")
  valid_611801 = validateParameter(valid_611801, JString, required = false,
                                 default = nil)
  if valid_611801 != nil:
    section.add "X-Amz-Algorithm", valid_611801
  var valid_611802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611802 = validateParameter(valid_611802, JString, required = false,
                                 default = nil)
  if valid_611802 != nil:
    section.add "X-Amz-SignedHeaders", valid_611802
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611803: Call_DeleteGroup_611790; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a user group from Amazon QuickSight. 
  ## 
  let valid = call_611803.validator(path, query, header, formData, body)
  let scheme = call_611803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611803.url(scheme.get, call_611803.host, call_611803.base,
                         call_611803.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611803, url, valid)

proc call*(call_611804: Call_DeleteGroup_611790; GroupName: string;
          AwsAccountId: string; Namespace: string): Recallable =
  ## deleteGroup
  ## Removes a user group from Amazon QuickSight. 
  ##   GroupName: string (required)
  ##            : The name of the group that you want to delete.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_611805 = newJObject()
  add(path_611805, "GroupName", newJString(GroupName))
  add(path_611805, "AwsAccountId", newJString(AwsAccountId))
  add(path_611805, "Namespace", newJString(Namespace))
  result = call_611804.call(path_611805, nil, nil, nil, nil)

var deleteGroup* = Call_DeleteGroup_611790(name: "deleteGroup",
                                        meth: HttpMethod.HttpDelete,
                                        host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}",
                                        validator: validate_DeleteGroup_611791,
                                        base: "/", url: url_DeleteGroup_611792,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIAMPolicyAssignment_611806 = ref object of OpenApiRestCall_610658
proc url_DeleteIAMPolicyAssignment_611808(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteIAMPolicyAssignment_611807(path: JsonNode; query: JsonNode;
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
  var valid_611809 = path.getOrDefault("AwsAccountId")
  valid_611809 = validateParameter(valid_611809, JString, required = true,
                                 default = nil)
  if valid_611809 != nil:
    section.add "AwsAccountId", valid_611809
  var valid_611810 = path.getOrDefault("Namespace")
  valid_611810 = validateParameter(valid_611810, JString, required = true,
                                 default = nil)
  if valid_611810 != nil:
    section.add "Namespace", valid_611810
  var valid_611811 = path.getOrDefault("AssignmentName")
  valid_611811 = validateParameter(valid_611811, JString, required = true,
                                 default = nil)
  if valid_611811 != nil:
    section.add "AssignmentName", valid_611811
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
  var valid_611812 = header.getOrDefault("X-Amz-Signature")
  valid_611812 = validateParameter(valid_611812, JString, required = false,
                                 default = nil)
  if valid_611812 != nil:
    section.add "X-Amz-Signature", valid_611812
  var valid_611813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611813 = validateParameter(valid_611813, JString, required = false,
                                 default = nil)
  if valid_611813 != nil:
    section.add "X-Amz-Content-Sha256", valid_611813
  var valid_611814 = header.getOrDefault("X-Amz-Date")
  valid_611814 = validateParameter(valid_611814, JString, required = false,
                                 default = nil)
  if valid_611814 != nil:
    section.add "X-Amz-Date", valid_611814
  var valid_611815 = header.getOrDefault("X-Amz-Credential")
  valid_611815 = validateParameter(valid_611815, JString, required = false,
                                 default = nil)
  if valid_611815 != nil:
    section.add "X-Amz-Credential", valid_611815
  var valid_611816 = header.getOrDefault("X-Amz-Security-Token")
  valid_611816 = validateParameter(valid_611816, JString, required = false,
                                 default = nil)
  if valid_611816 != nil:
    section.add "X-Amz-Security-Token", valid_611816
  var valid_611817 = header.getOrDefault("X-Amz-Algorithm")
  valid_611817 = validateParameter(valid_611817, JString, required = false,
                                 default = nil)
  if valid_611817 != nil:
    section.add "X-Amz-Algorithm", valid_611817
  var valid_611818 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611818 = validateParameter(valid_611818, JString, required = false,
                                 default = nil)
  if valid_611818 != nil:
    section.add "X-Amz-SignedHeaders", valid_611818
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611819: Call_DeleteIAMPolicyAssignment_611806; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing IAM policy assignment.
  ## 
  let valid = call_611819.validator(path, query, header, formData, body)
  let scheme = call_611819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611819.url(scheme.get, call_611819.host, call_611819.base,
                         call_611819.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611819, url, valid)

proc call*(call_611820: Call_DeleteIAMPolicyAssignment_611806;
          AwsAccountId: string; Namespace: string; AssignmentName: string): Recallable =
  ## deleteIAMPolicyAssignment
  ## Deletes an existing IAM policy assignment.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID where you want to delete the IAM policy assignment.
  ##   Namespace: string (required)
  ##            : The namespace that contains the assignment.
  ##   AssignmentName: string (required)
  ##                 : The name of the assignment. 
  var path_611821 = newJObject()
  add(path_611821, "AwsAccountId", newJString(AwsAccountId))
  add(path_611821, "Namespace", newJString(Namespace))
  add(path_611821, "AssignmentName", newJString(AssignmentName))
  result = call_611820.call(path_611821, nil, nil, nil, nil)

var deleteIAMPolicyAssignment* = Call_DeleteIAMPolicyAssignment_611806(
    name: "deleteIAMPolicyAssignment", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespace/{Namespace}/iam-policy-assignments/{AssignmentName}",
    validator: validate_DeleteIAMPolicyAssignment_611807, base: "/",
    url: url_DeleteIAMPolicyAssignment_611808,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_611838 = ref object of OpenApiRestCall_610658
proc url_UpdateUser_611840(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateUser_611839(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611841 = path.getOrDefault("AwsAccountId")
  valid_611841 = validateParameter(valid_611841, JString, required = true,
                                 default = nil)
  if valid_611841 != nil:
    section.add "AwsAccountId", valid_611841
  var valid_611842 = path.getOrDefault("Namespace")
  valid_611842 = validateParameter(valid_611842, JString, required = true,
                                 default = nil)
  if valid_611842 != nil:
    section.add "Namespace", valid_611842
  var valid_611843 = path.getOrDefault("UserName")
  valid_611843 = validateParameter(valid_611843, JString, required = true,
                                 default = nil)
  if valid_611843 != nil:
    section.add "UserName", valid_611843
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
  var valid_611844 = header.getOrDefault("X-Amz-Signature")
  valid_611844 = validateParameter(valid_611844, JString, required = false,
                                 default = nil)
  if valid_611844 != nil:
    section.add "X-Amz-Signature", valid_611844
  var valid_611845 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611845 = validateParameter(valid_611845, JString, required = false,
                                 default = nil)
  if valid_611845 != nil:
    section.add "X-Amz-Content-Sha256", valid_611845
  var valid_611846 = header.getOrDefault("X-Amz-Date")
  valid_611846 = validateParameter(valid_611846, JString, required = false,
                                 default = nil)
  if valid_611846 != nil:
    section.add "X-Amz-Date", valid_611846
  var valid_611847 = header.getOrDefault("X-Amz-Credential")
  valid_611847 = validateParameter(valid_611847, JString, required = false,
                                 default = nil)
  if valid_611847 != nil:
    section.add "X-Amz-Credential", valid_611847
  var valid_611848 = header.getOrDefault("X-Amz-Security-Token")
  valid_611848 = validateParameter(valid_611848, JString, required = false,
                                 default = nil)
  if valid_611848 != nil:
    section.add "X-Amz-Security-Token", valid_611848
  var valid_611849 = header.getOrDefault("X-Amz-Algorithm")
  valid_611849 = validateParameter(valid_611849, JString, required = false,
                                 default = nil)
  if valid_611849 != nil:
    section.add "X-Amz-Algorithm", valid_611849
  var valid_611850 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611850 = validateParameter(valid_611850, JString, required = false,
                                 default = nil)
  if valid_611850 != nil:
    section.add "X-Amz-SignedHeaders", valid_611850
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611852: Call_UpdateUser_611838; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Amazon QuickSight user.
  ## 
  let valid = call_611852.validator(path, query, header, formData, body)
  let scheme = call_611852.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611852.url(scheme.get, call_611852.host, call_611852.base,
                         call_611852.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611852, url, valid)

proc call*(call_611853: Call_UpdateUser_611838; AwsAccountId: string;
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
  var path_611854 = newJObject()
  var body_611855 = newJObject()
  add(path_611854, "AwsAccountId", newJString(AwsAccountId))
  add(path_611854, "Namespace", newJString(Namespace))
  add(path_611854, "UserName", newJString(UserName))
  if body != nil:
    body_611855 = body
  result = call_611853.call(path_611854, nil, nil, nil, body_611855)

var updateUser* = Call_UpdateUser_611838(name: "updateUser",
                                      meth: HttpMethod.HttpPut,
                                      host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}",
                                      validator: validate_UpdateUser_611839,
                                      base: "/", url: url_UpdateUser_611840,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_611822 = ref object of OpenApiRestCall_610658
proc url_DescribeUser_611824(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeUser_611823(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611825 = path.getOrDefault("AwsAccountId")
  valid_611825 = validateParameter(valid_611825, JString, required = true,
                                 default = nil)
  if valid_611825 != nil:
    section.add "AwsAccountId", valid_611825
  var valid_611826 = path.getOrDefault("Namespace")
  valid_611826 = validateParameter(valid_611826, JString, required = true,
                                 default = nil)
  if valid_611826 != nil:
    section.add "Namespace", valid_611826
  var valid_611827 = path.getOrDefault("UserName")
  valid_611827 = validateParameter(valid_611827, JString, required = true,
                                 default = nil)
  if valid_611827 != nil:
    section.add "UserName", valid_611827
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
  var valid_611828 = header.getOrDefault("X-Amz-Signature")
  valid_611828 = validateParameter(valid_611828, JString, required = false,
                                 default = nil)
  if valid_611828 != nil:
    section.add "X-Amz-Signature", valid_611828
  var valid_611829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611829 = validateParameter(valid_611829, JString, required = false,
                                 default = nil)
  if valid_611829 != nil:
    section.add "X-Amz-Content-Sha256", valid_611829
  var valid_611830 = header.getOrDefault("X-Amz-Date")
  valid_611830 = validateParameter(valid_611830, JString, required = false,
                                 default = nil)
  if valid_611830 != nil:
    section.add "X-Amz-Date", valid_611830
  var valid_611831 = header.getOrDefault("X-Amz-Credential")
  valid_611831 = validateParameter(valid_611831, JString, required = false,
                                 default = nil)
  if valid_611831 != nil:
    section.add "X-Amz-Credential", valid_611831
  var valid_611832 = header.getOrDefault("X-Amz-Security-Token")
  valid_611832 = validateParameter(valid_611832, JString, required = false,
                                 default = nil)
  if valid_611832 != nil:
    section.add "X-Amz-Security-Token", valid_611832
  var valid_611833 = header.getOrDefault("X-Amz-Algorithm")
  valid_611833 = validateParameter(valid_611833, JString, required = false,
                                 default = nil)
  if valid_611833 != nil:
    section.add "X-Amz-Algorithm", valid_611833
  var valid_611834 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611834 = validateParameter(valid_611834, JString, required = false,
                                 default = nil)
  if valid_611834 != nil:
    section.add "X-Amz-SignedHeaders", valid_611834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611835: Call_DescribeUser_611822; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a user, given the user name. 
  ## 
  let valid = call_611835.validator(path, query, header, formData, body)
  let scheme = call_611835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611835.url(scheme.get, call_611835.host, call_611835.base,
                         call_611835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611835, url, valid)

proc call*(call_611836: Call_DescribeUser_611822; AwsAccountId: string;
          Namespace: string; UserName: string): Recallable =
  ## describeUser
  ## Returns information about a user, given the user name. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: string (required)
  ##           : The name of the user that you want to describe.
  var path_611837 = newJObject()
  add(path_611837, "AwsAccountId", newJString(AwsAccountId))
  add(path_611837, "Namespace", newJString(Namespace))
  add(path_611837, "UserName", newJString(UserName))
  result = call_611836.call(path_611837, nil, nil, nil, nil)

var describeUser* = Call_DescribeUser_611822(name: "describeUser",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}",
    validator: validate_DescribeUser_611823, base: "/", url: url_DescribeUser_611824,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_611856 = ref object of OpenApiRestCall_610658
proc url_DeleteUser_611858(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteUser_611857(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611859 = path.getOrDefault("AwsAccountId")
  valid_611859 = validateParameter(valid_611859, JString, required = true,
                                 default = nil)
  if valid_611859 != nil:
    section.add "AwsAccountId", valid_611859
  var valid_611860 = path.getOrDefault("Namespace")
  valid_611860 = validateParameter(valid_611860, JString, required = true,
                                 default = nil)
  if valid_611860 != nil:
    section.add "Namespace", valid_611860
  var valid_611861 = path.getOrDefault("UserName")
  valid_611861 = validateParameter(valid_611861, JString, required = true,
                                 default = nil)
  if valid_611861 != nil:
    section.add "UserName", valid_611861
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
  var valid_611862 = header.getOrDefault("X-Amz-Signature")
  valid_611862 = validateParameter(valid_611862, JString, required = false,
                                 default = nil)
  if valid_611862 != nil:
    section.add "X-Amz-Signature", valid_611862
  var valid_611863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611863 = validateParameter(valid_611863, JString, required = false,
                                 default = nil)
  if valid_611863 != nil:
    section.add "X-Amz-Content-Sha256", valid_611863
  var valid_611864 = header.getOrDefault("X-Amz-Date")
  valid_611864 = validateParameter(valid_611864, JString, required = false,
                                 default = nil)
  if valid_611864 != nil:
    section.add "X-Amz-Date", valid_611864
  var valid_611865 = header.getOrDefault("X-Amz-Credential")
  valid_611865 = validateParameter(valid_611865, JString, required = false,
                                 default = nil)
  if valid_611865 != nil:
    section.add "X-Amz-Credential", valid_611865
  var valid_611866 = header.getOrDefault("X-Amz-Security-Token")
  valid_611866 = validateParameter(valid_611866, JString, required = false,
                                 default = nil)
  if valid_611866 != nil:
    section.add "X-Amz-Security-Token", valid_611866
  var valid_611867 = header.getOrDefault("X-Amz-Algorithm")
  valid_611867 = validateParameter(valid_611867, JString, required = false,
                                 default = nil)
  if valid_611867 != nil:
    section.add "X-Amz-Algorithm", valid_611867
  var valid_611868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611868 = validateParameter(valid_611868, JString, required = false,
                                 default = nil)
  if valid_611868 != nil:
    section.add "X-Amz-SignedHeaders", valid_611868
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611869: Call_DeleteUser_611856; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the Amazon QuickSight user that is associated with the identity of the AWS Identity and Access Management (IAM) user or role that's making the call. The IAM user isn't deleted as a result of this call. 
  ## 
  let valid = call_611869.validator(path, query, header, formData, body)
  let scheme = call_611869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611869.url(scheme.get, call_611869.host, call_611869.base,
                         call_611869.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611869, url, valid)

proc call*(call_611870: Call_DeleteUser_611856; AwsAccountId: string;
          Namespace: string; UserName: string): Recallable =
  ## deleteUser
  ## Deletes the Amazon QuickSight user that is associated with the identity of the AWS Identity and Access Management (IAM) user or role that's making the call. The IAM user isn't deleted as a result of this call. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: string (required)
  ##           : The name of the user that you want to delete.
  var path_611871 = newJObject()
  add(path_611871, "AwsAccountId", newJString(AwsAccountId))
  add(path_611871, "Namespace", newJString(Namespace))
  add(path_611871, "UserName", newJString(UserName))
  result = call_611870.call(path_611871, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_611856(name: "deleteUser",
                                      meth: HttpMethod.HttpDelete,
                                      host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}",
                                      validator: validate_DeleteUser_611857,
                                      base: "/", url: url_DeleteUser_611858,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserByPrincipalId_611872 = ref object of OpenApiRestCall_610658
proc url_DeleteUserByPrincipalId_611874(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteUserByPrincipalId_611873(path: JsonNode; query: JsonNode;
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
  var valid_611875 = path.getOrDefault("AwsAccountId")
  valid_611875 = validateParameter(valid_611875, JString, required = true,
                                 default = nil)
  if valid_611875 != nil:
    section.add "AwsAccountId", valid_611875
  var valid_611876 = path.getOrDefault("Namespace")
  valid_611876 = validateParameter(valid_611876, JString, required = true,
                                 default = nil)
  if valid_611876 != nil:
    section.add "Namespace", valid_611876
  var valid_611877 = path.getOrDefault("PrincipalId")
  valid_611877 = validateParameter(valid_611877, JString, required = true,
                                 default = nil)
  if valid_611877 != nil:
    section.add "PrincipalId", valid_611877
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
  var valid_611878 = header.getOrDefault("X-Amz-Signature")
  valid_611878 = validateParameter(valid_611878, JString, required = false,
                                 default = nil)
  if valid_611878 != nil:
    section.add "X-Amz-Signature", valid_611878
  var valid_611879 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611879 = validateParameter(valid_611879, JString, required = false,
                                 default = nil)
  if valid_611879 != nil:
    section.add "X-Amz-Content-Sha256", valid_611879
  var valid_611880 = header.getOrDefault("X-Amz-Date")
  valid_611880 = validateParameter(valid_611880, JString, required = false,
                                 default = nil)
  if valid_611880 != nil:
    section.add "X-Amz-Date", valid_611880
  var valid_611881 = header.getOrDefault("X-Amz-Credential")
  valid_611881 = validateParameter(valid_611881, JString, required = false,
                                 default = nil)
  if valid_611881 != nil:
    section.add "X-Amz-Credential", valid_611881
  var valid_611882 = header.getOrDefault("X-Amz-Security-Token")
  valid_611882 = validateParameter(valid_611882, JString, required = false,
                                 default = nil)
  if valid_611882 != nil:
    section.add "X-Amz-Security-Token", valid_611882
  var valid_611883 = header.getOrDefault("X-Amz-Algorithm")
  valid_611883 = validateParameter(valid_611883, JString, required = false,
                                 default = nil)
  if valid_611883 != nil:
    section.add "X-Amz-Algorithm", valid_611883
  var valid_611884 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611884 = validateParameter(valid_611884, JString, required = false,
                                 default = nil)
  if valid_611884 != nil:
    section.add "X-Amz-SignedHeaders", valid_611884
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611885: Call_DeleteUserByPrincipalId_611872; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a user identified by its principal ID. 
  ## 
  let valid = call_611885.validator(path, query, header, formData, body)
  let scheme = call_611885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611885.url(scheme.get, call_611885.host, call_611885.base,
                         call_611885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611885, url, valid)

proc call*(call_611886: Call_DeleteUserByPrincipalId_611872; AwsAccountId: string;
          Namespace: string; PrincipalId: string): Recallable =
  ## deleteUserByPrincipalId
  ## Deletes a user identified by its principal ID. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   PrincipalId: string (required)
  ##              : The principal ID of the user.
  var path_611887 = newJObject()
  add(path_611887, "AwsAccountId", newJString(AwsAccountId))
  add(path_611887, "Namespace", newJString(Namespace))
  add(path_611887, "PrincipalId", newJString(PrincipalId))
  result = call_611886.call(path_611887, nil, nil, nil, nil)

var deleteUserByPrincipalId* = Call_DeleteUserByPrincipalId_611872(
    name: "deleteUserByPrincipalId", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/user-principals/{PrincipalId}",
    validator: validate_DeleteUserByPrincipalId_611873, base: "/",
    url: url_DeleteUserByPrincipalId_611874, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDashboardPermissions_611903 = ref object of OpenApiRestCall_610658
proc url_UpdateDashboardPermissions_611905(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDashboardPermissions_611904(path: JsonNode; query: JsonNode;
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
  var valid_611906 = path.getOrDefault("AwsAccountId")
  valid_611906 = validateParameter(valid_611906, JString, required = true,
                                 default = nil)
  if valid_611906 != nil:
    section.add "AwsAccountId", valid_611906
  var valid_611907 = path.getOrDefault("DashboardId")
  valid_611907 = validateParameter(valid_611907, JString, required = true,
                                 default = nil)
  if valid_611907 != nil:
    section.add "DashboardId", valid_611907
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
  var valid_611908 = header.getOrDefault("X-Amz-Signature")
  valid_611908 = validateParameter(valid_611908, JString, required = false,
                                 default = nil)
  if valid_611908 != nil:
    section.add "X-Amz-Signature", valid_611908
  var valid_611909 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611909 = validateParameter(valid_611909, JString, required = false,
                                 default = nil)
  if valid_611909 != nil:
    section.add "X-Amz-Content-Sha256", valid_611909
  var valid_611910 = header.getOrDefault("X-Amz-Date")
  valid_611910 = validateParameter(valid_611910, JString, required = false,
                                 default = nil)
  if valid_611910 != nil:
    section.add "X-Amz-Date", valid_611910
  var valid_611911 = header.getOrDefault("X-Amz-Credential")
  valid_611911 = validateParameter(valid_611911, JString, required = false,
                                 default = nil)
  if valid_611911 != nil:
    section.add "X-Amz-Credential", valid_611911
  var valid_611912 = header.getOrDefault("X-Amz-Security-Token")
  valid_611912 = validateParameter(valid_611912, JString, required = false,
                                 default = nil)
  if valid_611912 != nil:
    section.add "X-Amz-Security-Token", valid_611912
  var valid_611913 = header.getOrDefault("X-Amz-Algorithm")
  valid_611913 = validateParameter(valid_611913, JString, required = false,
                                 default = nil)
  if valid_611913 != nil:
    section.add "X-Amz-Algorithm", valid_611913
  var valid_611914 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611914 = validateParameter(valid_611914, JString, required = false,
                                 default = nil)
  if valid_611914 != nil:
    section.add "X-Amz-SignedHeaders", valid_611914
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611916: Call_UpdateDashboardPermissions_611903; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates read and write permissions on a dashboard.
  ## 
  let valid = call_611916.validator(path, query, header, formData, body)
  let scheme = call_611916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611916.url(scheme.get, call_611916.host, call_611916.base,
                         call_611916.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611916, url, valid)

proc call*(call_611917: Call_UpdateDashboardPermissions_611903;
          AwsAccountId: string; body: JsonNode; DashboardId: string): Recallable =
  ## updateDashboardPermissions
  ## Updates read and write permissions on a dashboard.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard whose permissions you're updating.
  ##   body: JObject (required)
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  var path_611918 = newJObject()
  var body_611919 = newJObject()
  add(path_611918, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_611919 = body
  add(path_611918, "DashboardId", newJString(DashboardId))
  result = call_611917.call(path_611918, nil, nil, nil, body_611919)

var updateDashboardPermissions* = Call_UpdateDashboardPermissions_611903(
    name: "updateDashboardPermissions", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/permissions",
    validator: validate_UpdateDashboardPermissions_611904, base: "/",
    url: url_UpdateDashboardPermissions_611905,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDashboardPermissions_611888 = ref object of OpenApiRestCall_610658
proc url_DescribeDashboardPermissions_611890(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDashboardPermissions_611889(path: JsonNode; query: JsonNode;
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
  var valid_611891 = path.getOrDefault("AwsAccountId")
  valid_611891 = validateParameter(valid_611891, JString, required = true,
                                 default = nil)
  if valid_611891 != nil:
    section.add "AwsAccountId", valid_611891
  var valid_611892 = path.getOrDefault("DashboardId")
  valid_611892 = validateParameter(valid_611892, JString, required = true,
                                 default = nil)
  if valid_611892 != nil:
    section.add "DashboardId", valid_611892
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
  var valid_611893 = header.getOrDefault("X-Amz-Signature")
  valid_611893 = validateParameter(valid_611893, JString, required = false,
                                 default = nil)
  if valid_611893 != nil:
    section.add "X-Amz-Signature", valid_611893
  var valid_611894 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611894 = validateParameter(valid_611894, JString, required = false,
                                 default = nil)
  if valid_611894 != nil:
    section.add "X-Amz-Content-Sha256", valid_611894
  var valid_611895 = header.getOrDefault("X-Amz-Date")
  valid_611895 = validateParameter(valid_611895, JString, required = false,
                                 default = nil)
  if valid_611895 != nil:
    section.add "X-Amz-Date", valid_611895
  var valid_611896 = header.getOrDefault("X-Amz-Credential")
  valid_611896 = validateParameter(valid_611896, JString, required = false,
                                 default = nil)
  if valid_611896 != nil:
    section.add "X-Amz-Credential", valid_611896
  var valid_611897 = header.getOrDefault("X-Amz-Security-Token")
  valid_611897 = validateParameter(valid_611897, JString, required = false,
                                 default = nil)
  if valid_611897 != nil:
    section.add "X-Amz-Security-Token", valid_611897
  var valid_611898 = header.getOrDefault("X-Amz-Algorithm")
  valid_611898 = validateParameter(valid_611898, JString, required = false,
                                 default = nil)
  if valid_611898 != nil:
    section.add "X-Amz-Algorithm", valid_611898
  var valid_611899 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611899 = validateParameter(valid_611899, JString, required = false,
                                 default = nil)
  if valid_611899 != nil:
    section.add "X-Amz-SignedHeaders", valid_611899
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611900: Call_DescribeDashboardPermissions_611888; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes read and write permissions for a dashboard.
  ## 
  let valid = call_611900.validator(path, query, header, formData, body)
  let scheme = call_611900.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611900.url(scheme.get, call_611900.host, call_611900.base,
                         call_611900.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611900, url, valid)

proc call*(call_611901: Call_DescribeDashboardPermissions_611888;
          AwsAccountId: string; DashboardId: string): Recallable =
  ## describeDashboardPermissions
  ## Describes read and write permissions for a dashboard.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're describing permissions for.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard, also added to the IAM policy.
  var path_611902 = newJObject()
  add(path_611902, "AwsAccountId", newJString(AwsAccountId))
  add(path_611902, "DashboardId", newJString(DashboardId))
  result = call_611901.call(path_611902, nil, nil, nil, nil)

var describeDashboardPermissions* = Call_DescribeDashboardPermissions_611888(
    name: "describeDashboardPermissions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/permissions",
    validator: validate_DescribeDashboardPermissions_611889, base: "/",
    url: url_DescribeDashboardPermissions_611890,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSetPermissions_611935 = ref object of OpenApiRestCall_610658
proc url_UpdateDataSetPermissions_611937(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDataSetPermissions_611936(path: JsonNode; query: JsonNode;
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
  var valid_611938 = path.getOrDefault("AwsAccountId")
  valid_611938 = validateParameter(valid_611938, JString, required = true,
                                 default = nil)
  if valid_611938 != nil:
    section.add "AwsAccountId", valid_611938
  var valid_611939 = path.getOrDefault("DataSetId")
  valid_611939 = validateParameter(valid_611939, JString, required = true,
                                 default = nil)
  if valid_611939 != nil:
    section.add "DataSetId", valid_611939
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
  var valid_611940 = header.getOrDefault("X-Amz-Signature")
  valid_611940 = validateParameter(valid_611940, JString, required = false,
                                 default = nil)
  if valid_611940 != nil:
    section.add "X-Amz-Signature", valid_611940
  var valid_611941 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611941 = validateParameter(valid_611941, JString, required = false,
                                 default = nil)
  if valid_611941 != nil:
    section.add "X-Amz-Content-Sha256", valid_611941
  var valid_611942 = header.getOrDefault("X-Amz-Date")
  valid_611942 = validateParameter(valid_611942, JString, required = false,
                                 default = nil)
  if valid_611942 != nil:
    section.add "X-Amz-Date", valid_611942
  var valid_611943 = header.getOrDefault("X-Amz-Credential")
  valid_611943 = validateParameter(valid_611943, JString, required = false,
                                 default = nil)
  if valid_611943 != nil:
    section.add "X-Amz-Credential", valid_611943
  var valid_611944 = header.getOrDefault("X-Amz-Security-Token")
  valid_611944 = validateParameter(valid_611944, JString, required = false,
                                 default = nil)
  if valid_611944 != nil:
    section.add "X-Amz-Security-Token", valid_611944
  var valid_611945 = header.getOrDefault("X-Amz-Algorithm")
  valid_611945 = validateParameter(valid_611945, JString, required = false,
                                 default = nil)
  if valid_611945 != nil:
    section.add "X-Amz-Algorithm", valid_611945
  var valid_611946 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611946 = validateParameter(valid_611946, JString, required = false,
                                 default = nil)
  if valid_611946 != nil:
    section.add "X-Amz-SignedHeaders", valid_611946
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611948: Call_UpdateDataSetPermissions_611935; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
  ## 
  let valid = call_611948.validator(path, query, header, formData, body)
  let scheme = call_611948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611948.url(scheme.get, call_611948.host, call_611948.base,
                         call_611948.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611948, url, valid)

proc call*(call_611949: Call_UpdateDataSetPermissions_611935; AwsAccountId: string;
          DataSetId: string; body: JsonNode): Recallable =
  ## updateDataSetPermissions
  ## <p>Updates the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset whose permissions you want to update. This ID is unique per AWS Region for each AWS account.
  ##   body: JObject (required)
  var path_611950 = newJObject()
  var body_611951 = newJObject()
  add(path_611950, "AwsAccountId", newJString(AwsAccountId))
  add(path_611950, "DataSetId", newJString(DataSetId))
  if body != nil:
    body_611951 = body
  result = call_611949.call(path_611950, nil, nil, nil, body_611951)

var updateDataSetPermissions* = Call_UpdateDataSetPermissions_611935(
    name: "updateDataSetPermissions", meth: HttpMethod.HttpPost,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/permissions",
    validator: validate_UpdateDataSetPermissions_611936, base: "/",
    url: url_UpdateDataSetPermissions_611937, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSetPermissions_611920 = ref object of OpenApiRestCall_610658
proc url_DescribeDataSetPermissions_611922(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDataSetPermissions_611921(path: JsonNode; query: JsonNode;
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
  var valid_611923 = path.getOrDefault("AwsAccountId")
  valid_611923 = validateParameter(valid_611923, JString, required = true,
                                 default = nil)
  if valid_611923 != nil:
    section.add "AwsAccountId", valid_611923
  var valid_611924 = path.getOrDefault("DataSetId")
  valid_611924 = validateParameter(valid_611924, JString, required = true,
                                 default = nil)
  if valid_611924 != nil:
    section.add "DataSetId", valid_611924
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
  var valid_611925 = header.getOrDefault("X-Amz-Signature")
  valid_611925 = validateParameter(valid_611925, JString, required = false,
                                 default = nil)
  if valid_611925 != nil:
    section.add "X-Amz-Signature", valid_611925
  var valid_611926 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611926 = validateParameter(valid_611926, JString, required = false,
                                 default = nil)
  if valid_611926 != nil:
    section.add "X-Amz-Content-Sha256", valid_611926
  var valid_611927 = header.getOrDefault("X-Amz-Date")
  valid_611927 = validateParameter(valid_611927, JString, required = false,
                                 default = nil)
  if valid_611927 != nil:
    section.add "X-Amz-Date", valid_611927
  var valid_611928 = header.getOrDefault("X-Amz-Credential")
  valid_611928 = validateParameter(valid_611928, JString, required = false,
                                 default = nil)
  if valid_611928 != nil:
    section.add "X-Amz-Credential", valid_611928
  var valid_611929 = header.getOrDefault("X-Amz-Security-Token")
  valid_611929 = validateParameter(valid_611929, JString, required = false,
                                 default = nil)
  if valid_611929 != nil:
    section.add "X-Amz-Security-Token", valid_611929
  var valid_611930 = header.getOrDefault("X-Amz-Algorithm")
  valid_611930 = validateParameter(valid_611930, JString, required = false,
                                 default = nil)
  if valid_611930 != nil:
    section.add "X-Amz-Algorithm", valid_611930
  var valid_611931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611931 = validateParameter(valid_611931, JString, required = false,
                                 default = nil)
  if valid_611931 != nil:
    section.add "X-Amz-SignedHeaders", valid_611931
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611932: Call_DescribeDataSetPermissions_611920; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
  ## 
  let valid = call_611932.validator(path, query, header, formData, body)
  let scheme = call_611932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611932.url(scheme.get, call_611932.host, call_611932.base,
                         call_611932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611932, url, valid)

proc call*(call_611933: Call_DescribeDataSetPermissions_611920;
          AwsAccountId: string; DataSetId: string): Recallable =
  ## describeDataSetPermissions
  ## <p>Describes the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset that you want to create. This ID is unique per AWS Region for each AWS account.
  var path_611934 = newJObject()
  add(path_611934, "AwsAccountId", newJString(AwsAccountId))
  add(path_611934, "DataSetId", newJString(DataSetId))
  result = call_611933.call(path_611934, nil, nil, nil, nil)

var describeDataSetPermissions* = Call_DescribeDataSetPermissions_611920(
    name: "describeDataSetPermissions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/permissions",
    validator: validate_DescribeDataSetPermissions_611921, base: "/",
    url: url_DescribeDataSetPermissions_611922,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSourcePermissions_611967 = ref object of OpenApiRestCall_610658
proc url_UpdateDataSourcePermissions_611969(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDataSourcePermissions_611968(path: JsonNode; query: JsonNode;
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
  var valid_611970 = path.getOrDefault("DataSourceId")
  valid_611970 = validateParameter(valid_611970, JString, required = true,
                                 default = nil)
  if valid_611970 != nil:
    section.add "DataSourceId", valid_611970
  var valid_611971 = path.getOrDefault("AwsAccountId")
  valid_611971 = validateParameter(valid_611971, JString, required = true,
                                 default = nil)
  if valid_611971 != nil:
    section.add "AwsAccountId", valid_611971
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
  var valid_611972 = header.getOrDefault("X-Amz-Signature")
  valid_611972 = validateParameter(valid_611972, JString, required = false,
                                 default = nil)
  if valid_611972 != nil:
    section.add "X-Amz-Signature", valid_611972
  var valid_611973 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611973 = validateParameter(valid_611973, JString, required = false,
                                 default = nil)
  if valid_611973 != nil:
    section.add "X-Amz-Content-Sha256", valid_611973
  var valid_611974 = header.getOrDefault("X-Amz-Date")
  valid_611974 = validateParameter(valid_611974, JString, required = false,
                                 default = nil)
  if valid_611974 != nil:
    section.add "X-Amz-Date", valid_611974
  var valid_611975 = header.getOrDefault("X-Amz-Credential")
  valid_611975 = validateParameter(valid_611975, JString, required = false,
                                 default = nil)
  if valid_611975 != nil:
    section.add "X-Amz-Credential", valid_611975
  var valid_611976 = header.getOrDefault("X-Amz-Security-Token")
  valid_611976 = validateParameter(valid_611976, JString, required = false,
                                 default = nil)
  if valid_611976 != nil:
    section.add "X-Amz-Security-Token", valid_611976
  var valid_611977 = header.getOrDefault("X-Amz-Algorithm")
  valid_611977 = validateParameter(valid_611977, JString, required = false,
                                 default = nil)
  if valid_611977 != nil:
    section.add "X-Amz-Algorithm", valid_611977
  var valid_611978 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611978 = validateParameter(valid_611978, JString, required = false,
                                 default = nil)
  if valid_611978 != nil:
    section.add "X-Amz-SignedHeaders", valid_611978
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611980: Call_UpdateDataSourcePermissions_611967; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the permissions to a data source.
  ## 
  let valid = call_611980.validator(path, query, header, formData, body)
  let scheme = call_611980.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611980.url(scheme.get, call_611980.host, call_611980.base,
                         call_611980.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611980, url, valid)

proc call*(call_611981: Call_UpdateDataSourcePermissions_611967;
          DataSourceId: string; AwsAccountId: string; body: JsonNode): Recallable =
  ## updateDataSourcePermissions
  ## Updates the permissions to a data source.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account. 
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   body: JObject (required)
  var path_611982 = newJObject()
  var body_611983 = newJObject()
  add(path_611982, "DataSourceId", newJString(DataSourceId))
  add(path_611982, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_611983 = body
  result = call_611981.call(path_611982, nil, nil, nil, body_611983)

var updateDataSourcePermissions* = Call_UpdateDataSourcePermissions_611967(
    name: "updateDataSourcePermissions", meth: HttpMethod.HttpPost,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}/permissions",
    validator: validate_UpdateDataSourcePermissions_611968, base: "/",
    url: url_UpdateDataSourcePermissions_611969,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSourcePermissions_611952 = ref object of OpenApiRestCall_610658
proc url_DescribeDataSourcePermissions_611954(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeDataSourcePermissions_611953(path: JsonNode; query: JsonNode;
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
  var valid_611955 = path.getOrDefault("DataSourceId")
  valid_611955 = validateParameter(valid_611955, JString, required = true,
                                 default = nil)
  if valid_611955 != nil:
    section.add "DataSourceId", valid_611955
  var valid_611956 = path.getOrDefault("AwsAccountId")
  valid_611956 = validateParameter(valid_611956, JString, required = true,
                                 default = nil)
  if valid_611956 != nil:
    section.add "AwsAccountId", valid_611956
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
  var valid_611957 = header.getOrDefault("X-Amz-Signature")
  valid_611957 = validateParameter(valid_611957, JString, required = false,
                                 default = nil)
  if valid_611957 != nil:
    section.add "X-Amz-Signature", valid_611957
  var valid_611958 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611958 = validateParameter(valid_611958, JString, required = false,
                                 default = nil)
  if valid_611958 != nil:
    section.add "X-Amz-Content-Sha256", valid_611958
  var valid_611959 = header.getOrDefault("X-Amz-Date")
  valid_611959 = validateParameter(valid_611959, JString, required = false,
                                 default = nil)
  if valid_611959 != nil:
    section.add "X-Amz-Date", valid_611959
  var valid_611960 = header.getOrDefault("X-Amz-Credential")
  valid_611960 = validateParameter(valid_611960, JString, required = false,
                                 default = nil)
  if valid_611960 != nil:
    section.add "X-Amz-Credential", valid_611960
  var valid_611961 = header.getOrDefault("X-Amz-Security-Token")
  valid_611961 = validateParameter(valid_611961, JString, required = false,
                                 default = nil)
  if valid_611961 != nil:
    section.add "X-Amz-Security-Token", valid_611961
  var valid_611962 = header.getOrDefault("X-Amz-Algorithm")
  valid_611962 = validateParameter(valid_611962, JString, required = false,
                                 default = nil)
  if valid_611962 != nil:
    section.add "X-Amz-Algorithm", valid_611962
  var valid_611963 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611963 = validateParameter(valid_611963, JString, required = false,
                                 default = nil)
  if valid_611963 != nil:
    section.add "X-Amz-SignedHeaders", valid_611963
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611964: Call_DescribeDataSourcePermissions_611952; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the resource permissions for a data source.
  ## 
  let valid = call_611964.validator(path, query, header, formData, body)
  let scheme = call_611964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611964.url(scheme.get, call_611964.host, call_611964.base,
                         call_611964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611964, url, valid)

proc call*(call_611965: Call_DescribeDataSourcePermissions_611952;
          DataSourceId: string; AwsAccountId: string): Recallable =
  ## describeDataSourcePermissions
  ## Describes the resource permissions for a data source.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  var path_611966 = newJObject()
  add(path_611966, "DataSourceId", newJString(DataSourceId))
  add(path_611966, "AwsAccountId", newJString(AwsAccountId))
  result = call_611965.call(path_611966, nil, nil, nil, nil)

var describeDataSourcePermissions* = Call_DescribeDataSourcePermissions_611952(
    name: "describeDataSourcePermissions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}/permissions",
    validator: validate_DescribeDataSourcePermissions_611953, base: "/",
    url: url_DescribeDataSourcePermissions_611954,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIAMPolicyAssignment_612000 = ref object of OpenApiRestCall_610658
proc url_UpdateIAMPolicyAssignment_612002(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateIAMPolicyAssignment_612001(path: JsonNode; query: JsonNode;
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
  var valid_612003 = path.getOrDefault("AwsAccountId")
  valid_612003 = validateParameter(valid_612003, JString, required = true,
                                 default = nil)
  if valid_612003 != nil:
    section.add "AwsAccountId", valid_612003
  var valid_612004 = path.getOrDefault("Namespace")
  valid_612004 = validateParameter(valid_612004, JString, required = true,
                                 default = nil)
  if valid_612004 != nil:
    section.add "Namespace", valid_612004
  var valid_612005 = path.getOrDefault("AssignmentName")
  valid_612005 = validateParameter(valid_612005, JString, required = true,
                                 default = nil)
  if valid_612005 != nil:
    section.add "AssignmentName", valid_612005
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
  var valid_612006 = header.getOrDefault("X-Amz-Signature")
  valid_612006 = validateParameter(valid_612006, JString, required = false,
                                 default = nil)
  if valid_612006 != nil:
    section.add "X-Amz-Signature", valid_612006
  var valid_612007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612007 = validateParameter(valid_612007, JString, required = false,
                                 default = nil)
  if valid_612007 != nil:
    section.add "X-Amz-Content-Sha256", valid_612007
  var valid_612008 = header.getOrDefault("X-Amz-Date")
  valid_612008 = validateParameter(valid_612008, JString, required = false,
                                 default = nil)
  if valid_612008 != nil:
    section.add "X-Amz-Date", valid_612008
  var valid_612009 = header.getOrDefault("X-Amz-Credential")
  valid_612009 = validateParameter(valid_612009, JString, required = false,
                                 default = nil)
  if valid_612009 != nil:
    section.add "X-Amz-Credential", valid_612009
  var valid_612010 = header.getOrDefault("X-Amz-Security-Token")
  valid_612010 = validateParameter(valid_612010, JString, required = false,
                                 default = nil)
  if valid_612010 != nil:
    section.add "X-Amz-Security-Token", valid_612010
  var valid_612011 = header.getOrDefault("X-Amz-Algorithm")
  valid_612011 = validateParameter(valid_612011, JString, required = false,
                                 default = nil)
  if valid_612011 != nil:
    section.add "X-Amz-Algorithm", valid_612011
  var valid_612012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612012 = validateParameter(valid_612012, JString, required = false,
                                 default = nil)
  if valid_612012 != nil:
    section.add "X-Amz-SignedHeaders", valid_612012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612014: Call_UpdateIAMPolicyAssignment_612000; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing IAM policy assignment. This operation updates only the optional parameter or parameters that are specified in the request.
  ## 
  let valid = call_612014.validator(path, query, header, formData, body)
  let scheme = call_612014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612014.url(scheme.get, call_612014.host, call_612014.base,
                         call_612014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612014, url, valid)

proc call*(call_612015: Call_UpdateIAMPolicyAssignment_612000;
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
  var path_612016 = newJObject()
  var body_612017 = newJObject()
  add(path_612016, "AwsAccountId", newJString(AwsAccountId))
  add(path_612016, "Namespace", newJString(Namespace))
  add(path_612016, "AssignmentName", newJString(AssignmentName))
  if body != nil:
    body_612017 = body
  result = call_612015.call(path_612016, nil, nil, nil, body_612017)

var updateIAMPolicyAssignment* = Call_UpdateIAMPolicyAssignment_612000(
    name: "updateIAMPolicyAssignment", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/{AssignmentName}",
    validator: validate_UpdateIAMPolicyAssignment_612001, base: "/",
    url: url_UpdateIAMPolicyAssignment_612002,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIAMPolicyAssignment_611984 = ref object of OpenApiRestCall_610658
proc url_DescribeIAMPolicyAssignment_611986(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeIAMPolicyAssignment_611985(path: JsonNode; query: JsonNode;
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
  var valid_611987 = path.getOrDefault("AwsAccountId")
  valid_611987 = validateParameter(valid_611987, JString, required = true,
                                 default = nil)
  if valid_611987 != nil:
    section.add "AwsAccountId", valid_611987
  var valid_611988 = path.getOrDefault("Namespace")
  valid_611988 = validateParameter(valid_611988, JString, required = true,
                                 default = nil)
  if valid_611988 != nil:
    section.add "Namespace", valid_611988
  var valid_611989 = path.getOrDefault("AssignmentName")
  valid_611989 = validateParameter(valid_611989, JString, required = true,
                                 default = nil)
  if valid_611989 != nil:
    section.add "AssignmentName", valid_611989
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
  var valid_611990 = header.getOrDefault("X-Amz-Signature")
  valid_611990 = validateParameter(valid_611990, JString, required = false,
                                 default = nil)
  if valid_611990 != nil:
    section.add "X-Amz-Signature", valid_611990
  var valid_611991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611991 = validateParameter(valid_611991, JString, required = false,
                                 default = nil)
  if valid_611991 != nil:
    section.add "X-Amz-Content-Sha256", valid_611991
  var valid_611992 = header.getOrDefault("X-Amz-Date")
  valid_611992 = validateParameter(valid_611992, JString, required = false,
                                 default = nil)
  if valid_611992 != nil:
    section.add "X-Amz-Date", valid_611992
  var valid_611993 = header.getOrDefault("X-Amz-Credential")
  valid_611993 = validateParameter(valid_611993, JString, required = false,
                                 default = nil)
  if valid_611993 != nil:
    section.add "X-Amz-Credential", valid_611993
  var valid_611994 = header.getOrDefault("X-Amz-Security-Token")
  valid_611994 = validateParameter(valid_611994, JString, required = false,
                                 default = nil)
  if valid_611994 != nil:
    section.add "X-Amz-Security-Token", valid_611994
  var valid_611995 = header.getOrDefault("X-Amz-Algorithm")
  valid_611995 = validateParameter(valid_611995, JString, required = false,
                                 default = nil)
  if valid_611995 != nil:
    section.add "X-Amz-Algorithm", valid_611995
  var valid_611996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611996 = validateParameter(valid_611996, JString, required = false,
                                 default = nil)
  if valid_611996 != nil:
    section.add "X-Amz-SignedHeaders", valid_611996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611997: Call_DescribeIAMPolicyAssignment_611984; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing IAM policy assignment, as specified by the assignment name.
  ## 
  let valid = call_611997.validator(path, query, header, formData, body)
  let scheme = call_611997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611997.url(scheme.get, call_611997.host, call_611997.base,
                         call_611997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611997, url, valid)

proc call*(call_611998: Call_DescribeIAMPolicyAssignment_611984;
          AwsAccountId: string; Namespace: string; AssignmentName: string): Recallable =
  ## describeIAMPolicyAssignment
  ## Describes an existing IAM policy assignment, as specified by the assignment name.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the assignment that you want to describe.
  ##   Namespace: string (required)
  ##            : The namespace that contains the assignment.
  ##   AssignmentName: string (required)
  ##                 : The name of the assignment. 
  var path_611999 = newJObject()
  add(path_611999, "AwsAccountId", newJString(AwsAccountId))
  add(path_611999, "Namespace", newJString(Namespace))
  add(path_611999, "AssignmentName", newJString(AssignmentName))
  result = call_611998.call(path_611999, nil, nil, nil, nil)

var describeIAMPolicyAssignment* = Call_DescribeIAMPolicyAssignment_611984(
    name: "describeIAMPolicyAssignment", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/{AssignmentName}",
    validator: validate_DescribeIAMPolicyAssignment_611985, base: "/",
    url: url_DescribeIAMPolicyAssignment_611986,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTemplatePermissions_612033 = ref object of OpenApiRestCall_610658
proc url_UpdateTemplatePermissions_612035(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateTemplatePermissions_612034(path: JsonNode; query: JsonNode;
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
  var valid_612036 = path.getOrDefault("AwsAccountId")
  valid_612036 = validateParameter(valid_612036, JString, required = true,
                                 default = nil)
  if valid_612036 != nil:
    section.add "AwsAccountId", valid_612036
  var valid_612037 = path.getOrDefault("TemplateId")
  valid_612037 = validateParameter(valid_612037, JString, required = true,
                                 default = nil)
  if valid_612037 != nil:
    section.add "TemplateId", valid_612037
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
  var valid_612038 = header.getOrDefault("X-Amz-Signature")
  valid_612038 = validateParameter(valid_612038, JString, required = false,
                                 default = nil)
  if valid_612038 != nil:
    section.add "X-Amz-Signature", valid_612038
  var valid_612039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612039 = validateParameter(valid_612039, JString, required = false,
                                 default = nil)
  if valid_612039 != nil:
    section.add "X-Amz-Content-Sha256", valid_612039
  var valid_612040 = header.getOrDefault("X-Amz-Date")
  valid_612040 = validateParameter(valid_612040, JString, required = false,
                                 default = nil)
  if valid_612040 != nil:
    section.add "X-Amz-Date", valid_612040
  var valid_612041 = header.getOrDefault("X-Amz-Credential")
  valid_612041 = validateParameter(valid_612041, JString, required = false,
                                 default = nil)
  if valid_612041 != nil:
    section.add "X-Amz-Credential", valid_612041
  var valid_612042 = header.getOrDefault("X-Amz-Security-Token")
  valid_612042 = validateParameter(valid_612042, JString, required = false,
                                 default = nil)
  if valid_612042 != nil:
    section.add "X-Amz-Security-Token", valid_612042
  var valid_612043 = header.getOrDefault("X-Amz-Algorithm")
  valid_612043 = validateParameter(valid_612043, JString, required = false,
                                 default = nil)
  if valid_612043 != nil:
    section.add "X-Amz-Algorithm", valid_612043
  var valid_612044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612044 = validateParameter(valid_612044, JString, required = false,
                                 default = nil)
  if valid_612044 != nil:
    section.add "X-Amz-SignedHeaders", valid_612044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612046: Call_UpdateTemplatePermissions_612033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the resource permissions for a template.
  ## 
  let valid = call_612046.validator(path, query, header, formData, body)
  let scheme = call_612046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612046.url(scheme.get, call_612046.host, call_612046.base,
                         call_612046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612046, url, valid)

proc call*(call_612047: Call_UpdateTemplatePermissions_612033;
          AwsAccountId: string; TemplateId: string; body: JsonNode): Recallable =
  ## updateTemplatePermissions
  ## Updates the resource permissions for a template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  ##   body: JObject (required)
  var path_612048 = newJObject()
  var body_612049 = newJObject()
  add(path_612048, "AwsAccountId", newJString(AwsAccountId))
  add(path_612048, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_612049 = body
  result = call_612047.call(path_612048, nil, nil, nil, body_612049)

var updateTemplatePermissions* = Call_UpdateTemplatePermissions_612033(
    name: "updateTemplatePermissions", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}/permissions",
    validator: validate_UpdateTemplatePermissions_612034, base: "/",
    url: url_UpdateTemplatePermissions_612035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTemplatePermissions_612018 = ref object of OpenApiRestCall_610658
proc url_DescribeTemplatePermissions_612020(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeTemplatePermissions_612019(path: JsonNode; query: JsonNode;
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
  var valid_612021 = path.getOrDefault("AwsAccountId")
  valid_612021 = validateParameter(valid_612021, JString, required = true,
                                 default = nil)
  if valid_612021 != nil:
    section.add "AwsAccountId", valid_612021
  var valid_612022 = path.getOrDefault("TemplateId")
  valid_612022 = validateParameter(valid_612022, JString, required = true,
                                 default = nil)
  if valid_612022 != nil:
    section.add "TemplateId", valid_612022
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
  var valid_612023 = header.getOrDefault("X-Amz-Signature")
  valid_612023 = validateParameter(valid_612023, JString, required = false,
                                 default = nil)
  if valid_612023 != nil:
    section.add "X-Amz-Signature", valid_612023
  var valid_612024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612024 = validateParameter(valid_612024, JString, required = false,
                                 default = nil)
  if valid_612024 != nil:
    section.add "X-Amz-Content-Sha256", valid_612024
  var valid_612025 = header.getOrDefault("X-Amz-Date")
  valid_612025 = validateParameter(valid_612025, JString, required = false,
                                 default = nil)
  if valid_612025 != nil:
    section.add "X-Amz-Date", valid_612025
  var valid_612026 = header.getOrDefault("X-Amz-Credential")
  valid_612026 = validateParameter(valid_612026, JString, required = false,
                                 default = nil)
  if valid_612026 != nil:
    section.add "X-Amz-Credential", valid_612026
  var valid_612027 = header.getOrDefault("X-Amz-Security-Token")
  valid_612027 = validateParameter(valid_612027, JString, required = false,
                                 default = nil)
  if valid_612027 != nil:
    section.add "X-Amz-Security-Token", valid_612027
  var valid_612028 = header.getOrDefault("X-Amz-Algorithm")
  valid_612028 = validateParameter(valid_612028, JString, required = false,
                                 default = nil)
  if valid_612028 != nil:
    section.add "X-Amz-Algorithm", valid_612028
  var valid_612029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612029 = validateParameter(valid_612029, JString, required = false,
                                 default = nil)
  if valid_612029 != nil:
    section.add "X-Amz-SignedHeaders", valid_612029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612030: Call_DescribeTemplatePermissions_612018; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes read and write permissions on a template.
  ## 
  let valid = call_612030.validator(path, query, header, formData, body)
  let scheme = call_612030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612030.url(scheme.get, call_612030.host, call_612030.base,
                         call_612030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612030, url, valid)

proc call*(call_612031: Call_DescribeTemplatePermissions_612018;
          AwsAccountId: string; TemplateId: string): Recallable =
  ## describeTemplatePermissions
  ## Describes read and write permissions on a template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template that you're describing.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  var path_612032 = newJObject()
  add(path_612032, "AwsAccountId", newJString(AwsAccountId))
  add(path_612032, "TemplateId", newJString(TemplateId))
  result = call_612031.call(path_612032, nil, nil, nil, nil)

var describeTemplatePermissions* = Call_DescribeTemplatePermissions_612018(
    name: "describeTemplatePermissions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}/permissions",
    validator: validate_DescribeTemplatePermissions_612019, base: "/",
    url: url_DescribeTemplatePermissions_612020,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDashboardEmbedUrl_612050 = ref object of OpenApiRestCall_610658
proc url_GetDashboardEmbedUrl_612052(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDashboardEmbedUrl_612051(path: JsonNode; query: JsonNode;
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
  var valid_612053 = path.getOrDefault("AwsAccountId")
  valid_612053 = validateParameter(valid_612053, JString, required = true,
                                 default = nil)
  if valid_612053 != nil:
    section.add "AwsAccountId", valid_612053
  var valid_612054 = path.getOrDefault("DashboardId")
  valid_612054 = validateParameter(valid_612054, JString, required = true,
                                 default = nil)
  if valid_612054 != nil:
    section.add "DashboardId", valid_612054
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
  var valid_612055 = query.getOrDefault("reset-disabled")
  valid_612055 = validateParameter(valid_612055, JBool, required = false, default = nil)
  if valid_612055 != nil:
    section.add "reset-disabled", valid_612055
  var valid_612069 = query.getOrDefault("creds-type")
  valid_612069 = validateParameter(valid_612069, JString, required = true,
                                 default = newJString("IAM"))
  if valid_612069 != nil:
    section.add "creds-type", valid_612069
  var valid_612070 = query.getOrDefault("user-arn")
  valid_612070 = validateParameter(valid_612070, JString, required = false,
                                 default = nil)
  if valid_612070 != nil:
    section.add "user-arn", valid_612070
  var valid_612071 = query.getOrDefault("session-lifetime")
  valid_612071 = validateParameter(valid_612071, JInt, required = false, default = nil)
  if valid_612071 != nil:
    section.add "session-lifetime", valid_612071
  var valid_612072 = query.getOrDefault("undo-redo-disabled")
  valid_612072 = validateParameter(valid_612072, JBool, required = false, default = nil)
  if valid_612072 != nil:
    section.add "undo-redo-disabled", valid_612072
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612073 = header.getOrDefault("X-Amz-Signature")
  valid_612073 = validateParameter(valid_612073, JString, required = false,
                                 default = nil)
  if valid_612073 != nil:
    section.add "X-Amz-Signature", valid_612073
  var valid_612074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612074 = validateParameter(valid_612074, JString, required = false,
                                 default = nil)
  if valid_612074 != nil:
    section.add "X-Amz-Content-Sha256", valid_612074
  var valid_612075 = header.getOrDefault("X-Amz-Date")
  valid_612075 = validateParameter(valid_612075, JString, required = false,
                                 default = nil)
  if valid_612075 != nil:
    section.add "X-Amz-Date", valid_612075
  var valid_612076 = header.getOrDefault("X-Amz-Credential")
  valid_612076 = validateParameter(valid_612076, JString, required = false,
                                 default = nil)
  if valid_612076 != nil:
    section.add "X-Amz-Credential", valid_612076
  var valid_612077 = header.getOrDefault("X-Amz-Security-Token")
  valid_612077 = validateParameter(valid_612077, JString, required = false,
                                 default = nil)
  if valid_612077 != nil:
    section.add "X-Amz-Security-Token", valid_612077
  var valid_612078 = header.getOrDefault("X-Amz-Algorithm")
  valid_612078 = validateParameter(valid_612078, JString, required = false,
                                 default = nil)
  if valid_612078 != nil:
    section.add "X-Amz-Algorithm", valid_612078
  var valid_612079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612079 = validateParameter(valid_612079, JString, required = false,
                                 default = nil)
  if valid_612079 != nil:
    section.add "X-Amz-SignedHeaders", valid_612079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612080: Call_GetDashboardEmbedUrl_612050; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Generates a server-side embeddable URL and authorization code. For this process to work properly, first configure the dashboards and user permissions. For more information, see <a href="https://docs.aws.amazon.com/quicksight/latest/user/embedding-dashboards.html">Embedding Amazon QuickSight Dashboards</a> in the <i>Amazon QuickSight User Guide</i> or <a href="https://docs.aws.amazon.com/quicksight/latest/APIReference/qs-dev-embedded-dashboards.html">Embedding Amazon QuickSight Dashboards</a> in the <i>Amazon QuickSight API Reference</i>.</p> <p>Currently, you can use <code>GetDashboardEmbedURL</code> only from the server, not from the user’s browser.</p>
  ## 
  let valid = call_612080.validator(path, query, header, formData, body)
  let scheme = call_612080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612080.url(scheme.get, call_612080.host, call_612080.base,
                         call_612080.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612080, url, valid)

proc call*(call_612081: Call_GetDashboardEmbedUrl_612050; AwsAccountId: string;
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
  var path_612082 = newJObject()
  var query_612083 = newJObject()
  add(query_612083, "reset-disabled", newJBool(resetDisabled))
  add(path_612082, "AwsAccountId", newJString(AwsAccountId))
  add(query_612083, "creds-type", newJString(credsType))
  add(query_612083, "user-arn", newJString(userArn))
  add(path_612082, "DashboardId", newJString(DashboardId))
  add(query_612083, "session-lifetime", newJInt(sessionLifetime))
  add(query_612083, "undo-redo-disabled", newJBool(undoRedoDisabled))
  result = call_612081.call(path_612082, query_612083, nil, nil, nil)

var getDashboardEmbedUrl* = Call_GetDashboardEmbedUrl_612050(
    name: "getDashboardEmbedUrl", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/embed-url#creds-type",
    validator: validate_GetDashboardEmbedUrl_612051, base: "/",
    url: url_GetDashboardEmbedUrl_612052, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDashboardVersions_612084 = ref object of OpenApiRestCall_610658
proc url_ListDashboardVersions_612086(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDashboardVersions_612085(path: JsonNode; query: JsonNode;
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
  var valid_612087 = path.getOrDefault("AwsAccountId")
  valid_612087 = validateParameter(valid_612087, JString, required = true,
                                 default = nil)
  if valid_612087 != nil:
    section.add "AwsAccountId", valid_612087
  var valid_612088 = path.getOrDefault("DashboardId")
  valid_612088 = validateParameter(valid_612088, JString, required = true,
                                 default = nil)
  if valid_612088 != nil:
    section.add "DashboardId", valid_612088
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
  var valid_612089 = query.getOrDefault("MaxResults")
  valid_612089 = validateParameter(valid_612089, JString, required = false,
                                 default = nil)
  if valid_612089 != nil:
    section.add "MaxResults", valid_612089
  var valid_612090 = query.getOrDefault("NextToken")
  valid_612090 = validateParameter(valid_612090, JString, required = false,
                                 default = nil)
  if valid_612090 != nil:
    section.add "NextToken", valid_612090
  var valid_612091 = query.getOrDefault("max-results")
  valid_612091 = validateParameter(valid_612091, JInt, required = false, default = nil)
  if valid_612091 != nil:
    section.add "max-results", valid_612091
  var valid_612092 = query.getOrDefault("next-token")
  valid_612092 = validateParameter(valid_612092, JString, required = false,
                                 default = nil)
  if valid_612092 != nil:
    section.add "next-token", valid_612092
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612093 = header.getOrDefault("X-Amz-Signature")
  valid_612093 = validateParameter(valid_612093, JString, required = false,
                                 default = nil)
  if valid_612093 != nil:
    section.add "X-Amz-Signature", valid_612093
  var valid_612094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612094 = validateParameter(valid_612094, JString, required = false,
                                 default = nil)
  if valid_612094 != nil:
    section.add "X-Amz-Content-Sha256", valid_612094
  var valid_612095 = header.getOrDefault("X-Amz-Date")
  valid_612095 = validateParameter(valid_612095, JString, required = false,
                                 default = nil)
  if valid_612095 != nil:
    section.add "X-Amz-Date", valid_612095
  var valid_612096 = header.getOrDefault("X-Amz-Credential")
  valid_612096 = validateParameter(valid_612096, JString, required = false,
                                 default = nil)
  if valid_612096 != nil:
    section.add "X-Amz-Credential", valid_612096
  var valid_612097 = header.getOrDefault("X-Amz-Security-Token")
  valid_612097 = validateParameter(valid_612097, JString, required = false,
                                 default = nil)
  if valid_612097 != nil:
    section.add "X-Amz-Security-Token", valid_612097
  var valid_612098 = header.getOrDefault("X-Amz-Algorithm")
  valid_612098 = validateParameter(valid_612098, JString, required = false,
                                 default = nil)
  if valid_612098 != nil:
    section.add "X-Amz-Algorithm", valid_612098
  var valid_612099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612099 = validateParameter(valid_612099, JString, required = false,
                                 default = nil)
  if valid_612099 != nil:
    section.add "X-Amz-SignedHeaders", valid_612099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612100: Call_ListDashboardVersions_612084; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the versions of the dashboards in the QuickSight subscription.
  ## 
  let valid = call_612100.validator(path, query, header, formData, body)
  let scheme = call_612100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612100.url(scheme.get, call_612100.host, call_612100.base,
                         call_612100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612100, url, valid)

proc call*(call_612101: Call_ListDashboardVersions_612084; AwsAccountId: string;
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
  var path_612102 = newJObject()
  var query_612103 = newJObject()
  add(path_612102, "AwsAccountId", newJString(AwsAccountId))
  add(query_612103, "MaxResults", newJString(MaxResults))
  add(query_612103, "NextToken", newJString(NextToken))
  add(query_612103, "max-results", newJInt(maxResults))
  add(path_612102, "DashboardId", newJString(DashboardId))
  add(query_612103, "next-token", newJString(nextToken))
  result = call_612101.call(path_612102, query_612103, nil, nil, nil)

var listDashboardVersions* = Call_ListDashboardVersions_612084(
    name: "listDashboardVersions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/versions",
    validator: validate_ListDashboardVersions_612085, base: "/",
    url: url_ListDashboardVersions_612086, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDashboards_612104 = ref object of OpenApiRestCall_610658
proc url_ListDashboards_612106(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListDashboards_612105(path: JsonNode; query: JsonNode;
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
  var valid_612107 = path.getOrDefault("AwsAccountId")
  valid_612107 = validateParameter(valid_612107, JString, required = true,
                                 default = nil)
  if valid_612107 != nil:
    section.add "AwsAccountId", valid_612107
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
  var valid_612108 = query.getOrDefault("MaxResults")
  valid_612108 = validateParameter(valid_612108, JString, required = false,
                                 default = nil)
  if valid_612108 != nil:
    section.add "MaxResults", valid_612108
  var valid_612109 = query.getOrDefault("NextToken")
  valid_612109 = validateParameter(valid_612109, JString, required = false,
                                 default = nil)
  if valid_612109 != nil:
    section.add "NextToken", valid_612109
  var valid_612110 = query.getOrDefault("max-results")
  valid_612110 = validateParameter(valid_612110, JInt, required = false, default = nil)
  if valid_612110 != nil:
    section.add "max-results", valid_612110
  var valid_612111 = query.getOrDefault("next-token")
  valid_612111 = validateParameter(valid_612111, JString, required = false,
                                 default = nil)
  if valid_612111 != nil:
    section.add "next-token", valid_612111
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612112 = header.getOrDefault("X-Amz-Signature")
  valid_612112 = validateParameter(valid_612112, JString, required = false,
                                 default = nil)
  if valid_612112 != nil:
    section.add "X-Amz-Signature", valid_612112
  var valid_612113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612113 = validateParameter(valid_612113, JString, required = false,
                                 default = nil)
  if valid_612113 != nil:
    section.add "X-Amz-Content-Sha256", valid_612113
  var valid_612114 = header.getOrDefault("X-Amz-Date")
  valid_612114 = validateParameter(valid_612114, JString, required = false,
                                 default = nil)
  if valid_612114 != nil:
    section.add "X-Amz-Date", valid_612114
  var valid_612115 = header.getOrDefault("X-Amz-Credential")
  valid_612115 = validateParameter(valid_612115, JString, required = false,
                                 default = nil)
  if valid_612115 != nil:
    section.add "X-Amz-Credential", valid_612115
  var valid_612116 = header.getOrDefault("X-Amz-Security-Token")
  valid_612116 = validateParameter(valid_612116, JString, required = false,
                                 default = nil)
  if valid_612116 != nil:
    section.add "X-Amz-Security-Token", valid_612116
  var valid_612117 = header.getOrDefault("X-Amz-Algorithm")
  valid_612117 = validateParameter(valid_612117, JString, required = false,
                                 default = nil)
  if valid_612117 != nil:
    section.add "X-Amz-Algorithm", valid_612117
  var valid_612118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612118 = validateParameter(valid_612118, JString, required = false,
                                 default = nil)
  if valid_612118 != nil:
    section.add "X-Amz-SignedHeaders", valid_612118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612119: Call_ListDashboards_612104; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists dashboards in an AWS account.
  ## 
  let valid = call_612119.validator(path, query, header, formData, body)
  let scheme = call_612119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612119.url(scheme.get, call_612119.host, call_612119.base,
                         call_612119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612119, url, valid)

proc call*(call_612120: Call_ListDashboards_612104; AwsAccountId: string;
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
  var path_612121 = newJObject()
  var query_612122 = newJObject()
  add(path_612121, "AwsAccountId", newJString(AwsAccountId))
  add(query_612122, "MaxResults", newJString(MaxResults))
  add(query_612122, "NextToken", newJString(NextToken))
  add(query_612122, "max-results", newJInt(maxResults))
  add(query_612122, "next-token", newJString(nextToken))
  result = call_612120.call(path_612121, query_612122, nil, nil, nil)

var listDashboards* = Call_ListDashboards_612104(name: "listDashboards",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards",
    validator: validate_ListDashboards_612105, base: "/", url: url_ListDashboards_612106,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupMemberships_612123 = ref object of OpenApiRestCall_610658
proc url_ListGroupMemberships_612125(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListGroupMemberships_612124(path: JsonNode; query: JsonNode;
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
  var valid_612126 = path.getOrDefault("GroupName")
  valid_612126 = validateParameter(valid_612126, JString, required = true,
                                 default = nil)
  if valid_612126 != nil:
    section.add "GroupName", valid_612126
  var valid_612127 = path.getOrDefault("AwsAccountId")
  valid_612127 = validateParameter(valid_612127, JString, required = true,
                                 default = nil)
  if valid_612127 != nil:
    section.add "AwsAccountId", valid_612127
  var valid_612128 = path.getOrDefault("Namespace")
  valid_612128 = validateParameter(valid_612128, JString, required = true,
                                 default = nil)
  if valid_612128 != nil:
    section.add "Namespace", valid_612128
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return from this request.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_612129 = query.getOrDefault("max-results")
  valid_612129 = validateParameter(valid_612129, JInt, required = false, default = nil)
  if valid_612129 != nil:
    section.add "max-results", valid_612129
  var valid_612130 = query.getOrDefault("next-token")
  valid_612130 = validateParameter(valid_612130, JString, required = false,
                                 default = nil)
  if valid_612130 != nil:
    section.add "next-token", valid_612130
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612131 = header.getOrDefault("X-Amz-Signature")
  valid_612131 = validateParameter(valid_612131, JString, required = false,
                                 default = nil)
  if valid_612131 != nil:
    section.add "X-Amz-Signature", valid_612131
  var valid_612132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612132 = validateParameter(valid_612132, JString, required = false,
                                 default = nil)
  if valid_612132 != nil:
    section.add "X-Amz-Content-Sha256", valid_612132
  var valid_612133 = header.getOrDefault("X-Amz-Date")
  valid_612133 = validateParameter(valid_612133, JString, required = false,
                                 default = nil)
  if valid_612133 != nil:
    section.add "X-Amz-Date", valid_612133
  var valid_612134 = header.getOrDefault("X-Amz-Credential")
  valid_612134 = validateParameter(valid_612134, JString, required = false,
                                 default = nil)
  if valid_612134 != nil:
    section.add "X-Amz-Credential", valid_612134
  var valid_612135 = header.getOrDefault("X-Amz-Security-Token")
  valid_612135 = validateParameter(valid_612135, JString, required = false,
                                 default = nil)
  if valid_612135 != nil:
    section.add "X-Amz-Security-Token", valid_612135
  var valid_612136 = header.getOrDefault("X-Amz-Algorithm")
  valid_612136 = validateParameter(valid_612136, JString, required = false,
                                 default = nil)
  if valid_612136 != nil:
    section.add "X-Amz-Algorithm", valid_612136
  var valid_612137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612137 = validateParameter(valid_612137, JString, required = false,
                                 default = nil)
  if valid_612137 != nil:
    section.add "X-Amz-SignedHeaders", valid_612137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612138: Call_ListGroupMemberships_612123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists member users in a group.
  ## 
  let valid = call_612138.validator(path, query, header, formData, body)
  let scheme = call_612138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612138.url(scheme.get, call_612138.host, call_612138.base,
                         call_612138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612138, url, valid)

proc call*(call_612139: Call_ListGroupMemberships_612123; GroupName: string;
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
  var path_612140 = newJObject()
  var query_612141 = newJObject()
  add(path_612140, "GroupName", newJString(GroupName))
  add(path_612140, "AwsAccountId", newJString(AwsAccountId))
  add(path_612140, "Namespace", newJString(Namespace))
  add(query_612141, "max-results", newJInt(maxResults))
  add(query_612141, "next-token", newJString(nextToken))
  result = call_612139.call(path_612140, query_612141, nil, nil, nil)

var listGroupMemberships* = Call_ListGroupMemberships_612123(
    name: "listGroupMemberships", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members",
    validator: validate_ListGroupMemberships_612124, base: "/",
    url: url_ListGroupMemberships_612125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIAMPolicyAssignments_612142 = ref object of OpenApiRestCall_610658
proc url_ListIAMPolicyAssignments_612144(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListIAMPolicyAssignments_612143(path: JsonNode; query: JsonNode;
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
  var valid_612145 = path.getOrDefault("AwsAccountId")
  valid_612145 = validateParameter(valid_612145, JString, required = true,
                                 default = nil)
  if valid_612145 != nil:
    section.add "AwsAccountId", valid_612145
  var valid_612146 = path.getOrDefault("Namespace")
  valid_612146 = validateParameter(valid_612146, JString, required = true,
                                 default = nil)
  if valid_612146 != nil:
    section.add "Namespace", valid_612146
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_612147 = query.getOrDefault("max-results")
  valid_612147 = validateParameter(valid_612147, JInt, required = false, default = nil)
  if valid_612147 != nil:
    section.add "max-results", valid_612147
  var valid_612148 = query.getOrDefault("next-token")
  valid_612148 = validateParameter(valid_612148, JString, required = false,
                                 default = nil)
  if valid_612148 != nil:
    section.add "next-token", valid_612148
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612149 = header.getOrDefault("X-Amz-Signature")
  valid_612149 = validateParameter(valid_612149, JString, required = false,
                                 default = nil)
  if valid_612149 != nil:
    section.add "X-Amz-Signature", valid_612149
  var valid_612150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612150 = validateParameter(valid_612150, JString, required = false,
                                 default = nil)
  if valid_612150 != nil:
    section.add "X-Amz-Content-Sha256", valid_612150
  var valid_612151 = header.getOrDefault("X-Amz-Date")
  valid_612151 = validateParameter(valid_612151, JString, required = false,
                                 default = nil)
  if valid_612151 != nil:
    section.add "X-Amz-Date", valid_612151
  var valid_612152 = header.getOrDefault("X-Amz-Credential")
  valid_612152 = validateParameter(valid_612152, JString, required = false,
                                 default = nil)
  if valid_612152 != nil:
    section.add "X-Amz-Credential", valid_612152
  var valid_612153 = header.getOrDefault("X-Amz-Security-Token")
  valid_612153 = validateParameter(valid_612153, JString, required = false,
                                 default = nil)
  if valid_612153 != nil:
    section.add "X-Amz-Security-Token", valid_612153
  var valid_612154 = header.getOrDefault("X-Amz-Algorithm")
  valid_612154 = validateParameter(valid_612154, JString, required = false,
                                 default = nil)
  if valid_612154 != nil:
    section.add "X-Amz-Algorithm", valid_612154
  var valid_612155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612155 = validateParameter(valid_612155, JString, required = false,
                                 default = nil)
  if valid_612155 != nil:
    section.add "X-Amz-SignedHeaders", valid_612155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612157: Call_ListIAMPolicyAssignments_612142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists IAM policy assignments in the current Amazon QuickSight account.
  ## 
  let valid = call_612157.validator(path, query, header, formData, body)
  let scheme = call_612157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612157.url(scheme.get, call_612157.host, call_612157.base,
                         call_612157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612157, url, valid)

proc call*(call_612158: Call_ListIAMPolicyAssignments_612142; AwsAccountId: string;
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
  var path_612159 = newJObject()
  var query_612160 = newJObject()
  var body_612161 = newJObject()
  add(path_612159, "AwsAccountId", newJString(AwsAccountId))
  add(path_612159, "Namespace", newJString(Namespace))
  add(query_612160, "max-results", newJInt(maxResults))
  if body != nil:
    body_612161 = body
  add(query_612160, "next-token", newJString(nextToken))
  result = call_612158.call(path_612159, query_612160, nil, nil, body_612161)

var listIAMPolicyAssignments* = Call_ListIAMPolicyAssignments_612142(
    name: "listIAMPolicyAssignments", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments",
    validator: validate_ListIAMPolicyAssignments_612143, base: "/",
    url: url_ListIAMPolicyAssignments_612144, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIAMPolicyAssignmentsForUser_612162 = ref object of OpenApiRestCall_610658
proc url_ListIAMPolicyAssignmentsForUser_612164(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListIAMPolicyAssignmentsForUser_612163(path: JsonNode;
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
  var valid_612165 = path.getOrDefault("AwsAccountId")
  valid_612165 = validateParameter(valid_612165, JString, required = true,
                                 default = nil)
  if valid_612165 != nil:
    section.add "AwsAccountId", valid_612165
  var valid_612166 = path.getOrDefault("Namespace")
  valid_612166 = validateParameter(valid_612166, JString, required = true,
                                 default = nil)
  if valid_612166 != nil:
    section.add "Namespace", valid_612166
  var valid_612167 = path.getOrDefault("UserName")
  valid_612167 = validateParameter(valid_612167, JString, required = true,
                                 default = nil)
  if valid_612167 != nil:
    section.add "UserName", valid_612167
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_612168 = query.getOrDefault("max-results")
  valid_612168 = validateParameter(valid_612168, JInt, required = false, default = nil)
  if valid_612168 != nil:
    section.add "max-results", valid_612168
  var valid_612169 = query.getOrDefault("next-token")
  valid_612169 = validateParameter(valid_612169, JString, required = false,
                                 default = nil)
  if valid_612169 != nil:
    section.add "next-token", valid_612169
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612170 = header.getOrDefault("X-Amz-Signature")
  valid_612170 = validateParameter(valid_612170, JString, required = false,
                                 default = nil)
  if valid_612170 != nil:
    section.add "X-Amz-Signature", valid_612170
  var valid_612171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612171 = validateParameter(valid_612171, JString, required = false,
                                 default = nil)
  if valid_612171 != nil:
    section.add "X-Amz-Content-Sha256", valid_612171
  var valid_612172 = header.getOrDefault("X-Amz-Date")
  valid_612172 = validateParameter(valid_612172, JString, required = false,
                                 default = nil)
  if valid_612172 != nil:
    section.add "X-Amz-Date", valid_612172
  var valid_612173 = header.getOrDefault("X-Amz-Credential")
  valid_612173 = validateParameter(valid_612173, JString, required = false,
                                 default = nil)
  if valid_612173 != nil:
    section.add "X-Amz-Credential", valid_612173
  var valid_612174 = header.getOrDefault("X-Amz-Security-Token")
  valid_612174 = validateParameter(valid_612174, JString, required = false,
                                 default = nil)
  if valid_612174 != nil:
    section.add "X-Amz-Security-Token", valid_612174
  var valid_612175 = header.getOrDefault("X-Amz-Algorithm")
  valid_612175 = validateParameter(valid_612175, JString, required = false,
                                 default = nil)
  if valid_612175 != nil:
    section.add "X-Amz-Algorithm", valid_612175
  var valid_612176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612176 = validateParameter(valid_612176, JString, required = false,
                                 default = nil)
  if valid_612176 != nil:
    section.add "X-Amz-SignedHeaders", valid_612176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612177: Call_ListIAMPolicyAssignmentsForUser_612162;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists all the IAM policy assignments, including the Amazon Resource Names (ARNs) for the IAM policies assigned to the specified user and group or groups that the user belongs to.
  ## 
  let valid = call_612177.validator(path, query, header, formData, body)
  let scheme = call_612177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612177.url(scheme.get, call_612177.host, call_612177.base,
                         call_612177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612177, url, valid)

proc call*(call_612178: Call_ListIAMPolicyAssignmentsForUser_612162;
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
  var path_612179 = newJObject()
  var query_612180 = newJObject()
  add(path_612179, "AwsAccountId", newJString(AwsAccountId))
  add(path_612179, "Namespace", newJString(Namespace))
  add(path_612179, "UserName", newJString(UserName))
  add(query_612180, "max-results", newJInt(maxResults))
  add(query_612180, "next-token", newJString(nextToken))
  result = call_612178.call(path_612179, query_612180, nil, nil, nil)

var listIAMPolicyAssignmentsForUser* = Call_ListIAMPolicyAssignmentsForUser_612162(
    name: "listIAMPolicyAssignmentsForUser", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}/iam-policy-assignments",
    validator: validate_ListIAMPolicyAssignmentsForUser_612163, base: "/",
    url: url_ListIAMPolicyAssignmentsForUser_612164,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIngestions_612181 = ref object of OpenApiRestCall_610658
proc url_ListIngestions_612183(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListIngestions_612182(path: JsonNode; query: JsonNode;
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
  var valid_612184 = path.getOrDefault("AwsAccountId")
  valid_612184 = validateParameter(valid_612184, JString, required = true,
                                 default = nil)
  if valid_612184 != nil:
    section.add "AwsAccountId", valid_612184
  var valid_612185 = path.getOrDefault("DataSetId")
  valid_612185 = validateParameter(valid_612185, JString, required = true,
                                 default = nil)
  if valid_612185 != nil:
    section.add "DataSetId", valid_612185
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
  var valid_612186 = query.getOrDefault("MaxResults")
  valid_612186 = validateParameter(valid_612186, JString, required = false,
                                 default = nil)
  if valid_612186 != nil:
    section.add "MaxResults", valid_612186
  var valid_612187 = query.getOrDefault("NextToken")
  valid_612187 = validateParameter(valid_612187, JString, required = false,
                                 default = nil)
  if valid_612187 != nil:
    section.add "NextToken", valid_612187
  var valid_612188 = query.getOrDefault("max-results")
  valid_612188 = validateParameter(valid_612188, JInt, required = false, default = nil)
  if valid_612188 != nil:
    section.add "max-results", valid_612188
  var valid_612189 = query.getOrDefault("next-token")
  valid_612189 = validateParameter(valid_612189, JString, required = false,
                                 default = nil)
  if valid_612189 != nil:
    section.add "next-token", valid_612189
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612190 = header.getOrDefault("X-Amz-Signature")
  valid_612190 = validateParameter(valid_612190, JString, required = false,
                                 default = nil)
  if valid_612190 != nil:
    section.add "X-Amz-Signature", valid_612190
  var valid_612191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612191 = validateParameter(valid_612191, JString, required = false,
                                 default = nil)
  if valid_612191 != nil:
    section.add "X-Amz-Content-Sha256", valid_612191
  var valid_612192 = header.getOrDefault("X-Amz-Date")
  valid_612192 = validateParameter(valid_612192, JString, required = false,
                                 default = nil)
  if valid_612192 != nil:
    section.add "X-Amz-Date", valid_612192
  var valid_612193 = header.getOrDefault("X-Amz-Credential")
  valid_612193 = validateParameter(valid_612193, JString, required = false,
                                 default = nil)
  if valid_612193 != nil:
    section.add "X-Amz-Credential", valid_612193
  var valid_612194 = header.getOrDefault("X-Amz-Security-Token")
  valid_612194 = validateParameter(valid_612194, JString, required = false,
                                 default = nil)
  if valid_612194 != nil:
    section.add "X-Amz-Security-Token", valid_612194
  var valid_612195 = header.getOrDefault("X-Amz-Algorithm")
  valid_612195 = validateParameter(valid_612195, JString, required = false,
                                 default = nil)
  if valid_612195 != nil:
    section.add "X-Amz-Algorithm", valid_612195
  var valid_612196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612196 = validateParameter(valid_612196, JString, required = false,
                                 default = nil)
  if valid_612196 != nil:
    section.add "X-Amz-SignedHeaders", valid_612196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612197: Call_ListIngestions_612181; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the history of SPICE ingestions for a dataset.
  ## 
  let valid = call_612197.validator(path, query, header, formData, body)
  let scheme = call_612197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612197.url(scheme.get, call_612197.host, call_612197.base,
                         call_612197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612197, url, valid)

proc call*(call_612198: Call_ListIngestions_612181; AwsAccountId: string;
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
  var path_612199 = newJObject()
  var query_612200 = newJObject()
  add(path_612199, "AwsAccountId", newJString(AwsAccountId))
  add(query_612200, "MaxResults", newJString(MaxResults))
  add(query_612200, "NextToken", newJString(NextToken))
  add(path_612199, "DataSetId", newJString(DataSetId))
  add(query_612200, "max-results", newJInt(maxResults))
  add(query_612200, "next-token", newJString(nextToken))
  result = call_612198.call(path_612199, query_612200, nil, nil, nil)

var listIngestions* = Call_ListIngestions_612181(name: "listIngestions",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions",
    validator: validate_ListIngestions_612182, base: "/", url: url_ListIngestions_612183,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_612215 = ref object of OpenApiRestCall_610658
proc url_TagResource_612217(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_612216(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612218 = path.getOrDefault("ResourceArn")
  valid_612218 = validateParameter(valid_612218, JString, required = true,
                                 default = nil)
  if valid_612218 != nil:
    section.add "ResourceArn", valid_612218
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
  var valid_612219 = header.getOrDefault("X-Amz-Signature")
  valid_612219 = validateParameter(valid_612219, JString, required = false,
                                 default = nil)
  if valid_612219 != nil:
    section.add "X-Amz-Signature", valid_612219
  var valid_612220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612220 = validateParameter(valid_612220, JString, required = false,
                                 default = nil)
  if valid_612220 != nil:
    section.add "X-Amz-Content-Sha256", valid_612220
  var valid_612221 = header.getOrDefault("X-Amz-Date")
  valid_612221 = validateParameter(valid_612221, JString, required = false,
                                 default = nil)
  if valid_612221 != nil:
    section.add "X-Amz-Date", valid_612221
  var valid_612222 = header.getOrDefault("X-Amz-Credential")
  valid_612222 = validateParameter(valid_612222, JString, required = false,
                                 default = nil)
  if valid_612222 != nil:
    section.add "X-Amz-Credential", valid_612222
  var valid_612223 = header.getOrDefault("X-Amz-Security-Token")
  valid_612223 = validateParameter(valid_612223, JString, required = false,
                                 default = nil)
  if valid_612223 != nil:
    section.add "X-Amz-Security-Token", valid_612223
  var valid_612224 = header.getOrDefault("X-Amz-Algorithm")
  valid_612224 = validateParameter(valid_612224, JString, required = false,
                                 default = nil)
  if valid_612224 != nil:
    section.add "X-Amz-Algorithm", valid_612224
  var valid_612225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612225 = validateParameter(valid_612225, JString, required = false,
                                 default = nil)
  if valid_612225 != nil:
    section.add "X-Amz-SignedHeaders", valid_612225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612227: Call_TagResource_612215; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns one or more tags (key-value pairs) to the specified QuickSight resource. </p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. You can use the <code>TagResource</code> operation with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource. QuickSight supports tagging on data set, data source, dashboard, and template. </p> <p>Tagging for QuickSight works in a similar way to tagging for other AWS services, except for the following:</p> <ul> <li> <p>You can't use tags to track AWS costs for QuickSight. This restriction is because QuickSight costs are based on users and SPICE capacity, which aren't taggable resources.</p> </li> <li> <p>QuickSight doesn't currently support the Tag Editor for AWS Resource Groups.</p> </li> </ul>
  ## 
  let valid = call_612227.validator(path, query, header, formData, body)
  let scheme = call_612227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612227.url(scheme.get, call_612227.host, call_612227.base,
                         call_612227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612227, url, valid)

proc call*(call_612228: Call_TagResource_612215; ResourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Assigns one or more tags (key-value pairs) to the specified QuickSight resource. </p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. You can use the <code>TagResource</code> operation with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource. QuickSight supports tagging on data set, data source, dashboard, and template. </p> <p>Tagging for QuickSight works in a similar way to tagging for other AWS services, except for the following:</p> <ul> <li> <p>You can't use tags to track AWS costs for QuickSight. This restriction is because QuickSight costs are based on users and SPICE capacity, which aren't taggable resources.</p> </li> <li> <p>QuickSight doesn't currently support the Tag Editor for AWS Resource Groups.</p> </li> </ul>
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to tag.
  ##   body: JObject (required)
  var path_612229 = newJObject()
  var body_612230 = newJObject()
  add(path_612229, "ResourceArn", newJString(ResourceArn))
  if body != nil:
    body_612230 = body
  result = call_612228.call(path_612229, nil, nil, nil, body_612230)

var tagResource* = Call_TagResource_612215(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "quicksight.amazonaws.com",
                                        route: "/resources/{ResourceArn}/tags",
                                        validator: validate_TagResource_612216,
                                        base: "/", url: url_TagResource_612217,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_612201 = ref object of OpenApiRestCall_610658
proc url_ListTagsForResource_612203(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_612202(path: JsonNode; query: JsonNode;
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
  var valid_612204 = path.getOrDefault("ResourceArn")
  valid_612204 = validateParameter(valid_612204, JString, required = true,
                                 default = nil)
  if valid_612204 != nil:
    section.add "ResourceArn", valid_612204
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
  var valid_612205 = header.getOrDefault("X-Amz-Signature")
  valid_612205 = validateParameter(valid_612205, JString, required = false,
                                 default = nil)
  if valid_612205 != nil:
    section.add "X-Amz-Signature", valid_612205
  var valid_612206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612206 = validateParameter(valid_612206, JString, required = false,
                                 default = nil)
  if valid_612206 != nil:
    section.add "X-Amz-Content-Sha256", valid_612206
  var valid_612207 = header.getOrDefault("X-Amz-Date")
  valid_612207 = validateParameter(valid_612207, JString, required = false,
                                 default = nil)
  if valid_612207 != nil:
    section.add "X-Amz-Date", valid_612207
  var valid_612208 = header.getOrDefault("X-Amz-Credential")
  valid_612208 = validateParameter(valid_612208, JString, required = false,
                                 default = nil)
  if valid_612208 != nil:
    section.add "X-Amz-Credential", valid_612208
  var valid_612209 = header.getOrDefault("X-Amz-Security-Token")
  valid_612209 = validateParameter(valid_612209, JString, required = false,
                                 default = nil)
  if valid_612209 != nil:
    section.add "X-Amz-Security-Token", valid_612209
  var valid_612210 = header.getOrDefault("X-Amz-Algorithm")
  valid_612210 = validateParameter(valid_612210, JString, required = false,
                                 default = nil)
  if valid_612210 != nil:
    section.add "X-Amz-Algorithm", valid_612210
  var valid_612211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612211 = validateParameter(valid_612211, JString, required = false,
                                 default = nil)
  if valid_612211 != nil:
    section.add "X-Amz-SignedHeaders", valid_612211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612212: Call_ListTagsForResource_612201; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags assigned to a resource.
  ## 
  let valid = call_612212.validator(path, query, header, formData, body)
  let scheme = call_612212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612212.url(scheme.get, call_612212.host, call_612212.base,
                         call_612212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612212, url, valid)

proc call*(call_612213: Call_ListTagsForResource_612201; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags assigned to a resource.
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want a list of tags for.
  var path_612214 = newJObject()
  add(path_612214, "ResourceArn", newJString(ResourceArn))
  result = call_612213.call(path_612214, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_612201(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/resources/{ResourceArn}/tags",
    validator: validate_ListTagsForResource_612202, base: "/",
    url: url_ListTagsForResource_612203, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplateAliases_612231 = ref object of OpenApiRestCall_610658
proc url_ListTemplateAliases_612233(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTemplateAliases_612232(path: JsonNode; query: JsonNode;
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
  var valid_612234 = path.getOrDefault("AwsAccountId")
  valid_612234 = validateParameter(valid_612234, JString, required = true,
                                 default = nil)
  if valid_612234 != nil:
    section.add "AwsAccountId", valid_612234
  var valid_612235 = path.getOrDefault("TemplateId")
  valid_612235 = validateParameter(valid_612235, JString, required = true,
                                 default = nil)
  if valid_612235 != nil:
    section.add "TemplateId", valid_612235
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
  var valid_612236 = query.getOrDefault("MaxResults")
  valid_612236 = validateParameter(valid_612236, JString, required = false,
                                 default = nil)
  if valid_612236 != nil:
    section.add "MaxResults", valid_612236
  var valid_612237 = query.getOrDefault("NextToken")
  valid_612237 = validateParameter(valid_612237, JString, required = false,
                                 default = nil)
  if valid_612237 != nil:
    section.add "NextToken", valid_612237
  var valid_612238 = query.getOrDefault("max-result")
  valid_612238 = validateParameter(valid_612238, JInt, required = false, default = nil)
  if valid_612238 != nil:
    section.add "max-result", valid_612238
  var valid_612239 = query.getOrDefault("next-token")
  valid_612239 = validateParameter(valid_612239, JString, required = false,
                                 default = nil)
  if valid_612239 != nil:
    section.add "next-token", valid_612239
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612240 = header.getOrDefault("X-Amz-Signature")
  valid_612240 = validateParameter(valid_612240, JString, required = false,
                                 default = nil)
  if valid_612240 != nil:
    section.add "X-Amz-Signature", valid_612240
  var valid_612241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612241 = validateParameter(valid_612241, JString, required = false,
                                 default = nil)
  if valid_612241 != nil:
    section.add "X-Amz-Content-Sha256", valid_612241
  var valid_612242 = header.getOrDefault("X-Amz-Date")
  valid_612242 = validateParameter(valid_612242, JString, required = false,
                                 default = nil)
  if valid_612242 != nil:
    section.add "X-Amz-Date", valid_612242
  var valid_612243 = header.getOrDefault("X-Amz-Credential")
  valid_612243 = validateParameter(valid_612243, JString, required = false,
                                 default = nil)
  if valid_612243 != nil:
    section.add "X-Amz-Credential", valid_612243
  var valid_612244 = header.getOrDefault("X-Amz-Security-Token")
  valid_612244 = validateParameter(valid_612244, JString, required = false,
                                 default = nil)
  if valid_612244 != nil:
    section.add "X-Amz-Security-Token", valid_612244
  var valid_612245 = header.getOrDefault("X-Amz-Algorithm")
  valid_612245 = validateParameter(valid_612245, JString, required = false,
                                 default = nil)
  if valid_612245 != nil:
    section.add "X-Amz-Algorithm", valid_612245
  var valid_612246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612246 = validateParameter(valid_612246, JString, required = false,
                                 default = nil)
  if valid_612246 != nil:
    section.add "X-Amz-SignedHeaders", valid_612246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612247: Call_ListTemplateAliases_612231; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the aliases of a template.
  ## 
  let valid = call_612247.validator(path, query, header, formData, body)
  let scheme = call_612247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612247.url(scheme.get, call_612247.host, call_612247.base,
                         call_612247.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612247, url, valid)

proc call*(call_612248: Call_ListTemplateAliases_612231; AwsAccountId: string;
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
  var path_612249 = newJObject()
  var query_612250 = newJObject()
  add(path_612249, "AwsAccountId", newJString(AwsAccountId))
  add(query_612250, "MaxResults", newJString(MaxResults))
  add(query_612250, "NextToken", newJString(NextToken))
  add(query_612250, "max-result", newJInt(maxResult))
  add(path_612249, "TemplateId", newJString(TemplateId))
  add(query_612250, "next-token", newJString(nextToken))
  result = call_612248.call(path_612249, query_612250, nil, nil, nil)

var listTemplateAliases* = Call_ListTemplateAliases_612231(
    name: "listTemplateAliases", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases",
    validator: validate_ListTemplateAliases_612232, base: "/",
    url: url_ListTemplateAliases_612233, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplateVersions_612251 = ref object of OpenApiRestCall_610658
proc url_ListTemplateVersions_612253(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTemplateVersions_612252(path: JsonNode; query: JsonNode;
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
  var valid_612254 = path.getOrDefault("AwsAccountId")
  valid_612254 = validateParameter(valid_612254, JString, required = true,
                                 default = nil)
  if valid_612254 != nil:
    section.add "AwsAccountId", valid_612254
  var valid_612255 = path.getOrDefault("TemplateId")
  valid_612255 = validateParameter(valid_612255, JString, required = true,
                                 default = nil)
  if valid_612255 != nil:
    section.add "TemplateId", valid_612255
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
  var valid_612256 = query.getOrDefault("MaxResults")
  valid_612256 = validateParameter(valid_612256, JString, required = false,
                                 default = nil)
  if valid_612256 != nil:
    section.add "MaxResults", valid_612256
  var valid_612257 = query.getOrDefault("NextToken")
  valid_612257 = validateParameter(valid_612257, JString, required = false,
                                 default = nil)
  if valid_612257 != nil:
    section.add "NextToken", valid_612257
  var valid_612258 = query.getOrDefault("max-results")
  valid_612258 = validateParameter(valid_612258, JInt, required = false, default = nil)
  if valid_612258 != nil:
    section.add "max-results", valid_612258
  var valid_612259 = query.getOrDefault("next-token")
  valid_612259 = validateParameter(valid_612259, JString, required = false,
                                 default = nil)
  if valid_612259 != nil:
    section.add "next-token", valid_612259
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612260 = header.getOrDefault("X-Amz-Signature")
  valid_612260 = validateParameter(valid_612260, JString, required = false,
                                 default = nil)
  if valid_612260 != nil:
    section.add "X-Amz-Signature", valid_612260
  var valid_612261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612261 = validateParameter(valid_612261, JString, required = false,
                                 default = nil)
  if valid_612261 != nil:
    section.add "X-Amz-Content-Sha256", valid_612261
  var valid_612262 = header.getOrDefault("X-Amz-Date")
  valid_612262 = validateParameter(valid_612262, JString, required = false,
                                 default = nil)
  if valid_612262 != nil:
    section.add "X-Amz-Date", valid_612262
  var valid_612263 = header.getOrDefault("X-Amz-Credential")
  valid_612263 = validateParameter(valid_612263, JString, required = false,
                                 default = nil)
  if valid_612263 != nil:
    section.add "X-Amz-Credential", valid_612263
  var valid_612264 = header.getOrDefault("X-Amz-Security-Token")
  valid_612264 = validateParameter(valid_612264, JString, required = false,
                                 default = nil)
  if valid_612264 != nil:
    section.add "X-Amz-Security-Token", valid_612264
  var valid_612265 = header.getOrDefault("X-Amz-Algorithm")
  valid_612265 = validateParameter(valid_612265, JString, required = false,
                                 default = nil)
  if valid_612265 != nil:
    section.add "X-Amz-Algorithm", valid_612265
  var valid_612266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612266 = validateParameter(valid_612266, JString, required = false,
                                 default = nil)
  if valid_612266 != nil:
    section.add "X-Amz-SignedHeaders", valid_612266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612267: Call_ListTemplateVersions_612251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the versions of the templates in the current Amazon QuickSight account.
  ## 
  let valid = call_612267.validator(path, query, header, formData, body)
  let scheme = call_612267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612267.url(scheme.get, call_612267.host, call_612267.base,
                         call_612267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612267, url, valid)

proc call*(call_612268: Call_ListTemplateVersions_612251; AwsAccountId: string;
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
  var path_612269 = newJObject()
  var query_612270 = newJObject()
  add(path_612269, "AwsAccountId", newJString(AwsAccountId))
  add(query_612270, "MaxResults", newJString(MaxResults))
  add(query_612270, "NextToken", newJString(NextToken))
  add(query_612270, "max-results", newJInt(maxResults))
  add(path_612269, "TemplateId", newJString(TemplateId))
  add(query_612270, "next-token", newJString(nextToken))
  result = call_612268.call(path_612269, query_612270, nil, nil, nil)

var listTemplateVersions* = Call_ListTemplateVersions_612251(
    name: "listTemplateVersions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}/versions",
    validator: validate_ListTemplateVersions_612252, base: "/",
    url: url_ListTemplateVersions_612253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplates_612271 = ref object of OpenApiRestCall_610658
proc url_ListTemplates_612273(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTemplates_612272(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612274 = path.getOrDefault("AwsAccountId")
  valid_612274 = validateParameter(valid_612274, JString, required = true,
                                 default = nil)
  if valid_612274 != nil:
    section.add "AwsAccountId", valid_612274
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
  var valid_612275 = query.getOrDefault("MaxResults")
  valid_612275 = validateParameter(valid_612275, JString, required = false,
                                 default = nil)
  if valid_612275 != nil:
    section.add "MaxResults", valid_612275
  var valid_612276 = query.getOrDefault("NextToken")
  valid_612276 = validateParameter(valid_612276, JString, required = false,
                                 default = nil)
  if valid_612276 != nil:
    section.add "NextToken", valid_612276
  var valid_612277 = query.getOrDefault("max-result")
  valid_612277 = validateParameter(valid_612277, JInt, required = false, default = nil)
  if valid_612277 != nil:
    section.add "max-result", valid_612277
  var valid_612278 = query.getOrDefault("next-token")
  valid_612278 = validateParameter(valid_612278, JString, required = false,
                                 default = nil)
  if valid_612278 != nil:
    section.add "next-token", valid_612278
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612279 = header.getOrDefault("X-Amz-Signature")
  valid_612279 = validateParameter(valid_612279, JString, required = false,
                                 default = nil)
  if valid_612279 != nil:
    section.add "X-Amz-Signature", valid_612279
  var valid_612280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612280 = validateParameter(valid_612280, JString, required = false,
                                 default = nil)
  if valid_612280 != nil:
    section.add "X-Amz-Content-Sha256", valid_612280
  var valid_612281 = header.getOrDefault("X-Amz-Date")
  valid_612281 = validateParameter(valid_612281, JString, required = false,
                                 default = nil)
  if valid_612281 != nil:
    section.add "X-Amz-Date", valid_612281
  var valid_612282 = header.getOrDefault("X-Amz-Credential")
  valid_612282 = validateParameter(valid_612282, JString, required = false,
                                 default = nil)
  if valid_612282 != nil:
    section.add "X-Amz-Credential", valid_612282
  var valid_612283 = header.getOrDefault("X-Amz-Security-Token")
  valid_612283 = validateParameter(valid_612283, JString, required = false,
                                 default = nil)
  if valid_612283 != nil:
    section.add "X-Amz-Security-Token", valid_612283
  var valid_612284 = header.getOrDefault("X-Amz-Algorithm")
  valid_612284 = validateParameter(valid_612284, JString, required = false,
                                 default = nil)
  if valid_612284 != nil:
    section.add "X-Amz-Algorithm", valid_612284
  var valid_612285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612285 = validateParameter(valid_612285, JString, required = false,
                                 default = nil)
  if valid_612285 != nil:
    section.add "X-Amz-SignedHeaders", valid_612285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612286: Call_ListTemplates_612271; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the templates in the current Amazon QuickSight account.
  ## 
  let valid = call_612286.validator(path, query, header, formData, body)
  let scheme = call_612286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612286.url(scheme.get, call_612286.host, call_612286.base,
                         call_612286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612286, url, valid)

proc call*(call_612287: Call_ListTemplates_612271; AwsAccountId: string;
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
  var path_612288 = newJObject()
  var query_612289 = newJObject()
  add(path_612288, "AwsAccountId", newJString(AwsAccountId))
  add(query_612289, "MaxResults", newJString(MaxResults))
  add(query_612289, "NextToken", newJString(NextToken))
  add(query_612289, "max-result", newJInt(maxResult))
  add(query_612289, "next-token", newJString(nextToken))
  result = call_612287.call(path_612288, query_612289, nil, nil, nil)

var listTemplates* = Call_ListTemplates_612271(name: "listTemplates",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates",
    validator: validate_ListTemplates_612272, base: "/", url: url_ListTemplates_612273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserGroups_612290 = ref object of OpenApiRestCall_610658
proc url_ListUserGroups_612292(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListUserGroups_612291(path: JsonNode; query: JsonNode;
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
  var valid_612293 = path.getOrDefault("AwsAccountId")
  valid_612293 = validateParameter(valid_612293, JString, required = true,
                                 default = nil)
  if valid_612293 != nil:
    section.add "AwsAccountId", valid_612293
  var valid_612294 = path.getOrDefault("Namespace")
  valid_612294 = validateParameter(valid_612294, JString, required = true,
                                 default = nil)
  if valid_612294 != nil:
    section.add "Namespace", valid_612294
  var valid_612295 = path.getOrDefault("UserName")
  valid_612295 = validateParameter(valid_612295, JString, required = true,
                                 default = nil)
  if valid_612295 != nil:
    section.add "UserName", valid_612295
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return from this request.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_612296 = query.getOrDefault("max-results")
  valid_612296 = validateParameter(valid_612296, JInt, required = false, default = nil)
  if valid_612296 != nil:
    section.add "max-results", valid_612296
  var valid_612297 = query.getOrDefault("next-token")
  valid_612297 = validateParameter(valid_612297, JString, required = false,
                                 default = nil)
  if valid_612297 != nil:
    section.add "next-token", valid_612297
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612298 = header.getOrDefault("X-Amz-Signature")
  valid_612298 = validateParameter(valid_612298, JString, required = false,
                                 default = nil)
  if valid_612298 != nil:
    section.add "X-Amz-Signature", valid_612298
  var valid_612299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612299 = validateParameter(valid_612299, JString, required = false,
                                 default = nil)
  if valid_612299 != nil:
    section.add "X-Amz-Content-Sha256", valid_612299
  var valid_612300 = header.getOrDefault("X-Amz-Date")
  valid_612300 = validateParameter(valid_612300, JString, required = false,
                                 default = nil)
  if valid_612300 != nil:
    section.add "X-Amz-Date", valid_612300
  var valid_612301 = header.getOrDefault("X-Amz-Credential")
  valid_612301 = validateParameter(valid_612301, JString, required = false,
                                 default = nil)
  if valid_612301 != nil:
    section.add "X-Amz-Credential", valid_612301
  var valid_612302 = header.getOrDefault("X-Amz-Security-Token")
  valid_612302 = validateParameter(valid_612302, JString, required = false,
                                 default = nil)
  if valid_612302 != nil:
    section.add "X-Amz-Security-Token", valid_612302
  var valid_612303 = header.getOrDefault("X-Amz-Algorithm")
  valid_612303 = validateParameter(valid_612303, JString, required = false,
                                 default = nil)
  if valid_612303 != nil:
    section.add "X-Amz-Algorithm", valid_612303
  var valid_612304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612304 = validateParameter(valid_612304, JString, required = false,
                                 default = nil)
  if valid_612304 != nil:
    section.add "X-Amz-SignedHeaders", valid_612304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612305: Call_ListUserGroups_612290; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon QuickSight groups that an Amazon QuickSight user is a member of.
  ## 
  let valid = call_612305.validator(path, query, header, formData, body)
  let scheme = call_612305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612305.url(scheme.get, call_612305.host, call_612305.base,
                         call_612305.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612305, url, valid)

proc call*(call_612306: Call_ListUserGroups_612290; AwsAccountId: string;
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
  var path_612307 = newJObject()
  var query_612308 = newJObject()
  add(path_612307, "AwsAccountId", newJString(AwsAccountId))
  add(path_612307, "Namespace", newJString(Namespace))
  add(path_612307, "UserName", newJString(UserName))
  add(query_612308, "max-results", newJInt(maxResults))
  add(query_612308, "next-token", newJString(nextToken))
  result = call_612306.call(path_612307, query_612308, nil, nil, nil)

var listUserGroups* = Call_ListUserGroups_612290(name: "listUserGroups",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}/groups",
    validator: validate_ListUserGroups_612291, base: "/", url: url_ListUserGroups_612292,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterUser_612327 = ref object of OpenApiRestCall_610658
proc url_RegisterUser_612329(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RegisterUser_612328(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612330 = path.getOrDefault("AwsAccountId")
  valid_612330 = validateParameter(valid_612330, JString, required = true,
                                 default = nil)
  if valid_612330 != nil:
    section.add "AwsAccountId", valid_612330
  var valid_612331 = path.getOrDefault("Namespace")
  valid_612331 = validateParameter(valid_612331, JString, required = true,
                                 default = nil)
  if valid_612331 != nil:
    section.add "Namespace", valid_612331
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
  var valid_612332 = header.getOrDefault("X-Amz-Signature")
  valid_612332 = validateParameter(valid_612332, JString, required = false,
                                 default = nil)
  if valid_612332 != nil:
    section.add "X-Amz-Signature", valid_612332
  var valid_612333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612333 = validateParameter(valid_612333, JString, required = false,
                                 default = nil)
  if valid_612333 != nil:
    section.add "X-Amz-Content-Sha256", valid_612333
  var valid_612334 = header.getOrDefault("X-Amz-Date")
  valid_612334 = validateParameter(valid_612334, JString, required = false,
                                 default = nil)
  if valid_612334 != nil:
    section.add "X-Amz-Date", valid_612334
  var valid_612335 = header.getOrDefault("X-Amz-Credential")
  valid_612335 = validateParameter(valid_612335, JString, required = false,
                                 default = nil)
  if valid_612335 != nil:
    section.add "X-Amz-Credential", valid_612335
  var valid_612336 = header.getOrDefault("X-Amz-Security-Token")
  valid_612336 = validateParameter(valid_612336, JString, required = false,
                                 default = nil)
  if valid_612336 != nil:
    section.add "X-Amz-Security-Token", valid_612336
  var valid_612337 = header.getOrDefault("X-Amz-Algorithm")
  valid_612337 = validateParameter(valid_612337, JString, required = false,
                                 default = nil)
  if valid_612337 != nil:
    section.add "X-Amz-Algorithm", valid_612337
  var valid_612338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612338 = validateParameter(valid_612338, JString, required = false,
                                 default = nil)
  if valid_612338 != nil:
    section.add "X-Amz-SignedHeaders", valid_612338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_612340: Call_RegisterUser_612327; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Amazon QuickSight user, whose identity is associated with the AWS Identity and Access Management (IAM) identity or role specified in the request. 
  ## 
  let valid = call_612340.validator(path, query, header, formData, body)
  let scheme = call_612340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612340.url(scheme.get, call_612340.host, call_612340.base,
                         call_612340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612340, url, valid)

proc call*(call_612341: Call_RegisterUser_612327; AwsAccountId: string;
          Namespace: string; body: JsonNode): Recallable =
  ## registerUser
  ## Creates an Amazon QuickSight user, whose identity is associated with the AWS Identity and Access Management (IAM) identity or role specified in the request. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   body: JObject (required)
  var path_612342 = newJObject()
  var body_612343 = newJObject()
  add(path_612342, "AwsAccountId", newJString(AwsAccountId))
  add(path_612342, "Namespace", newJString(Namespace))
  if body != nil:
    body_612343 = body
  result = call_612341.call(path_612342, nil, nil, nil, body_612343)

var registerUser* = Call_RegisterUser_612327(name: "registerUser",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users",
    validator: validate_RegisterUser_612328, base: "/", url: url_RegisterUser_612329,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_612309 = ref object of OpenApiRestCall_610658
proc url_ListUsers_612311(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListUsers_612310(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612312 = path.getOrDefault("AwsAccountId")
  valid_612312 = validateParameter(valid_612312, JString, required = true,
                                 default = nil)
  if valid_612312 != nil:
    section.add "AwsAccountId", valid_612312
  var valid_612313 = path.getOrDefault("Namespace")
  valid_612313 = validateParameter(valid_612313, JString, required = true,
                                 default = nil)
  if valid_612313 != nil:
    section.add "Namespace", valid_612313
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return from this request.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_612314 = query.getOrDefault("max-results")
  valid_612314 = validateParameter(valid_612314, JInt, required = false, default = nil)
  if valid_612314 != nil:
    section.add "max-results", valid_612314
  var valid_612315 = query.getOrDefault("next-token")
  valid_612315 = validateParameter(valid_612315, JString, required = false,
                                 default = nil)
  if valid_612315 != nil:
    section.add "next-token", valid_612315
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612316 = header.getOrDefault("X-Amz-Signature")
  valid_612316 = validateParameter(valid_612316, JString, required = false,
                                 default = nil)
  if valid_612316 != nil:
    section.add "X-Amz-Signature", valid_612316
  var valid_612317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612317 = validateParameter(valid_612317, JString, required = false,
                                 default = nil)
  if valid_612317 != nil:
    section.add "X-Amz-Content-Sha256", valid_612317
  var valid_612318 = header.getOrDefault("X-Amz-Date")
  valid_612318 = validateParameter(valid_612318, JString, required = false,
                                 default = nil)
  if valid_612318 != nil:
    section.add "X-Amz-Date", valid_612318
  var valid_612319 = header.getOrDefault("X-Amz-Credential")
  valid_612319 = validateParameter(valid_612319, JString, required = false,
                                 default = nil)
  if valid_612319 != nil:
    section.add "X-Amz-Credential", valid_612319
  var valid_612320 = header.getOrDefault("X-Amz-Security-Token")
  valid_612320 = validateParameter(valid_612320, JString, required = false,
                                 default = nil)
  if valid_612320 != nil:
    section.add "X-Amz-Security-Token", valid_612320
  var valid_612321 = header.getOrDefault("X-Amz-Algorithm")
  valid_612321 = validateParameter(valid_612321, JString, required = false,
                                 default = nil)
  if valid_612321 != nil:
    section.add "X-Amz-Algorithm", valid_612321
  var valid_612322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612322 = validateParameter(valid_612322, JString, required = false,
                                 default = nil)
  if valid_612322 != nil:
    section.add "X-Amz-SignedHeaders", valid_612322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612323: Call_ListUsers_612309; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all of the Amazon QuickSight users belonging to this account. 
  ## 
  let valid = call_612323.validator(path, query, header, formData, body)
  let scheme = call_612323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612323.url(scheme.get, call_612323.host, call_612323.base,
                         call_612323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612323, url, valid)

proc call*(call_612324: Call_ListUsers_612309; AwsAccountId: string;
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
  var path_612325 = newJObject()
  var query_612326 = newJObject()
  add(path_612325, "AwsAccountId", newJString(AwsAccountId))
  add(path_612325, "Namespace", newJString(Namespace))
  add(query_612326, "max-results", newJInt(maxResults))
  add(query_612326, "next-token", newJString(nextToken))
  result = call_612324.call(path_612325, query_612326, nil, nil, nil)

var listUsers* = Call_ListUsers_612309(name: "listUsers", meth: HttpMethod.HttpGet,
                                    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users",
                                    validator: validate_ListUsers_612310,
                                    base: "/", url: url_ListUsers_612311,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_612344 = ref object of OpenApiRestCall_610658
proc url_UntagResource_612346(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_612345(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_612347 = path.getOrDefault("ResourceArn")
  valid_612347 = validateParameter(valid_612347, JString, required = true,
                                 default = nil)
  if valid_612347 != nil:
    section.add "ResourceArn", valid_612347
  result.add "path", section
  ## parameters in `query` object:
  ##   keys: JArray (required)
  ##       : The keys of the key-value pairs for the resource tag or tags assigned to the resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `keys` field"
  var valid_612348 = query.getOrDefault("keys")
  valid_612348 = validateParameter(valid_612348, JArray, required = true, default = nil)
  if valid_612348 != nil:
    section.add "keys", valid_612348
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_612349 = header.getOrDefault("X-Amz-Signature")
  valid_612349 = validateParameter(valid_612349, JString, required = false,
                                 default = nil)
  if valid_612349 != nil:
    section.add "X-Amz-Signature", valid_612349
  var valid_612350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612350 = validateParameter(valid_612350, JString, required = false,
                                 default = nil)
  if valid_612350 != nil:
    section.add "X-Amz-Content-Sha256", valid_612350
  var valid_612351 = header.getOrDefault("X-Amz-Date")
  valid_612351 = validateParameter(valid_612351, JString, required = false,
                                 default = nil)
  if valid_612351 != nil:
    section.add "X-Amz-Date", valid_612351
  var valid_612352 = header.getOrDefault("X-Amz-Credential")
  valid_612352 = validateParameter(valid_612352, JString, required = false,
                                 default = nil)
  if valid_612352 != nil:
    section.add "X-Amz-Credential", valid_612352
  var valid_612353 = header.getOrDefault("X-Amz-Security-Token")
  valid_612353 = validateParameter(valid_612353, JString, required = false,
                                 default = nil)
  if valid_612353 != nil:
    section.add "X-Amz-Security-Token", valid_612353
  var valid_612354 = header.getOrDefault("X-Amz-Algorithm")
  valid_612354 = validateParameter(valid_612354, JString, required = false,
                                 default = nil)
  if valid_612354 != nil:
    section.add "X-Amz-Algorithm", valid_612354
  var valid_612355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612355 = validateParameter(valid_612355, JString, required = false,
                                 default = nil)
  if valid_612355 != nil:
    section.add "X-Amz-SignedHeaders", valid_612355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612356: Call_UntagResource_612344; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag or tags from a resource.
  ## 
  let valid = call_612356.validator(path, query, header, formData, body)
  let scheme = call_612356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612356.url(scheme.get, call_612356.host, call_612356.base,
                         call_612356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612356, url, valid)

proc call*(call_612357: Call_UntagResource_612344; keys: JsonNode;
          ResourceArn: string): Recallable =
  ## untagResource
  ## Removes a tag or tags from a resource.
  ##   keys: JArray (required)
  ##       : The keys of the key-value pairs for the resource tag or tags assigned to the resource.
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to untag.
  var path_612358 = newJObject()
  var query_612359 = newJObject()
  if keys != nil:
    query_612359.add "keys", keys
  add(path_612358, "ResourceArn", newJString(ResourceArn))
  result = call_612357.call(path_612358, query_612359, nil, nil, nil)

var untagResource* = Call_UntagResource_612344(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/resources/{ResourceArn}/tags#keys",
    validator: validate_UntagResource_612345, base: "/", url: url_UntagResource_612346,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDashboardPublishedVersion_612360 = ref object of OpenApiRestCall_610658
proc url_UpdateDashboardPublishedVersion_612362(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateDashboardPublishedVersion_612361(path: JsonNode;
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
  var valid_612363 = path.getOrDefault("AwsAccountId")
  valid_612363 = validateParameter(valid_612363, JString, required = true,
                                 default = nil)
  if valid_612363 != nil:
    section.add "AwsAccountId", valid_612363
  var valid_612364 = path.getOrDefault("VersionNumber")
  valid_612364 = validateParameter(valid_612364, JInt, required = true, default = nil)
  if valid_612364 != nil:
    section.add "VersionNumber", valid_612364
  var valid_612365 = path.getOrDefault("DashboardId")
  valid_612365 = validateParameter(valid_612365, JString, required = true,
                                 default = nil)
  if valid_612365 != nil:
    section.add "DashboardId", valid_612365
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
  var valid_612366 = header.getOrDefault("X-Amz-Signature")
  valid_612366 = validateParameter(valid_612366, JString, required = false,
                                 default = nil)
  if valid_612366 != nil:
    section.add "X-Amz-Signature", valid_612366
  var valid_612367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_612367 = validateParameter(valid_612367, JString, required = false,
                                 default = nil)
  if valid_612367 != nil:
    section.add "X-Amz-Content-Sha256", valid_612367
  var valid_612368 = header.getOrDefault("X-Amz-Date")
  valid_612368 = validateParameter(valid_612368, JString, required = false,
                                 default = nil)
  if valid_612368 != nil:
    section.add "X-Amz-Date", valid_612368
  var valid_612369 = header.getOrDefault("X-Amz-Credential")
  valid_612369 = validateParameter(valid_612369, JString, required = false,
                                 default = nil)
  if valid_612369 != nil:
    section.add "X-Amz-Credential", valid_612369
  var valid_612370 = header.getOrDefault("X-Amz-Security-Token")
  valid_612370 = validateParameter(valid_612370, JString, required = false,
                                 default = nil)
  if valid_612370 != nil:
    section.add "X-Amz-Security-Token", valid_612370
  var valid_612371 = header.getOrDefault("X-Amz-Algorithm")
  valid_612371 = validateParameter(valid_612371, JString, required = false,
                                 default = nil)
  if valid_612371 != nil:
    section.add "X-Amz-Algorithm", valid_612371
  var valid_612372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_612372 = validateParameter(valid_612372, JString, required = false,
                                 default = nil)
  if valid_612372 != nil:
    section.add "X-Amz-SignedHeaders", valid_612372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_612373: Call_UpdateDashboardPublishedVersion_612360;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the published version of a dashboard.
  ## 
  let valid = call_612373.validator(path, query, header, formData, body)
  let scheme = call_612373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_612373.url(scheme.get, call_612373.host, call_612373.base,
                         call_612373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_612373, url, valid)

proc call*(call_612374: Call_UpdateDashboardPublishedVersion_612360;
          AwsAccountId: string; VersionNumber: int; DashboardId: string): Recallable =
  ## updateDashboardPublishedVersion
  ## Updates the published version of a dashboard.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're updating.
  ##   VersionNumber: int (required)
  ##                : The version number of the dashboard.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  var path_612375 = newJObject()
  add(path_612375, "AwsAccountId", newJString(AwsAccountId))
  add(path_612375, "VersionNumber", newJInt(VersionNumber))
  add(path_612375, "DashboardId", newJString(DashboardId))
  result = call_612374.call(path_612375, nil, nil, nil, nil)

var updateDashboardPublishedVersion* = Call_UpdateDashboardPublishedVersion_612360(
    name: "updateDashboardPublishedVersion", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/versions/{VersionNumber}",
    validator: validate_UpdateDashboardPublishedVersion_612361, base: "/",
    url: url_UpdateDashboardPublishedVersion_612362,
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
