
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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  Call_CreateIngestion_613268 = ref object of OpenApiRestCall_612658
proc url_CreateIngestion_613270(protocol: Scheme; host: string; base: string;
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

proc validate_CreateIngestion_613269(path: JsonNode; query: JsonNode;
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
  var valid_613271 = path.getOrDefault("AwsAccountId")
  valid_613271 = validateParameter(valid_613271, JString, required = true,
                                 default = nil)
  if valid_613271 != nil:
    section.add "AwsAccountId", valid_613271
  var valid_613272 = path.getOrDefault("DataSetId")
  valid_613272 = validateParameter(valid_613272, JString, required = true,
                                 default = nil)
  if valid_613272 != nil:
    section.add "DataSetId", valid_613272
  var valid_613273 = path.getOrDefault("IngestionId")
  valid_613273 = validateParameter(valid_613273, JString, required = true,
                                 default = nil)
  if valid_613273 != nil:
    section.add "IngestionId", valid_613273
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
  var valid_613274 = header.getOrDefault("X-Amz-Signature")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Signature", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Content-Sha256", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-Date")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Date", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-Credential")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Credential", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-Security-Token")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-Security-Token", valid_613278
  var valid_613279 = header.getOrDefault("X-Amz-Algorithm")
  valid_613279 = validateParameter(valid_613279, JString, required = false,
                                 default = nil)
  if valid_613279 != nil:
    section.add "X-Amz-Algorithm", valid_613279
  var valid_613280 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613280 = validateParameter(valid_613280, JString, required = false,
                                 default = nil)
  if valid_613280 != nil:
    section.add "X-Amz-SignedHeaders", valid_613280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613281: Call_CreateIngestion_613268; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates and starts a new SPICE ingestion on a dataset</p> <p>Any ingestions operating on tagged datasets inherit the same tags automatically for use in access control. For an example, see <a href="https://aws.example.com/premiumsupport/knowledge-center/iam-ec2-resource-tags/">How do I create an IAM policy to control access to Amazon EC2 resources using tags?</a> in the AWS Knowledge Center. Tags are visible on the tagged dataset, but not on the ingestion resource.</p>
  ## 
  let valid = call_613281.validator(path, query, header, formData, body)
  let scheme = call_613281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613281.url(scheme.get, call_613281.host, call_613281.base,
                         call_613281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613281, url, valid)

proc call*(call_613282: Call_CreateIngestion_613268; AwsAccountId: string;
          DataSetId: string; IngestionId: string): Recallable =
  ## createIngestion
  ## <p>Creates and starts a new SPICE ingestion on a dataset</p> <p>Any ingestions operating on tagged datasets inherit the same tags automatically for use in access control. For an example, see <a href="https://aws.example.com/premiumsupport/knowledge-center/iam-ec2-resource-tags/">How do I create an IAM policy to control access to Amazon EC2 resources using tags?</a> in the AWS Knowledge Center. Tags are visible on the tagged dataset, but not on the ingestion resource.</p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   IngestionId: string (required)
  ##              : An ID for the ingestion.
  var path_613283 = newJObject()
  add(path_613283, "AwsAccountId", newJString(AwsAccountId))
  add(path_613283, "DataSetId", newJString(DataSetId))
  add(path_613283, "IngestionId", newJString(IngestionId))
  result = call_613282.call(path_613283, nil, nil, nil, nil)

var createIngestion* = Call_CreateIngestion_613268(name: "createIngestion",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}",
    validator: validate_CreateIngestion_613269, base: "/", url: url_CreateIngestion_613270,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIngestion_612996 = ref object of OpenApiRestCall_612658
proc url_DescribeIngestion_612998(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeIngestion_612997(path: JsonNode; query: JsonNode;
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
  var valid_613124 = path.getOrDefault("AwsAccountId")
  valid_613124 = validateParameter(valid_613124, JString, required = true,
                                 default = nil)
  if valid_613124 != nil:
    section.add "AwsAccountId", valid_613124
  var valid_613125 = path.getOrDefault("DataSetId")
  valid_613125 = validateParameter(valid_613125, JString, required = true,
                                 default = nil)
  if valid_613125 != nil:
    section.add "DataSetId", valid_613125
  var valid_613126 = path.getOrDefault("IngestionId")
  valid_613126 = validateParameter(valid_613126, JString, required = true,
                                 default = nil)
  if valid_613126 != nil:
    section.add "IngestionId", valid_613126
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
  var valid_613127 = header.getOrDefault("X-Amz-Signature")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "X-Amz-Signature", valid_613127
  var valid_613128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613128 = validateParameter(valid_613128, JString, required = false,
                                 default = nil)
  if valid_613128 != nil:
    section.add "X-Amz-Content-Sha256", valid_613128
  var valid_613129 = header.getOrDefault("X-Amz-Date")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Date", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-Credential")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-Credential", valid_613130
  var valid_613131 = header.getOrDefault("X-Amz-Security-Token")
  valid_613131 = validateParameter(valid_613131, JString, required = false,
                                 default = nil)
  if valid_613131 != nil:
    section.add "X-Amz-Security-Token", valid_613131
  var valid_613132 = header.getOrDefault("X-Amz-Algorithm")
  valid_613132 = validateParameter(valid_613132, JString, required = false,
                                 default = nil)
  if valid_613132 != nil:
    section.add "X-Amz-Algorithm", valid_613132
  var valid_613133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613133 = validateParameter(valid_613133, JString, required = false,
                                 default = nil)
  if valid_613133 != nil:
    section.add "X-Amz-SignedHeaders", valid_613133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613156: Call_DescribeIngestion_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a SPICE ingestion.
  ## 
  let valid = call_613156.validator(path, query, header, formData, body)
  let scheme = call_613156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613156.url(scheme.get, call_613156.host, call_613156.base,
                         call_613156.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613156, url, valid)

proc call*(call_613227: Call_DescribeIngestion_612996; AwsAccountId: string;
          DataSetId: string; IngestionId: string): Recallable =
  ## describeIngestion
  ## Describes a SPICE ingestion.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   IngestionId: string (required)
  ##              : An ID for the ingestion.
  var path_613228 = newJObject()
  add(path_613228, "AwsAccountId", newJString(AwsAccountId))
  add(path_613228, "DataSetId", newJString(DataSetId))
  add(path_613228, "IngestionId", newJString(IngestionId))
  result = call_613227.call(path_613228, nil, nil, nil, nil)

var describeIngestion* = Call_DescribeIngestion_612996(name: "describeIngestion",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}",
    validator: validate_DescribeIngestion_612997, base: "/",
    url: url_DescribeIngestion_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelIngestion_613284 = ref object of OpenApiRestCall_612658
proc url_CancelIngestion_613286(protocol: Scheme; host: string; base: string;
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

proc validate_CancelIngestion_613285(path: JsonNode; query: JsonNode;
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
  var valid_613287 = path.getOrDefault("AwsAccountId")
  valid_613287 = validateParameter(valid_613287, JString, required = true,
                                 default = nil)
  if valid_613287 != nil:
    section.add "AwsAccountId", valid_613287
  var valid_613288 = path.getOrDefault("DataSetId")
  valid_613288 = validateParameter(valid_613288, JString, required = true,
                                 default = nil)
  if valid_613288 != nil:
    section.add "DataSetId", valid_613288
  var valid_613289 = path.getOrDefault("IngestionId")
  valid_613289 = validateParameter(valid_613289, JString, required = true,
                                 default = nil)
  if valid_613289 != nil:
    section.add "IngestionId", valid_613289
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
  var valid_613290 = header.getOrDefault("X-Amz-Signature")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-Signature", valid_613290
  var valid_613291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-Content-Sha256", valid_613291
  var valid_613292 = header.getOrDefault("X-Amz-Date")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-Date", valid_613292
  var valid_613293 = header.getOrDefault("X-Amz-Credential")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-Credential", valid_613293
  var valid_613294 = header.getOrDefault("X-Amz-Security-Token")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "X-Amz-Security-Token", valid_613294
  var valid_613295 = header.getOrDefault("X-Amz-Algorithm")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-Algorithm", valid_613295
  var valid_613296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "X-Amz-SignedHeaders", valid_613296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613297: Call_CancelIngestion_613284; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels an ongoing ingestion of data into SPICE.
  ## 
  let valid = call_613297.validator(path, query, header, formData, body)
  let scheme = call_613297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613297.url(scheme.get, call_613297.host, call_613297.base,
                         call_613297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613297, url, valid)

proc call*(call_613298: Call_CancelIngestion_613284; AwsAccountId: string;
          DataSetId: string; IngestionId: string): Recallable =
  ## cancelIngestion
  ## Cancels an ongoing ingestion of data into SPICE.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   IngestionId: string (required)
  ##              : An ID for the ingestion.
  var path_613299 = newJObject()
  add(path_613299, "AwsAccountId", newJString(AwsAccountId))
  add(path_613299, "DataSetId", newJString(DataSetId))
  add(path_613299, "IngestionId", newJString(IngestionId))
  result = call_613298.call(path_613299, nil, nil, nil, nil)

var cancelIngestion* = Call_CancelIngestion_613284(name: "cancelIngestion",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}",
    validator: validate_CancelIngestion_613285, base: "/", url: url_CancelIngestion_613286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDashboard_613318 = ref object of OpenApiRestCall_612658
proc url_UpdateDashboard_613320(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDashboard_613319(path: JsonNode; query: JsonNode;
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
  var valid_613321 = path.getOrDefault("AwsAccountId")
  valid_613321 = validateParameter(valid_613321, JString, required = true,
                                 default = nil)
  if valid_613321 != nil:
    section.add "AwsAccountId", valid_613321
  var valid_613322 = path.getOrDefault("DashboardId")
  valid_613322 = validateParameter(valid_613322, JString, required = true,
                                 default = nil)
  if valid_613322 != nil:
    section.add "DashboardId", valid_613322
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
  var valid_613323 = header.getOrDefault("X-Amz-Signature")
  valid_613323 = validateParameter(valid_613323, JString, required = false,
                                 default = nil)
  if valid_613323 != nil:
    section.add "X-Amz-Signature", valid_613323
  var valid_613324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613324 = validateParameter(valid_613324, JString, required = false,
                                 default = nil)
  if valid_613324 != nil:
    section.add "X-Amz-Content-Sha256", valid_613324
  var valid_613325 = header.getOrDefault("X-Amz-Date")
  valid_613325 = validateParameter(valid_613325, JString, required = false,
                                 default = nil)
  if valid_613325 != nil:
    section.add "X-Amz-Date", valid_613325
  var valid_613326 = header.getOrDefault("X-Amz-Credential")
  valid_613326 = validateParameter(valid_613326, JString, required = false,
                                 default = nil)
  if valid_613326 != nil:
    section.add "X-Amz-Credential", valid_613326
  var valid_613327 = header.getOrDefault("X-Amz-Security-Token")
  valid_613327 = validateParameter(valid_613327, JString, required = false,
                                 default = nil)
  if valid_613327 != nil:
    section.add "X-Amz-Security-Token", valid_613327
  var valid_613328 = header.getOrDefault("X-Amz-Algorithm")
  valid_613328 = validateParameter(valid_613328, JString, required = false,
                                 default = nil)
  if valid_613328 != nil:
    section.add "X-Amz-Algorithm", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-SignedHeaders", valid_613329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613331: Call_UpdateDashboard_613318; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a dashboard in an AWS account.
  ## 
  let valid = call_613331.validator(path, query, header, formData, body)
  let scheme = call_613331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613331.url(scheme.get, call_613331.host, call_613331.base,
                         call_613331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613331, url, valid)

proc call*(call_613332: Call_UpdateDashboard_613318; AwsAccountId: string;
          body: JsonNode; DashboardId: string): Recallable =
  ## updateDashboard
  ## Updates a dashboard in an AWS account.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're updating.
  ##   body: JObject (required)
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  var path_613333 = newJObject()
  var body_613334 = newJObject()
  add(path_613333, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_613334 = body
  add(path_613333, "DashboardId", newJString(DashboardId))
  result = call_613332.call(path_613333, nil, nil, nil, body_613334)

var updateDashboard* = Call_UpdateDashboard_613318(name: "updateDashboard",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}",
    validator: validate_UpdateDashboard_613319, base: "/", url: url_UpdateDashboard_613320,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDashboard_613335 = ref object of OpenApiRestCall_612658
proc url_CreateDashboard_613337(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDashboard_613336(path: JsonNode; query: JsonNode;
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
  var valid_613338 = path.getOrDefault("AwsAccountId")
  valid_613338 = validateParameter(valid_613338, JString, required = true,
                                 default = nil)
  if valid_613338 != nil:
    section.add "AwsAccountId", valid_613338
  var valid_613339 = path.getOrDefault("DashboardId")
  valid_613339 = validateParameter(valid_613339, JString, required = true,
                                 default = nil)
  if valid_613339 != nil:
    section.add "DashboardId", valid_613339
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
  var valid_613340 = header.getOrDefault("X-Amz-Signature")
  valid_613340 = validateParameter(valid_613340, JString, required = false,
                                 default = nil)
  if valid_613340 != nil:
    section.add "X-Amz-Signature", valid_613340
  var valid_613341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613341 = validateParameter(valid_613341, JString, required = false,
                                 default = nil)
  if valid_613341 != nil:
    section.add "X-Amz-Content-Sha256", valid_613341
  var valid_613342 = header.getOrDefault("X-Amz-Date")
  valid_613342 = validateParameter(valid_613342, JString, required = false,
                                 default = nil)
  if valid_613342 != nil:
    section.add "X-Amz-Date", valid_613342
  var valid_613343 = header.getOrDefault("X-Amz-Credential")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "X-Amz-Credential", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Security-Token")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Security-Token", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Algorithm")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Algorithm", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-SignedHeaders", valid_613346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613348: Call_CreateDashboard_613335; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a dashboard from a template. To first create a template, see the CreateTemplate API operation.</p> <p>A dashboard is an entity in QuickSight that identifies QuickSight reports, created from analyses. You can share QuickSight dashboards. With the right permissions, you can create scheduled email reports from them. The <code>CreateDashboard</code>, <code>DescribeDashboard</code>, and <code>ListDashboardsByUser</code> API operations act on the dashboard entity. If you have the correct permissions, you can create a dashboard from a template that exists in a different AWS account.</p>
  ## 
  let valid = call_613348.validator(path, query, header, formData, body)
  let scheme = call_613348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613348.url(scheme.get, call_613348.host, call_613348.base,
                         call_613348.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613348, url, valid)

proc call*(call_613349: Call_CreateDashboard_613335; AwsAccountId: string;
          body: JsonNode; DashboardId: string): Recallable =
  ## createDashboard
  ## <p>Creates a dashboard from a template. To first create a template, see the CreateTemplate API operation.</p> <p>A dashboard is an entity in QuickSight that identifies QuickSight reports, created from analyses. You can share QuickSight dashboards. With the right permissions, you can create scheduled email reports from them. The <code>CreateDashboard</code>, <code>DescribeDashboard</code>, and <code>ListDashboardsByUser</code> API operations act on the dashboard entity. If you have the correct permissions, you can create a dashboard from a template that exists in a different AWS account.</p>
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account where you want to create the dashboard.
  ##   body: JObject (required)
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard, also added to the IAM policy.
  var path_613350 = newJObject()
  var body_613351 = newJObject()
  add(path_613350, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_613351 = body
  add(path_613350, "DashboardId", newJString(DashboardId))
  result = call_613349.call(path_613350, nil, nil, nil, body_613351)

var createDashboard* = Call_CreateDashboard_613335(name: "createDashboard",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}",
    validator: validate_CreateDashboard_613336, base: "/", url: url_CreateDashboard_613337,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDashboard_613300 = ref object of OpenApiRestCall_612658
proc url_DescribeDashboard_613302(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDashboard_613301(path: JsonNode; query: JsonNode;
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
  var valid_613303 = path.getOrDefault("AwsAccountId")
  valid_613303 = validateParameter(valid_613303, JString, required = true,
                                 default = nil)
  if valid_613303 != nil:
    section.add "AwsAccountId", valid_613303
  var valid_613304 = path.getOrDefault("DashboardId")
  valid_613304 = validateParameter(valid_613304, JString, required = true,
                                 default = nil)
  if valid_613304 != nil:
    section.add "DashboardId", valid_613304
  result.add "path", section
  ## parameters in `query` object:
  ##   version-number: JInt
  ##                 : The version number for the dashboard. If a version number isn't passed, the latest published dashboard version is described. 
  ##   alias-name: JString
  ##             : The alias name.
  section = newJObject()
  var valid_613305 = query.getOrDefault("version-number")
  valid_613305 = validateParameter(valid_613305, JInt, required = false, default = nil)
  if valid_613305 != nil:
    section.add "version-number", valid_613305
  var valid_613306 = query.getOrDefault("alias-name")
  valid_613306 = validateParameter(valid_613306, JString, required = false,
                                 default = nil)
  if valid_613306 != nil:
    section.add "alias-name", valid_613306
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613307 = header.getOrDefault("X-Amz-Signature")
  valid_613307 = validateParameter(valid_613307, JString, required = false,
                                 default = nil)
  if valid_613307 != nil:
    section.add "X-Amz-Signature", valid_613307
  var valid_613308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "X-Amz-Content-Sha256", valid_613308
  var valid_613309 = header.getOrDefault("X-Amz-Date")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-Date", valid_613309
  var valid_613310 = header.getOrDefault("X-Amz-Credential")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "X-Amz-Credential", valid_613310
  var valid_613311 = header.getOrDefault("X-Amz-Security-Token")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "X-Amz-Security-Token", valid_613311
  var valid_613312 = header.getOrDefault("X-Amz-Algorithm")
  valid_613312 = validateParameter(valid_613312, JString, required = false,
                                 default = nil)
  if valid_613312 != nil:
    section.add "X-Amz-Algorithm", valid_613312
  var valid_613313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "X-Amz-SignedHeaders", valid_613313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613314: Call_DescribeDashboard_613300; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a summary for a dashboard.
  ## 
  let valid = call_613314.validator(path, query, header, formData, body)
  let scheme = call_613314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613314.url(scheme.get, call_613314.host, call_613314.base,
                         call_613314.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613314, url, valid)

proc call*(call_613315: Call_DescribeDashboard_613300; AwsAccountId: string;
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
  var path_613316 = newJObject()
  var query_613317 = newJObject()
  add(query_613317, "version-number", newJInt(versionNumber))
  add(path_613316, "AwsAccountId", newJString(AwsAccountId))
  add(query_613317, "alias-name", newJString(aliasName))
  add(path_613316, "DashboardId", newJString(DashboardId))
  result = call_613315.call(path_613316, query_613317, nil, nil, nil)

var describeDashboard* = Call_DescribeDashboard_613300(name: "describeDashboard",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}",
    validator: validate_DescribeDashboard_613301, base: "/",
    url: url_DescribeDashboard_613302, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDashboard_613352 = ref object of OpenApiRestCall_612658
proc url_DeleteDashboard_613354(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDashboard_613353(path: JsonNode; query: JsonNode;
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
  var valid_613355 = path.getOrDefault("AwsAccountId")
  valid_613355 = validateParameter(valid_613355, JString, required = true,
                                 default = nil)
  if valid_613355 != nil:
    section.add "AwsAccountId", valid_613355
  var valid_613356 = path.getOrDefault("DashboardId")
  valid_613356 = validateParameter(valid_613356, JString, required = true,
                                 default = nil)
  if valid_613356 != nil:
    section.add "DashboardId", valid_613356
  result.add "path", section
  ## parameters in `query` object:
  ##   version-number: JInt
  ##                 : The version number of the dashboard. If the version number property is provided, only the specified version of the dashboard is deleted.
  section = newJObject()
  var valid_613357 = query.getOrDefault("version-number")
  valid_613357 = validateParameter(valid_613357, JInt, required = false, default = nil)
  if valid_613357 != nil:
    section.add "version-number", valid_613357
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613358 = header.getOrDefault("X-Amz-Signature")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "X-Amz-Signature", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Content-Sha256", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Date")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Date", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Credential")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Credential", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-Security-Token")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-Security-Token", valid_613362
  var valid_613363 = header.getOrDefault("X-Amz-Algorithm")
  valid_613363 = validateParameter(valid_613363, JString, required = false,
                                 default = nil)
  if valid_613363 != nil:
    section.add "X-Amz-Algorithm", valid_613363
  var valid_613364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613364 = validateParameter(valid_613364, JString, required = false,
                                 default = nil)
  if valid_613364 != nil:
    section.add "X-Amz-SignedHeaders", valid_613364
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613365: Call_DeleteDashboard_613352; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a dashboard.
  ## 
  let valid = call_613365.validator(path, query, header, formData, body)
  let scheme = call_613365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613365.url(scheme.get, call_613365.host, call_613365.base,
                         call_613365.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613365, url, valid)

proc call*(call_613366: Call_DeleteDashboard_613352; AwsAccountId: string;
          DashboardId: string; versionNumber: int = 0): Recallable =
  ## deleteDashboard
  ## Deletes a dashboard.
  ##   versionNumber: int
  ##                : The version number of the dashboard. If the version number property is provided, only the specified version of the dashboard is deleted.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're deleting.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  var path_613367 = newJObject()
  var query_613368 = newJObject()
  add(query_613368, "version-number", newJInt(versionNumber))
  add(path_613367, "AwsAccountId", newJString(AwsAccountId))
  add(path_613367, "DashboardId", newJString(DashboardId))
  result = call_613366.call(path_613367, query_613368, nil, nil, nil)

var deleteDashboard* = Call_DeleteDashboard_613352(name: "deleteDashboard",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}",
    validator: validate_DeleteDashboard_613353, base: "/", url: url_DeleteDashboard_613354,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSet_613388 = ref object of OpenApiRestCall_612658
proc url_CreateDataSet_613390(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDataSet_613389(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613391 = path.getOrDefault("AwsAccountId")
  valid_613391 = validateParameter(valid_613391, JString, required = true,
                                 default = nil)
  if valid_613391 != nil:
    section.add "AwsAccountId", valid_613391
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
  var valid_613392 = header.getOrDefault("X-Amz-Signature")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Signature", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-Content-Sha256", valid_613393
  var valid_613394 = header.getOrDefault("X-Amz-Date")
  valid_613394 = validateParameter(valid_613394, JString, required = false,
                                 default = nil)
  if valid_613394 != nil:
    section.add "X-Amz-Date", valid_613394
  var valid_613395 = header.getOrDefault("X-Amz-Credential")
  valid_613395 = validateParameter(valid_613395, JString, required = false,
                                 default = nil)
  if valid_613395 != nil:
    section.add "X-Amz-Credential", valid_613395
  var valid_613396 = header.getOrDefault("X-Amz-Security-Token")
  valid_613396 = validateParameter(valid_613396, JString, required = false,
                                 default = nil)
  if valid_613396 != nil:
    section.add "X-Amz-Security-Token", valid_613396
  var valid_613397 = header.getOrDefault("X-Amz-Algorithm")
  valid_613397 = validateParameter(valid_613397, JString, required = false,
                                 default = nil)
  if valid_613397 != nil:
    section.add "X-Amz-Algorithm", valid_613397
  var valid_613398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613398 = validateParameter(valid_613398, JString, required = false,
                                 default = nil)
  if valid_613398 != nil:
    section.add "X-Amz-SignedHeaders", valid_613398
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613400: Call_CreateDataSet_613388; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a dataset.
  ## 
  let valid = call_613400.validator(path, query, header, formData, body)
  let scheme = call_613400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613400.url(scheme.get, call_613400.host, call_613400.base,
                         call_613400.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613400, url, valid)

proc call*(call_613401: Call_CreateDataSet_613388; AwsAccountId: string;
          body: JsonNode): Recallable =
  ## createDataSet
  ## Creates a dataset.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   body: JObject (required)
  var path_613402 = newJObject()
  var body_613403 = newJObject()
  add(path_613402, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_613403 = body
  result = call_613401.call(path_613402, nil, nil, nil, body_613403)

var createDataSet* = Call_CreateDataSet_613388(name: "createDataSet",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets",
    validator: validate_CreateDataSet_613389, base: "/", url: url_CreateDataSet_613390,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSets_613369 = ref object of OpenApiRestCall_612658
proc url_ListDataSets_613371(protocol: Scheme; host: string; base: string;
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

proc validate_ListDataSets_613370(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613372 = path.getOrDefault("AwsAccountId")
  valid_613372 = validateParameter(valid_613372, JString, required = true,
                                 default = nil)
  if valid_613372 != nil:
    section.add "AwsAccountId", valid_613372
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
  var valid_613373 = query.getOrDefault("MaxResults")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "MaxResults", valid_613373
  var valid_613374 = query.getOrDefault("NextToken")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "NextToken", valid_613374
  var valid_613375 = query.getOrDefault("max-results")
  valid_613375 = validateParameter(valid_613375, JInt, required = false, default = nil)
  if valid_613375 != nil:
    section.add "max-results", valid_613375
  var valid_613376 = query.getOrDefault("next-token")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "next-token", valid_613376
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613377 = header.getOrDefault("X-Amz-Signature")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Signature", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-Content-Sha256", valid_613378
  var valid_613379 = header.getOrDefault("X-Amz-Date")
  valid_613379 = validateParameter(valid_613379, JString, required = false,
                                 default = nil)
  if valid_613379 != nil:
    section.add "X-Amz-Date", valid_613379
  var valid_613380 = header.getOrDefault("X-Amz-Credential")
  valid_613380 = validateParameter(valid_613380, JString, required = false,
                                 default = nil)
  if valid_613380 != nil:
    section.add "X-Amz-Credential", valid_613380
  var valid_613381 = header.getOrDefault("X-Amz-Security-Token")
  valid_613381 = validateParameter(valid_613381, JString, required = false,
                                 default = nil)
  if valid_613381 != nil:
    section.add "X-Amz-Security-Token", valid_613381
  var valid_613382 = header.getOrDefault("X-Amz-Algorithm")
  valid_613382 = validateParameter(valid_613382, JString, required = false,
                                 default = nil)
  if valid_613382 != nil:
    section.add "X-Amz-Algorithm", valid_613382
  var valid_613383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613383 = validateParameter(valid_613383, JString, required = false,
                                 default = nil)
  if valid_613383 != nil:
    section.add "X-Amz-SignedHeaders", valid_613383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613384: Call_ListDataSets_613369; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all of the datasets belonging to the current AWS account in an AWS Region.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/*</code>.</p>
  ## 
  let valid = call_613384.validator(path, query, header, formData, body)
  let scheme = call_613384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613384.url(scheme.get, call_613384.host, call_613384.base,
                         call_613384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613384, url, valid)

proc call*(call_613385: Call_ListDataSets_613369; AwsAccountId: string;
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
  var path_613386 = newJObject()
  var query_613387 = newJObject()
  add(path_613386, "AwsAccountId", newJString(AwsAccountId))
  add(query_613387, "MaxResults", newJString(MaxResults))
  add(query_613387, "NextToken", newJString(NextToken))
  add(query_613387, "max-results", newJInt(maxResults))
  add(query_613387, "next-token", newJString(nextToken))
  result = call_613385.call(path_613386, query_613387, nil, nil, nil)

var listDataSets* = Call_ListDataSets_613369(name: "listDataSets",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets", validator: validate_ListDataSets_613370,
    base: "/", url: url_ListDataSets_613371, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSource_613423 = ref object of OpenApiRestCall_612658
proc url_CreateDataSource_613425(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDataSource_613424(path: JsonNode; query: JsonNode;
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
  var valid_613426 = path.getOrDefault("AwsAccountId")
  valid_613426 = validateParameter(valid_613426, JString, required = true,
                                 default = nil)
  if valid_613426 != nil:
    section.add "AwsAccountId", valid_613426
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
  var valid_613427 = header.getOrDefault("X-Amz-Signature")
  valid_613427 = validateParameter(valid_613427, JString, required = false,
                                 default = nil)
  if valid_613427 != nil:
    section.add "X-Amz-Signature", valid_613427
  var valid_613428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613428 = validateParameter(valid_613428, JString, required = false,
                                 default = nil)
  if valid_613428 != nil:
    section.add "X-Amz-Content-Sha256", valid_613428
  var valid_613429 = header.getOrDefault("X-Amz-Date")
  valid_613429 = validateParameter(valid_613429, JString, required = false,
                                 default = nil)
  if valid_613429 != nil:
    section.add "X-Amz-Date", valid_613429
  var valid_613430 = header.getOrDefault("X-Amz-Credential")
  valid_613430 = validateParameter(valid_613430, JString, required = false,
                                 default = nil)
  if valid_613430 != nil:
    section.add "X-Amz-Credential", valid_613430
  var valid_613431 = header.getOrDefault("X-Amz-Security-Token")
  valid_613431 = validateParameter(valid_613431, JString, required = false,
                                 default = nil)
  if valid_613431 != nil:
    section.add "X-Amz-Security-Token", valid_613431
  var valid_613432 = header.getOrDefault("X-Amz-Algorithm")
  valid_613432 = validateParameter(valid_613432, JString, required = false,
                                 default = nil)
  if valid_613432 != nil:
    section.add "X-Amz-Algorithm", valid_613432
  var valid_613433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-SignedHeaders", valid_613433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613435: Call_CreateDataSource_613423; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a data source.
  ## 
  let valid = call_613435.validator(path, query, header, formData, body)
  let scheme = call_613435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613435.url(scheme.get, call_613435.host, call_613435.base,
                         call_613435.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613435, url, valid)

proc call*(call_613436: Call_CreateDataSource_613423; AwsAccountId: string;
          body: JsonNode): Recallable =
  ## createDataSource
  ## Creates a data source.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   body: JObject (required)
  var path_613437 = newJObject()
  var body_613438 = newJObject()
  add(path_613437, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_613438 = body
  result = call_613436.call(path_613437, nil, nil, nil, body_613438)

var createDataSource* = Call_CreateDataSource_613423(name: "createDataSource",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources",
    validator: validate_CreateDataSource_613424, base: "/",
    url: url_CreateDataSource_613425, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSources_613404 = ref object of OpenApiRestCall_612658
proc url_ListDataSources_613406(protocol: Scheme; host: string; base: string;
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

proc validate_ListDataSources_613405(path: JsonNode; query: JsonNode;
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
  var valid_613407 = path.getOrDefault("AwsAccountId")
  valid_613407 = validateParameter(valid_613407, JString, required = true,
                                 default = nil)
  if valid_613407 != nil:
    section.add "AwsAccountId", valid_613407
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
  var valid_613408 = query.getOrDefault("MaxResults")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "MaxResults", valid_613408
  var valid_613409 = query.getOrDefault("NextToken")
  valid_613409 = validateParameter(valid_613409, JString, required = false,
                                 default = nil)
  if valid_613409 != nil:
    section.add "NextToken", valid_613409
  var valid_613410 = query.getOrDefault("max-results")
  valid_613410 = validateParameter(valid_613410, JInt, required = false, default = nil)
  if valid_613410 != nil:
    section.add "max-results", valid_613410
  var valid_613411 = query.getOrDefault("next-token")
  valid_613411 = validateParameter(valid_613411, JString, required = false,
                                 default = nil)
  if valid_613411 != nil:
    section.add "next-token", valid_613411
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613412 = header.getOrDefault("X-Amz-Signature")
  valid_613412 = validateParameter(valid_613412, JString, required = false,
                                 default = nil)
  if valid_613412 != nil:
    section.add "X-Amz-Signature", valid_613412
  var valid_613413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613413 = validateParameter(valid_613413, JString, required = false,
                                 default = nil)
  if valid_613413 != nil:
    section.add "X-Amz-Content-Sha256", valid_613413
  var valid_613414 = header.getOrDefault("X-Amz-Date")
  valid_613414 = validateParameter(valid_613414, JString, required = false,
                                 default = nil)
  if valid_613414 != nil:
    section.add "X-Amz-Date", valid_613414
  var valid_613415 = header.getOrDefault("X-Amz-Credential")
  valid_613415 = validateParameter(valid_613415, JString, required = false,
                                 default = nil)
  if valid_613415 != nil:
    section.add "X-Amz-Credential", valid_613415
  var valid_613416 = header.getOrDefault("X-Amz-Security-Token")
  valid_613416 = validateParameter(valid_613416, JString, required = false,
                                 default = nil)
  if valid_613416 != nil:
    section.add "X-Amz-Security-Token", valid_613416
  var valid_613417 = header.getOrDefault("X-Amz-Algorithm")
  valid_613417 = validateParameter(valid_613417, JString, required = false,
                                 default = nil)
  if valid_613417 != nil:
    section.add "X-Amz-Algorithm", valid_613417
  var valid_613418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613418 = validateParameter(valid_613418, JString, required = false,
                                 default = nil)
  if valid_613418 != nil:
    section.add "X-Amz-SignedHeaders", valid_613418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613419: Call_ListDataSources_613404; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists data sources in current AWS Region that belong to this AWS account.
  ## 
  let valid = call_613419.validator(path, query, header, formData, body)
  let scheme = call_613419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613419.url(scheme.get, call_613419.host, call_613419.base,
                         call_613419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613419, url, valid)

proc call*(call_613420: Call_ListDataSources_613404; AwsAccountId: string;
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
  var path_613421 = newJObject()
  var query_613422 = newJObject()
  add(path_613421, "AwsAccountId", newJString(AwsAccountId))
  add(query_613422, "MaxResults", newJString(MaxResults))
  add(query_613422, "NextToken", newJString(NextToken))
  add(query_613422, "max-results", newJInt(maxResults))
  add(query_613422, "next-token", newJString(nextToken))
  result = call_613420.call(path_613421, query_613422, nil, nil, nil)

var listDataSources* = Call_ListDataSources_613404(name: "listDataSources",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources",
    validator: validate_ListDataSources_613405, base: "/", url: url_ListDataSources_613406,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroup_613457 = ref object of OpenApiRestCall_612658
proc url_CreateGroup_613459(protocol: Scheme; host: string; base: string;
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

proc validate_CreateGroup_613458(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613460 = path.getOrDefault("AwsAccountId")
  valid_613460 = validateParameter(valid_613460, JString, required = true,
                                 default = nil)
  if valid_613460 != nil:
    section.add "AwsAccountId", valid_613460
  var valid_613461 = path.getOrDefault("Namespace")
  valid_613461 = validateParameter(valid_613461, JString, required = true,
                                 default = nil)
  if valid_613461 != nil:
    section.add "Namespace", valid_613461
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
  var valid_613462 = header.getOrDefault("X-Amz-Signature")
  valid_613462 = validateParameter(valid_613462, JString, required = false,
                                 default = nil)
  if valid_613462 != nil:
    section.add "X-Amz-Signature", valid_613462
  var valid_613463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613463 = validateParameter(valid_613463, JString, required = false,
                                 default = nil)
  if valid_613463 != nil:
    section.add "X-Amz-Content-Sha256", valid_613463
  var valid_613464 = header.getOrDefault("X-Amz-Date")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Date", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-Credential")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Credential", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Security-Token")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Security-Token", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Algorithm")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Algorithm", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-SignedHeaders", valid_613468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613470: Call_CreateGroup_613457; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon QuickSight group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;relevant-aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a group object.</p>
  ## 
  let valid = call_613470.validator(path, query, header, formData, body)
  let scheme = call_613470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613470.url(scheme.get, call_613470.host, call_613470.base,
                         call_613470.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613470, url, valid)

proc call*(call_613471: Call_CreateGroup_613457; AwsAccountId: string;
          Namespace: string; body: JsonNode): Recallable =
  ## createGroup
  ## <p>Creates an Amazon QuickSight group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;relevant-aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a group object.</p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   body: JObject (required)
  var path_613472 = newJObject()
  var body_613473 = newJObject()
  add(path_613472, "AwsAccountId", newJString(AwsAccountId))
  add(path_613472, "Namespace", newJString(Namespace))
  if body != nil:
    body_613473 = body
  result = call_613471.call(path_613472, nil, nil, nil, body_613473)

var createGroup* = Call_CreateGroup_613457(name: "createGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups",
                                        validator: validate_CreateGroup_613458,
                                        base: "/", url: url_CreateGroup_613459,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_613439 = ref object of OpenApiRestCall_612658
proc url_ListGroups_613441(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListGroups_613440(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613442 = path.getOrDefault("AwsAccountId")
  valid_613442 = validateParameter(valid_613442, JString, required = true,
                                 default = nil)
  if valid_613442 != nil:
    section.add "AwsAccountId", valid_613442
  var valid_613443 = path.getOrDefault("Namespace")
  valid_613443 = validateParameter(valid_613443, JString, required = true,
                                 default = nil)
  if valid_613443 != nil:
    section.add "Namespace", valid_613443
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_613444 = query.getOrDefault("max-results")
  valid_613444 = validateParameter(valid_613444, JInt, required = false, default = nil)
  if valid_613444 != nil:
    section.add "max-results", valid_613444
  var valid_613445 = query.getOrDefault("next-token")
  valid_613445 = validateParameter(valid_613445, JString, required = false,
                                 default = nil)
  if valid_613445 != nil:
    section.add "next-token", valid_613445
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613446 = header.getOrDefault("X-Amz-Signature")
  valid_613446 = validateParameter(valid_613446, JString, required = false,
                                 default = nil)
  if valid_613446 != nil:
    section.add "X-Amz-Signature", valid_613446
  var valid_613447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613447 = validateParameter(valid_613447, JString, required = false,
                                 default = nil)
  if valid_613447 != nil:
    section.add "X-Amz-Content-Sha256", valid_613447
  var valid_613448 = header.getOrDefault("X-Amz-Date")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-Date", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Credential")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Credential", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-Security-Token")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Security-Token", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-Algorithm")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Algorithm", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-SignedHeaders", valid_613452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613453: Call_ListGroups_613439; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all user groups in Amazon QuickSight. 
  ## 
  let valid = call_613453.validator(path, query, header, formData, body)
  let scheme = call_613453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613453.url(scheme.get, call_613453.host, call_613453.base,
                         call_613453.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613453, url, valid)

proc call*(call_613454: Call_ListGroups_613439; AwsAccountId: string;
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
  var path_613455 = newJObject()
  var query_613456 = newJObject()
  add(path_613455, "AwsAccountId", newJString(AwsAccountId))
  add(path_613455, "Namespace", newJString(Namespace))
  add(query_613456, "max-results", newJInt(maxResults))
  add(query_613456, "next-token", newJString(nextToken))
  result = call_613454.call(path_613455, query_613456, nil, nil, nil)

var listGroups* = Call_ListGroups_613439(name: "listGroups",
                                      meth: HttpMethod.HttpGet,
                                      host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups",
                                      validator: validate_ListGroups_613440,
                                      base: "/", url: url_ListGroups_613441,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroupMembership_613474 = ref object of OpenApiRestCall_612658
proc url_CreateGroupMembership_613476(protocol: Scheme; host: string; base: string;
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

proc validate_CreateGroupMembership_613475(path: JsonNode; query: JsonNode;
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
  var valid_613477 = path.getOrDefault("GroupName")
  valid_613477 = validateParameter(valid_613477, JString, required = true,
                                 default = nil)
  if valid_613477 != nil:
    section.add "GroupName", valid_613477
  var valid_613478 = path.getOrDefault("AwsAccountId")
  valid_613478 = validateParameter(valid_613478, JString, required = true,
                                 default = nil)
  if valid_613478 != nil:
    section.add "AwsAccountId", valid_613478
  var valid_613479 = path.getOrDefault("Namespace")
  valid_613479 = validateParameter(valid_613479, JString, required = true,
                                 default = nil)
  if valid_613479 != nil:
    section.add "Namespace", valid_613479
  var valid_613480 = path.getOrDefault("MemberName")
  valid_613480 = validateParameter(valid_613480, JString, required = true,
                                 default = nil)
  if valid_613480 != nil:
    section.add "MemberName", valid_613480
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
  var valid_613481 = header.getOrDefault("X-Amz-Signature")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Signature", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Content-Sha256", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Date")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Date", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-Credential")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-Credential", valid_613484
  var valid_613485 = header.getOrDefault("X-Amz-Security-Token")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-Security-Token", valid_613485
  var valid_613486 = header.getOrDefault("X-Amz-Algorithm")
  valid_613486 = validateParameter(valid_613486, JString, required = false,
                                 default = nil)
  if valid_613486 != nil:
    section.add "X-Amz-Algorithm", valid_613486
  var valid_613487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613487 = validateParameter(valid_613487, JString, required = false,
                                 default = nil)
  if valid_613487 != nil:
    section.add "X-Amz-SignedHeaders", valid_613487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613488: Call_CreateGroupMembership_613474; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds an Amazon QuickSight user to an Amazon QuickSight group. 
  ## 
  let valid = call_613488.validator(path, query, header, formData, body)
  let scheme = call_613488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613488.url(scheme.get, call_613488.host, call_613488.base,
                         call_613488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613488, url, valid)

proc call*(call_613489: Call_CreateGroupMembership_613474; GroupName: string;
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
  var path_613490 = newJObject()
  add(path_613490, "GroupName", newJString(GroupName))
  add(path_613490, "AwsAccountId", newJString(AwsAccountId))
  add(path_613490, "Namespace", newJString(Namespace))
  add(path_613490, "MemberName", newJString(MemberName))
  result = call_613489.call(path_613490, nil, nil, nil, nil)

var createGroupMembership* = Call_CreateGroupMembership_613474(
    name: "createGroupMembership", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members/{MemberName}",
    validator: validate_CreateGroupMembership_613475, base: "/",
    url: url_CreateGroupMembership_613476, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroupMembership_613491 = ref object of OpenApiRestCall_612658
proc url_DeleteGroupMembership_613493(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGroupMembership_613492(path: JsonNode; query: JsonNode;
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
  var valid_613494 = path.getOrDefault("GroupName")
  valid_613494 = validateParameter(valid_613494, JString, required = true,
                                 default = nil)
  if valid_613494 != nil:
    section.add "GroupName", valid_613494
  var valid_613495 = path.getOrDefault("AwsAccountId")
  valid_613495 = validateParameter(valid_613495, JString, required = true,
                                 default = nil)
  if valid_613495 != nil:
    section.add "AwsAccountId", valid_613495
  var valid_613496 = path.getOrDefault("Namespace")
  valid_613496 = validateParameter(valid_613496, JString, required = true,
                                 default = nil)
  if valid_613496 != nil:
    section.add "Namespace", valid_613496
  var valid_613497 = path.getOrDefault("MemberName")
  valid_613497 = validateParameter(valid_613497, JString, required = true,
                                 default = nil)
  if valid_613497 != nil:
    section.add "MemberName", valid_613497
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
  var valid_613498 = header.getOrDefault("X-Amz-Signature")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "X-Amz-Signature", valid_613498
  var valid_613499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "X-Amz-Content-Sha256", valid_613499
  var valid_613500 = header.getOrDefault("X-Amz-Date")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "X-Amz-Date", valid_613500
  var valid_613501 = header.getOrDefault("X-Amz-Credential")
  valid_613501 = validateParameter(valid_613501, JString, required = false,
                                 default = nil)
  if valid_613501 != nil:
    section.add "X-Amz-Credential", valid_613501
  var valid_613502 = header.getOrDefault("X-Amz-Security-Token")
  valid_613502 = validateParameter(valid_613502, JString, required = false,
                                 default = nil)
  if valid_613502 != nil:
    section.add "X-Amz-Security-Token", valid_613502
  var valid_613503 = header.getOrDefault("X-Amz-Algorithm")
  valid_613503 = validateParameter(valid_613503, JString, required = false,
                                 default = nil)
  if valid_613503 != nil:
    section.add "X-Amz-Algorithm", valid_613503
  var valid_613504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613504 = validateParameter(valid_613504, JString, required = false,
                                 default = nil)
  if valid_613504 != nil:
    section.add "X-Amz-SignedHeaders", valid_613504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613505: Call_DeleteGroupMembership_613491; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a user from a group so that the user is no longer a member of the group.
  ## 
  let valid = call_613505.validator(path, query, header, formData, body)
  let scheme = call_613505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613505.url(scheme.get, call_613505.host, call_613505.base,
                         call_613505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613505, url, valid)

proc call*(call_613506: Call_DeleteGroupMembership_613491; GroupName: string;
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
  var path_613507 = newJObject()
  add(path_613507, "GroupName", newJString(GroupName))
  add(path_613507, "AwsAccountId", newJString(AwsAccountId))
  add(path_613507, "Namespace", newJString(Namespace))
  add(path_613507, "MemberName", newJString(MemberName))
  result = call_613506.call(path_613507, nil, nil, nil, nil)

var deleteGroupMembership* = Call_DeleteGroupMembership_613491(
    name: "deleteGroupMembership", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members/{MemberName}",
    validator: validate_DeleteGroupMembership_613492, base: "/",
    url: url_DeleteGroupMembership_613493, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIAMPolicyAssignment_613508 = ref object of OpenApiRestCall_612658
proc url_CreateIAMPolicyAssignment_613510(protocol: Scheme; host: string;
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

proc validate_CreateIAMPolicyAssignment_613509(path: JsonNode; query: JsonNode;
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
  var valid_613511 = path.getOrDefault("AwsAccountId")
  valid_613511 = validateParameter(valid_613511, JString, required = true,
                                 default = nil)
  if valid_613511 != nil:
    section.add "AwsAccountId", valid_613511
  var valid_613512 = path.getOrDefault("Namespace")
  valid_613512 = validateParameter(valid_613512, JString, required = true,
                                 default = nil)
  if valid_613512 != nil:
    section.add "Namespace", valid_613512
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
  var valid_613513 = header.getOrDefault("X-Amz-Signature")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "X-Amz-Signature", valid_613513
  var valid_613514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "X-Amz-Content-Sha256", valid_613514
  var valid_613515 = header.getOrDefault("X-Amz-Date")
  valid_613515 = validateParameter(valid_613515, JString, required = false,
                                 default = nil)
  if valid_613515 != nil:
    section.add "X-Amz-Date", valid_613515
  var valid_613516 = header.getOrDefault("X-Amz-Credential")
  valid_613516 = validateParameter(valid_613516, JString, required = false,
                                 default = nil)
  if valid_613516 != nil:
    section.add "X-Amz-Credential", valid_613516
  var valid_613517 = header.getOrDefault("X-Amz-Security-Token")
  valid_613517 = validateParameter(valid_613517, JString, required = false,
                                 default = nil)
  if valid_613517 != nil:
    section.add "X-Amz-Security-Token", valid_613517
  var valid_613518 = header.getOrDefault("X-Amz-Algorithm")
  valid_613518 = validateParameter(valid_613518, JString, required = false,
                                 default = nil)
  if valid_613518 != nil:
    section.add "X-Amz-Algorithm", valid_613518
  var valid_613519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613519 = validateParameter(valid_613519, JString, required = false,
                                 default = nil)
  if valid_613519 != nil:
    section.add "X-Amz-SignedHeaders", valid_613519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613521: Call_CreateIAMPolicyAssignment_613508; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an assignment with one specified IAM policy, identified by its Amazon Resource Name (ARN). This policy will be assigned to specified groups or users of Amazon QuickSight. The users and groups need to be in the same namespace. 
  ## 
  let valid = call_613521.validator(path, query, header, formData, body)
  let scheme = call_613521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613521.url(scheme.get, call_613521.host, call_613521.base,
                         call_613521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613521, url, valid)

proc call*(call_613522: Call_CreateIAMPolicyAssignment_613508;
          AwsAccountId: string; Namespace: string; body: JsonNode): Recallable =
  ## createIAMPolicyAssignment
  ## Creates an assignment with one specified IAM policy, identified by its Amazon Resource Name (ARN). This policy will be assigned to specified groups or users of Amazon QuickSight. The users and groups need to be in the same namespace. 
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account where you want to assign an IAM policy to QuickSight users or groups.
  ##   Namespace: string (required)
  ##            : The namespace that contains the assignment.
  ##   body: JObject (required)
  var path_613523 = newJObject()
  var body_613524 = newJObject()
  add(path_613523, "AwsAccountId", newJString(AwsAccountId))
  add(path_613523, "Namespace", newJString(Namespace))
  if body != nil:
    body_613524 = body
  result = call_613522.call(path_613523, nil, nil, nil, body_613524)

var createIAMPolicyAssignment* = Call_CreateIAMPolicyAssignment_613508(
    name: "createIAMPolicyAssignment", meth: HttpMethod.HttpPost,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/",
    validator: validate_CreateIAMPolicyAssignment_613509, base: "/",
    url: url_CreateIAMPolicyAssignment_613510,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTemplate_613543 = ref object of OpenApiRestCall_612658
proc url_UpdateTemplate_613545(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateTemplate_613544(path: JsonNode; query: JsonNode;
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
  var valid_613546 = path.getOrDefault("AwsAccountId")
  valid_613546 = validateParameter(valid_613546, JString, required = true,
                                 default = nil)
  if valid_613546 != nil:
    section.add "AwsAccountId", valid_613546
  var valid_613547 = path.getOrDefault("TemplateId")
  valid_613547 = validateParameter(valid_613547, JString, required = true,
                                 default = nil)
  if valid_613547 != nil:
    section.add "TemplateId", valid_613547
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
  var valid_613548 = header.getOrDefault("X-Amz-Signature")
  valid_613548 = validateParameter(valid_613548, JString, required = false,
                                 default = nil)
  if valid_613548 != nil:
    section.add "X-Amz-Signature", valid_613548
  var valid_613549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613549 = validateParameter(valid_613549, JString, required = false,
                                 default = nil)
  if valid_613549 != nil:
    section.add "X-Amz-Content-Sha256", valid_613549
  var valid_613550 = header.getOrDefault("X-Amz-Date")
  valid_613550 = validateParameter(valid_613550, JString, required = false,
                                 default = nil)
  if valid_613550 != nil:
    section.add "X-Amz-Date", valid_613550
  var valid_613551 = header.getOrDefault("X-Amz-Credential")
  valid_613551 = validateParameter(valid_613551, JString, required = false,
                                 default = nil)
  if valid_613551 != nil:
    section.add "X-Amz-Credential", valid_613551
  var valid_613552 = header.getOrDefault("X-Amz-Security-Token")
  valid_613552 = validateParameter(valid_613552, JString, required = false,
                                 default = nil)
  if valid_613552 != nil:
    section.add "X-Amz-Security-Token", valid_613552
  var valid_613553 = header.getOrDefault("X-Amz-Algorithm")
  valid_613553 = validateParameter(valid_613553, JString, required = false,
                                 default = nil)
  if valid_613553 != nil:
    section.add "X-Amz-Algorithm", valid_613553
  var valid_613554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613554 = validateParameter(valid_613554, JString, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "X-Amz-SignedHeaders", valid_613554
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613556: Call_UpdateTemplate_613543; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a template from an existing Amazon QuickSight analysis or another template.
  ## 
  let valid = call_613556.validator(path, query, header, formData, body)
  let scheme = call_613556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613556.url(scheme.get, call_613556.host, call_613556.base,
                         call_613556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613556, url, valid)

proc call*(call_613557: Call_UpdateTemplate_613543; AwsAccountId: string;
          TemplateId: string; body: JsonNode): Recallable =
  ## updateTemplate
  ## Updates a template from an existing Amazon QuickSight analysis or another template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template that you're updating.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  ##   body: JObject (required)
  var path_613558 = newJObject()
  var body_613559 = newJObject()
  add(path_613558, "AwsAccountId", newJString(AwsAccountId))
  add(path_613558, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_613559 = body
  result = call_613557.call(path_613558, nil, nil, nil, body_613559)

var updateTemplate* = Call_UpdateTemplate_613543(name: "updateTemplate",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}",
    validator: validate_UpdateTemplate_613544, base: "/", url: url_UpdateTemplate_613545,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTemplate_613560 = ref object of OpenApiRestCall_612658
proc url_CreateTemplate_613562(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTemplate_613561(path: JsonNode; query: JsonNode;
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
  var valid_613563 = path.getOrDefault("AwsAccountId")
  valid_613563 = validateParameter(valid_613563, JString, required = true,
                                 default = nil)
  if valid_613563 != nil:
    section.add "AwsAccountId", valid_613563
  var valid_613564 = path.getOrDefault("TemplateId")
  valid_613564 = validateParameter(valid_613564, JString, required = true,
                                 default = nil)
  if valid_613564 != nil:
    section.add "TemplateId", valid_613564
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
  var valid_613565 = header.getOrDefault("X-Amz-Signature")
  valid_613565 = validateParameter(valid_613565, JString, required = false,
                                 default = nil)
  if valid_613565 != nil:
    section.add "X-Amz-Signature", valid_613565
  var valid_613566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613566 = validateParameter(valid_613566, JString, required = false,
                                 default = nil)
  if valid_613566 != nil:
    section.add "X-Amz-Content-Sha256", valid_613566
  var valid_613567 = header.getOrDefault("X-Amz-Date")
  valid_613567 = validateParameter(valid_613567, JString, required = false,
                                 default = nil)
  if valid_613567 != nil:
    section.add "X-Amz-Date", valid_613567
  var valid_613568 = header.getOrDefault("X-Amz-Credential")
  valid_613568 = validateParameter(valid_613568, JString, required = false,
                                 default = nil)
  if valid_613568 != nil:
    section.add "X-Amz-Credential", valid_613568
  var valid_613569 = header.getOrDefault("X-Amz-Security-Token")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-Security-Token", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-Algorithm")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-Algorithm", valid_613570
  var valid_613571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-SignedHeaders", valid_613571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613573: Call_CreateTemplate_613560; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a template from an existing QuickSight analysis or template. You can use the resulting template to create a dashboard.</p> <p>A <i>template</i> is an entity in QuickSight that encapsulates the metadata required to create an analysis and that you can use to create s dashboard. A template adds a layer of abstraction by using placeholders to replace the dataset associated with the analysis. You can use templates to create dashboards by replacing dataset placeholders with datasets that follow the same schema that was used to create the source analysis and template.</p>
  ## 
  let valid = call_613573.validator(path, query, header, formData, body)
  let scheme = call_613573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613573.url(scheme.get, call_613573.host, call_613573.base,
                         call_613573.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613573, url, valid)

proc call*(call_613574: Call_CreateTemplate_613560; AwsAccountId: string;
          TemplateId: string; body: JsonNode): Recallable =
  ## createTemplate
  ## <p>Creates a template from an existing QuickSight analysis or template. You can use the resulting template to create a dashboard.</p> <p>A <i>template</i> is an entity in QuickSight that encapsulates the metadata required to create an analysis and that you can use to create s dashboard. A template adds a layer of abstraction by using placeholders to replace the dataset associated with the analysis. You can use templates to create dashboards by replacing dataset placeholders with datasets that follow the same schema that was used to create the source analysis and template.</p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   TemplateId: string (required)
  ##             : An ID for the template that you want to create. This template is unique per AWS Region in each AWS account.
  ##   body: JObject (required)
  var path_613575 = newJObject()
  var body_613576 = newJObject()
  add(path_613575, "AwsAccountId", newJString(AwsAccountId))
  add(path_613575, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_613576 = body
  result = call_613574.call(path_613575, nil, nil, nil, body_613576)

var createTemplate* = Call_CreateTemplate_613560(name: "createTemplate",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}",
    validator: validate_CreateTemplate_613561, base: "/", url: url_CreateTemplate_613562,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTemplate_613525 = ref object of OpenApiRestCall_612658
proc url_DescribeTemplate_613527(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTemplate_613526(path: JsonNode; query: JsonNode;
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
  var valid_613528 = path.getOrDefault("AwsAccountId")
  valid_613528 = validateParameter(valid_613528, JString, required = true,
                                 default = nil)
  if valid_613528 != nil:
    section.add "AwsAccountId", valid_613528
  var valid_613529 = path.getOrDefault("TemplateId")
  valid_613529 = validateParameter(valid_613529, JString, required = true,
                                 default = nil)
  if valid_613529 != nil:
    section.add "TemplateId", valid_613529
  result.add "path", section
  ## parameters in `query` object:
  ##   version-number: JInt
  ##                 : (Optional) The number for the version to describe. If a <code>VersionNumber</code> parameter value isn't provided, the latest version of the template is described.
  ##   alias-name: JString
  ##             : The alias of the template that you want to describe. If you name a specific alias, you describe the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. The keyword <code>$PUBLISHED</code> doesn't apply to templates.
  section = newJObject()
  var valid_613530 = query.getOrDefault("version-number")
  valid_613530 = validateParameter(valid_613530, JInt, required = false, default = nil)
  if valid_613530 != nil:
    section.add "version-number", valid_613530
  var valid_613531 = query.getOrDefault("alias-name")
  valid_613531 = validateParameter(valid_613531, JString, required = false,
                                 default = nil)
  if valid_613531 != nil:
    section.add "alias-name", valid_613531
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613532 = header.getOrDefault("X-Amz-Signature")
  valid_613532 = validateParameter(valid_613532, JString, required = false,
                                 default = nil)
  if valid_613532 != nil:
    section.add "X-Amz-Signature", valid_613532
  var valid_613533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613533 = validateParameter(valid_613533, JString, required = false,
                                 default = nil)
  if valid_613533 != nil:
    section.add "X-Amz-Content-Sha256", valid_613533
  var valid_613534 = header.getOrDefault("X-Amz-Date")
  valid_613534 = validateParameter(valid_613534, JString, required = false,
                                 default = nil)
  if valid_613534 != nil:
    section.add "X-Amz-Date", valid_613534
  var valid_613535 = header.getOrDefault("X-Amz-Credential")
  valid_613535 = validateParameter(valid_613535, JString, required = false,
                                 default = nil)
  if valid_613535 != nil:
    section.add "X-Amz-Credential", valid_613535
  var valid_613536 = header.getOrDefault("X-Amz-Security-Token")
  valid_613536 = validateParameter(valid_613536, JString, required = false,
                                 default = nil)
  if valid_613536 != nil:
    section.add "X-Amz-Security-Token", valid_613536
  var valid_613537 = header.getOrDefault("X-Amz-Algorithm")
  valid_613537 = validateParameter(valid_613537, JString, required = false,
                                 default = nil)
  if valid_613537 != nil:
    section.add "X-Amz-Algorithm", valid_613537
  var valid_613538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613538 = validateParameter(valid_613538, JString, required = false,
                                 default = nil)
  if valid_613538 != nil:
    section.add "X-Amz-SignedHeaders", valid_613538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613539: Call_DescribeTemplate_613525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a template's metadata.
  ## 
  let valid = call_613539.validator(path, query, header, formData, body)
  let scheme = call_613539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613539.url(scheme.get, call_613539.host, call_613539.base,
                         call_613539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613539, url, valid)

proc call*(call_613540: Call_DescribeTemplate_613525; AwsAccountId: string;
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
  var path_613541 = newJObject()
  var query_613542 = newJObject()
  add(query_613542, "version-number", newJInt(versionNumber))
  add(path_613541, "AwsAccountId", newJString(AwsAccountId))
  add(query_613542, "alias-name", newJString(aliasName))
  add(path_613541, "TemplateId", newJString(TemplateId))
  result = call_613540.call(path_613541, query_613542, nil, nil, nil)

var describeTemplate* = Call_DescribeTemplate_613525(name: "describeTemplate",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}",
    validator: validate_DescribeTemplate_613526, base: "/",
    url: url_DescribeTemplate_613527, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTemplate_613577 = ref object of OpenApiRestCall_612658
proc url_DeleteTemplate_613579(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTemplate_613578(path: JsonNode; query: JsonNode;
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
  var valid_613580 = path.getOrDefault("AwsAccountId")
  valid_613580 = validateParameter(valid_613580, JString, required = true,
                                 default = nil)
  if valid_613580 != nil:
    section.add "AwsAccountId", valid_613580
  var valid_613581 = path.getOrDefault("TemplateId")
  valid_613581 = validateParameter(valid_613581, JString, required = true,
                                 default = nil)
  if valid_613581 != nil:
    section.add "TemplateId", valid_613581
  result.add "path", section
  ## parameters in `query` object:
  ##   version-number: JInt
  ##                 : Specifies the version of the template that you want to delete. If you don't provide a version number, <code>DeleteTemplate</code> deletes all versions of the template. 
  section = newJObject()
  var valid_613582 = query.getOrDefault("version-number")
  valid_613582 = validateParameter(valid_613582, JInt, required = false, default = nil)
  if valid_613582 != nil:
    section.add "version-number", valid_613582
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613583 = header.getOrDefault("X-Amz-Signature")
  valid_613583 = validateParameter(valid_613583, JString, required = false,
                                 default = nil)
  if valid_613583 != nil:
    section.add "X-Amz-Signature", valid_613583
  var valid_613584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613584 = validateParameter(valid_613584, JString, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "X-Amz-Content-Sha256", valid_613584
  var valid_613585 = header.getOrDefault("X-Amz-Date")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "X-Amz-Date", valid_613585
  var valid_613586 = header.getOrDefault("X-Amz-Credential")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-Credential", valid_613586
  var valid_613587 = header.getOrDefault("X-Amz-Security-Token")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-Security-Token", valid_613587
  var valid_613588 = header.getOrDefault("X-Amz-Algorithm")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "X-Amz-Algorithm", valid_613588
  var valid_613589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613589 = validateParameter(valid_613589, JString, required = false,
                                 default = nil)
  if valid_613589 != nil:
    section.add "X-Amz-SignedHeaders", valid_613589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613590: Call_DeleteTemplate_613577; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a template.
  ## 
  let valid = call_613590.validator(path, query, header, formData, body)
  let scheme = call_613590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613590.url(scheme.get, call_613590.host, call_613590.base,
                         call_613590.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613590, url, valid)

proc call*(call_613591: Call_DeleteTemplate_613577; AwsAccountId: string;
          TemplateId: string; versionNumber: int = 0): Recallable =
  ## deleteTemplate
  ## Deletes a template.
  ##   versionNumber: int
  ##                : Specifies the version of the template that you want to delete. If you don't provide a version number, <code>DeleteTemplate</code> deletes all versions of the template. 
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template that you're deleting.
  ##   TemplateId: string (required)
  ##             : An ID for the template you want to delete.
  var path_613592 = newJObject()
  var query_613593 = newJObject()
  add(query_613593, "version-number", newJInt(versionNumber))
  add(path_613592, "AwsAccountId", newJString(AwsAccountId))
  add(path_613592, "TemplateId", newJString(TemplateId))
  result = call_613591.call(path_613592, query_613593, nil, nil, nil)

var deleteTemplate* = Call_DeleteTemplate_613577(name: "deleteTemplate",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}",
    validator: validate_DeleteTemplate_613578, base: "/", url: url_DeleteTemplate_613579,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTemplateAlias_613610 = ref object of OpenApiRestCall_612658
proc url_UpdateTemplateAlias_613612(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateTemplateAlias_613611(path: JsonNode; query: JsonNode;
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
  var valid_613613 = path.getOrDefault("AwsAccountId")
  valid_613613 = validateParameter(valid_613613, JString, required = true,
                                 default = nil)
  if valid_613613 != nil:
    section.add "AwsAccountId", valid_613613
  var valid_613614 = path.getOrDefault("AliasName")
  valid_613614 = validateParameter(valid_613614, JString, required = true,
                                 default = nil)
  if valid_613614 != nil:
    section.add "AliasName", valid_613614
  var valid_613615 = path.getOrDefault("TemplateId")
  valid_613615 = validateParameter(valid_613615, JString, required = true,
                                 default = nil)
  if valid_613615 != nil:
    section.add "TemplateId", valid_613615
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
  var valid_613616 = header.getOrDefault("X-Amz-Signature")
  valid_613616 = validateParameter(valid_613616, JString, required = false,
                                 default = nil)
  if valid_613616 != nil:
    section.add "X-Amz-Signature", valid_613616
  var valid_613617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "X-Amz-Content-Sha256", valid_613617
  var valid_613618 = header.getOrDefault("X-Amz-Date")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "X-Amz-Date", valid_613618
  var valid_613619 = header.getOrDefault("X-Amz-Credential")
  valid_613619 = validateParameter(valid_613619, JString, required = false,
                                 default = nil)
  if valid_613619 != nil:
    section.add "X-Amz-Credential", valid_613619
  var valid_613620 = header.getOrDefault("X-Amz-Security-Token")
  valid_613620 = validateParameter(valid_613620, JString, required = false,
                                 default = nil)
  if valid_613620 != nil:
    section.add "X-Amz-Security-Token", valid_613620
  var valid_613621 = header.getOrDefault("X-Amz-Algorithm")
  valid_613621 = validateParameter(valid_613621, JString, required = false,
                                 default = nil)
  if valid_613621 != nil:
    section.add "X-Amz-Algorithm", valid_613621
  var valid_613622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613622 = validateParameter(valid_613622, JString, required = false,
                                 default = nil)
  if valid_613622 != nil:
    section.add "X-Amz-SignedHeaders", valid_613622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613624: Call_UpdateTemplateAlias_613610; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the template alias of a template.
  ## 
  let valid = call_613624.validator(path, query, header, formData, body)
  let scheme = call_613624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613624.url(scheme.get, call_613624.host, call_613624.base,
                         call_613624.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613624, url, valid)

proc call*(call_613625: Call_UpdateTemplateAlias_613610; AwsAccountId: string;
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
  var path_613626 = newJObject()
  var body_613627 = newJObject()
  add(path_613626, "AwsAccountId", newJString(AwsAccountId))
  add(path_613626, "AliasName", newJString(AliasName))
  add(path_613626, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_613627 = body
  result = call_613625.call(path_613626, nil, nil, nil, body_613627)

var updateTemplateAlias* = Call_UpdateTemplateAlias_613610(
    name: "updateTemplateAlias", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}",
    validator: validate_UpdateTemplateAlias_613611, base: "/",
    url: url_UpdateTemplateAlias_613612, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTemplateAlias_613628 = ref object of OpenApiRestCall_612658
proc url_CreateTemplateAlias_613630(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTemplateAlias_613629(path: JsonNode; query: JsonNode;
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
  var valid_613631 = path.getOrDefault("AwsAccountId")
  valid_613631 = validateParameter(valid_613631, JString, required = true,
                                 default = nil)
  if valid_613631 != nil:
    section.add "AwsAccountId", valid_613631
  var valid_613632 = path.getOrDefault("AliasName")
  valid_613632 = validateParameter(valid_613632, JString, required = true,
                                 default = nil)
  if valid_613632 != nil:
    section.add "AliasName", valid_613632
  var valid_613633 = path.getOrDefault("TemplateId")
  valid_613633 = validateParameter(valid_613633, JString, required = true,
                                 default = nil)
  if valid_613633 != nil:
    section.add "TemplateId", valid_613633
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
  var valid_613634 = header.getOrDefault("X-Amz-Signature")
  valid_613634 = validateParameter(valid_613634, JString, required = false,
                                 default = nil)
  if valid_613634 != nil:
    section.add "X-Amz-Signature", valid_613634
  var valid_613635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613635 = validateParameter(valid_613635, JString, required = false,
                                 default = nil)
  if valid_613635 != nil:
    section.add "X-Amz-Content-Sha256", valid_613635
  var valid_613636 = header.getOrDefault("X-Amz-Date")
  valid_613636 = validateParameter(valid_613636, JString, required = false,
                                 default = nil)
  if valid_613636 != nil:
    section.add "X-Amz-Date", valid_613636
  var valid_613637 = header.getOrDefault("X-Amz-Credential")
  valid_613637 = validateParameter(valid_613637, JString, required = false,
                                 default = nil)
  if valid_613637 != nil:
    section.add "X-Amz-Credential", valid_613637
  var valid_613638 = header.getOrDefault("X-Amz-Security-Token")
  valid_613638 = validateParameter(valid_613638, JString, required = false,
                                 default = nil)
  if valid_613638 != nil:
    section.add "X-Amz-Security-Token", valid_613638
  var valid_613639 = header.getOrDefault("X-Amz-Algorithm")
  valid_613639 = validateParameter(valid_613639, JString, required = false,
                                 default = nil)
  if valid_613639 != nil:
    section.add "X-Amz-Algorithm", valid_613639
  var valid_613640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613640 = validateParameter(valid_613640, JString, required = false,
                                 default = nil)
  if valid_613640 != nil:
    section.add "X-Amz-SignedHeaders", valid_613640
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613642: Call_CreateTemplateAlias_613628; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a template alias for a template.
  ## 
  let valid = call_613642.validator(path, query, header, formData, body)
  let scheme = call_613642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613642.url(scheme.get, call_613642.host, call_613642.base,
                         call_613642.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613642, url, valid)

proc call*(call_613643: Call_CreateTemplateAlias_613628; AwsAccountId: string;
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
  var path_613644 = newJObject()
  var body_613645 = newJObject()
  add(path_613644, "AwsAccountId", newJString(AwsAccountId))
  add(path_613644, "AliasName", newJString(AliasName))
  add(path_613644, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_613645 = body
  result = call_613643.call(path_613644, nil, nil, nil, body_613645)

var createTemplateAlias* = Call_CreateTemplateAlias_613628(
    name: "createTemplateAlias", meth: HttpMethod.HttpPost,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}",
    validator: validate_CreateTemplateAlias_613629, base: "/",
    url: url_CreateTemplateAlias_613630, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTemplateAlias_613594 = ref object of OpenApiRestCall_612658
proc url_DescribeTemplateAlias_613596(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTemplateAlias_613595(path: JsonNode; query: JsonNode;
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
  var valid_613597 = path.getOrDefault("AwsAccountId")
  valid_613597 = validateParameter(valid_613597, JString, required = true,
                                 default = nil)
  if valid_613597 != nil:
    section.add "AwsAccountId", valid_613597
  var valid_613598 = path.getOrDefault("AliasName")
  valid_613598 = validateParameter(valid_613598, JString, required = true,
                                 default = nil)
  if valid_613598 != nil:
    section.add "AliasName", valid_613598
  var valid_613599 = path.getOrDefault("TemplateId")
  valid_613599 = validateParameter(valid_613599, JString, required = true,
                                 default = nil)
  if valid_613599 != nil:
    section.add "TemplateId", valid_613599
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
  var valid_613600 = header.getOrDefault("X-Amz-Signature")
  valid_613600 = validateParameter(valid_613600, JString, required = false,
                                 default = nil)
  if valid_613600 != nil:
    section.add "X-Amz-Signature", valid_613600
  var valid_613601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613601 = validateParameter(valid_613601, JString, required = false,
                                 default = nil)
  if valid_613601 != nil:
    section.add "X-Amz-Content-Sha256", valid_613601
  var valid_613602 = header.getOrDefault("X-Amz-Date")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "X-Amz-Date", valid_613602
  var valid_613603 = header.getOrDefault("X-Amz-Credential")
  valid_613603 = validateParameter(valid_613603, JString, required = false,
                                 default = nil)
  if valid_613603 != nil:
    section.add "X-Amz-Credential", valid_613603
  var valid_613604 = header.getOrDefault("X-Amz-Security-Token")
  valid_613604 = validateParameter(valid_613604, JString, required = false,
                                 default = nil)
  if valid_613604 != nil:
    section.add "X-Amz-Security-Token", valid_613604
  var valid_613605 = header.getOrDefault("X-Amz-Algorithm")
  valid_613605 = validateParameter(valid_613605, JString, required = false,
                                 default = nil)
  if valid_613605 != nil:
    section.add "X-Amz-Algorithm", valid_613605
  var valid_613606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613606 = validateParameter(valid_613606, JString, required = false,
                                 default = nil)
  if valid_613606 != nil:
    section.add "X-Amz-SignedHeaders", valid_613606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613607: Call_DescribeTemplateAlias_613594; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the template alias for a template.
  ## 
  let valid = call_613607.validator(path, query, header, formData, body)
  let scheme = call_613607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613607.url(scheme.get, call_613607.host, call_613607.base,
                         call_613607.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613607, url, valid)

proc call*(call_613608: Call_DescribeTemplateAlias_613594; AwsAccountId: string;
          AliasName: string; TemplateId: string): Recallable =
  ## describeTemplateAlias
  ## Describes the template alias for a template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template alias that you're describing.
  ##   AliasName: string (required)
  ##            : The name of the template alias that you want to describe. If you name a specific alias, you describe the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. The keyword <code>$PUBLISHED</code> doesn't apply to templates.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  var path_613609 = newJObject()
  add(path_613609, "AwsAccountId", newJString(AwsAccountId))
  add(path_613609, "AliasName", newJString(AliasName))
  add(path_613609, "TemplateId", newJString(TemplateId))
  result = call_613608.call(path_613609, nil, nil, nil, nil)

var describeTemplateAlias* = Call_DescribeTemplateAlias_613594(
    name: "describeTemplateAlias", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}",
    validator: validate_DescribeTemplateAlias_613595, base: "/",
    url: url_DescribeTemplateAlias_613596, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTemplateAlias_613646 = ref object of OpenApiRestCall_612658
proc url_DeleteTemplateAlias_613648(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTemplateAlias_613647(path: JsonNode; query: JsonNode;
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
  var valid_613649 = path.getOrDefault("AwsAccountId")
  valid_613649 = validateParameter(valid_613649, JString, required = true,
                                 default = nil)
  if valid_613649 != nil:
    section.add "AwsAccountId", valid_613649
  var valid_613650 = path.getOrDefault("AliasName")
  valid_613650 = validateParameter(valid_613650, JString, required = true,
                                 default = nil)
  if valid_613650 != nil:
    section.add "AliasName", valid_613650
  var valid_613651 = path.getOrDefault("TemplateId")
  valid_613651 = validateParameter(valid_613651, JString, required = true,
                                 default = nil)
  if valid_613651 != nil:
    section.add "TemplateId", valid_613651
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
  var valid_613652 = header.getOrDefault("X-Amz-Signature")
  valid_613652 = validateParameter(valid_613652, JString, required = false,
                                 default = nil)
  if valid_613652 != nil:
    section.add "X-Amz-Signature", valid_613652
  var valid_613653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613653 = validateParameter(valid_613653, JString, required = false,
                                 default = nil)
  if valid_613653 != nil:
    section.add "X-Amz-Content-Sha256", valid_613653
  var valid_613654 = header.getOrDefault("X-Amz-Date")
  valid_613654 = validateParameter(valid_613654, JString, required = false,
                                 default = nil)
  if valid_613654 != nil:
    section.add "X-Amz-Date", valid_613654
  var valid_613655 = header.getOrDefault("X-Amz-Credential")
  valid_613655 = validateParameter(valid_613655, JString, required = false,
                                 default = nil)
  if valid_613655 != nil:
    section.add "X-Amz-Credential", valid_613655
  var valid_613656 = header.getOrDefault("X-Amz-Security-Token")
  valid_613656 = validateParameter(valid_613656, JString, required = false,
                                 default = nil)
  if valid_613656 != nil:
    section.add "X-Amz-Security-Token", valid_613656
  var valid_613657 = header.getOrDefault("X-Amz-Algorithm")
  valid_613657 = validateParameter(valid_613657, JString, required = false,
                                 default = nil)
  if valid_613657 != nil:
    section.add "X-Amz-Algorithm", valid_613657
  var valid_613658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613658 = validateParameter(valid_613658, JString, required = false,
                                 default = nil)
  if valid_613658 != nil:
    section.add "X-Amz-SignedHeaders", valid_613658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613659: Call_DeleteTemplateAlias_613646; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the item that the specified template alias points to. If you provide a specific alias, you delete the version of the template that the alias points to.
  ## 
  let valid = call_613659.validator(path, query, header, formData, body)
  let scheme = call_613659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613659.url(scheme.get, call_613659.host, call_613659.base,
                         call_613659.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613659, url, valid)

proc call*(call_613660: Call_DeleteTemplateAlias_613646; AwsAccountId: string;
          AliasName: string; TemplateId: string): Recallable =
  ## deleteTemplateAlias
  ## Deletes the item that the specified template alias points to. If you provide a specific alias, you delete the version of the template that the alias points to.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the item to delete.
  ##   AliasName: string (required)
  ##            : The name for the template alias. If you name a specific alias, you delete the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. 
  ##   TemplateId: string (required)
  ##             : The ID for the template that the specified alias is for.
  var path_613661 = newJObject()
  add(path_613661, "AwsAccountId", newJString(AwsAccountId))
  add(path_613661, "AliasName", newJString(AliasName))
  add(path_613661, "TemplateId", newJString(TemplateId))
  result = call_613660.call(path_613661, nil, nil, nil, nil)

var deleteTemplateAlias* = Call_DeleteTemplateAlias_613646(
    name: "deleteTemplateAlias", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}",
    validator: validate_DeleteTemplateAlias_613647, base: "/",
    url: url_DeleteTemplateAlias_613648, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSet_613677 = ref object of OpenApiRestCall_612658
proc url_UpdateDataSet_613679(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDataSet_613678(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613680 = path.getOrDefault("AwsAccountId")
  valid_613680 = validateParameter(valid_613680, JString, required = true,
                                 default = nil)
  if valid_613680 != nil:
    section.add "AwsAccountId", valid_613680
  var valid_613681 = path.getOrDefault("DataSetId")
  valid_613681 = validateParameter(valid_613681, JString, required = true,
                                 default = nil)
  if valid_613681 != nil:
    section.add "DataSetId", valid_613681
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
  var valid_613682 = header.getOrDefault("X-Amz-Signature")
  valid_613682 = validateParameter(valid_613682, JString, required = false,
                                 default = nil)
  if valid_613682 != nil:
    section.add "X-Amz-Signature", valid_613682
  var valid_613683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613683 = validateParameter(valid_613683, JString, required = false,
                                 default = nil)
  if valid_613683 != nil:
    section.add "X-Amz-Content-Sha256", valid_613683
  var valid_613684 = header.getOrDefault("X-Amz-Date")
  valid_613684 = validateParameter(valid_613684, JString, required = false,
                                 default = nil)
  if valid_613684 != nil:
    section.add "X-Amz-Date", valid_613684
  var valid_613685 = header.getOrDefault("X-Amz-Credential")
  valid_613685 = validateParameter(valid_613685, JString, required = false,
                                 default = nil)
  if valid_613685 != nil:
    section.add "X-Amz-Credential", valid_613685
  var valid_613686 = header.getOrDefault("X-Amz-Security-Token")
  valid_613686 = validateParameter(valid_613686, JString, required = false,
                                 default = nil)
  if valid_613686 != nil:
    section.add "X-Amz-Security-Token", valid_613686
  var valid_613687 = header.getOrDefault("X-Amz-Algorithm")
  valid_613687 = validateParameter(valid_613687, JString, required = false,
                                 default = nil)
  if valid_613687 != nil:
    section.add "X-Amz-Algorithm", valid_613687
  var valid_613688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613688 = validateParameter(valid_613688, JString, required = false,
                                 default = nil)
  if valid_613688 != nil:
    section.add "X-Amz-SignedHeaders", valid_613688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613690: Call_UpdateDataSet_613677; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a dataset.
  ## 
  let valid = call_613690.validator(path, query, header, formData, body)
  let scheme = call_613690.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613690.url(scheme.get, call_613690.host, call_613690.base,
                         call_613690.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613690, url, valid)

proc call*(call_613691: Call_UpdateDataSet_613677; AwsAccountId: string;
          DataSetId: string; body: JsonNode): Recallable =
  ## updateDataSet
  ## Updates a dataset.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset that you want to update. This ID is unique per AWS Region for each AWS account.
  ##   body: JObject (required)
  var path_613692 = newJObject()
  var body_613693 = newJObject()
  add(path_613692, "AwsAccountId", newJString(AwsAccountId))
  add(path_613692, "DataSetId", newJString(DataSetId))
  if body != nil:
    body_613693 = body
  result = call_613691.call(path_613692, nil, nil, nil, body_613693)

var updateDataSet* = Call_UpdateDataSet_613677(name: "updateDataSet",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}",
    validator: validate_UpdateDataSet_613678, base: "/", url: url_UpdateDataSet_613679,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSet_613662 = ref object of OpenApiRestCall_612658
proc url_DescribeDataSet_613664(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDataSet_613663(path: JsonNode; query: JsonNode;
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
  var valid_613665 = path.getOrDefault("AwsAccountId")
  valid_613665 = validateParameter(valid_613665, JString, required = true,
                                 default = nil)
  if valid_613665 != nil:
    section.add "AwsAccountId", valid_613665
  var valid_613666 = path.getOrDefault("DataSetId")
  valid_613666 = validateParameter(valid_613666, JString, required = true,
                                 default = nil)
  if valid_613666 != nil:
    section.add "DataSetId", valid_613666
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
  var valid_613667 = header.getOrDefault("X-Amz-Signature")
  valid_613667 = validateParameter(valid_613667, JString, required = false,
                                 default = nil)
  if valid_613667 != nil:
    section.add "X-Amz-Signature", valid_613667
  var valid_613668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613668 = validateParameter(valid_613668, JString, required = false,
                                 default = nil)
  if valid_613668 != nil:
    section.add "X-Amz-Content-Sha256", valid_613668
  var valid_613669 = header.getOrDefault("X-Amz-Date")
  valid_613669 = validateParameter(valid_613669, JString, required = false,
                                 default = nil)
  if valid_613669 != nil:
    section.add "X-Amz-Date", valid_613669
  var valid_613670 = header.getOrDefault("X-Amz-Credential")
  valid_613670 = validateParameter(valid_613670, JString, required = false,
                                 default = nil)
  if valid_613670 != nil:
    section.add "X-Amz-Credential", valid_613670
  var valid_613671 = header.getOrDefault("X-Amz-Security-Token")
  valid_613671 = validateParameter(valid_613671, JString, required = false,
                                 default = nil)
  if valid_613671 != nil:
    section.add "X-Amz-Security-Token", valid_613671
  var valid_613672 = header.getOrDefault("X-Amz-Algorithm")
  valid_613672 = validateParameter(valid_613672, JString, required = false,
                                 default = nil)
  if valid_613672 != nil:
    section.add "X-Amz-Algorithm", valid_613672
  var valid_613673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613673 = validateParameter(valid_613673, JString, required = false,
                                 default = nil)
  if valid_613673 != nil:
    section.add "X-Amz-SignedHeaders", valid_613673
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613674: Call_DescribeDataSet_613662; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a dataset. 
  ## 
  let valid = call_613674.validator(path, query, header, formData, body)
  let scheme = call_613674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613674.url(scheme.get, call_613674.host, call_613674.base,
                         call_613674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613674, url, valid)

proc call*(call_613675: Call_DescribeDataSet_613662; AwsAccountId: string;
          DataSetId: string): Recallable =
  ## describeDataSet
  ## Describes a dataset. 
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset that you want to create. This ID is unique per AWS Region for each AWS account.
  var path_613676 = newJObject()
  add(path_613676, "AwsAccountId", newJString(AwsAccountId))
  add(path_613676, "DataSetId", newJString(DataSetId))
  result = call_613675.call(path_613676, nil, nil, nil, nil)

var describeDataSet* = Call_DescribeDataSet_613662(name: "describeDataSet",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}",
    validator: validate_DescribeDataSet_613663, base: "/", url: url_DescribeDataSet_613664,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSet_613694 = ref object of OpenApiRestCall_612658
proc url_DeleteDataSet_613696(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDataSet_613695(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613697 = path.getOrDefault("AwsAccountId")
  valid_613697 = validateParameter(valid_613697, JString, required = true,
                                 default = nil)
  if valid_613697 != nil:
    section.add "AwsAccountId", valid_613697
  var valid_613698 = path.getOrDefault("DataSetId")
  valid_613698 = validateParameter(valid_613698, JString, required = true,
                                 default = nil)
  if valid_613698 != nil:
    section.add "DataSetId", valid_613698
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
  var valid_613699 = header.getOrDefault("X-Amz-Signature")
  valid_613699 = validateParameter(valid_613699, JString, required = false,
                                 default = nil)
  if valid_613699 != nil:
    section.add "X-Amz-Signature", valid_613699
  var valid_613700 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613700 = validateParameter(valid_613700, JString, required = false,
                                 default = nil)
  if valid_613700 != nil:
    section.add "X-Amz-Content-Sha256", valid_613700
  var valid_613701 = header.getOrDefault("X-Amz-Date")
  valid_613701 = validateParameter(valid_613701, JString, required = false,
                                 default = nil)
  if valid_613701 != nil:
    section.add "X-Amz-Date", valid_613701
  var valid_613702 = header.getOrDefault("X-Amz-Credential")
  valid_613702 = validateParameter(valid_613702, JString, required = false,
                                 default = nil)
  if valid_613702 != nil:
    section.add "X-Amz-Credential", valid_613702
  var valid_613703 = header.getOrDefault("X-Amz-Security-Token")
  valid_613703 = validateParameter(valid_613703, JString, required = false,
                                 default = nil)
  if valid_613703 != nil:
    section.add "X-Amz-Security-Token", valid_613703
  var valid_613704 = header.getOrDefault("X-Amz-Algorithm")
  valid_613704 = validateParameter(valid_613704, JString, required = false,
                                 default = nil)
  if valid_613704 != nil:
    section.add "X-Amz-Algorithm", valid_613704
  var valid_613705 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613705 = validateParameter(valid_613705, JString, required = false,
                                 default = nil)
  if valid_613705 != nil:
    section.add "X-Amz-SignedHeaders", valid_613705
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613706: Call_DeleteDataSet_613694; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a dataset.
  ## 
  let valid = call_613706.validator(path, query, header, formData, body)
  let scheme = call_613706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613706.url(scheme.get, call_613706.host, call_613706.base,
                         call_613706.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613706, url, valid)

proc call*(call_613707: Call_DeleteDataSet_613694; AwsAccountId: string;
          DataSetId: string): Recallable =
  ## deleteDataSet
  ## Deletes a dataset.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset that you want to create. This ID is unique per AWS Region for each AWS account.
  var path_613708 = newJObject()
  add(path_613708, "AwsAccountId", newJString(AwsAccountId))
  add(path_613708, "DataSetId", newJString(DataSetId))
  result = call_613707.call(path_613708, nil, nil, nil, nil)

var deleteDataSet* = Call_DeleteDataSet_613694(name: "deleteDataSet",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}",
    validator: validate_DeleteDataSet_613695, base: "/", url: url_DeleteDataSet_613696,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSource_613724 = ref object of OpenApiRestCall_612658
proc url_UpdateDataSource_613726(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDataSource_613725(path: JsonNode; query: JsonNode;
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
  var valid_613727 = path.getOrDefault("DataSourceId")
  valid_613727 = validateParameter(valid_613727, JString, required = true,
                                 default = nil)
  if valid_613727 != nil:
    section.add "DataSourceId", valid_613727
  var valid_613728 = path.getOrDefault("AwsAccountId")
  valid_613728 = validateParameter(valid_613728, JString, required = true,
                                 default = nil)
  if valid_613728 != nil:
    section.add "AwsAccountId", valid_613728
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
  var valid_613729 = header.getOrDefault("X-Amz-Signature")
  valid_613729 = validateParameter(valid_613729, JString, required = false,
                                 default = nil)
  if valid_613729 != nil:
    section.add "X-Amz-Signature", valid_613729
  var valid_613730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613730 = validateParameter(valid_613730, JString, required = false,
                                 default = nil)
  if valid_613730 != nil:
    section.add "X-Amz-Content-Sha256", valid_613730
  var valid_613731 = header.getOrDefault("X-Amz-Date")
  valid_613731 = validateParameter(valid_613731, JString, required = false,
                                 default = nil)
  if valid_613731 != nil:
    section.add "X-Amz-Date", valid_613731
  var valid_613732 = header.getOrDefault("X-Amz-Credential")
  valid_613732 = validateParameter(valid_613732, JString, required = false,
                                 default = nil)
  if valid_613732 != nil:
    section.add "X-Amz-Credential", valid_613732
  var valid_613733 = header.getOrDefault("X-Amz-Security-Token")
  valid_613733 = validateParameter(valid_613733, JString, required = false,
                                 default = nil)
  if valid_613733 != nil:
    section.add "X-Amz-Security-Token", valid_613733
  var valid_613734 = header.getOrDefault("X-Amz-Algorithm")
  valid_613734 = validateParameter(valid_613734, JString, required = false,
                                 default = nil)
  if valid_613734 != nil:
    section.add "X-Amz-Algorithm", valid_613734
  var valid_613735 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613735 = validateParameter(valid_613735, JString, required = false,
                                 default = nil)
  if valid_613735 != nil:
    section.add "X-Amz-SignedHeaders", valid_613735
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613737: Call_UpdateDataSource_613724; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a data source.
  ## 
  let valid = call_613737.validator(path, query, header, formData, body)
  let scheme = call_613737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613737.url(scheme.get, call_613737.host, call_613737.base,
                         call_613737.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613737, url, valid)

proc call*(call_613738: Call_UpdateDataSource_613724; DataSourceId: string;
          AwsAccountId: string; body: JsonNode): Recallable =
  ## updateDataSource
  ## Updates a data source.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account. 
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   body: JObject (required)
  var path_613739 = newJObject()
  var body_613740 = newJObject()
  add(path_613739, "DataSourceId", newJString(DataSourceId))
  add(path_613739, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_613740 = body
  result = call_613738.call(path_613739, nil, nil, nil, body_613740)

var updateDataSource* = Call_UpdateDataSource_613724(name: "updateDataSource",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}",
    validator: validate_UpdateDataSource_613725, base: "/",
    url: url_UpdateDataSource_613726, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSource_613709 = ref object of OpenApiRestCall_612658
proc url_DescribeDataSource_613711(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDataSource_613710(path: JsonNode; query: JsonNode;
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
  var valid_613712 = path.getOrDefault("DataSourceId")
  valid_613712 = validateParameter(valid_613712, JString, required = true,
                                 default = nil)
  if valid_613712 != nil:
    section.add "DataSourceId", valid_613712
  var valid_613713 = path.getOrDefault("AwsAccountId")
  valid_613713 = validateParameter(valid_613713, JString, required = true,
                                 default = nil)
  if valid_613713 != nil:
    section.add "AwsAccountId", valid_613713
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
  var valid_613714 = header.getOrDefault("X-Amz-Signature")
  valid_613714 = validateParameter(valid_613714, JString, required = false,
                                 default = nil)
  if valid_613714 != nil:
    section.add "X-Amz-Signature", valid_613714
  var valid_613715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613715 = validateParameter(valid_613715, JString, required = false,
                                 default = nil)
  if valid_613715 != nil:
    section.add "X-Amz-Content-Sha256", valid_613715
  var valid_613716 = header.getOrDefault("X-Amz-Date")
  valid_613716 = validateParameter(valid_613716, JString, required = false,
                                 default = nil)
  if valid_613716 != nil:
    section.add "X-Amz-Date", valid_613716
  var valid_613717 = header.getOrDefault("X-Amz-Credential")
  valid_613717 = validateParameter(valid_613717, JString, required = false,
                                 default = nil)
  if valid_613717 != nil:
    section.add "X-Amz-Credential", valid_613717
  var valid_613718 = header.getOrDefault("X-Amz-Security-Token")
  valid_613718 = validateParameter(valid_613718, JString, required = false,
                                 default = nil)
  if valid_613718 != nil:
    section.add "X-Amz-Security-Token", valid_613718
  var valid_613719 = header.getOrDefault("X-Amz-Algorithm")
  valid_613719 = validateParameter(valid_613719, JString, required = false,
                                 default = nil)
  if valid_613719 != nil:
    section.add "X-Amz-Algorithm", valid_613719
  var valid_613720 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613720 = validateParameter(valid_613720, JString, required = false,
                                 default = nil)
  if valid_613720 != nil:
    section.add "X-Amz-SignedHeaders", valid_613720
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613721: Call_DescribeDataSource_613709; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a data source.
  ## 
  let valid = call_613721.validator(path, query, header, formData, body)
  let scheme = call_613721.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613721.url(scheme.get, call_613721.host, call_613721.base,
                         call_613721.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613721, url, valid)

proc call*(call_613722: Call_DescribeDataSource_613709; DataSourceId: string;
          AwsAccountId: string): Recallable =
  ## describeDataSource
  ## Describes a data source.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  var path_613723 = newJObject()
  add(path_613723, "DataSourceId", newJString(DataSourceId))
  add(path_613723, "AwsAccountId", newJString(AwsAccountId))
  result = call_613722.call(path_613723, nil, nil, nil, nil)

var describeDataSource* = Call_DescribeDataSource_613709(
    name: "describeDataSource", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}",
    validator: validate_DescribeDataSource_613710, base: "/",
    url: url_DescribeDataSource_613711, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSource_613741 = ref object of OpenApiRestCall_612658
proc url_DeleteDataSource_613743(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDataSource_613742(path: JsonNode; query: JsonNode;
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
  var valid_613744 = path.getOrDefault("DataSourceId")
  valid_613744 = validateParameter(valid_613744, JString, required = true,
                                 default = nil)
  if valid_613744 != nil:
    section.add "DataSourceId", valid_613744
  var valid_613745 = path.getOrDefault("AwsAccountId")
  valid_613745 = validateParameter(valid_613745, JString, required = true,
                                 default = nil)
  if valid_613745 != nil:
    section.add "AwsAccountId", valid_613745
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
  var valid_613746 = header.getOrDefault("X-Amz-Signature")
  valid_613746 = validateParameter(valid_613746, JString, required = false,
                                 default = nil)
  if valid_613746 != nil:
    section.add "X-Amz-Signature", valid_613746
  var valid_613747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613747 = validateParameter(valid_613747, JString, required = false,
                                 default = nil)
  if valid_613747 != nil:
    section.add "X-Amz-Content-Sha256", valid_613747
  var valid_613748 = header.getOrDefault("X-Amz-Date")
  valid_613748 = validateParameter(valid_613748, JString, required = false,
                                 default = nil)
  if valid_613748 != nil:
    section.add "X-Amz-Date", valid_613748
  var valid_613749 = header.getOrDefault("X-Amz-Credential")
  valid_613749 = validateParameter(valid_613749, JString, required = false,
                                 default = nil)
  if valid_613749 != nil:
    section.add "X-Amz-Credential", valid_613749
  var valid_613750 = header.getOrDefault("X-Amz-Security-Token")
  valid_613750 = validateParameter(valid_613750, JString, required = false,
                                 default = nil)
  if valid_613750 != nil:
    section.add "X-Amz-Security-Token", valid_613750
  var valid_613751 = header.getOrDefault("X-Amz-Algorithm")
  valid_613751 = validateParameter(valid_613751, JString, required = false,
                                 default = nil)
  if valid_613751 != nil:
    section.add "X-Amz-Algorithm", valid_613751
  var valid_613752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613752 = validateParameter(valid_613752, JString, required = false,
                                 default = nil)
  if valid_613752 != nil:
    section.add "X-Amz-SignedHeaders", valid_613752
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613753: Call_DeleteDataSource_613741; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the data source permanently. This action breaks all the datasets that reference the deleted data source.
  ## 
  let valid = call_613753.validator(path, query, header, formData, body)
  let scheme = call_613753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613753.url(scheme.get, call_613753.host, call_613753.base,
                         call_613753.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613753, url, valid)

proc call*(call_613754: Call_DeleteDataSource_613741; DataSourceId: string;
          AwsAccountId: string): Recallable =
  ## deleteDataSource
  ## Deletes the data source permanently. This action breaks all the datasets that reference the deleted data source.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  var path_613755 = newJObject()
  add(path_613755, "DataSourceId", newJString(DataSourceId))
  add(path_613755, "AwsAccountId", newJString(AwsAccountId))
  result = call_613754.call(path_613755, nil, nil, nil, nil)

var deleteDataSource* = Call_DeleteDataSource_613741(name: "deleteDataSource",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}",
    validator: validate_DeleteDataSource_613742, base: "/",
    url: url_DeleteDataSource_613743, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_613772 = ref object of OpenApiRestCall_612658
proc url_UpdateGroup_613774(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGroup_613773(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613775 = path.getOrDefault("GroupName")
  valid_613775 = validateParameter(valid_613775, JString, required = true,
                                 default = nil)
  if valid_613775 != nil:
    section.add "GroupName", valid_613775
  var valid_613776 = path.getOrDefault("AwsAccountId")
  valid_613776 = validateParameter(valid_613776, JString, required = true,
                                 default = nil)
  if valid_613776 != nil:
    section.add "AwsAccountId", valid_613776
  var valid_613777 = path.getOrDefault("Namespace")
  valid_613777 = validateParameter(valid_613777, JString, required = true,
                                 default = nil)
  if valid_613777 != nil:
    section.add "Namespace", valid_613777
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
  var valid_613778 = header.getOrDefault("X-Amz-Signature")
  valid_613778 = validateParameter(valid_613778, JString, required = false,
                                 default = nil)
  if valid_613778 != nil:
    section.add "X-Amz-Signature", valid_613778
  var valid_613779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613779 = validateParameter(valid_613779, JString, required = false,
                                 default = nil)
  if valid_613779 != nil:
    section.add "X-Amz-Content-Sha256", valid_613779
  var valid_613780 = header.getOrDefault("X-Amz-Date")
  valid_613780 = validateParameter(valid_613780, JString, required = false,
                                 default = nil)
  if valid_613780 != nil:
    section.add "X-Amz-Date", valid_613780
  var valid_613781 = header.getOrDefault("X-Amz-Credential")
  valid_613781 = validateParameter(valid_613781, JString, required = false,
                                 default = nil)
  if valid_613781 != nil:
    section.add "X-Amz-Credential", valid_613781
  var valid_613782 = header.getOrDefault("X-Amz-Security-Token")
  valid_613782 = validateParameter(valid_613782, JString, required = false,
                                 default = nil)
  if valid_613782 != nil:
    section.add "X-Amz-Security-Token", valid_613782
  var valid_613783 = header.getOrDefault("X-Amz-Algorithm")
  valid_613783 = validateParameter(valid_613783, JString, required = false,
                                 default = nil)
  if valid_613783 != nil:
    section.add "X-Amz-Algorithm", valid_613783
  var valid_613784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613784 = validateParameter(valid_613784, JString, required = false,
                                 default = nil)
  if valid_613784 != nil:
    section.add "X-Amz-SignedHeaders", valid_613784
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613786: Call_UpdateGroup_613772; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes a group description. 
  ## 
  let valid = call_613786.validator(path, query, header, formData, body)
  let scheme = call_613786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613786.url(scheme.get, call_613786.host, call_613786.base,
                         call_613786.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613786, url, valid)

proc call*(call_613787: Call_UpdateGroup_613772; GroupName: string;
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
  var path_613788 = newJObject()
  var body_613789 = newJObject()
  add(path_613788, "GroupName", newJString(GroupName))
  add(path_613788, "AwsAccountId", newJString(AwsAccountId))
  add(path_613788, "Namespace", newJString(Namespace))
  if body != nil:
    body_613789 = body
  result = call_613787.call(path_613788, nil, nil, nil, body_613789)

var updateGroup* = Call_UpdateGroup_613772(name: "updateGroup",
                                        meth: HttpMethod.HttpPut,
                                        host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}",
                                        validator: validate_UpdateGroup_613773,
                                        base: "/", url: url_UpdateGroup_613774,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGroup_613756 = ref object of OpenApiRestCall_612658
proc url_DescribeGroup_613758(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeGroup_613757(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613759 = path.getOrDefault("GroupName")
  valid_613759 = validateParameter(valid_613759, JString, required = true,
                                 default = nil)
  if valid_613759 != nil:
    section.add "GroupName", valid_613759
  var valid_613760 = path.getOrDefault("AwsAccountId")
  valid_613760 = validateParameter(valid_613760, JString, required = true,
                                 default = nil)
  if valid_613760 != nil:
    section.add "AwsAccountId", valid_613760
  var valid_613761 = path.getOrDefault("Namespace")
  valid_613761 = validateParameter(valid_613761, JString, required = true,
                                 default = nil)
  if valid_613761 != nil:
    section.add "Namespace", valid_613761
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
  var valid_613762 = header.getOrDefault("X-Amz-Signature")
  valid_613762 = validateParameter(valid_613762, JString, required = false,
                                 default = nil)
  if valid_613762 != nil:
    section.add "X-Amz-Signature", valid_613762
  var valid_613763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613763 = validateParameter(valid_613763, JString, required = false,
                                 default = nil)
  if valid_613763 != nil:
    section.add "X-Amz-Content-Sha256", valid_613763
  var valid_613764 = header.getOrDefault("X-Amz-Date")
  valid_613764 = validateParameter(valid_613764, JString, required = false,
                                 default = nil)
  if valid_613764 != nil:
    section.add "X-Amz-Date", valid_613764
  var valid_613765 = header.getOrDefault("X-Amz-Credential")
  valid_613765 = validateParameter(valid_613765, JString, required = false,
                                 default = nil)
  if valid_613765 != nil:
    section.add "X-Amz-Credential", valid_613765
  var valid_613766 = header.getOrDefault("X-Amz-Security-Token")
  valid_613766 = validateParameter(valid_613766, JString, required = false,
                                 default = nil)
  if valid_613766 != nil:
    section.add "X-Amz-Security-Token", valid_613766
  var valid_613767 = header.getOrDefault("X-Amz-Algorithm")
  valid_613767 = validateParameter(valid_613767, JString, required = false,
                                 default = nil)
  if valid_613767 != nil:
    section.add "X-Amz-Algorithm", valid_613767
  var valid_613768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613768 = validateParameter(valid_613768, JString, required = false,
                                 default = nil)
  if valid_613768 != nil:
    section.add "X-Amz-SignedHeaders", valid_613768
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613769: Call_DescribeGroup_613756; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an Amazon QuickSight group's description and Amazon Resource Name (ARN). 
  ## 
  let valid = call_613769.validator(path, query, header, formData, body)
  let scheme = call_613769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613769.url(scheme.get, call_613769.host, call_613769.base,
                         call_613769.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613769, url, valid)

proc call*(call_613770: Call_DescribeGroup_613756; GroupName: string;
          AwsAccountId: string; Namespace: string): Recallable =
  ## describeGroup
  ## Returns an Amazon QuickSight group's description and Amazon Resource Name (ARN). 
  ##   GroupName: string (required)
  ##            : The name of the group that you want to describe.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_613771 = newJObject()
  add(path_613771, "GroupName", newJString(GroupName))
  add(path_613771, "AwsAccountId", newJString(AwsAccountId))
  add(path_613771, "Namespace", newJString(Namespace))
  result = call_613770.call(path_613771, nil, nil, nil, nil)

var describeGroup* = Call_DescribeGroup_613756(name: "describeGroup",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}",
    validator: validate_DescribeGroup_613757, base: "/", url: url_DescribeGroup_613758,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_613790 = ref object of OpenApiRestCall_612658
proc url_DeleteGroup_613792(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGroup_613791(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613793 = path.getOrDefault("GroupName")
  valid_613793 = validateParameter(valid_613793, JString, required = true,
                                 default = nil)
  if valid_613793 != nil:
    section.add "GroupName", valid_613793
  var valid_613794 = path.getOrDefault("AwsAccountId")
  valid_613794 = validateParameter(valid_613794, JString, required = true,
                                 default = nil)
  if valid_613794 != nil:
    section.add "AwsAccountId", valid_613794
  var valid_613795 = path.getOrDefault("Namespace")
  valid_613795 = validateParameter(valid_613795, JString, required = true,
                                 default = nil)
  if valid_613795 != nil:
    section.add "Namespace", valid_613795
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
  var valid_613796 = header.getOrDefault("X-Amz-Signature")
  valid_613796 = validateParameter(valid_613796, JString, required = false,
                                 default = nil)
  if valid_613796 != nil:
    section.add "X-Amz-Signature", valid_613796
  var valid_613797 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613797 = validateParameter(valid_613797, JString, required = false,
                                 default = nil)
  if valid_613797 != nil:
    section.add "X-Amz-Content-Sha256", valid_613797
  var valid_613798 = header.getOrDefault("X-Amz-Date")
  valid_613798 = validateParameter(valid_613798, JString, required = false,
                                 default = nil)
  if valid_613798 != nil:
    section.add "X-Amz-Date", valid_613798
  var valid_613799 = header.getOrDefault("X-Amz-Credential")
  valid_613799 = validateParameter(valid_613799, JString, required = false,
                                 default = nil)
  if valid_613799 != nil:
    section.add "X-Amz-Credential", valid_613799
  var valid_613800 = header.getOrDefault("X-Amz-Security-Token")
  valid_613800 = validateParameter(valid_613800, JString, required = false,
                                 default = nil)
  if valid_613800 != nil:
    section.add "X-Amz-Security-Token", valid_613800
  var valid_613801 = header.getOrDefault("X-Amz-Algorithm")
  valid_613801 = validateParameter(valid_613801, JString, required = false,
                                 default = nil)
  if valid_613801 != nil:
    section.add "X-Amz-Algorithm", valid_613801
  var valid_613802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613802 = validateParameter(valid_613802, JString, required = false,
                                 default = nil)
  if valid_613802 != nil:
    section.add "X-Amz-SignedHeaders", valid_613802
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613803: Call_DeleteGroup_613790; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a user group from Amazon QuickSight. 
  ## 
  let valid = call_613803.validator(path, query, header, formData, body)
  let scheme = call_613803.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613803.url(scheme.get, call_613803.host, call_613803.base,
                         call_613803.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613803, url, valid)

proc call*(call_613804: Call_DeleteGroup_613790; GroupName: string;
          AwsAccountId: string; Namespace: string): Recallable =
  ## deleteGroup
  ## Removes a user group from Amazon QuickSight. 
  ##   GroupName: string (required)
  ##            : The name of the group that you want to delete.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_613805 = newJObject()
  add(path_613805, "GroupName", newJString(GroupName))
  add(path_613805, "AwsAccountId", newJString(AwsAccountId))
  add(path_613805, "Namespace", newJString(Namespace))
  result = call_613804.call(path_613805, nil, nil, nil, nil)

var deleteGroup* = Call_DeleteGroup_613790(name: "deleteGroup",
                                        meth: HttpMethod.HttpDelete,
                                        host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}",
                                        validator: validate_DeleteGroup_613791,
                                        base: "/", url: url_DeleteGroup_613792,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIAMPolicyAssignment_613806 = ref object of OpenApiRestCall_612658
proc url_DeleteIAMPolicyAssignment_613808(protocol: Scheme; host: string;
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

proc validate_DeleteIAMPolicyAssignment_613807(path: JsonNode; query: JsonNode;
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
  var valid_613809 = path.getOrDefault("AwsAccountId")
  valid_613809 = validateParameter(valid_613809, JString, required = true,
                                 default = nil)
  if valid_613809 != nil:
    section.add "AwsAccountId", valid_613809
  var valid_613810 = path.getOrDefault("Namespace")
  valid_613810 = validateParameter(valid_613810, JString, required = true,
                                 default = nil)
  if valid_613810 != nil:
    section.add "Namespace", valid_613810
  var valid_613811 = path.getOrDefault("AssignmentName")
  valid_613811 = validateParameter(valid_613811, JString, required = true,
                                 default = nil)
  if valid_613811 != nil:
    section.add "AssignmentName", valid_613811
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
  var valid_613812 = header.getOrDefault("X-Amz-Signature")
  valid_613812 = validateParameter(valid_613812, JString, required = false,
                                 default = nil)
  if valid_613812 != nil:
    section.add "X-Amz-Signature", valid_613812
  var valid_613813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613813 = validateParameter(valid_613813, JString, required = false,
                                 default = nil)
  if valid_613813 != nil:
    section.add "X-Amz-Content-Sha256", valid_613813
  var valid_613814 = header.getOrDefault("X-Amz-Date")
  valid_613814 = validateParameter(valid_613814, JString, required = false,
                                 default = nil)
  if valid_613814 != nil:
    section.add "X-Amz-Date", valid_613814
  var valid_613815 = header.getOrDefault("X-Amz-Credential")
  valid_613815 = validateParameter(valid_613815, JString, required = false,
                                 default = nil)
  if valid_613815 != nil:
    section.add "X-Amz-Credential", valid_613815
  var valid_613816 = header.getOrDefault("X-Amz-Security-Token")
  valid_613816 = validateParameter(valid_613816, JString, required = false,
                                 default = nil)
  if valid_613816 != nil:
    section.add "X-Amz-Security-Token", valid_613816
  var valid_613817 = header.getOrDefault("X-Amz-Algorithm")
  valid_613817 = validateParameter(valid_613817, JString, required = false,
                                 default = nil)
  if valid_613817 != nil:
    section.add "X-Amz-Algorithm", valid_613817
  var valid_613818 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613818 = validateParameter(valid_613818, JString, required = false,
                                 default = nil)
  if valid_613818 != nil:
    section.add "X-Amz-SignedHeaders", valid_613818
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613819: Call_DeleteIAMPolicyAssignment_613806; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing IAM policy assignment.
  ## 
  let valid = call_613819.validator(path, query, header, formData, body)
  let scheme = call_613819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613819.url(scheme.get, call_613819.host, call_613819.base,
                         call_613819.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613819, url, valid)

proc call*(call_613820: Call_DeleteIAMPolicyAssignment_613806;
          AwsAccountId: string; Namespace: string; AssignmentName: string): Recallable =
  ## deleteIAMPolicyAssignment
  ## Deletes an existing IAM policy assignment.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID where you want to delete the IAM policy assignment.
  ##   Namespace: string (required)
  ##            : The namespace that contains the assignment.
  ##   AssignmentName: string (required)
  ##                 : The name of the assignment. 
  var path_613821 = newJObject()
  add(path_613821, "AwsAccountId", newJString(AwsAccountId))
  add(path_613821, "Namespace", newJString(Namespace))
  add(path_613821, "AssignmentName", newJString(AssignmentName))
  result = call_613820.call(path_613821, nil, nil, nil, nil)

var deleteIAMPolicyAssignment* = Call_DeleteIAMPolicyAssignment_613806(
    name: "deleteIAMPolicyAssignment", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespace/{Namespace}/iam-policy-assignments/{AssignmentName}",
    validator: validate_DeleteIAMPolicyAssignment_613807, base: "/",
    url: url_DeleteIAMPolicyAssignment_613808,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_613838 = ref object of OpenApiRestCall_612658
proc url_UpdateUser_613840(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateUser_613839(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613841 = path.getOrDefault("AwsAccountId")
  valid_613841 = validateParameter(valid_613841, JString, required = true,
                                 default = nil)
  if valid_613841 != nil:
    section.add "AwsAccountId", valid_613841
  var valid_613842 = path.getOrDefault("Namespace")
  valid_613842 = validateParameter(valid_613842, JString, required = true,
                                 default = nil)
  if valid_613842 != nil:
    section.add "Namespace", valid_613842
  var valid_613843 = path.getOrDefault("UserName")
  valid_613843 = validateParameter(valid_613843, JString, required = true,
                                 default = nil)
  if valid_613843 != nil:
    section.add "UserName", valid_613843
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
  var valid_613844 = header.getOrDefault("X-Amz-Signature")
  valid_613844 = validateParameter(valid_613844, JString, required = false,
                                 default = nil)
  if valid_613844 != nil:
    section.add "X-Amz-Signature", valid_613844
  var valid_613845 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613845 = validateParameter(valid_613845, JString, required = false,
                                 default = nil)
  if valid_613845 != nil:
    section.add "X-Amz-Content-Sha256", valid_613845
  var valid_613846 = header.getOrDefault("X-Amz-Date")
  valid_613846 = validateParameter(valid_613846, JString, required = false,
                                 default = nil)
  if valid_613846 != nil:
    section.add "X-Amz-Date", valid_613846
  var valid_613847 = header.getOrDefault("X-Amz-Credential")
  valid_613847 = validateParameter(valid_613847, JString, required = false,
                                 default = nil)
  if valid_613847 != nil:
    section.add "X-Amz-Credential", valid_613847
  var valid_613848 = header.getOrDefault("X-Amz-Security-Token")
  valid_613848 = validateParameter(valid_613848, JString, required = false,
                                 default = nil)
  if valid_613848 != nil:
    section.add "X-Amz-Security-Token", valid_613848
  var valid_613849 = header.getOrDefault("X-Amz-Algorithm")
  valid_613849 = validateParameter(valid_613849, JString, required = false,
                                 default = nil)
  if valid_613849 != nil:
    section.add "X-Amz-Algorithm", valid_613849
  var valid_613850 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613850 = validateParameter(valid_613850, JString, required = false,
                                 default = nil)
  if valid_613850 != nil:
    section.add "X-Amz-SignedHeaders", valid_613850
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613852: Call_UpdateUser_613838; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Amazon QuickSight user.
  ## 
  let valid = call_613852.validator(path, query, header, formData, body)
  let scheme = call_613852.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613852.url(scheme.get, call_613852.host, call_613852.base,
                         call_613852.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613852, url, valid)

proc call*(call_613853: Call_UpdateUser_613838; AwsAccountId: string;
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
  var path_613854 = newJObject()
  var body_613855 = newJObject()
  add(path_613854, "AwsAccountId", newJString(AwsAccountId))
  add(path_613854, "Namespace", newJString(Namespace))
  add(path_613854, "UserName", newJString(UserName))
  if body != nil:
    body_613855 = body
  result = call_613853.call(path_613854, nil, nil, nil, body_613855)

var updateUser* = Call_UpdateUser_613838(name: "updateUser",
                                      meth: HttpMethod.HttpPut,
                                      host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}",
                                      validator: validate_UpdateUser_613839,
                                      base: "/", url: url_UpdateUser_613840,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_613822 = ref object of OpenApiRestCall_612658
proc url_DescribeUser_613824(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeUser_613823(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613825 = path.getOrDefault("AwsAccountId")
  valid_613825 = validateParameter(valid_613825, JString, required = true,
                                 default = nil)
  if valid_613825 != nil:
    section.add "AwsAccountId", valid_613825
  var valid_613826 = path.getOrDefault("Namespace")
  valid_613826 = validateParameter(valid_613826, JString, required = true,
                                 default = nil)
  if valid_613826 != nil:
    section.add "Namespace", valid_613826
  var valid_613827 = path.getOrDefault("UserName")
  valid_613827 = validateParameter(valid_613827, JString, required = true,
                                 default = nil)
  if valid_613827 != nil:
    section.add "UserName", valid_613827
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
  var valid_613828 = header.getOrDefault("X-Amz-Signature")
  valid_613828 = validateParameter(valid_613828, JString, required = false,
                                 default = nil)
  if valid_613828 != nil:
    section.add "X-Amz-Signature", valid_613828
  var valid_613829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613829 = validateParameter(valid_613829, JString, required = false,
                                 default = nil)
  if valid_613829 != nil:
    section.add "X-Amz-Content-Sha256", valid_613829
  var valid_613830 = header.getOrDefault("X-Amz-Date")
  valid_613830 = validateParameter(valid_613830, JString, required = false,
                                 default = nil)
  if valid_613830 != nil:
    section.add "X-Amz-Date", valid_613830
  var valid_613831 = header.getOrDefault("X-Amz-Credential")
  valid_613831 = validateParameter(valid_613831, JString, required = false,
                                 default = nil)
  if valid_613831 != nil:
    section.add "X-Amz-Credential", valid_613831
  var valid_613832 = header.getOrDefault("X-Amz-Security-Token")
  valid_613832 = validateParameter(valid_613832, JString, required = false,
                                 default = nil)
  if valid_613832 != nil:
    section.add "X-Amz-Security-Token", valid_613832
  var valid_613833 = header.getOrDefault("X-Amz-Algorithm")
  valid_613833 = validateParameter(valid_613833, JString, required = false,
                                 default = nil)
  if valid_613833 != nil:
    section.add "X-Amz-Algorithm", valid_613833
  var valid_613834 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613834 = validateParameter(valid_613834, JString, required = false,
                                 default = nil)
  if valid_613834 != nil:
    section.add "X-Amz-SignedHeaders", valid_613834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613835: Call_DescribeUser_613822; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a user, given the user name. 
  ## 
  let valid = call_613835.validator(path, query, header, formData, body)
  let scheme = call_613835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613835.url(scheme.get, call_613835.host, call_613835.base,
                         call_613835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613835, url, valid)

proc call*(call_613836: Call_DescribeUser_613822; AwsAccountId: string;
          Namespace: string; UserName: string): Recallable =
  ## describeUser
  ## Returns information about a user, given the user name. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: string (required)
  ##           : The name of the user that you want to describe.
  var path_613837 = newJObject()
  add(path_613837, "AwsAccountId", newJString(AwsAccountId))
  add(path_613837, "Namespace", newJString(Namespace))
  add(path_613837, "UserName", newJString(UserName))
  result = call_613836.call(path_613837, nil, nil, nil, nil)

var describeUser* = Call_DescribeUser_613822(name: "describeUser",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}",
    validator: validate_DescribeUser_613823, base: "/", url: url_DescribeUser_613824,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_613856 = ref object of OpenApiRestCall_612658
proc url_DeleteUser_613858(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteUser_613857(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613859 = path.getOrDefault("AwsAccountId")
  valid_613859 = validateParameter(valid_613859, JString, required = true,
                                 default = nil)
  if valid_613859 != nil:
    section.add "AwsAccountId", valid_613859
  var valid_613860 = path.getOrDefault("Namespace")
  valid_613860 = validateParameter(valid_613860, JString, required = true,
                                 default = nil)
  if valid_613860 != nil:
    section.add "Namespace", valid_613860
  var valid_613861 = path.getOrDefault("UserName")
  valid_613861 = validateParameter(valid_613861, JString, required = true,
                                 default = nil)
  if valid_613861 != nil:
    section.add "UserName", valid_613861
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
  var valid_613862 = header.getOrDefault("X-Amz-Signature")
  valid_613862 = validateParameter(valid_613862, JString, required = false,
                                 default = nil)
  if valid_613862 != nil:
    section.add "X-Amz-Signature", valid_613862
  var valid_613863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613863 = validateParameter(valid_613863, JString, required = false,
                                 default = nil)
  if valid_613863 != nil:
    section.add "X-Amz-Content-Sha256", valid_613863
  var valid_613864 = header.getOrDefault("X-Amz-Date")
  valid_613864 = validateParameter(valid_613864, JString, required = false,
                                 default = nil)
  if valid_613864 != nil:
    section.add "X-Amz-Date", valid_613864
  var valid_613865 = header.getOrDefault("X-Amz-Credential")
  valid_613865 = validateParameter(valid_613865, JString, required = false,
                                 default = nil)
  if valid_613865 != nil:
    section.add "X-Amz-Credential", valid_613865
  var valid_613866 = header.getOrDefault("X-Amz-Security-Token")
  valid_613866 = validateParameter(valid_613866, JString, required = false,
                                 default = nil)
  if valid_613866 != nil:
    section.add "X-Amz-Security-Token", valid_613866
  var valid_613867 = header.getOrDefault("X-Amz-Algorithm")
  valid_613867 = validateParameter(valid_613867, JString, required = false,
                                 default = nil)
  if valid_613867 != nil:
    section.add "X-Amz-Algorithm", valid_613867
  var valid_613868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613868 = validateParameter(valid_613868, JString, required = false,
                                 default = nil)
  if valid_613868 != nil:
    section.add "X-Amz-SignedHeaders", valid_613868
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613869: Call_DeleteUser_613856; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the Amazon QuickSight user that is associated with the identity of the AWS Identity and Access Management (IAM) user or role that's making the call. The IAM user isn't deleted as a result of this call. 
  ## 
  let valid = call_613869.validator(path, query, header, formData, body)
  let scheme = call_613869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613869.url(scheme.get, call_613869.host, call_613869.base,
                         call_613869.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613869, url, valid)

proc call*(call_613870: Call_DeleteUser_613856; AwsAccountId: string;
          Namespace: string; UserName: string): Recallable =
  ## deleteUser
  ## Deletes the Amazon QuickSight user that is associated with the identity of the AWS Identity and Access Management (IAM) user or role that's making the call. The IAM user isn't deleted as a result of this call. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: string (required)
  ##           : The name of the user that you want to delete.
  var path_613871 = newJObject()
  add(path_613871, "AwsAccountId", newJString(AwsAccountId))
  add(path_613871, "Namespace", newJString(Namespace))
  add(path_613871, "UserName", newJString(UserName))
  result = call_613870.call(path_613871, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_613856(name: "deleteUser",
                                      meth: HttpMethod.HttpDelete,
                                      host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}",
                                      validator: validate_DeleteUser_613857,
                                      base: "/", url: url_DeleteUser_613858,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserByPrincipalId_613872 = ref object of OpenApiRestCall_612658
proc url_DeleteUserByPrincipalId_613874(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUserByPrincipalId_613873(path: JsonNode; query: JsonNode;
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
  var valid_613875 = path.getOrDefault("AwsAccountId")
  valid_613875 = validateParameter(valid_613875, JString, required = true,
                                 default = nil)
  if valid_613875 != nil:
    section.add "AwsAccountId", valid_613875
  var valid_613876 = path.getOrDefault("Namespace")
  valid_613876 = validateParameter(valid_613876, JString, required = true,
                                 default = nil)
  if valid_613876 != nil:
    section.add "Namespace", valid_613876
  var valid_613877 = path.getOrDefault("PrincipalId")
  valid_613877 = validateParameter(valid_613877, JString, required = true,
                                 default = nil)
  if valid_613877 != nil:
    section.add "PrincipalId", valid_613877
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
  var valid_613878 = header.getOrDefault("X-Amz-Signature")
  valid_613878 = validateParameter(valid_613878, JString, required = false,
                                 default = nil)
  if valid_613878 != nil:
    section.add "X-Amz-Signature", valid_613878
  var valid_613879 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613879 = validateParameter(valid_613879, JString, required = false,
                                 default = nil)
  if valid_613879 != nil:
    section.add "X-Amz-Content-Sha256", valid_613879
  var valid_613880 = header.getOrDefault("X-Amz-Date")
  valid_613880 = validateParameter(valid_613880, JString, required = false,
                                 default = nil)
  if valid_613880 != nil:
    section.add "X-Amz-Date", valid_613880
  var valid_613881 = header.getOrDefault("X-Amz-Credential")
  valid_613881 = validateParameter(valid_613881, JString, required = false,
                                 default = nil)
  if valid_613881 != nil:
    section.add "X-Amz-Credential", valid_613881
  var valid_613882 = header.getOrDefault("X-Amz-Security-Token")
  valid_613882 = validateParameter(valid_613882, JString, required = false,
                                 default = nil)
  if valid_613882 != nil:
    section.add "X-Amz-Security-Token", valid_613882
  var valid_613883 = header.getOrDefault("X-Amz-Algorithm")
  valid_613883 = validateParameter(valid_613883, JString, required = false,
                                 default = nil)
  if valid_613883 != nil:
    section.add "X-Amz-Algorithm", valid_613883
  var valid_613884 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613884 = validateParameter(valid_613884, JString, required = false,
                                 default = nil)
  if valid_613884 != nil:
    section.add "X-Amz-SignedHeaders", valid_613884
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613885: Call_DeleteUserByPrincipalId_613872; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a user identified by its principal ID. 
  ## 
  let valid = call_613885.validator(path, query, header, formData, body)
  let scheme = call_613885.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613885.url(scheme.get, call_613885.host, call_613885.base,
                         call_613885.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613885, url, valid)

proc call*(call_613886: Call_DeleteUserByPrincipalId_613872; AwsAccountId: string;
          Namespace: string; PrincipalId: string): Recallable =
  ## deleteUserByPrincipalId
  ## Deletes a user identified by its principal ID. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   PrincipalId: string (required)
  ##              : The principal ID of the user.
  var path_613887 = newJObject()
  add(path_613887, "AwsAccountId", newJString(AwsAccountId))
  add(path_613887, "Namespace", newJString(Namespace))
  add(path_613887, "PrincipalId", newJString(PrincipalId))
  result = call_613886.call(path_613887, nil, nil, nil, nil)

var deleteUserByPrincipalId* = Call_DeleteUserByPrincipalId_613872(
    name: "deleteUserByPrincipalId", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/user-principals/{PrincipalId}",
    validator: validate_DeleteUserByPrincipalId_613873, base: "/",
    url: url_DeleteUserByPrincipalId_613874, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDashboardPermissions_613903 = ref object of OpenApiRestCall_612658
proc url_UpdateDashboardPermissions_613905(protocol: Scheme; host: string;
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

proc validate_UpdateDashboardPermissions_613904(path: JsonNode; query: JsonNode;
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
  var valid_613906 = path.getOrDefault("AwsAccountId")
  valid_613906 = validateParameter(valid_613906, JString, required = true,
                                 default = nil)
  if valid_613906 != nil:
    section.add "AwsAccountId", valid_613906
  var valid_613907 = path.getOrDefault("DashboardId")
  valid_613907 = validateParameter(valid_613907, JString, required = true,
                                 default = nil)
  if valid_613907 != nil:
    section.add "DashboardId", valid_613907
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
  var valid_613908 = header.getOrDefault("X-Amz-Signature")
  valid_613908 = validateParameter(valid_613908, JString, required = false,
                                 default = nil)
  if valid_613908 != nil:
    section.add "X-Amz-Signature", valid_613908
  var valid_613909 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613909 = validateParameter(valid_613909, JString, required = false,
                                 default = nil)
  if valid_613909 != nil:
    section.add "X-Amz-Content-Sha256", valid_613909
  var valid_613910 = header.getOrDefault("X-Amz-Date")
  valid_613910 = validateParameter(valid_613910, JString, required = false,
                                 default = nil)
  if valid_613910 != nil:
    section.add "X-Amz-Date", valid_613910
  var valid_613911 = header.getOrDefault("X-Amz-Credential")
  valid_613911 = validateParameter(valid_613911, JString, required = false,
                                 default = nil)
  if valid_613911 != nil:
    section.add "X-Amz-Credential", valid_613911
  var valid_613912 = header.getOrDefault("X-Amz-Security-Token")
  valid_613912 = validateParameter(valid_613912, JString, required = false,
                                 default = nil)
  if valid_613912 != nil:
    section.add "X-Amz-Security-Token", valid_613912
  var valid_613913 = header.getOrDefault("X-Amz-Algorithm")
  valid_613913 = validateParameter(valid_613913, JString, required = false,
                                 default = nil)
  if valid_613913 != nil:
    section.add "X-Amz-Algorithm", valid_613913
  var valid_613914 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613914 = validateParameter(valid_613914, JString, required = false,
                                 default = nil)
  if valid_613914 != nil:
    section.add "X-Amz-SignedHeaders", valid_613914
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613916: Call_UpdateDashboardPermissions_613903; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates read and write permissions on a dashboard.
  ## 
  let valid = call_613916.validator(path, query, header, formData, body)
  let scheme = call_613916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613916.url(scheme.get, call_613916.host, call_613916.base,
                         call_613916.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613916, url, valid)

proc call*(call_613917: Call_UpdateDashboardPermissions_613903;
          AwsAccountId: string; body: JsonNode; DashboardId: string): Recallable =
  ## updateDashboardPermissions
  ## Updates read and write permissions on a dashboard.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard whose permissions you're updating.
  ##   body: JObject (required)
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  var path_613918 = newJObject()
  var body_613919 = newJObject()
  add(path_613918, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_613919 = body
  add(path_613918, "DashboardId", newJString(DashboardId))
  result = call_613917.call(path_613918, nil, nil, nil, body_613919)

var updateDashboardPermissions* = Call_UpdateDashboardPermissions_613903(
    name: "updateDashboardPermissions", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/permissions",
    validator: validate_UpdateDashboardPermissions_613904, base: "/",
    url: url_UpdateDashboardPermissions_613905,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDashboardPermissions_613888 = ref object of OpenApiRestCall_612658
proc url_DescribeDashboardPermissions_613890(protocol: Scheme; host: string;
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

proc validate_DescribeDashboardPermissions_613889(path: JsonNode; query: JsonNode;
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
  var valid_613891 = path.getOrDefault("AwsAccountId")
  valid_613891 = validateParameter(valid_613891, JString, required = true,
                                 default = nil)
  if valid_613891 != nil:
    section.add "AwsAccountId", valid_613891
  var valid_613892 = path.getOrDefault("DashboardId")
  valid_613892 = validateParameter(valid_613892, JString, required = true,
                                 default = nil)
  if valid_613892 != nil:
    section.add "DashboardId", valid_613892
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
  var valid_613893 = header.getOrDefault("X-Amz-Signature")
  valid_613893 = validateParameter(valid_613893, JString, required = false,
                                 default = nil)
  if valid_613893 != nil:
    section.add "X-Amz-Signature", valid_613893
  var valid_613894 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613894 = validateParameter(valid_613894, JString, required = false,
                                 default = nil)
  if valid_613894 != nil:
    section.add "X-Amz-Content-Sha256", valid_613894
  var valid_613895 = header.getOrDefault("X-Amz-Date")
  valid_613895 = validateParameter(valid_613895, JString, required = false,
                                 default = nil)
  if valid_613895 != nil:
    section.add "X-Amz-Date", valid_613895
  var valid_613896 = header.getOrDefault("X-Amz-Credential")
  valid_613896 = validateParameter(valid_613896, JString, required = false,
                                 default = nil)
  if valid_613896 != nil:
    section.add "X-Amz-Credential", valid_613896
  var valid_613897 = header.getOrDefault("X-Amz-Security-Token")
  valid_613897 = validateParameter(valid_613897, JString, required = false,
                                 default = nil)
  if valid_613897 != nil:
    section.add "X-Amz-Security-Token", valid_613897
  var valid_613898 = header.getOrDefault("X-Amz-Algorithm")
  valid_613898 = validateParameter(valid_613898, JString, required = false,
                                 default = nil)
  if valid_613898 != nil:
    section.add "X-Amz-Algorithm", valid_613898
  var valid_613899 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613899 = validateParameter(valid_613899, JString, required = false,
                                 default = nil)
  if valid_613899 != nil:
    section.add "X-Amz-SignedHeaders", valid_613899
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613900: Call_DescribeDashboardPermissions_613888; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes read and write permissions for a dashboard.
  ## 
  let valid = call_613900.validator(path, query, header, formData, body)
  let scheme = call_613900.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613900.url(scheme.get, call_613900.host, call_613900.base,
                         call_613900.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613900, url, valid)

proc call*(call_613901: Call_DescribeDashboardPermissions_613888;
          AwsAccountId: string; DashboardId: string): Recallable =
  ## describeDashboardPermissions
  ## Describes read and write permissions for a dashboard.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're describing permissions for.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard, also added to the IAM policy.
  var path_613902 = newJObject()
  add(path_613902, "AwsAccountId", newJString(AwsAccountId))
  add(path_613902, "DashboardId", newJString(DashboardId))
  result = call_613901.call(path_613902, nil, nil, nil, nil)

var describeDashboardPermissions* = Call_DescribeDashboardPermissions_613888(
    name: "describeDashboardPermissions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/permissions",
    validator: validate_DescribeDashboardPermissions_613889, base: "/",
    url: url_DescribeDashboardPermissions_613890,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSetPermissions_613935 = ref object of OpenApiRestCall_612658
proc url_UpdateDataSetPermissions_613937(protocol: Scheme; host: string;
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

proc validate_UpdateDataSetPermissions_613936(path: JsonNode; query: JsonNode;
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
  var valid_613938 = path.getOrDefault("AwsAccountId")
  valid_613938 = validateParameter(valid_613938, JString, required = true,
                                 default = nil)
  if valid_613938 != nil:
    section.add "AwsAccountId", valid_613938
  var valid_613939 = path.getOrDefault("DataSetId")
  valid_613939 = validateParameter(valid_613939, JString, required = true,
                                 default = nil)
  if valid_613939 != nil:
    section.add "DataSetId", valid_613939
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
  var valid_613940 = header.getOrDefault("X-Amz-Signature")
  valid_613940 = validateParameter(valid_613940, JString, required = false,
                                 default = nil)
  if valid_613940 != nil:
    section.add "X-Amz-Signature", valid_613940
  var valid_613941 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613941 = validateParameter(valid_613941, JString, required = false,
                                 default = nil)
  if valid_613941 != nil:
    section.add "X-Amz-Content-Sha256", valid_613941
  var valid_613942 = header.getOrDefault("X-Amz-Date")
  valid_613942 = validateParameter(valid_613942, JString, required = false,
                                 default = nil)
  if valid_613942 != nil:
    section.add "X-Amz-Date", valid_613942
  var valid_613943 = header.getOrDefault("X-Amz-Credential")
  valid_613943 = validateParameter(valid_613943, JString, required = false,
                                 default = nil)
  if valid_613943 != nil:
    section.add "X-Amz-Credential", valid_613943
  var valid_613944 = header.getOrDefault("X-Amz-Security-Token")
  valid_613944 = validateParameter(valid_613944, JString, required = false,
                                 default = nil)
  if valid_613944 != nil:
    section.add "X-Amz-Security-Token", valid_613944
  var valid_613945 = header.getOrDefault("X-Amz-Algorithm")
  valid_613945 = validateParameter(valid_613945, JString, required = false,
                                 default = nil)
  if valid_613945 != nil:
    section.add "X-Amz-Algorithm", valid_613945
  var valid_613946 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613946 = validateParameter(valid_613946, JString, required = false,
                                 default = nil)
  if valid_613946 != nil:
    section.add "X-Amz-SignedHeaders", valid_613946
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613948: Call_UpdateDataSetPermissions_613935; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
  ## 
  let valid = call_613948.validator(path, query, header, formData, body)
  let scheme = call_613948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613948.url(scheme.get, call_613948.host, call_613948.base,
                         call_613948.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613948, url, valid)

proc call*(call_613949: Call_UpdateDataSetPermissions_613935; AwsAccountId: string;
          DataSetId: string; body: JsonNode): Recallable =
  ## updateDataSetPermissions
  ## <p>Updates the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset whose permissions you want to update. This ID is unique per AWS Region for each AWS account.
  ##   body: JObject (required)
  var path_613950 = newJObject()
  var body_613951 = newJObject()
  add(path_613950, "AwsAccountId", newJString(AwsAccountId))
  add(path_613950, "DataSetId", newJString(DataSetId))
  if body != nil:
    body_613951 = body
  result = call_613949.call(path_613950, nil, nil, nil, body_613951)

var updateDataSetPermissions* = Call_UpdateDataSetPermissions_613935(
    name: "updateDataSetPermissions", meth: HttpMethod.HttpPost,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/permissions",
    validator: validate_UpdateDataSetPermissions_613936, base: "/",
    url: url_UpdateDataSetPermissions_613937, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSetPermissions_613920 = ref object of OpenApiRestCall_612658
proc url_DescribeDataSetPermissions_613922(protocol: Scheme; host: string;
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

proc validate_DescribeDataSetPermissions_613921(path: JsonNode; query: JsonNode;
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
  var valid_613923 = path.getOrDefault("AwsAccountId")
  valid_613923 = validateParameter(valid_613923, JString, required = true,
                                 default = nil)
  if valid_613923 != nil:
    section.add "AwsAccountId", valid_613923
  var valid_613924 = path.getOrDefault("DataSetId")
  valid_613924 = validateParameter(valid_613924, JString, required = true,
                                 default = nil)
  if valid_613924 != nil:
    section.add "DataSetId", valid_613924
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
  var valid_613925 = header.getOrDefault("X-Amz-Signature")
  valid_613925 = validateParameter(valid_613925, JString, required = false,
                                 default = nil)
  if valid_613925 != nil:
    section.add "X-Amz-Signature", valid_613925
  var valid_613926 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613926 = validateParameter(valid_613926, JString, required = false,
                                 default = nil)
  if valid_613926 != nil:
    section.add "X-Amz-Content-Sha256", valid_613926
  var valid_613927 = header.getOrDefault("X-Amz-Date")
  valid_613927 = validateParameter(valid_613927, JString, required = false,
                                 default = nil)
  if valid_613927 != nil:
    section.add "X-Amz-Date", valid_613927
  var valid_613928 = header.getOrDefault("X-Amz-Credential")
  valid_613928 = validateParameter(valid_613928, JString, required = false,
                                 default = nil)
  if valid_613928 != nil:
    section.add "X-Amz-Credential", valid_613928
  var valid_613929 = header.getOrDefault("X-Amz-Security-Token")
  valid_613929 = validateParameter(valid_613929, JString, required = false,
                                 default = nil)
  if valid_613929 != nil:
    section.add "X-Amz-Security-Token", valid_613929
  var valid_613930 = header.getOrDefault("X-Amz-Algorithm")
  valid_613930 = validateParameter(valid_613930, JString, required = false,
                                 default = nil)
  if valid_613930 != nil:
    section.add "X-Amz-Algorithm", valid_613930
  var valid_613931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613931 = validateParameter(valid_613931, JString, required = false,
                                 default = nil)
  if valid_613931 != nil:
    section.add "X-Amz-SignedHeaders", valid_613931
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613932: Call_DescribeDataSetPermissions_613920; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
  ## 
  let valid = call_613932.validator(path, query, header, formData, body)
  let scheme = call_613932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613932.url(scheme.get, call_613932.host, call_613932.base,
                         call_613932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613932, url, valid)

proc call*(call_613933: Call_DescribeDataSetPermissions_613920;
          AwsAccountId: string; DataSetId: string): Recallable =
  ## describeDataSetPermissions
  ## <p>Describes the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset that you want to create. This ID is unique per AWS Region for each AWS account.
  var path_613934 = newJObject()
  add(path_613934, "AwsAccountId", newJString(AwsAccountId))
  add(path_613934, "DataSetId", newJString(DataSetId))
  result = call_613933.call(path_613934, nil, nil, nil, nil)

var describeDataSetPermissions* = Call_DescribeDataSetPermissions_613920(
    name: "describeDataSetPermissions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/permissions",
    validator: validate_DescribeDataSetPermissions_613921, base: "/",
    url: url_DescribeDataSetPermissions_613922,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSourcePermissions_613967 = ref object of OpenApiRestCall_612658
proc url_UpdateDataSourcePermissions_613969(protocol: Scheme; host: string;
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

proc validate_UpdateDataSourcePermissions_613968(path: JsonNode; query: JsonNode;
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
  var valid_613970 = path.getOrDefault("DataSourceId")
  valid_613970 = validateParameter(valid_613970, JString, required = true,
                                 default = nil)
  if valid_613970 != nil:
    section.add "DataSourceId", valid_613970
  var valid_613971 = path.getOrDefault("AwsAccountId")
  valid_613971 = validateParameter(valid_613971, JString, required = true,
                                 default = nil)
  if valid_613971 != nil:
    section.add "AwsAccountId", valid_613971
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
  var valid_613972 = header.getOrDefault("X-Amz-Signature")
  valid_613972 = validateParameter(valid_613972, JString, required = false,
                                 default = nil)
  if valid_613972 != nil:
    section.add "X-Amz-Signature", valid_613972
  var valid_613973 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613973 = validateParameter(valid_613973, JString, required = false,
                                 default = nil)
  if valid_613973 != nil:
    section.add "X-Amz-Content-Sha256", valid_613973
  var valid_613974 = header.getOrDefault("X-Amz-Date")
  valid_613974 = validateParameter(valid_613974, JString, required = false,
                                 default = nil)
  if valid_613974 != nil:
    section.add "X-Amz-Date", valid_613974
  var valid_613975 = header.getOrDefault("X-Amz-Credential")
  valid_613975 = validateParameter(valid_613975, JString, required = false,
                                 default = nil)
  if valid_613975 != nil:
    section.add "X-Amz-Credential", valid_613975
  var valid_613976 = header.getOrDefault("X-Amz-Security-Token")
  valid_613976 = validateParameter(valid_613976, JString, required = false,
                                 default = nil)
  if valid_613976 != nil:
    section.add "X-Amz-Security-Token", valid_613976
  var valid_613977 = header.getOrDefault("X-Amz-Algorithm")
  valid_613977 = validateParameter(valid_613977, JString, required = false,
                                 default = nil)
  if valid_613977 != nil:
    section.add "X-Amz-Algorithm", valid_613977
  var valid_613978 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613978 = validateParameter(valid_613978, JString, required = false,
                                 default = nil)
  if valid_613978 != nil:
    section.add "X-Amz-SignedHeaders", valid_613978
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613980: Call_UpdateDataSourcePermissions_613967; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the permissions to a data source.
  ## 
  let valid = call_613980.validator(path, query, header, formData, body)
  let scheme = call_613980.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613980.url(scheme.get, call_613980.host, call_613980.base,
                         call_613980.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613980, url, valid)

proc call*(call_613981: Call_UpdateDataSourcePermissions_613967;
          DataSourceId: string; AwsAccountId: string; body: JsonNode): Recallable =
  ## updateDataSourcePermissions
  ## Updates the permissions to a data source.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account. 
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   body: JObject (required)
  var path_613982 = newJObject()
  var body_613983 = newJObject()
  add(path_613982, "DataSourceId", newJString(DataSourceId))
  add(path_613982, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_613983 = body
  result = call_613981.call(path_613982, nil, nil, nil, body_613983)

var updateDataSourcePermissions* = Call_UpdateDataSourcePermissions_613967(
    name: "updateDataSourcePermissions", meth: HttpMethod.HttpPost,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}/permissions",
    validator: validate_UpdateDataSourcePermissions_613968, base: "/",
    url: url_UpdateDataSourcePermissions_613969,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSourcePermissions_613952 = ref object of OpenApiRestCall_612658
proc url_DescribeDataSourcePermissions_613954(protocol: Scheme; host: string;
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

proc validate_DescribeDataSourcePermissions_613953(path: JsonNode; query: JsonNode;
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
  var valid_613955 = path.getOrDefault("DataSourceId")
  valid_613955 = validateParameter(valid_613955, JString, required = true,
                                 default = nil)
  if valid_613955 != nil:
    section.add "DataSourceId", valid_613955
  var valid_613956 = path.getOrDefault("AwsAccountId")
  valid_613956 = validateParameter(valid_613956, JString, required = true,
                                 default = nil)
  if valid_613956 != nil:
    section.add "AwsAccountId", valid_613956
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
  var valid_613957 = header.getOrDefault("X-Amz-Signature")
  valid_613957 = validateParameter(valid_613957, JString, required = false,
                                 default = nil)
  if valid_613957 != nil:
    section.add "X-Amz-Signature", valid_613957
  var valid_613958 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613958 = validateParameter(valid_613958, JString, required = false,
                                 default = nil)
  if valid_613958 != nil:
    section.add "X-Amz-Content-Sha256", valid_613958
  var valid_613959 = header.getOrDefault("X-Amz-Date")
  valid_613959 = validateParameter(valid_613959, JString, required = false,
                                 default = nil)
  if valid_613959 != nil:
    section.add "X-Amz-Date", valid_613959
  var valid_613960 = header.getOrDefault("X-Amz-Credential")
  valid_613960 = validateParameter(valid_613960, JString, required = false,
                                 default = nil)
  if valid_613960 != nil:
    section.add "X-Amz-Credential", valid_613960
  var valid_613961 = header.getOrDefault("X-Amz-Security-Token")
  valid_613961 = validateParameter(valid_613961, JString, required = false,
                                 default = nil)
  if valid_613961 != nil:
    section.add "X-Amz-Security-Token", valid_613961
  var valid_613962 = header.getOrDefault("X-Amz-Algorithm")
  valid_613962 = validateParameter(valid_613962, JString, required = false,
                                 default = nil)
  if valid_613962 != nil:
    section.add "X-Amz-Algorithm", valid_613962
  var valid_613963 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613963 = validateParameter(valid_613963, JString, required = false,
                                 default = nil)
  if valid_613963 != nil:
    section.add "X-Amz-SignedHeaders", valid_613963
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613964: Call_DescribeDataSourcePermissions_613952; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the resource permissions for a data source.
  ## 
  let valid = call_613964.validator(path, query, header, formData, body)
  let scheme = call_613964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613964.url(scheme.get, call_613964.host, call_613964.base,
                         call_613964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613964, url, valid)

proc call*(call_613965: Call_DescribeDataSourcePermissions_613952;
          DataSourceId: string; AwsAccountId: string): Recallable =
  ## describeDataSourcePermissions
  ## Describes the resource permissions for a data source.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  var path_613966 = newJObject()
  add(path_613966, "DataSourceId", newJString(DataSourceId))
  add(path_613966, "AwsAccountId", newJString(AwsAccountId))
  result = call_613965.call(path_613966, nil, nil, nil, nil)

var describeDataSourcePermissions* = Call_DescribeDataSourcePermissions_613952(
    name: "describeDataSourcePermissions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}/permissions",
    validator: validate_DescribeDataSourcePermissions_613953, base: "/",
    url: url_DescribeDataSourcePermissions_613954,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIAMPolicyAssignment_614000 = ref object of OpenApiRestCall_612658
proc url_UpdateIAMPolicyAssignment_614002(protocol: Scheme; host: string;
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

proc validate_UpdateIAMPolicyAssignment_614001(path: JsonNode; query: JsonNode;
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
  var valid_614003 = path.getOrDefault("AwsAccountId")
  valid_614003 = validateParameter(valid_614003, JString, required = true,
                                 default = nil)
  if valid_614003 != nil:
    section.add "AwsAccountId", valid_614003
  var valid_614004 = path.getOrDefault("Namespace")
  valid_614004 = validateParameter(valid_614004, JString, required = true,
                                 default = nil)
  if valid_614004 != nil:
    section.add "Namespace", valid_614004
  var valid_614005 = path.getOrDefault("AssignmentName")
  valid_614005 = validateParameter(valid_614005, JString, required = true,
                                 default = nil)
  if valid_614005 != nil:
    section.add "AssignmentName", valid_614005
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
  var valid_614006 = header.getOrDefault("X-Amz-Signature")
  valid_614006 = validateParameter(valid_614006, JString, required = false,
                                 default = nil)
  if valid_614006 != nil:
    section.add "X-Amz-Signature", valid_614006
  var valid_614007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614007 = validateParameter(valid_614007, JString, required = false,
                                 default = nil)
  if valid_614007 != nil:
    section.add "X-Amz-Content-Sha256", valid_614007
  var valid_614008 = header.getOrDefault("X-Amz-Date")
  valid_614008 = validateParameter(valid_614008, JString, required = false,
                                 default = nil)
  if valid_614008 != nil:
    section.add "X-Amz-Date", valid_614008
  var valid_614009 = header.getOrDefault("X-Amz-Credential")
  valid_614009 = validateParameter(valid_614009, JString, required = false,
                                 default = nil)
  if valid_614009 != nil:
    section.add "X-Amz-Credential", valid_614009
  var valid_614010 = header.getOrDefault("X-Amz-Security-Token")
  valid_614010 = validateParameter(valid_614010, JString, required = false,
                                 default = nil)
  if valid_614010 != nil:
    section.add "X-Amz-Security-Token", valid_614010
  var valid_614011 = header.getOrDefault("X-Amz-Algorithm")
  valid_614011 = validateParameter(valid_614011, JString, required = false,
                                 default = nil)
  if valid_614011 != nil:
    section.add "X-Amz-Algorithm", valid_614011
  var valid_614012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614012 = validateParameter(valid_614012, JString, required = false,
                                 default = nil)
  if valid_614012 != nil:
    section.add "X-Amz-SignedHeaders", valid_614012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614014: Call_UpdateIAMPolicyAssignment_614000; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing IAM policy assignment. This operation updates only the optional parameter or parameters that are specified in the request.
  ## 
  let valid = call_614014.validator(path, query, header, formData, body)
  let scheme = call_614014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614014.url(scheme.get, call_614014.host, call_614014.base,
                         call_614014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614014, url, valid)

proc call*(call_614015: Call_UpdateIAMPolicyAssignment_614000;
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
  var path_614016 = newJObject()
  var body_614017 = newJObject()
  add(path_614016, "AwsAccountId", newJString(AwsAccountId))
  add(path_614016, "Namespace", newJString(Namespace))
  add(path_614016, "AssignmentName", newJString(AssignmentName))
  if body != nil:
    body_614017 = body
  result = call_614015.call(path_614016, nil, nil, nil, body_614017)

var updateIAMPolicyAssignment* = Call_UpdateIAMPolicyAssignment_614000(
    name: "updateIAMPolicyAssignment", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/{AssignmentName}",
    validator: validate_UpdateIAMPolicyAssignment_614001, base: "/",
    url: url_UpdateIAMPolicyAssignment_614002,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIAMPolicyAssignment_613984 = ref object of OpenApiRestCall_612658
proc url_DescribeIAMPolicyAssignment_613986(protocol: Scheme; host: string;
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

proc validate_DescribeIAMPolicyAssignment_613985(path: JsonNode; query: JsonNode;
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
  var valid_613987 = path.getOrDefault("AwsAccountId")
  valid_613987 = validateParameter(valid_613987, JString, required = true,
                                 default = nil)
  if valid_613987 != nil:
    section.add "AwsAccountId", valid_613987
  var valid_613988 = path.getOrDefault("Namespace")
  valid_613988 = validateParameter(valid_613988, JString, required = true,
                                 default = nil)
  if valid_613988 != nil:
    section.add "Namespace", valid_613988
  var valid_613989 = path.getOrDefault("AssignmentName")
  valid_613989 = validateParameter(valid_613989, JString, required = true,
                                 default = nil)
  if valid_613989 != nil:
    section.add "AssignmentName", valid_613989
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
  var valid_613990 = header.getOrDefault("X-Amz-Signature")
  valid_613990 = validateParameter(valid_613990, JString, required = false,
                                 default = nil)
  if valid_613990 != nil:
    section.add "X-Amz-Signature", valid_613990
  var valid_613991 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613991 = validateParameter(valid_613991, JString, required = false,
                                 default = nil)
  if valid_613991 != nil:
    section.add "X-Amz-Content-Sha256", valid_613991
  var valid_613992 = header.getOrDefault("X-Amz-Date")
  valid_613992 = validateParameter(valid_613992, JString, required = false,
                                 default = nil)
  if valid_613992 != nil:
    section.add "X-Amz-Date", valid_613992
  var valid_613993 = header.getOrDefault("X-Amz-Credential")
  valid_613993 = validateParameter(valid_613993, JString, required = false,
                                 default = nil)
  if valid_613993 != nil:
    section.add "X-Amz-Credential", valid_613993
  var valid_613994 = header.getOrDefault("X-Amz-Security-Token")
  valid_613994 = validateParameter(valid_613994, JString, required = false,
                                 default = nil)
  if valid_613994 != nil:
    section.add "X-Amz-Security-Token", valid_613994
  var valid_613995 = header.getOrDefault("X-Amz-Algorithm")
  valid_613995 = validateParameter(valid_613995, JString, required = false,
                                 default = nil)
  if valid_613995 != nil:
    section.add "X-Amz-Algorithm", valid_613995
  var valid_613996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613996 = validateParameter(valid_613996, JString, required = false,
                                 default = nil)
  if valid_613996 != nil:
    section.add "X-Amz-SignedHeaders", valid_613996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613997: Call_DescribeIAMPolicyAssignment_613984; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing IAM policy assignment, as specified by the assignment name.
  ## 
  let valid = call_613997.validator(path, query, header, formData, body)
  let scheme = call_613997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613997.url(scheme.get, call_613997.host, call_613997.base,
                         call_613997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613997, url, valid)

proc call*(call_613998: Call_DescribeIAMPolicyAssignment_613984;
          AwsAccountId: string; Namespace: string; AssignmentName: string): Recallable =
  ## describeIAMPolicyAssignment
  ## Describes an existing IAM policy assignment, as specified by the assignment name.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the assignment that you want to describe.
  ##   Namespace: string (required)
  ##            : The namespace that contains the assignment.
  ##   AssignmentName: string (required)
  ##                 : The name of the assignment. 
  var path_613999 = newJObject()
  add(path_613999, "AwsAccountId", newJString(AwsAccountId))
  add(path_613999, "Namespace", newJString(Namespace))
  add(path_613999, "AssignmentName", newJString(AssignmentName))
  result = call_613998.call(path_613999, nil, nil, nil, nil)

var describeIAMPolicyAssignment* = Call_DescribeIAMPolicyAssignment_613984(
    name: "describeIAMPolicyAssignment", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/{AssignmentName}",
    validator: validate_DescribeIAMPolicyAssignment_613985, base: "/",
    url: url_DescribeIAMPolicyAssignment_613986,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTemplatePermissions_614033 = ref object of OpenApiRestCall_612658
proc url_UpdateTemplatePermissions_614035(protocol: Scheme; host: string;
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

proc validate_UpdateTemplatePermissions_614034(path: JsonNode; query: JsonNode;
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
  var valid_614036 = path.getOrDefault("AwsAccountId")
  valid_614036 = validateParameter(valid_614036, JString, required = true,
                                 default = nil)
  if valid_614036 != nil:
    section.add "AwsAccountId", valid_614036
  var valid_614037 = path.getOrDefault("TemplateId")
  valid_614037 = validateParameter(valid_614037, JString, required = true,
                                 default = nil)
  if valid_614037 != nil:
    section.add "TemplateId", valid_614037
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
  var valid_614038 = header.getOrDefault("X-Amz-Signature")
  valid_614038 = validateParameter(valid_614038, JString, required = false,
                                 default = nil)
  if valid_614038 != nil:
    section.add "X-Amz-Signature", valid_614038
  var valid_614039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614039 = validateParameter(valid_614039, JString, required = false,
                                 default = nil)
  if valid_614039 != nil:
    section.add "X-Amz-Content-Sha256", valid_614039
  var valid_614040 = header.getOrDefault("X-Amz-Date")
  valid_614040 = validateParameter(valid_614040, JString, required = false,
                                 default = nil)
  if valid_614040 != nil:
    section.add "X-Amz-Date", valid_614040
  var valid_614041 = header.getOrDefault("X-Amz-Credential")
  valid_614041 = validateParameter(valid_614041, JString, required = false,
                                 default = nil)
  if valid_614041 != nil:
    section.add "X-Amz-Credential", valid_614041
  var valid_614042 = header.getOrDefault("X-Amz-Security-Token")
  valid_614042 = validateParameter(valid_614042, JString, required = false,
                                 default = nil)
  if valid_614042 != nil:
    section.add "X-Amz-Security-Token", valid_614042
  var valid_614043 = header.getOrDefault("X-Amz-Algorithm")
  valid_614043 = validateParameter(valid_614043, JString, required = false,
                                 default = nil)
  if valid_614043 != nil:
    section.add "X-Amz-Algorithm", valid_614043
  var valid_614044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614044 = validateParameter(valid_614044, JString, required = false,
                                 default = nil)
  if valid_614044 != nil:
    section.add "X-Amz-SignedHeaders", valid_614044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614046: Call_UpdateTemplatePermissions_614033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the resource permissions for a template.
  ## 
  let valid = call_614046.validator(path, query, header, formData, body)
  let scheme = call_614046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614046.url(scheme.get, call_614046.host, call_614046.base,
                         call_614046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614046, url, valid)

proc call*(call_614047: Call_UpdateTemplatePermissions_614033;
          AwsAccountId: string; TemplateId: string; body: JsonNode): Recallable =
  ## updateTemplatePermissions
  ## Updates the resource permissions for a template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  ##   body: JObject (required)
  var path_614048 = newJObject()
  var body_614049 = newJObject()
  add(path_614048, "AwsAccountId", newJString(AwsAccountId))
  add(path_614048, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_614049 = body
  result = call_614047.call(path_614048, nil, nil, nil, body_614049)

var updateTemplatePermissions* = Call_UpdateTemplatePermissions_614033(
    name: "updateTemplatePermissions", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}/permissions",
    validator: validate_UpdateTemplatePermissions_614034, base: "/",
    url: url_UpdateTemplatePermissions_614035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTemplatePermissions_614018 = ref object of OpenApiRestCall_612658
proc url_DescribeTemplatePermissions_614020(protocol: Scheme; host: string;
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

proc validate_DescribeTemplatePermissions_614019(path: JsonNode; query: JsonNode;
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
  var valid_614021 = path.getOrDefault("AwsAccountId")
  valid_614021 = validateParameter(valid_614021, JString, required = true,
                                 default = nil)
  if valid_614021 != nil:
    section.add "AwsAccountId", valid_614021
  var valid_614022 = path.getOrDefault("TemplateId")
  valid_614022 = validateParameter(valid_614022, JString, required = true,
                                 default = nil)
  if valid_614022 != nil:
    section.add "TemplateId", valid_614022
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
  var valid_614023 = header.getOrDefault("X-Amz-Signature")
  valid_614023 = validateParameter(valid_614023, JString, required = false,
                                 default = nil)
  if valid_614023 != nil:
    section.add "X-Amz-Signature", valid_614023
  var valid_614024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614024 = validateParameter(valid_614024, JString, required = false,
                                 default = nil)
  if valid_614024 != nil:
    section.add "X-Amz-Content-Sha256", valid_614024
  var valid_614025 = header.getOrDefault("X-Amz-Date")
  valid_614025 = validateParameter(valid_614025, JString, required = false,
                                 default = nil)
  if valid_614025 != nil:
    section.add "X-Amz-Date", valid_614025
  var valid_614026 = header.getOrDefault("X-Amz-Credential")
  valid_614026 = validateParameter(valid_614026, JString, required = false,
                                 default = nil)
  if valid_614026 != nil:
    section.add "X-Amz-Credential", valid_614026
  var valid_614027 = header.getOrDefault("X-Amz-Security-Token")
  valid_614027 = validateParameter(valid_614027, JString, required = false,
                                 default = nil)
  if valid_614027 != nil:
    section.add "X-Amz-Security-Token", valid_614027
  var valid_614028 = header.getOrDefault("X-Amz-Algorithm")
  valid_614028 = validateParameter(valid_614028, JString, required = false,
                                 default = nil)
  if valid_614028 != nil:
    section.add "X-Amz-Algorithm", valid_614028
  var valid_614029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614029 = validateParameter(valid_614029, JString, required = false,
                                 default = nil)
  if valid_614029 != nil:
    section.add "X-Amz-SignedHeaders", valid_614029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614030: Call_DescribeTemplatePermissions_614018; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes read and write permissions on a template.
  ## 
  let valid = call_614030.validator(path, query, header, formData, body)
  let scheme = call_614030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614030.url(scheme.get, call_614030.host, call_614030.base,
                         call_614030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614030, url, valid)

proc call*(call_614031: Call_DescribeTemplatePermissions_614018;
          AwsAccountId: string; TemplateId: string): Recallable =
  ## describeTemplatePermissions
  ## Describes read and write permissions on a template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template that you're describing.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  var path_614032 = newJObject()
  add(path_614032, "AwsAccountId", newJString(AwsAccountId))
  add(path_614032, "TemplateId", newJString(TemplateId))
  result = call_614031.call(path_614032, nil, nil, nil, nil)

var describeTemplatePermissions* = Call_DescribeTemplatePermissions_614018(
    name: "describeTemplatePermissions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}/permissions",
    validator: validate_DescribeTemplatePermissions_614019, base: "/",
    url: url_DescribeTemplatePermissions_614020,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDashboardEmbedUrl_614050 = ref object of OpenApiRestCall_612658
proc url_GetDashboardEmbedUrl_614052(protocol: Scheme; host: string; base: string;
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

proc validate_GetDashboardEmbedUrl_614051(path: JsonNode; query: JsonNode;
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
  var valid_614053 = path.getOrDefault("AwsAccountId")
  valid_614053 = validateParameter(valid_614053, JString, required = true,
                                 default = nil)
  if valid_614053 != nil:
    section.add "AwsAccountId", valid_614053
  var valid_614054 = path.getOrDefault("DashboardId")
  valid_614054 = validateParameter(valid_614054, JString, required = true,
                                 default = nil)
  if valid_614054 != nil:
    section.add "DashboardId", valid_614054
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
  var valid_614055 = query.getOrDefault("reset-disabled")
  valid_614055 = validateParameter(valid_614055, JBool, required = false, default = nil)
  if valid_614055 != nil:
    section.add "reset-disabled", valid_614055
  var valid_614069 = query.getOrDefault("creds-type")
  valid_614069 = validateParameter(valid_614069, JString, required = true,
                                 default = newJString("IAM"))
  if valid_614069 != nil:
    section.add "creds-type", valid_614069
  var valid_614070 = query.getOrDefault("user-arn")
  valid_614070 = validateParameter(valid_614070, JString, required = false,
                                 default = nil)
  if valid_614070 != nil:
    section.add "user-arn", valid_614070
  var valid_614071 = query.getOrDefault("session-lifetime")
  valid_614071 = validateParameter(valid_614071, JInt, required = false, default = nil)
  if valid_614071 != nil:
    section.add "session-lifetime", valid_614071
  var valid_614072 = query.getOrDefault("undo-redo-disabled")
  valid_614072 = validateParameter(valid_614072, JBool, required = false, default = nil)
  if valid_614072 != nil:
    section.add "undo-redo-disabled", valid_614072
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614073 = header.getOrDefault("X-Amz-Signature")
  valid_614073 = validateParameter(valid_614073, JString, required = false,
                                 default = nil)
  if valid_614073 != nil:
    section.add "X-Amz-Signature", valid_614073
  var valid_614074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614074 = validateParameter(valid_614074, JString, required = false,
                                 default = nil)
  if valid_614074 != nil:
    section.add "X-Amz-Content-Sha256", valid_614074
  var valid_614075 = header.getOrDefault("X-Amz-Date")
  valid_614075 = validateParameter(valid_614075, JString, required = false,
                                 default = nil)
  if valid_614075 != nil:
    section.add "X-Amz-Date", valid_614075
  var valid_614076 = header.getOrDefault("X-Amz-Credential")
  valid_614076 = validateParameter(valid_614076, JString, required = false,
                                 default = nil)
  if valid_614076 != nil:
    section.add "X-Amz-Credential", valid_614076
  var valid_614077 = header.getOrDefault("X-Amz-Security-Token")
  valid_614077 = validateParameter(valid_614077, JString, required = false,
                                 default = nil)
  if valid_614077 != nil:
    section.add "X-Amz-Security-Token", valid_614077
  var valid_614078 = header.getOrDefault("X-Amz-Algorithm")
  valid_614078 = validateParameter(valid_614078, JString, required = false,
                                 default = nil)
  if valid_614078 != nil:
    section.add "X-Amz-Algorithm", valid_614078
  var valid_614079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614079 = validateParameter(valid_614079, JString, required = false,
                                 default = nil)
  if valid_614079 != nil:
    section.add "X-Amz-SignedHeaders", valid_614079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614080: Call_GetDashboardEmbedUrl_614050; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Generates a server-side embeddable URL and authorization code. For this process to work properly, first configure the dashboards and user permissions. For more information, see <a href="https://docs.aws.amazon.com/quicksight/latest/user/embedding-dashboards.html">Embedding Amazon QuickSight Dashboards</a> in the <i>Amazon QuickSight User Guide</i> or <a href="https://docs.aws.amazon.com/quicksight/latest/APIReference/qs-dev-embedded-dashboards.html">Embedding Amazon QuickSight Dashboards</a> in the <i>Amazon QuickSight API Reference</i>.</p> <p>Currently, you can use <code>GetDashboardEmbedURL</code> only from the server, not from the user’s browser.</p>
  ## 
  let valid = call_614080.validator(path, query, header, formData, body)
  let scheme = call_614080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614080.url(scheme.get, call_614080.host, call_614080.base,
                         call_614080.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614080, url, valid)

proc call*(call_614081: Call_GetDashboardEmbedUrl_614050; AwsAccountId: string;
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
  var path_614082 = newJObject()
  var query_614083 = newJObject()
  add(query_614083, "reset-disabled", newJBool(resetDisabled))
  add(path_614082, "AwsAccountId", newJString(AwsAccountId))
  add(query_614083, "creds-type", newJString(credsType))
  add(query_614083, "user-arn", newJString(userArn))
  add(path_614082, "DashboardId", newJString(DashboardId))
  add(query_614083, "session-lifetime", newJInt(sessionLifetime))
  add(query_614083, "undo-redo-disabled", newJBool(undoRedoDisabled))
  result = call_614081.call(path_614082, query_614083, nil, nil, nil)

var getDashboardEmbedUrl* = Call_GetDashboardEmbedUrl_614050(
    name: "getDashboardEmbedUrl", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/embed-url#creds-type",
    validator: validate_GetDashboardEmbedUrl_614051, base: "/",
    url: url_GetDashboardEmbedUrl_614052, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDashboardVersions_614084 = ref object of OpenApiRestCall_612658
proc url_ListDashboardVersions_614086(protocol: Scheme; host: string; base: string;
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

proc validate_ListDashboardVersions_614085(path: JsonNode; query: JsonNode;
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
  var valid_614087 = path.getOrDefault("AwsAccountId")
  valid_614087 = validateParameter(valid_614087, JString, required = true,
                                 default = nil)
  if valid_614087 != nil:
    section.add "AwsAccountId", valid_614087
  var valid_614088 = path.getOrDefault("DashboardId")
  valid_614088 = validateParameter(valid_614088, JString, required = true,
                                 default = nil)
  if valid_614088 != nil:
    section.add "DashboardId", valid_614088
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
  var valid_614089 = query.getOrDefault("MaxResults")
  valid_614089 = validateParameter(valid_614089, JString, required = false,
                                 default = nil)
  if valid_614089 != nil:
    section.add "MaxResults", valid_614089
  var valid_614090 = query.getOrDefault("NextToken")
  valid_614090 = validateParameter(valid_614090, JString, required = false,
                                 default = nil)
  if valid_614090 != nil:
    section.add "NextToken", valid_614090
  var valid_614091 = query.getOrDefault("max-results")
  valid_614091 = validateParameter(valid_614091, JInt, required = false, default = nil)
  if valid_614091 != nil:
    section.add "max-results", valid_614091
  var valid_614092 = query.getOrDefault("next-token")
  valid_614092 = validateParameter(valid_614092, JString, required = false,
                                 default = nil)
  if valid_614092 != nil:
    section.add "next-token", valid_614092
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614093 = header.getOrDefault("X-Amz-Signature")
  valid_614093 = validateParameter(valid_614093, JString, required = false,
                                 default = nil)
  if valid_614093 != nil:
    section.add "X-Amz-Signature", valid_614093
  var valid_614094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614094 = validateParameter(valid_614094, JString, required = false,
                                 default = nil)
  if valid_614094 != nil:
    section.add "X-Amz-Content-Sha256", valid_614094
  var valid_614095 = header.getOrDefault("X-Amz-Date")
  valid_614095 = validateParameter(valid_614095, JString, required = false,
                                 default = nil)
  if valid_614095 != nil:
    section.add "X-Amz-Date", valid_614095
  var valid_614096 = header.getOrDefault("X-Amz-Credential")
  valid_614096 = validateParameter(valid_614096, JString, required = false,
                                 default = nil)
  if valid_614096 != nil:
    section.add "X-Amz-Credential", valid_614096
  var valid_614097 = header.getOrDefault("X-Amz-Security-Token")
  valid_614097 = validateParameter(valid_614097, JString, required = false,
                                 default = nil)
  if valid_614097 != nil:
    section.add "X-Amz-Security-Token", valid_614097
  var valid_614098 = header.getOrDefault("X-Amz-Algorithm")
  valid_614098 = validateParameter(valid_614098, JString, required = false,
                                 default = nil)
  if valid_614098 != nil:
    section.add "X-Amz-Algorithm", valid_614098
  var valid_614099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614099 = validateParameter(valid_614099, JString, required = false,
                                 default = nil)
  if valid_614099 != nil:
    section.add "X-Amz-SignedHeaders", valid_614099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614100: Call_ListDashboardVersions_614084; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the versions of the dashboards in the QuickSight subscription.
  ## 
  let valid = call_614100.validator(path, query, header, formData, body)
  let scheme = call_614100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614100.url(scheme.get, call_614100.host, call_614100.base,
                         call_614100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614100, url, valid)

proc call*(call_614101: Call_ListDashboardVersions_614084; AwsAccountId: string;
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
  var path_614102 = newJObject()
  var query_614103 = newJObject()
  add(path_614102, "AwsAccountId", newJString(AwsAccountId))
  add(query_614103, "MaxResults", newJString(MaxResults))
  add(query_614103, "NextToken", newJString(NextToken))
  add(query_614103, "max-results", newJInt(maxResults))
  add(path_614102, "DashboardId", newJString(DashboardId))
  add(query_614103, "next-token", newJString(nextToken))
  result = call_614101.call(path_614102, query_614103, nil, nil, nil)

var listDashboardVersions* = Call_ListDashboardVersions_614084(
    name: "listDashboardVersions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/versions",
    validator: validate_ListDashboardVersions_614085, base: "/",
    url: url_ListDashboardVersions_614086, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDashboards_614104 = ref object of OpenApiRestCall_612658
proc url_ListDashboards_614106(protocol: Scheme; host: string; base: string;
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

proc validate_ListDashboards_614105(path: JsonNode; query: JsonNode;
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
  var valid_614107 = path.getOrDefault("AwsAccountId")
  valid_614107 = validateParameter(valid_614107, JString, required = true,
                                 default = nil)
  if valid_614107 != nil:
    section.add "AwsAccountId", valid_614107
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
  var valid_614108 = query.getOrDefault("MaxResults")
  valid_614108 = validateParameter(valid_614108, JString, required = false,
                                 default = nil)
  if valid_614108 != nil:
    section.add "MaxResults", valid_614108
  var valid_614109 = query.getOrDefault("NextToken")
  valid_614109 = validateParameter(valid_614109, JString, required = false,
                                 default = nil)
  if valid_614109 != nil:
    section.add "NextToken", valid_614109
  var valid_614110 = query.getOrDefault("max-results")
  valid_614110 = validateParameter(valid_614110, JInt, required = false, default = nil)
  if valid_614110 != nil:
    section.add "max-results", valid_614110
  var valid_614111 = query.getOrDefault("next-token")
  valid_614111 = validateParameter(valid_614111, JString, required = false,
                                 default = nil)
  if valid_614111 != nil:
    section.add "next-token", valid_614111
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614112 = header.getOrDefault("X-Amz-Signature")
  valid_614112 = validateParameter(valid_614112, JString, required = false,
                                 default = nil)
  if valid_614112 != nil:
    section.add "X-Amz-Signature", valid_614112
  var valid_614113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614113 = validateParameter(valid_614113, JString, required = false,
                                 default = nil)
  if valid_614113 != nil:
    section.add "X-Amz-Content-Sha256", valid_614113
  var valid_614114 = header.getOrDefault("X-Amz-Date")
  valid_614114 = validateParameter(valid_614114, JString, required = false,
                                 default = nil)
  if valid_614114 != nil:
    section.add "X-Amz-Date", valid_614114
  var valid_614115 = header.getOrDefault("X-Amz-Credential")
  valid_614115 = validateParameter(valid_614115, JString, required = false,
                                 default = nil)
  if valid_614115 != nil:
    section.add "X-Amz-Credential", valid_614115
  var valid_614116 = header.getOrDefault("X-Amz-Security-Token")
  valid_614116 = validateParameter(valid_614116, JString, required = false,
                                 default = nil)
  if valid_614116 != nil:
    section.add "X-Amz-Security-Token", valid_614116
  var valid_614117 = header.getOrDefault("X-Amz-Algorithm")
  valid_614117 = validateParameter(valid_614117, JString, required = false,
                                 default = nil)
  if valid_614117 != nil:
    section.add "X-Amz-Algorithm", valid_614117
  var valid_614118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614118 = validateParameter(valid_614118, JString, required = false,
                                 default = nil)
  if valid_614118 != nil:
    section.add "X-Amz-SignedHeaders", valid_614118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614119: Call_ListDashboards_614104; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists dashboards in an AWS account.
  ## 
  let valid = call_614119.validator(path, query, header, formData, body)
  let scheme = call_614119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614119.url(scheme.get, call_614119.host, call_614119.base,
                         call_614119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614119, url, valid)

proc call*(call_614120: Call_ListDashboards_614104; AwsAccountId: string;
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
  var path_614121 = newJObject()
  var query_614122 = newJObject()
  add(path_614121, "AwsAccountId", newJString(AwsAccountId))
  add(query_614122, "MaxResults", newJString(MaxResults))
  add(query_614122, "NextToken", newJString(NextToken))
  add(query_614122, "max-results", newJInt(maxResults))
  add(query_614122, "next-token", newJString(nextToken))
  result = call_614120.call(path_614121, query_614122, nil, nil, nil)

var listDashboards* = Call_ListDashboards_614104(name: "listDashboards",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards",
    validator: validate_ListDashboards_614105, base: "/", url: url_ListDashboards_614106,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupMemberships_614123 = ref object of OpenApiRestCall_612658
proc url_ListGroupMemberships_614125(protocol: Scheme; host: string; base: string;
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

proc validate_ListGroupMemberships_614124(path: JsonNode; query: JsonNode;
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
  var valid_614126 = path.getOrDefault("GroupName")
  valid_614126 = validateParameter(valid_614126, JString, required = true,
                                 default = nil)
  if valid_614126 != nil:
    section.add "GroupName", valid_614126
  var valid_614127 = path.getOrDefault("AwsAccountId")
  valid_614127 = validateParameter(valid_614127, JString, required = true,
                                 default = nil)
  if valid_614127 != nil:
    section.add "AwsAccountId", valid_614127
  var valid_614128 = path.getOrDefault("Namespace")
  valid_614128 = validateParameter(valid_614128, JString, required = true,
                                 default = nil)
  if valid_614128 != nil:
    section.add "Namespace", valid_614128
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return from this request.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_614129 = query.getOrDefault("max-results")
  valid_614129 = validateParameter(valid_614129, JInt, required = false, default = nil)
  if valid_614129 != nil:
    section.add "max-results", valid_614129
  var valid_614130 = query.getOrDefault("next-token")
  valid_614130 = validateParameter(valid_614130, JString, required = false,
                                 default = nil)
  if valid_614130 != nil:
    section.add "next-token", valid_614130
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614131 = header.getOrDefault("X-Amz-Signature")
  valid_614131 = validateParameter(valid_614131, JString, required = false,
                                 default = nil)
  if valid_614131 != nil:
    section.add "X-Amz-Signature", valid_614131
  var valid_614132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614132 = validateParameter(valid_614132, JString, required = false,
                                 default = nil)
  if valid_614132 != nil:
    section.add "X-Amz-Content-Sha256", valid_614132
  var valid_614133 = header.getOrDefault("X-Amz-Date")
  valid_614133 = validateParameter(valid_614133, JString, required = false,
                                 default = nil)
  if valid_614133 != nil:
    section.add "X-Amz-Date", valid_614133
  var valid_614134 = header.getOrDefault("X-Amz-Credential")
  valid_614134 = validateParameter(valid_614134, JString, required = false,
                                 default = nil)
  if valid_614134 != nil:
    section.add "X-Amz-Credential", valid_614134
  var valid_614135 = header.getOrDefault("X-Amz-Security-Token")
  valid_614135 = validateParameter(valid_614135, JString, required = false,
                                 default = nil)
  if valid_614135 != nil:
    section.add "X-Amz-Security-Token", valid_614135
  var valid_614136 = header.getOrDefault("X-Amz-Algorithm")
  valid_614136 = validateParameter(valid_614136, JString, required = false,
                                 default = nil)
  if valid_614136 != nil:
    section.add "X-Amz-Algorithm", valid_614136
  var valid_614137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614137 = validateParameter(valid_614137, JString, required = false,
                                 default = nil)
  if valid_614137 != nil:
    section.add "X-Amz-SignedHeaders", valid_614137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614138: Call_ListGroupMemberships_614123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists member users in a group.
  ## 
  let valid = call_614138.validator(path, query, header, formData, body)
  let scheme = call_614138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614138.url(scheme.get, call_614138.host, call_614138.base,
                         call_614138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614138, url, valid)

proc call*(call_614139: Call_ListGroupMemberships_614123; GroupName: string;
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
  var path_614140 = newJObject()
  var query_614141 = newJObject()
  add(path_614140, "GroupName", newJString(GroupName))
  add(path_614140, "AwsAccountId", newJString(AwsAccountId))
  add(path_614140, "Namespace", newJString(Namespace))
  add(query_614141, "max-results", newJInt(maxResults))
  add(query_614141, "next-token", newJString(nextToken))
  result = call_614139.call(path_614140, query_614141, nil, nil, nil)

var listGroupMemberships* = Call_ListGroupMemberships_614123(
    name: "listGroupMemberships", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members",
    validator: validate_ListGroupMemberships_614124, base: "/",
    url: url_ListGroupMemberships_614125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIAMPolicyAssignments_614142 = ref object of OpenApiRestCall_612658
proc url_ListIAMPolicyAssignments_614144(protocol: Scheme; host: string;
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

proc validate_ListIAMPolicyAssignments_614143(path: JsonNode; query: JsonNode;
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
  var valid_614145 = path.getOrDefault("AwsAccountId")
  valid_614145 = validateParameter(valid_614145, JString, required = true,
                                 default = nil)
  if valid_614145 != nil:
    section.add "AwsAccountId", valid_614145
  var valid_614146 = path.getOrDefault("Namespace")
  valid_614146 = validateParameter(valid_614146, JString, required = true,
                                 default = nil)
  if valid_614146 != nil:
    section.add "Namespace", valid_614146
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_614147 = query.getOrDefault("max-results")
  valid_614147 = validateParameter(valid_614147, JInt, required = false, default = nil)
  if valid_614147 != nil:
    section.add "max-results", valid_614147
  var valid_614148 = query.getOrDefault("next-token")
  valid_614148 = validateParameter(valid_614148, JString, required = false,
                                 default = nil)
  if valid_614148 != nil:
    section.add "next-token", valid_614148
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614149 = header.getOrDefault("X-Amz-Signature")
  valid_614149 = validateParameter(valid_614149, JString, required = false,
                                 default = nil)
  if valid_614149 != nil:
    section.add "X-Amz-Signature", valid_614149
  var valid_614150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614150 = validateParameter(valid_614150, JString, required = false,
                                 default = nil)
  if valid_614150 != nil:
    section.add "X-Amz-Content-Sha256", valid_614150
  var valid_614151 = header.getOrDefault("X-Amz-Date")
  valid_614151 = validateParameter(valid_614151, JString, required = false,
                                 default = nil)
  if valid_614151 != nil:
    section.add "X-Amz-Date", valid_614151
  var valid_614152 = header.getOrDefault("X-Amz-Credential")
  valid_614152 = validateParameter(valid_614152, JString, required = false,
                                 default = nil)
  if valid_614152 != nil:
    section.add "X-Amz-Credential", valid_614152
  var valid_614153 = header.getOrDefault("X-Amz-Security-Token")
  valid_614153 = validateParameter(valid_614153, JString, required = false,
                                 default = nil)
  if valid_614153 != nil:
    section.add "X-Amz-Security-Token", valid_614153
  var valid_614154 = header.getOrDefault("X-Amz-Algorithm")
  valid_614154 = validateParameter(valid_614154, JString, required = false,
                                 default = nil)
  if valid_614154 != nil:
    section.add "X-Amz-Algorithm", valid_614154
  var valid_614155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614155 = validateParameter(valid_614155, JString, required = false,
                                 default = nil)
  if valid_614155 != nil:
    section.add "X-Amz-SignedHeaders", valid_614155
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614157: Call_ListIAMPolicyAssignments_614142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists IAM policy assignments in the current Amazon QuickSight account.
  ## 
  let valid = call_614157.validator(path, query, header, formData, body)
  let scheme = call_614157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614157.url(scheme.get, call_614157.host, call_614157.base,
                         call_614157.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614157, url, valid)

proc call*(call_614158: Call_ListIAMPolicyAssignments_614142; AwsAccountId: string;
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
  var path_614159 = newJObject()
  var query_614160 = newJObject()
  var body_614161 = newJObject()
  add(path_614159, "AwsAccountId", newJString(AwsAccountId))
  add(path_614159, "Namespace", newJString(Namespace))
  add(query_614160, "max-results", newJInt(maxResults))
  if body != nil:
    body_614161 = body
  add(query_614160, "next-token", newJString(nextToken))
  result = call_614158.call(path_614159, query_614160, nil, nil, body_614161)

var listIAMPolicyAssignments* = Call_ListIAMPolicyAssignments_614142(
    name: "listIAMPolicyAssignments", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments",
    validator: validate_ListIAMPolicyAssignments_614143, base: "/",
    url: url_ListIAMPolicyAssignments_614144, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIAMPolicyAssignmentsForUser_614162 = ref object of OpenApiRestCall_612658
proc url_ListIAMPolicyAssignmentsForUser_614164(protocol: Scheme; host: string;
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

proc validate_ListIAMPolicyAssignmentsForUser_614163(path: JsonNode;
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
  var valid_614165 = path.getOrDefault("AwsAccountId")
  valid_614165 = validateParameter(valid_614165, JString, required = true,
                                 default = nil)
  if valid_614165 != nil:
    section.add "AwsAccountId", valid_614165
  var valid_614166 = path.getOrDefault("Namespace")
  valid_614166 = validateParameter(valid_614166, JString, required = true,
                                 default = nil)
  if valid_614166 != nil:
    section.add "Namespace", valid_614166
  var valid_614167 = path.getOrDefault("UserName")
  valid_614167 = validateParameter(valid_614167, JString, required = true,
                                 default = nil)
  if valid_614167 != nil:
    section.add "UserName", valid_614167
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_614168 = query.getOrDefault("max-results")
  valid_614168 = validateParameter(valid_614168, JInt, required = false, default = nil)
  if valid_614168 != nil:
    section.add "max-results", valid_614168
  var valid_614169 = query.getOrDefault("next-token")
  valid_614169 = validateParameter(valid_614169, JString, required = false,
                                 default = nil)
  if valid_614169 != nil:
    section.add "next-token", valid_614169
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614170 = header.getOrDefault("X-Amz-Signature")
  valid_614170 = validateParameter(valid_614170, JString, required = false,
                                 default = nil)
  if valid_614170 != nil:
    section.add "X-Amz-Signature", valid_614170
  var valid_614171 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614171 = validateParameter(valid_614171, JString, required = false,
                                 default = nil)
  if valid_614171 != nil:
    section.add "X-Amz-Content-Sha256", valid_614171
  var valid_614172 = header.getOrDefault("X-Amz-Date")
  valid_614172 = validateParameter(valid_614172, JString, required = false,
                                 default = nil)
  if valid_614172 != nil:
    section.add "X-Amz-Date", valid_614172
  var valid_614173 = header.getOrDefault("X-Amz-Credential")
  valid_614173 = validateParameter(valid_614173, JString, required = false,
                                 default = nil)
  if valid_614173 != nil:
    section.add "X-Amz-Credential", valid_614173
  var valid_614174 = header.getOrDefault("X-Amz-Security-Token")
  valid_614174 = validateParameter(valid_614174, JString, required = false,
                                 default = nil)
  if valid_614174 != nil:
    section.add "X-Amz-Security-Token", valid_614174
  var valid_614175 = header.getOrDefault("X-Amz-Algorithm")
  valid_614175 = validateParameter(valid_614175, JString, required = false,
                                 default = nil)
  if valid_614175 != nil:
    section.add "X-Amz-Algorithm", valid_614175
  var valid_614176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614176 = validateParameter(valid_614176, JString, required = false,
                                 default = nil)
  if valid_614176 != nil:
    section.add "X-Amz-SignedHeaders", valid_614176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614177: Call_ListIAMPolicyAssignmentsForUser_614162;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists all the IAM policy assignments, including the Amazon Resource Names (ARNs) for the IAM policies assigned to the specified user and group or groups that the user belongs to.
  ## 
  let valid = call_614177.validator(path, query, header, formData, body)
  let scheme = call_614177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614177.url(scheme.get, call_614177.host, call_614177.base,
                         call_614177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614177, url, valid)

proc call*(call_614178: Call_ListIAMPolicyAssignmentsForUser_614162;
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
  var path_614179 = newJObject()
  var query_614180 = newJObject()
  add(path_614179, "AwsAccountId", newJString(AwsAccountId))
  add(path_614179, "Namespace", newJString(Namespace))
  add(path_614179, "UserName", newJString(UserName))
  add(query_614180, "max-results", newJInt(maxResults))
  add(query_614180, "next-token", newJString(nextToken))
  result = call_614178.call(path_614179, query_614180, nil, nil, nil)

var listIAMPolicyAssignmentsForUser* = Call_ListIAMPolicyAssignmentsForUser_614162(
    name: "listIAMPolicyAssignmentsForUser", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}/iam-policy-assignments",
    validator: validate_ListIAMPolicyAssignmentsForUser_614163, base: "/",
    url: url_ListIAMPolicyAssignmentsForUser_614164,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIngestions_614181 = ref object of OpenApiRestCall_612658
proc url_ListIngestions_614183(protocol: Scheme; host: string; base: string;
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

proc validate_ListIngestions_614182(path: JsonNode; query: JsonNode;
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
  var valid_614184 = path.getOrDefault("AwsAccountId")
  valid_614184 = validateParameter(valid_614184, JString, required = true,
                                 default = nil)
  if valid_614184 != nil:
    section.add "AwsAccountId", valid_614184
  var valid_614185 = path.getOrDefault("DataSetId")
  valid_614185 = validateParameter(valid_614185, JString, required = true,
                                 default = nil)
  if valid_614185 != nil:
    section.add "DataSetId", valid_614185
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
  var valid_614186 = query.getOrDefault("MaxResults")
  valid_614186 = validateParameter(valid_614186, JString, required = false,
                                 default = nil)
  if valid_614186 != nil:
    section.add "MaxResults", valid_614186
  var valid_614187 = query.getOrDefault("NextToken")
  valid_614187 = validateParameter(valid_614187, JString, required = false,
                                 default = nil)
  if valid_614187 != nil:
    section.add "NextToken", valid_614187
  var valid_614188 = query.getOrDefault("max-results")
  valid_614188 = validateParameter(valid_614188, JInt, required = false, default = nil)
  if valid_614188 != nil:
    section.add "max-results", valid_614188
  var valid_614189 = query.getOrDefault("next-token")
  valid_614189 = validateParameter(valid_614189, JString, required = false,
                                 default = nil)
  if valid_614189 != nil:
    section.add "next-token", valid_614189
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614190 = header.getOrDefault("X-Amz-Signature")
  valid_614190 = validateParameter(valid_614190, JString, required = false,
                                 default = nil)
  if valid_614190 != nil:
    section.add "X-Amz-Signature", valid_614190
  var valid_614191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614191 = validateParameter(valid_614191, JString, required = false,
                                 default = nil)
  if valid_614191 != nil:
    section.add "X-Amz-Content-Sha256", valid_614191
  var valid_614192 = header.getOrDefault("X-Amz-Date")
  valid_614192 = validateParameter(valid_614192, JString, required = false,
                                 default = nil)
  if valid_614192 != nil:
    section.add "X-Amz-Date", valid_614192
  var valid_614193 = header.getOrDefault("X-Amz-Credential")
  valid_614193 = validateParameter(valid_614193, JString, required = false,
                                 default = nil)
  if valid_614193 != nil:
    section.add "X-Amz-Credential", valid_614193
  var valid_614194 = header.getOrDefault("X-Amz-Security-Token")
  valid_614194 = validateParameter(valid_614194, JString, required = false,
                                 default = nil)
  if valid_614194 != nil:
    section.add "X-Amz-Security-Token", valid_614194
  var valid_614195 = header.getOrDefault("X-Amz-Algorithm")
  valid_614195 = validateParameter(valid_614195, JString, required = false,
                                 default = nil)
  if valid_614195 != nil:
    section.add "X-Amz-Algorithm", valid_614195
  var valid_614196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614196 = validateParameter(valid_614196, JString, required = false,
                                 default = nil)
  if valid_614196 != nil:
    section.add "X-Amz-SignedHeaders", valid_614196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614197: Call_ListIngestions_614181; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the history of SPICE ingestions for a dataset.
  ## 
  let valid = call_614197.validator(path, query, header, formData, body)
  let scheme = call_614197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614197.url(scheme.get, call_614197.host, call_614197.base,
                         call_614197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614197, url, valid)

proc call*(call_614198: Call_ListIngestions_614181; AwsAccountId: string;
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
  var path_614199 = newJObject()
  var query_614200 = newJObject()
  add(path_614199, "AwsAccountId", newJString(AwsAccountId))
  add(query_614200, "MaxResults", newJString(MaxResults))
  add(query_614200, "NextToken", newJString(NextToken))
  add(path_614199, "DataSetId", newJString(DataSetId))
  add(query_614200, "max-results", newJInt(maxResults))
  add(query_614200, "next-token", newJString(nextToken))
  result = call_614198.call(path_614199, query_614200, nil, nil, nil)

var listIngestions* = Call_ListIngestions_614181(name: "listIngestions",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions",
    validator: validate_ListIngestions_614182, base: "/", url: url_ListIngestions_614183,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_614215 = ref object of OpenApiRestCall_612658
proc url_TagResource_614217(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_614216(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614218 = path.getOrDefault("ResourceArn")
  valid_614218 = validateParameter(valid_614218, JString, required = true,
                                 default = nil)
  if valid_614218 != nil:
    section.add "ResourceArn", valid_614218
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
  var valid_614219 = header.getOrDefault("X-Amz-Signature")
  valid_614219 = validateParameter(valid_614219, JString, required = false,
                                 default = nil)
  if valid_614219 != nil:
    section.add "X-Amz-Signature", valid_614219
  var valid_614220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614220 = validateParameter(valid_614220, JString, required = false,
                                 default = nil)
  if valid_614220 != nil:
    section.add "X-Amz-Content-Sha256", valid_614220
  var valid_614221 = header.getOrDefault("X-Amz-Date")
  valid_614221 = validateParameter(valid_614221, JString, required = false,
                                 default = nil)
  if valid_614221 != nil:
    section.add "X-Amz-Date", valid_614221
  var valid_614222 = header.getOrDefault("X-Amz-Credential")
  valid_614222 = validateParameter(valid_614222, JString, required = false,
                                 default = nil)
  if valid_614222 != nil:
    section.add "X-Amz-Credential", valid_614222
  var valid_614223 = header.getOrDefault("X-Amz-Security-Token")
  valid_614223 = validateParameter(valid_614223, JString, required = false,
                                 default = nil)
  if valid_614223 != nil:
    section.add "X-Amz-Security-Token", valid_614223
  var valid_614224 = header.getOrDefault("X-Amz-Algorithm")
  valid_614224 = validateParameter(valid_614224, JString, required = false,
                                 default = nil)
  if valid_614224 != nil:
    section.add "X-Amz-Algorithm", valid_614224
  var valid_614225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614225 = validateParameter(valid_614225, JString, required = false,
                                 default = nil)
  if valid_614225 != nil:
    section.add "X-Amz-SignedHeaders", valid_614225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614227: Call_TagResource_614215; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns one or more tags (key-value pairs) to the specified QuickSight resource. </p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. You can use the <code>TagResource</code> operation with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource. QuickSight supports tagging on data set, data source, dashboard, and template. </p> <p>Tagging for QuickSight works in a similar way to tagging for other AWS services, except for the following:</p> <ul> <li> <p>You can't use tags to track AWS costs for QuickSight. This restriction is because QuickSight costs are based on users and SPICE capacity, which aren't taggable resources.</p> </li> <li> <p>QuickSight doesn't currently support the Tag Editor for AWS Resource Groups.</p> </li> </ul>
  ## 
  let valid = call_614227.validator(path, query, header, formData, body)
  let scheme = call_614227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614227.url(scheme.get, call_614227.host, call_614227.base,
                         call_614227.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614227, url, valid)

proc call*(call_614228: Call_TagResource_614215; ResourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Assigns one or more tags (key-value pairs) to the specified QuickSight resource. </p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. You can use the <code>TagResource</code> operation with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource. QuickSight supports tagging on data set, data source, dashboard, and template. </p> <p>Tagging for QuickSight works in a similar way to tagging for other AWS services, except for the following:</p> <ul> <li> <p>You can't use tags to track AWS costs for QuickSight. This restriction is because QuickSight costs are based on users and SPICE capacity, which aren't taggable resources.</p> </li> <li> <p>QuickSight doesn't currently support the Tag Editor for AWS Resource Groups.</p> </li> </ul>
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to tag.
  ##   body: JObject (required)
  var path_614229 = newJObject()
  var body_614230 = newJObject()
  add(path_614229, "ResourceArn", newJString(ResourceArn))
  if body != nil:
    body_614230 = body
  result = call_614228.call(path_614229, nil, nil, nil, body_614230)

var tagResource* = Call_TagResource_614215(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "quicksight.amazonaws.com",
                                        route: "/resources/{ResourceArn}/tags",
                                        validator: validate_TagResource_614216,
                                        base: "/", url: url_TagResource_614217,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_614201 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_614203(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_614202(path: JsonNode; query: JsonNode;
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
  var valid_614204 = path.getOrDefault("ResourceArn")
  valid_614204 = validateParameter(valid_614204, JString, required = true,
                                 default = nil)
  if valid_614204 != nil:
    section.add "ResourceArn", valid_614204
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
  var valid_614205 = header.getOrDefault("X-Amz-Signature")
  valid_614205 = validateParameter(valid_614205, JString, required = false,
                                 default = nil)
  if valid_614205 != nil:
    section.add "X-Amz-Signature", valid_614205
  var valid_614206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614206 = validateParameter(valid_614206, JString, required = false,
                                 default = nil)
  if valid_614206 != nil:
    section.add "X-Amz-Content-Sha256", valid_614206
  var valid_614207 = header.getOrDefault("X-Amz-Date")
  valid_614207 = validateParameter(valid_614207, JString, required = false,
                                 default = nil)
  if valid_614207 != nil:
    section.add "X-Amz-Date", valid_614207
  var valid_614208 = header.getOrDefault("X-Amz-Credential")
  valid_614208 = validateParameter(valid_614208, JString, required = false,
                                 default = nil)
  if valid_614208 != nil:
    section.add "X-Amz-Credential", valid_614208
  var valid_614209 = header.getOrDefault("X-Amz-Security-Token")
  valid_614209 = validateParameter(valid_614209, JString, required = false,
                                 default = nil)
  if valid_614209 != nil:
    section.add "X-Amz-Security-Token", valid_614209
  var valid_614210 = header.getOrDefault("X-Amz-Algorithm")
  valid_614210 = validateParameter(valid_614210, JString, required = false,
                                 default = nil)
  if valid_614210 != nil:
    section.add "X-Amz-Algorithm", valid_614210
  var valid_614211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614211 = validateParameter(valid_614211, JString, required = false,
                                 default = nil)
  if valid_614211 != nil:
    section.add "X-Amz-SignedHeaders", valid_614211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614212: Call_ListTagsForResource_614201; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags assigned to a resource.
  ## 
  let valid = call_614212.validator(path, query, header, formData, body)
  let scheme = call_614212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614212.url(scheme.get, call_614212.host, call_614212.base,
                         call_614212.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614212, url, valid)

proc call*(call_614213: Call_ListTagsForResource_614201; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags assigned to a resource.
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want a list of tags for.
  var path_614214 = newJObject()
  add(path_614214, "ResourceArn", newJString(ResourceArn))
  result = call_614213.call(path_614214, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_614201(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/resources/{ResourceArn}/tags",
    validator: validate_ListTagsForResource_614202, base: "/",
    url: url_ListTagsForResource_614203, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplateAliases_614231 = ref object of OpenApiRestCall_612658
proc url_ListTemplateAliases_614233(protocol: Scheme; host: string; base: string;
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

proc validate_ListTemplateAliases_614232(path: JsonNode; query: JsonNode;
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
  var valid_614234 = path.getOrDefault("AwsAccountId")
  valid_614234 = validateParameter(valid_614234, JString, required = true,
                                 default = nil)
  if valid_614234 != nil:
    section.add "AwsAccountId", valid_614234
  var valid_614235 = path.getOrDefault("TemplateId")
  valid_614235 = validateParameter(valid_614235, JString, required = true,
                                 default = nil)
  if valid_614235 != nil:
    section.add "TemplateId", valid_614235
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
  var valid_614236 = query.getOrDefault("MaxResults")
  valid_614236 = validateParameter(valid_614236, JString, required = false,
                                 default = nil)
  if valid_614236 != nil:
    section.add "MaxResults", valid_614236
  var valid_614237 = query.getOrDefault("NextToken")
  valid_614237 = validateParameter(valid_614237, JString, required = false,
                                 default = nil)
  if valid_614237 != nil:
    section.add "NextToken", valid_614237
  var valid_614238 = query.getOrDefault("max-result")
  valid_614238 = validateParameter(valid_614238, JInt, required = false, default = nil)
  if valid_614238 != nil:
    section.add "max-result", valid_614238
  var valid_614239 = query.getOrDefault("next-token")
  valid_614239 = validateParameter(valid_614239, JString, required = false,
                                 default = nil)
  if valid_614239 != nil:
    section.add "next-token", valid_614239
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614240 = header.getOrDefault("X-Amz-Signature")
  valid_614240 = validateParameter(valid_614240, JString, required = false,
                                 default = nil)
  if valid_614240 != nil:
    section.add "X-Amz-Signature", valid_614240
  var valid_614241 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614241 = validateParameter(valid_614241, JString, required = false,
                                 default = nil)
  if valid_614241 != nil:
    section.add "X-Amz-Content-Sha256", valid_614241
  var valid_614242 = header.getOrDefault("X-Amz-Date")
  valid_614242 = validateParameter(valid_614242, JString, required = false,
                                 default = nil)
  if valid_614242 != nil:
    section.add "X-Amz-Date", valid_614242
  var valid_614243 = header.getOrDefault("X-Amz-Credential")
  valid_614243 = validateParameter(valid_614243, JString, required = false,
                                 default = nil)
  if valid_614243 != nil:
    section.add "X-Amz-Credential", valid_614243
  var valid_614244 = header.getOrDefault("X-Amz-Security-Token")
  valid_614244 = validateParameter(valid_614244, JString, required = false,
                                 default = nil)
  if valid_614244 != nil:
    section.add "X-Amz-Security-Token", valid_614244
  var valid_614245 = header.getOrDefault("X-Amz-Algorithm")
  valid_614245 = validateParameter(valid_614245, JString, required = false,
                                 default = nil)
  if valid_614245 != nil:
    section.add "X-Amz-Algorithm", valid_614245
  var valid_614246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614246 = validateParameter(valid_614246, JString, required = false,
                                 default = nil)
  if valid_614246 != nil:
    section.add "X-Amz-SignedHeaders", valid_614246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614247: Call_ListTemplateAliases_614231; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the aliases of a template.
  ## 
  let valid = call_614247.validator(path, query, header, formData, body)
  let scheme = call_614247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614247.url(scheme.get, call_614247.host, call_614247.base,
                         call_614247.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614247, url, valid)

proc call*(call_614248: Call_ListTemplateAliases_614231; AwsAccountId: string;
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
  var path_614249 = newJObject()
  var query_614250 = newJObject()
  add(path_614249, "AwsAccountId", newJString(AwsAccountId))
  add(query_614250, "MaxResults", newJString(MaxResults))
  add(query_614250, "NextToken", newJString(NextToken))
  add(query_614250, "max-result", newJInt(maxResult))
  add(path_614249, "TemplateId", newJString(TemplateId))
  add(query_614250, "next-token", newJString(nextToken))
  result = call_614248.call(path_614249, query_614250, nil, nil, nil)

var listTemplateAliases* = Call_ListTemplateAliases_614231(
    name: "listTemplateAliases", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases",
    validator: validate_ListTemplateAliases_614232, base: "/",
    url: url_ListTemplateAliases_614233, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplateVersions_614251 = ref object of OpenApiRestCall_612658
proc url_ListTemplateVersions_614253(protocol: Scheme; host: string; base: string;
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

proc validate_ListTemplateVersions_614252(path: JsonNode; query: JsonNode;
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
  var valid_614254 = path.getOrDefault("AwsAccountId")
  valid_614254 = validateParameter(valid_614254, JString, required = true,
                                 default = nil)
  if valid_614254 != nil:
    section.add "AwsAccountId", valid_614254
  var valid_614255 = path.getOrDefault("TemplateId")
  valid_614255 = validateParameter(valid_614255, JString, required = true,
                                 default = nil)
  if valid_614255 != nil:
    section.add "TemplateId", valid_614255
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
  var valid_614256 = query.getOrDefault("MaxResults")
  valid_614256 = validateParameter(valid_614256, JString, required = false,
                                 default = nil)
  if valid_614256 != nil:
    section.add "MaxResults", valid_614256
  var valid_614257 = query.getOrDefault("NextToken")
  valid_614257 = validateParameter(valid_614257, JString, required = false,
                                 default = nil)
  if valid_614257 != nil:
    section.add "NextToken", valid_614257
  var valid_614258 = query.getOrDefault("max-results")
  valid_614258 = validateParameter(valid_614258, JInt, required = false, default = nil)
  if valid_614258 != nil:
    section.add "max-results", valid_614258
  var valid_614259 = query.getOrDefault("next-token")
  valid_614259 = validateParameter(valid_614259, JString, required = false,
                                 default = nil)
  if valid_614259 != nil:
    section.add "next-token", valid_614259
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614260 = header.getOrDefault("X-Amz-Signature")
  valid_614260 = validateParameter(valid_614260, JString, required = false,
                                 default = nil)
  if valid_614260 != nil:
    section.add "X-Amz-Signature", valid_614260
  var valid_614261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614261 = validateParameter(valid_614261, JString, required = false,
                                 default = nil)
  if valid_614261 != nil:
    section.add "X-Amz-Content-Sha256", valid_614261
  var valid_614262 = header.getOrDefault("X-Amz-Date")
  valid_614262 = validateParameter(valid_614262, JString, required = false,
                                 default = nil)
  if valid_614262 != nil:
    section.add "X-Amz-Date", valid_614262
  var valid_614263 = header.getOrDefault("X-Amz-Credential")
  valid_614263 = validateParameter(valid_614263, JString, required = false,
                                 default = nil)
  if valid_614263 != nil:
    section.add "X-Amz-Credential", valid_614263
  var valid_614264 = header.getOrDefault("X-Amz-Security-Token")
  valid_614264 = validateParameter(valid_614264, JString, required = false,
                                 default = nil)
  if valid_614264 != nil:
    section.add "X-Amz-Security-Token", valid_614264
  var valid_614265 = header.getOrDefault("X-Amz-Algorithm")
  valid_614265 = validateParameter(valid_614265, JString, required = false,
                                 default = nil)
  if valid_614265 != nil:
    section.add "X-Amz-Algorithm", valid_614265
  var valid_614266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614266 = validateParameter(valid_614266, JString, required = false,
                                 default = nil)
  if valid_614266 != nil:
    section.add "X-Amz-SignedHeaders", valid_614266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614267: Call_ListTemplateVersions_614251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the versions of the templates in the current Amazon QuickSight account.
  ## 
  let valid = call_614267.validator(path, query, header, formData, body)
  let scheme = call_614267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614267.url(scheme.get, call_614267.host, call_614267.base,
                         call_614267.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614267, url, valid)

proc call*(call_614268: Call_ListTemplateVersions_614251; AwsAccountId: string;
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
  var path_614269 = newJObject()
  var query_614270 = newJObject()
  add(path_614269, "AwsAccountId", newJString(AwsAccountId))
  add(query_614270, "MaxResults", newJString(MaxResults))
  add(query_614270, "NextToken", newJString(NextToken))
  add(query_614270, "max-results", newJInt(maxResults))
  add(path_614269, "TemplateId", newJString(TemplateId))
  add(query_614270, "next-token", newJString(nextToken))
  result = call_614268.call(path_614269, query_614270, nil, nil, nil)

var listTemplateVersions* = Call_ListTemplateVersions_614251(
    name: "listTemplateVersions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}/versions",
    validator: validate_ListTemplateVersions_614252, base: "/",
    url: url_ListTemplateVersions_614253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplates_614271 = ref object of OpenApiRestCall_612658
proc url_ListTemplates_614273(protocol: Scheme; host: string; base: string;
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

proc validate_ListTemplates_614272(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614274 = path.getOrDefault("AwsAccountId")
  valid_614274 = validateParameter(valid_614274, JString, required = true,
                                 default = nil)
  if valid_614274 != nil:
    section.add "AwsAccountId", valid_614274
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
  var valid_614275 = query.getOrDefault("MaxResults")
  valid_614275 = validateParameter(valid_614275, JString, required = false,
                                 default = nil)
  if valid_614275 != nil:
    section.add "MaxResults", valid_614275
  var valid_614276 = query.getOrDefault("NextToken")
  valid_614276 = validateParameter(valid_614276, JString, required = false,
                                 default = nil)
  if valid_614276 != nil:
    section.add "NextToken", valid_614276
  var valid_614277 = query.getOrDefault("max-result")
  valid_614277 = validateParameter(valid_614277, JInt, required = false, default = nil)
  if valid_614277 != nil:
    section.add "max-result", valid_614277
  var valid_614278 = query.getOrDefault("next-token")
  valid_614278 = validateParameter(valid_614278, JString, required = false,
                                 default = nil)
  if valid_614278 != nil:
    section.add "next-token", valid_614278
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614279 = header.getOrDefault("X-Amz-Signature")
  valid_614279 = validateParameter(valid_614279, JString, required = false,
                                 default = nil)
  if valid_614279 != nil:
    section.add "X-Amz-Signature", valid_614279
  var valid_614280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614280 = validateParameter(valid_614280, JString, required = false,
                                 default = nil)
  if valid_614280 != nil:
    section.add "X-Amz-Content-Sha256", valid_614280
  var valid_614281 = header.getOrDefault("X-Amz-Date")
  valid_614281 = validateParameter(valid_614281, JString, required = false,
                                 default = nil)
  if valid_614281 != nil:
    section.add "X-Amz-Date", valid_614281
  var valid_614282 = header.getOrDefault("X-Amz-Credential")
  valid_614282 = validateParameter(valid_614282, JString, required = false,
                                 default = nil)
  if valid_614282 != nil:
    section.add "X-Amz-Credential", valid_614282
  var valid_614283 = header.getOrDefault("X-Amz-Security-Token")
  valid_614283 = validateParameter(valid_614283, JString, required = false,
                                 default = nil)
  if valid_614283 != nil:
    section.add "X-Amz-Security-Token", valid_614283
  var valid_614284 = header.getOrDefault("X-Amz-Algorithm")
  valid_614284 = validateParameter(valid_614284, JString, required = false,
                                 default = nil)
  if valid_614284 != nil:
    section.add "X-Amz-Algorithm", valid_614284
  var valid_614285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614285 = validateParameter(valid_614285, JString, required = false,
                                 default = nil)
  if valid_614285 != nil:
    section.add "X-Amz-SignedHeaders", valid_614285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614286: Call_ListTemplates_614271; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the templates in the current Amazon QuickSight account.
  ## 
  let valid = call_614286.validator(path, query, header, formData, body)
  let scheme = call_614286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614286.url(scheme.get, call_614286.host, call_614286.base,
                         call_614286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614286, url, valid)

proc call*(call_614287: Call_ListTemplates_614271; AwsAccountId: string;
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
  var path_614288 = newJObject()
  var query_614289 = newJObject()
  add(path_614288, "AwsAccountId", newJString(AwsAccountId))
  add(query_614289, "MaxResults", newJString(MaxResults))
  add(query_614289, "NextToken", newJString(NextToken))
  add(query_614289, "max-result", newJInt(maxResult))
  add(query_614289, "next-token", newJString(nextToken))
  result = call_614287.call(path_614288, query_614289, nil, nil, nil)

var listTemplates* = Call_ListTemplates_614271(name: "listTemplates",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates",
    validator: validate_ListTemplates_614272, base: "/", url: url_ListTemplates_614273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserGroups_614290 = ref object of OpenApiRestCall_612658
proc url_ListUserGroups_614292(protocol: Scheme; host: string; base: string;
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

proc validate_ListUserGroups_614291(path: JsonNode; query: JsonNode;
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
  var valid_614293 = path.getOrDefault("AwsAccountId")
  valid_614293 = validateParameter(valid_614293, JString, required = true,
                                 default = nil)
  if valid_614293 != nil:
    section.add "AwsAccountId", valid_614293
  var valid_614294 = path.getOrDefault("Namespace")
  valid_614294 = validateParameter(valid_614294, JString, required = true,
                                 default = nil)
  if valid_614294 != nil:
    section.add "Namespace", valid_614294
  var valid_614295 = path.getOrDefault("UserName")
  valid_614295 = validateParameter(valid_614295, JString, required = true,
                                 default = nil)
  if valid_614295 != nil:
    section.add "UserName", valid_614295
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return from this request.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_614296 = query.getOrDefault("max-results")
  valid_614296 = validateParameter(valid_614296, JInt, required = false, default = nil)
  if valid_614296 != nil:
    section.add "max-results", valid_614296
  var valid_614297 = query.getOrDefault("next-token")
  valid_614297 = validateParameter(valid_614297, JString, required = false,
                                 default = nil)
  if valid_614297 != nil:
    section.add "next-token", valid_614297
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614298 = header.getOrDefault("X-Amz-Signature")
  valid_614298 = validateParameter(valid_614298, JString, required = false,
                                 default = nil)
  if valid_614298 != nil:
    section.add "X-Amz-Signature", valid_614298
  var valid_614299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614299 = validateParameter(valid_614299, JString, required = false,
                                 default = nil)
  if valid_614299 != nil:
    section.add "X-Amz-Content-Sha256", valid_614299
  var valid_614300 = header.getOrDefault("X-Amz-Date")
  valid_614300 = validateParameter(valid_614300, JString, required = false,
                                 default = nil)
  if valid_614300 != nil:
    section.add "X-Amz-Date", valid_614300
  var valid_614301 = header.getOrDefault("X-Amz-Credential")
  valid_614301 = validateParameter(valid_614301, JString, required = false,
                                 default = nil)
  if valid_614301 != nil:
    section.add "X-Amz-Credential", valid_614301
  var valid_614302 = header.getOrDefault("X-Amz-Security-Token")
  valid_614302 = validateParameter(valid_614302, JString, required = false,
                                 default = nil)
  if valid_614302 != nil:
    section.add "X-Amz-Security-Token", valid_614302
  var valid_614303 = header.getOrDefault("X-Amz-Algorithm")
  valid_614303 = validateParameter(valid_614303, JString, required = false,
                                 default = nil)
  if valid_614303 != nil:
    section.add "X-Amz-Algorithm", valid_614303
  var valid_614304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614304 = validateParameter(valid_614304, JString, required = false,
                                 default = nil)
  if valid_614304 != nil:
    section.add "X-Amz-SignedHeaders", valid_614304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614305: Call_ListUserGroups_614290; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon QuickSight groups that an Amazon QuickSight user is a member of.
  ## 
  let valid = call_614305.validator(path, query, header, formData, body)
  let scheme = call_614305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614305.url(scheme.get, call_614305.host, call_614305.base,
                         call_614305.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614305, url, valid)

proc call*(call_614306: Call_ListUserGroups_614290; AwsAccountId: string;
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
  var path_614307 = newJObject()
  var query_614308 = newJObject()
  add(path_614307, "AwsAccountId", newJString(AwsAccountId))
  add(path_614307, "Namespace", newJString(Namespace))
  add(path_614307, "UserName", newJString(UserName))
  add(query_614308, "max-results", newJInt(maxResults))
  add(query_614308, "next-token", newJString(nextToken))
  result = call_614306.call(path_614307, query_614308, nil, nil, nil)

var listUserGroups* = Call_ListUserGroups_614290(name: "listUserGroups",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}/groups",
    validator: validate_ListUserGroups_614291, base: "/", url: url_ListUserGroups_614292,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterUser_614327 = ref object of OpenApiRestCall_612658
proc url_RegisterUser_614329(protocol: Scheme; host: string; base: string;
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

proc validate_RegisterUser_614328(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614330 = path.getOrDefault("AwsAccountId")
  valid_614330 = validateParameter(valid_614330, JString, required = true,
                                 default = nil)
  if valid_614330 != nil:
    section.add "AwsAccountId", valid_614330
  var valid_614331 = path.getOrDefault("Namespace")
  valid_614331 = validateParameter(valid_614331, JString, required = true,
                                 default = nil)
  if valid_614331 != nil:
    section.add "Namespace", valid_614331
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
  var valid_614332 = header.getOrDefault("X-Amz-Signature")
  valid_614332 = validateParameter(valid_614332, JString, required = false,
                                 default = nil)
  if valid_614332 != nil:
    section.add "X-Amz-Signature", valid_614332
  var valid_614333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614333 = validateParameter(valid_614333, JString, required = false,
                                 default = nil)
  if valid_614333 != nil:
    section.add "X-Amz-Content-Sha256", valid_614333
  var valid_614334 = header.getOrDefault("X-Amz-Date")
  valid_614334 = validateParameter(valid_614334, JString, required = false,
                                 default = nil)
  if valid_614334 != nil:
    section.add "X-Amz-Date", valid_614334
  var valid_614335 = header.getOrDefault("X-Amz-Credential")
  valid_614335 = validateParameter(valid_614335, JString, required = false,
                                 default = nil)
  if valid_614335 != nil:
    section.add "X-Amz-Credential", valid_614335
  var valid_614336 = header.getOrDefault("X-Amz-Security-Token")
  valid_614336 = validateParameter(valid_614336, JString, required = false,
                                 default = nil)
  if valid_614336 != nil:
    section.add "X-Amz-Security-Token", valid_614336
  var valid_614337 = header.getOrDefault("X-Amz-Algorithm")
  valid_614337 = validateParameter(valid_614337, JString, required = false,
                                 default = nil)
  if valid_614337 != nil:
    section.add "X-Amz-Algorithm", valid_614337
  var valid_614338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614338 = validateParameter(valid_614338, JString, required = false,
                                 default = nil)
  if valid_614338 != nil:
    section.add "X-Amz-SignedHeaders", valid_614338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_614340: Call_RegisterUser_614327; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Amazon QuickSight user, whose identity is associated with the AWS Identity and Access Management (IAM) identity or role specified in the request. 
  ## 
  let valid = call_614340.validator(path, query, header, formData, body)
  let scheme = call_614340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614340.url(scheme.get, call_614340.host, call_614340.base,
                         call_614340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614340, url, valid)

proc call*(call_614341: Call_RegisterUser_614327; AwsAccountId: string;
          Namespace: string; body: JsonNode): Recallable =
  ## registerUser
  ## Creates an Amazon QuickSight user, whose identity is associated with the AWS Identity and Access Management (IAM) identity or role specified in the request. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   body: JObject (required)
  var path_614342 = newJObject()
  var body_614343 = newJObject()
  add(path_614342, "AwsAccountId", newJString(AwsAccountId))
  add(path_614342, "Namespace", newJString(Namespace))
  if body != nil:
    body_614343 = body
  result = call_614341.call(path_614342, nil, nil, nil, body_614343)

var registerUser* = Call_RegisterUser_614327(name: "registerUser",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users",
    validator: validate_RegisterUser_614328, base: "/", url: url_RegisterUser_614329,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_614309 = ref object of OpenApiRestCall_612658
proc url_ListUsers_614311(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListUsers_614310(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614312 = path.getOrDefault("AwsAccountId")
  valid_614312 = validateParameter(valid_614312, JString, required = true,
                                 default = nil)
  if valid_614312 != nil:
    section.add "AwsAccountId", valid_614312
  var valid_614313 = path.getOrDefault("Namespace")
  valid_614313 = validateParameter(valid_614313, JString, required = true,
                                 default = nil)
  if valid_614313 != nil:
    section.add "Namespace", valid_614313
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return from this request.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_614314 = query.getOrDefault("max-results")
  valid_614314 = validateParameter(valid_614314, JInt, required = false, default = nil)
  if valid_614314 != nil:
    section.add "max-results", valid_614314
  var valid_614315 = query.getOrDefault("next-token")
  valid_614315 = validateParameter(valid_614315, JString, required = false,
                                 default = nil)
  if valid_614315 != nil:
    section.add "next-token", valid_614315
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614316 = header.getOrDefault("X-Amz-Signature")
  valid_614316 = validateParameter(valid_614316, JString, required = false,
                                 default = nil)
  if valid_614316 != nil:
    section.add "X-Amz-Signature", valid_614316
  var valid_614317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614317 = validateParameter(valid_614317, JString, required = false,
                                 default = nil)
  if valid_614317 != nil:
    section.add "X-Amz-Content-Sha256", valid_614317
  var valid_614318 = header.getOrDefault("X-Amz-Date")
  valid_614318 = validateParameter(valid_614318, JString, required = false,
                                 default = nil)
  if valid_614318 != nil:
    section.add "X-Amz-Date", valid_614318
  var valid_614319 = header.getOrDefault("X-Amz-Credential")
  valid_614319 = validateParameter(valid_614319, JString, required = false,
                                 default = nil)
  if valid_614319 != nil:
    section.add "X-Amz-Credential", valid_614319
  var valid_614320 = header.getOrDefault("X-Amz-Security-Token")
  valid_614320 = validateParameter(valid_614320, JString, required = false,
                                 default = nil)
  if valid_614320 != nil:
    section.add "X-Amz-Security-Token", valid_614320
  var valid_614321 = header.getOrDefault("X-Amz-Algorithm")
  valid_614321 = validateParameter(valid_614321, JString, required = false,
                                 default = nil)
  if valid_614321 != nil:
    section.add "X-Amz-Algorithm", valid_614321
  var valid_614322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614322 = validateParameter(valid_614322, JString, required = false,
                                 default = nil)
  if valid_614322 != nil:
    section.add "X-Amz-SignedHeaders", valid_614322
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614323: Call_ListUsers_614309; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all of the Amazon QuickSight users belonging to this account. 
  ## 
  let valid = call_614323.validator(path, query, header, formData, body)
  let scheme = call_614323.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614323.url(scheme.get, call_614323.host, call_614323.base,
                         call_614323.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614323, url, valid)

proc call*(call_614324: Call_ListUsers_614309; AwsAccountId: string;
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
  var path_614325 = newJObject()
  var query_614326 = newJObject()
  add(path_614325, "AwsAccountId", newJString(AwsAccountId))
  add(path_614325, "Namespace", newJString(Namespace))
  add(query_614326, "max-results", newJInt(maxResults))
  add(query_614326, "next-token", newJString(nextToken))
  result = call_614324.call(path_614325, query_614326, nil, nil, nil)

var listUsers* = Call_ListUsers_614309(name: "listUsers", meth: HttpMethod.HttpGet,
                                    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users",
                                    validator: validate_ListUsers_614310,
                                    base: "/", url: url_ListUsers_614311,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_614344 = ref object of OpenApiRestCall_612658
proc url_UntagResource_614346(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_614345(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_614347 = path.getOrDefault("ResourceArn")
  valid_614347 = validateParameter(valid_614347, JString, required = true,
                                 default = nil)
  if valid_614347 != nil:
    section.add "ResourceArn", valid_614347
  result.add "path", section
  ## parameters in `query` object:
  ##   keys: JArray (required)
  ##       : The keys of the key-value pairs for the resource tag or tags assigned to the resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `keys` field"
  var valid_614348 = query.getOrDefault("keys")
  valid_614348 = validateParameter(valid_614348, JArray, required = true, default = nil)
  if valid_614348 != nil:
    section.add "keys", valid_614348
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_614349 = header.getOrDefault("X-Amz-Signature")
  valid_614349 = validateParameter(valid_614349, JString, required = false,
                                 default = nil)
  if valid_614349 != nil:
    section.add "X-Amz-Signature", valid_614349
  var valid_614350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614350 = validateParameter(valid_614350, JString, required = false,
                                 default = nil)
  if valid_614350 != nil:
    section.add "X-Amz-Content-Sha256", valid_614350
  var valid_614351 = header.getOrDefault("X-Amz-Date")
  valid_614351 = validateParameter(valid_614351, JString, required = false,
                                 default = nil)
  if valid_614351 != nil:
    section.add "X-Amz-Date", valid_614351
  var valid_614352 = header.getOrDefault("X-Amz-Credential")
  valid_614352 = validateParameter(valid_614352, JString, required = false,
                                 default = nil)
  if valid_614352 != nil:
    section.add "X-Amz-Credential", valid_614352
  var valid_614353 = header.getOrDefault("X-Amz-Security-Token")
  valid_614353 = validateParameter(valid_614353, JString, required = false,
                                 default = nil)
  if valid_614353 != nil:
    section.add "X-Amz-Security-Token", valid_614353
  var valid_614354 = header.getOrDefault("X-Amz-Algorithm")
  valid_614354 = validateParameter(valid_614354, JString, required = false,
                                 default = nil)
  if valid_614354 != nil:
    section.add "X-Amz-Algorithm", valid_614354
  var valid_614355 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614355 = validateParameter(valid_614355, JString, required = false,
                                 default = nil)
  if valid_614355 != nil:
    section.add "X-Amz-SignedHeaders", valid_614355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614356: Call_UntagResource_614344; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag or tags from a resource.
  ## 
  let valid = call_614356.validator(path, query, header, formData, body)
  let scheme = call_614356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614356.url(scheme.get, call_614356.host, call_614356.base,
                         call_614356.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614356, url, valid)

proc call*(call_614357: Call_UntagResource_614344; keys: JsonNode;
          ResourceArn: string): Recallable =
  ## untagResource
  ## Removes a tag or tags from a resource.
  ##   keys: JArray (required)
  ##       : The keys of the key-value pairs for the resource tag or tags assigned to the resource.
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to untag.
  var path_614358 = newJObject()
  var query_614359 = newJObject()
  if keys != nil:
    query_614359.add "keys", keys
  add(path_614358, "ResourceArn", newJString(ResourceArn))
  result = call_614357.call(path_614358, query_614359, nil, nil, nil)

var untagResource* = Call_UntagResource_614344(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/resources/{ResourceArn}/tags#keys",
    validator: validate_UntagResource_614345, base: "/", url: url_UntagResource_614346,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDashboardPublishedVersion_614360 = ref object of OpenApiRestCall_612658
proc url_UpdateDashboardPublishedVersion_614362(protocol: Scheme; host: string;
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

proc validate_UpdateDashboardPublishedVersion_614361(path: JsonNode;
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
  var valid_614363 = path.getOrDefault("AwsAccountId")
  valid_614363 = validateParameter(valid_614363, JString, required = true,
                                 default = nil)
  if valid_614363 != nil:
    section.add "AwsAccountId", valid_614363
  var valid_614364 = path.getOrDefault("VersionNumber")
  valid_614364 = validateParameter(valid_614364, JInt, required = true, default = nil)
  if valid_614364 != nil:
    section.add "VersionNumber", valid_614364
  var valid_614365 = path.getOrDefault("DashboardId")
  valid_614365 = validateParameter(valid_614365, JString, required = true,
                                 default = nil)
  if valid_614365 != nil:
    section.add "DashboardId", valid_614365
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
  var valid_614366 = header.getOrDefault("X-Amz-Signature")
  valid_614366 = validateParameter(valid_614366, JString, required = false,
                                 default = nil)
  if valid_614366 != nil:
    section.add "X-Amz-Signature", valid_614366
  var valid_614367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_614367 = validateParameter(valid_614367, JString, required = false,
                                 default = nil)
  if valid_614367 != nil:
    section.add "X-Amz-Content-Sha256", valid_614367
  var valid_614368 = header.getOrDefault("X-Amz-Date")
  valid_614368 = validateParameter(valid_614368, JString, required = false,
                                 default = nil)
  if valid_614368 != nil:
    section.add "X-Amz-Date", valid_614368
  var valid_614369 = header.getOrDefault("X-Amz-Credential")
  valid_614369 = validateParameter(valid_614369, JString, required = false,
                                 default = nil)
  if valid_614369 != nil:
    section.add "X-Amz-Credential", valid_614369
  var valid_614370 = header.getOrDefault("X-Amz-Security-Token")
  valid_614370 = validateParameter(valid_614370, JString, required = false,
                                 default = nil)
  if valid_614370 != nil:
    section.add "X-Amz-Security-Token", valid_614370
  var valid_614371 = header.getOrDefault("X-Amz-Algorithm")
  valid_614371 = validateParameter(valid_614371, JString, required = false,
                                 default = nil)
  if valid_614371 != nil:
    section.add "X-Amz-Algorithm", valid_614371
  var valid_614372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_614372 = validateParameter(valid_614372, JString, required = false,
                                 default = nil)
  if valid_614372 != nil:
    section.add "X-Amz-SignedHeaders", valid_614372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_614373: Call_UpdateDashboardPublishedVersion_614360;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the published version of a dashboard.
  ## 
  let valid = call_614373.validator(path, query, header, formData, body)
  let scheme = call_614373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_614373.url(scheme.get, call_614373.host, call_614373.base,
                         call_614373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_614373, url, valid)

proc call*(call_614374: Call_UpdateDashboardPublishedVersion_614360;
          AwsAccountId: string; VersionNumber: int; DashboardId: string): Recallable =
  ## updateDashboardPublishedVersion
  ## Updates the published version of a dashboard.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're updating.
  ##   VersionNumber: int (required)
  ##                : The version number of the dashboard.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  var path_614375 = newJObject()
  add(path_614375, "AwsAccountId", newJString(AwsAccountId))
  add(path_614375, "VersionNumber", newJInt(VersionNumber))
  add(path_614375, "DashboardId", newJString(DashboardId))
  result = call_614374.call(path_614375, nil, nil, nil, nil)

var updateDashboardPublishedVersion* = Call_UpdateDashboardPublishedVersion_614360(
    name: "updateDashboardPublishedVersion", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/versions/{VersionNumber}",
    validator: validate_UpdateDashboardPublishedVersion_614361, base: "/",
    url: url_UpdateDashboardPublishedVersion_614362,
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
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
