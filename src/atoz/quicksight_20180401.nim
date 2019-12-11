
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
  Call_CreateIngestion_597999 = ref object of OpenApiRestCall_597389
proc url_CreateIngestion_598001(protocol: Scheme; host: string; base: string;
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

proc validate_CreateIngestion_598000(path: JsonNode; query: JsonNode;
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
  var valid_598002 = path.getOrDefault("AwsAccountId")
  valid_598002 = validateParameter(valid_598002, JString, required = true,
                                 default = nil)
  if valid_598002 != nil:
    section.add "AwsAccountId", valid_598002
  var valid_598003 = path.getOrDefault("DataSetId")
  valid_598003 = validateParameter(valid_598003, JString, required = true,
                                 default = nil)
  if valid_598003 != nil:
    section.add "DataSetId", valid_598003
  var valid_598004 = path.getOrDefault("IngestionId")
  valid_598004 = validateParameter(valid_598004, JString, required = true,
                                 default = nil)
  if valid_598004 != nil:
    section.add "IngestionId", valid_598004
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
  var valid_598005 = header.getOrDefault("X-Amz-Signature")
  valid_598005 = validateParameter(valid_598005, JString, required = false,
                                 default = nil)
  if valid_598005 != nil:
    section.add "X-Amz-Signature", valid_598005
  var valid_598006 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598006 = validateParameter(valid_598006, JString, required = false,
                                 default = nil)
  if valid_598006 != nil:
    section.add "X-Amz-Content-Sha256", valid_598006
  var valid_598007 = header.getOrDefault("X-Amz-Date")
  valid_598007 = validateParameter(valid_598007, JString, required = false,
                                 default = nil)
  if valid_598007 != nil:
    section.add "X-Amz-Date", valid_598007
  var valid_598008 = header.getOrDefault("X-Amz-Credential")
  valid_598008 = validateParameter(valid_598008, JString, required = false,
                                 default = nil)
  if valid_598008 != nil:
    section.add "X-Amz-Credential", valid_598008
  var valid_598009 = header.getOrDefault("X-Amz-Security-Token")
  valid_598009 = validateParameter(valid_598009, JString, required = false,
                                 default = nil)
  if valid_598009 != nil:
    section.add "X-Amz-Security-Token", valid_598009
  var valid_598010 = header.getOrDefault("X-Amz-Algorithm")
  valid_598010 = validateParameter(valid_598010, JString, required = false,
                                 default = nil)
  if valid_598010 != nil:
    section.add "X-Amz-Algorithm", valid_598010
  var valid_598011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598011 = validateParameter(valid_598011, JString, required = false,
                                 default = nil)
  if valid_598011 != nil:
    section.add "X-Amz-SignedHeaders", valid_598011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598012: Call_CreateIngestion_597999; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates and starts a new SPICE ingestion on a dataset</p> <p>Any ingestions operating on tagged datasets inherit the same tags automatically for use in access control. For an example, see <a href="https://aws.example.com/premiumsupport/knowledge-center/iam-ec2-resource-tags/">How do I create an IAM policy to control access to Amazon EC2 resources using tags?</a> in the AWS Knowledge Center. Tags are visible on the tagged dataset, but not on the ingestion resource.</p>
  ## 
  let valid = call_598012.validator(path, query, header, formData, body)
  let scheme = call_598012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598012.url(scheme.get, call_598012.host, call_598012.base,
                         call_598012.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598012, url, valid)

proc call*(call_598013: Call_CreateIngestion_597999; AwsAccountId: string;
          DataSetId: string; IngestionId: string): Recallable =
  ## createIngestion
  ## <p>Creates and starts a new SPICE ingestion on a dataset</p> <p>Any ingestions operating on tagged datasets inherit the same tags automatically for use in access control. For an example, see <a href="https://aws.example.com/premiumsupport/knowledge-center/iam-ec2-resource-tags/">How do I create an IAM policy to control access to Amazon EC2 resources using tags?</a> in the AWS Knowledge Center. Tags are visible on the tagged dataset, but not on the ingestion resource.</p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   IngestionId: string (required)
  ##              : An ID for the ingestion.
  var path_598014 = newJObject()
  add(path_598014, "AwsAccountId", newJString(AwsAccountId))
  add(path_598014, "DataSetId", newJString(DataSetId))
  add(path_598014, "IngestionId", newJString(IngestionId))
  result = call_598013.call(path_598014, nil, nil, nil, nil)

var createIngestion* = Call_CreateIngestion_597999(name: "createIngestion",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}",
    validator: validate_CreateIngestion_598000, base: "/", url: url_CreateIngestion_598001,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIngestion_597727 = ref object of OpenApiRestCall_597389
proc url_DescribeIngestion_597729(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeIngestion_597728(path: JsonNode; query: JsonNode;
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
  var valid_597855 = path.getOrDefault("AwsAccountId")
  valid_597855 = validateParameter(valid_597855, JString, required = true,
                                 default = nil)
  if valid_597855 != nil:
    section.add "AwsAccountId", valid_597855
  var valid_597856 = path.getOrDefault("DataSetId")
  valid_597856 = validateParameter(valid_597856, JString, required = true,
                                 default = nil)
  if valid_597856 != nil:
    section.add "DataSetId", valid_597856
  var valid_597857 = path.getOrDefault("IngestionId")
  valid_597857 = validateParameter(valid_597857, JString, required = true,
                                 default = nil)
  if valid_597857 != nil:
    section.add "IngestionId", valid_597857
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
  var valid_597858 = header.getOrDefault("X-Amz-Signature")
  valid_597858 = validateParameter(valid_597858, JString, required = false,
                                 default = nil)
  if valid_597858 != nil:
    section.add "X-Amz-Signature", valid_597858
  var valid_597859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597859 = validateParameter(valid_597859, JString, required = false,
                                 default = nil)
  if valid_597859 != nil:
    section.add "X-Amz-Content-Sha256", valid_597859
  var valid_597860 = header.getOrDefault("X-Amz-Date")
  valid_597860 = validateParameter(valid_597860, JString, required = false,
                                 default = nil)
  if valid_597860 != nil:
    section.add "X-Amz-Date", valid_597860
  var valid_597861 = header.getOrDefault("X-Amz-Credential")
  valid_597861 = validateParameter(valid_597861, JString, required = false,
                                 default = nil)
  if valid_597861 != nil:
    section.add "X-Amz-Credential", valid_597861
  var valid_597862 = header.getOrDefault("X-Amz-Security-Token")
  valid_597862 = validateParameter(valid_597862, JString, required = false,
                                 default = nil)
  if valid_597862 != nil:
    section.add "X-Amz-Security-Token", valid_597862
  var valid_597863 = header.getOrDefault("X-Amz-Algorithm")
  valid_597863 = validateParameter(valid_597863, JString, required = false,
                                 default = nil)
  if valid_597863 != nil:
    section.add "X-Amz-Algorithm", valid_597863
  var valid_597864 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597864 = validateParameter(valid_597864, JString, required = false,
                                 default = nil)
  if valid_597864 != nil:
    section.add "X-Amz-SignedHeaders", valid_597864
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_597887: Call_DescribeIngestion_597727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a SPICE ingestion.
  ## 
  let valid = call_597887.validator(path, query, header, formData, body)
  let scheme = call_597887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597887.url(scheme.get, call_597887.host, call_597887.base,
                         call_597887.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597887, url, valid)

proc call*(call_597958: Call_DescribeIngestion_597727; AwsAccountId: string;
          DataSetId: string; IngestionId: string): Recallable =
  ## describeIngestion
  ## Describes a SPICE ingestion.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   IngestionId: string (required)
  ##              : An ID for the ingestion.
  var path_597959 = newJObject()
  add(path_597959, "AwsAccountId", newJString(AwsAccountId))
  add(path_597959, "DataSetId", newJString(DataSetId))
  add(path_597959, "IngestionId", newJString(IngestionId))
  result = call_597958.call(path_597959, nil, nil, nil, nil)

var describeIngestion* = Call_DescribeIngestion_597727(name: "describeIngestion",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}",
    validator: validate_DescribeIngestion_597728, base: "/",
    url: url_DescribeIngestion_597729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelIngestion_598015 = ref object of OpenApiRestCall_597389
proc url_CancelIngestion_598017(protocol: Scheme; host: string; base: string;
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

proc validate_CancelIngestion_598016(path: JsonNode; query: JsonNode;
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
  var valid_598018 = path.getOrDefault("AwsAccountId")
  valid_598018 = validateParameter(valid_598018, JString, required = true,
                                 default = nil)
  if valid_598018 != nil:
    section.add "AwsAccountId", valid_598018
  var valid_598019 = path.getOrDefault("DataSetId")
  valid_598019 = validateParameter(valid_598019, JString, required = true,
                                 default = nil)
  if valid_598019 != nil:
    section.add "DataSetId", valid_598019
  var valid_598020 = path.getOrDefault("IngestionId")
  valid_598020 = validateParameter(valid_598020, JString, required = true,
                                 default = nil)
  if valid_598020 != nil:
    section.add "IngestionId", valid_598020
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
  var valid_598021 = header.getOrDefault("X-Amz-Signature")
  valid_598021 = validateParameter(valid_598021, JString, required = false,
                                 default = nil)
  if valid_598021 != nil:
    section.add "X-Amz-Signature", valid_598021
  var valid_598022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598022 = validateParameter(valid_598022, JString, required = false,
                                 default = nil)
  if valid_598022 != nil:
    section.add "X-Amz-Content-Sha256", valid_598022
  var valid_598023 = header.getOrDefault("X-Amz-Date")
  valid_598023 = validateParameter(valid_598023, JString, required = false,
                                 default = nil)
  if valid_598023 != nil:
    section.add "X-Amz-Date", valid_598023
  var valid_598024 = header.getOrDefault("X-Amz-Credential")
  valid_598024 = validateParameter(valid_598024, JString, required = false,
                                 default = nil)
  if valid_598024 != nil:
    section.add "X-Amz-Credential", valid_598024
  var valid_598025 = header.getOrDefault("X-Amz-Security-Token")
  valid_598025 = validateParameter(valid_598025, JString, required = false,
                                 default = nil)
  if valid_598025 != nil:
    section.add "X-Amz-Security-Token", valid_598025
  var valid_598026 = header.getOrDefault("X-Amz-Algorithm")
  valid_598026 = validateParameter(valid_598026, JString, required = false,
                                 default = nil)
  if valid_598026 != nil:
    section.add "X-Amz-Algorithm", valid_598026
  var valid_598027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598027 = validateParameter(valid_598027, JString, required = false,
                                 default = nil)
  if valid_598027 != nil:
    section.add "X-Amz-SignedHeaders", valid_598027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598028: Call_CancelIngestion_598015; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels an ongoing ingestion of data into SPICE.
  ## 
  let valid = call_598028.validator(path, query, header, formData, body)
  let scheme = call_598028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598028.url(scheme.get, call_598028.host, call_598028.base,
                         call_598028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598028, url, valid)

proc call*(call_598029: Call_CancelIngestion_598015; AwsAccountId: string;
          DataSetId: string; IngestionId: string): Recallable =
  ## cancelIngestion
  ## Cancels an ongoing ingestion of data into SPICE.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   IngestionId: string (required)
  ##              : An ID for the ingestion.
  var path_598030 = newJObject()
  add(path_598030, "AwsAccountId", newJString(AwsAccountId))
  add(path_598030, "DataSetId", newJString(DataSetId))
  add(path_598030, "IngestionId", newJString(IngestionId))
  result = call_598029.call(path_598030, nil, nil, nil, nil)

var cancelIngestion* = Call_CancelIngestion_598015(name: "cancelIngestion",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}",
    validator: validate_CancelIngestion_598016, base: "/", url: url_CancelIngestion_598017,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDashboard_598049 = ref object of OpenApiRestCall_597389
proc url_UpdateDashboard_598051(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDashboard_598050(path: JsonNode; query: JsonNode;
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
  var valid_598052 = path.getOrDefault("AwsAccountId")
  valid_598052 = validateParameter(valid_598052, JString, required = true,
                                 default = nil)
  if valid_598052 != nil:
    section.add "AwsAccountId", valid_598052
  var valid_598053 = path.getOrDefault("DashboardId")
  valid_598053 = validateParameter(valid_598053, JString, required = true,
                                 default = nil)
  if valid_598053 != nil:
    section.add "DashboardId", valid_598053
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
  var valid_598054 = header.getOrDefault("X-Amz-Signature")
  valid_598054 = validateParameter(valid_598054, JString, required = false,
                                 default = nil)
  if valid_598054 != nil:
    section.add "X-Amz-Signature", valid_598054
  var valid_598055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598055 = validateParameter(valid_598055, JString, required = false,
                                 default = nil)
  if valid_598055 != nil:
    section.add "X-Amz-Content-Sha256", valid_598055
  var valid_598056 = header.getOrDefault("X-Amz-Date")
  valid_598056 = validateParameter(valid_598056, JString, required = false,
                                 default = nil)
  if valid_598056 != nil:
    section.add "X-Amz-Date", valid_598056
  var valid_598057 = header.getOrDefault("X-Amz-Credential")
  valid_598057 = validateParameter(valid_598057, JString, required = false,
                                 default = nil)
  if valid_598057 != nil:
    section.add "X-Amz-Credential", valid_598057
  var valid_598058 = header.getOrDefault("X-Amz-Security-Token")
  valid_598058 = validateParameter(valid_598058, JString, required = false,
                                 default = nil)
  if valid_598058 != nil:
    section.add "X-Amz-Security-Token", valid_598058
  var valid_598059 = header.getOrDefault("X-Amz-Algorithm")
  valid_598059 = validateParameter(valid_598059, JString, required = false,
                                 default = nil)
  if valid_598059 != nil:
    section.add "X-Amz-Algorithm", valid_598059
  var valid_598060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598060 = validateParameter(valid_598060, JString, required = false,
                                 default = nil)
  if valid_598060 != nil:
    section.add "X-Amz-SignedHeaders", valid_598060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598062: Call_UpdateDashboard_598049; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a dashboard in an AWS account.
  ## 
  let valid = call_598062.validator(path, query, header, formData, body)
  let scheme = call_598062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598062.url(scheme.get, call_598062.host, call_598062.base,
                         call_598062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598062, url, valid)

proc call*(call_598063: Call_UpdateDashboard_598049; AwsAccountId: string;
          body: JsonNode; DashboardId: string): Recallable =
  ## updateDashboard
  ## Updates a dashboard in an AWS account.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're updating.
  ##   body: JObject (required)
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  var path_598064 = newJObject()
  var body_598065 = newJObject()
  add(path_598064, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_598065 = body
  add(path_598064, "DashboardId", newJString(DashboardId))
  result = call_598063.call(path_598064, nil, nil, nil, body_598065)

var updateDashboard* = Call_UpdateDashboard_598049(name: "updateDashboard",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}",
    validator: validate_UpdateDashboard_598050, base: "/", url: url_UpdateDashboard_598051,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDashboard_598066 = ref object of OpenApiRestCall_597389
proc url_CreateDashboard_598068(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDashboard_598067(path: JsonNode; query: JsonNode;
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
  var valid_598069 = path.getOrDefault("AwsAccountId")
  valid_598069 = validateParameter(valid_598069, JString, required = true,
                                 default = nil)
  if valid_598069 != nil:
    section.add "AwsAccountId", valid_598069
  var valid_598070 = path.getOrDefault("DashboardId")
  valid_598070 = validateParameter(valid_598070, JString, required = true,
                                 default = nil)
  if valid_598070 != nil:
    section.add "DashboardId", valid_598070
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
  var valid_598071 = header.getOrDefault("X-Amz-Signature")
  valid_598071 = validateParameter(valid_598071, JString, required = false,
                                 default = nil)
  if valid_598071 != nil:
    section.add "X-Amz-Signature", valid_598071
  var valid_598072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598072 = validateParameter(valid_598072, JString, required = false,
                                 default = nil)
  if valid_598072 != nil:
    section.add "X-Amz-Content-Sha256", valid_598072
  var valid_598073 = header.getOrDefault("X-Amz-Date")
  valid_598073 = validateParameter(valid_598073, JString, required = false,
                                 default = nil)
  if valid_598073 != nil:
    section.add "X-Amz-Date", valid_598073
  var valid_598074 = header.getOrDefault("X-Amz-Credential")
  valid_598074 = validateParameter(valid_598074, JString, required = false,
                                 default = nil)
  if valid_598074 != nil:
    section.add "X-Amz-Credential", valid_598074
  var valid_598075 = header.getOrDefault("X-Amz-Security-Token")
  valid_598075 = validateParameter(valid_598075, JString, required = false,
                                 default = nil)
  if valid_598075 != nil:
    section.add "X-Amz-Security-Token", valid_598075
  var valid_598076 = header.getOrDefault("X-Amz-Algorithm")
  valid_598076 = validateParameter(valid_598076, JString, required = false,
                                 default = nil)
  if valid_598076 != nil:
    section.add "X-Amz-Algorithm", valid_598076
  var valid_598077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598077 = validateParameter(valid_598077, JString, required = false,
                                 default = nil)
  if valid_598077 != nil:
    section.add "X-Amz-SignedHeaders", valid_598077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598079: Call_CreateDashboard_598066; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a dashboard from a template. To first create a template, see the CreateTemplate API operation.</p> <p>A dashboard is an entity in QuickSight that identifies QuickSight reports, created from analyses. You can share QuickSight dashboards. With the right permissions, you can create scheduled email reports from them. The <code>CreateDashboard</code>, <code>DescribeDashboard</code>, and <code>ListDashboardsByUser</code> API operations act on the dashboard entity. If you have the correct permissions, you can create a dashboard from a template that exists in a different AWS account.</p>
  ## 
  let valid = call_598079.validator(path, query, header, formData, body)
  let scheme = call_598079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598079.url(scheme.get, call_598079.host, call_598079.base,
                         call_598079.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598079, url, valid)

proc call*(call_598080: Call_CreateDashboard_598066; AwsAccountId: string;
          body: JsonNode; DashboardId: string): Recallable =
  ## createDashboard
  ## <p>Creates a dashboard from a template. To first create a template, see the CreateTemplate API operation.</p> <p>A dashboard is an entity in QuickSight that identifies QuickSight reports, created from analyses. You can share QuickSight dashboards. With the right permissions, you can create scheduled email reports from them. The <code>CreateDashboard</code>, <code>DescribeDashboard</code>, and <code>ListDashboardsByUser</code> API operations act on the dashboard entity. If you have the correct permissions, you can create a dashboard from a template that exists in a different AWS account.</p>
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account where you want to create the dashboard.
  ##   body: JObject (required)
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard, also added to the IAM policy.
  var path_598081 = newJObject()
  var body_598082 = newJObject()
  add(path_598081, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_598082 = body
  add(path_598081, "DashboardId", newJString(DashboardId))
  result = call_598080.call(path_598081, nil, nil, nil, body_598082)

var createDashboard* = Call_CreateDashboard_598066(name: "createDashboard",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}",
    validator: validate_CreateDashboard_598067, base: "/", url: url_CreateDashboard_598068,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDashboard_598031 = ref object of OpenApiRestCall_597389
proc url_DescribeDashboard_598033(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDashboard_598032(path: JsonNode; query: JsonNode;
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
  var valid_598034 = path.getOrDefault("AwsAccountId")
  valid_598034 = validateParameter(valid_598034, JString, required = true,
                                 default = nil)
  if valid_598034 != nil:
    section.add "AwsAccountId", valid_598034
  var valid_598035 = path.getOrDefault("DashboardId")
  valid_598035 = validateParameter(valid_598035, JString, required = true,
                                 default = nil)
  if valid_598035 != nil:
    section.add "DashboardId", valid_598035
  result.add "path", section
  ## parameters in `query` object:
  ##   version-number: JInt
  ##                 : The version number for the dashboard. If a version number isn't passed, the latest published dashboard version is described. 
  ##   alias-name: JString
  ##             : The alias name.
  section = newJObject()
  var valid_598036 = query.getOrDefault("version-number")
  valid_598036 = validateParameter(valid_598036, JInt, required = false, default = nil)
  if valid_598036 != nil:
    section.add "version-number", valid_598036
  var valid_598037 = query.getOrDefault("alias-name")
  valid_598037 = validateParameter(valid_598037, JString, required = false,
                                 default = nil)
  if valid_598037 != nil:
    section.add "alias-name", valid_598037
  result.add "query", section
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
  if body != nil:
    result.add "body", body

proc call*(call_598045: Call_DescribeDashboard_598031; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a summary for a dashboard.
  ## 
  let valid = call_598045.validator(path, query, header, formData, body)
  let scheme = call_598045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598045.url(scheme.get, call_598045.host, call_598045.base,
                         call_598045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598045, url, valid)

proc call*(call_598046: Call_DescribeDashboard_598031; AwsAccountId: string;
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
  var path_598047 = newJObject()
  var query_598048 = newJObject()
  add(query_598048, "version-number", newJInt(versionNumber))
  add(path_598047, "AwsAccountId", newJString(AwsAccountId))
  add(query_598048, "alias-name", newJString(aliasName))
  add(path_598047, "DashboardId", newJString(DashboardId))
  result = call_598046.call(path_598047, query_598048, nil, nil, nil)

var describeDashboard* = Call_DescribeDashboard_598031(name: "describeDashboard",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}",
    validator: validate_DescribeDashboard_598032, base: "/",
    url: url_DescribeDashboard_598033, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDashboard_598083 = ref object of OpenApiRestCall_597389
proc url_DeleteDashboard_598085(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDashboard_598084(path: JsonNode; query: JsonNode;
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
  var valid_598086 = path.getOrDefault("AwsAccountId")
  valid_598086 = validateParameter(valid_598086, JString, required = true,
                                 default = nil)
  if valid_598086 != nil:
    section.add "AwsAccountId", valid_598086
  var valid_598087 = path.getOrDefault("DashboardId")
  valid_598087 = validateParameter(valid_598087, JString, required = true,
                                 default = nil)
  if valid_598087 != nil:
    section.add "DashboardId", valid_598087
  result.add "path", section
  ## parameters in `query` object:
  ##   version-number: JInt
  ##                 : The version number of the dashboard. If the version number property is provided, only the specified version of the dashboard is deleted.
  section = newJObject()
  var valid_598088 = query.getOrDefault("version-number")
  valid_598088 = validateParameter(valid_598088, JInt, required = false, default = nil)
  if valid_598088 != nil:
    section.add "version-number", valid_598088
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_598089 = header.getOrDefault("X-Amz-Signature")
  valid_598089 = validateParameter(valid_598089, JString, required = false,
                                 default = nil)
  if valid_598089 != nil:
    section.add "X-Amz-Signature", valid_598089
  var valid_598090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598090 = validateParameter(valid_598090, JString, required = false,
                                 default = nil)
  if valid_598090 != nil:
    section.add "X-Amz-Content-Sha256", valid_598090
  var valid_598091 = header.getOrDefault("X-Amz-Date")
  valid_598091 = validateParameter(valid_598091, JString, required = false,
                                 default = nil)
  if valid_598091 != nil:
    section.add "X-Amz-Date", valid_598091
  var valid_598092 = header.getOrDefault("X-Amz-Credential")
  valid_598092 = validateParameter(valid_598092, JString, required = false,
                                 default = nil)
  if valid_598092 != nil:
    section.add "X-Amz-Credential", valid_598092
  var valid_598093 = header.getOrDefault("X-Amz-Security-Token")
  valid_598093 = validateParameter(valid_598093, JString, required = false,
                                 default = nil)
  if valid_598093 != nil:
    section.add "X-Amz-Security-Token", valid_598093
  var valid_598094 = header.getOrDefault("X-Amz-Algorithm")
  valid_598094 = validateParameter(valid_598094, JString, required = false,
                                 default = nil)
  if valid_598094 != nil:
    section.add "X-Amz-Algorithm", valid_598094
  var valid_598095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598095 = validateParameter(valid_598095, JString, required = false,
                                 default = nil)
  if valid_598095 != nil:
    section.add "X-Amz-SignedHeaders", valid_598095
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598096: Call_DeleteDashboard_598083; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a dashboard.
  ## 
  let valid = call_598096.validator(path, query, header, formData, body)
  let scheme = call_598096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598096.url(scheme.get, call_598096.host, call_598096.base,
                         call_598096.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598096, url, valid)

proc call*(call_598097: Call_DeleteDashboard_598083; AwsAccountId: string;
          DashboardId: string; versionNumber: int = 0): Recallable =
  ## deleteDashboard
  ## Deletes a dashboard.
  ##   versionNumber: int
  ##                : The version number of the dashboard. If the version number property is provided, only the specified version of the dashboard is deleted.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're deleting.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  var path_598098 = newJObject()
  var query_598099 = newJObject()
  add(query_598099, "version-number", newJInt(versionNumber))
  add(path_598098, "AwsAccountId", newJString(AwsAccountId))
  add(path_598098, "DashboardId", newJString(DashboardId))
  result = call_598097.call(path_598098, query_598099, nil, nil, nil)

var deleteDashboard* = Call_DeleteDashboard_598083(name: "deleteDashboard",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}",
    validator: validate_DeleteDashboard_598084, base: "/", url: url_DeleteDashboard_598085,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSet_598119 = ref object of OpenApiRestCall_597389
proc url_CreateDataSet_598121(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDataSet_598120(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598122 = path.getOrDefault("AwsAccountId")
  valid_598122 = validateParameter(valid_598122, JString, required = true,
                                 default = nil)
  if valid_598122 != nil:
    section.add "AwsAccountId", valid_598122
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
  var valid_598123 = header.getOrDefault("X-Amz-Signature")
  valid_598123 = validateParameter(valid_598123, JString, required = false,
                                 default = nil)
  if valid_598123 != nil:
    section.add "X-Amz-Signature", valid_598123
  var valid_598124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598124 = validateParameter(valid_598124, JString, required = false,
                                 default = nil)
  if valid_598124 != nil:
    section.add "X-Amz-Content-Sha256", valid_598124
  var valid_598125 = header.getOrDefault("X-Amz-Date")
  valid_598125 = validateParameter(valid_598125, JString, required = false,
                                 default = nil)
  if valid_598125 != nil:
    section.add "X-Amz-Date", valid_598125
  var valid_598126 = header.getOrDefault("X-Amz-Credential")
  valid_598126 = validateParameter(valid_598126, JString, required = false,
                                 default = nil)
  if valid_598126 != nil:
    section.add "X-Amz-Credential", valid_598126
  var valid_598127 = header.getOrDefault("X-Amz-Security-Token")
  valid_598127 = validateParameter(valid_598127, JString, required = false,
                                 default = nil)
  if valid_598127 != nil:
    section.add "X-Amz-Security-Token", valid_598127
  var valid_598128 = header.getOrDefault("X-Amz-Algorithm")
  valid_598128 = validateParameter(valid_598128, JString, required = false,
                                 default = nil)
  if valid_598128 != nil:
    section.add "X-Amz-Algorithm", valid_598128
  var valid_598129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598129 = validateParameter(valid_598129, JString, required = false,
                                 default = nil)
  if valid_598129 != nil:
    section.add "X-Amz-SignedHeaders", valid_598129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598131: Call_CreateDataSet_598119; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a dataset.
  ## 
  let valid = call_598131.validator(path, query, header, formData, body)
  let scheme = call_598131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598131.url(scheme.get, call_598131.host, call_598131.base,
                         call_598131.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598131, url, valid)

proc call*(call_598132: Call_CreateDataSet_598119; AwsAccountId: string;
          body: JsonNode): Recallable =
  ## createDataSet
  ## Creates a dataset.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   body: JObject (required)
  var path_598133 = newJObject()
  var body_598134 = newJObject()
  add(path_598133, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_598134 = body
  result = call_598132.call(path_598133, nil, nil, nil, body_598134)

var createDataSet* = Call_CreateDataSet_598119(name: "createDataSet",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets",
    validator: validate_CreateDataSet_598120, base: "/", url: url_CreateDataSet_598121,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSets_598100 = ref object of OpenApiRestCall_597389
proc url_ListDataSets_598102(protocol: Scheme; host: string; base: string;
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

proc validate_ListDataSets_598101(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598103 = path.getOrDefault("AwsAccountId")
  valid_598103 = validateParameter(valid_598103, JString, required = true,
                                 default = nil)
  if valid_598103 != nil:
    section.add "AwsAccountId", valid_598103
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
  var valid_598104 = query.getOrDefault("MaxResults")
  valid_598104 = validateParameter(valid_598104, JString, required = false,
                                 default = nil)
  if valid_598104 != nil:
    section.add "MaxResults", valid_598104
  var valid_598105 = query.getOrDefault("NextToken")
  valid_598105 = validateParameter(valid_598105, JString, required = false,
                                 default = nil)
  if valid_598105 != nil:
    section.add "NextToken", valid_598105
  var valid_598106 = query.getOrDefault("max-results")
  valid_598106 = validateParameter(valid_598106, JInt, required = false, default = nil)
  if valid_598106 != nil:
    section.add "max-results", valid_598106
  var valid_598107 = query.getOrDefault("next-token")
  valid_598107 = validateParameter(valid_598107, JString, required = false,
                                 default = nil)
  if valid_598107 != nil:
    section.add "next-token", valid_598107
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_598108 = header.getOrDefault("X-Amz-Signature")
  valid_598108 = validateParameter(valid_598108, JString, required = false,
                                 default = nil)
  if valid_598108 != nil:
    section.add "X-Amz-Signature", valid_598108
  var valid_598109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598109 = validateParameter(valid_598109, JString, required = false,
                                 default = nil)
  if valid_598109 != nil:
    section.add "X-Amz-Content-Sha256", valid_598109
  var valid_598110 = header.getOrDefault("X-Amz-Date")
  valid_598110 = validateParameter(valid_598110, JString, required = false,
                                 default = nil)
  if valid_598110 != nil:
    section.add "X-Amz-Date", valid_598110
  var valid_598111 = header.getOrDefault("X-Amz-Credential")
  valid_598111 = validateParameter(valid_598111, JString, required = false,
                                 default = nil)
  if valid_598111 != nil:
    section.add "X-Amz-Credential", valid_598111
  var valid_598112 = header.getOrDefault("X-Amz-Security-Token")
  valid_598112 = validateParameter(valid_598112, JString, required = false,
                                 default = nil)
  if valid_598112 != nil:
    section.add "X-Amz-Security-Token", valid_598112
  var valid_598113 = header.getOrDefault("X-Amz-Algorithm")
  valid_598113 = validateParameter(valid_598113, JString, required = false,
                                 default = nil)
  if valid_598113 != nil:
    section.add "X-Amz-Algorithm", valid_598113
  var valid_598114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598114 = validateParameter(valid_598114, JString, required = false,
                                 default = nil)
  if valid_598114 != nil:
    section.add "X-Amz-SignedHeaders", valid_598114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598115: Call_ListDataSets_598100; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all of the datasets belonging to the current AWS account in an AWS Region.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/*</code>.</p>
  ## 
  let valid = call_598115.validator(path, query, header, formData, body)
  let scheme = call_598115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598115.url(scheme.get, call_598115.host, call_598115.base,
                         call_598115.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598115, url, valid)

proc call*(call_598116: Call_ListDataSets_598100; AwsAccountId: string;
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
  var path_598117 = newJObject()
  var query_598118 = newJObject()
  add(path_598117, "AwsAccountId", newJString(AwsAccountId))
  add(query_598118, "MaxResults", newJString(MaxResults))
  add(query_598118, "NextToken", newJString(NextToken))
  add(query_598118, "max-results", newJInt(maxResults))
  add(query_598118, "next-token", newJString(nextToken))
  result = call_598116.call(path_598117, query_598118, nil, nil, nil)

var listDataSets* = Call_ListDataSets_598100(name: "listDataSets",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets", validator: validate_ListDataSets_598101,
    base: "/", url: url_ListDataSets_598102, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSource_598154 = ref object of OpenApiRestCall_597389
proc url_CreateDataSource_598156(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDataSource_598155(path: JsonNode; query: JsonNode;
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
  var valid_598157 = path.getOrDefault("AwsAccountId")
  valid_598157 = validateParameter(valid_598157, JString, required = true,
                                 default = nil)
  if valid_598157 != nil:
    section.add "AwsAccountId", valid_598157
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
  var valid_598158 = header.getOrDefault("X-Amz-Signature")
  valid_598158 = validateParameter(valid_598158, JString, required = false,
                                 default = nil)
  if valid_598158 != nil:
    section.add "X-Amz-Signature", valid_598158
  var valid_598159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598159 = validateParameter(valid_598159, JString, required = false,
                                 default = nil)
  if valid_598159 != nil:
    section.add "X-Amz-Content-Sha256", valid_598159
  var valid_598160 = header.getOrDefault("X-Amz-Date")
  valid_598160 = validateParameter(valid_598160, JString, required = false,
                                 default = nil)
  if valid_598160 != nil:
    section.add "X-Amz-Date", valid_598160
  var valid_598161 = header.getOrDefault("X-Amz-Credential")
  valid_598161 = validateParameter(valid_598161, JString, required = false,
                                 default = nil)
  if valid_598161 != nil:
    section.add "X-Amz-Credential", valid_598161
  var valid_598162 = header.getOrDefault("X-Amz-Security-Token")
  valid_598162 = validateParameter(valid_598162, JString, required = false,
                                 default = nil)
  if valid_598162 != nil:
    section.add "X-Amz-Security-Token", valid_598162
  var valid_598163 = header.getOrDefault("X-Amz-Algorithm")
  valid_598163 = validateParameter(valid_598163, JString, required = false,
                                 default = nil)
  if valid_598163 != nil:
    section.add "X-Amz-Algorithm", valid_598163
  var valid_598164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598164 = validateParameter(valid_598164, JString, required = false,
                                 default = nil)
  if valid_598164 != nil:
    section.add "X-Amz-SignedHeaders", valid_598164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598166: Call_CreateDataSource_598154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a data source.
  ## 
  let valid = call_598166.validator(path, query, header, formData, body)
  let scheme = call_598166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598166.url(scheme.get, call_598166.host, call_598166.base,
                         call_598166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598166, url, valid)

proc call*(call_598167: Call_CreateDataSource_598154; AwsAccountId: string;
          body: JsonNode): Recallable =
  ## createDataSource
  ## Creates a data source.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   body: JObject (required)
  var path_598168 = newJObject()
  var body_598169 = newJObject()
  add(path_598168, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_598169 = body
  result = call_598167.call(path_598168, nil, nil, nil, body_598169)

var createDataSource* = Call_CreateDataSource_598154(name: "createDataSource",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources",
    validator: validate_CreateDataSource_598155, base: "/",
    url: url_CreateDataSource_598156, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSources_598135 = ref object of OpenApiRestCall_597389
proc url_ListDataSources_598137(protocol: Scheme; host: string; base: string;
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

proc validate_ListDataSources_598136(path: JsonNode; query: JsonNode;
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
  var valid_598138 = path.getOrDefault("AwsAccountId")
  valid_598138 = validateParameter(valid_598138, JString, required = true,
                                 default = nil)
  if valid_598138 != nil:
    section.add "AwsAccountId", valid_598138
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
  var valid_598139 = query.getOrDefault("MaxResults")
  valid_598139 = validateParameter(valid_598139, JString, required = false,
                                 default = nil)
  if valid_598139 != nil:
    section.add "MaxResults", valid_598139
  var valid_598140 = query.getOrDefault("NextToken")
  valid_598140 = validateParameter(valid_598140, JString, required = false,
                                 default = nil)
  if valid_598140 != nil:
    section.add "NextToken", valid_598140
  var valid_598141 = query.getOrDefault("max-results")
  valid_598141 = validateParameter(valid_598141, JInt, required = false, default = nil)
  if valid_598141 != nil:
    section.add "max-results", valid_598141
  var valid_598142 = query.getOrDefault("next-token")
  valid_598142 = validateParameter(valid_598142, JString, required = false,
                                 default = nil)
  if valid_598142 != nil:
    section.add "next-token", valid_598142
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_598143 = header.getOrDefault("X-Amz-Signature")
  valid_598143 = validateParameter(valid_598143, JString, required = false,
                                 default = nil)
  if valid_598143 != nil:
    section.add "X-Amz-Signature", valid_598143
  var valid_598144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598144 = validateParameter(valid_598144, JString, required = false,
                                 default = nil)
  if valid_598144 != nil:
    section.add "X-Amz-Content-Sha256", valid_598144
  var valid_598145 = header.getOrDefault("X-Amz-Date")
  valid_598145 = validateParameter(valid_598145, JString, required = false,
                                 default = nil)
  if valid_598145 != nil:
    section.add "X-Amz-Date", valid_598145
  var valid_598146 = header.getOrDefault("X-Amz-Credential")
  valid_598146 = validateParameter(valid_598146, JString, required = false,
                                 default = nil)
  if valid_598146 != nil:
    section.add "X-Amz-Credential", valid_598146
  var valid_598147 = header.getOrDefault("X-Amz-Security-Token")
  valid_598147 = validateParameter(valid_598147, JString, required = false,
                                 default = nil)
  if valid_598147 != nil:
    section.add "X-Amz-Security-Token", valid_598147
  var valid_598148 = header.getOrDefault("X-Amz-Algorithm")
  valid_598148 = validateParameter(valid_598148, JString, required = false,
                                 default = nil)
  if valid_598148 != nil:
    section.add "X-Amz-Algorithm", valid_598148
  var valid_598149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598149 = validateParameter(valid_598149, JString, required = false,
                                 default = nil)
  if valid_598149 != nil:
    section.add "X-Amz-SignedHeaders", valid_598149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598150: Call_ListDataSources_598135; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists data sources in current AWS Region that belong to this AWS account.
  ## 
  let valid = call_598150.validator(path, query, header, formData, body)
  let scheme = call_598150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598150.url(scheme.get, call_598150.host, call_598150.base,
                         call_598150.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598150, url, valid)

proc call*(call_598151: Call_ListDataSources_598135; AwsAccountId: string;
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
  var path_598152 = newJObject()
  var query_598153 = newJObject()
  add(path_598152, "AwsAccountId", newJString(AwsAccountId))
  add(query_598153, "MaxResults", newJString(MaxResults))
  add(query_598153, "NextToken", newJString(NextToken))
  add(query_598153, "max-results", newJInt(maxResults))
  add(query_598153, "next-token", newJString(nextToken))
  result = call_598151.call(path_598152, query_598153, nil, nil, nil)

var listDataSources* = Call_ListDataSources_598135(name: "listDataSources",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources",
    validator: validate_ListDataSources_598136, base: "/", url: url_ListDataSources_598137,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroup_598188 = ref object of OpenApiRestCall_597389
proc url_CreateGroup_598190(protocol: Scheme; host: string; base: string;
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

proc validate_CreateGroup_598189(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598191 = path.getOrDefault("AwsAccountId")
  valid_598191 = validateParameter(valid_598191, JString, required = true,
                                 default = nil)
  if valid_598191 != nil:
    section.add "AwsAccountId", valid_598191
  var valid_598192 = path.getOrDefault("Namespace")
  valid_598192 = validateParameter(valid_598192, JString, required = true,
                                 default = nil)
  if valid_598192 != nil:
    section.add "Namespace", valid_598192
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
  var valid_598193 = header.getOrDefault("X-Amz-Signature")
  valid_598193 = validateParameter(valid_598193, JString, required = false,
                                 default = nil)
  if valid_598193 != nil:
    section.add "X-Amz-Signature", valid_598193
  var valid_598194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598194 = validateParameter(valid_598194, JString, required = false,
                                 default = nil)
  if valid_598194 != nil:
    section.add "X-Amz-Content-Sha256", valid_598194
  var valid_598195 = header.getOrDefault("X-Amz-Date")
  valid_598195 = validateParameter(valid_598195, JString, required = false,
                                 default = nil)
  if valid_598195 != nil:
    section.add "X-Amz-Date", valid_598195
  var valid_598196 = header.getOrDefault("X-Amz-Credential")
  valid_598196 = validateParameter(valid_598196, JString, required = false,
                                 default = nil)
  if valid_598196 != nil:
    section.add "X-Amz-Credential", valid_598196
  var valid_598197 = header.getOrDefault("X-Amz-Security-Token")
  valid_598197 = validateParameter(valid_598197, JString, required = false,
                                 default = nil)
  if valid_598197 != nil:
    section.add "X-Amz-Security-Token", valid_598197
  var valid_598198 = header.getOrDefault("X-Amz-Algorithm")
  valid_598198 = validateParameter(valid_598198, JString, required = false,
                                 default = nil)
  if valid_598198 != nil:
    section.add "X-Amz-Algorithm", valid_598198
  var valid_598199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598199 = validateParameter(valid_598199, JString, required = false,
                                 default = nil)
  if valid_598199 != nil:
    section.add "X-Amz-SignedHeaders", valid_598199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598201: Call_CreateGroup_598188; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon QuickSight group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;relevant-aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a group object.</p>
  ## 
  let valid = call_598201.validator(path, query, header, formData, body)
  let scheme = call_598201.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598201.url(scheme.get, call_598201.host, call_598201.base,
                         call_598201.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598201, url, valid)

proc call*(call_598202: Call_CreateGroup_598188; AwsAccountId: string;
          Namespace: string; body: JsonNode): Recallable =
  ## createGroup
  ## <p>Creates an Amazon QuickSight group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;relevant-aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a group object.</p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   body: JObject (required)
  var path_598203 = newJObject()
  var body_598204 = newJObject()
  add(path_598203, "AwsAccountId", newJString(AwsAccountId))
  add(path_598203, "Namespace", newJString(Namespace))
  if body != nil:
    body_598204 = body
  result = call_598202.call(path_598203, nil, nil, nil, body_598204)

var createGroup* = Call_CreateGroup_598188(name: "createGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups",
                                        validator: validate_CreateGroup_598189,
                                        base: "/", url: url_CreateGroup_598190,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_598170 = ref object of OpenApiRestCall_597389
proc url_ListGroups_598172(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListGroups_598171(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598173 = path.getOrDefault("AwsAccountId")
  valid_598173 = validateParameter(valid_598173, JString, required = true,
                                 default = nil)
  if valid_598173 != nil:
    section.add "AwsAccountId", valid_598173
  var valid_598174 = path.getOrDefault("Namespace")
  valid_598174 = validateParameter(valid_598174, JString, required = true,
                                 default = nil)
  if valid_598174 != nil:
    section.add "Namespace", valid_598174
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_598175 = query.getOrDefault("max-results")
  valid_598175 = validateParameter(valid_598175, JInt, required = false, default = nil)
  if valid_598175 != nil:
    section.add "max-results", valid_598175
  var valid_598176 = query.getOrDefault("next-token")
  valid_598176 = validateParameter(valid_598176, JString, required = false,
                                 default = nil)
  if valid_598176 != nil:
    section.add "next-token", valid_598176
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_598177 = header.getOrDefault("X-Amz-Signature")
  valid_598177 = validateParameter(valid_598177, JString, required = false,
                                 default = nil)
  if valid_598177 != nil:
    section.add "X-Amz-Signature", valid_598177
  var valid_598178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598178 = validateParameter(valid_598178, JString, required = false,
                                 default = nil)
  if valid_598178 != nil:
    section.add "X-Amz-Content-Sha256", valid_598178
  var valid_598179 = header.getOrDefault("X-Amz-Date")
  valid_598179 = validateParameter(valid_598179, JString, required = false,
                                 default = nil)
  if valid_598179 != nil:
    section.add "X-Amz-Date", valid_598179
  var valid_598180 = header.getOrDefault("X-Amz-Credential")
  valid_598180 = validateParameter(valid_598180, JString, required = false,
                                 default = nil)
  if valid_598180 != nil:
    section.add "X-Amz-Credential", valid_598180
  var valid_598181 = header.getOrDefault("X-Amz-Security-Token")
  valid_598181 = validateParameter(valid_598181, JString, required = false,
                                 default = nil)
  if valid_598181 != nil:
    section.add "X-Amz-Security-Token", valid_598181
  var valid_598182 = header.getOrDefault("X-Amz-Algorithm")
  valid_598182 = validateParameter(valid_598182, JString, required = false,
                                 default = nil)
  if valid_598182 != nil:
    section.add "X-Amz-Algorithm", valid_598182
  var valid_598183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598183 = validateParameter(valid_598183, JString, required = false,
                                 default = nil)
  if valid_598183 != nil:
    section.add "X-Amz-SignedHeaders", valid_598183
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598184: Call_ListGroups_598170; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all user groups in Amazon QuickSight. 
  ## 
  let valid = call_598184.validator(path, query, header, formData, body)
  let scheme = call_598184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598184.url(scheme.get, call_598184.host, call_598184.base,
                         call_598184.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598184, url, valid)

proc call*(call_598185: Call_ListGroups_598170; AwsAccountId: string;
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
  var path_598186 = newJObject()
  var query_598187 = newJObject()
  add(path_598186, "AwsAccountId", newJString(AwsAccountId))
  add(path_598186, "Namespace", newJString(Namespace))
  add(query_598187, "max-results", newJInt(maxResults))
  add(query_598187, "next-token", newJString(nextToken))
  result = call_598185.call(path_598186, query_598187, nil, nil, nil)

var listGroups* = Call_ListGroups_598170(name: "listGroups",
                                      meth: HttpMethod.HttpGet,
                                      host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups",
                                      validator: validate_ListGroups_598171,
                                      base: "/", url: url_ListGroups_598172,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroupMembership_598205 = ref object of OpenApiRestCall_597389
proc url_CreateGroupMembership_598207(protocol: Scheme; host: string; base: string;
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

proc validate_CreateGroupMembership_598206(path: JsonNode; query: JsonNode;
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
  var valid_598208 = path.getOrDefault("GroupName")
  valid_598208 = validateParameter(valid_598208, JString, required = true,
                                 default = nil)
  if valid_598208 != nil:
    section.add "GroupName", valid_598208
  var valid_598209 = path.getOrDefault("AwsAccountId")
  valid_598209 = validateParameter(valid_598209, JString, required = true,
                                 default = nil)
  if valid_598209 != nil:
    section.add "AwsAccountId", valid_598209
  var valid_598210 = path.getOrDefault("Namespace")
  valid_598210 = validateParameter(valid_598210, JString, required = true,
                                 default = nil)
  if valid_598210 != nil:
    section.add "Namespace", valid_598210
  var valid_598211 = path.getOrDefault("MemberName")
  valid_598211 = validateParameter(valid_598211, JString, required = true,
                                 default = nil)
  if valid_598211 != nil:
    section.add "MemberName", valid_598211
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
  var valid_598212 = header.getOrDefault("X-Amz-Signature")
  valid_598212 = validateParameter(valid_598212, JString, required = false,
                                 default = nil)
  if valid_598212 != nil:
    section.add "X-Amz-Signature", valid_598212
  var valid_598213 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598213 = validateParameter(valid_598213, JString, required = false,
                                 default = nil)
  if valid_598213 != nil:
    section.add "X-Amz-Content-Sha256", valid_598213
  var valid_598214 = header.getOrDefault("X-Amz-Date")
  valid_598214 = validateParameter(valid_598214, JString, required = false,
                                 default = nil)
  if valid_598214 != nil:
    section.add "X-Amz-Date", valid_598214
  var valid_598215 = header.getOrDefault("X-Amz-Credential")
  valid_598215 = validateParameter(valid_598215, JString, required = false,
                                 default = nil)
  if valid_598215 != nil:
    section.add "X-Amz-Credential", valid_598215
  var valid_598216 = header.getOrDefault("X-Amz-Security-Token")
  valid_598216 = validateParameter(valid_598216, JString, required = false,
                                 default = nil)
  if valid_598216 != nil:
    section.add "X-Amz-Security-Token", valid_598216
  var valid_598217 = header.getOrDefault("X-Amz-Algorithm")
  valid_598217 = validateParameter(valid_598217, JString, required = false,
                                 default = nil)
  if valid_598217 != nil:
    section.add "X-Amz-Algorithm", valid_598217
  var valid_598218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598218 = validateParameter(valid_598218, JString, required = false,
                                 default = nil)
  if valid_598218 != nil:
    section.add "X-Amz-SignedHeaders", valid_598218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598219: Call_CreateGroupMembership_598205; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds an Amazon QuickSight user to an Amazon QuickSight group. 
  ## 
  let valid = call_598219.validator(path, query, header, formData, body)
  let scheme = call_598219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598219.url(scheme.get, call_598219.host, call_598219.base,
                         call_598219.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598219, url, valid)

proc call*(call_598220: Call_CreateGroupMembership_598205; GroupName: string;
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
  var path_598221 = newJObject()
  add(path_598221, "GroupName", newJString(GroupName))
  add(path_598221, "AwsAccountId", newJString(AwsAccountId))
  add(path_598221, "Namespace", newJString(Namespace))
  add(path_598221, "MemberName", newJString(MemberName))
  result = call_598220.call(path_598221, nil, nil, nil, nil)

var createGroupMembership* = Call_CreateGroupMembership_598205(
    name: "createGroupMembership", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members/{MemberName}",
    validator: validate_CreateGroupMembership_598206, base: "/",
    url: url_CreateGroupMembership_598207, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroupMembership_598222 = ref object of OpenApiRestCall_597389
proc url_DeleteGroupMembership_598224(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGroupMembership_598223(path: JsonNode; query: JsonNode;
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
  var valid_598225 = path.getOrDefault("GroupName")
  valid_598225 = validateParameter(valid_598225, JString, required = true,
                                 default = nil)
  if valid_598225 != nil:
    section.add "GroupName", valid_598225
  var valid_598226 = path.getOrDefault("AwsAccountId")
  valid_598226 = validateParameter(valid_598226, JString, required = true,
                                 default = nil)
  if valid_598226 != nil:
    section.add "AwsAccountId", valid_598226
  var valid_598227 = path.getOrDefault("Namespace")
  valid_598227 = validateParameter(valid_598227, JString, required = true,
                                 default = nil)
  if valid_598227 != nil:
    section.add "Namespace", valid_598227
  var valid_598228 = path.getOrDefault("MemberName")
  valid_598228 = validateParameter(valid_598228, JString, required = true,
                                 default = nil)
  if valid_598228 != nil:
    section.add "MemberName", valid_598228
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
  var valid_598229 = header.getOrDefault("X-Amz-Signature")
  valid_598229 = validateParameter(valid_598229, JString, required = false,
                                 default = nil)
  if valid_598229 != nil:
    section.add "X-Amz-Signature", valid_598229
  var valid_598230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598230 = validateParameter(valid_598230, JString, required = false,
                                 default = nil)
  if valid_598230 != nil:
    section.add "X-Amz-Content-Sha256", valid_598230
  var valid_598231 = header.getOrDefault("X-Amz-Date")
  valid_598231 = validateParameter(valid_598231, JString, required = false,
                                 default = nil)
  if valid_598231 != nil:
    section.add "X-Amz-Date", valid_598231
  var valid_598232 = header.getOrDefault("X-Amz-Credential")
  valid_598232 = validateParameter(valid_598232, JString, required = false,
                                 default = nil)
  if valid_598232 != nil:
    section.add "X-Amz-Credential", valid_598232
  var valid_598233 = header.getOrDefault("X-Amz-Security-Token")
  valid_598233 = validateParameter(valid_598233, JString, required = false,
                                 default = nil)
  if valid_598233 != nil:
    section.add "X-Amz-Security-Token", valid_598233
  var valid_598234 = header.getOrDefault("X-Amz-Algorithm")
  valid_598234 = validateParameter(valid_598234, JString, required = false,
                                 default = nil)
  if valid_598234 != nil:
    section.add "X-Amz-Algorithm", valid_598234
  var valid_598235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598235 = validateParameter(valid_598235, JString, required = false,
                                 default = nil)
  if valid_598235 != nil:
    section.add "X-Amz-SignedHeaders", valid_598235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598236: Call_DeleteGroupMembership_598222; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a user from a group so that the user is no longer a member of the group.
  ## 
  let valid = call_598236.validator(path, query, header, formData, body)
  let scheme = call_598236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598236.url(scheme.get, call_598236.host, call_598236.base,
                         call_598236.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598236, url, valid)

proc call*(call_598237: Call_DeleteGroupMembership_598222; GroupName: string;
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
  var path_598238 = newJObject()
  add(path_598238, "GroupName", newJString(GroupName))
  add(path_598238, "AwsAccountId", newJString(AwsAccountId))
  add(path_598238, "Namespace", newJString(Namespace))
  add(path_598238, "MemberName", newJString(MemberName))
  result = call_598237.call(path_598238, nil, nil, nil, nil)

var deleteGroupMembership* = Call_DeleteGroupMembership_598222(
    name: "deleteGroupMembership", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members/{MemberName}",
    validator: validate_DeleteGroupMembership_598223, base: "/",
    url: url_DeleteGroupMembership_598224, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIAMPolicyAssignment_598239 = ref object of OpenApiRestCall_597389
proc url_CreateIAMPolicyAssignment_598241(protocol: Scheme; host: string;
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

proc validate_CreateIAMPolicyAssignment_598240(path: JsonNode; query: JsonNode;
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
  var valid_598242 = path.getOrDefault("AwsAccountId")
  valid_598242 = validateParameter(valid_598242, JString, required = true,
                                 default = nil)
  if valid_598242 != nil:
    section.add "AwsAccountId", valid_598242
  var valid_598243 = path.getOrDefault("Namespace")
  valid_598243 = validateParameter(valid_598243, JString, required = true,
                                 default = nil)
  if valid_598243 != nil:
    section.add "Namespace", valid_598243
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
  var valid_598244 = header.getOrDefault("X-Amz-Signature")
  valid_598244 = validateParameter(valid_598244, JString, required = false,
                                 default = nil)
  if valid_598244 != nil:
    section.add "X-Amz-Signature", valid_598244
  var valid_598245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598245 = validateParameter(valid_598245, JString, required = false,
                                 default = nil)
  if valid_598245 != nil:
    section.add "X-Amz-Content-Sha256", valid_598245
  var valid_598246 = header.getOrDefault("X-Amz-Date")
  valid_598246 = validateParameter(valid_598246, JString, required = false,
                                 default = nil)
  if valid_598246 != nil:
    section.add "X-Amz-Date", valid_598246
  var valid_598247 = header.getOrDefault("X-Amz-Credential")
  valid_598247 = validateParameter(valid_598247, JString, required = false,
                                 default = nil)
  if valid_598247 != nil:
    section.add "X-Amz-Credential", valid_598247
  var valid_598248 = header.getOrDefault("X-Amz-Security-Token")
  valid_598248 = validateParameter(valid_598248, JString, required = false,
                                 default = nil)
  if valid_598248 != nil:
    section.add "X-Amz-Security-Token", valid_598248
  var valid_598249 = header.getOrDefault("X-Amz-Algorithm")
  valid_598249 = validateParameter(valid_598249, JString, required = false,
                                 default = nil)
  if valid_598249 != nil:
    section.add "X-Amz-Algorithm", valid_598249
  var valid_598250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598250 = validateParameter(valid_598250, JString, required = false,
                                 default = nil)
  if valid_598250 != nil:
    section.add "X-Amz-SignedHeaders", valid_598250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598252: Call_CreateIAMPolicyAssignment_598239; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an assignment with one specified IAM policy, identified by its Amazon Resource Name (ARN). This policy will be assigned to specified groups or users of Amazon QuickSight. The users and groups need to be in the same namespace. 
  ## 
  let valid = call_598252.validator(path, query, header, formData, body)
  let scheme = call_598252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598252.url(scheme.get, call_598252.host, call_598252.base,
                         call_598252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598252, url, valid)

proc call*(call_598253: Call_CreateIAMPolicyAssignment_598239;
          AwsAccountId: string; Namespace: string; body: JsonNode): Recallable =
  ## createIAMPolicyAssignment
  ## Creates an assignment with one specified IAM policy, identified by its Amazon Resource Name (ARN). This policy will be assigned to specified groups or users of Amazon QuickSight. The users and groups need to be in the same namespace. 
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account where you want to assign an IAM policy to QuickSight users or groups.
  ##   Namespace: string (required)
  ##            : The namespace that contains the assignment.
  ##   body: JObject (required)
  var path_598254 = newJObject()
  var body_598255 = newJObject()
  add(path_598254, "AwsAccountId", newJString(AwsAccountId))
  add(path_598254, "Namespace", newJString(Namespace))
  if body != nil:
    body_598255 = body
  result = call_598253.call(path_598254, nil, nil, nil, body_598255)

var createIAMPolicyAssignment* = Call_CreateIAMPolicyAssignment_598239(
    name: "createIAMPolicyAssignment", meth: HttpMethod.HttpPost,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/",
    validator: validate_CreateIAMPolicyAssignment_598240, base: "/",
    url: url_CreateIAMPolicyAssignment_598241,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTemplate_598274 = ref object of OpenApiRestCall_597389
proc url_UpdateTemplate_598276(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateTemplate_598275(path: JsonNode; query: JsonNode;
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
  var valid_598277 = path.getOrDefault("AwsAccountId")
  valid_598277 = validateParameter(valid_598277, JString, required = true,
                                 default = nil)
  if valid_598277 != nil:
    section.add "AwsAccountId", valid_598277
  var valid_598278 = path.getOrDefault("TemplateId")
  valid_598278 = validateParameter(valid_598278, JString, required = true,
                                 default = nil)
  if valid_598278 != nil:
    section.add "TemplateId", valid_598278
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
  var valid_598279 = header.getOrDefault("X-Amz-Signature")
  valid_598279 = validateParameter(valid_598279, JString, required = false,
                                 default = nil)
  if valid_598279 != nil:
    section.add "X-Amz-Signature", valid_598279
  var valid_598280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598280 = validateParameter(valid_598280, JString, required = false,
                                 default = nil)
  if valid_598280 != nil:
    section.add "X-Amz-Content-Sha256", valid_598280
  var valid_598281 = header.getOrDefault("X-Amz-Date")
  valid_598281 = validateParameter(valid_598281, JString, required = false,
                                 default = nil)
  if valid_598281 != nil:
    section.add "X-Amz-Date", valid_598281
  var valid_598282 = header.getOrDefault("X-Amz-Credential")
  valid_598282 = validateParameter(valid_598282, JString, required = false,
                                 default = nil)
  if valid_598282 != nil:
    section.add "X-Amz-Credential", valid_598282
  var valid_598283 = header.getOrDefault("X-Amz-Security-Token")
  valid_598283 = validateParameter(valid_598283, JString, required = false,
                                 default = nil)
  if valid_598283 != nil:
    section.add "X-Amz-Security-Token", valid_598283
  var valid_598284 = header.getOrDefault("X-Amz-Algorithm")
  valid_598284 = validateParameter(valid_598284, JString, required = false,
                                 default = nil)
  if valid_598284 != nil:
    section.add "X-Amz-Algorithm", valid_598284
  var valid_598285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598285 = validateParameter(valid_598285, JString, required = false,
                                 default = nil)
  if valid_598285 != nil:
    section.add "X-Amz-SignedHeaders", valid_598285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598287: Call_UpdateTemplate_598274; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a template from an existing Amazon QuickSight analysis or another template.
  ## 
  let valid = call_598287.validator(path, query, header, formData, body)
  let scheme = call_598287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598287.url(scheme.get, call_598287.host, call_598287.base,
                         call_598287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598287, url, valid)

proc call*(call_598288: Call_UpdateTemplate_598274; AwsAccountId: string;
          TemplateId: string; body: JsonNode): Recallable =
  ## updateTemplate
  ## Updates a template from an existing Amazon QuickSight analysis or another template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template that you're updating.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  ##   body: JObject (required)
  var path_598289 = newJObject()
  var body_598290 = newJObject()
  add(path_598289, "AwsAccountId", newJString(AwsAccountId))
  add(path_598289, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_598290 = body
  result = call_598288.call(path_598289, nil, nil, nil, body_598290)

var updateTemplate* = Call_UpdateTemplate_598274(name: "updateTemplate",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}",
    validator: validate_UpdateTemplate_598275, base: "/", url: url_UpdateTemplate_598276,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTemplate_598291 = ref object of OpenApiRestCall_597389
proc url_CreateTemplate_598293(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTemplate_598292(path: JsonNode; query: JsonNode;
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
  var valid_598294 = path.getOrDefault("AwsAccountId")
  valid_598294 = validateParameter(valid_598294, JString, required = true,
                                 default = nil)
  if valid_598294 != nil:
    section.add "AwsAccountId", valid_598294
  var valid_598295 = path.getOrDefault("TemplateId")
  valid_598295 = validateParameter(valid_598295, JString, required = true,
                                 default = nil)
  if valid_598295 != nil:
    section.add "TemplateId", valid_598295
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
  var valid_598296 = header.getOrDefault("X-Amz-Signature")
  valid_598296 = validateParameter(valid_598296, JString, required = false,
                                 default = nil)
  if valid_598296 != nil:
    section.add "X-Amz-Signature", valid_598296
  var valid_598297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598297 = validateParameter(valid_598297, JString, required = false,
                                 default = nil)
  if valid_598297 != nil:
    section.add "X-Amz-Content-Sha256", valid_598297
  var valid_598298 = header.getOrDefault("X-Amz-Date")
  valid_598298 = validateParameter(valid_598298, JString, required = false,
                                 default = nil)
  if valid_598298 != nil:
    section.add "X-Amz-Date", valid_598298
  var valid_598299 = header.getOrDefault("X-Amz-Credential")
  valid_598299 = validateParameter(valid_598299, JString, required = false,
                                 default = nil)
  if valid_598299 != nil:
    section.add "X-Amz-Credential", valid_598299
  var valid_598300 = header.getOrDefault("X-Amz-Security-Token")
  valid_598300 = validateParameter(valid_598300, JString, required = false,
                                 default = nil)
  if valid_598300 != nil:
    section.add "X-Amz-Security-Token", valid_598300
  var valid_598301 = header.getOrDefault("X-Amz-Algorithm")
  valid_598301 = validateParameter(valid_598301, JString, required = false,
                                 default = nil)
  if valid_598301 != nil:
    section.add "X-Amz-Algorithm", valid_598301
  var valid_598302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598302 = validateParameter(valid_598302, JString, required = false,
                                 default = nil)
  if valid_598302 != nil:
    section.add "X-Amz-SignedHeaders", valid_598302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598304: Call_CreateTemplate_598291; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a template from an existing QuickSight analysis or template. You can use the resulting template to create a dashboard.</p> <p>A <i>template</i> is an entity in QuickSight that encapsulates the metadata required to create an analysis and that you can use to create s dashboard. A template adds a layer of abstraction by using placeholders to replace the dataset associated with the analysis. You can use templates to create dashboards by replacing dataset placeholders with datasets that follow the same schema that was used to create the source analysis and template.</p>
  ## 
  let valid = call_598304.validator(path, query, header, formData, body)
  let scheme = call_598304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598304.url(scheme.get, call_598304.host, call_598304.base,
                         call_598304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598304, url, valid)

proc call*(call_598305: Call_CreateTemplate_598291; AwsAccountId: string;
          TemplateId: string; body: JsonNode): Recallable =
  ## createTemplate
  ## <p>Creates a template from an existing QuickSight analysis or template. You can use the resulting template to create a dashboard.</p> <p>A <i>template</i> is an entity in QuickSight that encapsulates the metadata required to create an analysis and that you can use to create s dashboard. A template adds a layer of abstraction by using placeholders to replace the dataset associated with the analysis. You can use templates to create dashboards by replacing dataset placeholders with datasets that follow the same schema that was used to create the source analysis and template.</p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   TemplateId: string (required)
  ##             : An ID for the template that you want to create. This template is unique per AWS Region in each AWS account.
  ##   body: JObject (required)
  var path_598306 = newJObject()
  var body_598307 = newJObject()
  add(path_598306, "AwsAccountId", newJString(AwsAccountId))
  add(path_598306, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_598307 = body
  result = call_598305.call(path_598306, nil, nil, nil, body_598307)

var createTemplate* = Call_CreateTemplate_598291(name: "createTemplate",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}",
    validator: validate_CreateTemplate_598292, base: "/", url: url_CreateTemplate_598293,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTemplate_598256 = ref object of OpenApiRestCall_597389
proc url_DescribeTemplate_598258(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTemplate_598257(path: JsonNode; query: JsonNode;
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
  var valid_598259 = path.getOrDefault("AwsAccountId")
  valid_598259 = validateParameter(valid_598259, JString, required = true,
                                 default = nil)
  if valid_598259 != nil:
    section.add "AwsAccountId", valid_598259
  var valid_598260 = path.getOrDefault("TemplateId")
  valid_598260 = validateParameter(valid_598260, JString, required = true,
                                 default = nil)
  if valid_598260 != nil:
    section.add "TemplateId", valid_598260
  result.add "path", section
  ## parameters in `query` object:
  ##   version-number: JInt
  ##                 : (Optional) The number for the version to describe. If a <code>VersionNumber</code> parameter value isn't provided, the latest version of the template is described.
  ##   alias-name: JString
  ##             : The alias of the template that you want to describe. If you name a specific alias, you describe the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. The keyword <code>$PUBLISHED</code> doesn't apply to templates.
  section = newJObject()
  var valid_598261 = query.getOrDefault("version-number")
  valid_598261 = validateParameter(valid_598261, JInt, required = false, default = nil)
  if valid_598261 != nil:
    section.add "version-number", valid_598261
  var valid_598262 = query.getOrDefault("alias-name")
  valid_598262 = validateParameter(valid_598262, JString, required = false,
                                 default = nil)
  if valid_598262 != nil:
    section.add "alias-name", valid_598262
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_598263 = header.getOrDefault("X-Amz-Signature")
  valid_598263 = validateParameter(valid_598263, JString, required = false,
                                 default = nil)
  if valid_598263 != nil:
    section.add "X-Amz-Signature", valid_598263
  var valid_598264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598264 = validateParameter(valid_598264, JString, required = false,
                                 default = nil)
  if valid_598264 != nil:
    section.add "X-Amz-Content-Sha256", valid_598264
  var valid_598265 = header.getOrDefault("X-Amz-Date")
  valid_598265 = validateParameter(valid_598265, JString, required = false,
                                 default = nil)
  if valid_598265 != nil:
    section.add "X-Amz-Date", valid_598265
  var valid_598266 = header.getOrDefault("X-Amz-Credential")
  valid_598266 = validateParameter(valid_598266, JString, required = false,
                                 default = nil)
  if valid_598266 != nil:
    section.add "X-Amz-Credential", valid_598266
  var valid_598267 = header.getOrDefault("X-Amz-Security-Token")
  valid_598267 = validateParameter(valid_598267, JString, required = false,
                                 default = nil)
  if valid_598267 != nil:
    section.add "X-Amz-Security-Token", valid_598267
  var valid_598268 = header.getOrDefault("X-Amz-Algorithm")
  valid_598268 = validateParameter(valid_598268, JString, required = false,
                                 default = nil)
  if valid_598268 != nil:
    section.add "X-Amz-Algorithm", valid_598268
  var valid_598269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598269 = validateParameter(valid_598269, JString, required = false,
                                 default = nil)
  if valid_598269 != nil:
    section.add "X-Amz-SignedHeaders", valid_598269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598270: Call_DescribeTemplate_598256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a template's metadata.
  ## 
  let valid = call_598270.validator(path, query, header, formData, body)
  let scheme = call_598270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598270.url(scheme.get, call_598270.host, call_598270.base,
                         call_598270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598270, url, valid)

proc call*(call_598271: Call_DescribeTemplate_598256; AwsAccountId: string;
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
  var path_598272 = newJObject()
  var query_598273 = newJObject()
  add(query_598273, "version-number", newJInt(versionNumber))
  add(path_598272, "AwsAccountId", newJString(AwsAccountId))
  add(query_598273, "alias-name", newJString(aliasName))
  add(path_598272, "TemplateId", newJString(TemplateId))
  result = call_598271.call(path_598272, query_598273, nil, nil, nil)

var describeTemplate* = Call_DescribeTemplate_598256(name: "describeTemplate",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}",
    validator: validate_DescribeTemplate_598257, base: "/",
    url: url_DescribeTemplate_598258, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTemplate_598308 = ref object of OpenApiRestCall_597389
proc url_DeleteTemplate_598310(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTemplate_598309(path: JsonNode; query: JsonNode;
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
  var valid_598311 = path.getOrDefault("AwsAccountId")
  valid_598311 = validateParameter(valid_598311, JString, required = true,
                                 default = nil)
  if valid_598311 != nil:
    section.add "AwsAccountId", valid_598311
  var valid_598312 = path.getOrDefault("TemplateId")
  valid_598312 = validateParameter(valid_598312, JString, required = true,
                                 default = nil)
  if valid_598312 != nil:
    section.add "TemplateId", valid_598312
  result.add "path", section
  ## parameters in `query` object:
  ##   version-number: JInt
  ##                 : Specifies the version of the template that you want to delete. If you don't provide a version number, <code>DeleteTemplate</code> deletes all versions of the template. 
  section = newJObject()
  var valid_598313 = query.getOrDefault("version-number")
  valid_598313 = validateParameter(valid_598313, JInt, required = false, default = nil)
  if valid_598313 != nil:
    section.add "version-number", valid_598313
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_598314 = header.getOrDefault("X-Amz-Signature")
  valid_598314 = validateParameter(valid_598314, JString, required = false,
                                 default = nil)
  if valid_598314 != nil:
    section.add "X-Amz-Signature", valid_598314
  var valid_598315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598315 = validateParameter(valid_598315, JString, required = false,
                                 default = nil)
  if valid_598315 != nil:
    section.add "X-Amz-Content-Sha256", valid_598315
  var valid_598316 = header.getOrDefault("X-Amz-Date")
  valid_598316 = validateParameter(valid_598316, JString, required = false,
                                 default = nil)
  if valid_598316 != nil:
    section.add "X-Amz-Date", valid_598316
  var valid_598317 = header.getOrDefault("X-Amz-Credential")
  valid_598317 = validateParameter(valid_598317, JString, required = false,
                                 default = nil)
  if valid_598317 != nil:
    section.add "X-Amz-Credential", valid_598317
  var valid_598318 = header.getOrDefault("X-Amz-Security-Token")
  valid_598318 = validateParameter(valid_598318, JString, required = false,
                                 default = nil)
  if valid_598318 != nil:
    section.add "X-Amz-Security-Token", valid_598318
  var valid_598319 = header.getOrDefault("X-Amz-Algorithm")
  valid_598319 = validateParameter(valid_598319, JString, required = false,
                                 default = nil)
  if valid_598319 != nil:
    section.add "X-Amz-Algorithm", valid_598319
  var valid_598320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598320 = validateParameter(valid_598320, JString, required = false,
                                 default = nil)
  if valid_598320 != nil:
    section.add "X-Amz-SignedHeaders", valid_598320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598321: Call_DeleteTemplate_598308; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a template.
  ## 
  let valid = call_598321.validator(path, query, header, formData, body)
  let scheme = call_598321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598321.url(scheme.get, call_598321.host, call_598321.base,
                         call_598321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598321, url, valid)

proc call*(call_598322: Call_DeleteTemplate_598308; AwsAccountId: string;
          TemplateId: string; versionNumber: int = 0): Recallable =
  ## deleteTemplate
  ## Deletes a template.
  ##   versionNumber: int
  ##                : Specifies the version of the template that you want to delete. If you don't provide a version number, <code>DeleteTemplate</code> deletes all versions of the template. 
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template that you're deleting.
  ##   TemplateId: string (required)
  ##             : An ID for the template you want to delete.
  var path_598323 = newJObject()
  var query_598324 = newJObject()
  add(query_598324, "version-number", newJInt(versionNumber))
  add(path_598323, "AwsAccountId", newJString(AwsAccountId))
  add(path_598323, "TemplateId", newJString(TemplateId))
  result = call_598322.call(path_598323, query_598324, nil, nil, nil)

var deleteTemplate* = Call_DeleteTemplate_598308(name: "deleteTemplate",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}",
    validator: validate_DeleteTemplate_598309, base: "/", url: url_DeleteTemplate_598310,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTemplateAlias_598341 = ref object of OpenApiRestCall_597389
proc url_UpdateTemplateAlias_598343(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateTemplateAlias_598342(path: JsonNode; query: JsonNode;
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
  var valid_598344 = path.getOrDefault("AwsAccountId")
  valid_598344 = validateParameter(valid_598344, JString, required = true,
                                 default = nil)
  if valid_598344 != nil:
    section.add "AwsAccountId", valid_598344
  var valid_598345 = path.getOrDefault("AliasName")
  valid_598345 = validateParameter(valid_598345, JString, required = true,
                                 default = nil)
  if valid_598345 != nil:
    section.add "AliasName", valid_598345
  var valid_598346 = path.getOrDefault("TemplateId")
  valid_598346 = validateParameter(valid_598346, JString, required = true,
                                 default = nil)
  if valid_598346 != nil:
    section.add "TemplateId", valid_598346
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
  var valid_598347 = header.getOrDefault("X-Amz-Signature")
  valid_598347 = validateParameter(valid_598347, JString, required = false,
                                 default = nil)
  if valid_598347 != nil:
    section.add "X-Amz-Signature", valid_598347
  var valid_598348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598348 = validateParameter(valid_598348, JString, required = false,
                                 default = nil)
  if valid_598348 != nil:
    section.add "X-Amz-Content-Sha256", valid_598348
  var valid_598349 = header.getOrDefault("X-Amz-Date")
  valid_598349 = validateParameter(valid_598349, JString, required = false,
                                 default = nil)
  if valid_598349 != nil:
    section.add "X-Amz-Date", valid_598349
  var valid_598350 = header.getOrDefault("X-Amz-Credential")
  valid_598350 = validateParameter(valid_598350, JString, required = false,
                                 default = nil)
  if valid_598350 != nil:
    section.add "X-Amz-Credential", valid_598350
  var valid_598351 = header.getOrDefault("X-Amz-Security-Token")
  valid_598351 = validateParameter(valid_598351, JString, required = false,
                                 default = nil)
  if valid_598351 != nil:
    section.add "X-Amz-Security-Token", valid_598351
  var valid_598352 = header.getOrDefault("X-Amz-Algorithm")
  valid_598352 = validateParameter(valid_598352, JString, required = false,
                                 default = nil)
  if valid_598352 != nil:
    section.add "X-Amz-Algorithm", valid_598352
  var valid_598353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598353 = validateParameter(valid_598353, JString, required = false,
                                 default = nil)
  if valid_598353 != nil:
    section.add "X-Amz-SignedHeaders", valid_598353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598355: Call_UpdateTemplateAlias_598341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the template alias of a template.
  ## 
  let valid = call_598355.validator(path, query, header, formData, body)
  let scheme = call_598355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598355.url(scheme.get, call_598355.host, call_598355.base,
                         call_598355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598355, url, valid)

proc call*(call_598356: Call_UpdateTemplateAlias_598341; AwsAccountId: string;
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
  var path_598357 = newJObject()
  var body_598358 = newJObject()
  add(path_598357, "AwsAccountId", newJString(AwsAccountId))
  add(path_598357, "AliasName", newJString(AliasName))
  add(path_598357, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_598358 = body
  result = call_598356.call(path_598357, nil, nil, nil, body_598358)

var updateTemplateAlias* = Call_UpdateTemplateAlias_598341(
    name: "updateTemplateAlias", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}",
    validator: validate_UpdateTemplateAlias_598342, base: "/",
    url: url_UpdateTemplateAlias_598343, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTemplateAlias_598359 = ref object of OpenApiRestCall_597389
proc url_CreateTemplateAlias_598361(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTemplateAlias_598360(path: JsonNode; query: JsonNode;
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
  var valid_598362 = path.getOrDefault("AwsAccountId")
  valid_598362 = validateParameter(valid_598362, JString, required = true,
                                 default = nil)
  if valid_598362 != nil:
    section.add "AwsAccountId", valid_598362
  var valid_598363 = path.getOrDefault("AliasName")
  valid_598363 = validateParameter(valid_598363, JString, required = true,
                                 default = nil)
  if valid_598363 != nil:
    section.add "AliasName", valid_598363
  var valid_598364 = path.getOrDefault("TemplateId")
  valid_598364 = validateParameter(valid_598364, JString, required = true,
                                 default = nil)
  if valid_598364 != nil:
    section.add "TemplateId", valid_598364
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
  var valid_598365 = header.getOrDefault("X-Amz-Signature")
  valid_598365 = validateParameter(valid_598365, JString, required = false,
                                 default = nil)
  if valid_598365 != nil:
    section.add "X-Amz-Signature", valid_598365
  var valid_598366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598366 = validateParameter(valid_598366, JString, required = false,
                                 default = nil)
  if valid_598366 != nil:
    section.add "X-Amz-Content-Sha256", valid_598366
  var valid_598367 = header.getOrDefault("X-Amz-Date")
  valid_598367 = validateParameter(valid_598367, JString, required = false,
                                 default = nil)
  if valid_598367 != nil:
    section.add "X-Amz-Date", valid_598367
  var valid_598368 = header.getOrDefault("X-Amz-Credential")
  valid_598368 = validateParameter(valid_598368, JString, required = false,
                                 default = nil)
  if valid_598368 != nil:
    section.add "X-Amz-Credential", valid_598368
  var valid_598369 = header.getOrDefault("X-Amz-Security-Token")
  valid_598369 = validateParameter(valid_598369, JString, required = false,
                                 default = nil)
  if valid_598369 != nil:
    section.add "X-Amz-Security-Token", valid_598369
  var valid_598370 = header.getOrDefault("X-Amz-Algorithm")
  valid_598370 = validateParameter(valid_598370, JString, required = false,
                                 default = nil)
  if valid_598370 != nil:
    section.add "X-Amz-Algorithm", valid_598370
  var valid_598371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598371 = validateParameter(valid_598371, JString, required = false,
                                 default = nil)
  if valid_598371 != nil:
    section.add "X-Amz-SignedHeaders", valid_598371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598373: Call_CreateTemplateAlias_598359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a template alias for a template.
  ## 
  let valid = call_598373.validator(path, query, header, formData, body)
  let scheme = call_598373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598373.url(scheme.get, call_598373.host, call_598373.base,
                         call_598373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598373, url, valid)

proc call*(call_598374: Call_CreateTemplateAlias_598359; AwsAccountId: string;
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
  var path_598375 = newJObject()
  var body_598376 = newJObject()
  add(path_598375, "AwsAccountId", newJString(AwsAccountId))
  add(path_598375, "AliasName", newJString(AliasName))
  add(path_598375, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_598376 = body
  result = call_598374.call(path_598375, nil, nil, nil, body_598376)

var createTemplateAlias* = Call_CreateTemplateAlias_598359(
    name: "createTemplateAlias", meth: HttpMethod.HttpPost,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}",
    validator: validate_CreateTemplateAlias_598360, base: "/",
    url: url_CreateTemplateAlias_598361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTemplateAlias_598325 = ref object of OpenApiRestCall_597389
proc url_DescribeTemplateAlias_598327(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTemplateAlias_598326(path: JsonNode; query: JsonNode;
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
  var valid_598328 = path.getOrDefault("AwsAccountId")
  valid_598328 = validateParameter(valid_598328, JString, required = true,
                                 default = nil)
  if valid_598328 != nil:
    section.add "AwsAccountId", valid_598328
  var valid_598329 = path.getOrDefault("AliasName")
  valid_598329 = validateParameter(valid_598329, JString, required = true,
                                 default = nil)
  if valid_598329 != nil:
    section.add "AliasName", valid_598329
  var valid_598330 = path.getOrDefault("TemplateId")
  valid_598330 = validateParameter(valid_598330, JString, required = true,
                                 default = nil)
  if valid_598330 != nil:
    section.add "TemplateId", valid_598330
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
  var valid_598331 = header.getOrDefault("X-Amz-Signature")
  valid_598331 = validateParameter(valid_598331, JString, required = false,
                                 default = nil)
  if valid_598331 != nil:
    section.add "X-Amz-Signature", valid_598331
  var valid_598332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598332 = validateParameter(valid_598332, JString, required = false,
                                 default = nil)
  if valid_598332 != nil:
    section.add "X-Amz-Content-Sha256", valid_598332
  var valid_598333 = header.getOrDefault("X-Amz-Date")
  valid_598333 = validateParameter(valid_598333, JString, required = false,
                                 default = nil)
  if valid_598333 != nil:
    section.add "X-Amz-Date", valid_598333
  var valid_598334 = header.getOrDefault("X-Amz-Credential")
  valid_598334 = validateParameter(valid_598334, JString, required = false,
                                 default = nil)
  if valid_598334 != nil:
    section.add "X-Amz-Credential", valid_598334
  var valid_598335 = header.getOrDefault("X-Amz-Security-Token")
  valid_598335 = validateParameter(valid_598335, JString, required = false,
                                 default = nil)
  if valid_598335 != nil:
    section.add "X-Amz-Security-Token", valid_598335
  var valid_598336 = header.getOrDefault("X-Amz-Algorithm")
  valid_598336 = validateParameter(valid_598336, JString, required = false,
                                 default = nil)
  if valid_598336 != nil:
    section.add "X-Amz-Algorithm", valid_598336
  var valid_598337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598337 = validateParameter(valid_598337, JString, required = false,
                                 default = nil)
  if valid_598337 != nil:
    section.add "X-Amz-SignedHeaders", valid_598337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598338: Call_DescribeTemplateAlias_598325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the template alias for a template.
  ## 
  let valid = call_598338.validator(path, query, header, formData, body)
  let scheme = call_598338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598338.url(scheme.get, call_598338.host, call_598338.base,
                         call_598338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598338, url, valid)

proc call*(call_598339: Call_DescribeTemplateAlias_598325; AwsAccountId: string;
          AliasName: string; TemplateId: string): Recallable =
  ## describeTemplateAlias
  ## Describes the template alias for a template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template alias that you're describing.
  ##   AliasName: string (required)
  ##            : The name of the template alias that you want to describe. If you name a specific alias, you describe the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. The keyword <code>$PUBLISHED</code> doesn't apply to templates.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  var path_598340 = newJObject()
  add(path_598340, "AwsAccountId", newJString(AwsAccountId))
  add(path_598340, "AliasName", newJString(AliasName))
  add(path_598340, "TemplateId", newJString(TemplateId))
  result = call_598339.call(path_598340, nil, nil, nil, nil)

var describeTemplateAlias* = Call_DescribeTemplateAlias_598325(
    name: "describeTemplateAlias", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}",
    validator: validate_DescribeTemplateAlias_598326, base: "/",
    url: url_DescribeTemplateAlias_598327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTemplateAlias_598377 = ref object of OpenApiRestCall_597389
proc url_DeleteTemplateAlias_598379(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTemplateAlias_598378(path: JsonNode; query: JsonNode;
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
  var valid_598380 = path.getOrDefault("AwsAccountId")
  valid_598380 = validateParameter(valid_598380, JString, required = true,
                                 default = nil)
  if valid_598380 != nil:
    section.add "AwsAccountId", valid_598380
  var valid_598381 = path.getOrDefault("AliasName")
  valid_598381 = validateParameter(valid_598381, JString, required = true,
                                 default = nil)
  if valid_598381 != nil:
    section.add "AliasName", valid_598381
  var valid_598382 = path.getOrDefault("TemplateId")
  valid_598382 = validateParameter(valid_598382, JString, required = true,
                                 default = nil)
  if valid_598382 != nil:
    section.add "TemplateId", valid_598382
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
  var valid_598383 = header.getOrDefault("X-Amz-Signature")
  valid_598383 = validateParameter(valid_598383, JString, required = false,
                                 default = nil)
  if valid_598383 != nil:
    section.add "X-Amz-Signature", valid_598383
  var valid_598384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598384 = validateParameter(valid_598384, JString, required = false,
                                 default = nil)
  if valid_598384 != nil:
    section.add "X-Amz-Content-Sha256", valid_598384
  var valid_598385 = header.getOrDefault("X-Amz-Date")
  valid_598385 = validateParameter(valid_598385, JString, required = false,
                                 default = nil)
  if valid_598385 != nil:
    section.add "X-Amz-Date", valid_598385
  var valid_598386 = header.getOrDefault("X-Amz-Credential")
  valid_598386 = validateParameter(valid_598386, JString, required = false,
                                 default = nil)
  if valid_598386 != nil:
    section.add "X-Amz-Credential", valid_598386
  var valid_598387 = header.getOrDefault("X-Amz-Security-Token")
  valid_598387 = validateParameter(valid_598387, JString, required = false,
                                 default = nil)
  if valid_598387 != nil:
    section.add "X-Amz-Security-Token", valid_598387
  var valid_598388 = header.getOrDefault("X-Amz-Algorithm")
  valid_598388 = validateParameter(valid_598388, JString, required = false,
                                 default = nil)
  if valid_598388 != nil:
    section.add "X-Amz-Algorithm", valid_598388
  var valid_598389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598389 = validateParameter(valid_598389, JString, required = false,
                                 default = nil)
  if valid_598389 != nil:
    section.add "X-Amz-SignedHeaders", valid_598389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598390: Call_DeleteTemplateAlias_598377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the item that the specified template alias points to. If you provide a specific alias, you delete the version of the template that the alias points to.
  ## 
  let valid = call_598390.validator(path, query, header, formData, body)
  let scheme = call_598390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598390.url(scheme.get, call_598390.host, call_598390.base,
                         call_598390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598390, url, valid)

proc call*(call_598391: Call_DeleteTemplateAlias_598377; AwsAccountId: string;
          AliasName: string; TemplateId: string): Recallable =
  ## deleteTemplateAlias
  ## Deletes the item that the specified template alias points to. If you provide a specific alias, you delete the version of the template that the alias points to.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the item to delete.
  ##   AliasName: string (required)
  ##            : The name for the template alias. If you name a specific alias, you delete the version that the alias points to. You can specify the latest version of the template by providing the keyword <code>$LATEST</code> in the <code>AliasName</code> parameter. 
  ##   TemplateId: string (required)
  ##             : The ID for the template that the specified alias is for.
  var path_598392 = newJObject()
  add(path_598392, "AwsAccountId", newJString(AwsAccountId))
  add(path_598392, "AliasName", newJString(AliasName))
  add(path_598392, "TemplateId", newJString(TemplateId))
  result = call_598391.call(path_598392, nil, nil, nil, nil)

var deleteTemplateAlias* = Call_DeleteTemplateAlias_598377(
    name: "deleteTemplateAlias", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}",
    validator: validate_DeleteTemplateAlias_598378, base: "/",
    url: url_DeleteTemplateAlias_598379, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSet_598408 = ref object of OpenApiRestCall_597389
proc url_UpdateDataSet_598410(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDataSet_598409(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598411 = path.getOrDefault("AwsAccountId")
  valid_598411 = validateParameter(valid_598411, JString, required = true,
                                 default = nil)
  if valid_598411 != nil:
    section.add "AwsAccountId", valid_598411
  var valid_598412 = path.getOrDefault("DataSetId")
  valid_598412 = validateParameter(valid_598412, JString, required = true,
                                 default = nil)
  if valid_598412 != nil:
    section.add "DataSetId", valid_598412
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
  var valid_598413 = header.getOrDefault("X-Amz-Signature")
  valid_598413 = validateParameter(valid_598413, JString, required = false,
                                 default = nil)
  if valid_598413 != nil:
    section.add "X-Amz-Signature", valid_598413
  var valid_598414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598414 = validateParameter(valid_598414, JString, required = false,
                                 default = nil)
  if valid_598414 != nil:
    section.add "X-Amz-Content-Sha256", valid_598414
  var valid_598415 = header.getOrDefault("X-Amz-Date")
  valid_598415 = validateParameter(valid_598415, JString, required = false,
                                 default = nil)
  if valid_598415 != nil:
    section.add "X-Amz-Date", valid_598415
  var valid_598416 = header.getOrDefault("X-Amz-Credential")
  valid_598416 = validateParameter(valid_598416, JString, required = false,
                                 default = nil)
  if valid_598416 != nil:
    section.add "X-Amz-Credential", valid_598416
  var valid_598417 = header.getOrDefault("X-Amz-Security-Token")
  valid_598417 = validateParameter(valid_598417, JString, required = false,
                                 default = nil)
  if valid_598417 != nil:
    section.add "X-Amz-Security-Token", valid_598417
  var valid_598418 = header.getOrDefault("X-Amz-Algorithm")
  valid_598418 = validateParameter(valid_598418, JString, required = false,
                                 default = nil)
  if valid_598418 != nil:
    section.add "X-Amz-Algorithm", valid_598418
  var valid_598419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598419 = validateParameter(valid_598419, JString, required = false,
                                 default = nil)
  if valid_598419 != nil:
    section.add "X-Amz-SignedHeaders", valid_598419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598421: Call_UpdateDataSet_598408; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a dataset.
  ## 
  let valid = call_598421.validator(path, query, header, formData, body)
  let scheme = call_598421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598421.url(scheme.get, call_598421.host, call_598421.base,
                         call_598421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598421, url, valid)

proc call*(call_598422: Call_UpdateDataSet_598408; AwsAccountId: string;
          DataSetId: string; body: JsonNode): Recallable =
  ## updateDataSet
  ## Updates a dataset.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset that you want to update. This ID is unique per AWS Region for each AWS account.
  ##   body: JObject (required)
  var path_598423 = newJObject()
  var body_598424 = newJObject()
  add(path_598423, "AwsAccountId", newJString(AwsAccountId))
  add(path_598423, "DataSetId", newJString(DataSetId))
  if body != nil:
    body_598424 = body
  result = call_598422.call(path_598423, nil, nil, nil, body_598424)

var updateDataSet* = Call_UpdateDataSet_598408(name: "updateDataSet",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}",
    validator: validate_UpdateDataSet_598409, base: "/", url: url_UpdateDataSet_598410,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSet_598393 = ref object of OpenApiRestCall_597389
proc url_DescribeDataSet_598395(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDataSet_598394(path: JsonNode; query: JsonNode;
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
  var valid_598396 = path.getOrDefault("AwsAccountId")
  valid_598396 = validateParameter(valid_598396, JString, required = true,
                                 default = nil)
  if valid_598396 != nil:
    section.add "AwsAccountId", valid_598396
  var valid_598397 = path.getOrDefault("DataSetId")
  valid_598397 = validateParameter(valid_598397, JString, required = true,
                                 default = nil)
  if valid_598397 != nil:
    section.add "DataSetId", valid_598397
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
  var valid_598398 = header.getOrDefault("X-Amz-Signature")
  valid_598398 = validateParameter(valid_598398, JString, required = false,
                                 default = nil)
  if valid_598398 != nil:
    section.add "X-Amz-Signature", valid_598398
  var valid_598399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598399 = validateParameter(valid_598399, JString, required = false,
                                 default = nil)
  if valid_598399 != nil:
    section.add "X-Amz-Content-Sha256", valid_598399
  var valid_598400 = header.getOrDefault("X-Amz-Date")
  valid_598400 = validateParameter(valid_598400, JString, required = false,
                                 default = nil)
  if valid_598400 != nil:
    section.add "X-Amz-Date", valid_598400
  var valid_598401 = header.getOrDefault("X-Amz-Credential")
  valid_598401 = validateParameter(valid_598401, JString, required = false,
                                 default = nil)
  if valid_598401 != nil:
    section.add "X-Amz-Credential", valid_598401
  var valid_598402 = header.getOrDefault("X-Amz-Security-Token")
  valid_598402 = validateParameter(valid_598402, JString, required = false,
                                 default = nil)
  if valid_598402 != nil:
    section.add "X-Amz-Security-Token", valid_598402
  var valid_598403 = header.getOrDefault("X-Amz-Algorithm")
  valid_598403 = validateParameter(valid_598403, JString, required = false,
                                 default = nil)
  if valid_598403 != nil:
    section.add "X-Amz-Algorithm", valid_598403
  var valid_598404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598404 = validateParameter(valid_598404, JString, required = false,
                                 default = nil)
  if valid_598404 != nil:
    section.add "X-Amz-SignedHeaders", valid_598404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598405: Call_DescribeDataSet_598393; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a dataset. 
  ## 
  let valid = call_598405.validator(path, query, header, formData, body)
  let scheme = call_598405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598405.url(scheme.get, call_598405.host, call_598405.base,
                         call_598405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598405, url, valid)

proc call*(call_598406: Call_DescribeDataSet_598393; AwsAccountId: string;
          DataSetId: string): Recallable =
  ## describeDataSet
  ## Describes a dataset. 
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset that you want to create. This ID is unique per AWS Region for each AWS account.
  var path_598407 = newJObject()
  add(path_598407, "AwsAccountId", newJString(AwsAccountId))
  add(path_598407, "DataSetId", newJString(DataSetId))
  result = call_598406.call(path_598407, nil, nil, nil, nil)

var describeDataSet* = Call_DescribeDataSet_598393(name: "describeDataSet",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}",
    validator: validate_DescribeDataSet_598394, base: "/", url: url_DescribeDataSet_598395,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSet_598425 = ref object of OpenApiRestCall_597389
proc url_DeleteDataSet_598427(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDataSet_598426(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598428 = path.getOrDefault("AwsAccountId")
  valid_598428 = validateParameter(valid_598428, JString, required = true,
                                 default = nil)
  if valid_598428 != nil:
    section.add "AwsAccountId", valid_598428
  var valid_598429 = path.getOrDefault("DataSetId")
  valid_598429 = validateParameter(valid_598429, JString, required = true,
                                 default = nil)
  if valid_598429 != nil:
    section.add "DataSetId", valid_598429
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
  var valid_598430 = header.getOrDefault("X-Amz-Signature")
  valid_598430 = validateParameter(valid_598430, JString, required = false,
                                 default = nil)
  if valid_598430 != nil:
    section.add "X-Amz-Signature", valid_598430
  var valid_598431 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598431 = validateParameter(valid_598431, JString, required = false,
                                 default = nil)
  if valid_598431 != nil:
    section.add "X-Amz-Content-Sha256", valid_598431
  var valid_598432 = header.getOrDefault("X-Amz-Date")
  valid_598432 = validateParameter(valid_598432, JString, required = false,
                                 default = nil)
  if valid_598432 != nil:
    section.add "X-Amz-Date", valid_598432
  var valid_598433 = header.getOrDefault("X-Amz-Credential")
  valid_598433 = validateParameter(valid_598433, JString, required = false,
                                 default = nil)
  if valid_598433 != nil:
    section.add "X-Amz-Credential", valid_598433
  var valid_598434 = header.getOrDefault("X-Amz-Security-Token")
  valid_598434 = validateParameter(valid_598434, JString, required = false,
                                 default = nil)
  if valid_598434 != nil:
    section.add "X-Amz-Security-Token", valid_598434
  var valid_598435 = header.getOrDefault("X-Amz-Algorithm")
  valid_598435 = validateParameter(valid_598435, JString, required = false,
                                 default = nil)
  if valid_598435 != nil:
    section.add "X-Amz-Algorithm", valid_598435
  var valid_598436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598436 = validateParameter(valid_598436, JString, required = false,
                                 default = nil)
  if valid_598436 != nil:
    section.add "X-Amz-SignedHeaders", valid_598436
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598437: Call_DeleteDataSet_598425; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a dataset.
  ## 
  let valid = call_598437.validator(path, query, header, formData, body)
  let scheme = call_598437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598437.url(scheme.get, call_598437.host, call_598437.base,
                         call_598437.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598437, url, valid)

proc call*(call_598438: Call_DeleteDataSet_598425; AwsAccountId: string;
          DataSetId: string): Recallable =
  ## deleteDataSet
  ## Deletes a dataset.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset that you want to create. This ID is unique per AWS Region for each AWS account.
  var path_598439 = newJObject()
  add(path_598439, "AwsAccountId", newJString(AwsAccountId))
  add(path_598439, "DataSetId", newJString(DataSetId))
  result = call_598438.call(path_598439, nil, nil, nil, nil)

var deleteDataSet* = Call_DeleteDataSet_598425(name: "deleteDataSet",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}",
    validator: validate_DeleteDataSet_598426, base: "/", url: url_DeleteDataSet_598427,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSource_598455 = ref object of OpenApiRestCall_597389
proc url_UpdateDataSource_598457(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDataSource_598456(path: JsonNode; query: JsonNode;
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
  var valid_598458 = path.getOrDefault("DataSourceId")
  valid_598458 = validateParameter(valid_598458, JString, required = true,
                                 default = nil)
  if valid_598458 != nil:
    section.add "DataSourceId", valid_598458
  var valid_598459 = path.getOrDefault("AwsAccountId")
  valid_598459 = validateParameter(valid_598459, JString, required = true,
                                 default = nil)
  if valid_598459 != nil:
    section.add "AwsAccountId", valid_598459
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
  var valid_598460 = header.getOrDefault("X-Amz-Signature")
  valid_598460 = validateParameter(valid_598460, JString, required = false,
                                 default = nil)
  if valid_598460 != nil:
    section.add "X-Amz-Signature", valid_598460
  var valid_598461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598461 = validateParameter(valid_598461, JString, required = false,
                                 default = nil)
  if valid_598461 != nil:
    section.add "X-Amz-Content-Sha256", valid_598461
  var valid_598462 = header.getOrDefault("X-Amz-Date")
  valid_598462 = validateParameter(valid_598462, JString, required = false,
                                 default = nil)
  if valid_598462 != nil:
    section.add "X-Amz-Date", valid_598462
  var valid_598463 = header.getOrDefault("X-Amz-Credential")
  valid_598463 = validateParameter(valid_598463, JString, required = false,
                                 default = nil)
  if valid_598463 != nil:
    section.add "X-Amz-Credential", valid_598463
  var valid_598464 = header.getOrDefault("X-Amz-Security-Token")
  valid_598464 = validateParameter(valid_598464, JString, required = false,
                                 default = nil)
  if valid_598464 != nil:
    section.add "X-Amz-Security-Token", valid_598464
  var valid_598465 = header.getOrDefault("X-Amz-Algorithm")
  valid_598465 = validateParameter(valid_598465, JString, required = false,
                                 default = nil)
  if valid_598465 != nil:
    section.add "X-Amz-Algorithm", valid_598465
  var valid_598466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598466 = validateParameter(valid_598466, JString, required = false,
                                 default = nil)
  if valid_598466 != nil:
    section.add "X-Amz-SignedHeaders", valid_598466
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598468: Call_UpdateDataSource_598455; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a data source.
  ## 
  let valid = call_598468.validator(path, query, header, formData, body)
  let scheme = call_598468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598468.url(scheme.get, call_598468.host, call_598468.base,
                         call_598468.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598468, url, valid)

proc call*(call_598469: Call_UpdateDataSource_598455; DataSourceId: string;
          AwsAccountId: string; body: JsonNode): Recallable =
  ## updateDataSource
  ## Updates a data source.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account. 
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   body: JObject (required)
  var path_598470 = newJObject()
  var body_598471 = newJObject()
  add(path_598470, "DataSourceId", newJString(DataSourceId))
  add(path_598470, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_598471 = body
  result = call_598469.call(path_598470, nil, nil, nil, body_598471)

var updateDataSource* = Call_UpdateDataSource_598455(name: "updateDataSource",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}",
    validator: validate_UpdateDataSource_598456, base: "/",
    url: url_UpdateDataSource_598457, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSource_598440 = ref object of OpenApiRestCall_597389
proc url_DescribeDataSource_598442(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDataSource_598441(path: JsonNode; query: JsonNode;
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
  var valid_598443 = path.getOrDefault("DataSourceId")
  valid_598443 = validateParameter(valid_598443, JString, required = true,
                                 default = nil)
  if valid_598443 != nil:
    section.add "DataSourceId", valid_598443
  var valid_598444 = path.getOrDefault("AwsAccountId")
  valid_598444 = validateParameter(valid_598444, JString, required = true,
                                 default = nil)
  if valid_598444 != nil:
    section.add "AwsAccountId", valid_598444
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
  var valid_598445 = header.getOrDefault("X-Amz-Signature")
  valid_598445 = validateParameter(valid_598445, JString, required = false,
                                 default = nil)
  if valid_598445 != nil:
    section.add "X-Amz-Signature", valid_598445
  var valid_598446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598446 = validateParameter(valid_598446, JString, required = false,
                                 default = nil)
  if valid_598446 != nil:
    section.add "X-Amz-Content-Sha256", valid_598446
  var valid_598447 = header.getOrDefault("X-Amz-Date")
  valid_598447 = validateParameter(valid_598447, JString, required = false,
                                 default = nil)
  if valid_598447 != nil:
    section.add "X-Amz-Date", valid_598447
  var valid_598448 = header.getOrDefault("X-Amz-Credential")
  valid_598448 = validateParameter(valid_598448, JString, required = false,
                                 default = nil)
  if valid_598448 != nil:
    section.add "X-Amz-Credential", valid_598448
  var valid_598449 = header.getOrDefault("X-Amz-Security-Token")
  valid_598449 = validateParameter(valid_598449, JString, required = false,
                                 default = nil)
  if valid_598449 != nil:
    section.add "X-Amz-Security-Token", valid_598449
  var valid_598450 = header.getOrDefault("X-Amz-Algorithm")
  valid_598450 = validateParameter(valid_598450, JString, required = false,
                                 default = nil)
  if valid_598450 != nil:
    section.add "X-Amz-Algorithm", valid_598450
  var valid_598451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598451 = validateParameter(valid_598451, JString, required = false,
                                 default = nil)
  if valid_598451 != nil:
    section.add "X-Amz-SignedHeaders", valid_598451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598452: Call_DescribeDataSource_598440; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a data source.
  ## 
  let valid = call_598452.validator(path, query, header, formData, body)
  let scheme = call_598452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598452.url(scheme.get, call_598452.host, call_598452.base,
                         call_598452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598452, url, valid)

proc call*(call_598453: Call_DescribeDataSource_598440; DataSourceId: string;
          AwsAccountId: string): Recallable =
  ## describeDataSource
  ## Describes a data source.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  var path_598454 = newJObject()
  add(path_598454, "DataSourceId", newJString(DataSourceId))
  add(path_598454, "AwsAccountId", newJString(AwsAccountId))
  result = call_598453.call(path_598454, nil, nil, nil, nil)

var describeDataSource* = Call_DescribeDataSource_598440(
    name: "describeDataSource", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}",
    validator: validate_DescribeDataSource_598441, base: "/",
    url: url_DescribeDataSource_598442, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSource_598472 = ref object of OpenApiRestCall_597389
proc url_DeleteDataSource_598474(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDataSource_598473(path: JsonNode; query: JsonNode;
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
  var valid_598475 = path.getOrDefault("DataSourceId")
  valid_598475 = validateParameter(valid_598475, JString, required = true,
                                 default = nil)
  if valid_598475 != nil:
    section.add "DataSourceId", valid_598475
  var valid_598476 = path.getOrDefault("AwsAccountId")
  valid_598476 = validateParameter(valid_598476, JString, required = true,
                                 default = nil)
  if valid_598476 != nil:
    section.add "AwsAccountId", valid_598476
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
  if body != nil:
    result.add "body", body

proc call*(call_598484: Call_DeleteDataSource_598472; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the data source permanently. This action breaks all the datasets that reference the deleted data source.
  ## 
  let valid = call_598484.validator(path, query, header, formData, body)
  let scheme = call_598484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598484.url(scheme.get, call_598484.host, call_598484.base,
                         call_598484.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598484, url, valid)

proc call*(call_598485: Call_DeleteDataSource_598472; DataSourceId: string;
          AwsAccountId: string): Recallable =
  ## deleteDataSource
  ## Deletes the data source permanently. This action breaks all the datasets that reference the deleted data source.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  var path_598486 = newJObject()
  add(path_598486, "DataSourceId", newJString(DataSourceId))
  add(path_598486, "AwsAccountId", newJString(AwsAccountId))
  result = call_598485.call(path_598486, nil, nil, nil, nil)

var deleteDataSource* = Call_DeleteDataSource_598472(name: "deleteDataSource",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}",
    validator: validate_DeleteDataSource_598473, base: "/",
    url: url_DeleteDataSource_598474, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_598503 = ref object of OpenApiRestCall_597389
proc url_UpdateGroup_598505(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGroup_598504(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598506 = path.getOrDefault("GroupName")
  valid_598506 = validateParameter(valid_598506, JString, required = true,
                                 default = nil)
  if valid_598506 != nil:
    section.add "GroupName", valid_598506
  var valid_598507 = path.getOrDefault("AwsAccountId")
  valid_598507 = validateParameter(valid_598507, JString, required = true,
                                 default = nil)
  if valid_598507 != nil:
    section.add "AwsAccountId", valid_598507
  var valid_598508 = path.getOrDefault("Namespace")
  valid_598508 = validateParameter(valid_598508, JString, required = true,
                                 default = nil)
  if valid_598508 != nil:
    section.add "Namespace", valid_598508
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
  var valid_598509 = header.getOrDefault("X-Amz-Signature")
  valid_598509 = validateParameter(valid_598509, JString, required = false,
                                 default = nil)
  if valid_598509 != nil:
    section.add "X-Amz-Signature", valid_598509
  var valid_598510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598510 = validateParameter(valid_598510, JString, required = false,
                                 default = nil)
  if valid_598510 != nil:
    section.add "X-Amz-Content-Sha256", valid_598510
  var valid_598511 = header.getOrDefault("X-Amz-Date")
  valid_598511 = validateParameter(valid_598511, JString, required = false,
                                 default = nil)
  if valid_598511 != nil:
    section.add "X-Amz-Date", valid_598511
  var valid_598512 = header.getOrDefault("X-Amz-Credential")
  valid_598512 = validateParameter(valid_598512, JString, required = false,
                                 default = nil)
  if valid_598512 != nil:
    section.add "X-Amz-Credential", valid_598512
  var valid_598513 = header.getOrDefault("X-Amz-Security-Token")
  valid_598513 = validateParameter(valid_598513, JString, required = false,
                                 default = nil)
  if valid_598513 != nil:
    section.add "X-Amz-Security-Token", valid_598513
  var valid_598514 = header.getOrDefault("X-Amz-Algorithm")
  valid_598514 = validateParameter(valid_598514, JString, required = false,
                                 default = nil)
  if valid_598514 != nil:
    section.add "X-Amz-Algorithm", valid_598514
  var valid_598515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598515 = validateParameter(valid_598515, JString, required = false,
                                 default = nil)
  if valid_598515 != nil:
    section.add "X-Amz-SignedHeaders", valid_598515
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598517: Call_UpdateGroup_598503; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes a group description. 
  ## 
  let valid = call_598517.validator(path, query, header, formData, body)
  let scheme = call_598517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598517.url(scheme.get, call_598517.host, call_598517.base,
                         call_598517.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598517, url, valid)

proc call*(call_598518: Call_UpdateGroup_598503; GroupName: string;
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
  var path_598519 = newJObject()
  var body_598520 = newJObject()
  add(path_598519, "GroupName", newJString(GroupName))
  add(path_598519, "AwsAccountId", newJString(AwsAccountId))
  add(path_598519, "Namespace", newJString(Namespace))
  if body != nil:
    body_598520 = body
  result = call_598518.call(path_598519, nil, nil, nil, body_598520)

var updateGroup* = Call_UpdateGroup_598503(name: "updateGroup",
                                        meth: HttpMethod.HttpPut,
                                        host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}",
                                        validator: validate_UpdateGroup_598504,
                                        base: "/", url: url_UpdateGroup_598505,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGroup_598487 = ref object of OpenApiRestCall_597389
proc url_DescribeGroup_598489(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeGroup_598488(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598490 = path.getOrDefault("GroupName")
  valid_598490 = validateParameter(valid_598490, JString, required = true,
                                 default = nil)
  if valid_598490 != nil:
    section.add "GroupName", valid_598490
  var valid_598491 = path.getOrDefault("AwsAccountId")
  valid_598491 = validateParameter(valid_598491, JString, required = true,
                                 default = nil)
  if valid_598491 != nil:
    section.add "AwsAccountId", valid_598491
  var valid_598492 = path.getOrDefault("Namespace")
  valid_598492 = validateParameter(valid_598492, JString, required = true,
                                 default = nil)
  if valid_598492 != nil:
    section.add "Namespace", valid_598492
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
  var valid_598493 = header.getOrDefault("X-Amz-Signature")
  valid_598493 = validateParameter(valid_598493, JString, required = false,
                                 default = nil)
  if valid_598493 != nil:
    section.add "X-Amz-Signature", valid_598493
  var valid_598494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598494 = validateParameter(valid_598494, JString, required = false,
                                 default = nil)
  if valid_598494 != nil:
    section.add "X-Amz-Content-Sha256", valid_598494
  var valid_598495 = header.getOrDefault("X-Amz-Date")
  valid_598495 = validateParameter(valid_598495, JString, required = false,
                                 default = nil)
  if valid_598495 != nil:
    section.add "X-Amz-Date", valid_598495
  var valid_598496 = header.getOrDefault("X-Amz-Credential")
  valid_598496 = validateParameter(valid_598496, JString, required = false,
                                 default = nil)
  if valid_598496 != nil:
    section.add "X-Amz-Credential", valid_598496
  var valid_598497 = header.getOrDefault("X-Amz-Security-Token")
  valid_598497 = validateParameter(valid_598497, JString, required = false,
                                 default = nil)
  if valid_598497 != nil:
    section.add "X-Amz-Security-Token", valid_598497
  var valid_598498 = header.getOrDefault("X-Amz-Algorithm")
  valid_598498 = validateParameter(valid_598498, JString, required = false,
                                 default = nil)
  if valid_598498 != nil:
    section.add "X-Amz-Algorithm", valid_598498
  var valid_598499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598499 = validateParameter(valid_598499, JString, required = false,
                                 default = nil)
  if valid_598499 != nil:
    section.add "X-Amz-SignedHeaders", valid_598499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598500: Call_DescribeGroup_598487; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns an Amazon QuickSight group's description and Amazon Resource Name (ARN). 
  ## 
  let valid = call_598500.validator(path, query, header, formData, body)
  let scheme = call_598500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598500.url(scheme.get, call_598500.host, call_598500.base,
                         call_598500.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598500, url, valid)

proc call*(call_598501: Call_DescribeGroup_598487; GroupName: string;
          AwsAccountId: string; Namespace: string): Recallable =
  ## describeGroup
  ## Returns an Amazon QuickSight group's description and Amazon Resource Name (ARN). 
  ##   GroupName: string (required)
  ##            : The name of the group that you want to describe.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_598502 = newJObject()
  add(path_598502, "GroupName", newJString(GroupName))
  add(path_598502, "AwsAccountId", newJString(AwsAccountId))
  add(path_598502, "Namespace", newJString(Namespace))
  result = call_598501.call(path_598502, nil, nil, nil, nil)

var describeGroup* = Call_DescribeGroup_598487(name: "describeGroup",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}",
    validator: validate_DescribeGroup_598488, base: "/", url: url_DescribeGroup_598489,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_598521 = ref object of OpenApiRestCall_597389
proc url_DeleteGroup_598523(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGroup_598522(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598524 = path.getOrDefault("GroupName")
  valid_598524 = validateParameter(valid_598524, JString, required = true,
                                 default = nil)
  if valid_598524 != nil:
    section.add "GroupName", valid_598524
  var valid_598525 = path.getOrDefault("AwsAccountId")
  valid_598525 = validateParameter(valid_598525, JString, required = true,
                                 default = nil)
  if valid_598525 != nil:
    section.add "AwsAccountId", valid_598525
  var valid_598526 = path.getOrDefault("Namespace")
  valid_598526 = validateParameter(valid_598526, JString, required = true,
                                 default = nil)
  if valid_598526 != nil:
    section.add "Namespace", valid_598526
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
  var valid_598527 = header.getOrDefault("X-Amz-Signature")
  valid_598527 = validateParameter(valid_598527, JString, required = false,
                                 default = nil)
  if valid_598527 != nil:
    section.add "X-Amz-Signature", valid_598527
  var valid_598528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598528 = validateParameter(valid_598528, JString, required = false,
                                 default = nil)
  if valid_598528 != nil:
    section.add "X-Amz-Content-Sha256", valid_598528
  var valid_598529 = header.getOrDefault("X-Amz-Date")
  valid_598529 = validateParameter(valid_598529, JString, required = false,
                                 default = nil)
  if valid_598529 != nil:
    section.add "X-Amz-Date", valid_598529
  var valid_598530 = header.getOrDefault("X-Amz-Credential")
  valid_598530 = validateParameter(valid_598530, JString, required = false,
                                 default = nil)
  if valid_598530 != nil:
    section.add "X-Amz-Credential", valid_598530
  var valid_598531 = header.getOrDefault("X-Amz-Security-Token")
  valid_598531 = validateParameter(valid_598531, JString, required = false,
                                 default = nil)
  if valid_598531 != nil:
    section.add "X-Amz-Security-Token", valid_598531
  var valid_598532 = header.getOrDefault("X-Amz-Algorithm")
  valid_598532 = validateParameter(valid_598532, JString, required = false,
                                 default = nil)
  if valid_598532 != nil:
    section.add "X-Amz-Algorithm", valid_598532
  var valid_598533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598533 = validateParameter(valid_598533, JString, required = false,
                                 default = nil)
  if valid_598533 != nil:
    section.add "X-Amz-SignedHeaders", valid_598533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598534: Call_DeleteGroup_598521; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a user group from Amazon QuickSight. 
  ## 
  let valid = call_598534.validator(path, query, header, formData, body)
  let scheme = call_598534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598534.url(scheme.get, call_598534.host, call_598534.base,
                         call_598534.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598534, url, valid)

proc call*(call_598535: Call_DeleteGroup_598521; GroupName: string;
          AwsAccountId: string; Namespace: string): Recallable =
  ## deleteGroup
  ## Removes a user group from Amazon QuickSight. 
  ##   GroupName: string (required)
  ##            : The name of the group that you want to delete.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_598536 = newJObject()
  add(path_598536, "GroupName", newJString(GroupName))
  add(path_598536, "AwsAccountId", newJString(AwsAccountId))
  add(path_598536, "Namespace", newJString(Namespace))
  result = call_598535.call(path_598536, nil, nil, nil, nil)

var deleteGroup* = Call_DeleteGroup_598521(name: "deleteGroup",
                                        meth: HttpMethod.HttpDelete,
                                        host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}",
                                        validator: validate_DeleteGroup_598522,
                                        base: "/", url: url_DeleteGroup_598523,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIAMPolicyAssignment_598537 = ref object of OpenApiRestCall_597389
proc url_DeleteIAMPolicyAssignment_598539(protocol: Scheme; host: string;
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

proc validate_DeleteIAMPolicyAssignment_598538(path: JsonNode; query: JsonNode;
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
  var valid_598540 = path.getOrDefault("AwsAccountId")
  valid_598540 = validateParameter(valid_598540, JString, required = true,
                                 default = nil)
  if valid_598540 != nil:
    section.add "AwsAccountId", valid_598540
  var valid_598541 = path.getOrDefault("Namespace")
  valid_598541 = validateParameter(valid_598541, JString, required = true,
                                 default = nil)
  if valid_598541 != nil:
    section.add "Namespace", valid_598541
  var valid_598542 = path.getOrDefault("AssignmentName")
  valid_598542 = validateParameter(valid_598542, JString, required = true,
                                 default = nil)
  if valid_598542 != nil:
    section.add "AssignmentName", valid_598542
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
  var valid_598543 = header.getOrDefault("X-Amz-Signature")
  valid_598543 = validateParameter(valid_598543, JString, required = false,
                                 default = nil)
  if valid_598543 != nil:
    section.add "X-Amz-Signature", valid_598543
  var valid_598544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598544 = validateParameter(valid_598544, JString, required = false,
                                 default = nil)
  if valid_598544 != nil:
    section.add "X-Amz-Content-Sha256", valid_598544
  var valid_598545 = header.getOrDefault("X-Amz-Date")
  valid_598545 = validateParameter(valid_598545, JString, required = false,
                                 default = nil)
  if valid_598545 != nil:
    section.add "X-Amz-Date", valid_598545
  var valid_598546 = header.getOrDefault("X-Amz-Credential")
  valid_598546 = validateParameter(valid_598546, JString, required = false,
                                 default = nil)
  if valid_598546 != nil:
    section.add "X-Amz-Credential", valid_598546
  var valid_598547 = header.getOrDefault("X-Amz-Security-Token")
  valid_598547 = validateParameter(valid_598547, JString, required = false,
                                 default = nil)
  if valid_598547 != nil:
    section.add "X-Amz-Security-Token", valid_598547
  var valid_598548 = header.getOrDefault("X-Amz-Algorithm")
  valid_598548 = validateParameter(valid_598548, JString, required = false,
                                 default = nil)
  if valid_598548 != nil:
    section.add "X-Amz-Algorithm", valid_598548
  var valid_598549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598549 = validateParameter(valid_598549, JString, required = false,
                                 default = nil)
  if valid_598549 != nil:
    section.add "X-Amz-SignedHeaders", valid_598549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598550: Call_DeleteIAMPolicyAssignment_598537; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing IAM policy assignment.
  ## 
  let valid = call_598550.validator(path, query, header, formData, body)
  let scheme = call_598550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598550.url(scheme.get, call_598550.host, call_598550.base,
                         call_598550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598550, url, valid)

proc call*(call_598551: Call_DeleteIAMPolicyAssignment_598537;
          AwsAccountId: string; Namespace: string; AssignmentName: string): Recallable =
  ## deleteIAMPolicyAssignment
  ## Deletes an existing IAM policy assignment.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID where you want to delete the IAM policy assignment.
  ##   Namespace: string (required)
  ##            : The namespace that contains the assignment.
  ##   AssignmentName: string (required)
  ##                 : The name of the assignment. 
  var path_598552 = newJObject()
  add(path_598552, "AwsAccountId", newJString(AwsAccountId))
  add(path_598552, "Namespace", newJString(Namespace))
  add(path_598552, "AssignmentName", newJString(AssignmentName))
  result = call_598551.call(path_598552, nil, nil, nil, nil)

var deleteIAMPolicyAssignment* = Call_DeleteIAMPolicyAssignment_598537(
    name: "deleteIAMPolicyAssignment", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespace/{Namespace}/iam-policy-assignments/{AssignmentName}",
    validator: validate_DeleteIAMPolicyAssignment_598538, base: "/",
    url: url_DeleteIAMPolicyAssignment_598539,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_598569 = ref object of OpenApiRestCall_597389
proc url_UpdateUser_598571(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateUser_598570(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598572 = path.getOrDefault("AwsAccountId")
  valid_598572 = validateParameter(valid_598572, JString, required = true,
                                 default = nil)
  if valid_598572 != nil:
    section.add "AwsAccountId", valid_598572
  var valid_598573 = path.getOrDefault("Namespace")
  valid_598573 = validateParameter(valid_598573, JString, required = true,
                                 default = nil)
  if valid_598573 != nil:
    section.add "Namespace", valid_598573
  var valid_598574 = path.getOrDefault("UserName")
  valid_598574 = validateParameter(valid_598574, JString, required = true,
                                 default = nil)
  if valid_598574 != nil:
    section.add "UserName", valid_598574
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
  var valid_598575 = header.getOrDefault("X-Amz-Signature")
  valid_598575 = validateParameter(valid_598575, JString, required = false,
                                 default = nil)
  if valid_598575 != nil:
    section.add "X-Amz-Signature", valid_598575
  var valid_598576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598576 = validateParameter(valid_598576, JString, required = false,
                                 default = nil)
  if valid_598576 != nil:
    section.add "X-Amz-Content-Sha256", valid_598576
  var valid_598577 = header.getOrDefault("X-Amz-Date")
  valid_598577 = validateParameter(valid_598577, JString, required = false,
                                 default = nil)
  if valid_598577 != nil:
    section.add "X-Amz-Date", valid_598577
  var valid_598578 = header.getOrDefault("X-Amz-Credential")
  valid_598578 = validateParameter(valid_598578, JString, required = false,
                                 default = nil)
  if valid_598578 != nil:
    section.add "X-Amz-Credential", valid_598578
  var valid_598579 = header.getOrDefault("X-Amz-Security-Token")
  valid_598579 = validateParameter(valid_598579, JString, required = false,
                                 default = nil)
  if valid_598579 != nil:
    section.add "X-Amz-Security-Token", valid_598579
  var valid_598580 = header.getOrDefault("X-Amz-Algorithm")
  valid_598580 = validateParameter(valid_598580, JString, required = false,
                                 default = nil)
  if valid_598580 != nil:
    section.add "X-Amz-Algorithm", valid_598580
  var valid_598581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598581 = validateParameter(valid_598581, JString, required = false,
                                 default = nil)
  if valid_598581 != nil:
    section.add "X-Amz-SignedHeaders", valid_598581
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598583: Call_UpdateUser_598569; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Amazon QuickSight user.
  ## 
  let valid = call_598583.validator(path, query, header, formData, body)
  let scheme = call_598583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598583.url(scheme.get, call_598583.host, call_598583.base,
                         call_598583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598583, url, valid)

proc call*(call_598584: Call_UpdateUser_598569; AwsAccountId: string;
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
  var path_598585 = newJObject()
  var body_598586 = newJObject()
  add(path_598585, "AwsAccountId", newJString(AwsAccountId))
  add(path_598585, "Namespace", newJString(Namespace))
  add(path_598585, "UserName", newJString(UserName))
  if body != nil:
    body_598586 = body
  result = call_598584.call(path_598585, nil, nil, nil, body_598586)

var updateUser* = Call_UpdateUser_598569(name: "updateUser",
                                      meth: HttpMethod.HttpPut,
                                      host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}",
                                      validator: validate_UpdateUser_598570,
                                      base: "/", url: url_UpdateUser_598571,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_598553 = ref object of OpenApiRestCall_597389
proc url_DescribeUser_598555(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeUser_598554(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598556 = path.getOrDefault("AwsAccountId")
  valid_598556 = validateParameter(valid_598556, JString, required = true,
                                 default = nil)
  if valid_598556 != nil:
    section.add "AwsAccountId", valid_598556
  var valid_598557 = path.getOrDefault("Namespace")
  valid_598557 = validateParameter(valid_598557, JString, required = true,
                                 default = nil)
  if valid_598557 != nil:
    section.add "Namespace", valid_598557
  var valid_598558 = path.getOrDefault("UserName")
  valid_598558 = validateParameter(valid_598558, JString, required = true,
                                 default = nil)
  if valid_598558 != nil:
    section.add "UserName", valid_598558
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
  var valid_598559 = header.getOrDefault("X-Amz-Signature")
  valid_598559 = validateParameter(valid_598559, JString, required = false,
                                 default = nil)
  if valid_598559 != nil:
    section.add "X-Amz-Signature", valid_598559
  var valid_598560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598560 = validateParameter(valid_598560, JString, required = false,
                                 default = nil)
  if valid_598560 != nil:
    section.add "X-Amz-Content-Sha256", valid_598560
  var valid_598561 = header.getOrDefault("X-Amz-Date")
  valid_598561 = validateParameter(valid_598561, JString, required = false,
                                 default = nil)
  if valid_598561 != nil:
    section.add "X-Amz-Date", valid_598561
  var valid_598562 = header.getOrDefault("X-Amz-Credential")
  valid_598562 = validateParameter(valid_598562, JString, required = false,
                                 default = nil)
  if valid_598562 != nil:
    section.add "X-Amz-Credential", valid_598562
  var valid_598563 = header.getOrDefault("X-Amz-Security-Token")
  valid_598563 = validateParameter(valid_598563, JString, required = false,
                                 default = nil)
  if valid_598563 != nil:
    section.add "X-Amz-Security-Token", valid_598563
  var valid_598564 = header.getOrDefault("X-Amz-Algorithm")
  valid_598564 = validateParameter(valid_598564, JString, required = false,
                                 default = nil)
  if valid_598564 != nil:
    section.add "X-Amz-Algorithm", valid_598564
  var valid_598565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598565 = validateParameter(valid_598565, JString, required = false,
                                 default = nil)
  if valid_598565 != nil:
    section.add "X-Amz-SignedHeaders", valid_598565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598566: Call_DescribeUser_598553; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns information about a user, given the user name. 
  ## 
  let valid = call_598566.validator(path, query, header, formData, body)
  let scheme = call_598566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598566.url(scheme.get, call_598566.host, call_598566.base,
                         call_598566.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598566, url, valid)

proc call*(call_598567: Call_DescribeUser_598553; AwsAccountId: string;
          Namespace: string; UserName: string): Recallable =
  ## describeUser
  ## Returns information about a user, given the user name. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: string (required)
  ##           : The name of the user that you want to describe.
  var path_598568 = newJObject()
  add(path_598568, "AwsAccountId", newJString(AwsAccountId))
  add(path_598568, "Namespace", newJString(Namespace))
  add(path_598568, "UserName", newJString(UserName))
  result = call_598567.call(path_598568, nil, nil, nil, nil)

var describeUser* = Call_DescribeUser_598553(name: "describeUser",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}",
    validator: validate_DescribeUser_598554, base: "/", url: url_DescribeUser_598555,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_598587 = ref object of OpenApiRestCall_597389
proc url_DeleteUser_598589(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteUser_598588(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598590 = path.getOrDefault("AwsAccountId")
  valid_598590 = validateParameter(valid_598590, JString, required = true,
                                 default = nil)
  if valid_598590 != nil:
    section.add "AwsAccountId", valid_598590
  var valid_598591 = path.getOrDefault("Namespace")
  valid_598591 = validateParameter(valid_598591, JString, required = true,
                                 default = nil)
  if valid_598591 != nil:
    section.add "Namespace", valid_598591
  var valid_598592 = path.getOrDefault("UserName")
  valid_598592 = validateParameter(valid_598592, JString, required = true,
                                 default = nil)
  if valid_598592 != nil:
    section.add "UserName", valid_598592
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
  var valid_598593 = header.getOrDefault("X-Amz-Signature")
  valid_598593 = validateParameter(valid_598593, JString, required = false,
                                 default = nil)
  if valid_598593 != nil:
    section.add "X-Amz-Signature", valid_598593
  var valid_598594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598594 = validateParameter(valid_598594, JString, required = false,
                                 default = nil)
  if valid_598594 != nil:
    section.add "X-Amz-Content-Sha256", valid_598594
  var valid_598595 = header.getOrDefault("X-Amz-Date")
  valid_598595 = validateParameter(valid_598595, JString, required = false,
                                 default = nil)
  if valid_598595 != nil:
    section.add "X-Amz-Date", valid_598595
  var valid_598596 = header.getOrDefault("X-Amz-Credential")
  valid_598596 = validateParameter(valid_598596, JString, required = false,
                                 default = nil)
  if valid_598596 != nil:
    section.add "X-Amz-Credential", valid_598596
  var valid_598597 = header.getOrDefault("X-Amz-Security-Token")
  valid_598597 = validateParameter(valid_598597, JString, required = false,
                                 default = nil)
  if valid_598597 != nil:
    section.add "X-Amz-Security-Token", valid_598597
  var valid_598598 = header.getOrDefault("X-Amz-Algorithm")
  valid_598598 = validateParameter(valid_598598, JString, required = false,
                                 default = nil)
  if valid_598598 != nil:
    section.add "X-Amz-Algorithm", valid_598598
  var valid_598599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598599 = validateParameter(valid_598599, JString, required = false,
                                 default = nil)
  if valid_598599 != nil:
    section.add "X-Amz-SignedHeaders", valid_598599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598600: Call_DeleteUser_598587; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the Amazon QuickSight user that is associated with the identity of the AWS Identity and Access Management (IAM) user or role that's making the call. The IAM user isn't deleted as a result of this call. 
  ## 
  let valid = call_598600.validator(path, query, header, formData, body)
  let scheme = call_598600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598600.url(scheme.get, call_598600.host, call_598600.base,
                         call_598600.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598600, url, valid)

proc call*(call_598601: Call_DeleteUser_598587; AwsAccountId: string;
          Namespace: string; UserName: string): Recallable =
  ## deleteUser
  ## Deletes the Amazon QuickSight user that is associated with the identity of the AWS Identity and Access Management (IAM) user or role that's making the call. The IAM user isn't deleted as a result of this call. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   UserName: string (required)
  ##           : The name of the user that you want to delete.
  var path_598602 = newJObject()
  add(path_598602, "AwsAccountId", newJString(AwsAccountId))
  add(path_598602, "Namespace", newJString(Namespace))
  add(path_598602, "UserName", newJString(UserName))
  result = call_598601.call(path_598602, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_598587(name: "deleteUser",
                                      meth: HttpMethod.HttpDelete,
                                      host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}",
                                      validator: validate_DeleteUser_598588,
                                      base: "/", url: url_DeleteUser_598589,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserByPrincipalId_598603 = ref object of OpenApiRestCall_597389
proc url_DeleteUserByPrincipalId_598605(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUserByPrincipalId_598604(path: JsonNode; query: JsonNode;
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
  var valid_598606 = path.getOrDefault("AwsAccountId")
  valid_598606 = validateParameter(valid_598606, JString, required = true,
                                 default = nil)
  if valid_598606 != nil:
    section.add "AwsAccountId", valid_598606
  var valid_598607 = path.getOrDefault("Namespace")
  valid_598607 = validateParameter(valid_598607, JString, required = true,
                                 default = nil)
  if valid_598607 != nil:
    section.add "Namespace", valid_598607
  var valid_598608 = path.getOrDefault("PrincipalId")
  valid_598608 = validateParameter(valid_598608, JString, required = true,
                                 default = nil)
  if valid_598608 != nil:
    section.add "PrincipalId", valid_598608
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
  var valid_598609 = header.getOrDefault("X-Amz-Signature")
  valid_598609 = validateParameter(valid_598609, JString, required = false,
                                 default = nil)
  if valid_598609 != nil:
    section.add "X-Amz-Signature", valid_598609
  var valid_598610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598610 = validateParameter(valid_598610, JString, required = false,
                                 default = nil)
  if valid_598610 != nil:
    section.add "X-Amz-Content-Sha256", valid_598610
  var valid_598611 = header.getOrDefault("X-Amz-Date")
  valid_598611 = validateParameter(valid_598611, JString, required = false,
                                 default = nil)
  if valid_598611 != nil:
    section.add "X-Amz-Date", valid_598611
  var valid_598612 = header.getOrDefault("X-Amz-Credential")
  valid_598612 = validateParameter(valid_598612, JString, required = false,
                                 default = nil)
  if valid_598612 != nil:
    section.add "X-Amz-Credential", valid_598612
  var valid_598613 = header.getOrDefault("X-Amz-Security-Token")
  valid_598613 = validateParameter(valid_598613, JString, required = false,
                                 default = nil)
  if valid_598613 != nil:
    section.add "X-Amz-Security-Token", valid_598613
  var valid_598614 = header.getOrDefault("X-Amz-Algorithm")
  valid_598614 = validateParameter(valid_598614, JString, required = false,
                                 default = nil)
  if valid_598614 != nil:
    section.add "X-Amz-Algorithm", valid_598614
  var valid_598615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598615 = validateParameter(valid_598615, JString, required = false,
                                 default = nil)
  if valid_598615 != nil:
    section.add "X-Amz-SignedHeaders", valid_598615
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598616: Call_DeleteUserByPrincipalId_598603; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a user identified by its principal ID. 
  ## 
  let valid = call_598616.validator(path, query, header, formData, body)
  let scheme = call_598616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598616.url(scheme.get, call_598616.host, call_598616.base,
                         call_598616.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598616, url, valid)

proc call*(call_598617: Call_DeleteUserByPrincipalId_598603; AwsAccountId: string;
          Namespace: string; PrincipalId: string): Recallable =
  ## deleteUserByPrincipalId
  ## Deletes a user identified by its principal ID. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   PrincipalId: string (required)
  ##              : The principal ID of the user.
  var path_598618 = newJObject()
  add(path_598618, "AwsAccountId", newJString(AwsAccountId))
  add(path_598618, "Namespace", newJString(Namespace))
  add(path_598618, "PrincipalId", newJString(PrincipalId))
  result = call_598617.call(path_598618, nil, nil, nil, nil)

var deleteUserByPrincipalId* = Call_DeleteUserByPrincipalId_598603(
    name: "deleteUserByPrincipalId", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/user-principals/{PrincipalId}",
    validator: validate_DeleteUserByPrincipalId_598604, base: "/",
    url: url_DeleteUserByPrincipalId_598605, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDashboardPermissions_598634 = ref object of OpenApiRestCall_597389
proc url_UpdateDashboardPermissions_598636(protocol: Scheme; host: string;
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

proc validate_UpdateDashboardPermissions_598635(path: JsonNode; query: JsonNode;
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
  var valid_598637 = path.getOrDefault("AwsAccountId")
  valid_598637 = validateParameter(valid_598637, JString, required = true,
                                 default = nil)
  if valid_598637 != nil:
    section.add "AwsAccountId", valid_598637
  var valid_598638 = path.getOrDefault("DashboardId")
  valid_598638 = validateParameter(valid_598638, JString, required = true,
                                 default = nil)
  if valid_598638 != nil:
    section.add "DashboardId", valid_598638
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
  var valid_598639 = header.getOrDefault("X-Amz-Signature")
  valid_598639 = validateParameter(valid_598639, JString, required = false,
                                 default = nil)
  if valid_598639 != nil:
    section.add "X-Amz-Signature", valid_598639
  var valid_598640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598640 = validateParameter(valid_598640, JString, required = false,
                                 default = nil)
  if valid_598640 != nil:
    section.add "X-Amz-Content-Sha256", valid_598640
  var valid_598641 = header.getOrDefault("X-Amz-Date")
  valid_598641 = validateParameter(valid_598641, JString, required = false,
                                 default = nil)
  if valid_598641 != nil:
    section.add "X-Amz-Date", valid_598641
  var valid_598642 = header.getOrDefault("X-Amz-Credential")
  valid_598642 = validateParameter(valid_598642, JString, required = false,
                                 default = nil)
  if valid_598642 != nil:
    section.add "X-Amz-Credential", valid_598642
  var valid_598643 = header.getOrDefault("X-Amz-Security-Token")
  valid_598643 = validateParameter(valid_598643, JString, required = false,
                                 default = nil)
  if valid_598643 != nil:
    section.add "X-Amz-Security-Token", valid_598643
  var valid_598644 = header.getOrDefault("X-Amz-Algorithm")
  valid_598644 = validateParameter(valid_598644, JString, required = false,
                                 default = nil)
  if valid_598644 != nil:
    section.add "X-Amz-Algorithm", valid_598644
  var valid_598645 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598645 = validateParameter(valid_598645, JString, required = false,
                                 default = nil)
  if valid_598645 != nil:
    section.add "X-Amz-SignedHeaders", valid_598645
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598647: Call_UpdateDashboardPermissions_598634; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates read and write permissions on a dashboard.
  ## 
  let valid = call_598647.validator(path, query, header, formData, body)
  let scheme = call_598647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598647.url(scheme.get, call_598647.host, call_598647.base,
                         call_598647.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598647, url, valid)

proc call*(call_598648: Call_UpdateDashboardPermissions_598634;
          AwsAccountId: string; body: JsonNode; DashboardId: string): Recallable =
  ## updateDashboardPermissions
  ## Updates read and write permissions on a dashboard.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard whose permissions you're updating.
  ##   body: JObject (required)
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  var path_598649 = newJObject()
  var body_598650 = newJObject()
  add(path_598649, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_598650 = body
  add(path_598649, "DashboardId", newJString(DashboardId))
  result = call_598648.call(path_598649, nil, nil, nil, body_598650)

var updateDashboardPermissions* = Call_UpdateDashboardPermissions_598634(
    name: "updateDashboardPermissions", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/permissions",
    validator: validate_UpdateDashboardPermissions_598635, base: "/",
    url: url_UpdateDashboardPermissions_598636,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDashboardPermissions_598619 = ref object of OpenApiRestCall_597389
proc url_DescribeDashboardPermissions_598621(protocol: Scheme; host: string;
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

proc validate_DescribeDashboardPermissions_598620(path: JsonNode; query: JsonNode;
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
  var valid_598622 = path.getOrDefault("AwsAccountId")
  valid_598622 = validateParameter(valid_598622, JString, required = true,
                                 default = nil)
  if valid_598622 != nil:
    section.add "AwsAccountId", valid_598622
  var valid_598623 = path.getOrDefault("DashboardId")
  valid_598623 = validateParameter(valid_598623, JString, required = true,
                                 default = nil)
  if valid_598623 != nil:
    section.add "DashboardId", valid_598623
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
  var valid_598624 = header.getOrDefault("X-Amz-Signature")
  valid_598624 = validateParameter(valid_598624, JString, required = false,
                                 default = nil)
  if valid_598624 != nil:
    section.add "X-Amz-Signature", valid_598624
  var valid_598625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598625 = validateParameter(valid_598625, JString, required = false,
                                 default = nil)
  if valid_598625 != nil:
    section.add "X-Amz-Content-Sha256", valid_598625
  var valid_598626 = header.getOrDefault("X-Amz-Date")
  valid_598626 = validateParameter(valid_598626, JString, required = false,
                                 default = nil)
  if valid_598626 != nil:
    section.add "X-Amz-Date", valid_598626
  var valid_598627 = header.getOrDefault("X-Amz-Credential")
  valid_598627 = validateParameter(valid_598627, JString, required = false,
                                 default = nil)
  if valid_598627 != nil:
    section.add "X-Amz-Credential", valid_598627
  var valid_598628 = header.getOrDefault("X-Amz-Security-Token")
  valid_598628 = validateParameter(valid_598628, JString, required = false,
                                 default = nil)
  if valid_598628 != nil:
    section.add "X-Amz-Security-Token", valid_598628
  var valid_598629 = header.getOrDefault("X-Amz-Algorithm")
  valid_598629 = validateParameter(valid_598629, JString, required = false,
                                 default = nil)
  if valid_598629 != nil:
    section.add "X-Amz-Algorithm", valid_598629
  var valid_598630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598630 = validateParameter(valid_598630, JString, required = false,
                                 default = nil)
  if valid_598630 != nil:
    section.add "X-Amz-SignedHeaders", valid_598630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598631: Call_DescribeDashboardPermissions_598619; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes read and write permissions for a dashboard.
  ## 
  let valid = call_598631.validator(path, query, header, formData, body)
  let scheme = call_598631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598631.url(scheme.get, call_598631.host, call_598631.base,
                         call_598631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598631, url, valid)

proc call*(call_598632: Call_DescribeDashboardPermissions_598619;
          AwsAccountId: string; DashboardId: string): Recallable =
  ## describeDashboardPermissions
  ## Describes read and write permissions for a dashboard.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're describing permissions for.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard, also added to the IAM policy.
  var path_598633 = newJObject()
  add(path_598633, "AwsAccountId", newJString(AwsAccountId))
  add(path_598633, "DashboardId", newJString(DashboardId))
  result = call_598632.call(path_598633, nil, nil, nil, nil)

var describeDashboardPermissions* = Call_DescribeDashboardPermissions_598619(
    name: "describeDashboardPermissions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/permissions",
    validator: validate_DescribeDashboardPermissions_598620, base: "/",
    url: url_DescribeDashboardPermissions_598621,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSetPermissions_598666 = ref object of OpenApiRestCall_597389
proc url_UpdateDataSetPermissions_598668(protocol: Scheme; host: string;
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

proc validate_UpdateDataSetPermissions_598667(path: JsonNode; query: JsonNode;
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
  var valid_598669 = path.getOrDefault("AwsAccountId")
  valid_598669 = validateParameter(valid_598669, JString, required = true,
                                 default = nil)
  if valid_598669 != nil:
    section.add "AwsAccountId", valid_598669
  var valid_598670 = path.getOrDefault("DataSetId")
  valid_598670 = validateParameter(valid_598670, JString, required = true,
                                 default = nil)
  if valid_598670 != nil:
    section.add "DataSetId", valid_598670
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
  var valid_598671 = header.getOrDefault("X-Amz-Signature")
  valid_598671 = validateParameter(valid_598671, JString, required = false,
                                 default = nil)
  if valid_598671 != nil:
    section.add "X-Amz-Signature", valid_598671
  var valid_598672 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598672 = validateParameter(valid_598672, JString, required = false,
                                 default = nil)
  if valid_598672 != nil:
    section.add "X-Amz-Content-Sha256", valid_598672
  var valid_598673 = header.getOrDefault("X-Amz-Date")
  valid_598673 = validateParameter(valid_598673, JString, required = false,
                                 default = nil)
  if valid_598673 != nil:
    section.add "X-Amz-Date", valid_598673
  var valid_598674 = header.getOrDefault("X-Amz-Credential")
  valid_598674 = validateParameter(valid_598674, JString, required = false,
                                 default = nil)
  if valid_598674 != nil:
    section.add "X-Amz-Credential", valid_598674
  var valid_598675 = header.getOrDefault("X-Amz-Security-Token")
  valid_598675 = validateParameter(valid_598675, JString, required = false,
                                 default = nil)
  if valid_598675 != nil:
    section.add "X-Amz-Security-Token", valid_598675
  var valid_598676 = header.getOrDefault("X-Amz-Algorithm")
  valid_598676 = validateParameter(valid_598676, JString, required = false,
                                 default = nil)
  if valid_598676 != nil:
    section.add "X-Amz-Algorithm", valid_598676
  var valid_598677 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598677 = validateParameter(valid_598677, JString, required = false,
                                 default = nil)
  if valid_598677 != nil:
    section.add "X-Amz-SignedHeaders", valid_598677
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598679: Call_UpdateDataSetPermissions_598666; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
  ## 
  let valid = call_598679.validator(path, query, header, formData, body)
  let scheme = call_598679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598679.url(scheme.get, call_598679.host, call_598679.base,
                         call_598679.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598679, url, valid)

proc call*(call_598680: Call_UpdateDataSetPermissions_598666; AwsAccountId: string;
          DataSetId: string; body: JsonNode): Recallable =
  ## updateDataSetPermissions
  ## <p>Updates the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset whose permissions you want to update. This ID is unique per AWS Region for each AWS account.
  ##   body: JObject (required)
  var path_598681 = newJObject()
  var body_598682 = newJObject()
  add(path_598681, "AwsAccountId", newJString(AwsAccountId))
  add(path_598681, "DataSetId", newJString(DataSetId))
  if body != nil:
    body_598682 = body
  result = call_598680.call(path_598681, nil, nil, nil, body_598682)

var updateDataSetPermissions* = Call_UpdateDataSetPermissions_598666(
    name: "updateDataSetPermissions", meth: HttpMethod.HttpPost,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/permissions",
    validator: validate_UpdateDataSetPermissions_598667, base: "/",
    url: url_UpdateDataSetPermissions_598668, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSetPermissions_598651 = ref object of OpenApiRestCall_597389
proc url_DescribeDataSetPermissions_598653(protocol: Scheme; host: string;
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

proc validate_DescribeDataSetPermissions_598652(path: JsonNode; query: JsonNode;
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
  var valid_598654 = path.getOrDefault("AwsAccountId")
  valid_598654 = validateParameter(valid_598654, JString, required = true,
                                 default = nil)
  if valid_598654 != nil:
    section.add "AwsAccountId", valid_598654
  var valid_598655 = path.getOrDefault("DataSetId")
  valid_598655 = validateParameter(valid_598655, JString, required = true,
                                 default = nil)
  if valid_598655 != nil:
    section.add "DataSetId", valid_598655
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
  var valid_598656 = header.getOrDefault("X-Amz-Signature")
  valid_598656 = validateParameter(valid_598656, JString, required = false,
                                 default = nil)
  if valid_598656 != nil:
    section.add "X-Amz-Signature", valid_598656
  var valid_598657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598657 = validateParameter(valid_598657, JString, required = false,
                                 default = nil)
  if valid_598657 != nil:
    section.add "X-Amz-Content-Sha256", valid_598657
  var valid_598658 = header.getOrDefault("X-Amz-Date")
  valid_598658 = validateParameter(valid_598658, JString, required = false,
                                 default = nil)
  if valid_598658 != nil:
    section.add "X-Amz-Date", valid_598658
  var valid_598659 = header.getOrDefault("X-Amz-Credential")
  valid_598659 = validateParameter(valid_598659, JString, required = false,
                                 default = nil)
  if valid_598659 != nil:
    section.add "X-Amz-Credential", valid_598659
  var valid_598660 = header.getOrDefault("X-Amz-Security-Token")
  valid_598660 = validateParameter(valid_598660, JString, required = false,
                                 default = nil)
  if valid_598660 != nil:
    section.add "X-Amz-Security-Token", valid_598660
  var valid_598661 = header.getOrDefault("X-Amz-Algorithm")
  valid_598661 = validateParameter(valid_598661, JString, required = false,
                                 default = nil)
  if valid_598661 != nil:
    section.add "X-Amz-Algorithm", valid_598661
  var valid_598662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598662 = validateParameter(valid_598662, JString, required = false,
                                 default = nil)
  if valid_598662 != nil:
    section.add "X-Amz-SignedHeaders", valid_598662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598663: Call_DescribeDataSetPermissions_598651; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
  ## 
  let valid = call_598663.validator(path, query, header, formData, body)
  let scheme = call_598663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598663.url(scheme.get, call_598663.host, call_598663.base,
                         call_598663.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598663, url, valid)

proc call*(call_598664: Call_DescribeDataSetPermissions_598651;
          AwsAccountId: string; DataSetId: string): Recallable =
  ## describeDataSetPermissions
  ## <p>Describes the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code>.</p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset that you want to create. This ID is unique per AWS Region for each AWS account.
  var path_598665 = newJObject()
  add(path_598665, "AwsAccountId", newJString(AwsAccountId))
  add(path_598665, "DataSetId", newJString(DataSetId))
  result = call_598664.call(path_598665, nil, nil, nil, nil)

var describeDataSetPermissions* = Call_DescribeDataSetPermissions_598651(
    name: "describeDataSetPermissions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/permissions",
    validator: validate_DescribeDataSetPermissions_598652, base: "/",
    url: url_DescribeDataSetPermissions_598653,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSourcePermissions_598698 = ref object of OpenApiRestCall_597389
proc url_UpdateDataSourcePermissions_598700(protocol: Scheme; host: string;
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

proc validate_UpdateDataSourcePermissions_598699(path: JsonNode; query: JsonNode;
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
  var valid_598701 = path.getOrDefault("DataSourceId")
  valid_598701 = validateParameter(valid_598701, JString, required = true,
                                 default = nil)
  if valid_598701 != nil:
    section.add "DataSourceId", valid_598701
  var valid_598702 = path.getOrDefault("AwsAccountId")
  valid_598702 = validateParameter(valid_598702, JString, required = true,
                                 default = nil)
  if valid_598702 != nil:
    section.add "AwsAccountId", valid_598702
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
  var valid_598703 = header.getOrDefault("X-Amz-Signature")
  valid_598703 = validateParameter(valid_598703, JString, required = false,
                                 default = nil)
  if valid_598703 != nil:
    section.add "X-Amz-Signature", valid_598703
  var valid_598704 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598704 = validateParameter(valid_598704, JString, required = false,
                                 default = nil)
  if valid_598704 != nil:
    section.add "X-Amz-Content-Sha256", valid_598704
  var valid_598705 = header.getOrDefault("X-Amz-Date")
  valid_598705 = validateParameter(valid_598705, JString, required = false,
                                 default = nil)
  if valid_598705 != nil:
    section.add "X-Amz-Date", valid_598705
  var valid_598706 = header.getOrDefault("X-Amz-Credential")
  valid_598706 = validateParameter(valid_598706, JString, required = false,
                                 default = nil)
  if valid_598706 != nil:
    section.add "X-Amz-Credential", valid_598706
  var valid_598707 = header.getOrDefault("X-Amz-Security-Token")
  valid_598707 = validateParameter(valid_598707, JString, required = false,
                                 default = nil)
  if valid_598707 != nil:
    section.add "X-Amz-Security-Token", valid_598707
  var valid_598708 = header.getOrDefault("X-Amz-Algorithm")
  valid_598708 = validateParameter(valid_598708, JString, required = false,
                                 default = nil)
  if valid_598708 != nil:
    section.add "X-Amz-Algorithm", valid_598708
  var valid_598709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598709 = validateParameter(valid_598709, JString, required = false,
                                 default = nil)
  if valid_598709 != nil:
    section.add "X-Amz-SignedHeaders", valid_598709
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598711: Call_UpdateDataSourcePermissions_598698; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the permissions to a data source.
  ## 
  let valid = call_598711.validator(path, query, header, formData, body)
  let scheme = call_598711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598711.url(scheme.get, call_598711.host, call_598711.base,
                         call_598711.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598711, url, valid)

proc call*(call_598712: Call_UpdateDataSourcePermissions_598698;
          DataSourceId: string; AwsAccountId: string; body: JsonNode): Recallable =
  ## updateDataSourcePermissions
  ## Updates the permissions to a data source.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account. 
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   body: JObject (required)
  var path_598713 = newJObject()
  var body_598714 = newJObject()
  add(path_598713, "DataSourceId", newJString(DataSourceId))
  add(path_598713, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_598714 = body
  result = call_598712.call(path_598713, nil, nil, nil, body_598714)

var updateDataSourcePermissions* = Call_UpdateDataSourcePermissions_598698(
    name: "updateDataSourcePermissions", meth: HttpMethod.HttpPost,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}/permissions",
    validator: validate_UpdateDataSourcePermissions_598699, base: "/",
    url: url_UpdateDataSourcePermissions_598700,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSourcePermissions_598683 = ref object of OpenApiRestCall_597389
proc url_DescribeDataSourcePermissions_598685(protocol: Scheme; host: string;
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

proc validate_DescribeDataSourcePermissions_598684(path: JsonNode; query: JsonNode;
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
  var valid_598686 = path.getOrDefault("DataSourceId")
  valid_598686 = validateParameter(valid_598686, JString, required = true,
                                 default = nil)
  if valid_598686 != nil:
    section.add "DataSourceId", valid_598686
  var valid_598687 = path.getOrDefault("AwsAccountId")
  valid_598687 = validateParameter(valid_598687, JString, required = true,
                                 default = nil)
  if valid_598687 != nil:
    section.add "AwsAccountId", valid_598687
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
  var valid_598688 = header.getOrDefault("X-Amz-Signature")
  valid_598688 = validateParameter(valid_598688, JString, required = false,
                                 default = nil)
  if valid_598688 != nil:
    section.add "X-Amz-Signature", valid_598688
  var valid_598689 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598689 = validateParameter(valid_598689, JString, required = false,
                                 default = nil)
  if valid_598689 != nil:
    section.add "X-Amz-Content-Sha256", valid_598689
  var valid_598690 = header.getOrDefault("X-Amz-Date")
  valid_598690 = validateParameter(valid_598690, JString, required = false,
                                 default = nil)
  if valid_598690 != nil:
    section.add "X-Amz-Date", valid_598690
  var valid_598691 = header.getOrDefault("X-Amz-Credential")
  valid_598691 = validateParameter(valid_598691, JString, required = false,
                                 default = nil)
  if valid_598691 != nil:
    section.add "X-Amz-Credential", valid_598691
  var valid_598692 = header.getOrDefault("X-Amz-Security-Token")
  valid_598692 = validateParameter(valid_598692, JString, required = false,
                                 default = nil)
  if valid_598692 != nil:
    section.add "X-Amz-Security-Token", valid_598692
  var valid_598693 = header.getOrDefault("X-Amz-Algorithm")
  valid_598693 = validateParameter(valid_598693, JString, required = false,
                                 default = nil)
  if valid_598693 != nil:
    section.add "X-Amz-Algorithm", valid_598693
  var valid_598694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598694 = validateParameter(valid_598694, JString, required = false,
                                 default = nil)
  if valid_598694 != nil:
    section.add "X-Amz-SignedHeaders", valid_598694
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598695: Call_DescribeDataSourcePermissions_598683; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes the resource permissions for a data source.
  ## 
  let valid = call_598695.validator(path, query, header, formData, body)
  let scheme = call_598695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598695.url(scheme.get, call_598695.host, call_598695.base,
                         call_598695.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598695, url, valid)

proc call*(call_598696: Call_DescribeDataSourcePermissions_598683;
          DataSourceId: string; AwsAccountId: string): Recallable =
  ## describeDataSourcePermissions
  ## Describes the resource permissions for a data source.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This ID is unique per AWS Region for each AWS account.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  var path_598697 = newJObject()
  add(path_598697, "DataSourceId", newJString(DataSourceId))
  add(path_598697, "AwsAccountId", newJString(AwsAccountId))
  result = call_598696.call(path_598697, nil, nil, nil, nil)

var describeDataSourcePermissions* = Call_DescribeDataSourcePermissions_598683(
    name: "describeDataSourcePermissions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}/permissions",
    validator: validate_DescribeDataSourcePermissions_598684, base: "/",
    url: url_DescribeDataSourcePermissions_598685,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIAMPolicyAssignment_598731 = ref object of OpenApiRestCall_597389
proc url_UpdateIAMPolicyAssignment_598733(protocol: Scheme; host: string;
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

proc validate_UpdateIAMPolicyAssignment_598732(path: JsonNode; query: JsonNode;
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
  var valid_598734 = path.getOrDefault("AwsAccountId")
  valid_598734 = validateParameter(valid_598734, JString, required = true,
                                 default = nil)
  if valid_598734 != nil:
    section.add "AwsAccountId", valid_598734
  var valid_598735 = path.getOrDefault("Namespace")
  valid_598735 = validateParameter(valid_598735, JString, required = true,
                                 default = nil)
  if valid_598735 != nil:
    section.add "Namespace", valid_598735
  var valid_598736 = path.getOrDefault("AssignmentName")
  valid_598736 = validateParameter(valid_598736, JString, required = true,
                                 default = nil)
  if valid_598736 != nil:
    section.add "AssignmentName", valid_598736
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
  var valid_598737 = header.getOrDefault("X-Amz-Signature")
  valid_598737 = validateParameter(valid_598737, JString, required = false,
                                 default = nil)
  if valid_598737 != nil:
    section.add "X-Amz-Signature", valid_598737
  var valid_598738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598738 = validateParameter(valid_598738, JString, required = false,
                                 default = nil)
  if valid_598738 != nil:
    section.add "X-Amz-Content-Sha256", valid_598738
  var valid_598739 = header.getOrDefault("X-Amz-Date")
  valid_598739 = validateParameter(valid_598739, JString, required = false,
                                 default = nil)
  if valid_598739 != nil:
    section.add "X-Amz-Date", valid_598739
  var valid_598740 = header.getOrDefault("X-Amz-Credential")
  valid_598740 = validateParameter(valid_598740, JString, required = false,
                                 default = nil)
  if valid_598740 != nil:
    section.add "X-Amz-Credential", valid_598740
  var valid_598741 = header.getOrDefault("X-Amz-Security-Token")
  valid_598741 = validateParameter(valid_598741, JString, required = false,
                                 default = nil)
  if valid_598741 != nil:
    section.add "X-Amz-Security-Token", valid_598741
  var valid_598742 = header.getOrDefault("X-Amz-Algorithm")
  valid_598742 = validateParameter(valid_598742, JString, required = false,
                                 default = nil)
  if valid_598742 != nil:
    section.add "X-Amz-Algorithm", valid_598742
  var valid_598743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598743 = validateParameter(valid_598743, JString, required = false,
                                 default = nil)
  if valid_598743 != nil:
    section.add "X-Amz-SignedHeaders", valid_598743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598745: Call_UpdateIAMPolicyAssignment_598731; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing IAM policy assignment. This operation updates only the optional parameter or parameters that are specified in the request.
  ## 
  let valid = call_598745.validator(path, query, header, formData, body)
  let scheme = call_598745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598745.url(scheme.get, call_598745.host, call_598745.base,
                         call_598745.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598745, url, valid)

proc call*(call_598746: Call_UpdateIAMPolicyAssignment_598731;
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
  var path_598747 = newJObject()
  var body_598748 = newJObject()
  add(path_598747, "AwsAccountId", newJString(AwsAccountId))
  add(path_598747, "Namespace", newJString(Namespace))
  add(path_598747, "AssignmentName", newJString(AssignmentName))
  if body != nil:
    body_598748 = body
  result = call_598746.call(path_598747, nil, nil, nil, body_598748)

var updateIAMPolicyAssignment* = Call_UpdateIAMPolicyAssignment_598731(
    name: "updateIAMPolicyAssignment", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/{AssignmentName}",
    validator: validate_UpdateIAMPolicyAssignment_598732, base: "/",
    url: url_UpdateIAMPolicyAssignment_598733,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIAMPolicyAssignment_598715 = ref object of OpenApiRestCall_597389
proc url_DescribeIAMPolicyAssignment_598717(protocol: Scheme; host: string;
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

proc validate_DescribeIAMPolicyAssignment_598716(path: JsonNode; query: JsonNode;
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
  var valid_598718 = path.getOrDefault("AwsAccountId")
  valid_598718 = validateParameter(valid_598718, JString, required = true,
                                 default = nil)
  if valid_598718 != nil:
    section.add "AwsAccountId", valid_598718
  var valid_598719 = path.getOrDefault("Namespace")
  valid_598719 = validateParameter(valid_598719, JString, required = true,
                                 default = nil)
  if valid_598719 != nil:
    section.add "Namespace", valid_598719
  var valid_598720 = path.getOrDefault("AssignmentName")
  valid_598720 = validateParameter(valid_598720, JString, required = true,
                                 default = nil)
  if valid_598720 != nil:
    section.add "AssignmentName", valid_598720
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
  var valid_598721 = header.getOrDefault("X-Amz-Signature")
  valid_598721 = validateParameter(valid_598721, JString, required = false,
                                 default = nil)
  if valid_598721 != nil:
    section.add "X-Amz-Signature", valid_598721
  var valid_598722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598722 = validateParameter(valid_598722, JString, required = false,
                                 default = nil)
  if valid_598722 != nil:
    section.add "X-Amz-Content-Sha256", valid_598722
  var valid_598723 = header.getOrDefault("X-Amz-Date")
  valid_598723 = validateParameter(valid_598723, JString, required = false,
                                 default = nil)
  if valid_598723 != nil:
    section.add "X-Amz-Date", valid_598723
  var valid_598724 = header.getOrDefault("X-Amz-Credential")
  valid_598724 = validateParameter(valid_598724, JString, required = false,
                                 default = nil)
  if valid_598724 != nil:
    section.add "X-Amz-Credential", valid_598724
  var valid_598725 = header.getOrDefault("X-Amz-Security-Token")
  valid_598725 = validateParameter(valid_598725, JString, required = false,
                                 default = nil)
  if valid_598725 != nil:
    section.add "X-Amz-Security-Token", valid_598725
  var valid_598726 = header.getOrDefault("X-Amz-Algorithm")
  valid_598726 = validateParameter(valid_598726, JString, required = false,
                                 default = nil)
  if valid_598726 != nil:
    section.add "X-Amz-Algorithm", valid_598726
  var valid_598727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598727 = validateParameter(valid_598727, JString, required = false,
                                 default = nil)
  if valid_598727 != nil:
    section.add "X-Amz-SignedHeaders", valid_598727
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598728: Call_DescribeIAMPolicyAssignment_598715; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes an existing IAM policy assignment, as specified by the assignment name.
  ## 
  let valid = call_598728.validator(path, query, header, formData, body)
  let scheme = call_598728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598728.url(scheme.get, call_598728.host, call_598728.base,
                         call_598728.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598728, url, valid)

proc call*(call_598729: Call_DescribeIAMPolicyAssignment_598715;
          AwsAccountId: string; Namespace: string; AssignmentName: string): Recallable =
  ## describeIAMPolicyAssignment
  ## Describes an existing IAM policy assignment, as specified by the assignment name.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the assignment that you want to describe.
  ##   Namespace: string (required)
  ##            : The namespace that contains the assignment.
  ##   AssignmentName: string (required)
  ##                 : The name of the assignment. 
  var path_598730 = newJObject()
  add(path_598730, "AwsAccountId", newJString(AwsAccountId))
  add(path_598730, "Namespace", newJString(Namespace))
  add(path_598730, "AssignmentName", newJString(AssignmentName))
  result = call_598729.call(path_598730, nil, nil, nil, nil)

var describeIAMPolicyAssignment* = Call_DescribeIAMPolicyAssignment_598715(
    name: "describeIAMPolicyAssignment", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/{AssignmentName}",
    validator: validate_DescribeIAMPolicyAssignment_598716, base: "/",
    url: url_DescribeIAMPolicyAssignment_598717,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTemplatePermissions_598764 = ref object of OpenApiRestCall_597389
proc url_UpdateTemplatePermissions_598766(protocol: Scheme; host: string;
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

proc validate_UpdateTemplatePermissions_598765(path: JsonNode; query: JsonNode;
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
  var valid_598767 = path.getOrDefault("AwsAccountId")
  valid_598767 = validateParameter(valid_598767, JString, required = true,
                                 default = nil)
  if valid_598767 != nil:
    section.add "AwsAccountId", valid_598767
  var valid_598768 = path.getOrDefault("TemplateId")
  valid_598768 = validateParameter(valid_598768, JString, required = true,
                                 default = nil)
  if valid_598768 != nil:
    section.add "TemplateId", valid_598768
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
  var valid_598769 = header.getOrDefault("X-Amz-Signature")
  valid_598769 = validateParameter(valid_598769, JString, required = false,
                                 default = nil)
  if valid_598769 != nil:
    section.add "X-Amz-Signature", valid_598769
  var valid_598770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598770 = validateParameter(valid_598770, JString, required = false,
                                 default = nil)
  if valid_598770 != nil:
    section.add "X-Amz-Content-Sha256", valid_598770
  var valid_598771 = header.getOrDefault("X-Amz-Date")
  valid_598771 = validateParameter(valid_598771, JString, required = false,
                                 default = nil)
  if valid_598771 != nil:
    section.add "X-Amz-Date", valid_598771
  var valid_598772 = header.getOrDefault("X-Amz-Credential")
  valid_598772 = validateParameter(valid_598772, JString, required = false,
                                 default = nil)
  if valid_598772 != nil:
    section.add "X-Amz-Credential", valid_598772
  var valid_598773 = header.getOrDefault("X-Amz-Security-Token")
  valid_598773 = validateParameter(valid_598773, JString, required = false,
                                 default = nil)
  if valid_598773 != nil:
    section.add "X-Amz-Security-Token", valid_598773
  var valid_598774 = header.getOrDefault("X-Amz-Algorithm")
  valid_598774 = validateParameter(valid_598774, JString, required = false,
                                 default = nil)
  if valid_598774 != nil:
    section.add "X-Amz-Algorithm", valid_598774
  var valid_598775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598775 = validateParameter(valid_598775, JString, required = false,
                                 default = nil)
  if valid_598775 != nil:
    section.add "X-Amz-SignedHeaders", valid_598775
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598777: Call_UpdateTemplatePermissions_598764; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the resource permissions for a template.
  ## 
  let valid = call_598777.validator(path, query, header, formData, body)
  let scheme = call_598777.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598777.url(scheme.get, call_598777.host, call_598777.base,
                         call_598777.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598777, url, valid)

proc call*(call_598778: Call_UpdateTemplatePermissions_598764;
          AwsAccountId: string; TemplateId: string; body: JsonNode): Recallable =
  ## updateTemplatePermissions
  ## Updates the resource permissions for a template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  ##   body: JObject (required)
  var path_598779 = newJObject()
  var body_598780 = newJObject()
  add(path_598779, "AwsAccountId", newJString(AwsAccountId))
  add(path_598779, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_598780 = body
  result = call_598778.call(path_598779, nil, nil, nil, body_598780)

var updateTemplatePermissions* = Call_UpdateTemplatePermissions_598764(
    name: "updateTemplatePermissions", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}/permissions",
    validator: validate_UpdateTemplatePermissions_598765, base: "/",
    url: url_UpdateTemplatePermissions_598766,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTemplatePermissions_598749 = ref object of OpenApiRestCall_597389
proc url_DescribeTemplatePermissions_598751(protocol: Scheme; host: string;
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

proc validate_DescribeTemplatePermissions_598750(path: JsonNode; query: JsonNode;
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
  var valid_598752 = path.getOrDefault("AwsAccountId")
  valid_598752 = validateParameter(valid_598752, JString, required = true,
                                 default = nil)
  if valid_598752 != nil:
    section.add "AwsAccountId", valid_598752
  var valid_598753 = path.getOrDefault("TemplateId")
  valid_598753 = validateParameter(valid_598753, JString, required = true,
                                 default = nil)
  if valid_598753 != nil:
    section.add "TemplateId", valid_598753
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
  var valid_598754 = header.getOrDefault("X-Amz-Signature")
  valid_598754 = validateParameter(valid_598754, JString, required = false,
                                 default = nil)
  if valid_598754 != nil:
    section.add "X-Amz-Signature", valid_598754
  var valid_598755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598755 = validateParameter(valid_598755, JString, required = false,
                                 default = nil)
  if valid_598755 != nil:
    section.add "X-Amz-Content-Sha256", valid_598755
  var valid_598756 = header.getOrDefault("X-Amz-Date")
  valid_598756 = validateParameter(valid_598756, JString, required = false,
                                 default = nil)
  if valid_598756 != nil:
    section.add "X-Amz-Date", valid_598756
  var valid_598757 = header.getOrDefault("X-Amz-Credential")
  valid_598757 = validateParameter(valid_598757, JString, required = false,
                                 default = nil)
  if valid_598757 != nil:
    section.add "X-Amz-Credential", valid_598757
  var valid_598758 = header.getOrDefault("X-Amz-Security-Token")
  valid_598758 = validateParameter(valid_598758, JString, required = false,
                                 default = nil)
  if valid_598758 != nil:
    section.add "X-Amz-Security-Token", valid_598758
  var valid_598759 = header.getOrDefault("X-Amz-Algorithm")
  valid_598759 = validateParameter(valid_598759, JString, required = false,
                                 default = nil)
  if valid_598759 != nil:
    section.add "X-Amz-Algorithm", valid_598759
  var valid_598760 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598760 = validateParameter(valid_598760, JString, required = false,
                                 default = nil)
  if valid_598760 != nil:
    section.add "X-Amz-SignedHeaders", valid_598760
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598761: Call_DescribeTemplatePermissions_598749; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes read and write permissions on a template.
  ## 
  let valid = call_598761.validator(path, query, header, formData, body)
  let scheme = call_598761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598761.url(scheme.get, call_598761.host, call_598761.base,
                         call_598761.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598761, url, valid)

proc call*(call_598762: Call_DescribeTemplatePermissions_598749;
          AwsAccountId: string; TemplateId: string): Recallable =
  ## describeTemplatePermissions
  ## Describes read and write permissions on a template.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the template that you're describing.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  var path_598763 = newJObject()
  add(path_598763, "AwsAccountId", newJString(AwsAccountId))
  add(path_598763, "TemplateId", newJString(TemplateId))
  result = call_598762.call(path_598763, nil, nil, nil, nil)

var describeTemplatePermissions* = Call_DescribeTemplatePermissions_598749(
    name: "describeTemplatePermissions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}/permissions",
    validator: validate_DescribeTemplatePermissions_598750, base: "/",
    url: url_DescribeTemplatePermissions_598751,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDashboardEmbedUrl_598781 = ref object of OpenApiRestCall_597389
proc url_GetDashboardEmbedUrl_598783(protocol: Scheme; host: string; base: string;
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

proc validate_GetDashboardEmbedUrl_598782(path: JsonNode; query: JsonNode;
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
  var valid_598784 = path.getOrDefault("AwsAccountId")
  valid_598784 = validateParameter(valid_598784, JString, required = true,
                                 default = nil)
  if valid_598784 != nil:
    section.add "AwsAccountId", valid_598784
  var valid_598785 = path.getOrDefault("DashboardId")
  valid_598785 = validateParameter(valid_598785, JString, required = true,
                                 default = nil)
  if valid_598785 != nil:
    section.add "DashboardId", valid_598785
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
  var valid_598786 = query.getOrDefault("reset-disabled")
  valid_598786 = validateParameter(valid_598786, JBool, required = false, default = nil)
  if valid_598786 != nil:
    section.add "reset-disabled", valid_598786
  assert query != nil,
        "query argument is necessary due to required `creds-type` field"
  var valid_598800 = query.getOrDefault("creds-type")
  valid_598800 = validateParameter(valid_598800, JString, required = true,
                                 default = newJString("IAM"))
  if valid_598800 != nil:
    section.add "creds-type", valid_598800
  var valid_598801 = query.getOrDefault("user-arn")
  valid_598801 = validateParameter(valid_598801, JString, required = false,
                                 default = nil)
  if valid_598801 != nil:
    section.add "user-arn", valid_598801
  var valid_598802 = query.getOrDefault("session-lifetime")
  valid_598802 = validateParameter(valid_598802, JInt, required = false, default = nil)
  if valid_598802 != nil:
    section.add "session-lifetime", valid_598802
  var valid_598803 = query.getOrDefault("undo-redo-disabled")
  valid_598803 = validateParameter(valid_598803, JBool, required = false, default = nil)
  if valid_598803 != nil:
    section.add "undo-redo-disabled", valid_598803
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_598804 = header.getOrDefault("X-Amz-Signature")
  valid_598804 = validateParameter(valid_598804, JString, required = false,
                                 default = nil)
  if valid_598804 != nil:
    section.add "X-Amz-Signature", valid_598804
  var valid_598805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598805 = validateParameter(valid_598805, JString, required = false,
                                 default = nil)
  if valid_598805 != nil:
    section.add "X-Amz-Content-Sha256", valid_598805
  var valid_598806 = header.getOrDefault("X-Amz-Date")
  valid_598806 = validateParameter(valid_598806, JString, required = false,
                                 default = nil)
  if valid_598806 != nil:
    section.add "X-Amz-Date", valid_598806
  var valid_598807 = header.getOrDefault("X-Amz-Credential")
  valid_598807 = validateParameter(valid_598807, JString, required = false,
                                 default = nil)
  if valid_598807 != nil:
    section.add "X-Amz-Credential", valid_598807
  var valid_598808 = header.getOrDefault("X-Amz-Security-Token")
  valid_598808 = validateParameter(valid_598808, JString, required = false,
                                 default = nil)
  if valid_598808 != nil:
    section.add "X-Amz-Security-Token", valid_598808
  var valid_598809 = header.getOrDefault("X-Amz-Algorithm")
  valid_598809 = validateParameter(valid_598809, JString, required = false,
                                 default = nil)
  if valid_598809 != nil:
    section.add "X-Amz-Algorithm", valid_598809
  var valid_598810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598810 = validateParameter(valid_598810, JString, required = false,
                                 default = nil)
  if valid_598810 != nil:
    section.add "X-Amz-SignedHeaders", valid_598810
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598811: Call_GetDashboardEmbedUrl_598781; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Generates a server-side embeddable URL and authorization code. For this process to work properly, first configure the dashboards and user permissions. For more information, see <a href="https://docs.aws.amazon.com/quicksight/latest/user/embedding-dashboards.html">Embedding Amazon QuickSight Dashboards</a> in the <i>Amazon QuickSight User Guide</i> or <a href="https://docs.aws.amazon.com/quicksight/latest/APIReference/qs-dev-embedded-dashboards.html">Embedding Amazon QuickSight Dashboards</a> in the <i>Amazon QuickSight API Reference</i>.</p> <p>Currently, you can use <code>GetDashboardEmbedURL</code> only from the server, not from the user’s browser.</p>
  ## 
  let valid = call_598811.validator(path, query, header, formData, body)
  let scheme = call_598811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598811.url(scheme.get, call_598811.host, call_598811.base,
                         call_598811.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598811, url, valid)

proc call*(call_598812: Call_GetDashboardEmbedUrl_598781; AwsAccountId: string;
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
  var path_598813 = newJObject()
  var query_598814 = newJObject()
  add(query_598814, "reset-disabled", newJBool(resetDisabled))
  add(path_598813, "AwsAccountId", newJString(AwsAccountId))
  add(query_598814, "creds-type", newJString(credsType))
  add(query_598814, "user-arn", newJString(userArn))
  add(path_598813, "DashboardId", newJString(DashboardId))
  add(query_598814, "session-lifetime", newJInt(sessionLifetime))
  add(query_598814, "undo-redo-disabled", newJBool(undoRedoDisabled))
  result = call_598812.call(path_598813, query_598814, nil, nil, nil)

var getDashboardEmbedUrl* = Call_GetDashboardEmbedUrl_598781(
    name: "getDashboardEmbedUrl", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/embed-url#creds-type",
    validator: validate_GetDashboardEmbedUrl_598782, base: "/",
    url: url_GetDashboardEmbedUrl_598783, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDashboardVersions_598815 = ref object of OpenApiRestCall_597389
proc url_ListDashboardVersions_598817(protocol: Scheme; host: string; base: string;
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

proc validate_ListDashboardVersions_598816(path: JsonNode; query: JsonNode;
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
  var valid_598818 = path.getOrDefault("AwsAccountId")
  valid_598818 = validateParameter(valid_598818, JString, required = true,
                                 default = nil)
  if valid_598818 != nil:
    section.add "AwsAccountId", valid_598818
  var valid_598819 = path.getOrDefault("DashboardId")
  valid_598819 = validateParameter(valid_598819, JString, required = true,
                                 default = nil)
  if valid_598819 != nil:
    section.add "DashboardId", valid_598819
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
  var valid_598820 = query.getOrDefault("MaxResults")
  valid_598820 = validateParameter(valid_598820, JString, required = false,
                                 default = nil)
  if valid_598820 != nil:
    section.add "MaxResults", valid_598820
  var valid_598821 = query.getOrDefault("NextToken")
  valid_598821 = validateParameter(valid_598821, JString, required = false,
                                 default = nil)
  if valid_598821 != nil:
    section.add "NextToken", valid_598821
  var valid_598822 = query.getOrDefault("max-results")
  valid_598822 = validateParameter(valid_598822, JInt, required = false, default = nil)
  if valid_598822 != nil:
    section.add "max-results", valid_598822
  var valid_598823 = query.getOrDefault("next-token")
  valid_598823 = validateParameter(valid_598823, JString, required = false,
                                 default = nil)
  if valid_598823 != nil:
    section.add "next-token", valid_598823
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_598824 = header.getOrDefault("X-Amz-Signature")
  valid_598824 = validateParameter(valid_598824, JString, required = false,
                                 default = nil)
  if valid_598824 != nil:
    section.add "X-Amz-Signature", valid_598824
  var valid_598825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598825 = validateParameter(valid_598825, JString, required = false,
                                 default = nil)
  if valid_598825 != nil:
    section.add "X-Amz-Content-Sha256", valid_598825
  var valid_598826 = header.getOrDefault("X-Amz-Date")
  valid_598826 = validateParameter(valid_598826, JString, required = false,
                                 default = nil)
  if valid_598826 != nil:
    section.add "X-Amz-Date", valid_598826
  var valid_598827 = header.getOrDefault("X-Amz-Credential")
  valid_598827 = validateParameter(valid_598827, JString, required = false,
                                 default = nil)
  if valid_598827 != nil:
    section.add "X-Amz-Credential", valid_598827
  var valid_598828 = header.getOrDefault("X-Amz-Security-Token")
  valid_598828 = validateParameter(valid_598828, JString, required = false,
                                 default = nil)
  if valid_598828 != nil:
    section.add "X-Amz-Security-Token", valid_598828
  var valid_598829 = header.getOrDefault("X-Amz-Algorithm")
  valid_598829 = validateParameter(valid_598829, JString, required = false,
                                 default = nil)
  if valid_598829 != nil:
    section.add "X-Amz-Algorithm", valid_598829
  var valid_598830 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598830 = validateParameter(valid_598830, JString, required = false,
                                 default = nil)
  if valid_598830 != nil:
    section.add "X-Amz-SignedHeaders", valid_598830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598831: Call_ListDashboardVersions_598815; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the versions of the dashboards in the QuickSight subscription.
  ## 
  let valid = call_598831.validator(path, query, header, formData, body)
  let scheme = call_598831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598831.url(scheme.get, call_598831.host, call_598831.base,
                         call_598831.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598831, url, valid)

proc call*(call_598832: Call_ListDashboardVersions_598815; AwsAccountId: string;
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
  var path_598833 = newJObject()
  var query_598834 = newJObject()
  add(path_598833, "AwsAccountId", newJString(AwsAccountId))
  add(query_598834, "MaxResults", newJString(MaxResults))
  add(query_598834, "NextToken", newJString(NextToken))
  add(query_598834, "max-results", newJInt(maxResults))
  add(path_598833, "DashboardId", newJString(DashboardId))
  add(query_598834, "next-token", newJString(nextToken))
  result = call_598832.call(path_598833, query_598834, nil, nil, nil)

var listDashboardVersions* = Call_ListDashboardVersions_598815(
    name: "listDashboardVersions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/versions",
    validator: validate_ListDashboardVersions_598816, base: "/",
    url: url_ListDashboardVersions_598817, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDashboards_598835 = ref object of OpenApiRestCall_597389
proc url_ListDashboards_598837(protocol: Scheme; host: string; base: string;
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

proc validate_ListDashboards_598836(path: JsonNode; query: JsonNode;
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
  var valid_598838 = path.getOrDefault("AwsAccountId")
  valid_598838 = validateParameter(valid_598838, JString, required = true,
                                 default = nil)
  if valid_598838 != nil:
    section.add "AwsAccountId", valid_598838
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
  var valid_598839 = query.getOrDefault("MaxResults")
  valid_598839 = validateParameter(valid_598839, JString, required = false,
                                 default = nil)
  if valid_598839 != nil:
    section.add "MaxResults", valid_598839
  var valid_598840 = query.getOrDefault("NextToken")
  valid_598840 = validateParameter(valid_598840, JString, required = false,
                                 default = nil)
  if valid_598840 != nil:
    section.add "NextToken", valid_598840
  var valid_598841 = query.getOrDefault("max-results")
  valid_598841 = validateParameter(valid_598841, JInt, required = false, default = nil)
  if valid_598841 != nil:
    section.add "max-results", valid_598841
  var valid_598842 = query.getOrDefault("next-token")
  valid_598842 = validateParameter(valid_598842, JString, required = false,
                                 default = nil)
  if valid_598842 != nil:
    section.add "next-token", valid_598842
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_598843 = header.getOrDefault("X-Amz-Signature")
  valid_598843 = validateParameter(valid_598843, JString, required = false,
                                 default = nil)
  if valid_598843 != nil:
    section.add "X-Amz-Signature", valid_598843
  var valid_598844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598844 = validateParameter(valid_598844, JString, required = false,
                                 default = nil)
  if valid_598844 != nil:
    section.add "X-Amz-Content-Sha256", valid_598844
  var valid_598845 = header.getOrDefault("X-Amz-Date")
  valid_598845 = validateParameter(valid_598845, JString, required = false,
                                 default = nil)
  if valid_598845 != nil:
    section.add "X-Amz-Date", valid_598845
  var valid_598846 = header.getOrDefault("X-Amz-Credential")
  valid_598846 = validateParameter(valid_598846, JString, required = false,
                                 default = nil)
  if valid_598846 != nil:
    section.add "X-Amz-Credential", valid_598846
  var valid_598847 = header.getOrDefault("X-Amz-Security-Token")
  valid_598847 = validateParameter(valid_598847, JString, required = false,
                                 default = nil)
  if valid_598847 != nil:
    section.add "X-Amz-Security-Token", valid_598847
  var valid_598848 = header.getOrDefault("X-Amz-Algorithm")
  valid_598848 = validateParameter(valid_598848, JString, required = false,
                                 default = nil)
  if valid_598848 != nil:
    section.add "X-Amz-Algorithm", valid_598848
  var valid_598849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598849 = validateParameter(valid_598849, JString, required = false,
                                 default = nil)
  if valid_598849 != nil:
    section.add "X-Amz-SignedHeaders", valid_598849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598850: Call_ListDashboards_598835; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists dashboards in an AWS account.
  ## 
  let valid = call_598850.validator(path, query, header, formData, body)
  let scheme = call_598850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598850.url(scheme.get, call_598850.host, call_598850.base,
                         call_598850.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598850, url, valid)

proc call*(call_598851: Call_ListDashboards_598835; AwsAccountId: string;
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
  var path_598852 = newJObject()
  var query_598853 = newJObject()
  add(path_598852, "AwsAccountId", newJString(AwsAccountId))
  add(query_598853, "MaxResults", newJString(MaxResults))
  add(query_598853, "NextToken", newJString(NextToken))
  add(query_598853, "max-results", newJInt(maxResults))
  add(query_598853, "next-token", newJString(nextToken))
  result = call_598851.call(path_598852, query_598853, nil, nil, nil)

var listDashboards* = Call_ListDashboards_598835(name: "listDashboards",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards",
    validator: validate_ListDashboards_598836, base: "/", url: url_ListDashboards_598837,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupMemberships_598854 = ref object of OpenApiRestCall_597389
proc url_ListGroupMemberships_598856(protocol: Scheme; host: string; base: string;
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

proc validate_ListGroupMemberships_598855(path: JsonNode; query: JsonNode;
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
  var valid_598857 = path.getOrDefault("GroupName")
  valid_598857 = validateParameter(valid_598857, JString, required = true,
                                 default = nil)
  if valid_598857 != nil:
    section.add "GroupName", valid_598857
  var valid_598858 = path.getOrDefault("AwsAccountId")
  valid_598858 = validateParameter(valid_598858, JString, required = true,
                                 default = nil)
  if valid_598858 != nil:
    section.add "AwsAccountId", valid_598858
  var valid_598859 = path.getOrDefault("Namespace")
  valid_598859 = validateParameter(valid_598859, JString, required = true,
                                 default = nil)
  if valid_598859 != nil:
    section.add "Namespace", valid_598859
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return from this request.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_598860 = query.getOrDefault("max-results")
  valid_598860 = validateParameter(valid_598860, JInt, required = false, default = nil)
  if valid_598860 != nil:
    section.add "max-results", valid_598860
  var valid_598861 = query.getOrDefault("next-token")
  valid_598861 = validateParameter(valid_598861, JString, required = false,
                                 default = nil)
  if valid_598861 != nil:
    section.add "next-token", valid_598861
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_598862 = header.getOrDefault("X-Amz-Signature")
  valid_598862 = validateParameter(valid_598862, JString, required = false,
                                 default = nil)
  if valid_598862 != nil:
    section.add "X-Amz-Signature", valid_598862
  var valid_598863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598863 = validateParameter(valid_598863, JString, required = false,
                                 default = nil)
  if valid_598863 != nil:
    section.add "X-Amz-Content-Sha256", valid_598863
  var valid_598864 = header.getOrDefault("X-Amz-Date")
  valid_598864 = validateParameter(valid_598864, JString, required = false,
                                 default = nil)
  if valid_598864 != nil:
    section.add "X-Amz-Date", valid_598864
  var valid_598865 = header.getOrDefault("X-Amz-Credential")
  valid_598865 = validateParameter(valid_598865, JString, required = false,
                                 default = nil)
  if valid_598865 != nil:
    section.add "X-Amz-Credential", valid_598865
  var valid_598866 = header.getOrDefault("X-Amz-Security-Token")
  valid_598866 = validateParameter(valid_598866, JString, required = false,
                                 default = nil)
  if valid_598866 != nil:
    section.add "X-Amz-Security-Token", valid_598866
  var valid_598867 = header.getOrDefault("X-Amz-Algorithm")
  valid_598867 = validateParameter(valid_598867, JString, required = false,
                                 default = nil)
  if valid_598867 != nil:
    section.add "X-Amz-Algorithm", valid_598867
  var valid_598868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598868 = validateParameter(valid_598868, JString, required = false,
                                 default = nil)
  if valid_598868 != nil:
    section.add "X-Amz-SignedHeaders", valid_598868
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598869: Call_ListGroupMemberships_598854; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists member users in a group.
  ## 
  let valid = call_598869.validator(path, query, header, formData, body)
  let scheme = call_598869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598869.url(scheme.get, call_598869.host, call_598869.base,
                         call_598869.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598869, url, valid)

proc call*(call_598870: Call_ListGroupMemberships_598854; GroupName: string;
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
  var path_598871 = newJObject()
  var query_598872 = newJObject()
  add(path_598871, "GroupName", newJString(GroupName))
  add(path_598871, "AwsAccountId", newJString(AwsAccountId))
  add(path_598871, "Namespace", newJString(Namespace))
  add(query_598872, "max-results", newJInt(maxResults))
  add(query_598872, "next-token", newJString(nextToken))
  result = call_598870.call(path_598871, query_598872, nil, nil, nil)

var listGroupMemberships* = Call_ListGroupMemberships_598854(
    name: "listGroupMemberships", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members",
    validator: validate_ListGroupMemberships_598855, base: "/",
    url: url_ListGroupMemberships_598856, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIAMPolicyAssignments_598873 = ref object of OpenApiRestCall_597389
proc url_ListIAMPolicyAssignments_598875(protocol: Scheme; host: string;
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

proc validate_ListIAMPolicyAssignments_598874(path: JsonNode; query: JsonNode;
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
  var valid_598876 = path.getOrDefault("AwsAccountId")
  valid_598876 = validateParameter(valid_598876, JString, required = true,
                                 default = nil)
  if valid_598876 != nil:
    section.add "AwsAccountId", valid_598876
  var valid_598877 = path.getOrDefault("Namespace")
  valid_598877 = validateParameter(valid_598877, JString, required = true,
                                 default = nil)
  if valid_598877 != nil:
    section.add "Namespace", valid_598877
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_598878 = query.getOrDefault("max-results")
  valid_598878 = validateParameter(valid_598878, JInt, required = false, default = nil)
  if valid_598878 != nil:
    section.add "max-results", valid_598878
  var valid_598879 = query.getOrDefault("next-token")
  valid_598879 = validateParameter(valid_598879, JString, required = false,
                                 default = nil)
  if valid_598879 != nil:
    section.add "next-token", valid_598879
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_598880 = header.getOrDefault("X-Amz-Signature")
  valid_598880 = validateParameter(valid_598880, JString, required = false,
                                 default = nil)
  if valid_598880 != nil:
    section.add "X-Amz-Signature", valid_598880
  var valid_598881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598881 = validateParameter(valid_598881, JString, required = false,
                                 default = nil)
  if valid_598881 != nil:
    section.add "X-Amz-Content-Sha256", valid_598881
  var valid_598882 = header.getOrDefault("X-Amz-Date")
  valid_598882 = validateParameter(valid_598882, JString, required = false,
                                 default = nil)
  if valid_598882 != nil:
    section.add "X-Amz-Date", valid_598882
  var valid_598883 = header.getOrDefault("X-Amz-Credential")
  valid_598883 = validateParameter(valid_598883, JString, required = false,
                                 default = nil)
  if valid_598883 != nil:
    section.add "X-Amz-Credential", valid_598883
  var valid_598884 = header.getOrDefault("X-Amz-Security-Token")
  valid_598884 = validateParameter(valid_598884, JString, required = false,
                                 default = nil)
  if valid_598884 != nil:
    section.add "X-Amz-Security-Token", valid_598884
  var valid_598885 = header.getOrDefault("X-Amz-Algorithm")
  valid_598885 = validateParameter(valid_598885, JString, required = false,
                                 default = nil)
  if valid_598885 != nil:
    section.add "X-Amz-Algorithm", valid_598885
  var valid_598886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598886 = validateParameter(valid_598886, JString, required = false,
                                 default = nil)
  if valid_598886 != nil:
    section.add "X-Amz-SignedHeaders", valid_598886
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598888: Call_ListIAMPolicyAssignments_598873; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists IAM policy assignments in the current Amazon QuickSight account.
  ## 
  let valid = call_598888.validator(path, query, header, formData, body)
  let scheme = call_598888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598888.url(scheme.get, call_598888.host, call_598888.base,
                         call_598888.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598888, url, valid)

proc call*(call_598889: Call_ListIAMPolicyAssignments_598873; AwsAccountId: string;
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
  var path_598890 = newJObject()
  var query_598891 = newJObject()
  var body_598892 = newJObject()
  add(path_598890, "AwsAccountId", newJString(AwsAccountId))
  add(path_598890, "Namespace", newJString(Namespace))
  add(query_598891, "max-results", newJInt(maxResults))
  if body != nil:
    body_598892 = body
  add(query_598891, "next-token", newJString(nextToken))
  result = call_598889.call(path_598890, query_598891, nil, nil, body_598892)

var listIAMPolicyAssignments* = Call_ListIAMPolicyAssignments_598873(
    name: "listIAMPolicyAssignments", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments",
    validator: validate_ListIAMPolicyAssignments_598874, base: "/",
    url: url_ListIAMPolicyAssignments_598875, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIAMPolicyAssignmentsForUser_598893 = ref object of OpenApiRestCall_597389
proc url_ListIAMPolicyAssignmentsForUser_598895(protocol: Scheme; host: string;
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

proc validate_ListIAMPolicyAssignmentsForUser_598894(path: JsonNode;
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
  var valid_598896 = path.getOrDefault("AwsAccountId")
  valid_598896 = validateParameter(valid_598896, JString, required = true,
                                 default = nil)
  if valid_598896 != nil:
    section.add "AwsAccountId", valid_598896
  var valid_598897 = path.getOrDefault("Namespace")
  valid_598897 = validateParameter(valid_598897, JString, required = true,
                                 default = nil)
  if valid_598897 != nil:
    section.add "Namespace", valid_598897
  var valid_598898 = path.getOrDefault("UserName")
  valid_598898 = validateParameter(valid_598898, JString, required = true,
                                 default = nil)
  if valid_598898 != nil:
    section.add "UserName", valid_598898
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_598899 = query.getOrDefault("max-results")
  valid_598899 = validateParameter(valid_598899, JInt, required = false, default = nil)
  if valid_598899 != nil:
    section.add "max-results", valid_598899
  var valid_598900 = query.getOrDefault("next-token")
  valid_598900 = validateParameter(valid_598900, JString, required = false,
                                 default = nil)
  if valid_598900 != nil:
    section.add "next-token", valid_598900
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_598901 = header.getOrDefault("X-Amz-Signature")
  valid_598901 = validateParameter(valid_598901, JString, required = false,
                                 default = nil)
  if valid_598901 != nil:
    section.add "X-Amz-Signature", valid_598901
  var valid_598902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598902 = validateParameter(valid_598902, JString, required = false,
                                 default = nil)
  if valid_598902 != nil:
    section.add "X-Amz-Content-Sha256", valid_598902
  var valid_598903 = header.getOrDefault("X-Amz-Date")
  valid_598903 = validateParameter(valid_598903, JString, required = false,
                                 default = nil)
  if valid_598903 != nil:
    section.add "X-Amz-Date", valid_598903
  var valid_598904 = header.getOrDefault("X-Amz-Credential")
  valid_598904 = validateParameter(valid_598904, JString, required = false,
                                 default = nil)
  if valid_598904 != nil:
    section.add "X-Amz-Credential", valid_598904
  var valid_598905 = header.getOrDefault("X-Amz-Security-Token")
  valid_598905 = validateParameter(valid_598905, JString, required = false,
                                 default = nil)
  if valid_598905 != nil:
    section.add "X-Amz-Security-Token", valid_598905
  var valid_598906 = header.getOrDefault("X-Amz-Algorithm")
  valid_598906 = validateParameter(valid_598906, JString, required = false,
                                 default = nil)
  if valid_598906 != nil:
    section.add "X-Amz-Algorithm", valid_598906
  var valid_598907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598907 = validateParameter(valid_598907, JString, required = false,
                                 default = nil)
  if valid_598907 != nil:
    section.add "X-Amz-SignedHeaders", valid_598907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598908: Call_ListIAMPolicyAssignmentsForUser_598893;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Lists all the IAM policy assignments, including the Amazon Resource Names (ARNs) for the IAM policies assigned to the specified user and group or groups that the user belongs to.
  ## 
  let valid = call_598908.validator(path, query, header, formData, body)
  let scheme = call_598908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598908.url(scheme.get, call_598908.host, call_598908.base,
                         call_598908.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598908, url, valid)

proc call*(call_598909: Call_ListIAMPolicyAssignmentsForUser_598893;
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
  var path_598910 = newJObject()
  var query_598911 = newJObject()
  add(path_598910, "AwsAccountId", newJString(AwsAccountId))
  add(path_598910, "Namespace", newJString(Namespace))
  add(path_598910, "UserName", newJString(UserName))
  add(query_598911, "max-results", newJInt(maxResults))
  add(query_598911, "next-token", newJString(nextToken))
  result = call_598909.call(path_598910, query_598911, nil, nil, nil)

var listIAMPolicyAssignmentsForUser* = Call_ListIAMPolicyAssignmentsForUser_598893(
    name: "listIAMPolicyAssignmentsForUser", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}/iam-policy-assignments",
    validator: validate_ListIAMPolicyAssignmentsForUser_598894, base: "/",
    url: url_ListIAMPolicyAssignmentsForUser_598895,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIngestions_598912 = ref object of OpenApiRestCall_597389
proc url_ListIngestions_598914(protocol: Scheme; host: string; base: string;
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

proc validate_ListIngestions_598913(path: JsonNode; query: JsonNode;
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
  var valid_598915 = path.getOrDefault("AwsAccountId")
  valid_598915 = validateParameter(valid_598915, JString, required = true,
                                 default = nil)
  if valid_598915 != nil:
    section.add "AwsAccountId", valid_598915
  var valid_598916 = path.getOrDefault("DataSetId")
  valid_598916 = validateParameter(valid_598916, JString, required = true,
                                 default = nil)
  if valid_598916 != nil:
    section.add "DataSetId", valid_598916
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
  var valid_598917 = query.getOrDefault("MaxResults")
  valid_598917 = validateParameter(valid_598917, JString, required = false,
                                 default = nil)
  if valid_598917 != nil:
    section.add "MaxResults", valid_598917
  var valid_598918 = query.getOrDefault("NextToken")
  valid_598918 = validateParameter(valid_598918, JString, required = false,
                                 default = nil)
  if valid_598918 != nil:
    section.add "NextToken", valid_598918
  var valid_598919 = query.getOrDefault("max-results")
  valid_598919 = validateParameter(valid_598919, JInt, required = false, default = nil)
  if valid_598919 != nil:
    section.add "max-results", valid_598919
  var valid_598920 = query.getOrDefault("next-token")
  valid_598920 = validateParameter(valid_598920, JString, required = false,
                                 default = nil)
  if valid_598920 != nil:
    section.add "next-token", valid_598920
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_598921 = header.getOrDefault("X-Amz-Signature")
  valid_598921 = validateParameter(valid_598921, JString, required = false,
                                 default = nil)
  if valid_598921 != nil:
    section.add "X-Amz-Signature", valid_598921
  var valid_598922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598922 = validateParameter(valid_598922, JString, required = false,
                                 default = nil)
  if valid_598922 != nil:
    section.add "X-Amz-Content-Sha256", valid_598922
  var valid_598923 = header.getOrDefault("X-Amz-Date")
  valid_598923 = validateParameter(valid_598923, JString, required = false,
                                 default = nil)
  if valid_598923 != nil:
    section.add "X-Amz-Date", valid_598923
  var valid_598924 = header.getOrDefault("X-Amz-Credential")
  valid_598924 = validateParameter(valid_598924, JString, required = false,
                                 default = nil)
  if valid_598924 != nil:
    section.add "X-Amz-Credential", valid_598924
  var valid_598925 = header.getOrDefault("X-Amz-Security-Token")
  valid_598925 = validateParameter(valid_598925, JString, required = false,
                                 default = nil)
  if valid_598925 != nil:
    section.add "X-Amz-Security-Token", valid_598925
  var valid_598926 = header.getOrDefault("X-Amz-Algorithm")
  valid_598926 = validateParameter(valid_598926, JString, required = false,
                                 default = nil)
  if valid_598926 != nil:
    section.add "X-Amz-Algorithm", valid_598926
  var valid_598927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598927 = validateParameter(valid_598927, JString, required = false,
                                 default = nil)
  if valid_598927 != nil:
    section.add "X-Amz-SignedHeaders", valid_598927
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598928: Call_ListIngestions_598912; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the history of SPICE ingestions for a dataset.
  ## 
  let valid = call_598928.validator(path, query, header, formData, body)
  let scheme = call_598928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598928.url(scheme.get, call_598928.host, call_598928.base,
                         call_598928.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598928, url, valid)

proc call*(call_598929: Call_ListIngestions_598912; AwsAccountId: string;
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
  var path_598930 = newJObject()
  var query_598931 = newJObject()
  add(path_598930, "AwsAccountId", newJString(AwsAccountId))
  add(query_598931, "MaxResults", newJString(MaxResults))
  add(query_598931, "NextToken", newJString(NextToken))
  add(path_598930, "DataSetId", newJString(DataSetId))
  add(query_598931, "max-results", newJInt(maxResults))
  add(query_598931, "next-token", newJString(nextToken))
  result = call_598929.call(path_598930, query_598931, nil, nil, nil)

var listIngestions* = Call_ListIngestions_598912(name: "listIngestions",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions",
    validator: validate_ListIngestions_598913, base: "/", url: url_ListIngestions_598914,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_598946 = ref object of OpenApiRestCall_597389
proc url_TagResource_598948(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_598947(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598949 = path.getOrDefault("ResourceArn")
  valid_598949 = validateParameter(valid_598949, JString, required = true,
                                 default = nil)
  if valid_598949 != nil:
    section.add "ResourceArn", valid_598949
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
  var valid_598950 = header.getOrDefault("X-Amz-Signature")
  valid_598950 = validateParameter(valid_598950, JString, required = false,
                                 default = nil)
  if valid_598950 != nil:
    section.add "X-Amz-Signature", valid_598950
  var valid_598951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598951 = validateParameter(valid_598951, JString, required = false,
                                 default = nil)
  if valid_598951 != nil:
    section.add "X-Amz-Content-Sha256", valid_598951
  var valid_598952 = header.getOrDefault("X-Amz-Date")
  valid_598952 = validateParameter(valid_598952, JString, required = false,
                                 default = nil)
  if valid_598952 != nil:
    section.add "X-Amz-Date", valid_598952
  var valid_598953 = header.getOrDefault("X-Amz-Credential")
  valid_598953 = validateParameter(valid_598953, JString, required = false,
                                 default = nil)
  if valid_598953 != nil:
    section.add "X-Amz-Credential", valid_598953
  var valid_598954 = header.getOrDefault("X-Amz-Security-Token")
  valid_598954 = validateParameter(valid_598954, JString, required = false,
                                 default = nil)
  if valid_598954 != nil:
    section.add "X-Amz-Security-Token", valid_598954
  var valid_598955 = header.getOrDefault("X-Amz-Algorithm")
  valid_598955 = validateParameter(valid_598955, JString, required = false,
                                 default = nil)
  if valid_598955 != nil:
    section.add "X-Amz-Algorithm", valid_598955
  var valid_598956 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598956 = validateParameter(valid_598956, JString, required = false,
                                 default = nil)
  if valid_598956 != nil:
    section.add "X-Amz-SignedHeaders", valid_598956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598958: Call_TagResource_598946; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns one or more tags (key-value pairs) to the specified QuickSight resource. </p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. You can use the <code>TagResource</code> operation with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource. QuickSight supports tagging on data set, data source, dashboard, and template. </p> <p>Tagging for QuickSight works in a similar way to tagging for other AWS services, except for the following:</p> <ul> <li> <p>You can't use tags to track AWS costs for QuickSight. This restriction is because QuickSight costs are based on users and SPICE capacity, which aren't taggable resources.</p> </li> <li> <p>QuickSight doesn't currently support the Tag Editor for AWS Resource Groups.</p> </li> </ul>
  ## 
  let valid = call_598958.validator(path, query, header, formData, body)
  let scheme = call_598958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598958.url(scheme.get, call_598958.host, call_598958.base,
                         call_598958.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598958, url, valid)

proc call*(call_598959: Call_TagResource_598946; ResourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Assigns one or more tags (key-value pairs) to the specified QuickSight resource. </p> <p>Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. You can use the <code>TagResource</code> operation with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource. QuickSight supports tagging on data set, data source, dashboard, and template. </p> <p>Tagging for QuickSight works in a similar way to tagging for other AWS services, except for the following:</p> <ul> <li> <p>You can't use tags to track AWS costs for QuickSight. This restriction is because QuickSight costs are based on users and SPICE capacity, which aren't taggable resources.</p> </li> <li> <p>QuickSight doesn't currently support the Tag Editor for AWS Resource Groups.</p> </li> </ul>
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to tag.
  ##   body: JObject (required)
  var path_598960 = newJObject()
  var body_598961 = newJObject()
  add(path_598960, "ResourceArn", newJString(ResourceArn))
  if body != nil:
    body_598961 = body
  result = call_598959.call(path_598960, nil, nil, nil, body_598961)

var tagResource* = Call_TagResource_598946(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "quicksight.amazonaws.com",
                                        route: "/resources/{ResourceArn}/tags",
                                        validator: validate_TagResource_598947,
                                        base: "/", url: url_TagResource_598948,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_598932 = ref object of OpenApiRestCall_597389
proc url_ListTagsForResource_598934(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_598933(path: JsonNode; query: JsonNode;
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
  var valid_598935 = path.getOrDefault("ResourceArn")
  valid_598935 = validateParameter(valid_598935, JString, required = true,
                                 default = nil)
  if valid_598935 != nil:
    section.add "ResourceArn", valid_598935
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
  var valid_598936 = header.getOrDefault("X-Amz-Signature")
  valid_598936 = validateParameter(valid_598936, JString, required = false,
                                 default = nil)
  if valid_598936 != nil:
    section.add "X-Amz-Signature", valid_598936
  var valid_598937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598937 = validateParameter(valid_598937, JString, required = false,
                                 default = nil)
  if valid_598937 != nil:
    section.add "X-Amz-Content-Sha256", valid_598937
  var valid_598938 = header.getOrDefault("X-Amz-Date")
  valid_598938 = validateParameter(valid_598938, JString, required = false,
                                 default = nil)
  if valid_598938 != nil:
    section.add "X-Amz-Date", valid_598938
  var valid_598939 = header.getOrDefault("X-Amz-Credential")
  valid_598939 = validateParameter(valid_598939, JString, required = false,
                                 default = nil)
  if valid_598939 != nil:
    section.add "X-Amz-Credential", valid_598939
  var valid_598940 = header.getOrDefault("X-Amz-Security-Token")
  valid_598940 = validateParameter(valid_598940, JString, required = false,
                                 default = nil)
  if valid_598940 != nil:
    section.add "X-Amz-Security-Token", valid_598940
  var valid_598941 = header.getOrDefault("X-Amz-Algorithm")
  valid_598941 = validateParameter(valid_598941, JString, required = false,
                                 default = nil)
  if valid_598941 != nil:
    section.add "X-Amz-Algorithm", valid_598941
  var valid_598942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598942 = validateParameter(valid_598942, JString, required = false,
                                 default = nil)
  if valid_598942 != nil:
    section.add "X-Amz-SignedHeaders", valid_598942
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598943: Call_ListTagsForResource_598932; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the tags assigned to a resource.
  ## 
  let valid = call_598943.validator(path, query, header, formData, body)
  let scheme = call_598943.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598943.url(scheme.get, call_598943.host, call_598943.base,
                         call_598943.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598943, url, valid)

proc call*(call_598944: Call_ListTagsForResource_598932; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists the tags assigned to a resource.
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want a list of tags for.
  var path_598945 = newJObject()
  add(path_598945, "ResourceArn", newJString(ResourceArn))
  result = call_598944.call(path_598945, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_598932(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/resources/{ResourceArn}/tags",
    validator: validate_ListTagsForResource_598933, base: "/",
    url: url_ListTagsForResource_598934, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplateAliases_598962 = ref object of OpenApiRestCall_597389
proc url_ListTemplateAliases_598964(protocol: Scheme; host: string; base: string;
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

proc validate_ListTemplateAliases_598963(path: JsonNode; query: JsonNode;
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
  var valid_598965 = path.getOrDefault("AwsAccountId")
  valid_598965 = validateParameter(valid_598965, JString, required = true,
                                 default = nil)
  if valid_598965 != nil:
    section.add "AwsAccountId", valid_598965
  var valid_598966 = path.getOrDefault("TemplateId")
  valid_598966 = validateParameter(valid_598966, JString, required = true,
                                 default = nil)
  if valid_598966 != nil:
    section.add "TemplateId", valid_598966
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
  var valid_598967 = query.getOrDefault("MaxResults")
  valid_598967 = validateParameter(valid_598967, JString, required = false,
                                 default = nil)
  if valid_598967 != nil:
    section.add "MaxResults", valid_598967
  var valid_598968 = query.getOrDefault("NextToken")
  valid_598968 = validateParameter(valid_598968, JString, required = false,
                                 default = nil)
  if valid_598968 != nil:
    section.add "NextToken", valid_598968
  var valid_598969 = query.getOrDefault("max-result")
  valid_598969 = validateParameter(valid_598969, JInt, required = false, default = nil)
  if valid_598969 != nil:
    section.add "max-result", valid_598969
  var valid_598970 = query.getOrDefault("next-token")
  valid_598970 = validateParameter(valid_598970, JString, required = false,
                                 default = nil)
  if valid_598970 != nil:
    section.add "next-token", valid_598970
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_598971 = header.getOrDefault("X-Amz-Signature")
  valid_598971 = validateParameter(valid_598971, JString, required = false,
                                 default = nil)
  if valid_598971 != nil:
    section.add "X-Amz-Signature", valid_598971
  var valid_598972 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598972 = validateParameter(valid_598972, JString, required = false,
                                 default = nil)
  if valid_598972 != nil:
    section.add "X-Amz-Content-Sha256", valid_598972
  var valid_598973 = header.getOrDefault("X-Amz-Date")
  valid_598973 = validateParameter(valid_598973, JString, required = false,
                                 default = nil)
  if valid_598973 != nil:
    section.add "X-Amz-Date", valid_598973
  var valid_598974 = header.getOrDefault("X-Amz-Credential")
  valid_598974 = validateParameter(valid_598974, JString, required = false,
                                 default = nil)
  if valid_598974 != nil:
    section.add "X-Amz-Credential", valid_598974
  var valid_598975 = header.getOrDefault("X-Amz-Security-Token")
  valid_598975 = validateParameter(valid_598975, JString, required = false,
                                 default = nil)
  if valid_598975 != nil:
    section.add "X-Amz-Security-Token", valid_598975
  var valid_598976 = header.getOrDefault("X-Amz-Algorithm")
  valid_598976 = validateParameter(valid_598976, JString, required = false,
                                 default = nil)
  if valid_598976 != nil:
    section.add "X-Amz-Algorithm", valid_598976
  var valid_598977 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598977 = validateParameter(valid_598977, JString, required = false,
                                 default = nil)
  if valid_598977 != nil:
    section.add "X-Amz-SignedHeaders", valid_598977
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598978: Call_ListTemplateAliases_598962; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the aliases of a template.
  ## 
  let valid = call_598978.validator(path, query, header, formData, body)
  let scheme = call_598978.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598978.url(scheme.get, call_598978.host, call_598978.base,
                         call_598978.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598978, url, valid)

proc call*(call_598979: Call_ListTemplateAliases_598962; AwsAccountId: string;
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
  var path_598980 = newJObject()
  var query_598981 = newJObject()
  add(path_598980, "AwsAccountId", newJString(AwsAccountId))
  add(query_598981, "MaxResults", newJString(MaxResults))
  add(query_598981, "NextToken", newJString(NextToken))
  add(query_598981, "max-result", newJInt(maxResult))
  add(path_598980, "TemplateId", newJString(TemplateId))
  add(query_598981, "next-token", newJString(nextToken))
  result = call_598979.call(path_598980, query_598981, nil, nil, nil)

var listTemplateAliases* = Call_ListTemplateAliases_598962(
    name: "listTemplateAliases", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases",
    validator: validate_ListTemplateAliases_598963, base: "/",
    url: url_ListTemplateAliases_598964, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplateVersions_598982 = ref object of OpenApiRestCall_597389
proc url_ListTemplateVersions_598984(protocol: Scheme; host: string; base: string;
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

proc validate_ListTemplateVersions_598983(path: JsonNode; query: JsonNode;
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
  var valid_598985 = path.getOrDefault("AwsAccountId")
  valid_598985 = validateParameter(valid_598985, JString, required = true,
                                 default = nil)
  if valid_598985 != nil:
    section.add "AwsAccountId", valid_598985
  var valid_598986 = path.getOrDefault("TemplateId")
  valid_598986 = validateParameter(valid_598986, JString, required = true,
                                 default = nil)
  if valid_598986 != nil:
    section.add "TemplateId", valid_598986
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
  var valid_598987 = query.getOrDefault("MaxResults")
  valid_598987 = validateParameter(valid_598987, JString, required = false,
                                 default = nil)
  if valid_598987 != nil:
    section.add "MaxResults", valid_598987
  var valid_598988 = query.getOrDefault("NextToken")
  valid_598988 = validateParameter(valid_598988, JString, required = false,
                                 default = nil)
  if valid_598988 != nil:
    section.add "NextToken", valid_598988
  var valid_598989 = query.getOrDefault("max-results")
  valid_598989 = validateParameter(valid_598989, JInt, required = false, default = nil)
  if valid_598989 != nil:
    section.add "max-results", valid_598989
  var valid_598990 = query.getOrDefault("next-token")
  valid_598990 = validateParameter(valid_598990, JString, required = false,
                                 default = nil)
  if valid_598990 != nil:
    section.add "next-token", valid_598990
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_598991 = header.getOrDefault("X-Amz-Signature")
  valid_598991 = validateParameter(valid_598991, JString, required = false,
                                 default = nil)
  if valid_598991 != nil:
    section.add "X-Amz-Signature", valid_598991
  var valid_598992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598992 = validateParameter(valid_598992, JString, required = false,
                                 default = nil)
  if valid_598992 != nil:
    section.add "X-Amz-Content-Sha256", valid_598992
  var valid_598993 = header.getOrDefault("X-Amz-Date")
  valid_598993 = validateParameter(valid_598993, JString, required = false,
                                 default = nil)
  if valid_598993 != nil:
    section.add "X-Amz-Date", valid_598993
  var valid_598994 = header.getOrDefault("X-Amz-Credential")
  valid_598994 = validateParameter(valid_598994, JString, required = false,
                                 default = nil)
  if valid_598994 != nil:
    section.add "X-Amz-Credential", valid_598994
  var valid_598995 = header.getOrDefault("X-Amz-Security-Token")
  valid_598995 = validateParameter(valid_598995, JString, required = false,
                                 default = nil)
  if valid_598995 != nil:
    section.add "X-Amz-Security-Token", valid_598995
  var valid_598996 = header.getOrDefault("X-Amz-Algorithm")
  valid_598996 = validateParameter(valid_598996, JString, required = false,
                                 default = nil)
  if valid_598996 != nil:
    section.add "X-Amz-Algorithm", valid_598996
  var valid_598997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598997 = validateParameter(valid_598997, JString, required = false,
                                 default = nil)
  if valid_598997 != nil:
    section.add "X-Amz-SignedHeaders", valid_598997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598998: Call_ListTemplateVersions_598982; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the versions of the templates in the current Amazon QuickSight account.
  ## 
  let valid = call_598998.validator(path, query, header, formData, body)
  let scheme = call_598998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598998.url(scheme.get, call_598998.host, call_598998.base,
                         call_598998.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598998, url, valid)

proc call*(call_598999: Call_ListTemplateVersions_598982; AwsAccountId: string;
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
  var path_599000 = newJObject()
  var query_599001 = newJObject()
  add(path_599000, "AwsAccountId", newJString(AwsAccountId))
  add(query_599001, "MaxResults", newJString(MaxResults))
  add(query_599001, "NextToken", newJString(NextToken))
  add(query_599001, "max-results", newJInt(maxResults))
  add(path_599000, "TemplateId", newJString(TemplateId))
  add(query_599001, "next-token", newJString(nextToken))
  result = call_598999.call(path_599000, query_599001, nil, nil, nil)

var listTemplateVersions* = Call_ListTemplateVersions_598982(
    name: "listTemplateVersions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}/versions",
    validator: validate_ListTemplateVersions_598983, base: "/",
    url: url_ListTemplateVersions_598984, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplates_599002 = ref object of OpenApiRestCall_597389
proc url_ListTemplates_599004(protocol: Scheme; host: string; base: string;
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

proc validate_ListTemplates_599003(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599005 = path.getOrDefault("AwsAccountId")
  valid_599005 = validateParameter(valid_599005, JString, required = true,
                                 default = nil)
  if valid_599005 != nil:
    section.add "AwsAccountId", valid_599005
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
  var valid_599006 = query.getOrDefault("MaxResults")
  valid_599006 = validateParameter(valid_599006, JString, required = false,
                                 default = nil)
  if valid_599006 != nil:
    section.add "MaxResults", valid_599006
  var valid_599007 = query.getOrDefault("NextToken")
  valid_599007 = validateParameter(valid_599007, JString, required = false,
                                 default = nil)
  if valid_599007 != nil:
    section.add "NextToken", valid_599007
  var valid_599008 = query.getOrDefault("max-result")
  valid_599008 = validateParameter(valid_599008, JInt, required = false, default = nil)
  if valid_599008 != nil:
    section.add "max-result", valid_599008
  var valid_599009 = query.getOrDefault("next-token")
  valid_599009 = validateParameter(valid_599009, JString, required = false,
                                 default = nil)
  if valid_599009 != nil:
    section.add "next-token", valid_599009
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_599010 = header.getOrDefault("X-Amz-Signature")
  valid_599010 = validateParameter(valid_599010, JString, required = false,
                                 default = nil)
  if valid_599010 != nil:
    section.add "X-Amz-Signature", valid_599010
  var valid_599011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599011 = validateParameter(valid_599011, JString, required = false,
                                 default = nil)
  if valid_599011 != nil:
    section.add "X-Amz-Content-Sha256", valid_599011
  var valid_599012 = header.getOrDefault("X-Amz-Date")
  valid_599012 = validateParameter(valid_599012, JString, required = false,
                                 default = nil)
  if valid_599012 != nil:
    section.add "X-Amz-Date", valid_599012
  var valid_599013 = header.getOrDefault("X-Amz-Credential")
  valid_599013 = validateParameter(valid_599013, JString, required = false,
                                 default = nil)
  if valid_599013 != nil:
    section.add "X-Amz-Credential", valid_599013
  var valid_599014 = header.getOrDefault("X-Amz-Security-Token")
  valid_599014 = validateParameter(valid_599014, JString, required = false,
                                 default = nil)
  if valid_599014 != nil:
    section.add "X-Amz-Security-Token", valid_599014
  var valid_599015 = header.getOrDefault("X-Amz-Algorithm")
  valid_599015 = validateParameter(valid_599015, JString, required = false,
                                 default = nil)
  if valid_599015 != nil:
    section.add "X-Amz-Algorithm", valid_599015
  var valid_599016 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599016 = validateParameter(valid_599016, JString, required = false,
                                 default = nil)
  if valid_599016 != nil:
    section.add "X-Amz-SignedHeaders", valid_599016
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599017: Call_ListTemplates_599002; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the templates in the current Amazon QuickSight account.
  ## 
  let valid = call_599017.validator(path, query, header, formData, body)
  let scheme = call_599017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599017.url(scheme.get, call_599017.host, call_599017.base,
                         call_599017.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599017, url, valid)

proc call*(call_599018: Call_ListTemplates_599002; AwsAccountId: string;
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
  var path_599019 = newJObject()
  var query_599020 = newJObject()
  add(path_599019, "AwsAccountId", newJString(AwsAccountId))
  add(query_599020, "MaxResults", newJString(MaxResults))
  add(query_599020, "NextToken", newJString(NextToken))
  add(query_599020, "max-result", newJInt(maxResult))
  add(query_599020, "next-token", newJString(nextToken))
  result = call_599018.call(path_599019, query_599020, nil, nil, nil)

var listTemplates* = Call_ListTemplates_599002(name: "listTemplates",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates",
    validator: validate_ListTemplates_599003, base: "/", url: url_ListTemplates_599004,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserGroups_599021 = ref object of OpenApiRestCall_597389
proc url_ListUserGroups_599023(protocol: Scheme; host: string; base: string;
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

proc validate_ListUserGroups_599022(path: JsonNode; query: JsonNode;
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
  var valid_599024 = path.getOrDefault("AwsAccountId")
  valid_599024 = validateParameter(valid_599024, JString, required = true,
                                 default = nil)
  if valid_599024 != nil:
    section.add "AwsAccountId", valid_599024
  var valid_599025 = path.getOrDefault("Namespace")
  valid_599025 = validateParameter(valid_599025, JString, required = true,
                                 default = nil)
  if valid_599025 != nil:
    section.add "Namespace", valid_599025
  var valid_599026 = path.getOrDefault("UserName")
  valid_599026 = validateParameter(valid_599026, JString, required = true,
                                 default = nil)
  if valid_599026 != nil:
    section.add "UserName", valid_599026
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return from this request.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_599027 = query.getOrDefault("max-results")
  valid_599027 = validateParameter(valid_599027, JInt, required = false, default = nil)
  if valid_599027 != nil:
    section.add "max-results", valid_599027
  var valid_599028 = query.getOrDefault("next-token")
  valid_599028 = validateParameter(valid_599028, JString, required = false,
                                 default = nil)
  if valid_599028 != nil:
    section.add "next-token", valid_599028
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_599029 = header.getOrDefault("X-Amz-Signature")
  valid_599029 = validateParameter(valid_599029, JString, required = false,
                                 default = nil)
  if valid_599029 != nil:
    section.add "X-Amz-Signature", valid_599029
  var valid_599030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599030 = validateParameter(valid_599030, JString, required = false,
                                 default = nil)
  if valid_599030 != nil:
    section.add "X-Amz-Content-Sha256", valid_599030
  var valid_599031 = header.getOrDefault("X-Amz-Date")
  valid_599031 = validateParameter(valid_599031, JString, required = false,
                                 default = nil)
  if valid_599031 != nil:
    section.add "X-Amz-Date", valid_599031
  var valid_599032 = header.getOrDefault("X-Amz-Credential")
  valid_599032 = validateParameter(valid_599032, JString, required = false,
                                 default = nil)
  if valid_599032 != nil:
    section.add "X-Amz-Credential", valid_599032
  var valid_599033 = header.getOrDefault("X-Amz-Security-Token")
  valid_599033 = validateParameter(valid_599033, JString, required = false,
                                 default = nil)
  if valid_599033 != nil:
    section.add "X-Amz-Security-Token", valid_599033
  var valid_599034 = header.getOrDefault("X-Amz-Algorithm")
  valid_599034 = validateParameter(valid_599034, JString, required = false,
                                 default = nil)
  if valid_599034 != nil:
    section.add "X-Amz-Algorithm", valid_599034
  var valid_599035 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599035 = validateParameter(valid_599035, JString, required = false,
                                 default = nil)
  if valid_599035 != nil:
    section.add "X-Amz-SignedHeaders", valid_599035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599036: Call_ListUserGroups_599021; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon QuickSight groups that an Amazon QuickSight user is a member of.
  ## 
  let valid = call_599036.validator(path, query, header, formData, body)
  let scheme = call_599036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599036.url(scheme.get, call_599036.host, call_599036.base,
                         call_599036.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599036, url, valid)

proc call*(call_599037: Call_ListUserGroups_599021; AwsAccountId: string;
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
  var path_599038 = newJObject()
  var query_599039 = newJObject()
  add(path_599038, "AwsAccountId", newJString(AwsAccountId))
  add(path_599038, "Namespace", newJString(Namespace))
  add(path_599038, "UserName", newJString(UserName))
  add(query_599039, "max-results", newJInt(maxResults))
  add(query_599039, "next-token", newJString(nextToken))
  result = call_599037.call(path_599038, query_599039, nil, nil, nil)

var listUserGroups* = Call_ListUserGroups_599021(name: "listUserGroups",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}/groups",
    validator: validate_ListUserGroups_599022, base: "/", url: url_ListUserGroups_599023,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterUser_599058 = ref object of OpenApiRestCall_597389
proc url_RegisterUser_599060(protocol: Scheme; host: string; base: string;
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

proc validate_RegisterUser_599059(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599061 = path.getOrDefault("AwsAccountId")
  valid_599061 = validateParameter(valid_599061, JString, required = true,
                                 default = nil)
  if valid_599061 != nil:
    section.add "AwsAccountId", valid_599061
  var valid_599062 = path.getOrDefault("Namespace")
  valid_599062 = validateParameter(valid_599062, JString, required = true,
                                 default = nil)
  if valid_599062 != nil:
    section.add "Namespace", valid_599062
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
  var valid_599063 = header.getOrDefault("X-Amz-Signature")
  valid_599063 = validateParameter(valid_599063, JString, required = false,
                                 default = nil)
  if valid_599063 != nil:
    section.add "X-Amz-Signature", valid_599063
  var valid_599064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599064 = validateParameter(valid_599064, JString, required = false,
                                 default = nil)
  if valid_599064 != nil:
    section.add "X-Amz-Content-Sha256", valid_599064
  var valid_599065 = header.getOrDefault("X-Amz-Date")
  valid_599065 = validateParameter(valid_599065, JString, required = false,
                                 default = nil)
  if valid_599065 != nil:
    section.add "X-Amz-Date", valid_599065
  var valid_599066 = header.getOrDefault("X-Amz-Credential")
  valid_599066 = validateParameter(valid_599066, JString, required = false,
                                 default = nil)
  if valid_599066 != nil:
    section.add "X-Amz-Credential", valid_599066
  var valid_599067 = header.getOrDefault("X-Amz-Security-Token")
  valid_599067 = validateParameter(valid_599067, JString, required = false,
                                 default = nil)
  if valid_599067 != nil:
    section.add "X-Amz-Security-Token", valid_599067
  var valid_599068 = header.getOrDefault("X-Amz-Algorithm")
  valid_599068 = validateParameter(valid_599068, JString, required = false,
                                 default = nil)
  if valid_599068 != nil:
    section.add "X-Amz-Algorithm", valid_599068
  var valid_599069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599069 = validateParameter(valid_599069, JString, required = false,
                                 default = nil)
  if valid_599069 != nil:
    section.add "X-Amz-SignedHeaders", valid_599069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599071: Call_RegisterUser_599058; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Amazon QuickSight user, whose identity is associated with the AWS Identity and Access Management (IAM) identity or role specified in the request. 
  ## 
  let valid = call_599071.validator(path, query, header, formData, body)
  let scheme = call_599071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599071.url(scheme.get, call_599071.host, call_599071.base,
                         call_599071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599071, url, valid)

proc call*(call_599072: Call_RegisterUser_599058; AwsAccountId: string;
          Namespace: string; body: JsonNode): Recallable =
  ## registerUser
  ## Creates an Amazon QuickSight user, whose identity is associated with the AWS Identity and Access Management (IAM) identity or role specified in the request. 
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  ##   body: JObject (required)
  var path_599073 = newJObject()
  var body_599074 = newJObject()
  add(path_599073, "AwsAccountId", newJString(AwsAccountId))
  add(path_599073, "Namespace", newJString(Namespace))
  if body != nil:
    body_599074 = body
  result = call_599072.call(path_599073, nil, nil, nil, body_599074)

var registerUser* = Call_RegisterUser_599058(name: "registerUser",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users",
    validator: validate_RegisterUser_599059, base: "/", url: url_RegisterUser_599060,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_599040 = ref object of OpenApiRestCall_597389
proc url_ListUsers_599042(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListUsers_599041(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599043 = path.getOrDefault("AwsAccountId")
  valid_599043 = validateParameter(valid_599043, JString, required = true,
                                 default = nil)
  if valid_599043 != nil:
    section.add "AwsAccountId", valid_599043
  var valid_599044 = path.getOrDefault("Namespace")
  valid_599044 = validateParameter(valid_599044, JString, required = true,
                                 default = nil)
  if valid_599044 != nil:
    section.add "Namespace", valid_599044
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return from this request.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_599045 = query.getOrDefault("max-results")
  valid_599045 = validateParameter(valid_599045, JInt, required = false, default = nil)
  if valid_599045 != nil:
    section.add "max-results", valid_599045
  var valid_599046 = query.getOrDefault("next-token")
  valid_599046 = validateParameter(valid_599046, JString, required = false,
                                 default = nil)
  if valid_599046 != nil:
    section.add "next-token", valid_599046
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_599047 = header.getOrDefault("X-Amz-Signature")
  valid_599047 = validateParameter(valid_599047, JString, required = false,
                                 default = nil)
  if valid_599047 != nil:
    section.add "X-Amz-Signature", valid_599047
  var valid_599048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599048 = validateParameter(valid_599048, JString, required = false,
                                 default = nil)
  if valid_599048 != nil:
    section.add "X-Amz-Content-Sha256", valid_599048
  var valid_599049 = header.getOrDefault("X-Amz-Date")
  valid_599049 = validateParameter(valid_599049, JString, required = false,
                                 default = nil)
  if valid_599049 != nil:
    section.add "X-Amz-Date", valid_599049
  var valid_599050 = header.getOrDefault("X-Amz-Credential")
  valid_599050 = validateParameter(valid_599050, JString, required = false,
                                 default = nil)
  if valid_599050 != nil:
    section.add "X-Amz-Credential", valid_599050
  var valid_599051 = header.getOrDefault("X-Amz-Security-Token")
  valid_599051 = validateParameter(valid_599051, JString, required = false,
                                 default = nil)
  if valid_599051 != nil:
    section.add "X-Amz-Security-Token", valid_599051
  var valid_599052 = header.getOrDefault("X-Amz-Algorithm")
  valid_599052 = validateParameter(valid_599052, JString, required = false,
                                 default = nil)
  if valid_599052 != nil:
    section.add "X-Amz-Algorithm", valid_599052
  var valid_599053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599053 = validateParameter(valid_599053, JString, required = false,
                                 default = nil)
  if valid_599053 != nil:
    section.add "X-Amz-SignedHeaders", valid_599053
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599054: Call_ListUsers_599040; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of all of the Amazon QuickSight users belonging to this account. 
  ## 
  let valid = call_599054.validator(path, query, header, formData, body)
  let scheme = call_599054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599054.url(scheme.get, call_599054.host, call_599054.base,
                         call_599054.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599054, url, valid)

proc call*(call_599055: Call_ListUsers_599040; AwsAccountId: string;
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
  var path_599056 = newJObject()
  var query_599057 = newJObject()
  add(path_599056, "AwsAccountId", newJString(AwsAccountId))
  add(path_599056, "Namespace", newJString(Namespace))
  add(query_599057, "max-results", newJInt(maxResults))
  add(query_599057, "next-token", newJString(nextToken))
  result = call_599055.call(path_599056, query_599057, nil, nil, nil)

var listUsers* = Call_ListUsers_599040(name: "listUsers", meth: HttpMethod.HttpGet,
                                    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users",
                                    validator: validate_ListUsers_599041,
                                    base: "/", url: url_ListUsers_599042,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_599075 = ref object of OpenApiRestCall_597389
proc url_UntagResource_599077(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_599076(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_599078 = path.getOrDefault("ResourceArn")
  valid_599078 = validateParameter(valid_599078, JString, required = true,
                                 default = nil)
  if valid_599078 != nil:
    section.add "ResourceArn", valid_599078
  result.add "path", section
  ## parameters in `query` object:
  ##   keys: JArray (required)
  ##       : The keys of the key-value pairs for the resource tag or tags assigned to the resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `keys` field"
  var valid_599079 = query.getOrDefault("keys")
  valid_599079 = validateParameter(valid_599079, JArray, required = true, default = nil)
  if valid_599079 != nil:
    section.add "keys", valid_599079
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_599080 = header.getOrDefault("X-Amz-Signature")
  valid_599080 = validateParameter(valid_599080, JString, required = false,
                                 default = nil)
  if valid_599080 != nil:
    section.add "X-Amz-Signature", valid_599080
  var valid_599081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599081 = validateParameter(valid_599081, JString, required = false,
                                 default = nil)
  if valid_599081 != nil:
    section.add "X-Amz-Content-Sha256", valid_599081
  var valid_599082 = header.getOrDefault("X-Amz-Date")
  valid_599082 = validateParameter(valid_599082, JString, required = false,
                                 default = nil)
  if valid_599082 != nil:
    section.add "X-Amz-Date", valid_599082
  var valid_599083 = header.getOrDefault("X-Amz-Credential")
  valid_599083 = validateParameter(valid_599083, JString, required = false,
                                 default = nil)
  if valid_599083 != nil:
    section.add "X-Amz-Credential", valid_599083
  var valid_599084 = header.getOrDefault("X-Amz-Security-Token")
  valid_599084 = validateParameter(valid_599084, JString, required = false,
                                 default = nil)
  if valid_599084 != nil:
    section.add "X-Amz-Security-Token", valid_599084
  var valid_599085 = header.getOrDefault("X-Amz-Algorithm")
  valid_599085 = validateParameter(valid_599085, JString, required = false,
                                 default = nil)
  if valid_599085 != nil:
    section.add "X-Amz-Algorithm", valid_599085
  var valid_599086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599086 = validateParameter(valid_599086, JString, required = false,
                                 default = nil)
  if valid_599086 != nil:
    section.add "X-Amz-SignedHeaders", valid_599086
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599087: Call_UntagResource_599075; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a tag or tags from a resource.
  ## 
  let valid = call_599087.validator(path, query, header, formData, body)
  let scheme = call_599087.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599087.url(scheme.get, call_599087.host, call_599087.base,
                         call_599087.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599087, url, valid)

proc call*(call_599088: Call_UntagResource_599075; keys: JsonNode;
          ResourceArn: string): Recallable =
  ## untagResource
  ## Removes a tag or tags from a resource.
  ##   keys: JArray (required)
  ##       : The keys of the key-value pairs for the resource tag or tags assigned to the resource.
  ##   ResourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource that you want to untag.
  var path_599089 = newJObject()
  var query_599090 = newJObject()
  if keys != nil:
    query_599090.add "keys", keys
  add(path_599089, "ResourceArn", newJString(ResourceArn))
  result = call_599088.call(path_599089, query_599090, nil, nil, nil)

var untagResource* = Call_UntagResource_599075(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/resources/{ResourceArn}/tags#keys",
    validator: validate_UntagResource_599076, base: "/", url: url_UntagResource_599077,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDashboardPublishedVersion_599091 = ref object of OpenApiRestCall_597389
proc url_UpdateDashboardPublishedVersion_599093(protocol: Scheme; host: string;
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

proc validate_UpdateDashboardPublishedVersion_599092(path: JsonNode;
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
  var valid_599094 = path.getOrDefault("AwsAccountId")
  valid_599094 = validateParameter(valid_599094, JString, required = true,
                                 default = nil)
  if valid_599094 != nil:
    section.add "AwsAccountId", valid_599094
  var valid_599095 = path.getOrDefault("VersionNumber")
  valid_599095 = validateParameter(valid_599095, JInt, required = true, default = nil)
  if valid_599095 != nil:
    section.add "VersionNumber", valid_599095
  var valid_599096 = path.getOrDefault("DashboardId")
  valid_599096 = validateParameter(valid_599096, JString, required = true,
                                 default = nil)
  if valid_599096 != nil:
    section.add "DashboardId", valid_599096
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
  var valid_599097 = header.getOrDefault("X-Amz-Signature")
  valid_599097 = validateParameter(valid_599097, JString, required = false,
                                 default = nil)
  if valid_599097 != nil:
    section.add "X-Amz-Signature", valid_599097
  var valid_599098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599098 = validateParameter(valid_599098, JString, required = false,
                                 default = nil)
  if valid_599098 != nil:
    section.add "X-Amz-Content-Sha256", valid_599098
  var valid_599099 = header.getOrDefault("X-Amz-Date")
  valid_599099 = validateParameter(valid_599099, JString, required = false,
                                 default = nil)
  if valid_599099 != nil:
    section.add "X-Amz-Date", valid_599099
  var valid_599100 = header.getOrDefault("X-Amz-Credential")
  valid_599100 = validateParameter(valid_599100, JString, required = false,
                                 default = nil)
  if valid_599100 != nil:
    section.add "X-Amz-Credential", valid_599100
  var valid_599101 = header.getOrDefault("X-Amz-Security-Token")
  valid_599101 = validateParameter(valid_599101, JString, required = false,
                                 default = nil)
  if valid_599101 != nil:
    section.add "X-Amz-Security-Token", valid_599101
  var valid_599102 = header.getOrDefault("X-Amz-Algorithm")
  valid_599102 = validateParameter(valid_599102, JString, required = false,
                                 default = nil)
  if valid_599102 != nil:
    section.add "X-Amz-Algorithm", valid_599102
  var valid_599103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599103 = validateParameter(valid_599103, JString, required = false,
                                 default = nil)
  if valid_599103 != nil:
    section.add "X-Amz-SignedHeaders", valid_599103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599104: Call_UpdateDashboardPublishedVersion_599091;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Updates the published version of a dashboard.
  ## 
  let valid = call_599104.validator(path, query, header, formData, body)
  let scheme = call_599104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599104.url(scheme.get, call_599104.host, call_599104.base,
                         call_599104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599104, url, valid)

proc call*(call_599105: Call_UpdateDashboardPublishedVersion_599091;
          AwsAccountId: string; VersionNumber: int; DashboardId: string): Recallable =
  ## updateDashboardPublishedVersion
  ## Updates the published version of a dashboard.
  ##   AwsAccountId: string (required)
  ##               : The ID of the AWS account that contains the dashboard that you're updating.
  ##   VersionNumber: int (required)
  ##                : The version number of the dashboard.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  var path_599106 = newJObject()
  add(path_599106, "AwsAccountId", newJString(AwsAccountId))
  add(path_599106, "VersionNumber", newJInt(VersionNumber))
  add(path_599106, "DashboardId", newJString(DashboardId))
  result = call_599105.call(path_599106, nil, nil, nil, nil)

var updateDashboardPublishedVersion* = Call_UpdateDashboardPublishedVersion_599091(
    name: "updateDashboardPublishedVersion", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/versions/{VersionNumber}",
    validator: validate_UpdateDashboardPublishedVersion_599092, base: "/",
    url: url_UpdateDashboardPublishedVersion_599093,
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
