
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
## <fullname>Amazon QuickSight API Reference</fullname> <p>Amazon QuickSight is a fully managed, serverless, cloud business intelligence service that makes it easy to extend data and insights to every user in your organization. This API interface reference contains documentation for a programming interface that you can use to manage Amazon QuickSight. </p>
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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
  Call_CreateIngestion_599977 = ref object of OpenApiRestCall_599368
proc url_CreateIngestion_599979(protocol: Scheme; host: string; base: string;
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

proc validate_CreateIngestion_599978(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Creates and starts a new SPICE ingestion on a dataset</p> <p>Any ingestions operating on tagged datasets inherit the same tags automatically for use in access-control. For an example, see <a href="https://aws.example.com/premiumsupport/knowledge-center/iam-ec2-resource-tags/">How do I create an IAM policy to control access to Amazon EC2 resources using tags?</a>. Tags will be visible on the tagged dataset, but not on the ingestion resource.</p>
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
  var valid_599980 = path.getOrDefault("AwsAccountId")
  valid_599980 = validateParameter(valid_599980, JString, required = true,
                                 default = nil)
  if valid_599980 != nil:
    section.add "AwsAccountId", valid_599980
  var valid_599981 = path.getOrDefault("DataSetId")
  valid_599981 = validateParameter(valid_599981, JString, required = true,
                                 default = nil)
  if valid_599981 != nil:
    section.add "DataSetId", valid_599981
  var valid_599982 = path.getOrDefault("IngestionId")
  valid_599982 = validateParameter(valid_599982, JString, required = true,
                                 default = nil)
  if valid_599982 != nil:
    section.add "IngestionId", valid_599982
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
  var valid_599983 = header.getOrDefault("X-Amz-Date")
  valid_599983 = validateParameter(valid_599983, JString, required = false,
                                 default = nil)
  if valid_599983 != nil:
    section.add "X-Amz-Date", valid_599983
  var valid_599984 = header.getOrDefault("X-Amz-Security-Token")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Security-Token", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Content-Sha256", valid_599985
  var valid_599986 = header.getOrDefault("X-Amz-Algorithm")
  valid_599986 = validateParameter(valid_599986, JString, required = false,
                                 default = nil)
  if valid_599986 != nil:
    section.add "X-Amz-Algorithm", valid_599986
  var valid_599987 = header.getOrDefault("X-Amz-Signature")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-Signature", valid_599987
  var valid_599988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599988 = validateParameter(valid_599988, JString, required = false,
                                 default = nil)
  if valid_599988 != nil:
    section.add "X-Amz-SignedHeaders", valid_599988
  var valid_599989 = header.getOrDefault("X-Amz-Credential")
  valid_599989 = validateParameter(valid_599989, JString, required = false,
                                 default = nil)
  if valid_599989 != nil:
    section.add "X-Amz-Credential", valid_599989
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599990: Call_CreateIngestion_599977; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates and starts a new SPICE ingestion on a dataset</p> <p>Any ingestions operating on tagged datasets inherit the same tags automatically for use in access-control. For an example, see <a href="https://aws.example.com/premiumsupport/knowledge-center/iam-ec2-resource-tags/">How do I create an IAM policy to control access to Amazon EC2 resources using tags?</a>. Tags will be visible on the tagged dataset, but not on the ingestion resource.</p>
  ## 
  let valid = call_599990.validator(path, query, header, formData, body)
  let scheme = call_599990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599990.url(scheme.get, call_599990.host, call_599990.base,
                         call_599990.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599990, url, valid)

proc call*(call_599991: Call_CreateIngestion_599977; AwsAccountId: string;
          DataSetId: string; IngestionId: string): Recallable =
  ## createIngestion
  ## <p>Creates and starts a new SPICE ingestion on a dataset</p> <p>Any ingestions operating on tagged datasets inherit the same tags automatically for use in access-control. For an example, see <a href="https://aws.example.com/premiumsupport/knowledge-center/iam-ec2-resource-tags/">How do I create an IAM policy to control access to Amazon EC2 resources using tags?</a>. Tags will be visible on the tagged dataset, but not on the ingestion resource.</p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   IngestionId: string (required)
  ##              : An ID for the ingestion.
  var path_599992 = newJObject()
  add(path_599992, "AwsAccountId", newJString(AwsAccountId))
  add(path_599992, "DataSetId", newJString(DataSetId))
  add(path_599992, "IngestionId", newJString(IngestionId))
  result = call_599991.call(path_599992, nil, nil, nil, nil)

var createIngestion* = Call_CreateIngestion_599977(name: "createIngestion",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}",
    validator: validate_CreateIngestion_599978, base: "/", url: url_CreateIngestion_599979,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIngestion_599705 = ref object of OpenApiRestCall_599368
proc url_DescribeIngestion_599707(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeIngestion_599706(path: JsonNode; query: JsonNode;
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
  var valid_599833 = path.getOrDefault("AwsAccountId")
  valid_599833 = validateParameter(valid_599833, JString, required = true,
                                 default = nil)
  if valid_599833 != nil:
    section.add "AwsAccountId", valid_599833
  var valid_599834 = path.getOrDefault("DataSetId")
  valid_599834 = validateParameter(valid_599834, JString, required = true,
                                 default = nil)
  if valid_599834 != nil:
    section.add "DataSetId", valid_599834
  var valid_599835 = path.getOrDefault("IngestionId")
  valid_599835 = validateParameter(valid_599835, JString, required = true,
                                 default = nil)
  if valid_599835 != nil:
    section.add "IngestionId", valid_599835
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
  var valid_599836 = header.getOrDefault("X-Amz-Date")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "X-Amz-Date", valid_599836
  var valid_599837 = header.getOrDefault("X-Amz-Security-Token")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "X-Amz-Security-Token", valid_599837
  var valid_599838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-Content-Sha256", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Algorithm")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Algorithm", valid_599839
  var valid_599840 = header.getOrDefault("X-Amz-Signature")
  valid_599840 = validateParameter(valid_599840, JString, required = false,
                                 default = nil)
  if valid_599840 != nil:
    section.add "X-Amz-Signature", valid_599840
  var valid_599841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599841 = validateParameter(valid_599841, JString, required = false,
                                 default = nil)
  if valid_599841 != nil:
    section.add "X-Amz-SignedHeaders", valid_599841
  var valid_599842 = header.getOrDefault("X-Amz-Credential")
  valid_599842 = validateParameter(valid_599842, JString, required = false,
                                 default = nil)
  if valid_599842 != nil:
    section.add "X-Amz-Credential", valid_599842
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599865: Call_DescribeIngestion_599705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a SPICE ingestion.
  ## 
  let valid = call_599865.validator(path, query, header, formData, body)
  let scheme = call_599865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599865.url(scheme.get, call_599865.host, call_599865.base,
                         call_599865.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599865, url, valid)

proc call*(call_599936: Call_DescribeIngestion_599705; AwsAccountId: string;
          DataSetId: string; IngestionId: string): Recallable =
  ## describeIngestion
  ## Describes a SPICE ingestion.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   IngestionId: string (required)
  ##              : An ID for the ingestion.
  var path_599937 = newJObject()
  add(path_599937, "AwsAccountId", newJString(AwsAccountId))
  add(path_599937, "DataSetId", newJString(DataSetId))
  add(path_599937, "IngestionId", newJString(IngestionId))
  result = call_599936.call(path_599937, nil, nil, nil, nil)

var describeIngestion* = Call_DescribeIngestion_599705(name: "describeIngestion",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}",
    validator: validate_DescribeIngestion_599706, base: "/",
    url: url_DescribeIngestion_599707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelIngestion_599993 = ref object of OpenApiRestCall_599368
proc url_CancelIngestion_599995(protocol: Scheme; host: string; base: string;
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

proc validate_CancelIngestion_599994(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Cancels an on-going ingestion of data into SPICE.
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
  var valid_599996 = path.getOrDefault("AwsAccountId")
  valid_599996 = validateParameter(valid_599996, JString, required = true,
                                 default = nil)
  if valid_599996 != nil:
    section.add "AwsAccountId", valid_599996
  var valid_599997 = path.getOrDefault("DataSetId")
  valid_599997 = validateParameter(valid_599997, JString, required = true,
                                 default = nil)
  if valid_599997 != nil:
    section.add "DataSetId", valid_599997
  var valid_599998 = path.getOrDefault("IngestionId")
  valid_599998 = validateParameter(valid_599998, JString, required = true,
                                 default = nil)
  if valid_599998 != nil:
    section.add "IngestionId", valid_599998
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
  var valid_599999 = header.getOrDefault("X-Amz-Date")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Date", valid_599999
  var valid_600000 = header.getOrDefault("X-Amz-Security-Token")
  valid_600000 = validateParameter(valid_600000, JString, required = false,
                                 default = nil)
  if valid_600000 != nil:
    section.add "X-Amz-Security-Token", valid_600000
  var valid_600001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600001 = validateParameter(valid_600001, JString, required = false,
                                 default = nil)
  if valid_600001 != nil:
    section.add "X-Amz-Content-Sha256", valid_600001
  var valid_600002 = header.getOrDefault("X-Amz-Algorithm")
  valid_600002 = validateParameter(valid_600002, JString, required = false,
                                 default = nil)
  if valid_600002 != nil:
    section.add "X-Amz-Algorithm", valid_600002
  var valid_600003 = header.getOrDefault("X-Amz-Signature")
  valid_600003 = validateParameter(valid_600003, JString, required = false,
                                 default = nil)
  if valid_600003 != nil:
    section.add "X-Amz-Signature", valid_600003
  var valid_600004 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600004 = validateParameter(valid_600004, JString, required = false,
                                 default = nil)
  if valid_600004 != nil:
    section.add "X-Amz-SignedHeaders", valid_600004
  var valid_600005 = header.getOrDefault("X-Amz-Credential")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "X-Amz-Credential", valid_600005
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600006: Call_CancelIngestion_599993; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels an on-going ingestion of data into SPICE.
  ## 
  let valid = call_600006.validator(path, query, header, formData, body)
  let scheme = call_600006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600006.url(scheme.get, call_600006.host, call_600006.base,
                         call_600006.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600006, url, valid)

proc call*(call_600007: Call_CancelIngestion_599993; AwsAccountId: string;
          DataSetId: string; IngestionId: string): Recallable =
  ## cancelIngestion
  ## Cancels an on-going ingestion of data into SPICE.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSetId: string (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   IngestionId: string (required)
  ##              : An ID for the ingestion.
  var path_600008 = newJObject()
  add(path_600008, "AwsAccountId", newJString(AwsAccountId))
  add(path_600008, "DataSetId", newJString(DataSetId))
  add(path_600008, "IngestionId", newJString(IngestionId))
  result = call_600007.call(path_600008, nil, nil, nil, nil)

var cancelIngestion* = Call_CancelIngestion_599993(name: "cancelIngestion",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions/{IngestionId}",
    validator: validate_CancelIngestion_599994, base: "/", url: url_CancelIngestion_599995,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDashboard_600027 = ref object of OpenApiRestCall_599368
proc url_UpdateDashboard_600029(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDashboard_600028(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Updates a dashboard in the AWS account.</p> <p>CLI syntax:</p> <p> <code>aws quicksight update-dashboard --aws-account-id 111122223333 --dashboard-id 123123123 --dashboard-name "test-update102" --source-entity SourceTemplate={Arn=arn:aws:quicksight:us-west-2:111122223333:template/sales-report-template2} --data-set-references DataSetPlaceholder=SalesDataSet,DataSetArn=arn:aws:quicksight:us-west-2:111122223333:dataset/0e251aef-9ebf-46e1-b852-eb4fa33c1d3a</code> </p> <p> <code>aws quicksight update-dashboard --cli-input-json file://update-dashboard.json </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : AWS account ID that contains the dashboard you are updating.
  ##   DashboardId: JString (required)
  ##              : The ID for the dashboard.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600030 = path.getOrDefault("AwsAccountId")
  valid_600030 = validateParameter(valid_600030, JString, required = true,
                                 default = nil)
  if valid_600030 != nil:
    section.add "AwsAccountId", valid_600030
  var valid_600031 = path.getOrDefault("DashboardId")
  valid_600031 = validateParameter(valid_600031, JString, required = true,
                                 default = nil)
  if valid_600031 != nil:
    section.add "DashboardId", valid_600031
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
  var valid_600032 = header.getOrDefault("X-Amz-Date")
  valid_600032 = validateParameter(valid_600032, JString, required = false,
                                 default = nil)
  if valid_600032 != nil:
    section.add "X-Amz-Date", valid_600032
  var valid_600033 = header.getOrDefault("X-Amz-Security-Token")
  valid_600033 = validateParameter(valid_600033, JString, required = false,
                                 default = nil)
  if valid_600033 != nil:
    section.add "X-Amz-Security-Token", valid_600033
  var valid_600034 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600034 = validateParameter(valid_600034, JString, required = false,
                                 default = nil)
  if valid_600034 != nil:
    section.add "X-Amz-Content-Sha256", valid_600034
  var valid_600035 = header.getOrDefault("X-Amz-Algorithm")
  valid_600035 = validateParameter(valid_600035, JString, required = false,
                                 default = nil)
  if valid_600035 != nil:
    section.add "X-Amz-Algorithm", valid_600035
  var valid_600036 = header.getOrDefault("X-Amz-Signature")
  valid_600036 = validateParameter(valid_600036, JString, required = false,
                                 default = nil)
  if valid_600036 != nil:
    section.add "X-Amz-Signature", valid_600036
  var valid_600037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600037 = validateParameter(valid_600037, JString, required = false,
                                 default = nil)
  if valid_600037 != nil:
    section.add "X-Amz-SignedHeaders", valid_600037
  var valid_600038 = header.getOrDefault("X-Amz-Credential")
  valid_600038 = validateParameter(valid_600038, JString, required = false,
                                 default = nil)
  if valid_600038 != nil:
    section.add "X-Amz-Credential", valid_600038
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600040: Call_UpdateDashboard_600027; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a dashboard in the AWS account.</p> <p>CLI syntax:</p> <p> <code>aws quicksight update-dashboard --aws-account-id 111122223333 --dashboard-id 123123123 --dashboard-name "test-update102" --source-entity SourceTemplate={Arn=arn:aws:quicksight:us-west-2:111122223333:template/sales-report-template2} --data-set-references DataSetPlaceholder=SalesDataSet,DataSetArn=arn:aws:quicksight:us-west-2:111122223333:dataset/0e251aef-9ebf-46e1-b852-eb4fa33c1d3a</code> </p> <p> <code>aws quicksight update-dashboard --cli-input-json file://update-dashboard.json </code> </p>
  ## 
  let valid = call_600040.validator(path, query, header, formData, body)
  let scheme = call_600040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600040.url(scheme.get, call_600040.host, call_600040.base,
                         call_600040.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600040, url, valid)

proc call*(call_600041: Call_UpdateDashboard_600027; AwsAccountId: string;
          DashboardId: string; body: JsonNode): Recallable =
  ## updateDashboard
  ## <p>Updates a dashboard in the AWS account.</p> <p>CLI syntax:</p> <p> <code>aws quicksight update-dashboard --aws-account-id 111122223333 --dashboard-id 123123123 --dashboard-name "test-update102" --source-entity SourceTemplate={Arn=arn:aws:quicksight:us-west-2:111122223333:template/sales-report-template2} --data-set-references DataSetPlaceholder=SalesDataSet,DataSetArn=arn:aws:quicksight:us-west-2:111122223333:dataset/0e251aef-9ebf-46e1-b852-eb4fa33c1d3a</code> </p> <p> <code>aws quicksight update-dashboard --cli-input-json file://update-dashboard.json </code> </p>
  ##   AwsAccountId: string (required)
  ##               : AWS account ID that contains the dashboard you are updating.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  ##   body: JObject (required)
  var path_600042 = newJObject()
  var body_600043 = newJObject()
  add(path_600042, "AwsAccountId", newJString(AwsAccountId))
  add(path_600042, "DashboardId", newJString(DashboardId))
  if body != nil:
    body_600043 = body
  result = call_600041.call(path_600042, nil, nil, nil, body_600043)

var updateDashboard* = Call_UpdateDashboard_600027(name: "updateDashboard",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}",
    validator: validate_UpdateDashboard_600028, base: "/", url: url_UpdateDashboard_600029,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDashboard_600044 = ref object of OpenApiRestCall_599368
proc url_CreateDashboard_600046(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDashboard_600045(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Creates a dashboard from a template. To first create a template, see the CreateTemplate API.</p> <p>A dashboard is an entity in QuickSight which identifies Quicksight reports, created from analyses. QuickSight dashboards are sharable. With the right permissions, you can create scheduled email reports from them. The <code>CreateDashboard</code>, <code>DescribeDashboard</code> and <code>ListDashboardsByUser</code> APIs act on the dashboard entity. If you have the correct permissions, you can create a dashboard from a template that exists in a different AWS account.</p> <p>CLI syntax:</p> <p> <code>aws quicksight create-dashboard --cli-input-json file://create-dashboard.json</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : AWS account ID where you want to create the dashboard.
  ##   DashboardId: JString (required)
  ##              : The ID for the dashboard, also added to IAM policy.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600047 = path.getOrDefault("AwsAccountId")
  valid_600047 = validateParameter(valid_600047, JString, required = true,
                                 default = nil)
  if valid_600047 != nil:
    section.add "AwsAccountId", valid_600047
  var valid_600048 = path.getOrDefault("DashboardId")
  valid_600048 = validateParameter(valid_600048, JString, required = true,
                                 default = nil)
  if valid_600048 != nil:
    section.add "DashboardId", valid_600048
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
  var valid_600049 = header.getOrDefault("X-Amz-Date")
  valid_600049 = validateParameter(valid_600049, JString, required = false,
                                 default = nil)
  if valid_600049 != nil:
    section.add "X-Amz-Date", valid_600049
  var valid_600050 = header.getOrDefault("X-Amz-Security-Token")
  valid_600050 = validateParameter(valid_600050, JString, required = false,
                                 default = nil)
  if valid_600050 != nil:
    section.add "X-Amz-Security-Token", valid_600050
  var valid_600051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600051 = validateParameter(valid_600051, JString, required = false,
                                 default = nil)
  if valid_600051 != nil:
    section.add "X-Amz-Content-Sha256", valid_600051
  var valid_600052 = header.getOrDefault("X-Amz-Algorithm")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Algorithm", valid_600052
  var valid_600053 = header.getOrDefault("X-Amz-Signature")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-Signature", valid_600053
  var valid_600054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600054 = validateParameter(valid_600054, JString, required = false,
                                 default = nil)
  if valid_600054 != nil:
    section.add "X-Amz-SignedHeaders", valid_600054
  var valid_600055 = header.getOrDefault("X-Amz-Credential")
  valid_600055 = validateParameter(valid_600055, JString, required = false,
                                 default = nil)
  if valid_600055 != nil:
    section.add "X-Amz-Credential", valid_600055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600057: Call_CreateDashboard_600044; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a dashboard from a template. To first create a template, see the CreateTemplate API.</p> <p>A dashboard is an entity in QuickSight which identifies Quicksight reports, created from analyses. QuickSight dashboards are sharable. With the right permissions, you can create scheduled email reports from them. The <code>CreateDashboard</code>, <code>DescribeDashboard</code> and <code>ListDashboardsByUser</code> APIs act on the dashboard entity. If you have the correct permissions, you can create a dashboard from a template that exists in a different AWS account.</p> <p>CLI syntax:</p> <p> <code>aws quicksight create-dashboard --cli-input-json file://create-dashboard.json</code> </p>
  ## 
  let valid = call_600057.validator(path, query, header, formData, body)
  let scheme = call_600057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600057.url(scheme.get, call_600057.host, call_600057.base,
                         call_600057.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600057, url, valid)

proc call*(call_600058: Call_CreateDashboard_600044; AwsAccountId: string;
          DashboardId: string; body: JsonNode): Recallable =
  ## createDashboard
  ## <p>Creates a dashboard from a template. To first create a template, see the CreateTemplate API.</p> <p>A dashboard is an entity in QuickSight which identifies Quicksight reports, created from analyses. QuickSight dashboards are sharable. With the right permissions, you can create scheduled email reports from them. The <code>CreateDashboard</code>, <code>DescribeDashboard</code> and <code>ListDashboardsByUser</code> APIs act on the dashboard entity. If you have the correct permissions, you can create a dashboard from a template that exists in a different AWS account.</p> <p>CLI syntax:</p> <p> <code>aws quicksight create-dashboard --cli-input-json file://create-dashboard.json</code> </p>
  ##   AwsAccountId: string (required)
  ##               : AWS account ID where you want to create the dashboard.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard, also added to IAM policy.
  ##   body: JObject (required)
  var path_600059 = newJObject()
  var body_600060 = newJObject()
  add(path_600059, "AwsAccountId", newJString(AwsAccountId))
  add(path_600059, "DashboardId", newJString(DashboardId))
  if body != nil:
    body_600060 = body
  result = call_600058.call(path_600059, nil, nil, nil, body_600060)

var createDashboard* = Call_CreateDashboard_600044(name: "createDashboard",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}",
    validator: validate_CreateDashboard_600045, base: "/", url: url_CreateDashboard_600046,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDashboard_600009 = ref object of OpenApiRestCall_599368
proc url_DescribeDashboard_600011(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDashboard_600010(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Provides a summary for a dashboard.</p> <p>CLI syntax:</p> <ul> <li> <p> <code>aws quicksight describe-dashboard --aws-account-id 111122223333 —dashboard-id reports_test_report -version-number 2</code> </p> </li> <li> <p> <code> aws quicksight describe-dashboard --aws-account-id 111122223333 —dashboard-id reports_test_report -alias-name ‘$PUBLISHED’ </code> </p> </li> </ul> <p/>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : AWS account ID that contains the dashboard you are describing.
  ##   DashboardId: JString (required)
  ##              : The ID for the dashboard.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600012 = path.getOrDefault("AwsAccountId")
  valid_600012 = validateParameter(valid_600012, JString, required = true,
                                 default = nil)
  if valid_600012 != nil:
    section.add "AwsAccountId", valid_600012
  var valid_600013 = path.getOrDefault("DashboardId")
  valid_600013 = validateParameter(valid_600013, JString, required = true,
                                 default = nil)
  if valid_600013 != nil:
    section.add "DashboardId", valid_600013
  result.add "path", section
  ## parameters in `query` object:
  ##   alias-name: JString
  ##             : The alias name.
  ##   version-number: JInt
  ##                 : The version number for the dashboard. If version number isn’t passed the latest published dashboard version is described. 
  section = newJObject()
  var valid_600014 = query.getOrDefault("alias-name")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "alias-name", valid_600014
  var valid_600015 = query.getOrDefault("version-number")
  valid_600015 = validateParameter(valid_600015, JInt, required = false, default = nil)
  if valid_600015 != nil:
    section.add "version-number", valid_600015
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
  var valid_600016 = header.getOrDefault("X-Amz-Date")
  valid_600016 = validateParameter(valid_600016, JString, required = false,
                                 default = nil)
  if valid_600016 != nil:
    section.add "X-Amz-Date", valid_600016
  var valid_600017 = header.getOrDefault("X-Amz-Security-Token")
  valid_600017 = validateParameter(valid_600017, JString, required = false,
                                 default = nil)
  if valid_600017 != nil:
    section.add "X-Amz-Security-Token", valid_600017
  var valid_600018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600018 = validateParameter(valid_600018, JString, required = false,
                                 default = nil)
  if valid_600018 != nil:
    section.add "X-Amz-Content-Sha256", valid_600018
  var valid_600019 = header.getOrDefault("X-Amz-Algorithm")
  valid_600019 = validateParameter(valid_600019, JString, required = false,
                                 default = nil)
  if valid_600019 != nil:
    section.add "X-Amz-Algorithm", valid_600019
  var valid_600020 = header.getOrDefault("X-Amz-Signature")
  valid_600020 = validateParameter(valid_600020, JString, required = false,
                                 default = nil)
  if valid_600020 != nil:
    section.add "X-Amz-Signature", valid_600020
  var valid_600021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600021 = validateParameter(valid_600021, JString, required = false,
                                 default = nil)
  if valid_600021 != nil:
    section.add "X-Amz-SignedHeaders", valid_600021
  var valid_600022 = header.getOrDefault("X-Amz-Credential")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-Credential", valid_600022
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600023: Call_DescribeDashboard_600009; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Provides a summary for a dashboard.</p> <p>CLI syntax:</p> <ul> <li> <p> <code>aws quicksight describe-dashboard --aws-account-id 111122223333 —dashboard-id reports_test_report -version-number 2</code> </p> </li> <li> <p> <code> aws quicksight describe-dashboard --aws-account-id 111122223333 —dashboard-id reports_test_report -alias-name ‘$PUBLISHED’ </code> </p> </li> </ul> <p/>
  ## 
  let valid = call_600023.validator(path, query, header, formData, body)
  let scheme = call_600023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600023.url(scheme.get, call_600023.host, call_600023.base,
                         call_600023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600023, url, valid)

proc call*(call_600024: Call_DescribeDashboard_600009; AwsAccountId: string;
          DashboardId: string; aliasName: string = ""; versionNumber: int = 0): Recallable =
  ## describeDashboard
  ## <p>Provides a summary for a dashboard.</p> <p>CLI syntax:</p> <ul> <li> <p> <code>aws quicksight describe-dashboard --aws-account-id 111122223333 —dashboard-id reports_test_report -version-number 2</code> </p> </li> <li> <p> <code> aws quicksight describe-dashboard --aws-account-id 111122223333 —dashboard-id reports_test_report -alias-name ‘$PUBLISHED’ </code> </p> </li> </ul> <p/>
  ##   AwsAccountId: string (required)
  ##               : AWS account ID that contains the dashboard you are describing.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  ##   aliasName: string
  ##            : The alias name.
  ##   versionNumber: int
  ##                : The version number for the dashboard. If version number isn’t passed the latest published dashboard version is described. 
  var path_600025 = newJObject()
  var query_600026 = newJObject()
  add(path_600025, "AwsAccountId", newJString(AwsAccountId))
  add(path_600025, "DashboardId", newJString(DashboardId))
  add(query_600026, "alias-name", newJString(aliasName))
  add(query_600026, "version-number", newJInt(versionNumber))
  result = call_600024.call(path_600025, query_600026, nil, nil, nil)

var describeDashboard* = Call_DescribeDashboard_600009(name: "describeDashboard",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}",
    validator: validate_DescribeDashboard_600010, base: "/",
    url: url_DescribeDashboard_600011, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDashboard_600061 = ref object of OpenApiRestCall_599368
proc url_DeleteDashboard_600063(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDashboard_600062(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Deletes a dashboard.</p> <p>CLI syntax:</p> <p> <code>aws quicksight delete-dashboard --aws-account-id 111122223333 —dashboard-id 123123123</code> </p> <p> <code>aws quicksight delete-dashboard --aws-account-id 111122223333 —dashboard-id 123123123 —version-number 3</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : AWS account ID that contains the dashboard you are deleting.
  ##   DashboardId: JString (required)
  ##              : The ID for the dashboard.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600064 = path.getOrDefault("AwsAccountId")
  valid_600064 = validateParameter(valid_600064, JString, required = true,
                                 default = nil)
  if valid_600064 != nil:
    section.add "AwsAccountId", valid_600064
  var valid_600065 = path.getOrDefault("DashboardId")
  valid_600065 = validateParameter(valid_600065, JString, required = true,
                                 default = nil)
  if valid_600065 != nil:
    section.add "DashboardId", valid_600065
  result.add "path", section
  ## parameters in `query` object:
  ##   version-number: JInt
  ##                 : The version number of the dashboard. If version number property is provided, only the specified version of the dashboard is deleted.
  section = newJObject()
  var valid_600066 = query.getOrDefault("version-number")
  valid_600066 = validateParameter(valid_600066, JInt, required = false, default = nil)
  if valid_600066 != nil:
    section.add "version-number", valid_600066
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
  var valid_600067 = header.getOrDefault("X-Amz-Date")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Date", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-Security-Token")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Security-Token", valid_600068
  var valid_600069 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600069 = validateParameter(valid_600069, JString, required = false,
                                 default = nil)
  if valid_600069 != nil:
    section.add "X-Amz-Content-Sha256", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-Algorithm")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Algorithm", valid_600070
  var valid_600071 = header.getOrDefault("X-Amz-Signature")
  valid_600071 = validateParameter(valid_600071, JString, required = false,
                                 default = nil)
  if valid_600071 != nil:
    section.add "X-Amz-Signature", valid_600071
  var valid_600072 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-SignedHeaders", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-Credential")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-Credential", valid_600073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600074: Call_DeleteDashboard_600061; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a dashboard.</p> <p>CLI syntax:</p> <p> <code>aws quicksight delete-dashboard --aws-account-id 111122223333 —dashboard-id 123123123</code> </p> <p> <code>aws quicksight delete-dashboard --aws-account-id 111122223333 —dashboard-id 123123123 —version-number 3</code> </p>
  ## 
  let valid = call_600074.validator(path, query, header, formData, body)
  let scheme = call_600074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600074.url(scheme.get, call_600074.host, call_600074.base,
                         call_600074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600074, url, valid)

proc call*(call_600075: Call_DeleteDashboard_600061; AwsAccountId: string;
          DashboardId: string; versionNumber: int = 0): Recallable =
  ## deleteDashboard
  ## <p>Deletes a dashboard.</p> <p>CLI syntax:</p> <p> <code>aws quicksight delete-dashboard --aws-account-id 111122223333 —dashboard-id 123123123</code> </p> <p> <code>aws quicksight delete-dashboard --aws-account-id 111122223333 —dashboard-id 123123123 —version-number 3</code> </p>
  ##   AwsAccountId: string (required)
  ##               : AWS account ID that contains the dashboard you are deleting.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  ##   versionNumber: int
  ##                : The version number of the dashboard. If version number property is provided, only the specified version of the dashboard is deleted.
  var path_600076 = newJObject()
  var query_600077 = newJObject()
  add(path_600076, "AwsAccountId", newJString(AwsAccountId))
  add(path_600076, "DashboardId", newJString(DashboardId))
  add(query_600077, "version-number", newJInt(versionNumber))
  result = call_600075.call(path_600076, query_600077, nil, nil, nil)

var deleteDashboard* = Call_DeleteDashboard_600061(name: "deleteDashboard",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}",
    validator: validate_DeleteDashboard_600062, base: "/", url: url_DeleteDashboard_600063,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSet_600097 = ref object of OpenApiRestCall_599368
proc url_CreateDataSet_600099(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDataSet_600098(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates a dataset.</p> <p>CLI syntax:</p> <p> <code>aws quicksight create-data-set \</code> </p> <p> <code>--aws-account-id=111122223333 \</code> </p> <p> <code>--data-set-id=unique-data-set-id \</code> </p> <p> <code>--name='My dataset' \</code> </p> <p> <code>--import-mode=SPICE \</code> </p> <p> <code>--physical-table-map='{</code> </p> <p> <code> "physical-table-id": {</code> </p> <p> <code> "RelationalTable": {</code> </p> <p> <code> "DataSourceArn": "arn:aws:quicksight:us-west-2:111111111111:datasource/data-source-id",</code> </p> <p> <code> "Name": "table1",</code> </p> <p> <code> "InputColumns": [</code> </p> <p> <code> {</code> </p> <p> <code> "Name": "column1",</code> </p> <p> <code> "Type": "STRING"</code> </p> <p> <code> }</code> </p> <p> <code> ]</code> </p> <p> <code> }</code> </p> <p> <code> }'</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS Account ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600100 = path.getOrDefault("AwsAccountId")
  valid_600100 = validateParameter(valid_600100, JString, required = true,
                                 default = nil)
  if valid_600100 != nil:
    section.add "AwsAccountId", valid_600100
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
  var valid_600101 = header.getOrDefault("X-Amz-Date")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "X-Amz-Date", valid_600101
  var valid_600102 = header.getOrDefault("X-Amz-Security-Token")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Security-Token", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-Content-Sha256", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-Algorithm")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-Algorithm", valid_600104
  var valid_600105 = header.getOrDefault("X-Amz-Signature")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "X-Amz-Signature", valid_600105
  var valid_600106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600106 = validateParameter(valid_600106, JString, required = false,
                                 default = nil)
  if valid_600106 != nil:
    section.add "X-Amz-SignedHeaders", valid_600106
  var valid_600107 = header.getOrDefault("X-Amz-Credential")
  valid_600107 = validateParameter(valid_600107, JString, required = false,
                                 default = nil)
  if valid_600107 != nil:
    section.add "X-Amz-Credential", valid_600107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600109: Call_CreateDataSet_600097; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a dataset.</p> <p>CLI syntax:</p> <p> <code>aws quicksight create-data-set \</code> </p> <p> <code>--aws-account-id=111122223333 \</code> </p> <p> <code>--data-set-id=unique-data-set-id \</code> </p> <p> <code>--name='My dataset' \</code> </p> <p> <code>--import-mode=SPICE \</code> </p> <p> <code>--physical-table-map='{</code> </p> <p> <code> "physical-table-id": {</code> </p> <p> <code> "RelationalTable": {</code> </p> <p> <code> "DataSourceArn": "arn:aws:quicksight:us-west-2:111111111111:datasource/data-source-id",</code> </p> <p> <code> "Name": "table1",</code> </p> <p> <code> "InputColumns": [</code> </p> <p> <code> {</code> </p> <p> <code> "Name": "column1",</code> </p> <p> <code> "Type": "STRING"</code> </p> <p> <code> }</code> </p> <p> <code> ]</code> </p> <p> <code> }</code> </p> <p> <code> }'</code> </p>
  ## 
  let valid = call_600109.validator(path, query, header, formData, body)
  let scheme = call_600109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600109.url(scheme.get, call_600109.host, call_600109.base,
                         call_600109.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600109, url, valid)

proc call*(call_600110: Call_CreateDataSet_600097; AwsAccountId: string;
          body: JsonNode): Recallable =
  ## createDataSet
  ## <p>Creates a dataset.</p> <p>CLI syntax:</p> <p> <code>aws quicksight create-data-set \</code> </p> <p> <code>--aws-account-id=111122223333 \</code> </p> <p> <code>--data-set-id=unique-data-set-id \</code> </p> <p> <code>--name='My dataset' \</code> </p> <p> <code>--import-mode=SPICE \</code> </p> <p> <code>--physical-table-map='{</code> </p> <p> <code> "physical-table-id": {</code> </p> <p> <code> "RelationalTable": {</code> </p> <p> <code> "DataSourceArn": "arn:aws:quicksight:us-west-2:111111111111:datasource/data-source-id",</code> </p> <p> <code> "Name": "table1",</code> </p> <p> <code> "InputColumns": [</code> </p> <p> <code> {</code> </p> <p> <code> "Name": "column1",</code> </p> <p> <code> "Type": "STRING"</code> </p> <p> <code> }</code> </p> <p> <code> ]</code> </p> <p> <code> }</code> </p> <p> <code> }'</code> </p>
  ##   AwsAccountId: string (required)
  ##               : The AWS Account ID.
  ##   body: JObject (required)
  var path_600111 = newJObject()
  var body_600112 = newJObject()
  add(path_600111, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_600112 = body
  result = call_600110.call(path_600111, nil, nil, nil, body_600112)

var createDataSet* = Call_CreateDataSet_600097(name: "createDataSet",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets",
    validator: validate_CreateDataSet_600098, base: "/", url: url_CreateDataSet_600099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSets_600078 = ref object of OpenApiRestCall_599368
proc url_ListDataSets_600080(protocol: Scheme; host: string; base: string;
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

proc validate_ListDataSets_600079(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists all of the datasets belonging to this account in an AWS region.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/*</code> </p> <p>CLI syntax: <code>aws quicksight list-data-sets --aws-account-id=111111111111</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS Account ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600081 = path.getOrDefault("AwsAccountId")
  valid_600081 = validateParameter(valid_600081, JString, required = true,
                                 default = nil)
  if valid_600081 != nil:
    section.add "AwsAccountId", valid_600081
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600082 = query.getOrDefault("NextToken")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "NextToken", valid_600082
  var valid_600083 = query.getOrDefault("max-results")
  valid_600083 = validateParameter(valid_600083, JInt, required = false, default = nil)
  if valid_600083 != nil:
    section.add "max-results", valid_600083
  var valid_600084 = query.getOrDefault("next-token")
  valid_600084 = validateParameter(valid_600084, JString, required = false,
                                 default = nil)
  if valid_600084 != nil:
    section.add "next-token", valid_600084
  var valid_600085 = query.getOrDefault("MaxResults")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "MaxResults", valid_600085
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
  var valid_600086 = header.getOrDefault("X-Amz-Date")
  valid_600086 = validateParameter(valid_600086, JString, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "X-Amz-Date", valid_600086
  var valid_600087 = header.getOrDefault("X-Amz-Security-Token")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "X-Amz-Security-Token", valid_600087
  var valid_600088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-Content-Sha256", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Algorithm")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Algorithm", valid_600089
  var valid_600090 = header.getOrDefault("X-Amz-Signature")
  valid_600090 = validateParameter(valid_600090, JString, required = false,
                                 default = nil)
  if valid_600090 != nil:
    section.add "X-Amz-Signature", valid_600090
  var valid_600091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600091 = validateParameter(valid_600091, JString, required = false,
                                 default = nil)
  if valid_600091 != nil:
    section.add "X-Amz-SignedHeaders", valid_600091
  var valid_600092 = header.getOrDefault("X-Amz-Credential")
  valid_600092 = validateParameter(valid_600092, JString, required = false,
                                 default = nil)
  if valid_600092 != nil:
    section.add "X-Amz-Credential", valid_600092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600093: Call_ListDataSets_600078; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all of the datasets belonging to this account in an AWS region.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/*</code> </p> <p>CLI syntax: <code>aws quicksight list-data-sets --aws-account-id=111111111111</code> </p>
  ## 
  let valid = call_600093.validator(path, query, header, formData, body)
  let scheme = call_600093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600093.url(scheme.get, call_600093.host, call_600093.base,
                         call_600093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600093, url, valid)

proc call*(call_600094: Call_ListDataSets_600078; AwsAccountId: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listDataSets
  ## <p>Lists all of the datasets belonging to this account in an AWS region.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/*</code> </p> <p>CLI syntax: <code>aws quicksight list-data-sets --aws-account-id=111111111111</code> </p>
  ##   AwsAccountId: string (required)
  ##               : The AWS Account ID.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_600095 = newJObject()
  var query_600096 = newJObject()
  add(path_600095, "AwsAccountId", newJString(AwsAccountId))
  add(query_600096, "NextToken", newJString(NextToken))
  add(query_600096, "max-results", newJInt(maxResults))
  add(query_600096, "next-token", newJString(nextToken))
  add(query_600096, "MaxResults", newJString(MaxResults))
  result = call_600094.call(path_600095, query_600096, nil, nil, nil)

var listDataSets* = Call_ListDataSets_600078(name: "listDataSets",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets", validator: validate_ListDataSets_600079,
    base: "/", url: url_ListDataSets_600080, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataSource_600132 = ref object of OpenApiRestCall_599368
proc url_CreateDataSource_600134(protocol: Scheme; host: string; base: string;
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

proc validate_CreateDataSource_600133(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Creates a data source.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:datasource/data-source-id</code> </p> <p>CLI syntax:</p> <p> <code>aws quicksight create-data-source \</code> </p> <p> <code>--aws-account-id=111122223333 \</code> </p> <p> <code>--data-source-id=unique-data-source-id \</code> </p> <p> <code>--name='My Data Source' \</code> </p> <p> <code>--type=POSTGRESQL \</code> </p> <p> <code>--data-source-parameters='{ "PostgreSqlParameters": {</code> </p> <p> <code> "Host": "my-db-host.example.com",</code> </p> <p> <code> "Port": 1234,</code> </p> <p> <code> "Database": "my-db" } }' \</code> </p> <p> <code>--credentials='{ "CredentialPair": {</code> </p> <p> <code> "Username": "username",</code> </p> <p> <code> "Password": "password" } }'</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600135 = path.getOrDefault("AwsAccountId")
  valid_600135 = validateParameter(valid_600135, JString, required = true,
                                 default = nil)
  if valid_600135 != nil:
    section.add "AwsAccountId", valid_600135
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
  var valid_600136 = header.getOrDefault("X-Amz-Date")
  valid_600136 = validateParameter(valid_600136, JString, required = false,
                                 default = nil)
  if valid_600136 != nil:
    section.add "X-Amz-Date", valid_600136
  var valid_600137 = header.getOrDefault("X-Amz-Security-Token")
  valid_600137 = validateParameter(valid_600137, JString, required = false,
                                 default = nil)
  if valid_600137 != nil:
    section.add "X-Amz-Security-Token", valid_600137
  var valid_600138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600138 = validateParameter(valid_600138, JString, required = false,
                                 default = nil)
  if valid_600138 != nil:
    section.add "X-Amz-Content-Sha256", valid_600138
  var valid_600139 = header.getOrDefault("X-Amz-Algorithm")
  valid_600139 = validateParameter(valid_600139, JString, required = false,
                                 default = nil)
  if valid_600139 != nil:
    section.add "X-Amz-Algorithm", valid_600139
  var valid_600140 = header.getOrDefault("X-Amz-Signature")
  valid_600140 = validateParameter(valid_600140, JString, required = false,
                                 default = nil)
  if valid_600140 != nil:
    section.add "X-Amz-Signature", valid_600140
  var valid_600141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600141 = validateParameter(valid_600141, JString, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "X-Amz-SignedHeaders", valid_600141
  var valid_600142 = header.getOrDefault("X-Amz-Credential")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Credential", valid_600142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600144: Call_CreateDataSource_600132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a data source.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:datasource/data-source-id</code> </p> <p>CLI syntax:</p> <p> <code>aws quicksight create-data-source \</code> </p> <p> <code>--aws-account-id=111122223333 \</code> </p> <p> <code>--data-source-id=unique-data-source-id \</code> </p> <p> <code>--name='My Data Source' \</code> </p> <p> <code>--type=POSTGRESQL \</code> </p> <p> <code>--data-source-parameters='{ "PostgreSqlParameters": {</code> </p> <p> <code> "Host": "my-db-host.example.com",</code> </p> <p> <code> "Port": 1234,</code> </p> <p> <code> "Database": "my-db" } }' \</code> </p> <p> <code>--credentials='{ "CredentialPair": {</code> </p> <p> <code> "Username": "username",</code> </p> <p> <code> "Password": "password" } }'</code> </p>
  ## 
  let valid = call_600144.validator(path, query, header, formData, body)
  let scheme = call_600144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600144.url(scheme.get, call_600144.host, call_600144.base,
                         call_600144.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600144, url, valid)

proc call*(call_600145: Call_CreateDataSource_600132; AwsAccountId: string;
          body: JsonNode): Recallable =
  ## createDataSource
  ## <p>Creates a data source.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:datasource/data-source-id</code> </p> <p>CLI syntax:</p> <p> <code>aws quicksight create-data-source \</code> </p> <p> <code>--aws-account-id=111122223333 \</code> </p> <p> <code>--data-source-id=unique-data-source-id \</code> </p> <p> <code>--name='My Data Source' \</code> </p> <p> <code>--type=POSTGRESQL \</code> </p> <p> <code>--data-source-parameters='{ "PostgreSqlParameters": {</code> </p> <p> <code> "Host": "my-db-host.example.com",</code> </p> <p> <code> "Port": 1234,</code> </p> <p> <code> "Database": "my-db" } }' \</code> </p> <p> <code>--credentials='{ "CredentialPair": {</code> </p> <p> <code> "Username": "username",</code> </p> <p> <code> "Password": "password" } }'</code> </p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   body: JObject (required)
  var path_600146 = newJObject()
  var body_600147 = newJObject()
  add(path_600146, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_600147 = body
  result = call_600145.call(path_600146, nil, nil, nil, body_600147)

var createDataSource* = Call_CreateDataSource_600132(name: "createDataSource",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources",
    validator: validate_CreateDataSource_600133, base: "/",
    url: url_CreateDataSource_600134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataSources_600113 = ref object of OpenApiRestCall_599368
proc url_ListDataSources_600115(protocol: Scheme; host: string; base: string;
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

proc validate_ListDataSources_600114(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Lists data sources in current AWS region that belong to this AWS account.</p> <p>The permissions resource is: <code>arn:aws:quicksight:region:aws-account-id:datasource/*</code> </p> <p>CLI syntax: <code>aws quicksight list-data-sources --aws-account-id=111122223333</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600116 = path.getOrDefault("AwsAccountId")
  valid_600116 = validateParameter(valid_600116, JString, required = true,
                                 default = nil)
  if valid_600116 != nil:
    section.add "AwsAccountId", valid_600116
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600117 = query.getOrDefault("NextToken")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "NextToken", valid_600117
  var valid_600118 = query.getOrDefault("max-results")
  valid_600118 = validateParameter(valid_600118, JInt, required = false, default = nil)
  if valid_600118 != nil:
    section.add "max-results", valid_600118
  var valid_600119 = query.getOrDefault("next-token")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "next-token", valid_600119
  var valid_600120 = query.getOrDefault("MaxResults")
  valid_600120 = validateParameter(valid_600120, JString, required = false,
                                 default = nil)
  if valid_600120 != nil:
    section.add "MaxResults", valid_600120
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
  var valid_600121 = header.getOrDefault("X-Amz-Date")
  valid_600121 = validateParameter(valid_600121, JString, required = false,
                                 default = nil)
  if valid_600121 != nil:
    section.add "X-Amz-Date", valid_600121
  var valid_600122 = header.getOrDefault("X-Amz-Security-Token")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "X-Amz-Security-Token", valid_600122
  var valid_600123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600123 = validateParameter(valid_600123, JString, required = false,
                                 default = nil)
  if valid_600123 != nil:
    section.add "X-Amz-Content-Sha256", valid_600123
  var valid_600124 = header.getOrDefault("X-Amz-Algorithm")
  valid_600124 = validateParameter(valid_600124, JString, required = false,
                                 default = nil)
  if valid_600124 != nil:
    section.add "X-Amz-Algorithm", valid_600124
  var valid_600125 = header.getOrDefault("X-Amz-Signature")
  valid_600125 = validateParameter(valid_600125, JString, required = false,
                                 default = nil)
  if valid_600125 != nil:
    section.add "X-Amz-Signature", valid_600125
  var valid_600126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600126 = validateParameter(valid_600126, JString, required = false,
                                 default = nil)
  if valid_600126 != nil:
    section.add "X-Amz-SignedHeaders", valid_600126
  var valid_600127 = header.getOrDefault("X-Amz-Credential")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Credential", valid_600127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600128: Call_ListDataSources_600113; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists data sources in current AWS region that belong to this AWS account.</p> <p>The permissions resource is: <code>arn:aws:quicksight:region:aws-account-id:datasource/*</code> </p> <p>CLI syntax: <code>aws quicksight list-data-sources --aws-account-id=111122223333</code> </p>
  ## 
  let valid = call_600128.validator(path, query, header, formData, body)
  let scheme = call_600128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600128.url(scheme.get, call_600128.host, call_600128.base,
                         call_600128.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600128, url, valid)

proc call*(call_600129: Call_ListDataSources_600113; AwsAccountId: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listDataSources
  ## <p>Lists data sources in current AWS region that belong to this AWS account.</p> <p>The permissions resource is: <code>arn:aws:quicksight:region:aws-account-id:datasource/*</code> </p> <p>CLI syntax: <code>aws quicksight list-data-sources --aws-account-id=111122223333</code> </p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_600130 = newJObject()
  var query_600131 = newJObject()
  add(path_600130, "AwsAccountId", newJString(AwsAccountId))
  add(query_600131, "NextToken", newJString(NextToken))
  add(query_600131, "max-results", newJInt(maxResults))
  add(query_600131, "next-token", newJString(nextToken))
  add(query_600131, "MaxResults", newJString(MaxResults))
  result = call_600129.call(path_600130, query_600131, nil, nil, nil)

var listDataSources* = Call_ListDataSources_600113(name: "listDataSources",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources",
    validator: validate_ListDataSources_600114, base: "/", url: url_ListDataSources_600115,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroup_600166 = ref object of OpenApiRestCall_599368
proc url_CreateGroup_600168(protocol: Scheme; host: string; base: string;
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

proc validate_CreateGroup_600167(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an Amazon QuickSight group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;relevant-aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a group object.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight create-group --aws-account-id=111122223333 --namespace=default --group-name="Sales-Management" --description="Sales Management - Forecasting" </code> </p>
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
  var valid_600169 = path.getOrDefault("AwsAccountId")
  valid_600169 = validateParameter(valid_600169, JString, required = true,
                                 default = nil)
  if valid_600169 != nil:
    section.add "AwsAccountId", valid_600169
  var valid_600170 = path.getOrDefault("Namespace")
  valid_600170 = validateParameter(valid_600170, JString, required = true,
                                 default = nil)
  if valid_600170 != nil:
    section.add "Namespace", valid_600170
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
  var valid_600171 = header.getOrDefault("X-Amz-Date")
  valid_600171 = validateParameter(valid_600171, JString, required = false,
                                 default = nil)
  if valid_600171 != nil:
    section.add "X-Amz-Date", valid_600171
  var valid_600172 = header.getOrDefault("X-Amz-Security-Token")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-Security-Token", valid_600172
  var valid_600173 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-Content-Sha256", valid_600173
  var valid_600174 = header.getOrDefault("X-Amz-Algorithm")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "X-Amz-Algorithm", valid_600174
  var valid_600175 = header.getOrDefault("X-Amz-Signature")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-Signature", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-SignedHeaders", valid_600176
  var valid_600177 = header.getOrDefault("X-Amz-Credential")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "X-Amz-Credential", valid_600177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600179: Call_CreateGroup_600166; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon QuickSight group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;relevant-aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a group object.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight create-group --aws-account-id=111122223333 --namespace=default --group-name="Sales-Management" --description="Sales Management - Forecasting" </code> </p>
  ## 
  let valid = call_600179.validator(path, query, header, formData, body)
  let scheme = call_600179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600179.url(scheme.get, call_600179.host, call_600179.base,
                         call_600179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600179, url, valid)

proc call*(call_600180: Call_CreateGroup_600166; AwsAccountId: string;
          body: JsonNode; Namespace: string): Recallable =
  ## createGroup
  ## <p>Creates an Amazon QuickSight group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;relevant-aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a group object.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight create-group --aws-account-id=111122223333 --namespace=default --group-name="Sales-Management" --description="Sales Management - Forecasting" </code> </p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   body: JObject (required)
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_600181 = newJObject()
  var body_600182 = newJObject()
  add(path_600181, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_600182 = body
  add(path_600181, "Namespace", newJString(Namespace))
  result = call_600180.call(path_600181, nil, nil, nil, body_600182)

var createGroup* = Call_CreateGroup_600166(name: "createGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups",
                                        validator: validate_CreateGroup_600167,
                                        base: "/", url: url_CreateGroup_600168,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroups_600148 = ref object of OpenApiRestCall_599368
proc url_ListGroups_600150(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListGroups_600149(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists all user groups in Amazon QuickSight. </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/*</code>.</p> <p>The response is a list of group objects. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight list-groups -\-aws-account-id=111122223333 -\-namespace=default </code> </p>
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
  var valid_600151 = path.getOrDefault("AwsAccountId")
  valid_600151 = validateParameter(valid_600151, JString, required = true,
                                 default = nil)
  if valid_600151 != nil:
    section.add "AwsAccountId", valid_600151
  var valid_600152 = path.getOrDefault("Namespace")
  valid_600152 = validateParameter(valid_600152, JString, required = true,
                                 default = nil)
  if valid_600152 != nil:
    section.add "Namespace", valid_600152
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_600153 = query.getOrDefault("max-results")
  valid_600153 = validateParameter(valid_600153, JInt, required = false, default = nil)
  if valid_600153 != nil:
    section.add "max-results", valid_600153
  var valid_600154 = query.getOrDefault("next-token")
  valid_600154 = validateParameter(valid_600154, JString, required = false,
                                 default = nil)
  if valid_600154 != nil:
    section.add "next-token", valid_600154
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
  var valid_600155 = header.getOrDefault("X-Amz-Date")
  valid_600155 = validateParameter(valid_600155, JString, required = false,
                                 default = nil)
  if valid_600155 != nil:
    section.add "X-Amz-Date", valid_600155
  var valid_600156 = header.getOrDefault("X-Amz-Security-Token")
  valid_600156 = validateParameter(valid_600156, JString, required = false,
                                 default = nil)
  if valid_600156 != nil:
    section.add "X-Amz-Security-Token", valid_600156
  var valid_600157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Content-Sha256", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-Algorithm")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Algorithm", valid_600158
  var valid_600159 = header.getOrDefault("X-Amz-Signature")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "X-Amz-Signature", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-SignedHeaders", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-Credential")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Credential", valid_600161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600162: Call_ListGroups_600148; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all user groups in Amazon QuickSight. </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/*</code>.</p> <p>The response is a list of group objects. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight list-groups -\-aws-account-id=111122223333 -\-namespace=default </code> </p>
  ## 
  let valid = call_600162.validator(path, query, header, formData, body)
  let scheme = call_600162.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600162.url(scheme.get, call_600162.host, call_600162.base,
                         call_600162.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600162, url, valid)

proc call*(call_600163: Call_ListGroups_600148; AwsAccountId: string;
          Namespace: string; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listGroups
  ## <p>Lists all user groups in Amazon QuickSight. </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/*</code>.</p> <p>The response is a list of group objects. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight list-groups -\-aws-account-id=111122223333 -\-namespace=default </code> </p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   maxResults: int
  ##             : The maximum number of results to return.
  ##   nextToken: string
  ##            : A pagination token that can be used in a subsequent request.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_600164 = newJObject()
  var query_600165 = newJObject()
  add(path_600164, "AwsAccountId", newJString(AwsAccountId))
  add(query_600165, "max-results", newJInt(maxResults))
  add(query_600165, "next-token", newJString(nextToken))
  add(path_600164, "Namespace", newJString(Namespace))
  result = call_600163.call(path_600164, query_600165, nil, nil, nil)

var listGroups* = Call_ListGroups_600148(name: "listGroups",
                                      meth: HttpMethod.HttpGet,
                                      host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups",
                                      validator: validate_ListGroups_600149,
                                      base: "/", url: url_ListGroups_600150,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroupMembership_600183 = ref object of OpenApiRestCall_599368
proc url_CreateGroupMembership_600185(protocol: Scheme; host: string; base: string;
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

proc validate_CreateGroupMembership_600184(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds an Amazon QuickSight user to an Amazon QuickSight group. </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The condition resource is the user name.</p> <p>The condition key is <code>quicksight:UserName</code>.</p> <p>The response is the group member object.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight create-group-membership --aws-account-id=111122223333 --namespace=default --group-name=Sales --member-name=Pat </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the group that you want to add the user to.
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   MemberName: JString (required)
  ##             : The name of the user that you want to add to the group membership.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_600186 = path.getOrDefault("GroupName")
  valid_600186 = validateParameter(valid_600186, JString, required = true,
                                 default = nil)
  if valid_600186 != nil:
    section.add "GroupName", valid_600186
  var valid_600187 = path.getOrDefault("AwsAccountId")
  valid_600187 = validateParameter(valid_600187, JString, required = true,
                                 default = nil)
  if valid_600187 != nil:
    section.add "AwsAccountId", valid_600187
  var valid_600188 = path.getOrDefault("MemberName")
  valid_600188 = validateParameter(valid_600188, JString, required = true,
                                 default = nil)
  if valid_600188 != nil:
    section.add "MemberName", valid_600188
  var valid_600189 = path.getOrDefault("Namespace")
  valid_600189 = validateParameter(valid_600189, JString, required = true,
                                 default = nil)
  if valid_600189 != nil:
    section.add "Namespace", valid_600189
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
  var valid_600190 = header.getOrDefault("X-Amz-Date")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-Date", valid_600190
  var valid_600191 = header.getOrDefault("X-Amz-Security-Token")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "X-Amz-Security-Token", valid_600191
  var valid_600192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "X-Amz-Content-Sha256", valid_600192
  var valid_600193 = header.getOrDefault("X-Amz-Algorithm")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "X-Amz-Algorithm", valid_600193
  var valid_600194 = header.getOrDefault("X-Amz-Signature")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-Signature", valid_600194
  var valid_600195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600195 = validateParameter(valid_600195, JString, required = false,
                                 default = nil)
  if valid_600195 != nil:
    section.add "X-Amz-SignedHeaders", valid_600195
  var valid_600196 = header.getOrDefault("X-Amz-Credential")
  valid_600196 = validateParameter(valid_600196, JString, required = false,
                                 default = nil)
  if valid_600196 != nil:
    section.add "X-Amz-Credential", valid_600196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600197: Call_CreateGroupMembership_600183; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds an Amazon QuickSight user to an Amazon QuickSight group. </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The condition resource is the user name.</p> <p>The condition key is <code>quicksight:UserName</code>.</p> <p>The response is the group member object.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight create-group-membership --aws-account-id=111122223333 --namespace=default --group-name=Sales --member-name=Pat </code> </p>
  ## 
  let valid = call_600197.validator(path, query, header, formData, body)
  let scheme = call_600197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600197.url(scheme.get, call_600197.host, call_600197.base,
                         call_600197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600197, url, valid)

proc call*(call_600198: Call_CreateGroupMembership_600183; GroupName: string;
          AwsAccountId: string; MemberName: string; Namespace: string): Recallable =
  ## createGroupMembership
  ## <p>Adds an Amazon QuickSight user to an Amazon QuickSight group. </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The condition resource is the user name.</p> <p>The condition key is <code>quicksight:UserName</code>.</p> <p>The response is the group member object.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight create-group-membership --aws-account-id=111122223333 --namespace=default --group-name=Sales --member-name=Pat </code> </p>
  ##   GroupName: string (required)
  ##            : The name of the group that you want to add the user to.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   MemberName: string (required)
  ##             : The name of the user that you want to add to the group membership.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_600199 = newJObject()
  add(path_600199, "GroupName", newJString(GroupName))
  add(path_600199, "AwsAccountId", newJString(AwsAccountId))
  add(path_600199, "MemberName", newJString(MemberName))
  add(path_600199, "Namespace", newJString(Namespace))
  result = call_600198.call(path_600199, nil, nil, nil, nil)

var createGroupMembership* = Call_CreateGroupMembership_600183(
    name: "createGroupMembership", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members/{MemberName}",
    validator: validate_CreateGroupMembership_600184, base: "/",
    url: url_CreateGroupMembership_600185, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroupMembership_600200 = ref object of OpenApiRestCall_599368
proc url_DeleteGroupMembership_600202(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGroupMembership_600201(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes a user from a group so that the user is no longer a member of the group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The condition resource is the user name.</p> <p>The condition key is <code>quicksight:UserName</code>.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight delete-group-membership --aws-account-id=111122223333 --namespace=default --group-name=Sales-Management --member-name=Charlie </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   GroupName: JString (required)
  ##            : The name of the group that you want to delete the user from.
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   MemberName: JString (required)
  ##             : The name of the user that you want to delete from the group membership.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `GroupName` field"
  var valid_600203 = path.getOrDefault("GroupName")
  valid_600203 = validateParameter(valid_600203, JString, required = true,
                                 default = nil)
  if valid_600203 != nil:
    section.add "GroupName", valid_600203
  var valid_600204 = path.getOrDefault("AwsAccountId")
  valid_600204 = validateParameter(valid_600204, JString, required = true,
                                 default = nil)
  if valid_600204 != nil:
    section.add "AwsAccountId", valid_600204
  var valid_600205 = path.getOrDefault("MemberName")
  valid_600205 = validateParameter(valid_600205, JString, required = true,
                                 default = nil)
  if valid_600205 != nil:
    section.add "MemberName", valid_600205
  var valid_600206 = path.getOrDefault("Namespace")
  valid_600206 = validateParameter(valid_600206, JString, required = true,
                                 default = nil)
  if valid_600206 != nil:
    section.add "Namespace", valid_600206
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
  var valid_600207 = header.getOrDefault("X-Amz-Date")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "X-Amz-Date", valid_600207
  var valid_600208 = header.getOrDefault("X-Amz-Security-Token")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "X-Amz-Security-Token", valid_600208
  var valid_600209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "X-Amz-Content-Sha256", valid_600209
  var valid_600210 = header.getOrDefault("X-Amz-Algorithm")
  valid_600210 = validateParameter(valid_600210, JString, required = false,
                                 default = nil)
  if valid_600210 != nil:
    section.add "X-Amz-Algorithm", valid_600210
  var valid_600211 = header.getOrDefault("X-Amz-Signature")
  valid_600211 = validateParameter(valid_600211, JString, required = false,
                                 default = nil)
  if valid_600211 != nil:
    section.add "X-Amz-Signature", valid_600211
  var valid_600212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600212 = validateParameter(valid_600212, JString, required = false,
                                 default = nil)
  if valid_600212 != nil:
    section.add "X-Amz-SignedHeaders", valid_600212
  var valid_600213 = header.getOrDefault("X-Amz-Credential")
  valid_600213 = validateParameter(valid_600213, JString, required = false,
                                 default = nil)
  if valid_600213 != nil:
    section.add "X-Amz-Credential", valid_600213
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600214: Call_DeleteGroupMembership_600200; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a user from a group so that the user is no longer a member of the group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The condition resource is the user name.</p> <p>The condition key is <code>quicksight:UserName</code>.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight delete-group-membership --aws-account-id=111122223333 --namespace=default --group-name=Sales-Management --member-name=Charlie </code> </p>
  ## 
  let valid = call_600214.validator(path, query, header, formData, body)
  let scheme = call_600214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600214.url(scheme.get, call_600214.host, call_600214.base,
                         call_600214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600214, url, valid)

proc call*(call_600215: Call_DeleteGroupMembership_600200; GroupName: string;
          AwsAccountId: string; MemberName: string; Namespace: string): Recallable =
  ## deleteGroupMembership
  ## <p>Removes a user from a group so that the user is no longer a member of the group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The condition resource is the user name.</p> <p>The condition key is <code>quicksight:UserName</code>.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight delete-group-membership --aws-account-id=111122223333 --namespace=default --group-name=Sales-Management --member-name=Charlie </code> </p>
  ##   GroupName: string (required)
  ##            : The name of the group that you want to delete the user from.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   MemberName: string (required)
  ##             : The name of the user that you want to delete from the group membership.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_600216 = newJObject()
  add(path_600216, "GroupName", newJString(GroupName))
  add(path_600216, "AwsAccountId", newJString(AwsAccountId))
  add(path_600216, "MemberName", newJString(MemberName))
  add(path_600216, "Namespace", newJString(Namespace))
  result = call_600215.call(path_600216, nil, nil, nil, nil)

var deleteGroupMembership* = Call_DeleteGroupMembership_600200(
    name: "deleteGroupMembership", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members/{MemberName}",
    validator: validate_DeleteGroupMembership_600201, base: "/",
    url: url_DeleteGroupMembership_600202, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateIAMPolicyAssignment_600217 = ref object of OpenApiRestCall_599368
proc url_CreateIAMPolicyAssignment_600219(protocol: Scheme; host: string;
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

proc validate_CreateIAMPolicyAssignment_600218(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an assignment with one specified IAM policy ARN and will assigned to specified groups or users of QuickSight. Users and groups need to be in the same namespace. </p> <p>CLI syntax:</p> <p> <code>aws quicksight create-iam-policy-assignment --aws-account-id=111122223333 --assignment-name=helpAssignment --policy-arn=arn:aws:iam::aws:policy/AdministratorAccess --identities="user=user5,engineer123,group=QS-Admin" --namespace=default --region=us-west-2</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS Account ID where you want to assign QuickSight users or groups to an IAM policy.
  ##   Namespace: JString (required)
  ##            : The namespace that contains the assignment.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600220 = path.getOrDefault("AwsAccountId")
  valid_600220 = validateParameter(valid_600220, JString, required = true,
                                 default = nil)
  if valid_600220 != nil:
    section.add "AwsAccountId", valid_600220
  var valid_600221 = path.getOrDefault("Namespace")
  valid_600221 = validateParameter(valid_600221, JString, required = true,
                                 default = nil)
  if valid_600221 != nil:
    section.add "Namespace", valid_600221
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
  var valid_600222 = header.getOrDefault("X-Amz-Date")
  valid_600222 = validateParameter(valid_600222, JString, required = false,
                                 default = nil)
  if valid_600222 != nil:
    section.add "X-Amz-Date", valid_600222
  var valid_600223 = header.getOrDefault("X-Amz-Security-Token")
  valid_600223 = validateParameter(valid_600223, JString, required = false,
                                 default = nil)
  if valid_600223 != nil:
    section.add "X-Amz-Security-Token", valid_600223
  var valid_600224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600224 = validateParameter(valid_600224, JString, required = false,
                                 default = nil)
  if valid_600224 != nil:
    section.add "X-Amz-Content-Sha256", valid_600224
  var valid_600225 = header.getOrDefault("X-Amz-Algorithm")
  valid_600225 = validateParameter(valid_600225, JString, required = false,
                                 default = nil)
  if valid_600225 != nil:
    section.add "X-Amz-Algorithm", valid_600225
  var valid_600226 = header.getOrDefault("X-Amz-Signature")
  valid_600226 = validateParameter(valid_600226, JString, required = false,
                                 default = nil)
  if valid_600226 != nil:
    section.add "X-Amz-Signature", valid_600226
  var valid_600227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600227 = validateParameter(valid_600227, JString, required = false,
                                 default = nil)
  if valid_600227 != nil:
    section.add "X-Amz-SignedHeaders", valid_600227
  var valid_600228 = header.getOrDefault("X-Amz-Credential")
  valid_600228 = validateParameter(valid_600228, JString, required = false,
                                 default = nil)
  if valid_600228 != nil:
    section.add "X-Amz-Credential", valid_600228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600230: Call_CreateIAMPolicyAssignment_600217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an assignment with one specified IAM policy ARN and will assigned to specified groups or users of QuickSight. Users and groups need to be in the same namespace. </p> <p>CLI syntax:</p> <p> <code>aws quicksight create-iam-policy-assignment --aws-account-id=111122223333 --assignment-name=helpAssignment --policy-arn=arn:aws:iam::aws:policy/AdministratorAccess --identities="user=user5,engineer123,group=QS-Admin" --namespace=default --region=us-west-2</code> </p>
  ## 
  let valid = call_600230.validator(path, query, header, formData, body)
  let scheme = call_600230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600230.url(scheme.get, call_600230.host, call_600230.base,
                         call_600230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600230, url, valid)

proc call*(call_600231: Call_CreateIAMPolicyAssignment_600217;
          AwsAccountId: string; body: JsonNode; Namespace: string): Recallable =
  ## createIAMPolicyAssignment
  ## <p>Creates an assignment with one specified IAM policy ARN and will assigned to specified groups or users of QuickSight. Users and groups need to be in the same namespace. </p> <p>CLI syntax:</p> <p> <code>aws quicksight create-iam-policy-assignment --aws-account-id=111122223333 --assignment-name=helpAssignment --policy-arn=arn:aws:iam::aws:policy/AdministratorAccess --identities="user=user5,engineer123,group=QS-Admin" --namespace=default --region=us-west-2</code> </p>
  ##   AwsAccountId: string (required)
  ##               : The AWS Account ID where you want to assign QuickSight users or groups to an IAM policy.
  ##   body: JObject (required)
  ##   Namespace: string (required)
  ##            : The namespace that contains the assignment.
  var path_600232 = newJObject()
  var body_600233 = newJObject()
  add(path_600232, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_600233 = body
  add(path_600232, "Namespace", newJString(Namespace))
  result = call_600231.call(path_600232, nil, nil, nil, body_600233)

var createIAMPolicyAssignment* = Call_CreateIAMPolicyAssignment_600217(
    name: "createIAMPolicyAssignment", meth: HttpMethod.HttpPost,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/",
    validator: validate_CreateIAMPolicyAssignment_600218, base: "/",
    url: url_CreateIAMPolicyAssignment_600219,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTemplate_600252 = ref object of OpenApiRestCall_599368
proc url_UpdateTemplate_600254(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateTemplate_600253(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Updates a template from an existing QuickSight analysis.</p> <p>CLI syntax:</p> <p> <code>aws quicksight update-template --aws-account-id 111122223333 --template-id reports_test_template --data-set-references DataSetPlaceholder=reports,DataSetArn=arn:aws:quicksight:us-west-2:111122223333:dataset/c684a204-d134-4c53-a63c-451f72c60c28 DataSetPlaceholder=Elblogs,DataSetArn=arn:aws:quicksight:us-west-2:111122223333:dataset/15840b7d-b542-4491-937b-602416b367b3 —source-entity SourceAnalysis=’{Arn=arn:aws:quicksight:us-west-2:111122223333:analysis/c5731fe9-4708-4598-8f6d-cf2a70875b6d}</code> </p> <p>You can also pass in a json file: <code>aws quicksight update-template —cli-input-json file://create-template.json</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : AWS account ID that contains the template you are updating.
  ##   TemplateId: JString (required)
  ##             : The ID for the template.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600255 = path.getOrDefault("AwsAccountId")
  valid_600255 = validateParameter(valid_600255, JString, required = true,
                                 default = nil)
  if valid_600255 != nil:
    section.add "AwsAccountId", valid_600255
  var valid_600256 = path.getOrDefault("TemplateId")
  valid_600256 = validateParameter(valid_600256, JString, required = true,
                                 default = nil)
  if valid_600256 != nil:
    section.add "TemplateId", valid_600256
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
  var valid_600257 = header.getOrDefault("X-Amz-Date")
  valid_600257 = validateParameter(valid_600257, JString, required = false,
                                 default = nil)
  if valid_600257 != nil:
    section.add "X-Amz-Date", valid_600257
  var valid_600258 = header.getOrDefault("X-Amz-Security-Token")
  valid_600258 = validateParameter(valid_600258, JString, required = false,
                                 default = nil)
  if valid_600258 != nil:
    section.add "X-Amz-Security-Token", valid_600258
  var valid_600259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600259 = validateParameter(valid_600259, JString, required = false,
                                 default = nil)
  if valid_600259 != nil:
    section.add "X-Amz-Content-Sha256", valid_600259
  var valid_600260 = header.getOrDefault("X-Amz-Algorithm")
  valid_600260 = validateParameter(valid_600260, JString, required = false,
                                 default = nil)
  if valid_600260 != nil:
    section.add "X-Amz-Algorithm", valid_600260
  var valid_600261 = header.getOrDefault("X-Amz-Signature")
  valid_600261 = validateParameter(valid_600261, JString, required = false,
                                 default = nil)
  if valid_600261 != nil:
    section.add "X-Amz-Signature", valid_600261
  var valid_600262 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600262 = validateParameter(valid_600262, JString, required = false,
                                 default = nil)
  if valid_600262 != nil:
    section.add "X-Amz-SignedHeaders", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-Credential")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Credential", valid_600263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600265: Call_UpdateTemplate_600252; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a template from an existing QuickSight analysis.</p> <p>CLI syntax:</p> <p> <code>aws quicksight update-template --aws-account-id 111122223333 --template-id reports_test_template --data-set-references DataSetPlaceholder=reports,DataSetArn=arn:aws:quicksight:us-west-2:111122223333:dataset/c684a204-d134-4c53-a63c-451f72c60c28 DataSetPlaceholder=Elblogs,DataSetArn=arn:aws:quicksight:us-west-2:111122223333:dataset/15840b7d-b542-4491-937b-602416b367b3 —source-entity SourceAnalysis=’{Arn=arn:aws:quicksight:us-west-2:111122223333:analysis/c5731fe9-4708-4598-8f6d-cf2a70875b6d}</code> </p> <p>You can also pass in a json file: <code>aws quicksight update-template —cli-input-json file://create-template.json</code> </p>
  ## 
  let valid = call_600265.validator(path, query, header, formData, body)
  let scheme = call_600265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600265.url(scheme.get, call_600265.host, call_600265.base,
                         call_600265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600265, url, valid)

proc call*(call_600266: Call_UpdateTemplate_600252; AwsAccountId: string;
          TemplateId: string; body: JsonNode): Recallable =
  ## updateTemplate
  ## <p>Updates a template from an existing QuickSight analysis.</p> <p>CLI syntax:</p> <p> <code>aws quicksight update-template --aws-account-id 111122223333 --template-id reports_test_template --data-set-references DataSetPlaceholder=reports,DataSetArn=arn:aws:quicksight:us-west-2:111122223333:dataset/c684a204-d134-4c53-a63c-451f72c60c28 DataSetPlaceholder=Elblogs,DataSetArn=arn:aws:quicksight:us-west-2:111122223333:dataset/15840b7d-b542-4491-937b-602416b367b3 —source-entity SourceAnalysis=’{Arn=arn:aws:quicksight:us-west-2:111122223333:analysis/c5731fe9-4708-4598-8f6d-cf2a70875b6d}</code> </p> <p>You can also pass in a json file: <code>aws quicksight update-template —cli-input-json file://create-template.json</code> </p>
  ##   AwsAccountId: string (required)
  ##               : AWS account ID that contains the template you are updating.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  ##   body: JObject (required)
  var path_600267 = newJObject()
  var body_600268 = newJObject()
  add(path_600267, "AwsAccountId", newJString(AwsAccountId))
  add(path_600267, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_600268 = body
  result = call_600266.call(path_600267, nil, nil, nil, body_600268)

var updateTemplate* = Call_UpdateTemplate_600252(name: "updateTemplate",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}",
    validator: validate_UpdateTemplate_600253, base: "/", url: url_UpdateTemplate_600254,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTemplate_600269 = ref object of OpenApiRestCall_599368
proc url_CreateTemplate_600271(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTemplate_600270(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Creates a template from an existing QuickSight analysis or template. The resulting template can be used to create a dashboard.</p> <p>A template is an entity in QuickSight which encapsulates the metadata required to create an analysis that can be used to create dashboard. It adds a layer of abstraction by use placeholders to replace the dataset associated with the analysis. You can use templates to create dashboards by replacing dataset placeholders with datasets which follow the same schema that was used to create the source analysis and template.</p> <p>To create a template from an existing analysis, use the analysis's ARN, <code>aws-account-id</code>, <code>template-id</code>, <code>source-entity</code>, and <code>data-set-references</code>.</p> <p>CLI syntax to create a template: </p> <p> <code>aws quicksight create-template —cli-input-json file://create-template.json</code> </p> <p>CLI syntax to create a template from another template in the same AWS account:</p> <p> <code>aws quicksight create-template --aws-account-id 111122223333 --template-id reports_test_template --data-set-references DataSetPlaceholder=reports,DataSetArn=arn:aws:quicksight:us-west-2:111122223333:dataset/0dfc789c-81f6-4f4f-b9ac-7db2453eefc8 DataSetPlaceholder=Elblogs,DataSetArn=arn:aws:quicksight:us-west-2:111122223333:dataset/f60da323-af68-45db-9016-08e0d1d7ded5 --source-entity SourceAnalysis='{Arn=arn:aws:quicksight:us-west-2:111122223333:analysis/7fb74527-c36d-4be8-8139-ac1be4c97365}'</code> </p> <p>To create template from another account’s template, you need to grant cross account resource permission for DescribeTemplate the account that contains the template.</p> <p>You can use a file to pass JSON to the function if you prefer. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   TemplateId: JString (required)
  ##             : An ID for the template you want to create. This is unique per AWS region per AWS account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600272 = path.getOrDefault("AwsAccountId")
  valid_600272 = validateParameter(valid_600272, JString, required = true,
                                 default = nil)
  if valid_600272 != nil:
    section.add "AwsAccountId", valid_600272
  var valid_600273 = path.getOrDefault("TemplateId")
  valid_600273 = validateParameter(valid_600273, JString, required = true,
                                 default = nil)
  if valid_600273 != nil:
    section.add "TemplateId", valid_600273
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
  var valid_600274 = header.getOrDefault("X-Amz-Date")
  valid_600274 = validateParameter(valid_600274, JString, required = false,
                                 default = nil)
  if valid_600274 != nil:
    section.add "X-Amz-Date", valid_600274
  var valid_600275 = header.getOrDefault("X-Amz-Security-Token")
  valid_600275 = validateParameter(valid_600275, JString, required = false,
                                 default = nil)
  if valid_600275 != nil:
    section.add "X-Amz-Security-Token", valid_600275
  var valid_600276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600276 = validateParameter(valid_600276, JString, required = false,
                                 default = nil)
  if valid_600276 != nil:
    section.add "X-Amz-Content-Sha256", valid_600276
  var valid_600277 = header.getOrDefault("X-Amz-Algorithm")
  valid_600277 = validateParameter(valid_600277, JString, required = false,
                                 default = nil)
  if valid_600277 != nil:
    section.add "X-Amz-Algorithm", valid_600277
  var valid_600278 = header.getOrDefault("X-Amz-Signature")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-Signature", valid_600278
  var valid_600279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600279 = validateParameter(valid_600279, JString, required = false,
                                 default = nil)
  if valid_600279 != nil:
    section.add "X-Amz-SignedHeaders", valid_600279
  var valid_600280 = header.getOrDefault("X-Amz-Credential")
  valid_600280 = validateParameter(valid_600280, JString, required = false,
                                 default = nil)
  if valid_600280 != nil:
    section.add "X-Amz-Credential", valid_600280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600282: Call_CreateTemplate_600269; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a template from an existing QuickSight analysis or template. The resulting template can be used to create a dashboard.</p> <p>A template is an entity in QuickSight which encapsulates the metadata required to create an analysis that can be used to create dashboard. It adds a layer of abstraction by use placeholders to replace the dataset associated with the analysis. You can use templates to create dashboards by replacing dataset placeholders with datasets which follow the same schema that was used to create the source analysis and template.</p> <p>To create a template from an existing analysis, use the analysis's ARN, <code>aws-account-id</code>, <code>template-id</code>, <code>source-entity</code>, and <code>data-set-references</code>.</p> <p>CLI syntax to create a template: </p> <p> <code>aws quicksight create-template —cli-input-json file://create-template.json</code> </p> <p>CLI syntax to create a template from another template in the same AWS account:</p> <p> <code>aws quicksight create-template --aws-account-id 111122223333 --template-id reports_test_template --data-set-references DataSetPlaceholder=reports,DataSetArn=arn:aws:quicksight:us-west-2:111122223333:dataset/0dfc789c-81f6-4f4f-b9ac-7db2453eefc8 DataSetPlaceholder=Elblogs,DataSetArn=arn:aws:quicksight:us-west-2:111122223333:dataset/f60da323-af68-45db-9016-08e0d1d7ded5 --source-entity SourceAnalysis='{Arn=arn:aws:quicksight:us-west-2:111122223333:analysis/7fb74527-c36d-4be8-8139-ac1be4c97365}'</code> </p> <p>To create template from another account’s template, you need to grant cross account resource permission for DescribeTemplate the account that contains the template.</p> <p>You can use a file to pass JSON to the function if you prefer. </p>
  ## 
  let valid = call_600282.validator(path, query, header, formData, body)
  let scheme = call_600282.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600282.url(scheme.get, call_600282.host, call_600282.base,
                         call_600282.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600282, url, valid)

proc call*(call_600283: Call_CreateTemplate_600269; AwsAccountId: string;
          TemplateId: string; body: JsonNode): Recallable =
  ## createTemplate
  ## <p>Creates a template from an existing QuickSight analysis or template. The resulting template can be used to create a dashboard.</p> <p>A template is an entity in QuickSight which encapsulates the metadata required to create an analysis that can be used to create dashboard. It adds a layer of abstraction by use placeholders to replace the dataset associated with the analysis. You can use templates to create dashboards by replacing dataset placeholders with datasets which follow the same schema that was used to create the source analysis and template.</p> <p>To create a template from an existing analysis, use the analysis's ARN, <code>aws-account-id</code>, <code>template-id</code>, <code>source-entity</code>, and <code>data-set-references</code>.</p> <p>CLI syntax to create a template: </p> <p> <code>aws quicksight create-template —cli-input-json file://create-template.json</code> </p> <p>CLI syntax to create a template from another template in the same AWS account:</p> <p> <code>aws quicksight create-template --aws-account-id 111122223333 --template-id reports_test_template --data-set-references DataSetPlaceholder=reports,DataSetArn=arn:aws:quicksight:us-west-2:111122223333:dataset/0dfc789c-81f6-4f4f-b9ac-7db2453eefc8 DataSetPlaceholder=Elblogs,DataSetArn=arn:aws:quicksight:us-west-2:111122223333:dataset/f60da323-af68-45db-9016-08e0d1d7ded5 --source-entity SourceAnalysis='{Arn=arn:aws:quicksight:us-west-2:111122223333:analysis/7fb74527-c36d-4be8-8139-ac1be4c97365}'</code> </p> <p>To create template from another account’s template, you need to grant cross account resource permission for DescribeTemplate the account that contains the template.</p> <p>You can use a file to pass JSON to the function if you prefer. </p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   TemplateId: string (required)
  ##             : An ID for the template you want to create. This is unique per AWS region per AWS account.
  ##   body: JObject (required)
  var path_600284 = newJObject()
  var body_600285 = newJObject()
  add(path_600284, "AwsAccountId", newJString(AwsAccountId))
  add(path_600284, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_600285 = body
  result = call_600283.call(path_600284, nil, nil, nil, body_600285)

var createTemplate* = Call_CreateTemplate_600269(name: "createTemplate",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}",
    validator: validate_CreateTemplate_600270, base: "/", url: url_CreateTemplate_600271,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTemplate_600234 = ref object of OpenApiRestCall_599368
proc url_DescribeTemplate_600236(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTemplate_600235(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Describes a template's metadata.</p> <p>CLI syntax:</p> <p> <code>aws quicksight describe-template --aws-account-id 111122223333 --template-id reports_test_template </code> </p> <p> <code>aws quicksight describe-template --aws-account-id 111122223333 --template-id reports_test_template --version-number-2</code> </p> <p> <code>aws quicksight describe-template --aws-account-id 111122223333 --template-id reports_test_template --alias-name '\$LATEST' </code> </p> <p>Users can explicitly describe the latest version of the dashboard by passing <code>$LATEST</code> to the <code>alias-name</code> parameter. <code>$LATEST</code> is an internally supported alias, which points to the latest version of the dashboard. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : AWS account ID that contains the template you are describing.
  ##   TemplateId: JString (required)
  ##             : An ID for the template.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600237 = path.getOrDefault("AwsAccountId")
  valid_600237 = validateParameter(valid_600237, JString, required = true,
                                 default = nil)
  if valid_600237 != nil:
    section.add "AwsAccountId", valid_600237
  var valid_600238 = path.getOrDefault("TemplateId")
  valid_600238 = validateParameter(valid_600238, JString, required = true,
                                 default = nil)
  if valid_600238 != nil:
    section.add "TemplateId", valid_600238
  result.add "path", section
  ## parameters in `query` object:
  ##   alias-name: JString
  ##             : This is an optional field, when an alias name is provided, the version referenced by the alias is described. Refer to <code>CreateTemplateAlias</code> to create a template alias. <code>$PUBLISHED</code> is not supported for template.
  ##   version-number: JInt
  ##                 : This is an optional field, when a version number is provided the corresponding version is describe, if it's not provided the latest version of the template is described.
  section = newJObject()
  var valid_600239 = query.getOrDefault("alias-name")
  valid_600239 = validateParameter(valid_600239, JString, required = false,
                                 default = nil)
  if valid_600239 != nil:
    section.add "alias-name", valid_600239
  var valid_600240 = query.getOrDefault("version-number")
  valid_600240 = validateParameter(valid_600240, JInt, required = false, default = nil)
  if valid_600240 != nil:
    section.add "version-number", valid_600240
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
  var valid_600241 = header.getOrDefault("X-Amz-Date")
  valid_600241 = validateParameter(valid_600241, JString, required = false,
                                 default = nil)
  if valid_600241 != nil:
    section.add "X-Amz-Date", valid_600241
  var valid_600242 = header.getOrDefault("X-Amz-Security-Token")
  valid_600242 = validateParameter(valid_600242, JString, required = false,
                                 default = nil)
  if valid_600242 != nil:
    section.add "X-Amz-Security-Token", valid_600242
  var valid_600243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600243 = validateParameter(valid_600243, JString, required = false,
                                 default = nil)
  if valid_600243 != nil:
    section.add "X-Amz-Content-Sha256", valid_600243
  var valid_600244 = header.getOrDefault("X-Amz-Algorithm")
  valid_600244 = validateParameter(valid_600244, JString, required = false,
                                 default = nil)
  if valid_600244 != nil:
    section.add "X-Amz-Algorithm", valid_600244
  var valid_600245 = header.getOrDefault("X-Amz-Signature")
  valid_600245 = validateParameter(valid_600245, JString, required = false,
                                 default = nil)
  if valid_600245 != nil:
    section.add "X-Amz-Signature", valid_600245
  var valid_600246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600246 = validateParameter(valid_600246, JString, required = false,
                                 default = nil)
  if valid_600246 != nil:
    section.add "X-Amz-SignedHeaders", valid_600246
  var valid_600247 = header.getOrDefault("X-Amz-Credential")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "X-Amz-Credential", valid_600247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600248: Call_DescribeTemplate_600234; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes a template's metadata.</p> <p>CLI syntax:</p> <p> <code>aws quicksight describe-template --aws-account-id 111122223333 --template-id reports_test_template </code> </p> <p> <code>aws quicksight describe-template --aws-account-id 111122223333 --template-id reports_test_template --version-number-2</code> </p> <p> <code>aws quicksight describe-template --aws-account-id 111122223333 --template-id reports_test_template --alias-name '\$LATEST' </code> </p> <p>Users can explicitly describe the latest version of the dashboard by passing <code>$LATEST</code> to the <code>alias-name</code> parameter. <code>$LATEST</code> is an internally supported alias, which points to the latest version of the dashboard. </p>
  ## 
  let valid = call_600248.validator(path, query, header, formData, body)
  let scheme = call_600248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600248.url(scheme.get, call_600248.host, call_600248.base,
                         call_600248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600248, url, valid)

proc call*(call_600249: Call_DescribeTemplate_600234; AwsAccountId: string;
          TemplateId: string; aliasName: string = ""; versionNumber: int = 0): Recallable =
  ## describeTemplate
  ## <p>Describes a template's metadata.</p> <p>CLI syntax:</p> <p> <code>aws quicksight describe-template --aws-account-id 111122223333 --template-id reports_test_template </code> </p> <p> <code>aws quicksight describe-template --aws-account-id 111122223333 --template-id reports_test_template --version-number-2</code> </p> <p> <code>aws quicksight describe-template --aws-account-id 111122223333 --template-id reports_test_template --alias-name '\$LATEST' </code> </p> <p>Users can explicitly describe the latest version of the dashboard by passing <code>$LATEST</code> to the <code>alias-name</code> parameter. <code>$LATEST</code> is an internally supported alias, which points to the latest version of the dashboard. </p>
  ##   AwsAccountId: string (required)
  ##               : AWS account ID that contains the template you are describing.
  ##   TemplateId: string (required)
  ##             : An ID for the template.
  ##   aliasName: string
  ##            : This is an optional field, when an alias name is provided, the version referenced by the alias is described. Refer to <code>CreateTemplateAlias</code> to create a template alias. <code>$PUBLISHED</code> is not supported for template.
  ##   versionNumber: int
  ##                : This is an optional field, when a version number is provided the corresponding version is describe, if it's not provided the latest version of the template is described.
  var path_600250 = newJObject()
  var query_600251 = newJObject()
  add(path_600250, "AwsAccountId", newJString(AwsAccountId))
  add(path_600250, "TemplateId", newJString(TemplateId))
  add(query_600251, "alias-name", newJString(aliasName))
  add(query_600251, "version-number", newJInt(versionNumber))
  result = call_600249.call(path_600250, query_600251, nil, nil, nil)

var describeTemplate* = Call_DescribeTemplate_600234(name: "describeTemplate",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}",
    validator: validate_DescribeTemplate_600235, base: "/",
    url: url_DescribeTemplate_600236, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTemplate_600286 = ref object of OpenApiRestCall_599368
proc url_DeleteTemplate_600288(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTemplate_600287(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Deletes a template.</p> <p>CLI syntax:</p> <ul> <li> <p> <code>aws quicksight delete-template --aws-account-id 111122223333 —-template-id reports_test_template --version-number 2 </code> </p> </li> <li> <p> <code>aws quicksight delete-template —aws-account-id 111122223333 —template-id reports_test_template —alias-name STAGING </code> </p> </li> <li> <p> <code>aws quicksight delete-template —aws-account-id 111122223333 —template-id reports_test_template —alias-name ‘\$LATEST’ </code> </p> </li> <li> <p> <code>aws quicksight delete-template --aws-account-id 111122223333 —-template-id reports_test_template</code> </p> </li> </ul> <p>If version number which is an optional field is not passed the template (including all the versions) is deleted by the API, if version number is provided, the specific template version is deleted by the API.</p> <p>Users can explicitly describe the latest version of the template by passing <code>$LATEST</code> to the <code>alias-name</code> parameter. <code>$LATEST</code> is an internally supported alias, which points to the latest version of the template. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : AWS account ID that contains the template you are deleting.
  ##   TemplateId: JString (required)
  ##             : An ID for the template you want to delete.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600289 = path.getOrDefault("AwsAccountId")
  valid_600289 = validateParameter(valid_600289, JString, required = true,
                                 default = nil)
  if valid_600289 != nil:
    section.add "AwsAccountId", valid_600289
  var valid_600290 = path.getOrDefault("TemplateId")
  valid_600290 = validateParameter(valid_600290, JString, required = true,
                                 default = nil)
  if valid_600290 != nil:
    section.add "TemplateId", valid_600290
  result.add "path", section
  ## parameters in `query` object:
  ##   version-number: JInt
  ##                 : The version number
  section = newJObject()
  var valid_600291 = query.getOrDefault("version-number")
  valid_600291 = validateParameter(valid_600291, JInt, required = false, default = nil)
  if valid_600291 != nil:
    section.add "version-number", valid_600291
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
  var valid_600292 = header.getOrDefault("X-Amz-Date")
  valid_600292 = validateParameter(valid_600292, JString, required = false,
                                 default = nil)
  if valid_600292 != nil:
    section.add "X-Amz-Date", valid_600292
  var valid_600293 = header.getOrDefault("X-Amz-Security-Token")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-Security-Token", valid_600293
  var valid_600294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600294 = validateParameter(valid_600294, JString, required = false,
                                 default = nil)
  if valid_600294 != nil:
    section.add "X-Amz-Content-Sha256", valid_600294
  var valid_600295 = header.getOrDefault("X-Amz-Algorithm")
  valid_600295 = validateParameter(valid_600295, JString, required = false,
                                 default = nil)
  if valid_600295 != nil:
    section.add "X-Amz-Algorithm", valid_600295
  var valid_600296 = header.getOrDefault("X-Amz-Signature")
  valid_600296 = validateParameter(valid_600296, JString, required = false,
                                 default = nil)
  if valid_600296 != nil:
    section.add "X-Amz-Signature", valid_600296
  var valid_600297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600297 = validateParameter(valid_600297, JString, required = false,
                                 default = nil)
  if valid_600297 != nil:
    section.add "X-Amz-SignedHeaders", valid_600297
  var valid_600298 = header.getOrDefault("X-Amz-Credential")
  valid_600298 = validateParameter(valid_600298, JString, required = false,
                                 default = nil)
  if valid_600298 != nil:
    section.add "X-Amz-Credential", valid_600298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600299: Call_DeleteTemplate_600286; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a template.</p> <p>CLI syntax:</p> <ul> <li> <p> <code>aws quicksight delete-template --aws-account-id 111122223333 —-template-id reports_test_template --version-number 2 </code> </p> </li> <li> <p> <code>aws quicksight delete-template —aws-account-id 111122223333 —template-id reports_test_template —alias-name STAGING </code> </p> </li> <li> <p> <code>aws quicksight delete-template —aws-account-id 111122223333 —template-id reports_test_template —alias-name ‘\$LATEST’ </code> </p> </li> <li> <p> <code>aws quicksight delete-template --aws-account-id 111122223333 —-template-id reports_test_template</code> </p> </li> </ul> <p>If version number which is an optional field is not passed the template (including all the versions) is deleted by the API, if version number is provided, the specific template version is deleted by the API.</p> <p>Users can explicitly describe the latest version of the template by passing <code>$LATEST</code> to the <code>alias-name</code> parameter. <code>$LATEST</code> is an internally supported alias, which points to the latest version of the template. </p>
  ## 
  let valid = call_600299.validator(path, query, header, formData, body)
  let scheme = call_600299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600299.url(scheme.get, call_600299.host, call_600299.base,
                         call_600299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600299, url, valid)

proc call*(call_600300: Call_DeleteTemplate_600286; AwsAccountId: string;
          TemplateId: string; versionNumber: int = 0): Recallable =
  ## deleteTemplate
  ## <p>Deletes a template.</p> <p>CLI syntax:</p> <ul> <li> <p> <code>aws quicksight delete-template --aws-account-id 111122223333 —-template-id reports_test_template --version-number 2 </code> </p> </li> <li> <p> <code>aws quicksight delete-template —aws-account-id 111122223333 —template-id reports_test_template —alias-name STAGING </code> </p> </li> <li> <p> <code>aws quicksight delete-template —aws-account-id 111122223333 —template-id reports_test_template —alias-name ‘\$LATEST’ </code> </p> </li> <li> <p> <code>aws quicksight delete-template --aws-account-id 111122223333 —-template-id reports_test_template</code> </p> </li> </ul> <p>If version number which is an optional field is not passed the template (including all the versions) is deleted by the API, if version number is provided, the specific template version is deleted by the API.</p> <p>Users can explicitly describe the latest version of the template by passing <code>$LATEST</code> to the <code>alias-name</code> parameter. <code>$LATEST</code> is an internally supported alias, which points to the latest version of the template. </p>
  ##   AwsAccountId: string (required)
  ##               : AWS account ID that contains the template you are deleting.
  ##   TemplateId: string (required)
  ##             : An ID for the template you want to delete.
  ##   versionNumber: int
  ##                : The version number
  var path_600301 = newJObject()
  var query_600302 = newJObject()
  add(path_600301, "AwsAccountId", newJString(AwsAccountId))
  add(path_600301, "TemplateId", newJString(TemplateId))
  add(query_600302, "version-number", newJInt(versionNumber))
  result = call_600300.call(path_600301, query_600302, nil, nil, nil)

var deleteTemplate* = Call_DeleteTemplate_600286(name: "deleteTemplate",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}",
    validator: validate_DeleteTemplate_600287, base: "/", url: url_DeleteTemplate_600288,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTemplateAlias_600319 = ref object of OpenApiRestCall_599368
proc url_UpdateTemplateAlias_600321(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateTemplateAlias_600320(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Updates the template alias of a template.</p> <p>CLI syntax:</p> <p> <code>aws quicksight update-template-alias --aws-account-id 111122223333 --template-id 'reports_test_template' --alias-name STAGING —template-version-number 2 </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : AWS account ID that contains the template aliases you are updating.
  ##   TemplateId: JString (required)
  ##             : The ID for the template.
  ##   AliasName: JString (required)
  ##            : The alias name.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600322 = path.getOrDefault("AwsAccountId")
  valid_600322 = validateParameter(valid_600322, JString, required = true,
                                 default = nil)
  if valid_600322 != nil:
    section.add "AwsAccountId", valid_600322
  var valid_600323 = path.getOrDefault("TemplateId")
  valid_600323 = validateParameter(valid_600323, JString, required = true,
                                 default = nil)
  if valid_600323 != nil:
    section.add "TemplateId", valid_600323
  var valid_600324 = path.getOrDefault("AliasName")
  valid_600324 = validateParameter(valid_600324, JString, required = true,
                                 default = nil)
  if valid_600324 != nil:
    section.add "AliasName", valid_600324
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
  var valid_600325 = header.getOrDefault("X-Amz-Date")
  valid_600325 = validateParameter(valid_600325, JString, required = false,
                                 default = nil)
  if valid_600325 != nil:
    section.add "X-Amz-Date", valid_600325
  var valid_600326 = header.getOrDefault("X-Amz-Security-Token")
  valid_600326 = validateParameter(valid_600326, JString, required = false,
                                 default = nil)
  if valid_600326 != nil:
    section.add "X-Amz-Security-Token", valid_600326
  var valid_600327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600327 = validateParameter(valid_600327, JString, required = false,
                                 default = nil)
  if valid_600327 != nil:
    section.add "X-Amz-Content-Sha256", valid_600327
  var valid_600328 = header.getOrDefault("X-Amz-Algorithm")
  valid_600328 = validateParameter(valid_600328, JString, required = false,
                                 default = nil)
  if valid_600328 != nil:
    section.add "X-Amz-Algorithm", valid_600328
  var valid_600329 = header.getOrDefault("X-Amz-Signature")
  valid_600329 = validateParameter(valid_600329, JString, required = false,
                                 default = nil)
  if valid_600329 != nil:
    section.add "X-Amz-Signature", valid_600329
  var valid_600330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600330 = validateParameter(valid_600330, JString, required = false,
                                 default = nil)
  if valid_600330 != nil:
    section.add "X-Amz-SignedHeaders", valid_600330
  var valid_600331 = header.getOrDefault("X-Amz-Credential")
  valid_600331 = validateParameter(valid_600331, JString, required = false,
                                 default = nil)
  if valid_600331 != nil:
    section.add "X-Amz-Credential", valid_600331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600333: Call_UpdateTemplateAlias_600319; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the template alias of a template.</p> <p>CLI syntax:</p> <p> <code>aws quicksight update-template-alias --aws-account-id 111122223333 --template-id 'reports_test_template' --alias-name STAGING —template-version-number 2 </code> </p>
  ## 
  let valid = call_600333.validator(path, query, header, formData, body)
  let scheme = call_600333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600333.url(scheme.get, call_600333.host, call_600333.base,
                         call_600333.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600333, url, valid)

proc call*(call_600334: Call_UpdateTemplateAlias_600319; AwsAccountId: string;
          TemplateId: string; body: JsonNode; AliasName: string): Recallable =
  ## updateTemplateAlias
  ## <p>Updates the template alias of a template.</p> <p>CLI syntax:</p> <p> <code>aws quicksight update-template-alias --aws-account-id 111122223333 --template-id 'reports_test_template' --alias-name STAGING —template-version-number 2 </code> </p>
  ##   AwsAccountId: string (required)
  ##               : AWS account ID that contains the template aliases you are updating.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  ##   body: JObject (required)
  ##   AliasName: string (required)
  ##            : The alias name.
  var path_600335 = newJObject()
  var body_600336 = newJObject()
  add(path_600335, "AwsAccountId", newJString(AwsAccountId))
  add(path_600335, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_600336 = body
  add(path_600335, "AliasName", newJString(AliasName))
  result = call_600334.call(path_600335, nil, nil, nil, body_600336)

var updateTemplateAlias* = Call_UpdateTemplateAlias_600319(
    name: "updateTemplateAlias", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}",
    validator: validate_UpdateTemplateAlias_600320, base: "/",
    url: url_UpdateTemplateAlias_600321, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTemplateAlias_600337 = ref object of OpenApiRestCall_599368
proc url_CreateTemplateAlias_600339(protocol: Scheme; host: string; base: string;
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

proc validate_CreateTemplateAlias_600338(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Creates a template alias for a template.</p> <p>CLI syntax:</p> <p> <code>aws quicksight create-template-alias --aws-account-id 111122223333 --template-id 'reports_test_template' --alias-name PROD —version-number 1</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : AWS account ID that contains the template you are aliasing.
  ##   TemplateId: JString (required)
  ##             : An ID for the template.
  ##   AliasName: JString (required)
  ##            : The name you want to give the template's alias. Alias names can't begin with a <code>$</code>, which is reserved by QuickSight. Alias names that start with ‘$’ sign are QuickSight reserved naming and can't be deleted. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600340 = path.getOrDefault("AwsAccountId")
  valid_600340 = validateParameter(valid_600340, JString, required = true,
                                 default = nil)
  if valid_600340 != nil:
    section.add "AwsAccountId", valid_600340
  var valid_600341 = path.getOrDefault("TemplateId")
  valid_600341 = validateParameter(valid_600341, JString, required = true,
                                 default = nil)
  if valid_600341 != nil:
    section.add "TemplateId", valid_600341
  var valid_600342 = path.getOrDefault("AliasName")
  valid_600342 = validateParameter(valid_600342, JString, required = true,
                                 default = nil)
  if valid_600342 != nil:
    section.add "AliasName", valid_600342
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
  var valid_600343 = header.getOrDefault("X-Amz-Date")
  valid_600343 = validateParameter(valid_600343, JString, required = false,
                                 default = nil)
  if valid_600343 != nil:
    section.add "X-Amz-Date", valid_600343
  var valid_600344 = header.getOrDefault("X-Amz-Security-Token")
  valid_600344 = validateParameter(valid_600344, JString, required = false,
                                 default = nil)
  if valid_600344 != nil:
    section.add "X-Amz-Security-Token", valid_600344
  var valid_600345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600345 = validateParameter(valid_600345, JString, required = false,
                                 default = nil)
  if valid_600345 != nil:
    section.add "X-Amz-Content-Sha256", valid_600345
  var valid_600346 = header.getOrDefault("X-Amz-Algorithm")
  valid_600346 = validateParameter(valid_600346, JString, required = false,
                                 default = nil)
  if valid_600346 != nil:
    section.add "X-Amz-Algorithm", valid_600346
  var valid_600347 = header.getOrDefault("X-Amz-Signature")
  valid_600347 = validateParameter(valid_600347, JString, required = false,
                                 default = nil)
  if valid_600347 != nil:
    section.add "X-Amz-Signature", valid_600347
  var valid_600348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600348 = validateParameter(valid_600348, JString, required = false,
                                 default = nil)
  if valid_600348 != nil:
    section.add "X-Amz-SignedHeaders", valid_600348
  var valid_600349 = header.getOrDefault("X-Amz-Credential")
  valid_600349 = validateParameter(valid_600349, JString, required = false,
                                 default = nil)
  if valid_600349 != nil:
    section.add "X-Amz-Credential", valid_600349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600351: Call_CreateTemplateAlias_600337; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a template alias for a template.</p> <p>CLI syntax:</p> <p> <code>aws quicksight create-template-alias --aws-account-id 111122223333 --template-id 'reports_test_template' --alias-name PROD —version-number 1</code> </p>
  ## 
  let valid = call_600351.validator(path, query, header, formData, body)
  let scheme = call_600351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600351.url(scheme.get, call_600351.host, call_600351.base,
                         call_600351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600351, url, valid)

proc call*(call_600352: Call_CreateTemplateAlias_600337; AwsAccountId: string;
          TemplateId: string; body: JsonNode; AliasName: string): Recallable =
  ## createTemplateAlias
  ## <p>Creates a template alias for a template.</p> <p>CLI syntax:</p> <p> <code>aws quicksight create-template-alias --aws-account-id 111122223333 --template-id 'reports_test_template' --alias-name PROD —version-number 1</code> </p>
  ##   AwsAccountId: string (required)
  ##               : AWS account ID that contains the template you are aliasing.
  ##   TemplateId: string (required)
  ##             : An ID for the template.
  ##   body: JObject (required)
  ##   AliasName: string (required)
  ##            : The name you want to give the template's alias. Alias names can't begin with a <code>$</code>, which is reserved by QuickSight. Alias names that start with ‘$’ sign are QuickSight reserved naming and can't be deleted. 
  var path_600353 = newJObject()
  var body_600354 = newJObject()
  add(path_600353, "AwsAccountId", newJString(AwsAccountId))
  add(path_600353, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_600354 = body
  add(path_600353, "AliasName", newJString(AliasName))
  result = call_600352.call(path_600353, nil, nil, nil, body_600354)

var createTemplateAlias* = Call_CreateTemplateAlias_600337(
    name: "createTemplateAlias", meth: HttpMethod.HttpPost,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}",
    validator: validate_CreateTemplateAlias_600338, base: "/",
    url: url_CreateTemplateAlias_600339, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTemplateAlias_600303 = ref object of OpenApiRestCall_599368
proc url_DescribeTemplateAlias_600305(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeTemplateAlias_600304(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the template aliases of a template.</p> <p>CLI syntax:</p> <p> <code>aws quicksight describe-template-alias --aws-account-id 111122223333 --template-id 'reports_test_template' --alias-name 'STAGING'</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : AWS account ID that contains the template alias you are describing.
  ##   TemplateId: JString (required)
  ##             : An ID for the template.
  ##   AliasName: JString (required)
  ##            : The alias name. <code>$PUBLISHED</code> is not supported for template.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600306 = path.getOrDefault("AwsAccountId")
  valid_600306 = validateParameter(valid_600306, JString, required = true,
                                 default = nil)
  if valid_600306 != nil:
    section.add "AwsAccountId", valid_600306
  var valid_600307 = path.getOrDefault("TemplateId")
  valid_600307 = validateParameter(valid_600307, JString, required = true,
                                 default = nil)
  if valid_600307 != nil:
    section.add "TemplateId", valid_600307
  var valid_600308 = path.getOrDefault("AliasName")
  valid_600308 = validateParameter(valid_600308, JString, required = true,
                                 default = nil)
  if valid_600308 != nil:
    section.add "AliasName", valid_600308
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
  var valid_600309 = header.getOrDefault("X-Amz-Date")
  valid_600309 = validateParameter(valid_600309, JString, required = false,
                                 default = nil)
  if valid_600309 != nil:
    section.add "X-Amz-Date", valid_600309
  var valid_600310 = header.getOrDefault("X-Amz-Security-Token")
  valid_600310 = validateParameter(valid_600310, JString, required = false,
                                 default = nil)
  if valid_600310 != nil:
    section.add "X-Amz-Security-Token", valid_600310
  var valid_600311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600311 = validateParameter(valid_600311, JString, required = false,
                                 default = nil)
  if valid_600311 != nil:
    section.add "X-Amz-Content-Sha256", valid_600311
  var valid_600312 = header.getOrDefault("X-Amz-Algorithm")
  valid_600312 = validateParameter(valid_600312, JString, required = false,
                                 default = nil)
  if valid_600312 != nil:
    section.add "X-Amz-Algorithm", valid_600312
  var valid_600313 = header.getOrDefault("X-Amz-Signature")
  valid_600313 = validateParameter(valid_600313, JString, required = false,
                                 default = nil)
  if valid_600313 != nil:
    section.add "X-Amz-Signature", valid_600313
  var valid_600314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600314 = validateParameter(valid_600314, JString, required = false,
                                 default = nil)
  if valid_600314 != nil:
    section.add "X-Amz-SignedHeaders", valid_600314
  var valid_600315 = header.getOrDefault("X-Amz-Credential")
  valid_600315 = validateParameter(valid_600315, JString, required = false,
                                 default = nil)
  if valid_600315 != nil:
    section.add "X-Amz-Credential", valid_600315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600316: Call_DescribeTemplateAlias_600303; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the template aliases of a template.</p> <p>CLI syntax:</p> <p> <code>aws quicksight describe-template-alias --aws-account-id 111122223333 --template-id 'reports_test_template' --alias-name 'STAGING'</code> </p>
  ## 
  let valid = call_600316.validator(path, query, header, formData, body)
  let scheme = call_600316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600316.url(scheme.get, call_600316.host, call_600316.base,
                         call_600316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600316, url, valid)

proc call*(call_600317: Call_DescribeTemplateAlias_600303; AwsAccountId: string;
          TemplateId: string; AliasName: string): Recallable =
  ## describeTemplateAlias
  ## <p>Describes the template aliases of a template.</p> <p>CLI syntax:</p> <p> <code>aws quicksight describe-template-alias --aws-account-id 111122223333 --template-id 'reports_test_template' --alias-name 'STAGING'</code> </p>
  ##   AwsAccountId: string (required)
  ##               : AWS account ID that contains the template alias you are describing.
  ##   TemplateId: string (required)
  ##             : An ID for the template.
  ##   AliasName: string (required)
  ##            : The alias name. <code>$PUBLISHED</code> is not supported for template.
  var path_600318 = newJObject()
  add(path_600318, "AwsAccountId", newJString(AwsAccountId))
  add(path_600318, "TemplateId", newJString(TemplateId))
  add(path_600318, "AliasName", newJString(AliasName))
  result = call_600317.call(path_600318, nil, nil, nil, nil)

var describeTemplateAlias* = Call_DescribeTemplateAlias_600303(
    name: "describeTemplateAlias", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}",
    validator: validate_DescribeTemplateAlias_600304, base: "/",
    url: url_DescribeTemplateAlias_600305, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTemplateAlias_600355 = ref object of OpenApiRestCall_599368
proc url_DeleteTemplateAlias_600357(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteTemplateAlias_600356(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Update template alias of given template.</p> <p>CLI syntax:</p> <p> <code>aws quicksight delete-template-alias --aws-account-id 111122223333 --template-id 'reports_test_template' --alias-name 'STAGING'</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : AWS account ID that contains the template alias you are deleting.
  ##   TemplateId: JString (required)
  ##             : An ID for the template.
  ##   AliasName: JString (required)
  ##            : The alias of the template. If alias-name is provided, the version that the alias-name points to is deleted. Alias names that start with <code>$</code> are reserved by QuickSight and can't be deleted.”
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600358 = path.getOrDefault("AwsAccountId")
  valid_600358 = validateParameter(valid_600358, JString, required = true,
                                 default = nil)
  if valid_600358 != nil:
    section.add "AwsAccountId", valid_600358
  var valid_600359 = path.getOrDefault("TemplateId")
  valid_600359 = validateParameter(valid_600359, JString, required = true,
                                 default = nil)
  if valid_600359 != nil:
    section.add "TemplateId", valid_600359
  var valid_600360 = path.getOrDefault("AliasName")
  valid_600360 = validateParameter(valid_600360, JString, required = true,
                                 default = nil)
  if valid_600360 != nil:
    section.add "AliasName", valid_600360
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
  var valid_600361 = header.getOrDefault("X-Amz-Date")
  valid_600361 = validateParameter(valid_600361, JString, required = false,
                                 default = nil)
  if valid_600361 != nil:
    section.add "X-Amz-Date", valid_600361
  var valid_600362 = header.getOrDefault("X-Amz-Security-Token")
  valid_600362 = validateParameter(valid_600362, JString, required = false,
                                 default = nil)
  if valid_600362 != nil:
    section.add "X-Amz-Security-Token", valid_600362
  var valid_600363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600363 = validateParameter(valid_600363, JString, required = false,
                                 default = nil)
  if valid_600363 != nil:
    section.add "X-Amz-Content-Sha256", valid_600363
  var valid_600364 = header.getOrDefault("X-Amz-Algorithm")
  valid_600364 = validateParameter(valid_600364, JString, required = false,
                                 default = nil)
  if valid_600364 != nil:
    section.add "X-Amz-Algorithm", valid_600364
  var valid_600365 = header.getOrDefault("X-Amz-Signature")
  valid_600365 = validateParameter(valid_600365, JString, required = false,
                                 default = nil)
  if valid_600365 != nil:
    section.add "X-Amz-Signature", valid_600365
  var valid_600366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600366 = validateParameter(valid_600366, JString, required = false,
                                 default = nil)
  if valid_600366 != nil:
    section.add "X-Amz-SignedHeaders", valid_600366
  var valid_600367 = header.getOrDefault("X-Amz-Credential")
  valid_600367 = validateParameter(valid_600367, JString, required = false,
                                 default = nil)
  if valid_600367 != nil:
    section.add "X-Amz-Credential", valid_600367
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600368: Call_DeleteTemplateAlias_600355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Update template alias of given template.</p> <p>CLI syntax:</p> <p> <code>aws quicksight delete-template-alias --aws-account-id 111122223333 --template-id 'reports_test_template' --alias-name 'STAGING'</code> </p>
  ## 
  let valid = call_600368.validator(path, query, header, formData, body)
  let scheme = call_600368.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600368.url(scheme.get, call_600368.host, call_600368.base,
                         call_600368.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600368, url, valid)

proc call*(call_600369: Call_DeleteTemplateAlias_600355; AwsAccountId: string;
          TemplateId: string; AliasName: string): Recallable =
  ## deleteTemplateAlias
  ## <p>Update template alias of given template.</p> <p>CLI syntax:</p> <p> <code>aws quicksight delete-template-alias --aws-account-id 111122223333 --template-id 'reports_test_template' --alias-name 'STAGING'</code> </p>
  ##   AwsAccountId: string (required)
  ##               : AWS account ID that contains the template alias you are deleting.
  ##   TemplateId: string (required)
  ##             : An ID for the template.
  ##   AliasName: string (required)
  ##            : The alias of the template. If alias-name is provided, the version that the alias-name points to is deleted. Alias names that start with <code>$</code> are reserved by QuickSight and can't be deleted.”
  var path_600370 = newJObject()
  add(path_600370, "AwsAccountId", newJString(AwsAccountId))
  add(path_600370, "TemplateId", newJString(TemplateId))
  add(path_600370, "AliasName", newJString(AliasName))
  result = call_600369.call(path_600370, nil, nil, nil, nil)

var deleteTemplateAlias* = Call_DeleteTemplateAlias_600355(
    name: "deleteTemplateAlias", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases/{AliasName}",
    validator: validate_DeleteTemplateAlias_600356, base: "/",
    url: url_DeleteTemplateAlias_600357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSet_600386 = ref object of OpenApiRestCall_599368
proc url_UpdateDataSet_600388(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDataSet_600387(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates a dataset.</p> <p>CLI syntax:</p> <p> <code>aws quicksight update-data-set \</code> </p> <p> <code>--aws-account-id=111122223333 \</code> </p> <p> <code>--data-set-id=unique-data-set-id \</code> </p> <p> <code>--name='My dataset' \</code> </p> <p> <code>--import-mode=SPICE \</code> </p> <p> <code>--physical-table-map='{</code> </p> <p> <code> "physical-table-id": {</code> </p> <p> <code> "RelationalTable": {</code> </p> <p> <code> "DataSourceArn": "arn:aws:quicksight:us-west-2:111111111111:datasource/data-source-id",</code> </p> <p> <code> "Name": "table1",</code> </p> <p> <code> "InputColumns": [</code> </p> <p> <code> {</code> </p> <p> <code> "Name": "column1",</code> </p> <p> <code> "Type": "STRING"</code> </p> <p> <code> }</code> </p> <p> <code> ]</code> </p> <p> <code> }</code> </p> <p> <code> }'</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS Account ID.
  ##   DataSetId: JString (required)
  ##            : The ID for the dataset you want to create. This is unique per region per AWS account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600389 = path.getOrDefault("AwsAccountId")
  valid_600389 = validateParameter(valid_600389, JString, required = true,
                                 default = nil)
  if valid_600389 != nil:
    section.add "AwsAccountId", valid_600389
  var valid_600390 = path.getOrDefault("DataSetId")
  valid_600390 = validateParameter(valid_600390, JString, required = true,
                                 default = nil)
  if valid_600390 != nil:
    section.add "DataSetId", valid_600390
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
  var valid_600391 = header.getOrDefault("X-Amz-Date")
  valid_600391 = validateParameter(valid_600391, JString, required = false,
                                 default = nil)
  if valid_600391 != nil:
    section.add "X-Amz-Date", valid_600391
  var valid_600392 = header.getOrDefault("X-Amz-Security-Token")
  valid_600392 = validateParameter(valid_600392, JString, required = false,
                                 default = nil)
  if valid_600392 != nil:
    section.add "X-Amz-Security-Token", valid_600392
  var valid_600393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600393 = validateParameter(valid_600393, JString, required = false,
                                 default = nil)
  if valid_600393 != nil:
    section.add "X-Amz-Content-Sha256", valid_600393
  var valid_600394 = header.getOrDefault("X-Amz-Algorithm")
  valid_600394 = validateParameter(valid_600394, JString, required = false,
                                 default = nil)
  if valid_600394 != nil:
    section.add "X-Amz-Algorithm", valid_600394
  var valid_600395 = header.getOrDefault("X-Amz-Signature")
  valid_600395 = validateParameter(valid_600395, JString, required = false,
                                 default = nil)
  if valid_600395 != nil:
    section.add "X-Amz-Signature", valid_600395
  var valid_600396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600396 = validateParameter(valid_600396, JString, required = false,
                                 default = nil)
  if valid_600396 != nil:
    section.add "X-Amz-SignedHeaders", valid_600396
  var valid_600397 = header.getOrDefault("X-Amz-Credential")
  valid_600397 = validateParameter(valid_600397, JString, required = false,
                                 default = nil)
  if valid_600397 != nil:
    section.add "X-Amz-Credential", valid_600397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600399: Call_UpdateDataSet_600386; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a dataset.</p> <p>CLI syntax:</p> <p> <code>aws quicksight update-data-set \</code> </p> <p> <code>--aws-account-id=111122223333 \</code> </p> <p> <code>--data-set-id=unique-data-set-id \</code> </p> <p> <code>--name='My dataset' \</code> </p> <p> <code>--import-mode=SPICE \</code> </p> <p> <code>--physical-table-map='{</code> </p> <p> <code> "physical-table-id": {</code> </p> <p> <code> "RelationalTable": {</code> </p> <p> <code> "DataSourceArn": "arn:aws:quicksight:us-west-2:111111111111:datasource/data-source-id",</code> </p> <p> <code> "Name": "table1",</code> </p> <p> <code> "InputColumns": [</code> </p> <p> <code> {</code> </p> <p> <code> "Name": "column1",</code> </p> <p> <code> "Type": "STRING"</code> </p> <p> <code> }</code> </p> <p> <code> ]</code> </p> <p> <code> }</code> </p> <p> <code> }'</code> </p>
  ## 
  let valid = call_600399.validator(path, query, header, formData, body)
  let scheme = call_600399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600399.url(scheme.get, call_600399.host, call_600399.base,
                         call_600399.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600399, url, valid)

proc call*(call_600400: Call_UpdateDataSet_600386; AwsAccountId: string;
          body: JsonNode; DataSetId: string): Recallable =
  ## updateDataSet
  ## <p>Updates a dataset.</p> <p>CLI syntax:</p> <p> <code>aws quicksight update-data-set \</code> </p> <p> <code>--aws-account-id=111122223333 \</code> </p> <p> <code>--data-set-id=unique-data-set-id \</code> </p> <p> <code>--name='My dataset' \</code> </p> <p> <code>--import-mode=SPICE \</code> </p> <p> <code>--physical-table-map='{</code> </p> <p> <code> "physical-table-id": {</code> </p> <p> <code> "RelationalTable": {</code> </p> <p> <code> "DataSourceArn": "arn:aws:quicksight:us-west-2:111111111111:datasource/data-source-id",</code> </p> <p> <code> "Name": "table1",</code> </p> <p> <code> "InputColumns": [</code> </p> <p> <code> {</code> </p> <p> <code> "Name": "column1",</code> </p> <p> <code> "Type": "STRING"</code> </p> <p> <code> }</code> </p> <p> <code> ]</code> </p> <p> <code> }</code> </p> <p> <code> }'</code> </p>
  ##   AwsAccountId: string (required)
  ##               : The AWS Account ID.
  ##   body: JObject (required)
  ##   DataSetId: string (required)
  ##            : The ID for the dataset you want to create. This is unique per region per AWS account.
  var path_600401 = newJObject()
  var body_600402 = newJObject()
  add(path_600401, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_600402 = body
  add(path_600401, "DataSetId", newJString(DataSetId))
  result = call_600400.call(path_600401, nil, nil, nil, body_600402)

var updateDataSet* = Call_UpdateDataSet_600386(name: "updateDataSet",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}",
    validator: validate_UpdateDataSet_600387, base: "/", url: url_UpdateDataSet_600388,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSet_600371 = ref object of OpenApiRestCall_599368
proc url_DescribeDataSet_600373(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDataSet_600372(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Describes a dataset. </p> <p>CLI syntax:</p> <p> <code>aws quicksight describe-data-set \</code> </p> <p> <code>--aws-account-id=111111111111 \</code> </p> <p> <code>--data-set-id=unique-data-set-id</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS Account ID.
  ##   DataSetId: JString (required)
  ##            : The ID for the dataset you want to create. This is unique per region per AWS account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600374 = path.getOrDefault("AwsAccountId")
  valid_600374 = validateParameter(valid_600374, JString, required = true,
                                 default = nil)
  if valid_600374 != nil:
    section.add "AwsAccountId", valid_600374
  var valid_600375 = path.getOrDefault("DataSetId")
  valid_600375 = validateParameter(valid_600375, JString, required = true,
                                 default = nil)
  if valid_600375 != nil:
    section.add "DataSetId", valid_600375
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
  var valid_600376 = header.getOrDefault("X-Amz-Date")
  valid_600376 = validateParameter(valid_600376, JString, required = false,
                                 default = nil)
  if valid_600376 != nil:
    section.add "X-Amz-Date", valid_600376
  var valid_600377 = header.getOrDefault("X-Amz-Security-Token")
  valid_600377 = validateParameter(valid_600377, JString, required = false,
                                 default = nil)
  if valid_600377 != nil:
    section.add "X-Amz-Security-Token", valid_600377
  var valid_600378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600378 = validateParameter(valid_600378, JString, required = false,
                                 default = nil)
  if valid_600378 != nil:
    section.add "X-Amz-Content-Sha256", valid_600378
  var valid_600379 = header.getOrDefault("X-Amz-Algorithm")
  valid_600379 = validateParameter(valid_600379, JString, required = false,
                                 default = nil)
  if valid_600379 != nil:
    section.add "X-Amz-Algorithm", valid_600379
  var valid_600380 = header.getOrDefault("X-Amz-Signature")
  valid_600380 = validateParameter(valid_600380, JString, required = false,
                                 default = nil)
  if valid_600380 != nil:
    section.add "X-Amz-Signature", valid_600380
  var valid_600381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600381 = validateParameter(valid_600381, JString, required = false,
                                 default = nil)
  if valid_600381 != nil:
    section.add "X-Amz-SignedHeaders", valid_600381
  var valid_600382 = header.getOrDefault("X-Amz-Credential")
  valid_600382 = validateParameter(valid_600382, JString, required = false,
                                 default = nil)
  if valid_600382 != nil:
    section.add "X-Amz-Credential", valid_600382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600383: Call_DescribeDataSet_600371; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes a dataset. </p> <p>CLI syntax:</p> <p> <code>aws quicksight describe-data-set \</code> </p> <p> <code>--aws-account-id=111111111111 \</code> </p> <p> <code>--data-set-id=unique-data-set-id</code> </p>
  ## 
  let valid = call_600383.validator(path, query, header, formData, body)
  let scheme = call_600383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600383.url(scheme.get, call_600383.host, call_600383.base,
                         call_600383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600383, url, valid)

proc call*(call_600384: Call_DescribeDataSet_600371; AwsAccountId: string;
          DataSetId: string): Recallable =
  ## describeDataSet
  ## <p>Describes a dataset. </p> <p>CLI syntax:</p> <p> <code>aws quicksight describe-data-set \</code> </p> <p> <code>--aws-account-id=111111111111 \</code> </p> <p> <code>--data-set-id=unique-data-set-id</code> </p>
  ##   AwsAccountId: string (required)
  ##               : The AWS Account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset you want to create. This is unique per region per AWS account.
  var path_600385 = newJObject()
  add(path_600385, "AwsAccountId", newJString(AwsAccountId))
  add(path_600385, "DataSetId", newJString(DataSetId))
  result = call_600384.call(path_600385, nil, nil, nil, nil)

var describeDataSet* = Call_DescribeDataSet_600371(name: "describeDataSet",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}",
    validator: validate_DescribeDataSet_600372, base: "/", url: url_DescribeDataSet_600373,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSet_600403 = ref object of OpenApiRestCall_599368
proc url_DeleteDataSet_600405(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDataSet_600404(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a dataset.</p> <p>CLI syntax:</p> <p> <code>aws quicksight delete-data-set \</code> </p> <p> <code>--aws-account-id=111111111111 \</code> </p> <p> <code>--data-set-id=unique-data-set-id</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS Account ID.
  ##   DataSetId: JString (required)
  ##            : The ID for the dataset you want to create. This is unique per region per AWS account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600406 = path.getOrDefault("AwsAccountId")
  valid_600406 = validateParameter(valid_600406, JString, required = true,
                                 default = nil)
  if valid_600406 != nil:
    section.add "AwsAccountId", valid_600406
  var valid_600407 = path.getOrDefault("DataSetId")
  valid_600407 = validateParameter(valid_600407, JString, required = true,
                                 default = nil)
  if valid_600407 != nil:
    section.add "DataSetId", valid_600407
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
  var valid_600408 = header.getOrDefault("X-Amz-Date")
  valid_600408 = validateParameter(valid_600408, JString, required = false,
                                 default = nil)
  if valid_600408 != nil:
    section.add "X-Amz-Date", valid_600408
  var valid_600409 = header.getOrDefault("X-Amz-Security-Token")
  valid_600409 = validateParameter(valid_600409, JString, required = false,
                                 default = nil)
  if valid_600409 != nil:
    section.add "X-Amz-Security-Token", valid_600409
  var valid_600410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600410 = validateParameter(valid_600410, JString, required = false,
                                 default = nil)
  if valid_600410 != nil:
    section.add "X-Amz-Content-Sha256", valid_600410
  var valid_600411 = header.getOrDefault("X-Amz-Algorithm")
  valid_600411 = validateParameter(valid_600411, JString, required = false,
                                 default = nil)
  if valid_600411 != nil:
    section.add "X-Amz-Algorithm", valid_600411
  var valid_600412 = header.getOrDefault("X-Amz-Signature")
  valid_600412 = validateParameter(valid_600412, JString, required = false,
                                 default = nil)
  if valid_600412 != nil:
    section.add "X-Amz-Signature", valid_600412
  var valid_600413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600413 = validateParameter(valid_600413, JString, required = false,
                                 default = nil)
  if valid_600413 != nil:
    section.add "X-Amz-SignedHeaders", valid_600413
  var valid_600414 = header.getOrDefault("X-Amz-Credential")
  valid_600414 = validateParameter(valid_600414, JString, required = false,
                                 default = nil)
  if valid_600414 != nil:
    section.add "X-Amz-Credential", valid_600414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600415: Call_DeleteDataSet_600403; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a dataset.</p> <p>CLI syntax:</p> <p> <code>aws quicksight delete-data-set \</code> </p> <p> <code>--aws-account-id=111111111111 \</code> </p> <p> <code>--data-set-id=unique-data-set-id</code> </p>
  ## 
  let valid = call_600415.validator(path, query, header, formData, body)
  let scheme = call_600415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600415.url(scheme.get, call_600415.host, call_600415.base,
                         call_600415.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600415, url, valid)

proc call*(call_600416: Call_DeleteDataSet_600403; AwsAccountId: string;
          DataSetId: string): Recallable =
  ## deleteDataSet
  ## <p>Deletes a dataset.</p> <p>CLI syntax:</p> <p> <code>aws quicksight delete-data-set \</code> </p> <p> <code>--aws-account-id=111111111111 \</code> </p> <p> <code>--data-set-id=unique-data-set-id</code> </p>
  ##   AwsAccountId: string (required)
  ##               : The AWS Account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset you want to create. This is unique per region per AWS account.
  var path_600417 = newJObject()
  add(path_600417, "AwsAccountId", newJString(AwsAccountId))
  add(path_600417, "DataSetId", newJString(DataSetId))
  result = call_600416.call(path_600417, nil, nil, nil, nil)

var deleteDataSet* = Call_DeleteDataSet_600403(name: "deleteDataSet",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}",
    validator: validate_DeleteDataSet_600404, base: "/", url: url_DeleteDataSet_600405,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSource_600433 = ref object of OpenApiRestCall_599368
proc url_UpdateDataSource_600435(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateDataSource_600434(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Updates a data source.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:datasource/data-source-id</code> </p> <p>CLI syntax:</p> <p> <code>aws quicksight update-data-source \</code> </p> <p> <code>--aws-account-id=111122223333 \</code> </p> <p> <code>--data-source-id=unique-data-source-id \</code> </p> <p> <code>--name='My Data Source' \</code> </p> <p> <code>--data-source-parameters='{"PostgreSqlParameters":{"Host":"my-db-host.example.com","Port":1234,"Database":"my-db"}}' \</code> </p> <p> <code>--credentials='{"CredentialPair":{"Username":"username","Password":"password"}}</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  ##   DataSourceId: JString (required)
  ##               : The ID of the data source. This is unique per AWS Region per AWS account. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600436 = path.getOrDefault("AwsAccountId")
  valid_600436 = validateParameter(valid_600436, JString, required = true,
                                 default = nil)
  if valid_600436 != nil:
    section.add "AwsAccountId", valid_600436
  var valid_600437 = path.getOrDefault("DataSourceId")
  valid_600437 = validateParameter(valid_600437, JString, required = true,
                                 default = nil)
  if valid_600437 != nil:
    section.add "DataSourceId", valid_600437
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
  var valid_600438 = header.getOrDefault("X-Amz-Date")
  valid_600438 = validateParameter(valid_600438, JString, required = false,
                                 default = nil)
  if valid_600438 != nil:
    section.add "X-Amz-Date", valid_600438
  var valid_600439 = header.getOrDefault("X-Amz-Security-Token")
  valid_600439 = validateParameter(valid_600439, JString, required = false,
                                 default = nil)
  if valid_600439 != nil:
    section.add "X-Amz-Security-Token", valid_600439
  var valid_600440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600440 = validateParameter(valid_600440, JString, required = false,
                                 default = nil)
  if valid_600440 != nil:
    section.add "X-Amz-Content-Sha256", valid_600440
  var valid_600441 = header.getOrDefault("X-Amz-Algorithm")
  valid_600441 = validateParameter(valid_600441, JString, required = false,
                                 default = nil)
  if valid_600441 != nil:
    section.add "X-Amz-Algorithm", valid_600441
  var valid_600442 = header.getOrDefault("X-Amz-Signature")
  valid_600442 = validateParameter(valid_600442, JString, required = false,
                                 default = nil)
  if valid_600442 != nil:
    section.add "X-Amz-Signature", valid_600442
  var valid_600443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600443 = validateParameter(valid_600443, JString, required = false,
                                 default = nil)
  if valid_600443 != nil:
    section.add "X-Amz-SignedHeaders", valid_600443
  var valid_600444 = header.getOrDefault("X-Amz-Credential")
  valid_600444 = validateParameter(valid_600444, JString, required = false,
                                 default = nil)
  if valid_600444 != nil:
    section.add "X-Amz-Credential", valid_600444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600446: Call_UpdateDataSource_600433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates a data source.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:datasource/data-source-id</code> </p> <p>CLI syntax:</p> <p> <code>aws quicksight update-data-source \</code> </p> <p> <code>--aws-account-id=111122223333 \</code> </p> <p> <code>--data-source-id=unique-data-source-id \</code> </p> <p> <code>--name='My Data Source' \</code> </p> <p> <code>--data-source-parameters='{"PostgreSqlParameters":{"Host":"my-db-host.example.com","Port":1234,"Database":"my-db"}}' \</code> </p> <p> <code>--credentials='{"CredentialPair":{"Username":"username","Password":"password"}}</code> </p>
  ## 
  let valid = call_600446.validator(path, query, header, formData, body)
  let scheme = call_600446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600446.url(scheme.get, call_600446.host, call_600446.base,
                         call_600446.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600446, url, valid)

proc call*(call_600447: Call_UpdateDataSource_600433; AwsAccountId: string;
          DataSourceId: string; body: JsonNode): Recallable =
  ## updateDataSource
  ## <p>Updates a data source.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:datasource/data-source-id</code> </p> <p>CLI syntax:</p> <p> <code>aws quicksight update-data-source \</code> </p> <p> <code>--aws-account-id=111122223333 \</code> </p> <p> <code>--data-source-id=unique-data-source-id \</code> </p> <p> <code>--name='My Data Source' \</code> </p> <p> <code>--data-source-parameters='{"PostgreSqlParameters":{"Host":"my-db-host.example.com","Port":1234,"Database":"my-db"}}' \</code> </p> <p> <code>--credentials='{"CredentialPair":{"Username":"username","Password":"password"}}</code> </p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This is unique per AWS Region per AWS account. 
  ##   body: JObject (required)
  var path_600448 = newJObject()
  var body_600449 = newJObject()
  add(path_600448, "AwsAccountId", newJString(AwsAccountId))
  add(path_600448, "DataSourceId", newJString(DataSourceId))
  if body != nil:
    body_600449 = body
  result = call_600447.call(path_600448, nil, nil, nil, body_600449)

var updateDataSource* = Call_UpdateDataSource_600433(name: "updateDataSource",
    meth: HttpMethod.HttpPut, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}",
    validator: validate_UpdateDataSource_600434, base: "/",
    url: url_UpdateDataSource_600435, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSource_600418 = ref object of OpenApiRestCall_599368
proc url_DescribeDataSource_600420(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeDataSource_600419(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Describes a data source.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:datasource/data-source-id</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  ##   DataSourceId: JString (required)
  ##               : The ID of the data source. This is unique per AWS Region per AWS account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600421 = path.getOrDefault("AwsAccountId")
  valid_600421 = validateParameter(valid_600421, JString, required = true,
                                 default = nil)
  if valid_600421 != nil:
    section.add "AwsAccountId", valid_600421
  var valid_600422 = path.getOrDefault("DataSourceId")
  valid_600422 = validateParameter(valid_600422, JString, required = true,
                                 default = nil)
  if valid_600422 != nil:
    section.add "DataSourceId", valid_600422
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
  var valid_600423 = header.getOrDefault("X-Amz-Date")
  valid_600423 = validateParameter(valid_600423, JString, required = false,
                                 default = nil)
  if valid_600423 != nil:
    section.add "X-Amz-Date", valid_600423
  var valid_600424 = header.getOrDefault("X-Amz-Security-Token")
  valid_600424 = validateParameter(valid_600424, JString, required = false,
                                 default = nil)
  if valid_600424 != nil:
    section.add "X-Amz-Security-Token", valid_600424
  var valid_600425 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600425 = validateParameter(valid_600425, JString, required = false,
                                 default = nil)
  if valid_600425 != nil:
    section.add "X-Amz-Content-Sha256", valid_600425
  var valid_600426 = header.getOrDefault("X-Amz-Algorithm")
  valid_600426 = validateParameter(valid_600426, JString, required = false,
                                 default = nil)
  if valid_600426 != nil:
    section.add "X-Amz-Algorithm", valid_600426
  var valid_600427 = header.getOrDefault("X-Amz-Signature")
  valid_600427 = validateParameter(valid_600427, JString, required = false,
                                 default = nil)
  if valid_600427 != nil:
    section.add "X-Amz-Signature", valid_600427
  var valid_600428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600428 = validateParameter(valid_600428, JString, required = false,
                                 default = nil)
  if valid_600428 != nil:
    section.add "X-Amz-SignedHeaders", valid_600428
  var valid_600429 = header.getOrDefault("X-Amz-Credential")
  valid_600429 = validateParameter(valid_600429, JString, required = false,
                                 default = nil)
  if valid_600429 != nil:
    section.add "X-Amz-Credential", valid_600429
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600430: Call_DescribeDataSource_600418; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes a data source.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:datasource/data-source-id</code> </p>
  ## 
  let valid = call_600430.validator(path, query, header, formData, body)
  let scheme = call_600430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600430.url(scheme.get, call_600430.host, call_600430.base,
                         call_600430.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600430, url, valid)

proc call*(call_600431: Call_DescribeDataSource_600418; AwsAccountId: string;
          DataSourceId: string): Recallable =
  ## describeDataSource
  ## <p>Describes a data source.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:datasource/data-source-id</code> </p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This is unique per AWS Region per AWS account.
  var path_600432 = newJObject()
  add(path_600432, "AwsAccountId", newJString(AwsAccountId))
  add(path_600432, "DataSourceId", newJString(DataSourceId))
  result = call_600431.call(path_600432, nil, nil, nil, nil)

var describeDataSource* = Call_DescribeDataSource_600418(
    name: "describeDataSource", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}",
    validator: validate_DescribeDataSource_600419, base: "/",
    url: url_DescribeDataSource_600420, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataSource_600450 = ref object of OpenApiRestCall_599368
proc url_DeleteDataSource_600452(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteDataSource_600451(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Deletes the data source permanently. This action breaks all the datasets that reference the deleted data source.</p> <p>CLI syntax:</p> <p> <code>aws quicksight delete-data-source \</code> </p> <p> <code>--aws-account-id=111122223333 \</code> </p> <p> <code>--data-source-id=unique-data-source-id </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  ##   DataSourceId: JString (required)
  ##               : The ID of the data source. This is unique per AWS Region per AWS account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600453 = path.getOrDefault("AwsAccountId")
  valid_600453 = validateParameter(valid_600453, JString, required = true,
                                 default = nil)
  if valid_600453 != nil:
    section.add "AwsAccountId", valid_600453
  var valid_600454 = path.getOrDefault("DataSourceId")
  valid_600454 = validateParameter(valid_600454, JString, required = true,
                                 default = nil)
  if valid_600454 != nil:
    section.add "DataSourceId", valid_600454
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
  var valid_600455 = header.getOrDefault("X-Amz-Date")
  valid_600455 = validateParameter(valid_600455, JString, required = false,
                                 default = nil)
  if valid_600455 != nil:
    section.add "X-Amz-Date", valid_600455
  var valid_600456 = header.getOrDefault("X-Amz-Security-Token")
  valid_600456 = validateParameter(valid_600456, JString, required = false,
                                 default = nil)
  if valid_600456 != nil:
    section.add "X-Amz-Security-Token", valid_600456
  var valid_600457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600457 = validateParameter(valid_600457, JString, required = false,
                                 default = nil)
  if valid_600457 != nil:
    section.add "X-Amz-Content-Sha256", valid_600457
  var valid_600458 = header.getOrDefault("X-Amz-Algorithm")
  valid_600458 = validateParameter(valid_600458, JString, required = false,
                                 default = nil)
  if valid_600458 != nil:
    section.add "X-Amz-Algorithm", valid_600458
  var valid_600459 = header.getOrDefault("X-Amz-Signature")
  valid_600459 = validateParameter(valid_600459, JString, required = false,
                                 default = nil)
  if valid_600459 != nil:
    section.add "X-Amz-Signature", valid_600459
  var valid_600460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600460 = validateParameter(valid_600460, JString, required = false,
                                 default = nil)
  if valid_600460 != nil:
    section.add "X-Amz-SignedHeaders", valid_600460
  var valid_600461 = header.getOrDefault("X-Amz-Credential")
  valid_600461 = validateParameter(valid_600461, JString, required = false,
                                 default = nil)
  if valid_600461 != nil:
    section.add "X-Amz-Credential", valid_600461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600462: Call_DeleteDataSource_600450; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the data source permanently. This action breaks all the datasets that reference the deleted data source.</p> <p>CLI syntax:</p> <p> <code>aws quicksight delete-data-source \</code> </p> <p> <code>--aws-account-id=111122223333 \</code> </p> <p> <code>--data-source-id=unique-data-source-id </code> </p>
  ## 
  let valid = call_600462.validator(path, query, header, formData, body)
  let scheme = call_600462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600462.url(scheme.get, call_600462.host, call_600462.base,
                         call_600462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600462, url, valid)

proc call*(call_600463: Call_DeleteDataSource_600450; AwsAccountId: string;
          DataSourceId: string): Recallable =
  ## deleteDataSource
  ## <p>Deletes the data source permanently. This action breaks all the datasets that reference the deleted data source.</p> <p>CLI syntax:</p> <p> <code>aws quicksight delete-data-source \</code> </p> <p> <code>--aws-account-id=111122223333 \</code> </p> <p> <code>--data-source-id=unique-data-source-id </code> </p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This is unique per AWS Region per AWS account.
  var path_600464 = newJObject()
  add(path_600464, "AwsAccountId", newJString(AwsAccountId))
  add(path_600464, "DataSourceId", newJString(DataSourceId))
  result = call_600463.call(path_600464, nil, nil, nil, nil)

var deleteDataSource* = Call_DeleteDataSource_600450(name: "deleteDataSource",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}",
    validator: validate_DeleteDataSource_600451, base: "/",
    url: url_DeleteDataSource_600452, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_600481 = ref object of OpenApiRestCall_599368
proc url_UpdateGroup_600483(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGroup_600482(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Changes a group description. </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a group object.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight update-group --aws-account-id=111122223333 --namespace=default --group-name=Sales --description="Sales BI Dashboards" </code> </p>
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
  var valid_600484 = path.getOrDefault("GroupName")
  valid_600484 = validateParameter(valid_600484, JString, required = true,
                                 default = nil)
  if valid_600484 != nil:
    section.add "GroupName", valid_600484
  var valid_600485 = path.getOrDefault("AwsAccountId")
  valid_600485 = validateParameter(valid_600485, JString, required = true,
                                 default = nil)
  if valid_600485 != nil:
    section.add "AwsAccountId", valid_600485
  var valid_600486 = path.getOrDefault("Namespace")
  valid_600486 = validateParameter(valid_600486, JString, required = true,
                                 default = nil)
  if valid_600486 != nil:
    section.add "Namespace", valid_600486
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
  var valid_600487 = header.getOrDefault("X-Amz-Date")
  valid_600487 = validateParameter(valid_600487, JString, required = false,
                                 default = nil)
  if valid_600487 != nil:
    section.add "X-Amz-Date", valid_600487
  var valid_600488 = header.getOrDefault("X-Amz-Security-Token")
  valid_600488 = validateParameter(valid_600488, JString, required = false,
                                 default = nil)
  if valid_600488 != nil:
    section.add "X-Amz-Security-Token", valid_600488
  var valid_600489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600489 = validateParameter(valid_600489, JString, required = false,
                                 default = nil)
  if valid_600489 != nil:
    section.add "X-Amz-Content-Sha256", valid_600489
  var valid_600490 = header.getOrDefault("X-Amz-Algorithm")
  valid_600490 = validateParameter(valid_600490, JString, required = false,
                                 default = nil)
  if valid_600490 != nil:
    section.add "X-Amz-Algorithm", valid_600490
  var valid_600491 = header.getOrDefault("X-Amz-Signature")
  valid_600491 = validateParameter(valid_600491, JString, required = false,
                                 default = nil)
  if valid_600491 != nil:
    section.add "X-Amz-Signature", valid_600491
  var valid_600492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600492 = validateParameter(valid_600492, JString, required = false,
                                 default = nil)
  if valid_600492 != nil:
    section.add "X-Amz-SignedHeaders", valid_600492
  var valid_600493 = header.getOrDefault("X-Amz-Credential")
  valid_600493 = validateParameter(valid_600493, JString, required = false,
                                 default = nil)
  if valid_600493 != nil:
    section.add "X-Amz-Credential", valid_600493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600495: Call_UpdateGroup_600481; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Changes a group description. </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a group object.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight update-group --aws-account-id=111122223333 --namespace=default --group-name=Sales --description="Sales BI Dashboards" </code> </p>
  ## 
  let valid = call_600495.validator(path, query, header, formData, body)
  let scheme = call_600495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600495.url(scheme.get, call_600495.host, call_600495.base,
                         call_600495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600495, url, valid)

proc call*(call_600496: Call_UpdateGroup_600481; GroupName: string;
          AwsAccountId: string; body: JsonNode; Namespace: string): Recallable =
  ## updateGroup
  ## <p>Changes a group description. </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a group object.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight update-group --aws-account-id=111122223333 --namespace=default --group-name=Sales --description="Sales BI Dashboards" </code> </p>
  ##   GroupName: string (required)
  ##            : The name of the group that you want to update.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   body: JObject (required)
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_600497 = newJObject()
  var body_600498 = newJObject()
  add(path_600497, "GroupName", newJString(GroupName))
  add(path_600497, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_600498 = body
  add(path_600497, "Namespace", newJString(Namespace))
  result = call_600496.call(path_600497, nil, nil, nil, body_600498)

var updateGroup* = Call_UpdateGroup_600481(name: "updateGroup",
                                        meth: HttpMethod.HttpPut,
                                        host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}",
                                        validator: validate_UpdateGroup_600482,
                                        base: "/", url: url_UpdateGroup_600483,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeGroup_600465 = ref object of OpenApiRestCall_599368
proc url_DescribeGroup_600467(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeGroup_600466(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns an Amazon QuickSight group's description and Amazon Resource Name (ARN). </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;relevant-aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is the group object. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight describe-group -\-aws-account-id=11112222333 -\-namespace=default -\-group-name=Sales </code> </p>
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
  var valid_600468 = path.getOrDefault("GroupName")
  valid_600468 = validateParameter(valid_600468, JString, required = true,
                                 default = nil)
  if valid_600468 != nil:
    section.add "GroupName", valid_600468
  var valid_600469 = path.getOrDefault("AwsAccountId")
  valid_600469 = validateParameter(valid_600469, JString, required = true,
                                 default = nil)
  if valid_600469 != nil:
    section.add "AwsAccountId", valid_600469
  var valid_600470 = path.getOrDefault("Namespace")
  valid_600470 = validateParameter(valid_600470, JString, required = true,
                                 default = nil)
  if valid_600470 != nil:
    section.add "Namespace", valid_600470
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
  var valid_600471 = header.getOrDefault("X-Amz-Date")
  valid_600471 = validateParameter(valid_600471, JString, required = false,
                                 default = nil)
  if valid_600471 != nil:
    section.add "X-Amz-Date", valid_600471
  var valid_600472 = header.getOrDefault("X-Amz-Security-Token")
  valid_600472 = validateParameter(valid_600472, JString, required = false,
                                 default = nil)
  if valid_600472 != nil:
    section.add "X-Amz-Security-Token", valid_600472
  var valid_600473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600473 = validateParameter(valid_600473, JString, required = false,
                                 default = nil)
  if valid_600473 != nil:
    section.add "X-Amz-Content-Sha256", valid_600473
  var valid_600474 = header.getOrDefault("X-Amz-Algorithm")
  valid_600474 = validateParameter(valid_600474, JString, required = false,
                                 default = nil)
  if valid_600474 != nil:
    section.add "X-Amz-Algorithm", valid_600474
  var valid_600475 = header.getOrDefault("X-Amz-Signature")
  valid_600475 = validateParameter(valid_600475, JString, required = false,
                                 default = nil)
  if valid_600475 != nil:
    section.add "X-Amz-Signature", valid_600475
  var valid_600476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600476 = validateParameter(valid_600476, JString, required = false,
                                 default = nil)
  if valid_600476 != nil:
    section.add "X-Amz-SignedHeaders", valid_600476
  var valid_600477 = header.getOrDefault("X-Amz-Credential")
  valid_600477 = validateParameter(valid_600477, JString, required = false,
                                 default = nil)
  if valid_600477 != nil:
    section.add "X-Amz-Credential", valid_600477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600478: Call_DescribeGroup_600465; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns an Amazon QuickSight group's description and Amazon Resource Name (ARN). </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;relevant-aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is the group object. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight describe-group -\-aws-account-id=11112222333 -\-namespace=default -\-group-name=Sales </code> </p>
  ## 
  let valid = call_600478.validator(path, query, header, formData, body)
  let scheme = call_600478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600478.url(scheme.get, call_600478.host, call_600478.base,
                         call_600478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600478, url, valid)

proc call*(call_600479: Call_DescribeGroup_600465; GroupName: string;
          AwsAccountId: string; Namespace: string): Recallable =
  ## describeGroup
  ## <p>Returns an Amazon QuickSight group's description and Amazon Resource Name (ARN). </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;relevant-aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is the group object. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight describe-group -\-aws-account-id=11112222333 -\-namespace=default -\-group-name=Sales </code> </p>
  ##   GroupName: string (required)
  ##            : The name of the group that you want to describe.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_600480 = newJObject()
  add(path_600480, "GroupName", newJString(GroupName))
  add(path_600480, "AwsAccountId", newJString(AwsAccountId))
  add(path_600480, "Namespace", newJString(Namespace))
  result = call_600479.call(path_600480, nil, nil, nil, nil)

var describeGroup* = Call_DescribeGroup_600465(name: "describeGroup",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}",
    validator: validate_DescribeGroup_600466, base: "/", url: url_DescribeGroup_600467,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_600499 = ref object of OpenApiRestCall_599368
proc url_DeleteGroup_600501(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGroup_600500(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes a user group from Amazon QuickSight. </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight delete-group -\-aws-account-id=111122223333 -\-namespace=default -\-group-name=Sales-Management </code> </p>
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
  var valid_600502 = path.getOrDefault("GroupName")
  valid_600502 = validateParameter(valid_600502, JString, required = true,
                                 default = nil)
  if valid_600502 != nil:
    section.add "GroupName", valid_600502
  var valid_600503 = path.getOrDefault("AwsAccountId")
  valid_600503 = validateParameter(valid_600503, JString, required = true,
                                 default = nil)
  if valid_600503 != nil:
    section.add "AwsAccountId", valid_600503
  var valid_600504 = path.getOrDefault("Namespace")
  valid_600504 = validateParameter(valid_600504, JString, required = true,
                                 default = nil)
  if valid_600504 != nil:
    section.add "Namespace", valid_600504
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
  var valid_600505 = header.getOrDefault("X-Amz-Date")
  valid_600505 = validateParameter(valid_600505, JString, required = false,
                                 default = nil)
  if valid_600505 != nil:
    section.add "X-Amz-Date", valid_600505
  var valid_600506 = header.getOrDefault("X-Amz-Security-Token")
  valid_600506 = validateParameter(valid_600506, JString, required = false,
                                 default = nil)
  if valid_600506 != nil:
    section.add "X-Amz-Security-Token", valid_600506
  var valid_600507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600507 = validateParameter(valid_600507, JString, required = false,
                                 default = nil)
  if valid_600507 != nil:
    section.add "X-Amz-Content-Sha256", valid_600507
  var valid_600508 = header.getOrDefault("X-Amz-Algorithm")
  valid_600508 = validateParameter(valid_600508, JString, required = false,
                                 default = nil)
  if valid_600508 != nil:
    section.add "X-Amz-Algorithm", valid_600508
  var valid_600509 = header.getOrDefault("X-Amz-Signature")
  valid_600509 = validateParameter(valid_600509, JString, required = false,
                                 default = nil)
  if valid_600509 != nil:
    section.add "X-Amz-Signature", valid_600509
  var valid_600510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600510 = validateParameter(valid_600510, JString, required = false,
                                 default = nil)
  if valid_600510 != nil:
    section.add "X-Amz-SignedHeaders", valid_600510
  var valid_600511 = header.getOrDefault("X-Amz-Credential")
  valid_600511 = validateParameter(valid_600511, JString, required = false,
                                 default = nil)
  if valid_600511 != nil:
    section.add "X-Amz-Credential", valid_600511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600512: Call_DeleteGroup_600499; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a user group from Amazon QuickSight. </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight delete-group -\-aws-account-id=111122223333 -\-namespace=default -\-group-name=Sales-Management </code> </p>
  ## 
  let valid = call_600512.validator(path, query, header, formData, body)
  let scheme = call_600512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600512.url(scheme.get, call_600512.host, call_600512.base,
                         call_600512.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600512, url, valid)

proc call*(call_600513: Call_DeleteGroup_600499; GroupName: string;
          AwsAccountId: string; Namespace: string): Recallable =
  ## deleteGroup
  ## <p>Removes a user group from Amazon QuickSight. </p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight delete-group -\-aws-account-id=111122223333 -\-namespace=default -\-group-name=Sales-Management </code> </p>
  ##   GroupName: string (required)
  ##            : The name of the group that you want to delete.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_600514 = newJObject()
  add(path_600514, "GroupName", newJString(GroupName))
  add(path_600514, "AwsAccountId", newJString(AwsAccountId))
  add(path_600514, "Namespace", newJString(Namespace))
  result = call_600513.call(path_600514, nil, nil, nil, nil)

var deleteGroup* = Call_DeleteGroup_600499(name: "deleteGroup",
                                        meth: HttpMethod.HttpDelete,
                                        host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}",
                                        validator: validate_DeleteGroup_600500,
                                        base: "/", url: url_DeleteGroup_600501,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteIAMPolicyAssignment_600515 = ref object of OpenApiRestCall_599368
proc url_DeleteIAMPolicyAssignment_600517(protocol: Scheme; host: string;
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

proc validate_DeleteIAMPolicyAssignment_600516(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes an existing assignment.</p> <p>CLI syntax:</p> <p> <code>aws quicksight delete-iam-policy-assignment --aws-account-id=111122223333 --assignment-name=testtest --region=us-east-1 --namespace=default</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AssignmentName: JString (required)
  ##                 : The name of the assignment. 
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID where you want to delete an IAM policy assignment.
  ##   Namespace: JString (required)
  ##            : The namespace that contains the assignment.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AssignmentName` field"
  var valid_600518 = path.getOrDefault("AssignmentName")
  valid_600518 = validateParameter(valid_600518, JString, required = true,
                                 default = nil)
  if valid_600518 != nil:
    section.add "AssignmentName", valid_600518
  var valid_600519 = path.getOrDefault("AwsAccountId")
  valid_600519 = validateParameter(valid_600519, JString, required = true,
                                 default = nil)
  if valid_600519 != nil:
    section.add "AwsAccountId", valid_600519
  var valid_600520 = path.getOrDefault("Namespace")
  valid_600520 = validateParameter(valid_600520, JString, required = true,
                                 default = nil)
  if valid_600520 != nil:
    section.add "Namespace", valid_600520
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
  var valid_600521 = header.getOrDefault("X-Amz-Date")
  valid_600521 = validateParameter(valid_600521, JString, required = false,
                                 default = nil)
  if valid_600521 != nil:
    section.add "X-Amz-Date", valid_600521
  var valid_600522 = header.getOrDefault("X-Amz-Security-Token")
  valid_600522 = validateParameter(valid_600522, JString, required = false,
                                 default = nil)
  if valid_600522 != nil:
    section.add "X-Amz-Security-Token", valid_600522
  var valid_600523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600523 = validateParameter(valid_600523, JString, required = false,
                                 default = nil)
  if valid_600523 != nil:
    section.add "X-Amz-Content-Sha256", valid_600523
  var valid_600524 = header.getOrDefault("X-Amz-Algorithm")
  valid_600524 = validateParameter(valid_600524, JString, required = false,
                                 default = nil)
  if valid_600524 != nil:
    section.add "X-Amz-Algorithm", valid_600524
  var valid_600525 = header.getOrDefault("X-Amz-Signature")
  valid_600525 = validateParameter(valid_600525, JString, required = false,
                                 default = nil)
  if valid_600525 != nil:
    section.add "X-Amz-Signature", valid_600525
  var valid_600526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600526 = validateParameter(valid_600526, JString, required = false,
                                 default = nil)
  if valid_600526 != nil:
    section.add "X-Amz-SignedHeaders", valid_600526
  var valid_600527 = header.getOrDefault("X-Amz-Credential")
  valid_600527 = validateParameter(valid_600527, JString, required = false,
                                 default = nil)
  if valid_600527 != nil:
    section.add "X-Amz-Credential", valid_600527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600528: Call_DeleteIAMPolicyAssignment_600515; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an existing assignment.</p> <p>CLI syntax:</p> <p> <code>aws quicksight delete-iam-policy-assignment --aws-account-id=111122223333 --assignment-name=testtest --region=us-east-1 --namespace=default</code> </p>
  ## 
  let valid = call_600528.validator(path, query, header, formData, body)
  let scheme = call_600528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600528.url(scheme.get, call_600528.host, call_600528.base,
                         call_600528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600528, url, valid)

proc call*(call_600529: Call_DeleteIAMPolicyAssignment_600515;
          AssignmentName: string; AwsAccountId: string; Namespace: string): Recallable =
  ## deleteIAMPolicyAssignment
  ## <p>Deletes an existing assignment.</p> <p>CLI syntax:</p> <p> <code>aws quicksight delete-iam-policy-assignment --aws-account-id=111122223333 --assignment-name=testtest --region=us-east-1 --namespace=default</code> </p>
  ##   AssignmentName: string (required)
  ##                 : The name of the assignment. 
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID where you want to delete an IAM policy assignment.
  ##   Namespace: string (required)
  ##            : The namespace that contains the assignment.
  var path_600530 = newJObject()
  add(path_600530, "AssignmentName", newJString(AssignmentName))
  add(path_600530, "AwsAccountId", newJString(AwsAccountId))
  add(path_600530, "Namespace", newJString(Namespace))
  result = call_600529.call(path_600530, nil, nil, nil, nil)

var deleteIAMPolicyAssignment* = Call_DeleteIAMPolicyAssignment_600515(
    name: "deleteIAMPolicyAssignment", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespace/{Namespace}/iam-policy-assignments/{AssignmentName}",
    validator: validate_DeleteIAMPolicyAssignment_600516, base: "/",
    url: url_DeleteIAMPolicyAssignment_600517,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateUser_600547 = ref object of OpenApiRestCall_599368
proc url_UpdateUser_600549(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_UpdateUser_600548(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates an Amazon QuickSight user.</p> <p>The response is a user object that contains the user's Amazon QuickSight user name, email address, active or inactive status in Amazon QuickSight, Amazon QuickSight role, and Amazon Resource Name (ARN). </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight update-user --user-name=Pat --role=ADMIN --email=new_address@example.com --aws-account-id=111122223333 --namespace=default --region=us-east-1 </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   UserName: JString (required)
  ##           : The Amazon QuickSight user name that you want to update.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600550 = path.getOrDefault("AwsAccountId")
  valid_600550 = validateParameter(valid_600550, JString, required = true,
                                 default = nil)
  if valid_600550 != nil:
    section.add "AwsAccountId", valid_600550
  var valid_600551 = path.getOrDefault("UserName")
  valid_600551 = validateParameter(valid_600551, JString, required = true,
                                 default = nil)
  if valid_600551 != nil:
    section.add "UserName", valid_600551
  var valid_600552 = path.getOrDefault("Namespace")
  valid_600552 = validateParameter(valid_600552, JString, required = true,
                                 default = nil)
  if valid_600552 != nil:
    section.add "Namespace", valid_600552
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
  var valid_600553 = header.getOrDefault("X-Amz-Date")
  valid_600553 = validateParameter(valid_600553, JString, required = false,
                                 default = nil)
  if valid_600553 != nil:
    section.add "X-Amz-Date", valid_600553
  var valid_600554 = header.getOrDefault("X-Amz-Security-Token")
  valid_600554 = validateParameter(valid_600554, JString, required = false,
                                 default = nil)
  if valid_600554 != nil:
    section.add "X-Amz-Security-Token", valid_600554
  var valid_600555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600555 = validateParameter(valid_600555, JString, required = false,
                                 default = nil)
  if valid_600555 != nil:
    section.add "X-Amz-Content-Sha256", valid_600555
  var valid_600556 = header.getOrDefault("X-Amz-Algorithm")
  valid_600556 = validateParameter(valid_600556, JString, required = false,
                                 default = nil)
  if valid_600556 != nil:
    section.add "X-Amz-Algorithm", valid_600556
  var valid_600557 = header.getOrDefault("X-Amz-Signature")
  valid_600557 = validateParameter(valid_600557, JString, required = false,
                                 default = nil)
  if valid_600557 != nil:
    section.add "X-Amz-Signature", valid_600557
  var valid_600558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600558 = validateParameter(valid_600558, JString, required = false,
                                 default = nil)
  if valid_600558 != nil:
    section.add "X-Amz-SignedHeaders", valid_600558
  var valid_600559 = header.getOrDefault("X-Amz-Credential")
  valid_600559 = validateParameter(valid_600559, JString, required = false,
                                 default = nil)
  if valid_600559 != nil:
    section.add "X-Amz-Credential", valid_600559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600561: Call_UpdateUser_600547; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an Amazon QuickSight user.</p> <p>The response is a user object that contains the user's Amazon QuickSight user name, email address, active or inactive status in Amazon QuickSight, Amazon QuickSight role, and Amazon Resource Name (ARN). </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight update-user --user-name=Pat --role=ADMIN --email=new_address@example.com --aws-account-id=111122223333 --namespace=default --region=us-east-1 </code> </p>
  ## 
  let valid = call_600561.validator(path, query, header, formData, body)
  let scheme = call_600561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600561.url(scheme.get, call_600561.host, call_600561.base,
                         call_600561.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600561, url, valid)

proc call*(call_600562: Call_UpdateUser_600547; AwsAccountId: string; body: JsonNode;
          UserName: string; Namespace: string): Recallable =
  ## updateUser
  ## <p>Updates an Amazon QuickSight user.</p> <p>The response is a user object that contains the user's Amazon QuickSight user name, email address, active or inactive status in Amazon QuickSight, Amazon QuickSight role, and Amazon Resource Name (ARN). </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight update-user --user-name=Pat --role=ADMIN --email=new_address@example.com --aws-account-id=111122223333 --namespace=default --region=us-east-1 </code> </p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   body: JObject (required)
  ##   UserName: string (required)
  ##           : The Amazon QuickSight user name that you want to update.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_600563 = newJObject()
  var body_600564 = newJObject()
  add(path_600563, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_600564 = body
  add(path_600563, "UserName", newJString(UserName))
  add(path_600563, "Namespace", newJString(Namespace))
  result = call_600562.call(path_600563, nil, nil, nil, body_600564)

var updateUser* = Call_UpdateUser_600547(name: "updateUser",
                                      meth: HttpMethod.HttpPut,
                                      host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}",
                                      validator: validate_UpdateUser_600548,
                                      base: "/", url: url_UpdateUser_600549,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUser_600531 = ref object of OpenApiRestCall_599368
proc url_DescribeUser_600533(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeUser_600532(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns information about a user, given the user name. </p> <p>The response is a user object that contains the user's Amazon Resource Name (ARN), AWS Identity and Access Management (IAM) role, and email address. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight describe-user --aws-account-id=111122223333 --namespace=default --user-name=Pat </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   UserName: JString (required)
  ##           : The name of the user that you want to describe.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600534 = path.getOrDefault("AwsAccountId")
  valid_600534 = validateParameter(valid_600534, JString, required = true,
                                 default = nil)
  if valid_600534 != nil:
    section.add "AwsAccountId", valid_600534
  var valid_600535 = path.getOrDefault("UserName")
  valid_600535 = validateParameter(valid_600535, JString, required = true,
                                 default = nil)
  if valid_600535 != nil:
    section.add "UserName", valid_600535
  var valid_600536 = path.getOrDefault("Namespace")
  valid_600536 = validateParameter(valid_600536, JString, required = true,
                                 default = nil)
  if valid_600536 != nil:
    section.add "Namespace", valid_600536
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
  var valid_600537 = header.getOrDefault("X-Amz-Date")
  valid_600537 = validateParameter(valid_600537, JString, required = false,
                                 default = nil)
  if valid_600537 != nil:
    section.add "X-Amz-Date", valid_600537
  var valid_600538 = header.getOrDefault("X-Amz-Security-Token")
  valid_600538 = validateParameter(valid_600538, JString, required = false,
                                 default = nil)
  if valid_600538 != nil:
    section.add "X-Amz-Security-Token", valid_600538
  var valid_600539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600539 = validateParameter(valid_600539, JString, required = false,
                                 default = nil)
  if valid_600539 != nil:
    section.add "X-Amz-Content-Sha256", valid_600539
  var valid_600540 = header.getOrDefault("X-Amz-Algorithm")
  valid_600540 = validateParameter(valid_600540, JString, required = false,
                                 default = nil)
  if valid_600540 != nil:
    section.add "X-Amz-Algorithm", valid_600540
  var valid_600541 = header.getOrDefault("X-Amz-Signature")
  valid_600541 = validateParameter(valid_600541, JString, required = false,
                                 default = nil)
  if valid_600541 != nil:
    section.add "X-Amz-Signature", valid_600541
  var valid_600542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600542 = validateParameter(valid_600542, JString, required = false,
                                 default = nil)
  if valid_600542 != nil:
    section.add "X-Amz-SignedHeaders", valid_600542
  var valid_600543 = header.getOrDefault("X-Amz-Credential")
  valid_600543 = validateParameter(valid_600543, JString, required = false,
                                 default = nil)
  if valid_600543 != nil:
    section.add "X-Amz-Credential", valid_600543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600544: Call_DescribeUser_600531; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns information about a user, given the user name. </p> <p>The response is a user object that contains the user's Amazon Resource Name (ARN), AWS Identity and Access Management (IAM) role, and email address. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight describe-user --aws-account-id=111122223333 --namespace=default --user-name=Pat </code> </p>
  ## 
  let valid = call_600544.validator(path, query, header, formData, body)
  let scheme = call_600544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600544.url(scheme.get, call_600544.host, call_600544.base,
                         call_600544.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600544, url, valid)

proc call*(call_600545: Call_DescribeUser_600531; AwsAccountId: string;
          UserName: string; Namespace: string): Recallable =
  ## describeUser
  ## <p>Returns information about a user, given the user name. </p> <p>The response is a user object that contains the user's Amazon Resource Name (ARN), AWS Identity and Access Management (IAM) role, and email address. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight describe-user --aws-account-id=111122223333 --namespace=default --user-name=Pat </code> </p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   UserName: string (required)
  ##           : The name of the user that you want to describe.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_600546 = newJObject()
  add(path_600546, "AwsAccountId", newJString(AwsAccountId))
  add(path_600546, "UserName", newJString(UserName))
  add(path_600546, "Namespace", newJString(Namespace))
  result = call_600545.call(path_600546, nil, nil, nil, nil)

var describeUser* = Call_DescribeUser_600531(name: "describeUser",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}",
    validator: validate_DescribeUser_600532, base: "/", url: url_DescribeUser_600533,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUser_600565 = ref object of OpenApiRestCall_599368
proc url_DeleteUser_600567(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteUser_600566(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the Amazon QuickSight user that is associated with the identity of the AWS Identity and Access Management (IAM) user or role that's making the call. The IAM user isn't deleted as a result of this call. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight delete-user --aws-account-id=111122223333 --namespace=default --user-name=Pat </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   UserName: JString (required)
  ##           : The name of the user that you want to delete.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600568 = path.getOrDefault("AwsAccountId")
  valid_600568 = validateParameter(valid_600568, JString, required = true,
                                 default = nil)
  if valid_600568 != nil:
    section.add "AwsAccountId", valid_600568
  var valid_600569 = path.getOrDefault("UserName")
  valid_600569 = validateParameter(valid_600569, JString, required = true,
                                 default = nil)
  if valid_600569 != nil:
    section.add "UserName", valid_600569
  var valid_600570 = path.getOrDefault("Namespace")
  valid_600570 = validateParameter(valid_600570, JString, required = true,
                                 default = nil)
  if valid_600570 != nil:
    section.add "Namespace", valid_600570
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
  var valid_600571 = header.getOrDefault("X-Amz-Date")
  valid_600571 = validateParameter(valid_600571, JString, required = false,
                                 default = nil)
  if valid_600571 != nil:
    section.add "X-Amz-Date", valid_600571
  var valid_600572 = header.getOrDefault("X-Amz-Security-Token")
  valid_600572 = validateParameter(valid_600572, JString, required = false,
                                 default = nil)
  if valid_600572 != nil:
    section.add "X-Amz-Security-Token", valid_600572
  var valid_600573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600573 = validateParameter(valid_600573, JString, required = false,
                                 default = nil)
  if valid_600573 != nil:
    section.add "X-Amz-Content-Sha256", valid_600573
  var valid_600574 = header.getOrDefault("X-Amz-Algorithm")
  valid_600574 = validateParameter(valid_600574, JString, required = false,
                                 default = nil)
  if valid_600574 != nil:
    section.add "X-Amz-Algorithm", valid_600574
  var valid_600575 = header.getOrDefault("X-Amz-Signature")
  valid_600575 = validateParameter(valid_600575, JString, required = false,
                                 default = nil)
  if valid_600575 != nil:
    section.add "X-Amz-Signature", valid_600575
  var valid_600576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600576 = validateParameter(valid_600576, JString, required = false,
                                 default = nil)
  if valid_600576 != nil:
    section.add "X-Amz-SignedHeaders", valid_600576
  var valid_600577 = header.getOrDefault("X-Amz-Credential")
  valid_600577 = validateParameter(valid_600577, JString, required = false,
                                 default = nil)
  if valid_600577 != nil:
    section.add "X-Amz-Credential", valid_600577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600578: Call_DeleteUser_600565; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the Amazon QuickSight user that is associated with the identity of the AWS Identity and Access Management (IAM) user or role that's making the call. The IAM user isn't deleted as a result of this call. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight delete-user --aws-account-id=111122223333 --namespace=default --user-name=Pat </code> </p>
  ## 
  let valid = call_600578.validator(path, query, header, formData, body)
  let scheme = call_600578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600578.url(scheme.get, call_600578.host, call_600578.base,
                         call_600578.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600578, url, valid)

proc call*(call_600579: Call_DeleteUser_600565; AwsAccountId: string;
          UserName: string; Namespace: string): Recallable =
  ## deleteUser
  ## <p>Deletes the Amazon QuickSight user that is associated with the identity of the AWS Identity and Access Management (IAM) user or role that's making the call. The IAM user isn't deleted as a result of this call. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight delete-user --aws-account-id=111122223333 --namespace=default --user-name=Pat </code> </p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   UserName: string (required)
  ##           : The name of the user that you want to delete.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_600580 = newJObject()
  add(path_600580, "AwsAccountId", newJString(AwsAccountId))
  add(path_600580, "UserName", newJString(UserName))
  add(path_600580, "Namespace", newJString(Namespace))
  result = call_600579.call(path_600580, nil, nil, nil, nil)

var deleteUser* = Call_DeleteUser_600565(name: "deleteUser",
                                      meth: HttpMethod.HttpDelete,
                                      host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}",
                                      validator: validate_DeleteUser_600566,
                                      base: "/", url: url_DeleteUser_600567,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteUserByPrincipalId_600581 = ref object of OpenApiRestCall_599368
proc url_DeleteUserByPrincipalId_600583(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteUserByPrincipalId_600582(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a user identified by its principal ID. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight delete-user-by-principal-id --aws-account-id=111122223333 --namespace=default --principal-id=ABCDEFJA26JLI7EUUOEHS </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   PrincipalId: JString (required)
  ##              : The principal ID of the user.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600584 = path.getOrDefault("AwsAccountId")
  valid_600584 = validateParameter(valid_600584, JString, required = true,
                                 default = nil)
  if valid_600584 != nil:
    section.add "AwsAccountId", valid_600584
  var valid_600585 = path.getOrDefault("PrincipalId")
  valid_600585 = validateParameter(valid_600585, JString, required = true,
                                 default = nil)
  if valid_600585 != nil:
    section.add "PrincipalId", valid_600585
  var valid_600586 = path.getOrDefault("Namespace")
  valid_600586 = validateParameter(valid_600586, JString, required = true,
                                 default = nil)
  if valid_600586 != nil:
    section.add "Namespace", valid_600586
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
  var valid_600587 = header.getOrDefault("X-Amz-Date")
  valid_600587 = validateParameter(valid_600587, JString, required = false,
                                 default = nil)
  if valid_600587 != nil:
    section.add "X-Amz-Date", valid_600587
  var valid_600588 = header.getOrDefault("X-Amz-Security-Token")
  valid_600588 = validateParameter(valid_600588, JString, required = false,
                                 default = nil)
  if valid_600588 != nil:
    section.add "X-Amz-Security-Token", valid_600588
  var valid_600589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600589 = validateParameter(valid_600589, JString, required = false,
                                 default = nil)
  if valid_600589 != nil:
    section.add "X-Amz-Content-Sha256", valid_600589
  var valid_600590 = header.getOrDefault("X-Amz-Algorithm")
  valid_600590 = validateParameter(valid_600590, JString, required = false,
                                 default = nil)
  if valid_600590 != nil:
    section.add "X-Amz-Algorithm", valid_600590
  var valid_600591 = header.getOrDefault("X-Amz-Signature")
  valid_600591 = validateParameter(valid_600591, JString, required = false,
                                 default = nil)
  if valid_600591 != nil:
    section.add "X-Amz-Signature", valid_600591
  var valid_600592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600592 = validateParameter(valid_600592, JString, required = false,
                                 default = nil)
  if valid_600592 != nil:
    section.add "X-Amz-SignedHeaders", valid_600592
  var valid_600593 = header.getOrDefault("X-Amz-Credential")
  valid_600593 = validateParameter(valid_600593, JString, required = false,
                                 default = nil)
  if valid_600593 != nil:
    section.add "X-Amz-Credential", valid_600593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600594: Call_DeleteUserByPrincipalId_600581; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a user identified by its principal ID. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight delete-user-by-principal-id --aws-account-id=111122223333 --namespace=default --principal-id=ABCDEFJA26JLI7EUUOEHS </code> </p>
  ## 
  let valid = call_600594.validator(path, query, header, formData, body)
  let scheme = call_600594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600594.url(scheme.get, call_600594.host, call_600594.base,
                         call_600594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600594, url, valid)

proc call*(call_600595: Call_DeleteUserByPrincipalId_600581; AwsAccountId: string;
          PrincipalId: string; Namespace: string): Recallable =
  ## deleteUserByPrincipalId
  ## <p>Deletes a user identified by its principal ID. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight delete-user-by-principal-id --aws-account-id=111122223333 --namespace=default --principal-id=ABCDEFJA26JLI7EUUOEHS </code> </p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   PrincipalId: string (required)
  ##              : The principal ID of the user.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_600596 = newJObject()
  add(path_600596, "AwsAccountId", newJString(AwsAccountId))
  add(path_600596, "PrincipalId", newJString(PrincipalId))
  add(path_600596, "Namespace", newJString(Namespace))
  result = call_600595.call(path_600596, nil, nil, nil, nil)

var deleteUserByPrincipalId* = Call_DeleteUserByPrincipalId_600581(
    name: "deleteUserByPrincipalId", meth: HttpMethod.HttpDelete,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/user-principals/{PrincipalId}",
    validator: validate_DeleteUserByPrincipalId_600582, base: "/",
    url: url_DeleteUserByPrincipalId_600583, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDashboardPermissions_600612 = ref object of OpenApiRestCall_599368
proc url_UpdateDashboardPermissions_600614(protocol: Scheme; host: string;
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

proc validate_UpdateDashboardPermissions_600613(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates read and write permissions on a dashboard.</p> <p>CLI syntax:</p> <p> <code>aws quicksight update-dashboard-permissions —cli-input-json file://update-permission.json</code> </p> <p>A sample update-permissions.json for granting read only permissions:</p> <p> <code>{ "AwsAccountId": "111122223333", "DashboardId": "reports_test_report", "GrantPermissions": [ { "Principal": "arn:aws:quicksight:us-east-1:111122223333:user/default/user2", "Actions": [ "quicksight:DescribeDashboard", "quicksight:ListDashboardVersions", "quicksight:DescribeDashboardVersion", "quicksight:QueryDashboard" ] } ] }</code> </p> <p>A sample update-permissions.json for granting read and write permissions:</p> <p> <code>{ "AwsAccountId": "111122223333", "DashboardId": "reports_test_report", "GrantPermissions": [ { "Principal": "arn:aws:quicksight:us-east-1:111122223333:user/default/user2", "Actions": [ "quicksight:DescribeDashboard", "quicksight:ListDashboardVersions", "quicksight:DescribeDashboardVersion", "quicksight:QueryDashboard", "quicksight:DescribeDashboardPermissions", "quicksight:UpdateDashboardPermissions", "quicksight:DeleteDashboardVersion", "quicksight:DeleteDashboard", "quicksight:UpdateDashboard", "quicksight:UpdateDashboardPublishedVersion", ] } ] }</code> </p> <p>A sample update-permissions.json for revoking write permissions:</p> <p> <code>{ "AwsAccountId": "111122223333", "DashboardId": "reports_test_report", "RevokePermissions": [ { "Principal": "arn:aws:quicksight:us-east-1:111122223333:user/default/user2", "Actions": [ "quicksight:DescribeDashboardPermissions", "quicksight:UpdateDashboardPermissions", "quicksight:DeleteDashboardVersion", "quicksight:DeleteDashboard", "quicksight:UpdateDashboard", "quicksight:UpdateDashboardPublishedVersion", ] } ] }</code> </p> <p>A sample update-permissions.json for revoking read and write permissions:</p> <p> <code>{ "AwsAccountId": "111122223333", "DashboardId": "reports_test_report", "RevokePermissions": [ { "Principal": "arn:aws:quicksight:us-east-1:111122223333:user/default/user2", "Actions": [ "quicksight:DescribeDashboard", "quicksight:ListDashboardVersions", "quicksight:DescribeDashboardVersion", "quicksight:QueryDashboard", "quicksight:DescribeDashboardPermissions", "quicksight:UpdateDashboardPermissions", "quicksight:DeleteDashboardVersion", "quicksight:DeleteDashboard", "quicksight:UpdateDashboard", "quicksight:UpdateDashboardPublishedVersion", ] } ] }</code> </p> <p>To obtain the principal name of a QuickSight user or group, you can use describe-group or describe-user. For example:</p> <p> <code>aws quicksight describe-user --aws-account-id 111122223333 --namespace default --user-name user2 --region us-east-1 { "User": { "Arn": "arn:aws:quicksight:us-east-1:111122223333:user/default/user2", "Active": true, "Email": "user2@example.com", "Role": "ADMIN", "UserName": "user2", "PrincipalId": "federated/iam/abcd2abcdabcdeabc5ab5" }, "RequestId": "8f74bb31-6291-448a-a71c-a765a44bae31", "Status": 200 }</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : AWS account ID that contains the dashboard you are updating.
  ##   DashboardId: JString (required)
  ##              : The ID for the dashboard.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600615 = path.getOrDefault("AwsAccountId")
  valid_600615 = validateParameter(valid_600615, JString, required = true,
                                 default = nil)
  if valid_600615 != nil:
    section.add "AwsAccountId", valid_600615
  var valid_600616 = path.getOrDefault("DashboardId")
  valid_600616 = validateParameter(valid_600616, JString, required = true,
                                 default = nil)
  if valid_600616 != nil:
    section.add "DashboardId", valid_600616
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
  var valid_600617 = header.getOrDefault("X-Amz-Date")
  valid_600617 = validateParameter(valid_600617, JString, required = false,
                                 default = nil)
  if valid_600617 != nil:
    section.add "X-Amz-Date", valid_600617
  var valid_600618 = header.getOrDefault("X-Amz-Security-Token")
  valid_600618 = validateParameter(valid_600618, JString, required = false,
                                 default = nil)
  if valid_600618 != nil:
    section.add "X-Amz-Security-Token", valid_600618
  var valid_600619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600619 = validateParameter(valid_600619, JString, required = false,
                                 default = nil)
  if valid_600619 != nil:
    section.add "X-Amz-Content-Sha256", valid_600619
  var valid_600620 = header.getOrDefault("X-Amz-Algorithm")
  valid_600620 = validateParameter(valid_600620, JString, required = false,
                                 default = nil)
  if valid_600620 != nil:
    section.add "X-Amz-Algorithm", valid_600620
  var valid_600621 = header.getOrDefault("X-Amz-Signature")
  valid_600621 = validateParameter(valid_600621, JString, required = false,
                                 default = nil)
  if valid_600621 != nil:
    section.add "X-Amz-Signature", valid_600621
  var valid_600622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600622 = validateParameter(valid_600622, JString, required = false,
                                 default = nil)
  if valid_600622 != nil:
    section.add "X-Amz-SignedHeaders", valid_600622
  var valid_600623 = header.getOrDefault("X-Amz-Credential")
  valid_600623 = validateParameter(valid_600623, JString, required = false,
                                 default = nil)
  if valid_600623 != nil:
    section.add "X-Amz-Credential", valid_600623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600625: Call_UpdateDashboardPermissions_600612; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates read and write permissions on a dashboard.</p> <p>CLI syntax:</p> <p> <code>aws quicksight update-dashboard-permissions —cli-input-json file://update-permission.json</code> </p> <p>A sample update-permissions.json for granting read only permissions:</p> <p> <code>{ "AwsAccountId": "111122223333", "DashboardId": "reports_test_report", "GrantPermissions": [ { "Principal": "arn:aws:quicksight:us-east-1:111122223333:user/default/user2", "Actions": [ "quicksight:DescribeDashboard", "quicksight:ListDashboardVersions", "quicksight:DescribeDashboardVersion", "quicksight:QueryDashboard" ] } ] }</code> </p> <p>A sample update-permissions.json for granting read and write permissions:</p> <p> <code>{ "AwsAccountId": "111122223333", "DashboardId": "reports_test_report", "GrantPermissions": [ { "Principal": "arn:aws:quicksight:us-east-1:111122223333:user/default/user2", "Actions": [ "quicksight:DescribeDashboard", "quicksight:ListDashboardVersions", "quicksight:DescribeDashboardVersion", "quicksight:QueryDashboard", "quicksight:DescribeDashboardPermissions", "quicksight:UpdateDashboardPermissions", "quicksight:DeleteDashboardVersion", "quicksight:DeleteDashboard", "quicksight:UpdateDashboard", "quicksight:UpdateDashboardPublishedVersion", ] } ] }</code> </p> <p>A sample update-permissions.json for revoking write permissions:</p> <p> <code>{ "AwsAccountId": "111122223333", "DashboardId": "reports_test_report", "RevokePermissions": [ { "Principal": "arn:aws:quicksight:us-east-1:111122223333:user/default/user2", "Actions": [ "quicksight:DescribeDashboardPermissions", "quicksight:UpdateDashboardPermissions", "quicksight:DeleteDashboardVersion", "quicksight:DeleteDashboard", "quicksight:UpdateDashboard", "quicksight:UpdateDashboardPublishedVersion", ] } ] }</code> </p> <p>A sample update-permissions.json for revoking read and write permissions:</p> <p> <code>{ "AwsAccountId": "111122223333", "DashboardId": "reports_test_report", "RevokePermissions": [ { "Principal": "arn:aws:quicksight:us-east-1:111122223333:user/default/user2", "Actions": [ "quicksight:DescribeDashboard", "quicksight:ListDashboardVersions", "quicksight:DescribeDashboardVersion", "quicksight:QueryDashboard", "quicksight:DescribeDashboardPermissions", "quicksight:UpdateDashboardPermissions", "quicksight:DeleteDashboardVersion", "quicksight:DeleteDashboard", "quicksight:UpdateDashboard", "quicksight:UpdateDashboardPublishedVersion", ] } ] }</code> </p> <p>To obtain the principal name of a QuickSight user or group, you can use describe-group or describe-user. For example:</p> <p> <code>aws quicksight describe-user --aws-account-id 111122223333 --namespace default --user-name user2 --region us-east-1 { "User": { "Arn": "arn:aws:quicksight:us-east-1:111122223333:user/default/user2", "Active": true, "Email": "user2@example.com", "Role": "ADMIN", "UserName": "user2", "PrincipalId": "federated/iam/abcd2abcdabcdeabc5ab5" }, "RequestId": "8f74bb31-6291-448a-a71c-a765a44bae31", "Status": 200 }</code> </p>
  ## 
  let valid = call_600625.validator(path, query, header, formData, body)
  let scheme = call_600625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600625.url(scheme.get, call_600625.host, call_600625.base,
                         call_600625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600625, url, valid)

proc call*(call_600626: Call_UpdateDashboardPermissions_600612;
          AwsAccountId: string; DashboardId: string; body: JsonNode): Recallable =
  ## updateDashboardPermissions
  ## <p>Updates read and write permissions on a dashboard.</p> <p>CLI syntax:</p> <p> <code>aws quicksight update-dashboard-permissions —cli-input-json file://update-permission.json</code> </p> <p>A sample update-permissions.json for granting read only permissions:</p> <p> <code>{ "AwsAccountId": "111122223333", "DashboardId": "reports_test_report", "GrantPermissions": [ { "Principal": "arn:aws:quicksight:us-east-1:111122223333:user/default/user2", "Actions": [ "quicksight:DescribeDashboard", "quicksight:ListDashboardVersions", "quicksight:DescribeDashboardVersion", "quicksight:QueryDashboard" ] } ] }</code> </p> <p>A sample update-permissions.json for granting read and write permissions:</p> <p> <code>{ "AwsAccountId": "111122223333", "DashboardId": "reports_test_report", "GrantPermissions": [ { "Principal": "arn:aws:quicksight:us-east-1:111122223333:user/default/user2", "Actions": [ "quicksight:DescribeDashboard", "quicksight:ListDashboardVersions", "quicksight:DescribeDashboardVersion", "quicksight:QueryDashboard", "quicksight:DescribeDashboardPermissions", "quicksight:UpdateDashboardPermissions", "quicksight:DeleteDashboardVersion", "quicksight:DeleteDashboard", "quicksight:UpdateDashboard", "quicksight:UpdateDashboardPublishedVersion", ] } ] }</code> </p> <p>A sample update-permissions.json for revoking write permissions:</p> <p> <code>{ "AwsAccountId": "111122223333", "DashboardId": "reports_test_report", "RevokePermissions": [ { "Principal": "arn:aws:quicksight:us-east-1:111122223333:user/default/user2", "Actions": [ "quicksight:DescribeDashboardPermissions", "quicksight:UpdateDashboardPermissions", "quicksight:DeleteDashboardVersion", "quicksight:DeleteDashboard", "quicksight:UpdateDashboard", "quicksight:UpdateDashboardPublishedVersion", ] } ] }</code> </p> <p>A sample update-permissions.json for revoking read and write permissions:</p> <p> <code>{ "AwsAccountId": "111122223333", "DashboardId": "reports_test_report", "RevokePermissions": [ { "Principal": "arn:aws:quicksight:us-east-1:111122223333:user/default/user2", "Actions": [ "quicksight:DescribeDashboard", "quicksight:ListDashboardVersions", "quicksight:DescribeDashboardVersion", "quicksight:QueryDashboard", "quicksight:DescribeDashboardPermissions", "quicksight:UpdateDashboardPermissions", "quicksight:DeleteDashboardVersion", "quicksight:DeleteDashboard", "quicksight:UpdateDashboard", "quicksight:UpdateDashboardPublishedVersion", ] } ] }</code> </p> <p>To obtain the principal name of a QuickSight user or group, you can use describe-group or describe-user. For example:</p> <p> <code>aws quicksight describe-user --aws-account-id 111122223333 --namespace default --user-name user2 --region us-east-1 { "User": { "Arn": "arn:aws:quicksight:us-east-1:111122223333:user/default/user2", "Active": true, "Email": "user2@example.com", "Role": "ADMIN", "UserName": "user2", "PrincipalId": "federated/iam/abcd2abcdabcdeabc5ab5" }, "RequestId": "8f74bb31-6291-448a-a71c-a765a44bae31", "Status": 200 }</code> </p>
  ##   AwsAccountId: string (required)
  ##               : AWS account ID that contains the dashboard you are updating.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  ##   body: JObject (required)
  var path_600627 = newJObject()
  var body_600628 = newJObject()
  add(path_600627, "AwsAccountId", newJString(AwsAccountId))
  add(path_600627, "DashboardId", newJString(DashboardId))
  if body != nil:
    body_600628 = body
  result = call_600626.call(path_600627, nil, nil, nil, body_600628)

var updateDashboardPermissions* = Call_UpdateDashboardPermissions_600612(
    name: "updateDashboardPermissions", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/permissions",
    validator: validate_UpdateDashboardPermissions_600613, base: "/",
    url: url_UpdateDashboardPermissions_600614,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDashboardPermissions_600597 = ref object of OpenApiRestCall_599368
proc url_DescribeDashboardPermissions_600599(protocol: Scheme; host: string;
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

proc validate_DescribeDashboardPermissions_600598(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes read and write permissions on a dashboard.</p> <p>CLI syntax:</p> <p> <code>aws quicksight describe-dashboard-permissions --aws-account-id 735340738645 —dashboard-id reports_test_bob_report</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : AWS account ID that contains the dashboard you are describing permissions of.
  ##   DashboardId: JString (required)
  ##              : The ID for the dashboard, also added to IAM policy.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600600 = path.getOrDefault("AwsAccountId")
  valid_600600 = validateParameter(valid_600600, JString, required = true,
                                 default = nil)
  if valid_600600 != nil:
    section.add "AwsAccountId", valid_600600
  var valid_600601 = path.getOrDefault("DashboardId")
  valid_600601 = validateParameter(valid_600601, JString, required = true,
                                 default = nil)
  if valid_600601 != nil:
    section.add "DashboardId", valid_600601
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
  var valid_600602 = header.getOrDefault("X-Amz-Date")
  valid_600602 = validateParameter(valid_600602, JString, required = false,
                                 default = nil)
  if valid_600602 != nil:
    section.add "X-Amz-Date", valid_600602
  var valid_600603 = header.getOrDefault("X-Amz-Security-Token")
  valid_600603 = validateParameter(valid_600603, JString, required = false,
                                 default = nil)
  if valid_600603 != nil:
    section.add "X-Amz-Security-Token", valid_600603
  var valid_600604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600604 = validateParameter(valid_600604, JString, required = false,
                                 default = nil)
  if valid_600604 != nil:
    section.add "X-Amz-Content-Sha256", valid_600604
  var valid_600605 = header.getOrDefault("X-Amz-Algorithm")
  valid_600605 = validateParameter(valid_600605, JString, required = false,
                                 default = nil)
  if valid_600605 != nil:
    section.add "X-Amz-Algorithm", valid_600605
  var valid_600606 = header.getOrDefault("X-Amz-Signature")
  valid_600606 = validateParameter(valid_600606, JString, required = false,
                                 default = nil)
  if valid_600606 != nil:
    section.add "X-Amz-Signature", valid_600606
  var valid_600607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600607 = validateParameter(valid_600607, JString, required = false,
                                 default = nil)
  if valid_600607 != nil:
    section.add "X-Amz-SignedHeaders", valid_600607
  var valid_600608 = header.getOrDefault("X-Amz-Credential")
  valid_600608 = validateParameter(valid_600608, JString, required = false,
                                 default = nil)
  if valid_600608 != nil:
    section.add "X-Amz-Credential", valid_600608
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600609: Call_DescribeDashboardPermissions_600597; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes read and write permissions on a dashboard.</p> <p>CLI syntax:</p> <p> <code>aws quicksight describe-dashboard-permissions --aws-account-id 735340738645 —dashboard-id reports_test_bob_report</code> </p>
  ## 
  let valid = call_600609.validator(path, query, header, formData, body)
  let scheme = call_600609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600609.url(scheme.get, call_600609.host, call_600609.base,
                         call_600609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600609, url, valid)

proc call*(call_600610: Call_DescribeDashboardPermissions_600597;
          AwsAccountId: string; DashboardId: string): Recallable =
  ## describeDashboardPermissions
  ## <p>Describes read and write permissions on a dashboard.</p> <p>CLI syntax:</p> <p> <code>aws quicksight describe-dashboard-permissions --aws-account-id 735340738645 —dashboard-id reports_test_bob_report</code> </p>
  ##   AwsAccountId: string (required)
  ##               : AWS account ID that contains the dashboard you are describing permissions of.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard, also added to IAM policy.
  var path_600611 = newJObject()
  add(path_600611, "AwsAccountId", newJString(AwsAccountId))
  add(path_600611, "DashboardId", newJString(DashboardId))
  result = call_600610.call(path_600611, nil, nil, nil, nil)

var describeDashboardPermissions* = Call_DescribeDashboardPermissions_600597(
    name: "describeDashboardPermissions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/permissions",
    validator: validate_DescribeDashboardPermissions_600598, base: "/",
    url: url_DescribeDashboardPermissions_600599,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSetPermissions_600644 = ref object of OpenApiRestCall_599368
proc url_UpdateDataSetPermissions_600646(protocol: Scheme; host: string;
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

proc validate_UpdateDataSetPermissions_600645(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code> </p> <p>CLI syntax: </p> <p> <code>aws quicksight update-data-set-permissions \</code> </p> <p> <code>--aws-account-id=111122223333 \</code> </p> <p> <code>--data-set-id=unique-data-set-id \</code> </p> <p> <code>--grant-permissions='[{"Principal":"arn:aws:quicksight:us-east-1:111122223333:user/default/user1","Actions":["quicksight:DescribeDataSet","quicksight:DescribeDataSetPermissions","quicksight:PassDataSet","quicksight:ListIngestions","quicksight:DescribeIngestion"]}]' \</code> </p> <p> <code>--revoke-permissions='[{"Principal":"arn:aws:quicksight:us-east-1:111122223333:user/default/user2","Actions":["quicksight:UpdateDataSet","quicksight:DeleteDataSet","quicksight:UpdateDataSetPermissions","quicksight:CreateIngestion","quicksight:CancelIngestion"]}]'</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS Account ID.
  ##   DataSetId: JString (required)
  ##            : The ID for the dataset you want to create. This is unique per region per AWS account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600647 = path.getOrDefault("AwsAccountId")
  valid_600647 = validateParameter(valid_600647, JString, required = true,
                                 default = nil)
  if valid_600647 != nil:
    section.add "AwsAccountId", valid_600647
  var valid_600648 = path.getOrDefault("DataSetId")
  valid_600648 = validateParameter(valid_600648, JString, required = true,
                                 default = nil)
  if valid_600648 != nil:
    section.add "DataSetId", valid_600648
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
  var valid_600649 = header.getOrDefault("X-Amz-Date")
  valid_600649 = validateParameter(valid_600649, JString, required = false,
                                 default = nil)
  if valid_600649 != nil:
    section.add "X-Amz-Date", valid_600649
  var valid_600650 = header.getOrDefault("X-Amz-Security-Token")
  valid_600650 = validateParameter(valid_600650, JString, required = false,
                                 default = nil)
  if valid_600650 != nil:
    section.add "X-Amz-Security-Token", valid_600650
  var valid_600651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600651 = validateParameter(valid_600651, JString, required = false,
                                 default = nil)
  if valid_600651 != nil:
    section.add "X-Amz-Content-Sha256", valid_600651
  var valid_600652 = header.getOrDefault("X-Amz-Algorithm")
  valid_600652 = validateParameter(valid_600652, JString, required = false,
                                 default = nil)
  if valid_600652 != nil:
    section.add "X-Amz-Algorithm", valid_600652
  var valid_600653 = header.getOrDefault("X-Amz-Signature")
  valid_600653 = validateParameter(valid_600653, JString, required = false,
                                 default = nil)
  if valid_600653 != nil:
    section.add "X-Amz-Signature", valid_600653
  var valid_600654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600654 = validateParameter(valid_600654, JString, required = false,
                                 default = nil)
  if valid_600654 != nil:
    section.add "X-Amz-SignedHeaders", valid_600654
  var valid_600655 = header.getOrDefault("X-Amz-Credential")
  valid_600655 = validateParameter(valid_600655, JString, required = false,
                                 default = nil)
  if valid_600655 != nil:
    section.add "X-Amz-Credential", valid_600655
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600657: Call_UpdateDataSetPermissions_600644; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code> </p> <p>CLI syntax: </p> <p> <code>aws quicksight update-data-set-permissions \</code> </p> <p> <code>--aws-account-id=111122223333 \</code> </p> <p> <code>--data-set-id=unique-data-set-id \</code> </p> <p> <code>--grant-permissions='[{"Principal":"arn:aws:quicksight:us-east-1:111122223333:user/default/user1","Actions":["quicksight:DescribeDataSet","quicksight:DescribeDataSetPermissions","quicksight:PassDataSet","quicksight:ListIngestions","quicksight:DescribeIngestion"]}]' \</code> </p> <p> <code>--revoke-permissions='[{"Principal":"arn:aws:quicksight:us-east-1:111122223333:user/default/user2","Actions":["quicksight:UpdateDataSet","quicksight:DeleteDataSet","quicksight:UpdateDataSetPermissions","quicksight:CreateIngestion","quicksight:CancelIngestion"]}]'</code> </p>
  ## 
  let valid = call_600657.validator(path, query, header, formData, body)
  let scheme = call_600657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600657.url(scheme.get, call_600657.host, call_600657.base,
                         call_600657.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600657, url, valid)

proc call*(call_600658: Call_UpdateDataSetPermissions_600644; AwsAccountId: string;
          body: JsonNode; DataSetId: string): Recallable =
  ## updateDataSetPermissions
  ## <p>Updates the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code> </p> <p>CLI syntax: </p> <p> <code>aws quicksight update-data-set-permissions \</code> </p> <p> <code>--aws-account-id=111122223333 \</code> </p> <p> <code>--data-set-id=unique-data-set-id \</code> </p> <p> <code>--grant-permissions='[{"Principal":"arn:aws:quicksight:us-east-1:111122223333:user/default/user1","Actions":["quicksight:DescribeDataSet","quicksight:DescribeDataSetPermissions","quicksight:PassDataSet","quicksight:ListIngestions","quicksight:DescribeIngestion"]}]' \</code> </p> <p> <code>--revoke-permissions='[{"Principal":"arn:aws:quicksight:us-east-1:111122223333:user/default/user2","Actions":["quicksight:UpdateDataSet","quicksight:DeleteDataSet","quicksight:UpdateDataSetPermissions","quicksight:CreateIngestion","quicksight:CancelIngestion"]}]'</code> </p>
  ##   AwsAccountId: string (required)
  ##               : The AWS Account ID.
  ##   body: JObject (required)
  ##   DataSetId: string (required)
  ##            : The ID for the dataset you want to create. This is unique per region per AWS account.
  var path_600659 = newJObject()
  var body_600660 = newJObject()
  add(path_600659, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_600660 = body
  add(path_600659, "DataSetId", newJString(DataSetId))
  result = call_600658.call(path_600659, nil, nil, nil, body_600660)

var updateDataSetPermissions* = Call_UpdateDataSetPermissions_600644(
    name: "updateDataSetPermissions", meth: HttpMethod.HttpPost,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/permissions",
    validator: validate_UpdateDataSetPermissions_600645, base: "/",
    url: url_UpdateDataSetPermissions_600646, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSetPermissions_600629 = ref object of OpenApiRestCall_599368
proc url_DescribeDataSetPermissions_600631(protocol: Scheme; host: string;
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

proc validate_DescribeDataSetPermissions_600630(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code> </p> <p>CLI syntax: </p> <p> <code>aws quicksight describe-data-set-permissions \</code> </p> <p> <code>--aws-account-id=111122223333 \</code> </p> <p> <code>--data-set-id=unique-data-set-id \</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS Account ID.
  ##   DataSetId: JString (required)
  ##            : The ID for the dataset you want to create. This is unique per region per AWS account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600632 = path.getOrDefault("AwsAccountId")
  valid_600632 = validateParameter(valid_600632, JString, required = true,
                                 default = nil)
  if valid_600632 != nil:
    section.add "AwsAccountId", valid_600632
  var valid_600633 = path.getOrDefault("DataSetId")
  valid_600633 = validateParameter(valid_600633, JString, required = true,
                                 default = nil)
  if valid_600633 != nil:
    section.add "DataSetId", valid_600633
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
  var valid_600634 = header.getOrDefault("X-Amz-Date")
  valid_600634 = validateParameter(valid_600634, JString, required = false,
                                 default = nil)
  if valid_600634 != nil:
    section.add "X-Amz-Date", valid_600634
  var valid_600635 = header.getOrDefault("X-Amz-Security-Token")
  valid_600635 = validateParameter(valid_600635, JString, required = false,
                                 default = nil)
  if valid_600635 != nil:
    section.add "X-Amz-Security-Token", valid_600635
  var valid_600636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600636 = validateParameter(valid_600636, JString, required = false,
                                 default = nil)
  if valid_600636 != nil:
    section.add "X-Amz-Content-Sha256", valid_600636
  var valid_600637 = header.getOrDefault("X-Amz-Algorithm")
  valid_600637 = validateParameter(valid_600637, JString, required = false,
                                 default = nil)
  if valid_600637 != nil:
    section.add "X-Amz-Algorithm", valid_600637
  var valid_600638 = header.getOrDefault("X-Amz-Signature")
  valid_600638 = validateParameter(valid_600638, JString, required = false,
                                 default = nil)
  if valid_600638 != nil:
    section.add "X-Amz-Signature", valid_600638
  var valid_600639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600639 = validateParameter(valid_600639, JString, required = false,
                                 default = nil)
  if valid_600639 != nil:
    section.add "X-Amz-SignedHeaders", valid_600639
  var valid_600640 = header.getOrDefault("X-Amz-Credential")
  valid_600640 = validateParameter(valid_600640, JString, required = false,
                                 default = nil)
  if valid_600640 != nil:
    section.add "X-Amz-Credential", valid_600640
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600641: Call_DescribeDataSetPermissions_600629; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code> </p> <p>CLI syntax: </p> <p> <code>aws quicksight describe-data-set-permissions \</code> </p> <p> <code>--aws-account-id=111122223333 \</code> </p> <p> <code>--data-set-id=unique-data-set-id \</code> </p>
  ## 
  let valid = call_600641.validator(path, query, header, formData, body)
  let scheme = call_600641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600641.url(scheme.get, call_600641.host, call_600641.base,
                         call_600641.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600641, url, valid)

proc call*(call_600642: Call_DescribeDataSetPermissions_600629;
          AwsAccountId: string; DataSetId: string): Recallable =
  ## describeDataSetPermissions
  ## <p>Describes the permissions on a dataset.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:dataset/data-set-id</code> </p> <p>CLI syntax: </p> <p> <code>aws quicksight describe-data-set-permissions \</code> </p> <p> <code>--aws-account-id=111122223333 \</code> </p> <p> <code>--data-set-id=unique-data-set-id \</code> </p>
  ##   AwsAccountId: string (required)
  ##               : The AWS Account ID.
  ##   DataSetId: string (required)
  ##            : The ID for the dataset you want to create. This is unique per region per AWS account.
  var path_600643 = newJObject()
  add(path_600643, "AwsAccountId", newJString(AwsAccountId))
  add(path_600643, "DataSetId", newJString(DataSetId))
  result = call_600642.call(path_600643, nil, nil, nil, nil)

var describeDataSetPermissions* = Call_DescribeDataSetPermissions_600629(
    name: "describeDataSetPermissions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/permissions",
    validator: validate_DescribeDataSetPermissions_600630, base: "/",
    url: url_DescribeDataSetPermissions_600631,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDataSourcePermissions_600676 = ref object of OpenApiRestCall_599368
proc url_UpdateDataSourcePermissions_600678(protocol: Scheme; host: string;
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

proc validate_UpdateDataSourcePermissions_600677(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the permissions to a data source.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:datasource/data-source-id</code> </p> <p>CLI syntax:</p> <p> <code>aws quicksight update-data-source-permissions \</code> </p> <p> <code>--aws-account-id=111122223333 \</code> </p> <p> <code>--data-source-id=unique-data-source-id \</code> </p> <p> <code>--name='My Data Source' \</code> </p> <p> <code>--grant-permissions='[{"Principal":"arn:aws:quicksight:us-east-1:111122223333:user/default/user1","Actions":["quicksight:DescribeDataSource","quicksight:DescribeDataSourcePermissions","quicksight:PassDataSource"]}]' \</code> </p> <p> <code>--revoke-permissions='[{"Principal":"arn:aws:quicksight:us-east-1:111122223333:user/default/user2","Actions":["quicksight:UpdateDataSource","quicksight:DeleteDataSource","quicksight:UpdateDataSourcePermissions"]}]'</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  ##   DataSourceId: JString (required)
  ##               : The ID of the data source. This is unique per AWS Region per AWS account. 
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600679 = path.getOrDefault("AwsAccountId")
  valid_600679 = validateParameter(valid_600679, JString, required = true,
                                 default = nil)
  if valid_600679 != nil:
    section.add "AwsAccountId", valid_600679
  var valid_600680 = path.getOrDefault("DataSourceId")
  valid_600680 = validateParameter(valid_600680, JString, required = true,
                                 default = nil)
  if valid_600680 != nil:
    section.add "DataSourceId", valid_600680
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
  var valid_600681 = header.getOrDefault("X-Amz-Date")
  valid_600681 = validateParameter(valid_600681, JString, required = false,
                                 default = nil)
  if valid_600681 != nil:
    section.add "X-Amz-Date", valid_600681
  var valid_600682 = header.getOrDefault("X-Amz-Security-Token")
  valid_600682 = validateParameter(valid_600682, JString, required = false,
                                 default = nil)
  if valid_600682 != nil:
    section.add "X-Amz-Security-Token", valid_600682
  var valid_600683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600683 = validateParameter(valid_600683, JString, required = false,
                                 default = nil)
  if valid_600683 != nil:
    section.add "X-Amz-Content-Sha256", valid_600683
  var valid_600684 = header.getOrDefault("X-Amz-Algorithm")
  valid_600684 = validateParameter(valid_600684, JString, required = false,
                                 default = nil)
  if valid_600684 != nil:
    section.add "X-Amz-Algorithm", valid_600684
  var valid_600685 = header.getOrDefault("X-Amz-Signature")
  valid_600685 = validateParameter(valid_600685, JString, required = false,
                                 default = nil)
  if valid_600685 != nil:
    section.add "X-Amz-Signature", valid_600685
  var valid_600686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600686 = validateParameter(valid_600686, JString, required = false,
                                 default = nil)
  if valid_600686 != nil:
    section.add "X-Amz-SignedHeaders", valid_600686
  var valid_600687 = header.getOrDefault("X-Amz-Credential")
  valid_600687 = validateParameter(valid_600687, JString, required = false,
                                 default = nil)
  if valid_600687 != nil:
    section.add "X-Amz-Credential", valid_600687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600689: Call_UpdateDataSourcePermissions_600676; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the permissions to a data source.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:datasource/data-source-id</code> </p> <p>CLI syntax:</p> <p> <code>aws quicksight update-data-source-permissions \</code> </p> <p> <code>--aws-account-id=111122223333 \</code> </p> <p> <code>--data-source-id=unique-data-source-id \</code> </p> <p> <code>--name='My Data Source' \</code> </p> <p> <code>--grant-permissions='[{"Principal":"arn:aws:quicksight:us-east-1:111122223333:user/default/user1","Actions":["quicksight:DescribeDataSource","quicksight:DescribeDataSourcePermissions","quicksight:PassDataSource"]}]' \</code> </p> <p> <code>--revoke-permissions='[{"Principal":"arn:aws:quicksight:us-east-1:111122223333:user/default/user2","Actions":["quicksight:UpdateDataSource","quicksight:DeleteDataSource","quicksight:UpdateDataSourcePermissions"]}]'</code> </p>
  ## 
  let valid = call_600689.validator(path, query, header, formData, body)
  let scheme = call_600689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600689.url(scheme.get, call_600689.host, call_600689.base,
                         call_600689.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600689, url, valid)

proc call*(call_600690: Call_UpdateDataSourcePermissions_600676;
          AwsAccountId: string; DataSourceId: string; body: JsonNode): Recallable =
  ## updateDataSourcePermissions
  ## <p>Updates the permissions to a data source.</p> <p>The permissions resource is <code>arn:aws:quicksight:region:aws-account-id:datasource/data-source-id</code> </p> <p>CLI syntax:</p> <p> <code>aws quicksight update-data-source-permissions \</code> </p> <p> <code>--aws-account-id=111122223333 \</code> </p> <p> <code>--data-source-id=unique-data-source-id \</code> </p> <p> <code>--name='My Data Source' \</code> </p> <p> <code>--grant-permissions='[{"Principal":"arn:aws:quicksight:us-east-1:111122223333:user/default/user1","Actions":["quicksight:DescribeDataSource","quicksight:DescribeDataSourcePermissions","quicksight:PassDataSource"]}]' \</code> </p> <p> <code>--revoke-permissions='[{"Principal":"arn:aws:quicksight:us-east-1:111122223333:user/default/user2","Actions":["quicksight:UpdateDataSource","quicksight:DeleteDataSource","quicksight:UpdateDataSourcePermissions"]}]'</code> </p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This is unique per AWS Region per AWS account. 
  ##   body: JObject (required)
  var path_600691 = newJObject()
  var body_600692 = newJObject()
  add(path_600691, "AwsAccountId", newJString(AwsAccountId))
  add(path_600691, "DataSourceId", newJString(DataSourceId))
  if body != nil:
    body_600692 = body
  result = call_600690.call(path_600691, nil, nil, nil, body_600692)

var updateDataSourcePermissions* = Call_UpdateDataSourcePermissions_600676(
    name: "updateDataSourcePermissions", meth: HttpMethod.HttpPost,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}/permissions",
    validator: validate_UpdateDataSourcePermissions_600677, base: "/",
    url: url_UpdateDataSourcePermissions_600678,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDataSourcePermissions_600661 = ref object of OpenApiRestCall_599368
proc url_DescribeDataSourcePermissions_600663(protocol: Scheme; host: string;
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

proc validate_DescribeDataSourcePermissions_600662(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes the resource permissions for a data source.</p> <p>The permissions resource is <code>aws:quicksight:region:aws-account-id:datasource/data-source-id</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID.
  ##   DataSourceId: JString (required)
  ##               : The ID of the data source. This is unique per AWS Region per AWS account.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600664 = path.getOrDefault("AwsAccountId")
  valid_600664 = validateParameter(valid_600664, JString, required = true,
                                 default = nil)
  if valid_600664 != nil:
    section.add "AwsAccountId", valid_600664
  var valid_600665 = path.getOrDefault("DataSourceId")
  valid_600665 = validateParameter(valid_600665, JString, required = true,
                                 default = nil)
  if valid_600665 != nil:
    section.add "DataSourceId", valid_600665
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
  var valid_600666 = header.getOrDefault("X-Amz-Date")
  valid_600666 = validateParameter(valid_600666, JString, required = false,
                                 default = nil)
  if valid_600666 != nil:
    section.add "X-Amz-Date", valid_600666
  var valid_600667 = header.getOrDefault("X-Amz-Security-Token")
  valid_600667 = validateParameter(valid_600667, JString, required = false,
                                 default = nil)
  if valid_600667 != nil:
    section.add "X-Amz-Security-Token", valid_600667
  var valid_600668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600668 = validateParameter(valid_600668, JString, required = false,
                                 default = nil)
  if valid_600668 != nil:
    section.add "X-Amz-Content-Sha256", valid_600668
  var valid_600669 = header.getOrDefault("X-Amz-Algorithm")
  valid_600669 = validateParameter(valid_600669, JString, required = false,
                                 default = nil)
  if valid_600669 != nil:
    section.add "X-Amz-Algorithm", valid_600669
  var valid_600670 = header.getOrDefault("X-Amz-Signature")
  valid_600670 = validateParameter(valid_600670, JString, required = false,
                                 default = nil)
  if valid_600670 != nil:
    section.add "X-Amz-Signature", valid_600670
  var valid_600671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600671 = validateParameter(valid_600671, JString, required = false,
                                 default = nil)
  if valid_600671 != nil:
    section.add "X-Amz-SignedHeaders", valid_600671
  var valid_600672 = header.getOrDefault("X-Amz-Credential")
  valid_600672 = validateParameter(valid_600672, JString, required = false,
                                 default = nil)
  if valid_600672 != nil:
    section.add "X-Amz-Credential", valid_600672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600673: Call_DescribeDataSourcePermissions_600661; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes the resource permissions for a data source.</p> <p>The permissions resource is <code>aws:quicksight:region:aws-account-id:datasource/data-source-id</code> </p>
  ## 
  let valid = call_600673.validator(path, query, header, formData, body)
  let scheme = call_600673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600673.url(scheme.get, call_600673.host, call_600673.base,
                         call_600673.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600673, url, valid)

proc call*(call_600674: Call_DescribeDataSourcePermissions_600661;
          AwsAccountId: string; DataSourceId: string): Recallable =
  ## describeDataSourcePermissions
  ## <p>Describes the resource permissions for a data source.</p> <p>The permissions resource is <code>aws:quicksight:region:aws-account-id:datasource/data-source-id</code> </p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   DataSourceId: string (required)
  ##               : The ID of the data source. This is unique per AWS Region per AWS account.
  var path_600675 = newJObject()
  add(path_600675, "AwsAccountId", newJString(AwsAccountId))
  add(path_600675, "DataSourceId", newJString(DataSourceId))
  result = call_600674.call(path_600675, nil, nil, nil, nil)

var describeDataSourcePermissions* = Call_DescribeDataSourcePermissions_600661(
    name: "describeDataSourcePermissions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sources/{DataSourceId}/permissions",
    validator: validate_DescribeDataSourcePermissions_600662, base: "/",
    url: url_DescribeDataSourcePermissions_600663,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateIAMPolicyAssignment_600709 = ref object of OpenApiRestCall_599368
proc url_UpdateIAMPolicyAssignment_600711(protocol: Scheme; host: string;
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

proc validate_UpdateIAMPolicyAssignment_600710(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates an existing assignment. This operation updates only the optional parameter or parameters that are specified in the request.</p> <p>CLI syntax:</p> <p> <code/>aws quicksight update-iam-policy-assignment --aws-account-id=111122223333 --assignment-name=FullAccessAssignment --assignment-status=DRAFT --policy-arns=arn:aws:iam::aws:policy/AdministratorAccess --identities="user=user-1,user-2,group=admin" --namespace=default --region=us-east-1</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AssignmentName: JString (required)
  ##                 : The name of the assignment. It must be unique within an AWS account.
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID that contains the IAM policy assignment.
  ##   Namespace: JString (required)
  ##            : The namespace of the assignment.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AssignmentName` field"
  var valid_600712 = path.getOrDefault("AssignmentName")
  valid_600712 = validateParameter(valid_600712, JString, required = true,
                                 default = nil)
  if valid_600712 != nil:
    section.add "AssignmentName", valid_600712
  var valid_600713 = path.getOrDefault("AwsAccountId")
  valid_600713 = validateParameter(valid_600713, JString, required = true,
                                 default = nil)
  if valid_600713 != nil:
    section.add "AwsAccountId", valid_600713
  var valid_600714 = path.getOrDefault("Namespace")
  valid_600714 = validateParameter(valid_600714, JString, required = true,
                                 default = nil)
  if valid_600714 != nil:
    section.add "Namespace", valid_600714
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
  var valid_600715 = header.getOrDefault("X-Amz-Date")
  valid_600715 = validateParameter(valid_600715, JString, required = false,
                                 default = nil)
  if valid_600715 != nil:
    section.add "X-Amz-Date", valid_600715
  var valid_600716 = header.getOrDefault("X-Amz-Security-Token")
  valid_600716 = validateParameter(valid_600716, JString, required = false,
                                 default = nil)
  if valid_600716 != nil:
    section.add "X-Amz-Security-Token", valid_600716
  var valid_600717 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600717 = validateParameter(valid_600717, JString, required = false,
                                 default = nil)
  if valid_600717 != nil:
    section.add "X-Amz-Content-Sha256", valid_600717
  var valid_600718 = header.getOrDefault("X-Amz-Algorithm")
  valid_600718 = validateParameter(valid_600718, JString, required = false,
                                 default = nil)
  if valid_600718 != nil:
    section.add "X-Amz-Algorithm", valid_600718
  var valid_600719 = header.getOrDefault("X-Amz-Signature")
  valid_600719 = validateParameter(valid_600719, JString, required = false,
                                 default = nil)
  if valid_600719 != nil:
    section.add "X-Amz-Signature", valid_600719
  var valid_600720 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600720 = validateParameter(valid_600720, JString, required = false,
                                 default = nil)
  if valid_600720 != nil:
    section.add "X-Amz-SignedHeaders", valid_600720
  var valid_600721 = header.getOrDefault("X-Amz-Credential")
  valid_600721 = validateParameter(valid_600721, JString, required = false,
                                 default = nil)
  if valid_600721 != nil:
    section.add "X-Amz-Credential", valid_600721
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600723: Call_UpdateIAMPolicyAssignment_600709; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an existing assignment. This operation updates only the optional parameter or parameters that are specified in the request.</p> <p>CLI syntax:</p> <p> <code/>aws quicksight update-iam-policy-assignment --aws-account-id=111122223333 --assignment-name=FullAccessAssignment --assignment-status=DRAFT --policy-arns=arn:aws:iam::aws:policy/AdministratorAccess --identities="user=user-1,user-2,group=admin" --namespace=default --region=us-east-1</p>
  ## 
  let valid = call_600723.validator(path, query, header, formData, body)
  let scheme = call_600723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600723.url(scheme.get, call_600723.host, call_600723.base,
                         call_600723.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600723, url, valid)

proc call*(call_600724: Call_UpdateIAMPolicyAssignment_600709;
          AssignmentName: string; AwsAccountId: string; body: JsonNode;
          Namespace: string): Recallable =
  ## updateIAMPolicyAssignment
  ## <p>Updates an existing assignment. This operation updates only the optional parameter or parameters that are specified in the request.</p> <p>CLI syntax:</p> <p> <code/>aws quicksight update-iam-policy-assignment --aws-account-id=111122223333 --assignment-name=FullAccessAssignment --assignment-status=DRAFT --policy-arns=arn:aws:iam::aws:policy/AdministratorAccess --identities="user=user-1,user-2,group=admin" --namespace=default --region=us-east-1</p>
  ##   AssignmentName: string (required)
  ##                 : The name of the assignment. It must be unique within an AWS account.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID that contains the IAM policy assignment.
  ##   body: JObject (required)
  ##   Namespace: string (required)
  ##            : The namespace of the assignment.
  var path_600725 = newJObject()
  var body_600726 = newJObject()
  add(path_600725, "AssignmentName", newJString(AssignmentName))
  add(path_600725, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_600726 = body
  add(path_600725, "Namespace", newJString(Namespace))
  result = call_600724.call(path_600725, nil, nil, nil, body_600726)

var updateIAMPolicyAssignment* = Call_UpdateIAMPolicyAssignment_600709(
    name: "updateIAMPolicyAssignment", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/{AssignmentName}",
    validator: validate_UpdateIAMPolicyAssignment_600710, base: "/",
    url: url_UpdateIAMPolicyAssignment_600711,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeIAMPolicyAssignment_600693 = ref object of OpenApiRestCall_599368
proc url_DescribeIAMPolicyAssignment_600695(protocol: Scheme; host: string;
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

proc validate_DescribeIAMPolicyAssignment_600694(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes an existing IAMPolicy Assignment by specified assignment name.</p> <p>CLI syntax:</p> <p> <code>aws quicksight describe-iam-policy-assignment --aws-account-id=111122223333 --assignment-name=testtest --namespace=default --region=us-east-1 </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AssignmentName: JString (required)
  ##                 : The name of the assignment. 
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID that contains the assignment you want to describe.
  ##   Namespace: JString (required)
  ##            : The namespace that contains the assignment.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AssignmentName` field"
  var valid_600696 = path.getOrDefault("AssignmentName")
  valid_600696 = validateParameter(valid_600696, JString, required = true,
                                 default = nil)
  if valid_600696 != nil:
    section.add "AssignmentName", valid_600696
  var valid_600697 = path.getOrDefault("AwsAccountId")
  valid_600697 = validateParameter(valid_600697, JString, required = true,
                                 default = nil)
  if valid_600697 != nil:
    section.add "AwsAccountId", valid_600697
  var valid_600698 = path.getOrDefault("Namespace")
  valid_600698 = validateParameter(valid_600698, JString, required = true,
                                 default = nil)
  if valid_600698 != nil:
    section.add "Namespace", valid_600698
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
  var valid_600699 = header.getOrDefault("X-Amz-Date")
  valid_600699 = validateParameter(valid_600699, JString, required = false,
                                 default = nil)
  if valid_600699 != nil:
    section.add "X-Amz-Date", valid_600699
  var valid_600700 = header.getOrDefault("X-Amz-Security-Token")
  valid_600700 = validateParameter(valid_600700, JString, required = false,
                                 default = nil)
  if valid_600700 != nil:
    section.add "X-Amz-Security-Token", valid_600700
  var valid_600701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600701 = validateParameter(valid_600701, JString, required = false,
                                 default = nil)
  if valid_600701 != nil:
    section.add "X-Amz-Content-Sha256", valid_600701
  var valid_600702 = header.getOrDefault("X-Amz-Algorithm")
  valid_600702 = validateParameter(valid_600702, JString, required = false,
                                 default = nil)
  if valid_600702 != nil:
    section.add "X-Amz-Algorithm", valid_600702
  var valid_600703 = header.getOrDefault("X-Amz-Signature")
  valid_600703 = validateParameter(valid_600703, JString, required = false,
                                 default = nil)
  if valid_600703 != nil:
    section.add "X-Amz-Signature", valid_600703
  var valid_600704 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600704 = validateParameter(valid_600704, JString, required = false,
                                 default = nil)
  if valid_600704 != nil:
    section.add "X-Amz-SignedHeaders", valid_600704
  var valid_600705 = header.getOrDefault("X-Amz-Credential")
  valid_600705 = validateParameter(valid_600705, JString, required = false,
                                 default = nil)
  if valid_600705 != nil:
    section.add "X-Amz-Credential", valid_600705
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600706: Call_DescribeIAMPolicyAssignment_600693; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes an existing IAMPolicy Assignment by specified assignment name.</p> <p>CLI syntax:</p> <p> <code>aws quicksight describe-iam-policy-assignment --aws-account-id=111122223333 --assignment-name=testtest --namespace=default --region=us-east-1 </code> </p>
  ## 
  let valid = call_600706.validator(path, query, header, formData, body)
  let scheme = call_600706.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600706.url(scheme.get, call_600706.host, call_600706.base,
                         call_600706.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600706, url, valid)

proc call*(call_600707: Call_DescribeIAMPolicyAssignment_600693;
          AssignmentName: string; AwsAccountId: string; Namespace: string): Recallable =
  ## describeIAMPolicyAssignment
  ## <p>Describes an existing IAMPolicy Assignment by specified assignment name.</p> <p>CLI syntax:</p> <p> <code>aws quicksight describe-iam-policy-assignment --aws-account-id=111122223333 --assignment-name=testtest --namespace=default --region=us-east-1 </code> </p>
  ##   AssignmentName: string (required)
  ##                 : The name of the assignment. 
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID that contains the assignment you want to describe.
  ##   Namespace: string (required)
  ##            : The namespace that contains the assignment.
  var path_600708 = newJObject()
  add(path_600708, "AssignmentName", newJString(AssignmentName))
  add(path_600708, "AwsAccountId", newJString(AwsAccountId))
  add(path_600708, "Namespace", newJString(Namespace))
  result = call_600707.call(path_600708, nil, nil, nil, nil)

var describeIAMPolicyAssignment* = Call_DescribeIAMPolicyAssignment_600693(
    name: "describeIAMPolicyAssignment", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments/{AssignmentName}",
    validator: validate_DescribeIAMPolicyAssignment_600694, base: "/",
    url: url_DescribeIAMPolicyAssignment_600695,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateTemplatePermissions_600742 = ref object of OpenApiRestCall_599368
proc url_UpdateTemplatePermissions_600744(protocol: Scheme; host: string;
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

proc validate_UpdateTemplatePermissions_600743(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the permissions on a template.</p> <p>CLI syntax:</p> <ul> <li> <p> <code>aws quicksight describe-template-permissions —aws-account-id 111122223333 —template-id reports_test_template</code> </p> </li> <li> <p> <code>aws quicksight update-template-permissions —cli-input-json file://update-permission.json </code> </p> </li> <li> <p>The structure of <code>update-permissions.json</code> to add permissions:</p> <p> <code>{ "AwsAccountId": "111122223333",</code> </p> <p> <code> "DashboardId": "reports_test_template",</code> </p> <p> <code> "GrantPermissions": [</code> </p> <p> <code> { "Principal": "arn:aws:quicksight:us-east-1:196359894473:user/default/user3",</code> </p> <p> <code> "Actions": [</code> </p> <p> <code> "quicksight:DescribeTemplate",</code> </p> <p> <code> "quicksight:ListTemplateVersions"</code> </p> <p> <code> ] } ] }</code> </p> <p>The structure of <code>update-permissions.json</code> to add permissions:</p> <p> <code>{ "AwsAccountId": "111122223333",</code> </p> <p> <code> "DashboardId": "reports_test_template",</code> </p> <p> <code> "RevokePermissions": [</code> </p> <p> <code> { "Principal": "arn:aws:quicksight:us-east-1:196359894473:user/default/user3",</code> </p> <p> <code> "Actions": [</code> </p> <p> <code> "quicksight:DescribeTemplate",</code> </p> <p> <code> "quicksight:ListTemplateVersions"</code> </p> <p> <code> ] } ] }</code> </p> <p>To obtain the principal name of a QuickSight group or user, use user describe-group or describe-user. For example:</p> <p> <code>aws quicksight describe-user </code> </p> <p> <code>--aws-account-id 111122223333</code> </p> <p> <code>--namespace default</code> </p> <p> <code>--user-name user2 </code> </p> <p> <code>--region us-east-1</code> </p> <p> <code>{</code> </p> <p> <code> "User": {</code> </p> <p> <code> "Arn": "arn:aws:quicksight:us-east-1:111122223333:user/default/user2",</code> </p> <p> <code> "Active": true,</code> </p> <p> <code> "Email": "user2@example.com",</code> </p> <p> <code> "Role": "ADMIN",</code> </p> <p> <code> "UserName": "user2",</code> </p> <p> <code> "PrincipalId": "federated/iam/abcd2abcdabcdeabc5ab5"</code> </p> <p> <code> },</code> </p> <p> <code> "RequestId": "8f74bb31-6291-448a-a71c-a765a44bae31",</code> </p> <p> <code> "Status": 200</code> </p> <p> <code>}</code> </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : AWS account ID that contains the template.
  ##   TemplateId: JString (required)
  ##             : The ID for the template.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600745 = path.getOrDefault("AwsAccountId")
  valid_600745 = validateParameter(valid_600745, JString, required = true,
                                 default = nil)
  if valid_600745 != nil:
    section.add "AwsAccountId", valid_600745
  var valid_600746 = path.getOrDefault("TemplateId")
  valid_600746 = validateParameter(valid_600746, JString, required = true,
                                 default = nil)
  if valid_600746 != nil:
    section.add "TemplateId", valid_600746
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
  var valid_600747 = header.getOrDefault("X-Amz-Date")
  valid_600747 = validateParameter(valid_600747, JString, required = false,
                                 default = nil)
  if valid_600747 != nil:
    section.add "X-Amz-Date", valid_600747
  var valid_600748 = header.getOrDefault("X-Amz-Security-Token")
  valid_600748 = validateParameter(valid_600748, JString, required = false,
                                 default = nil)
  if valid_600748 != nil:
    section.add "X-Amz-Security-Token", valid_600748
  var valid_600749 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600749 = validateParameter(valid_600749, JString, required = false,
                                 default = nil)
  if valid_600749 != nil:
    section.add "X-Amz-Content-Sha256", valid_600749
  var valid_600750 = header.getOrDefault("X-Amz-Algorithm")
  valid_600750 = validateParameter(valid_600750, JString, required = false,
                                 default = nil)
  if valid_600750 != nil:
    section.add "X-Amz-Algorithm", valid_600750
  var valid_600751 = header.getOrDefault("X-Amz-Signature")
  valid_600751 = validateParameter(valid_600751, JString, required = false,
                                 default = nil)
  if valid_600751 != nil:
    section.add "X-Amz-Signature", valid_600751
  var valid_600752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600752 = validateParameter(valid_600752, JString, required = false,
                                 default = nil)
  if valid_600752 != nil:
    section.add "X-Amz-SignedHeaders", valid_600752
  var valid_600753 = header.getOrDefault("X-Amz-Credential")
  valid_600753 = validateParameter(valid_600753, JString, required = false,
                                 default = nil)
  if valid_600753 != nil:
    section.add "X-Amz-Credential", valid_600753
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600755: Call_UpdateTemplatePermissions_600742; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the permissions on a template.</p> <p>CLI syntax:</p> <ul> <li> <p> <code>aws quicksight describe-template-permissions —aws-account-id 111122223333 —template-id reports_test_template</code> </p> </li> <li> <p> <code>aws quicksight update-template-permissions —cli-input-json file://update-permission.json </code> </p> </li> <li> <p>The structure of <code>update-permissions.json</code> to add permissions:</p> <p> <code>{ "AwsAccountId": "111122223333",</code> </p> <p> <code> "DashboardId": "reports_test_template",</code> </p> <p> <code> "GrantPermissions": [</code> </p> <p> <code> { "Principal": "arn:aws:quicksight:us-east-1:196359894473:user/default/user3",</code> </p> <p> <code> "Actions": [</code> </p> <p> <code> "quicksight:DescribeTemplate",</code> </p> <p> <code> "quicksight:ListTemplateVersions"</code> </p> <p> <code> ] } ] }</code> </p> <p>The structure of <code>update-permissions.json</code> to add permissions:</p> <p> <code>{ "AwsAccountId": "111122223333",</code> </p> <p> <code> "DashboardId": "reports_test_template",</code> </p> <p> <code> "RevokePermissions": [</code> </p> <p> <code> { "Principal": "arn:aws:quicksight:us-east-1:196359894473:user/default/user3",</code> </p> <p> <code> "Actions": [</code> </p> <p> <code> "quicksight:DescribeTemplate",</code> </p> <p> <code> "quicksight:ListTemplateVersions"</code> </p> <p> <code> ] } ] }</code> </p> <p>To obtain the principal name of a QuickSight group or user, use user describe-group or describe-user. For example:</p> <p> <code>aws quicksight describe-user </code> </p> <p> <code>--aws-account-id 111122223333</code> </p> <p> <code>--namespace default</code> </p> <p> <code>--user-name user2 </code> </p> <p> <code>--region us-east-1</code> </p> <p> <code>{</code> </p> <p> <code> "User": {</code> </p> <p> <code> "Arn": "arn:aws:quicksight:us-east-1:111122223333:user/default/user2",</code> </p> <p> <code> "Active": true,</code> </p> <p> <code> "Email": "user2@example.com",</code> </p> <p> <code> "Role": "ADMIN",</code> </p> <p> <code> "UserName": "user2",</code> </p> <p> <code> "PrincipalId": "federated/iam/abcd2abcdabcdeabc5ab5"</code> </p> <p> <code> },</code> </p> <p> <code> "RequestId": "8f74bb31-6291-448a-a71c-a765a44bae31",</code> </p> <p> <code> "Status": 200</code> </p> <p> <code>}</code> </p> </li> </ul>
  ## 
  let valid = call_600755.validator(path, query, header, formData, body)
  let scheme = call_600755.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600755.url(scheme.get, call_600755.host, call_600755.base,
                         call_600755.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600755, url, valid)

proc call*(call_600756: Call_UpdateTemplatePermissions_600742;
          AwsAccountId: string; TemplateId: string; body: JsonNode): Recallable =
  ## updateTemplatePermissions
  ## <p>Updates the permissions on a template.</p> <p>CLI syntax:</p> <ul> <li> <p> <code>aws quicksight describe-template-permissions —aws-account-id 111122223333 —template-id reports_test_template</code> </p> </li> <li> <p> <code>aws quicksight update-template-permissions —cli-input-json file://update-permission.json </code> </p> </li> <li> <p>The structure of <code>update-permissions.json</code> to add permissions:</p> <p> <code>{ "AwsAccountId": "111122223333",</code> </p> <p> <code> "DashboardId": "reports_test_template",</code> </p> <p> <code> "GrantPermissions": [</code> </p> <p> <code> { "Principal": "arn:aws:quicksight:us-east-1:196359894473:user/default/user3",</code> </p> <p> <code> "Actions": [</code> </p> <p> <code> "quicksight:DescribeTemplate",</code> </p> <p> <code> "quicksight:ListTemplateVersions"</code> </p> <p> <code> ] } ] }</code> </p> <p>The structure of <code>update-permissions.json</code> to add permissions:</p> <p> <code>{ "AwsAccountId": "111122223333",</code> </p> <p> <code> "DashboardId": "reports_test_template",</code> </p> <p> <code> "RevokePermissions": [</code> </p> <p> <code> { "Principal": "arn:aws:quicksight:us-east-1:196359894473:user/default/user3",</code> </p> <p> <code> "Actions": [</code> </p> <p> <code> "quicksight:DescribeTemplate",</code> </p> <p> <code> "quicksight:ListTemplateVersions"</code> </p> <p> <code> ] } ] }</code> </p> <p>To obtain the principal name of a QuickSight group or user, use user describe-group or describe-user. For example:</p> <p> <code>aws quicksight describe-user </code> </p> <p> <code>--aws-account-id 111122223333</code> </p> <p> <code>--namespace default</code> </p> <p> <code>--user-name user2 </code> </p> <p> <code>--region us-east-1</code> </p> <p> <code>{</code> </p> <p> <code> "User": {</code> </p> <p> <code> "Arn": "arn:aws:quicksight:us-east-1:111122223333:user/default/user2",</code> </p> <p> <code> "Active": true,</code> </p> <p> <code> "Email": "user2@example.com",</code> </p> <p> <code> "Role": "ADMIN",</code> </p> <p> <code> "UserName": "user2",</code> </p> <p> <code> "PrincipalId": "federated/iam/abcd2abcdabcdeabc5ab5"</code> </p> <p> <code> },</code> </p> <p> <code> "RequestId": "8f74bb31-6291-448a-a71c-a765a44bae31",</code> </p> <p> <code> "Status": 200</code> </p> <p> <code>}</code> </p> </li> </ul>
  ##   AwsAccountId: string (required)
  ##               : AWS account ID that contains the template.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  ##   body: JObject (required)
  var path_600757 = newJObject()
  var body_600758 = newJObject()
  add(path_600757, "AwsAccountId", newJString(AwsAccountId))
  add(path_600757, "TemplateId", newJString(TemplateId))
  if body != nil:
    body_600758 = body
  result = call_600756.call(path_600757, nil, nil, nil, body_600758)

var updateTemplatePermissions* = Call_UpdateTemplatePermissions_600742(
    name: "updateTemplatePermissions", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}/permissions",
    validator: validate_UpdateTemplatePermissions_600743, base: "/",
    url: url_UpdateTemplatePermissions_600744,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeTemplatePermissions_600727 = ref object of OpenApiRestCall_599368
proc url_DescribeTemplatePermissions_600729(protocol: Scheme; host: string;
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

proc validate_DescribeTemplatePermissions_600728(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Describes read and write permissions on a template.</p> <p>CLI syntax:</p> <p> <code>aws quicksight describe-template-permissions —aws-account-id 735340738645 —template-id reports_test_template</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : AWS account ID that contains the template you are describing.
  ##   TemplateId: JString (required)
  ##             : The ID for the template.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600730 = path.getOrDefault("AwsAccountId")
  valid_600730 = validateParameter(valid_600730, JString, required = true,
                                 default = nil)
  if valid_600730 != nil:
    section.add "AwsAccountId", valid_600730
  var valid_600731 = path.getOrDefault("TemplateId")
  valid_600731 = validateParameter(valid_600731, JString, required = true,
                                 default = nil)
  if valid_600731 != nil:
    section.add "TemplateId", valid_600731
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
  var valid_600732 = header.getOrDefault("X-Amz-Date")
  valid_600732 = validateParameter(valid_600732, JString, required = false,
                                 default = nil)
  if valid_600732 != nil:
    section.add "X-Amz-Date", valid_600732
  var valid_600733 = header.getOrDefault("X-Amz-Security-Token")
  valid_600733 = validateParameter(valid_600733, JString, required = false,
                                 default = nil)
  if valid_600733 != nil:
    section.add "X-Amz-Security-Token", valid_600733
  var valid_600734 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600734 = validateParameter(valid_600734, JString, required = false,
                                 default = nil)
  if valid_600734 != nil:
    section.add "X-Amz-Content-Sha256", valid_600734
  var valid_600735 = header.getOrDefault("X-Amz-Algorithm")
  valid_600735 = validateParameter(valid_600735, JString, required = false,
                                 default = nil)
  if valid_600735 != nil:
    section.add "X-Amz-Algorithm", valid_600735
  var valid_600736 = header.getOrDefault("X-Amz-Signature")
  valid_600736 = validateParameter(valid_600736, JString, required = false,
                                 default = nil)
  if valid_600736 != nil:
    section.add "X-Amz-Signature", valid_600736
  var valid_600737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600737 = validateParameter(valid_600737, JString, required = false,
                                 default = nil)
  if valid_600737 != nil:
    section.add "X-Amz-SignedHeaders", valid_600737
  var valid_600738 = header.getOrDefault("X-Amz-Credential")
  valid_600738 = validateParameter(valid_600738, JString, required = false,
                                 default = nil)
  if valid_600738 != nil:
    section.add "X-Amz-Credential", valid_600738
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600739: Call_DescribeTemplatePermissions_600727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Describes read and write permissions on a template.</p> <p>CLI syntax:</p> <p> <code>aws quicksight describe-template-permissions —aws-account-id 735340738645 —template-id reports_test_template</code> </p>
  ## 
  let valid = call_600739.validator(path, query, header, formData, body)
  let scheme = call_600739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600739.url(scheme.get, call_600739.host, call_600739.base,
                         call_600739.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600739, url, valid)

proc call*(call_600740: Call_DescribeTemplatePermissions_600727;
          AwsAccountId: string; TemplateId: string): Recallable =
  ## describeTemplatePermissions
  ## <p>Describes read and write permissions on a template.</p> <p>CLI syntax:</p> <p> <code>aws quicksight describe-template-permissions —aws-account-id 735340738645 —template-id reports_test_template</code> </p>
  ##   AwsAccountId: string (required)
  ##               : AWS account ID that contains the template you are describing.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  var path_600741 = newJObject()
  add(path_600741, "AwsAccountId", newJString(AwsAccountId))
  add(path_600741, "TemplateId", newJString(TemplateId))
  result = call_600740.call(path_600741, nil, nil, nil, nil)

var describeTemplatePermissions* = Call_DescribeTemplatePermissions_600727(
    name: "describeTemplatePermissions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}/permissions",
    validator: validate_DescribeTemplatePermissions_600728, base: "/",
    url: url_DescribeTemplatePermissions_600729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDashboardEmbedUrl_600759 = ref object of OpenApiRestCall_599368
proc url_GetDashboardEmbedUrl_600761(protocol: Scheme; host: string; base: string;
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

proc validate_GetDashboardEmbedUrl_600760(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Generates a server-side embeddable URL and authorization code. Before this can work properly, first you need to configure the dashboards and user permissions. For more information, see <a href="https://docs.aws.example.com/en_us/quicksight/latest/user/embedding.html"> Embedding Amazon QuickSight Dashboards</a>.</p> <p>Currently, you can use <code>GetDashboardEmbedURL</code> only from the server, not from the user’s browser.</p> <p> <b>CLI Sample:</b> </p> <p>Assume the role with permissions enabled for actions: <code>quickSight:RegisterUser</code> and <code>quicksight:GetDashboardEmbedURL</code>. You can use assume-role, assume-role-with-web-identity, or assume-role-with-saml. </p> <p> <code>aws sts assume-role --role-arn "arn:aws:iam::111122223333:role/embedding_quicksight_dashboard_role" --role-session-name embeddingsession</code> </p> <p>If the user does not exist in QuickSight, register the user:</p> <p> <code>aws quicksight register-user --aws-account-id 111122223333 --namespace default --identity-type IAM --iam-arn "arn:aws:iam::111122223333:role/embedding_quicksight_dashboard_role" --user-role READER --session-name "embeddingsession" --email user123@example.com --region us-east-1</code> </p> <p>Get the URL for the embedded dashboard (<code>IAM</code> identity authentication):</p> <p> <code>aws quicksight get-dashboard-embed-url --aws-account-id 111122223333 --dashboard-id 1a1ac2b2-3fc3-4b44-5e5d-c6db6778df89 --identity-type IAM</code> </p> <p>Get the URL for the embedded dashboard (<code>QUICKSIGHT</code> identity authentication):</p> <p> <code>aws quicksight get-dashboard-embed-url --aws-account-id 111122223333 --dashboard-id 1a1ac2b2-3fc3-4b44-5e5d-c6db6778df89 --identity-type QUICKSIGHT --user-arn arn:aws:quicksight:us-east-1:111122223333:user/default/embedding_quicksight_dashboard_role/embeddingsession</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : AWS account ID that contains the dashboard you are embedding.
  ##   DashboardId: JString (required)
  ##              : The ID for the dashboard, also added to IAM policy
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600762 = path.getOrDefault("AwsAccountId")
  valid_600762 = validateParameter(valid_600762, JString, required = true,
                                 default = nil)
  if valid_600762 != nil:
    section.add "AwsAccountId", valid_600762
  var valid_600763 = path.getOrDefault("DashboardId")
  valid_600763 = validateParameter(valid_600763, JString, required = true,
                                 default = nil)
  if valid_600763 != nil:
    section.add "DashboardId", valid_600763
  result.add "path", section
  ## parameters in `query` object:
  ##   session-lifetime: JInt
  ##                   : How many minutes the session is valid. The session lifetime must be between 15 and 600 minutes.
  ##   reset-disabled: JBool
  ##                 : Remove the reset button on embedded dashboard. The default is FALSE, which allows the reset button.
  ##   user-arn: JString
  ##           : <p>The Amazon QuickSight user's ARN, for use with <code>QUICKSIGHT</code> identity type. You can use this for any Amazon QuickSight users in your account (readers, authors, or admins) authenticated as one of the following:</p> <ul> <li> <p>Active Directory (AD) users or group members</p> </li> <li> <p>Invited non-federated users</p> </li> <li> <p>IAM users and IAM role-based sessions authenticated through Federated Single Sign-On using SAML, OpenID Connect, or IAM Federation</p> </li> </ul>
  ##   undo-redo-disabled: JBool
  ##                     : Remove the undo/redo button on embedded dashboard. The default is FALSE, which enables the undo/redo button.
  ##   creds-type: JString (required)
  ##             : The authentication method the user uses to sign in (IAM only).
  section = newJObject()
  var valid_600764 = query.getOrDefault("session-lifetime")
  valid_600764 = validateParameter(valid_600764, JInt, required = false, default = nil)
  if valid_600764 != nil:
    section.add "session-lifetime", valid_600764
  var valid_600765 = query.getOrDefault("reset-disabled")
  valid_600765 = validateParameter(valid_600765, JBool, required = false, default = nil)
  if valid_600765 != nil:
    section.add "reset-disabled", valid_600765
  var valid_600766 = query.getOrDefault("user-arn")
  valid_600766 = validateParameter(valid_600766, JString, required = false,
                                 default = nil)
  if valid_600766 != nil:
    section.add "user-arn", valid_600766
  var valid_600767 = query.getOrDefault("undo-redo-disabled")
  valid_600767 = validateParameter(valid_600767, JBool, required = false, default = nil)
  if valid_600767 != nil:
    section.add "undo-redo-disabled", valid_600767
  assert query != nil,
        "query argument is necessary due to required `creds-type` field"
  var valid_600781 = query.getOrDefault("creds-type")
  valid_600781 = validateParameter(valid_600781, JString, required = true,
                                 default = newJString("IAM"))
  if valid_600781 != nil:
    section.add "creds-type", valid_600781
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
  var valid_600782 = header.getOrDefault("X-Amz-Date")
  valid_600782 = validateParameter(valid_600782, JString, required = false,
                                 default = nil)
  if valid_600782 != nil:
    section.add "X-Amz-Date", valid_600782
  var valid_600783 = header.getOrDefault("X-Amz-Security-Token")
  valid_600783 = validateParameter(valid_600783, JString, required = false,
                                 default = nil)
  if valid_600783 != nil:
    section.add "X-Amz-Security-Token", valid_600783
  var valid_600784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600784 = validateParameter(valid_600784, JString, required = false,
                                 default = nil)
  if valid_600784 != nil:
    section.add "X-Amz-Content-Sha256", valid_600784
  var valid_600785 = header.getOrDefault("X-Amz-Algorithm")
  valid_600785 = validateParameter(valid_600785, JString, required = false,
                                 default = nil)
  if valid_600785 != nil:
    section.add "X-Amz-Algorithm", valid_600785
  var valid_600786 = header.getOrDefault("X-Amz-Signature")
  valid_600786 = validateParameter(valid_600786, JString, required = false,
                                 default = nil)
  if valid_600786 != nil:
    section.add "X-Amz-Signature", valid_600786
  var valid_600787 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600787 = validateParameter(valid_600787, JString, required = false,
                                 default = nil)
  if valid_600787 != nil:
    section.add "X-Amz-SignedHeaders", valid_600787
  var valid_600788 = header.getOrDefault("X-Amz-Credential")
  valid_600788 = validateParameter(valid_600788, JString, required = false,
                                 default = nil)
  if valid_600788 != nil:
    section.add "X-Amz-Credential", valid_600788
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600789: Call_GetDashboardEmbedUrl_600759; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Generates a server-side embeddable URL and authorization code. Before this can work properly, first you need to configure the dashboards and user permissions. For more information, see <a href="https://docs.aws.example.com/en_us/quicksight/latest/user/embedding.html"> Embedding Amazon QuickSight Dashboards</a>.</p> <p>Currently, you can use <code>GetDashboardEmbedURL</code> only from the server, not from the user’s browser.</p> <p> <b>CLI Sample:</b> </p> <p>Assume the role with permissions enabled for actions: <code>quickSight:RegisterUser</code> and <code>quicksight:GetDashboardEmbedURL</code>. You can use assume-role, assume-role-with-web-identity, or assume-role-with-saml. </p> <p> <code>aws sts assume-role --role-arn "arn:aws:iam::111122223333:role/embedding_quicksight_dashboard_role" --role-session-name embeddingsession</code> </p> <p>If the user does not exist in QuickSight, register the user:</p> <p> <code>aws quicksight register-user --aws-account-id 111122223333 --namespace default --identity-type IAM --iam-arn "arn:aws:iam::111122223333:role/embedding_quicksight_dashboard_role" --user-role READER --session-name "embeddingsession" --email user123@example.com --region us-east-1</code> </p> <p>Get the URL for the embedded dashboard (<code>IAM</code> identity authentication):</p> <p> <code>aws quicksight get-dashboard-embed-url --aws-account-id 111122223333 --dashboard-id 1a1ac2b2-3fc3-4b44-5e5d-c6db6778df89 --identity-type IAM</code> </p> <p>Get the URL for the embedded dashboard (<code>QUICKSIGHT</code> identity authentication):</p> <p> <code>aws quicksight get-dashboard-embed-url --aws-account-id 111122223333 --dashboard-id 1a1ac2b2-3fc3-4b44-5e5d-c6db6778df89 --identity-type QUICKSIGHT --user-arn arn:aws:quicksight:us-east-1:111122223333:user/default/embedding_quicksight_dashboard_role/embeddingsession</code> </p>
  ## 
  let valid = call_600789.validator(path, query, header, formData, body)
  let scheme = call_600789.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600789.url(scheme.get, call_600789.host, call_600789.base,
                         call_600789.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600789, url, valid)

proc call*(call_600790: Call_GetDashboardEmbedUrl_600759; AwsAccountId: string;
          DashboardId: string; sessionLifetime: int = 0; resetDisabled: bool = false;
          userArn: string = ""; undoRedoDisabled: bool = false;
          credsType: string = "IAM"): Recallable =
  ## getDashboardEmbedUrl
  ## <p>Generates a server-side embeddable URL and authorization code. Before this can work properly, first you need to configure the dashboards and user permissions. For more information, see <a href="https://docs.aws.example.com/en_us/quicksight/latest/user/embedding.html"> Embedding Amazon QuickSight Dashboards</a>.</p> <p>Currently, you can use <code>GetDashboardEmbedURL</code> only from the server, not from the user’s browser.</p> <p> <b>CLI Sample:</b> </p> <p>Assume the role with permissions enabled for actions: <code>quickSight:RegisterUser</code> and <code>quicksight:GetDashboardEmbedURL</code>. You can use assume-role, assume-role-with-web-identity, or assume-role-with-saml. </p> <p> <code>aws sts assume-role --role-arn "arn:aws:iam::111122223333:role/embedding_quicksight_dashboard_role" --role-session-name embeddingsession</code> </p> <p>If the user does not exist in QuickSight, register the user:</p> <p> <code>aws quicksight register-user --aws-account-id 111122223333 --namespace default --identity-type IAM --iam-arn "arn:aws:iam::111122223333:role/embedding_quicksight_dashboard_role" --user-role READER --session-name "embeddingsession" --email user123@example.com --region us-east-1</code> </p> <p>Get the URL for the embedded dashboard (<code>IAM</code> identity authentication):</p> <p> <code>aws quicksight get-dashboard-embed-url --aws-account-id 111122223333 --dashboard-id 1a1ac2b2-3fc3-4b44-5e5d-c6db6778df89 --identity-type IAM</code> </p> <p>Get the URL for the embedded dashboard (<code>QUICKSIGHT</code> identity authentication):</p> <p> <code>aws quicksight get-dashboard-embed-url --aws-account-id 111122223333 --dashboard-id 1a1ac2b2-3fc3-4b44-5e5d-c6db6778df89 --identity-type QUICKSIGHT --user-arn arn:aws:quicksight:us-east-1:111122223333:user/default/embedding_quicksight_dashboard_role/embeddingsession</code> </p>
  ##   AwsAccountId: string (required)
  ##               : AWS account ID that contains the dashboard you are embedding.
  ##   sessionLifetime: int
  ##                  : How many minutes the session is valid. The session lifetime must be between 15 and 600 minutes.
  ##   resetDisabled: bool
  ##                : Remove the reset button on embedded dashboard. The default is FALSE, which allows the reset button.
  ##   userArn: string
  ##          : <p>The Amazon QuickSight user's ARN, for use with <code>QUICKSIGHT</code> identity type. You can use this for any Amazon QuickSight users in your account (readers, authors, or admins) authenticated as one of the following:</p> <ul> <li> <p>Active Directory (AD) users or group members</p> </li> <li> <p>Invited non-federated users</p> </li> <li> <p>IAM users and IAM role-based sessions authenticated through Federated Single Sign-On using SAML, OpenID Connect, or IAM Federation</p> </li> </ul>
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard, also added to IAM policy
  ##   undoRedoDisabled: bool
  ##                   : Remove the undo/redo button on embedded dashboard. The default is FALSE, which enables the undo/redo button.
  ##   credsType: string (required)
  ##            : The authentication method the user uses to sign in (IAM only).
  var path_600791 = newJObject()
  var query_600792 = newJObject()
  add(path_600791, "AwsAccountId", newJString(AwsAccountId))
  add(query_600792, "session-lifetime", newJInt(sessionLifetime))
  add(query_600792, "reset-disabled", newJBool(resetDisabled))
  add(query_600792, "user-arn", newJString(userArn))
  add(path_600791, "DashboardId", newJString(DashboardId))
  add(query_600792, "undo-redo-disabled", newJBool(undoRedoDisabled))
  add(query_600792, "creds-type", newJString(credsType))
  result = call_600790.call(path_600791, query_600792, nil, nil, nil)

var getDashboardEmbedUrl* = Call_GetDashboardEmbedUrl_600759(
    name: "getDashboardEmbedUrl", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/embed-url#creds-type",
    validator: validate_GetDashboardEmbedUrl_600760, base: "/",
    url: url_GetDashboardEmbedUrl_600761, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDashboardVersions_600793 = ref object of OpenApiRestCall_599368
proc url_ListDashboardVersions_600795(protocol: Scheme; host: string; base: string;
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

proc validate_ListDashboardVersions_600794(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists all the versions of the dashboards in the Quicksight subscription.</p> <p>CLI syntax:</p> <p>aws quicksight list-template-versions —aws-account-id 111122223333 —template-id reports-test-template</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : AWS account ID that contains the dashboard you are listing.
  ##   DashboardId: JString (required)
  ##              : The ID for the dashboard.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600796 = path.getOrDefault("AwsAccountId")
  valid_600796 = validateParameter(valid_600796, JString, required = true,
                                 default = nil)
  if valid_600796 != nil:
    section.add "AwsAccountId", valid_600796
  var valid_600797 = path.getOrDefault("DashboardId")
  valid_600797 = validateParameter(valid_600797, JString, required = true,
                                 default = nil)
  if valid_600797 != nil:
    section.add "DashboardId", valid_600797
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600798 = query.getOrDefault("NextToken")
  valid_600798 = validateParameter(valid_600798, JString, required = false,
                                 default = nil)
  if valid_600798 != nil:
    section.add "NextToken", valid_600798
  var valid_600799 = query.getOrDefault("max-results")
  valid_600799 = validateParameter(valid_600799, JInt, required = false, default = nil)
  if valid_600799 != nil:
    section.add "max-results", valid_600799
  var valid_600800 = query.getOrDefault("next-token")
  valid_600800 = validateParameter(valid_600800, JString, required = false,
                                 default = nil)
  if valid_600800 != nil:
    section.add "next-token", valid_600800
  var valid_600801 = query.getOrDefault("MaxResults")
  valid_600801 = validateParameter(valid_600801, JString, required = false,
                                 default = nil)
  if valid_600801 != nil:
    section.add "MaxResults", valid_600801
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
  var valid_600802 = header.getOrDefault("X-Amz-Date")
  valid_600802 = validateParameter(valid_600802, JString, required = false,
                                 default = nil)
  if valid_600802 != nil:
    section.add "X-Amz-Date", valid_600802
  var valid_600803 = header.getOrDefault("X-Amz-Security-Token")
  valid_600803 = validateParameter(valid_600803, JString, required = false,
                                 default = nil)
  if valid_600803 != nil:
    section.add "X-Amz-Security-Token", valid_600803
  var valid_600804 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600804 = validateParameter(valid_600804, JString, required = false,
                                 default = nil)
  if valid_600804 != nil:
    section.add "X-Amz-Content-Sha256", valid_600804
  var valid_600805 = header.getOrDefault("X-Amz-Algorithm")
  valid_600805 = validateParameter(valid_600805, JString, required = false,
                                 default = nil)
  if valid_600805 != nil:
    section.add "X-Amz-Algorithm", valid_600805
  var valid_600806 = header.getOrDefault("X-Amz-Signature")
  valid_600806 = validateParameter(valid_600806, JString, required = false,
                                 default = nil)
  if valid_600806 != nil:
    section.add "X-Amz-Signature", valid_600806
  var valid_600807 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600807 = validateParameter(valid_600807, JString, required = false,
                                 default = nil)
  if valid_600807 != nil:
    section.add "X-Amz-SignedHeaders", valid_600807
  var valid_600808 = header.getOrDefault("X-Amz-Credential")
  valid_600808 = validateParameter(valid_600808, JString, required = false,
                                 default = nil)
  if valid_600808 != nil:
    section.add "X-Amz-Credential", valid_600808
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600809: Call_ListDashboardVersions_600793; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all the versions of the dashboards in the Quicksight subscription.</p> <p>CLI syntax:</p> <p>aws quicksight list-template-versions —aws-account-id 111122223333 —template-id reports-test-template</p>
  ## 
  let valid = call_600809.validator(path, query, header, formData, body)
  let scheme = call_600809.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600809.url(scheme.get, call_600809.host, call_600809.base,
                         call_600809.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600809, url, valid)

proc call*(call_600810: Call_ListDashboardVersions_600793; AwsAccountId: string;
          DashboardId: string; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listDashboardVersions
  ## <p>Lists all the versions of the dashboards in the Quicksight subscription.</p> <p>CLI syntax:</p> <p>aws quicksight list-template-versions —aws-account-id 111122223333 —template-id reports-test-template</p>
  ##   AwsAccountId: string (required)
  ##               : AWS account ID that contains the dashboard you are listing.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_600811 = newJObject()
  var query_600812 = newJObject()
  add(path_600811, "AwsAccountId", newJString(AwsAccountId))
  add(path_600811, "DashboardId", newJString(DashboardId))
  add(query_600812, "NextToken", newJString(NextToken))
  add(query_600812, "max-results", newJInt(maxResults))
  add(query_600812, "next-token", newJString(nextToken))
  add(query_600812, "MaxResults", newJString(MaxResults))
  result = call_600810.call(path_600811, query_600812, nil, nil, nil)

var listDashboardVersions* = Call_ListDashboardVersions_600793(
    name: "listDashboardVersions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/versions",
    validator: validate_ListDashboardVersions_600794, base: "/",
    url: url_ListDashboardVersions_600795, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDashboards_600813 = ref object of OpenApiRestCall_599368
proc url_ListDashboards_600815(protocol: Scheme; host: string; base: string;
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

proc validate_ListDashboards_600814(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Lists dashboards in the AWS account.</p> <p>CLI syntax:</p> <p> <code>aws quicksight list-dashboards --aws-account-id 111122223333 --max-results 5 —next-token 'next-10'</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : AWS account ID that contains the dashboards you are listing.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600816 = path.getOrDefault("AwsAccountId")
  valid_600816 = validateParameter(valid_600816, JString, required = true,
                                 default = nil)
  if valid_600816 != nil:
    section.add "AwsAccountId", valid_600816
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600817 = query.getOrDefault("NextToken")
  valid_600817 = validateParameter(valid_600817, JString, required = false,
                                 default = nil)
  if valid_600817 != nil:
    section.add "NextToken", valid_600817
  var valid_600818 = query.getOrDefault("max-results")
  valid_600818 = validateParameter(valid_600818, JInt, required = false, default = nil)
  if valid_600818 != nil:
    section.add "max-results", valid_600818
  var valid_600819 = query.getOrDefault("next-token")
  valid_600819 = validateParameter(valid_600819, JString, required = false,
                                 default = nil)
  if valid_600819 != nil:
    section.add "next-token", valid_600819
  var valid_600820 = query.getOrDefault("MaxResults")
  valid_600820 = validateParameter(valid_600820, JString, required = false,
                                 default = nil)
  if valid_600820 != nil:
    section.add "MaxResults", valid_600820
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
  var valid_600821 = header.getOrDefault("X-Amz-Date")
  valid_600821 = validateParameter(valid_600821, JString, required = false,
                                 default = nil)
  if valid_600821 != nil:
    section.add "X-Amz-Date", valid_600821
  var valid_600822 = header.getOrDefault("X-Amz-Security-Token")
  valid_600822 = validateParameter(valid_600822, JString, required = false,
                                 default = nil)
  if valid_600822 != nil:
    section.add "X-Amz-Security-Token", valid_600822
  var valid_600823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600823 = validateParameter(valid_600823, JString, required = false,
                                 default = nil)
  if valid_600823 != nil:
    section.add "X-Amz-Content-Sha256", valid_600823
  var valid_600824 = header.getOrDefault("X-Amz-Algorithm")
  valid_600824 = validateParameter(valid_600824, JString, required = false,
                                 default = nil)
  if valid_600824 != nil:
    section.add "X-Amz-Algorithm", valid_600824
  var valid_600825 = header.getOrDefault("X-Amz-Signature")
  valid_600825 = validateParameter(valid_600825, JString, required = false,
                                 default = nil)
  if valid_600825 != nil:
    section.add "X-Amz-Signature", valid_600825
  var valid_600826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600826 = validateParameter(valid_600826, JString, required = false,
                                 default = nil)
  if valid_600826 != nil:
    section.add "X-Amz-SignedHeaders", valid_600826
  var valid_600827 = header.getOrDefault("X-Amz-Credential")
  valid_600827 = validateParameter(valid_600827, JString, required = false,
                                 default = nil)
  if valid_600827 != nil:
    section.add "X-Amz-Credential", valid_600827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600828: Call_ListDashboards_600813; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists dashboards in the AWS account.</p> <p>CLI syntax:</p> <p> <code>aws quicksight list-dashboards --aws-account-id 111122223333 --max-results 5 —next-token 'next-10'</code> </p>
  ## 
  let valid = call_600828.validator(path, query, header, formData, body)
  let scheme = call_600828.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600828.url(scheme.get, call_600828.host, call_600828.base,
                         call_600828.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600828, url, valid)

proc call*(call_600829: Call_ListDashboards_600813; AwsAccountId: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listDashboards
  ## <p>Lists dashboards in the AWS account.</p> <p>CLI syntax:</p> <p> <code>aws quicksight list-dashboards --aws-account-id 111122223333 --max-results 5 —next-token 'next-10'</code> </p>
  ##   AwsAccountId: string (required)
  ##               : AWS account ID that contains the dashboards you are listing.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_600830 = newJObject()
  var query_600831 = newJObject()
  add(path_600830, "AwsAccountId", newJString(AwsAccountId))
  add(query_600831, "NextToken", newJString(NextToken))
  add(query_600831, "max-results", newJInt(maxResults))
  add(query_600831, "next-token", newJString(nextToken))
  add(query_600831, "MaxResults", newJString(MaxResults))
  result = call_600829.call(path_600830, query_600831, nil, nil, nil)

var listDashboards* = Call_ListDashboards_600813(name: "listDashboards",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/dashboards",
    validator: validate_ListDashboards_600814, base: "/", url: url_ListDashboards_600815,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroupMemberships_600832 = ref object of OpenApiRestCall_599368
proc url_ListGroupMemberships_600834(protocol: Scheme; host: string; base: string;
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

proc validate_ListGroupMemberships_600833(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists member users in a group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a list of group member objects.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight list-group-memberships -\-aws-account-id=111122223333 -\-namespace=default </code> </p>
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
  var valid_600835 = path.getOrDefault("GroupName")
  valid_600835 = validateParameter(valid_600835, JString, required = true,
                                 default = nil)
  if valid_600835 != nil:
    section.add "GroupName", valid_600835
  var valid_600836 = path.getOrDefault("AwsAccountId")
  valid_600836 = validateParameter(valid_600836, JString, required = true,
                                 default = nil)
  if valid_600836 != nil:
    section.add "AwsAccountId", valid_600836
  var valid_600837 = path.getOrDefault("Namespace")
  valid_600837 = validateParameter(valid_600837, JString, required = true,
                                 default = nil)
  if valid_600837 != nil:
    section.add "Namespace", valid_600837
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return from this request.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_600838 = query.getOrDefault("max-results")
  valid_600838 = validateParameter(valid_600838, JInt, required = false, default = nil)
  if valid_600838 != nil:
    section.add "max-results", valid_600838
  var valid_600839 = query.getOrDefault("next-token")
  valid_600839 = validateParameter(valid_600839, JString, required = false,
                                 default = nil)
  if valid_600839 != nil:
    section.add "next-token", valid_600839
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
  var valid_600840 = header.getOrDefault("X-Amz-Date")
  valid_600840 = validateParameter(valid_600840, JString, required = false,
                                 default = nil)
  if valid_600840 != nil:
    section.add "X-Amz-Date", valid_600840
  var valid_600841 = header.getOrDefault("X-Amz-Security-Token")
  valid_600841 = validateParameter(valid_600841, JString, required = false,
                                 default = nil)
  if valid_600841 != nil:
    section.add "X-Amz-Security-Token", valid_600841
  var valid_600842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600842 = validateParameter(valid_600842, JString, required = false,
                                 default = nil)
  if valid_600842 != nil:
    section.add "X-Amz-Content-Sha256", valid_600842
  var valid_600843 = header.getOrDefault("X-Amz-Algorithm")
  valid_600843 = validateParameter(valid_600843, JString, required = false,
                                 default = nil)
  if valid_600843 != nil:
    section.add "X-Amz-Algorithm", valid_600843
  var valid_600844 = header.getOrDefault("X-Amz-Signature")
  valid_600844 = validateParameter(valid_600844, JString, required = false,
                                 default = nil)
  if valid_600844 != nil:
    section.add "X-Amz-Signature", valid_600844
  var valid_600845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600845 = validateParameter(valid_600845, JString, required = false,
                                 default = nil)
  if valid_600845 != nil:
    section.add "X-Amz-SignedHeaders", valid_600845
  var valid_600846 = header.getOrDefault("X-Amz-Credential")
  valid_600846 = validateParameter(valid_600846, JString, required = false,
                                 default = nil)
  if valid_600846 != nil:
    section.add "X-Amz-Credential", valid_600846
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600847: Call_ListGroupMemberships_600832; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists member users in a group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a list of group member objects.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight list-group-memberships -\-aws-account-id=111122223333 -\-namespace=default </code> </p>
  ## 
  let valid = call_600847.validator(path, query, header, formData, body)
  let scheme = call_600847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600847.url(scheme.get, call_600847.host, call_600847.base,
                         call_600847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600847, url, valid)

proc call*(call_600848: Call_ListGroupMemberships_600832; GroupName: string;
          AwsAccountId: string; Namespace: string; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listGroupMemberships
  ## <p>Lists member users in a group.</p> <p>The permissions resource is <code>arn:aws:quicksight:us-east-1:<i>&lt;aws-account-id&gt;</i>:group/default/<i>&lt;group-name&gt;</i> </code>.</p> <p>The response is a list of group member objects.</p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight list-group-memberships -\-aws-account-id=111122223333 -\-namespace=default </code> </p>
  ##   GroupName: string (required)
  ##            : The name of the group that you want to see a membership list of.
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the group is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   maxResults: int
  ##             : The maximum number of results to return from this request.
  ##   nextToken: string
  ##            : A pagination token that can be used in a subsequent request.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_600849 = newJObject()
  var query_600850 = newJObject()
  add(path_600849, "GroupName", newJString(GroupName))
  add(path_600849, "AwsAccountId", newJString(AwsAccountId))
  add(query_600850, "max-results", newJInt(maxResults))
  add(query_600850, "next-token", newJString(nextToken))
  add(path_600849, "Namespace", newJString(Namespace))
  result = call_600848.call(path_600849, query_600850, nil, nil, nil)

var listGroupMemberships* = Call_ListGroupMemberships_600832(
    name: "listGroupMemberships", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/groups/{GroupName}/members",
    validator: validate_ListGroupMemberships_600833, base: "/",
    url: url_ListGroupMemberships_600834, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIAMPolicyAssignments_600851 = ref object of OpenApiRestCall_599368
proc url_ListIAMPolicyAssignments_600853(protocol: Scheme; host: string;
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

proc validate_ListIAMPolicyAssignments_600852(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists assignments in current QuickSight account.</p> <p>CLI syntax:</p> <p> <code>aws quicksight list-iam-policy-assignments --aws-account-id=111122223333 --max-result=5 --assignment-status=ENABLED --namespace=default --region=us-east-1 --next-token=3 </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID that contains this IAM policy assignment.
  ##   Namespace: JString (required)
  ##            : The namespace for this assignment.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600854 = path.getOrDefault("AwsAccountId")
  valid_600854 = validateParameter(valid_600854, JString, required = true,
                                 default = nil)
  if valid_600854 != nil:
    section.add "AwsAccountId", valid_600854
  var valid_600855 = path.getOrDefault("Namespace")
  valid_600855 = validateParameter(valid_600855, JString, required = true,
                                 default = nil)
  if valid_600855 != nil:
    section.add "Namespace", valid_600855
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_600856 = query.getOrDefault("max-results")
  valid_600856 = validateParameter(valid_600856, JInt, required = false, default = nil)
  if valid_600856 != nil:
    section.add "max-results", valid_600856
  var valid_600857 = query.getOrDefault("next-token")
  valid_600857 = validateParameter(valid_600857, JString, required = false,
                                 default = nil)
  if valid_600857 != nil:
    section.add "next-token", valid_600857
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
  var valid_600858 = header.getOrDefault("X-Amz-Date")
  valid_600858 = validateParameter(valid_600858, JString, required = false,
                                 default = nil)
  if valid_600858 != nil:
    section.add "X-Amz-Date", valid_600858
  var valid_600859 = header.getOrDefault("X-Amz-Security-Token")
  valid_600859 = validateParameter(valid_600859, JString, required = false,
                                 default = nil)
  if valid_600859 != nil:
    section.add "X-Amz-Security-Token", valid_600859
  var valid_600860 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600860 = validateParameter(valid_600860, JString, required = false,
                                 default = nil)
  if valid_600860 != nil:
    section.add "X-Amz-Content-Sha256", valid_600860
  var valid_600861 = header.getOrDefault("X-Amz-Algorithm")
  valid_600861 = validateParameter(valid_600861, JString, required = false,
                                 default = nil)
  if valid_600861 != nil:
    section.add "X-Amz-Algorithm", valid_600861
  var valid_600862 = header.getOrDefault("X-Amz-Signature")
  valid_600862 = validateParameter(valid_600862, JString, required = false,
                                 default = nil)
  if valid_600862 != nil:
    section.add "X-Amz-Signature", valid_600862
  var valid_600863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600863 = validateParameter(valid_600863, JString, required = false,
                                 default = nil)
  if valid_600863 != nil:
    section.add "X-Amz-SignedHeaders", valid_600863
  var valid_600864 = header.getOrDefault("X-Amz-Credential")
  valid_600864 = validateParameter(valid_600864, JString, required = false,
                                 default = nil)
  if valid_600864 != nil:
    section.add "X-Amz-Credential", valid_600864
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600866: Call_ListIAMPolicyAssignments_600851; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists assignments in current QuickSight account.</p> <p>CLI syntax:</p> <p> <code>aws quicksight list-iam-policy-assignments --aws-account-id=111122223333 --max-result=5 --assignment-status=ENABLED --namespace=default --region=us-east-1 --next-token=3 </code> </p>
  ## 
  let valid = call_600866.validator(path, query, header, formData, body)
  let scheme = call_600866.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600866.url(scheme.get, call_600866.host, call_600866.base,
                         call_600866.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600866, url, valid)

proc call*(call_600867: Call_ListIAMPolicyAssignments_600851; AwsAccountId: string;
          body: JsonNode; Namespace: string; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listIAMPolicyAssignments
  ## <p>Lists assignments in current QuickSight account.</p> <p>CLI syntax:</p> <p> <code>aws quicksight list-iam-policy-assignments --aws-account-id=111122223333 --max-result=5 --assignment-status=ENABLED --namespace=default --region=us-east-1 --next-token=3 </code> </p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID that contains this IAM policy assignment.
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   body: JObject (required)
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  ##   Namespace: string (required)
  ##            : The namespace for this assignment.
  var path_600868 = newJObject()
  var query_600869 = newJObject()
  var body_600870 = newJObject()
  add(path_600868, "AwsAccountId", newJString(AwsAccountId))
  add(query_600869, "max-results", newJInt(maxResults))
  if body != nil:
    body_600870 = body
  add(query_600869, "next-token", newJString(nextToken))
  add(path_600868, "Namespace", newJString(Namespace))
  result = call_600867.call(path_600868, query_600869, nil, nil, body_600870)

var listIAMPolicyAssignments* = Call_ListIAMPolicyAssignments_600851(
    name: "listIAMPolicyAssignments", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/iam-policy-assignments",
    validator: validate_ListIAMPolicyAssignments_600852, base: "/",
    url: url_ListIAMPolicyAssignments_600853, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIAMPolicyAssignmentsForUser_600871 = ref object of OpenApiRestCall_599368
proc url_ListIAMPolicyAssignmentsForUser_600873(protocol: Scheme; host: string;
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

proc validate_ListIAMPolicyAssignmentsForUser_600872(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists all the assignments and the ARNs for the associated IAM policies assigned to the specified user and the group or groups that the user belongs to.</p> <p>CLI syntax:</p> <p> <code>aws quicksight list-iam-policy-assignments-for-user --aws-account-id=111122223333 --user-name=user5 --namespace=default --max-result=6 --region=us-east-1 </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS account ID that contains the assignment.
  ##   UserName: JString (required)
  ##           : The name of the user.
  ##   Namespace: JString (required)
  ##            : The namespace of the assignment.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600874 = path.getOrDefault("AwsAccountId")
  valid_600874 = validateParameter(valid_600874, JString, required = true,
                                 default = nil)
  if valid_600874 != nil:
    section.add "AwsAccountId", valid_600874
  var valid_600875 = path.getOrDefault("UserName")
  valid_600875 = validateParameter(valid_600875, JString, required = true,
                                 default = nil)
  if valid_600875 != nil:
    section.add "UserName", valid_600875
  var valid_600876 = path.getOrDefault("Namespace")
  valid_600876 = validateParameter(valid_600876, JString, required = true,
                                 default = nil)
  if valid_600876 != nil:
    section.add "Namespace", valid_600876
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  section = newJObject()
  var valid_600877 = query.getOrDefault("max-results")
  valid_600877 = validateParameter(valid_600877, JInt, required = false, default = nil)
  if valid_600877 != nil:
    section.add "max-results", valid_600877
  var valid_600878 = query.getOrDefault("next-token")
  valid_600878 = validateParameter(valid_600878, JString, required = false,
                                 default = nil)
  if valid_600878 != nil:
    section.add "next-token", valid_600878
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
  var valid_600879 = header.getOrDefault("X-Amz-Date")
  valid_600879 = validateParameter(valid_600879, JString, required = false,
                                 default = nil)
  if valid_600879 != nil:
    section.add "X-Amz-Date", valid_600879
  var valid_600880 = header.getOrDefault("X-Amz-Security-Token")
  valid_600880 = validateParameter(valid_600880, JString, required = false,
                                 default = nil)
  if valid_600880 != nil:
    section.add "X-Amz-Security-Token", valid_600880
  var valid_600881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600881 = validateParameter(valid_600881, JString, required = false,
                                 default = nil)
  if valid_600881 != nil:
    section.add "X-Amz-Content-Sha256", valid_600881
  var valid_600882 = header.getOrDefault("X-Amz-Algorithm")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "X-Amz-Algorithm", valid_600882
  var valid_600883 = header.getOrDefault("X-Amz-Signature")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-Signature", valid_600883
  var valid_600884 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600884 = validateParameter(valid_600884, JString, required = false,
                                 default = nil)
  if valid_600884 != nil:
    section.add "X-Amz-SignedHeaders", valid_600884
  var valid_600885 = header.getOrDefault("X-Amz-Credential")
  valid_600885 = validateParameter(valid_600885, JString, required = false,
                                 default = nil)
  if valid_600885 != nil:
    section.add "X-Amz-Credential", valid_600885
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600886: Call_ListIAMPolicyAssignmentsForUser_600871;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Lists all the assignments and the ARNs for the associated IAM policies assigned to the specified user and the group or groups that the user belongs to.</p> <p>CLI syntax:</p> <p> <code>aws quicksight list-iam-policy-assignments-for-user --aws-account-id=111122223333 --user-name=user5 --namespace=default --max-result=6 --region=us-east-1 </code> </p>
  ## 
  let valid = call_600886.validator(path, query, header, formData, body)
  let scheme = call_600886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600886.url(scheme.get, call_600886.host, call_600886.base,
                         call_600886.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600886, url, valid)

proc call*(call_600887: Call_ListIAMPolicyAssignmentsForUser_600871;
          AwsAccountId: string; UserName: string; Namespace: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listIAMPolicyAssignmentsForUser
  ## <p>Lists all the assignments and the ARNs for the associated IAM policies assigned to the specified user and the group or groups that the user belongs to.</p> <p>CLI syntax:</p> <p> <code>aws quicksight list-iam-policy-assignments-for-user --aws-account-id=111122223333 --user-name=user5 --namespace=default --max-result=6 --region=us-east-1 </code> </p>
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID that contains the assignment.
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  ##   UserName: string (required)
  ##           : The name of the user.
  ##   Namespace: string (required)
  ##            : The namespace of the assignment.
  var path_600888 = newJObject()
  var query_600889 = newJObject()
  add(path_600888, "AwsAccountId", newJString(AwsAccountId))
  add(query_600889, "max-results", newJInt(maxResults))
  add(query_600889, "next-token", newJString(nextToken))
  add(path_600888, "UserName", newJString(UserName))
  add(path_600888, "Namespace", newJString(Namespace))
  result = call_600887.call(path_600888, query_600889, nil, nil, nil)

var listIAMPolicyAssignmentsForUser* = Call_ListIAMPolicyAssignmentsForUser_600871(
    name: "listIAMPolicyAssignmentsForUser", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}/iam-policy-assignments",
    validator: validate_ListIAMPolicyAssignmentsForUser_600872, base: "/",
    url: url_ListIAMPolicyAssignmentsForUser_600873,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListIngestions_600890 = ref object of OpenApiRestCall_599368
proc url_ListIngestions_600892(protocol: Scheme; host: string; base: string;
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

proc validate_ListIngestions_600891(path: JsonNode; query: JsonNode;
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
  var valid_600893 = path.getOrDefault("AwsAccountId")
  valid_600893 = validateParameter(valid_600893, JString, required = true,
                                 default = nil)
  if valid_600893 != nil:
    section.add "AwsAccountId", valid_600893
  var valid_600894 = path.getOrDefault("DataSetId")
  valid_600894 = validateParameter(valid_600894, JString, required = true,
                                 default = nil)
  if valid_600894 != nil:
    section.add "DataSetId", valid_600894
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600895 = query.getOrDefault("NextToken")
  valid_600895 = validateParameter(valid_600895, JString, required = false,
                                 default = nil)
  if valid_600895 != nil:
    section.add "NextToken", valid_600895
  var valid_600896 = query.getOrDefault("max-results")
  valid_600896 = validateParameter(valid_600896, JInt, required = false, default = nil)
  if valid_600896 != nil:
    section.add "max-results", valid_600896
  var valid_600897 = query.getOrDefault("next-token")
  valid_600897 = validateParameter(valid_600897, JString, required = false,
                                 default = nil)
  if valid_600897 != nil:
    section.add "next-token", valid_600897
  var valid_600898 = query.getOrDefault("MaxResults")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "MaxResults", valid_600898
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
  var valid_600899 = header.getOrDefault("X-Amz-Date")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Date", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Security-Token")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Security-Token", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-Content-Sha256", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-Algorithm")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Algorithm", valid_600902
  var valid_600903 = header.getOrDefault("X-Amz-Signature")
  valid_600903 = validateParameter(valid_600903, JString, required = false,
                                 default = nil)
  if valid_600903 != nil:
    section.add "X-Amz-Signature", valid_600903
  var valid_600904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600904 = validateParameter(valid_600904, JString, required = false,
                                 default = nil)
  if valid_600904 != nil:
    section.add "X-Amz-SignedHeaders", valid_600904
  var valid_600905 = header.getOrDefault("X-Amz-Credential")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "X-Amz-Credential", valid_600905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600906: Call_ListIngestions_600890; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the history of SPICE ingestions for a dataset.
  ## 
  let valid = call_600906.validator(path, query, header, formData, body)
  let scheme = call_600906.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600906.url(scheme.get, call_600906.host, call_600906.base,
                         call_600906.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600906, url, valid)

proc call*(call_600907: Call_ListIngestions_600890; AwsAccountId: string;
          DataSetId: string; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listIngestions
  ## Lists the history of SPICE ingestions for a dataset.
  ##   AwsAccountId: string (required)
  ##               : The AWS account ID.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  ##   DataSetId: string (required)
  ##            : The ID of the dataset used in the ingestion.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_600908 = newJObject()
  var query_600909 = newJObject()
  add(path_600908, "AwsAccountId", newJString(AwsAccountId))
  add(query_600909, "NextToken", newJString(NextToken))
  add(query_600909, "max-results", newJInt(maxResults))
  add(query_600909, "next-token", newJString(nextToken))
  add(path_600908, "DataSetId", newJString(DataSetId))
  add(query_600909, "MaxResults", newJString(MaxResults))
  result = call_600907.call(path_600908, query_600909, nil, nil, nil)

var listIngestions* = Call_ListIngestions_600890(name: "listIngestions",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/data-sets/{DataSetId}/ingestions",
    validator: validate_ListIngestions_600891, base: "/", url: url_ListIngestions_600892,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_600924 = ref object of OpenApiRestCall_599368
proc url_TagResource_600926(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_600925(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Assigns a tag or tags to a resource.</p> <p>Assigns one or more tags (key-value pairs) to the specified QuickSight resource. Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. You can use the TagResource action with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource. QuickSight supports tagging on data-set, data-source, dashboard, template. </p> <p>Tagging for QuickSight works in a similar was to tagging for other AWS services, except for the following:</p> <ul> <li> <p>You can't use tags to track AWS costs for QuickSight, because QuickSight costs are based on users and SPICE capacity, which aren't taggable resources.</p> </li> <li> <p>QuickSight doesn't currently support the Tag Editor for AWS Resource Groups.</p> </li> </ul> <p>CLI syntax to tag a resource:</p> <ul> <li> <p> <code>aws quicksight tag-resource --resource-arn arn:aws:quicksight:us-east-1:111111111111:dataset/dataset1 --tags Key=K1,Value=V1 Key=K2,Value=V2 --region us-east-1</code> </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the resource you want to tag.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceArn` field"
  var valid_600927 = path.getOrDefault("ResourceArn")
  valid_600927 = validateParameter(valid_600927, JString, required = true,
                                 default = nil)
  if valid_600927 != nil:
    section.add "ResourceArn", valid_600927
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
  var valid_600928 = header.getOrDefault("X-Amz-Date")
  valid_600928 = validateParameter(valid_600928, JString, required = false,
                                 default = nil)
  if valid_600928 != nil:
    section.add "X-Amz-Date", valid_600928
  var valid_600929 = header.getOrDefault("X-Amz-Security-Token")
  valid_600929 = validateParameter(valid_600929, JString, required = false,
                                 default = nil)
  if valid_600929 != nil:
    section.add "X-Amz-Security-Token", valid_600929
  var valid_600930 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600930 = validateParameter(valid_600930, JString, required = false,
                                 default = nil)
  if valid_600930 != nil:
    section.add "X-Amz-Content-Sha256", valid_600930
  var valid_600931 = header.getOrDefault("X-Amz-Algorithm")
  valid_600931 = validateParameter(valid_600931, JString, required = false,
                                 default = nil)
  if valid_600931 != nil:
    section.add "X-Amz-Algorithm", valid_600931
  var valid_600932 = header.getOrDefault("X-Amz-Signature")
  valid_600932 = validateParameter(valid_600932, JString, required = false,
                                 default = nil)
  if valid_600932 != nil:
    section.add "X-Amz-Signature", valid_600932
  var valid_600933 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600933 = validateParameter(valid_600933, JString, required = false,
                                 default = nil)
  if valid_600933 != nil:
    section.add "X-Amz-SignedHeaders", valid_600933
  var valid_600934 = header.getOrDefault("X-Amz-Credential")
  valid_600934 = validateParameter(valid_600934, JString, required = false,
                                 default = nil)
  if valid_600934 != nil:
    section.add "X-Amz-Credential", valid_600934
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600936: Call_TagResource_600924; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Assigns a tag or tags to a resource.</p> <p>Assigns one or more tags (key-value pairs) to the specified QuickSight resource. Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. You can use the TagResource action with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource. QuickSight supports tagging on data-set, data-source, dashboard, template. </p> <p>Tagging for QuickSight works in a similar was to tagging for other AWS services, except for the following:</p> <ul> <li> <p>You can't use tags to track AWS costs for QuickSight, because QuickSight costs are based on users and SPICE capacity, which aren't taggable resources.</p> </li> <li> <p>QuickSight doesn't currently support the Tag Editor for AWS Resource Groups.</p> </li> </ul> <p>CLI syntax to tag a resource:</p> <ul> <li> <p> <code>aws quicksight tag-resource --resource-arn arn:aws:quicksight:us-east-1:111111111111:dataset/dataset1 --tags Key=K1,Value=V1 Key=K2,Value=V2 --region us-east-1</code> </p> </li> </ul>
  ## 
  let valid = call_600936.validator(path, query, header, formData, body)
  let scheme = call_600936.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600936.url(scheme.get, call_600936.host, call_600936.base,
                         call_600936.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600936, url, valid)

proc call*(call_600937: Call_TagResource_600924; ResourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Assigns a tag or tags to a resource.</p> <p>Assigns one or more tags (key-value pairs) to the specified QuickSight resource. Tags can help you organize and categorize your resources. You can also use them to scope user permissions, by granting a user permission to access or change only resources with certain tag values. You can use the TagResource action with a resource that already has tags. If you specify a new tag key for the resource, this tag is appended to the list of tags associated with the resource. If you specify a tag key that is already associated with the resource, the new tag value that you specify replaces the previous value for that tag.</p> <p>You can associate as many as 50 tags with a resource. QuickSight supports tagging on data-set, data-source, dashboard, template. </p> <p>Tagging for QuickSight works in a similar was to tagging for other AWS services, except for the following:</p> <ul> <li> <p>You can't use tags to track AWS costs for QuickSight, because QuickSight costs are based on users and SPICE capacity, which aren't taggable resources.</p> </li> <li> <p>QuickSight doesn't currently support the Tag Editor for AWS Resource Groups.</p> </li> </ul> <p>CLI syntax to tag a resource:</p> <ul> <li> <p> <code>aws quicksight tag-resource --resource-arn arn:aws:quicksight:us-east-1:111111111111:dataset/dataset1 --tags Key=K1,Value=V1 Key=K2,Value=V2 --region us-east-1</code> </p> </li> </ul>
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource you want to tag.
  ##   body: JObject (required)
  var path_600938 = newJObject()
  var body_600939 = newJObject()
  add(path_600938, "ResourceArn", newJString(ResourceArn))
  if body != nil:
    body_600939 = body
  result = call_600937.call(path_600938, nil, nil, nil, body_600939)

var tagResource* = Call_TagResource_600924(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "quicksight.amazonaws.com",
                                        route: "/resources/{ResourceArn}/tags",
                                        validator: validate_TagResource_600925,
                                        base: "/", url: url_TagResource_600926,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600910 = ref object of OpenApiRestCall_599368
proc url_ListTagsForResource_600912(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_600911(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Lists the tags assigned to a resource.</p> <p>CLI syntax:</p> <ul> <li> <p> <code>aws quicksight list-tags-for-resource --resource-arn arn:aws:quicksight:us-east-1:111111111111:dataset/dataset1 --region us-east-1</code> </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the resource you want a list of tags for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceArn` field"
  var valid_600913 = path.getOrDefault("ResourceArn")
  valid_600913 = validateParameter(valid_600913, JString, required = true,
                                 default = nil)
  if valid_600913 != nil:
    section.add "ResourceArn", valid_600913
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
  var valid_600914 = header.getOrDefault("X-Amz-Date")
  valid_600914 = validateParameter(valid_600914, JString, required = false,
                                 default = nil)
  if valid_600914 != nil:
    section.add "X-Amz-Date", valid_600914
  var valid_600915 = header.getOrDefault("X-Amz-Security-Token")
  valid_600915 = validateParameter(valid_600915, JString, required = false,
                                 default = nil)
  if valid_600915 != nil:
    section.add "X-Amz-Security-Token", valid_600915
  var valid_600916 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600916 = validateParameter(valid_600916, JString, required = false,
                                 default = nil)
  if valid_600916 != nil:
    section.add "X-Amz-Content-Sha256", valid_600916
  var valid_600917 = header.getOrDefault("X-Amz-Algorithm")
  valid_600917 = validateParameter(valid_600917, JString, required = false,
                                 default = nil)
  if valid_600917 != nil:
    section.add "X-Amz-Algorithm", valid_600917
  var valid_600918 = header.getOrDefault("X-Amz-Signature")
  valid_600918 = validateParameter(valid_600918, JString, required = false,
                                 default = nil)
  if valid_600918 != nil:
    section.add "X-Amz-Signature", valid_600918
  var valid_600919 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600919 = validateParameter(valid_600919, JString, required = false,
                                 default = nil)
  if valid_600919 != nil:
    section.add "X-Amz-SignedHeaders", valid_600919
  var valid_600920 = header.getOrDefault("X-Amz-Credential")
  valid_600920 = validateParameter(valid_600920, JString, required = false,
                                 default = nil)
  if valid_600920 != nil:
    section.add "X-Amz-Credential", valid_600920
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600921: Call_ListTagsForResource_600910; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the tags assigned to a resource.</p> <p>CLI syntax:</p> <ul> <li> <p> <code>aws quicksight list-tags-for-resource --resource-arn arn:aws:quicksight:us-east-1:111111111111:dataset/dataset1 --region us-east-1</code> </p> </li> </ul>
  ## 
  let valid = call_600921.validator(path, query, header, formData, body)
  let scheme = call_600921.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600921.url(scheme.get, call_600921.host, call_600921.base,
                         call_600921.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600921, url, valid)

proc call*(call_600922: Call_ListTagsForResource_600910; ResourceArn: string): Recallable =
  ## listTagsForResource
  ## <p>Lists the tags assigned to a resource.</p> <p>CLI syntax:</p> <ul> <li> <p> <code>aws quicksight list-tags-for-resource --resource-arn arn:aws:quicksight:us-east-1:111111111111:dataset/dataset1 --region us-east-1</code> </p> </li> </ul>
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource you want a list of tags for.
  var path_600923 = newJObject()
  add(path_600923, "ResourceArn", newJString(ResourceArn))
  result = call_600922.call(path_600923, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_600910(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com", route: "/resources/{ResourceArn}/tags",
    validator: validate_ListTagsForResource_600911, base: "/",
    url: url_ListTagsForResource_600912, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplateAliases_600940 = ref object of OpenApiRestCall_599368
proc url_ListTemplateAliases_600942(protocol: Scheme; host: string; base: string;
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

proc validate_ListTemplateAliases_600941(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Lists all the aliases of a template.</p> <p>CLI syntax:</p> <p> <code>aws quicksight list-template-aliases --aws-account-id 111122223333 —template-id 'reports_test_template'</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : AWS account ID that contains the template aliases you are listing.
  ##   TemplateId: JString (required)
  ##             : The ID for the template.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600943 = path.getOrDefault("AwsAccountId")
  valid_600943 = validateParameter(valid_600943, JString, required = true,
                                 default = nil)
  if valid_600943 != nil:
    section.add "AwsAccountId", valid_600943
  var valid_600944 = path.getOrDefault("TemplateId")
  valid_600944 = validateParameter(valid_600944, JString, required = true,
                                 default = nil)
  if valid_600944 != nil:
    section.add "TemplateId", valid_600944
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-result: JInt
  ##             : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600945 = query.getOrDefault("NextToken")
  valid_600945 = validateParameter(valid_600945, JString, required = false,
                                 default = nil)
  if valid_600945 != nil:
    section.add "NextToken", valid_600945
  var valid_600946 = query.getOrDefault("max-result")
  valid_600946 = validateParameter(valid_600946, JInt, required = false, default = nil)
  if valid_600946 != nil:
    section.add "max-result", valid_600946
  var valid_600947 = query.getOrDefault("next-token")
  valid_600947 = validateParameter(valid_600947, JString, required = false,
                                 default = nil)
  if valid_600947 != nil:
    section.add "next-token", valid_600947
  var valid_600948 = query.getOrDefault("MaxResults")
  valid_600948 = validateParameter(valid_600948, JString, required = false,
                                 default = nil)
  if valid_600948 != nil:
    section.add "MaxResults", valid_600948
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
  var valid_600949 = header.getOrDefault("X-Amz-Date")
  valid_600949 = validateParameter(valid_600949, JString, required = false,
                                 default = nil)
  if valid_600949 != nil:
    section.add "X-Amz-Date", valid_600949
  var valid_600950 = header.getOrDefault("X-Amz-Security-Token")
  valid_600950 = validateParameter(valid_600950, JString, required = false,
                                 default = nil)
  if valid_600950 != nil:
    section.add "X-Amz-Security-Token", valid_600950
  var valid_600951 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600951 = validateParameter(valid_600951, JString, required = false,
                                 default = nil)
  if valid_600951 != nil:
    section.add "X-Amz-Content-Sha256", valid_600951
  var valid_600952 = header.getOrDefault("X-Amz-Algorithm")
  valid_600952 = validateParameter(valid_600952, JString, required = false,
                                 default = nil)
  if valid_600952 != nil:
    section.add "X-Amz-Algorithm", valid_600952
  var valid_600953 = header.getOrDefault("X-Amz-Signature")
  valid_600953 = validateParameter(valid_600953, JString, required = false,
                                 default = nil)
  if valid_600953 != nil:
    section.add "X-Amz-Signature", valid_600953
  var valid_600954 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600954 = validateParameter(valid_600954, JString, required = false,
                                 default = nil)
  if valid_600954 != nil:
    section.add "X-Amz-SignedHeaders", valid_600954
  var valid_600955 = header.getOrDefault("X-Amz-Credential")
  valid_600955 = validateParameter(valid_600955, JString, required = false,
                                 default = nil)
  if valid_600955 != nil:
    section.add "X-Amz-Credential", valid_600955
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600956: Call_ListTemplateAliases_600940; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all the aliases of a template.</p> <p>CLI syntax:</p> <p> <code>aws quicksight list-template-aliases --aws-account-id 111122223333 —template-id 'reports_test_template'</code> </p>
  ## 
  let valid = call_600956.validator(path, query, header, formData, body)
  let scheme = call_600956.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600956.url(scheme.get, call_600956.host, call_600956.base,
                         call_600956.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600956, url, valid)

proc call*(call_600957: Call_ListTemplateAliases_600940; AwsAccountId: string;
          TemplateId: string; NextToken: string = ""; maxResult: int = 0;
          nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTemplateAliases
  ## <p>Lists all the aliases of a template.</p> <p>CLI syntax:</p> <p> <code>aws quicksight list-template-aliases --aws-account-id 111122223333 —template-id 'reports_test_template'</code> </p>
  ##   AwsAccountId: string (required)
  ##               : AWS account ID that contains the template aliases you are listing.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResult: int
  ##            : The maximum number of results to be returned per request.
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_600958 = newJObject()
  var query_600959 = newJObject()
  add(path_600958, "AwsAccountId", newJString(AwsAccountId))
  add(query_600959, "NextToken", newJString(NextToken))
  add(query_600959, "max-result", newJInt(maxResult))
  add(path_600958, "TemplateId", newJString(TemplateId))
  add(query_600959, "next-token", newJString(nextToken))
  add(query_600959, "MaxResults", newJString(MaxResults))
  result = call_600957.call(path_600958, query_600959, nil, nil, nil)

var listTemplateAliases* = Call_ListTemplateAliases_600940(
    name: "listTemplateAliases", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}/aliases",
    validator: validate_ListTemplateAliases_600941, base: "/",
    url: url_ListTemplateAliases_600942, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplateVersions_600960 = ref object of OpenApiRestCall_599368
proc url_ListTemplateVersions_600962(protocol: Scheme; host: string; base: string;
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

proc validate_ListTemplateVersions_600961(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists all the versions of the templates in the Quicksight account.</p> <p>CLI syntax:</p> <p>aws quicksight list-template-versions --aws-account-id 111122223333 --aws-account-id 196359894473 --template-id reports-test-template</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : AWS account ID that contains the templates you are listing.
  ##   TemplateId: JString (required)
  ##             : The ID for the template.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600963 = path.getOrDefault("AwsAccountId")
  valid_600963 = validateParameter(valid_600963, JString, required = true,
                                 default = nil)
  if valid_600963 != nil:
    section.add "AwsAccountId", valid_600963
  var valid_600964 = path.getOrDefault("TemplateId")
  valid_600964 = validateParameter(valid_600964, JString, required = true,
                                 default = nil)
  if valid_600964 != nil:
    section.add "TemplateId", valid_600964
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-results: JInt
  ##              : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600965 = query.getOrDefault("NextToken")
  valid_600965 = validateParameter(valid_600965, JString, required = false,
                                 default = nil)
  if valid_600965 != nil:
    section.add "NextToken", valid_600965
  var valid_600966 = query.getOrDefault("max-results")
  valid_600966 = validateParameter(valid_600966, JInt, required = false, default = nil)
  if valid_600966 != nil:
    section.add "max-results", valid_600966
  var valid_600967 = query.getOrDefault("next-token")
  valid_600967 = validateParameter(valid_600967, JString, required = false,
                                 default = nil)
  if valid_600967 != nil:
    section.add "next-token", valid_600967
  var valid_600968 = query.getOrDefault("MaxResults")
  valid_600968 = validateParameter(valid_600968, JString, required = false,
                                 default = nil)
  if valid_600968 != nil:
    section.add "MaxResults", valid_600968
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
  var valid_600969 = header.getOrDefault("X-Amz-Date")
  valid_600969 = validateParameter(valid_600969, JString, required = false,
                                 default = nil)
  if valid_600969 != nil:
    section.add "X-Amz-Date", valid_600969
  var valid_600970 = header.getOrDefault("X-Amz-Security-Token")
  valid_600970 = validateParameter(valid_600970, JString, required = false,
                                 default = nil)
  if valid_600970 != nil:
    section.add "X-Amz-Security-Token", valid_600970
  var valid_600971 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600971 = validateParameter(valid_600971, JString, required = false,
                                 default = nil)
  if valid_600971 != nil:
    section.add "X-Amz-Content-Sha256", valid_600971
  var valid_600972 = header.getOrDefault("X-Amz-Algorithm")
  valid_600972 = validateParameter(valid_600972, JString, required = false,
                                 default = nil)
  if valid_600972 != nil:
    section.add "X-Amz-Algorithm", valid_600972
  var valid_600973 = header.getOrDefault("X-Amz-Signature")
  valid_600973 = validateParameter(valid_600973, JString, required = false,
                                 default = nil)
  if valid_600973 != nil:
    section.add "X-Amz-Signature", valid_600973
  var valid_600974 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600974 = validateParameter(valid_600974, JString, required = false,
                                 default = nil)
  if valid_600974 != nil:
    section.add "X-Amz-SignedHeaders", valid_600974
  var valid_600975 = header.getOrDefault("X-Amz-Credential")
  valid_600975 = validateParameter(valid_600975, JString, required = false,
                                 default = nil)
  if valid_600975 != nil:
    section.add "X-Amz-Credential", valid_600975
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600976: Call_ListTemplateVersions_600960; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all the versions of the templates in the Quicksight account.</p> <p>CLI syntax:</p> <p>aws quicksight list-template-versions --aws-account-id 111122223333 --aws-account-id 196359894473 --template-id reports-test-template</p>
  ## 
  let valid = call_600976.validator(path, query, header, formData, body)
  let scheme = call_600976.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600976.url(scheme.get, call_600976.host, call_600976.base,
                         call_600976.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600976, url, valid)

proc call*(call_600977: Call_ListTemplateVersions_600960; AwsAccountId: string;
          TemplateId: string; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listTemplateVersions
  ## <p>Lists all the versions of the templates in the Quicksight account.</p> <p>CLI syntax:</p> <p>aws quicksight list-template-versions --aws-account-id 111122223333 --aws-account-id 196359894473 --template-id reports-test-template</p>
  ##   AwsAccountId: string (required)
  ##               : AWS account ID that contains the templates you are listing.
  ##   NextToken: string
  ##            : Pagination token
  ##   TemplateId: string (required)
  ##             : The ID for the template.
  ##   maxResults: int
  ##             : The maximum number of results to be returned per request.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_600978 = newJObject()
  var query_600979 = newJObject()
  add(path_600978, "AwsAccountId", newJString(AwsAccountId))
  add(query_600979, "NextToken", newJString(NextToken))
  add(path_600978, "TemplateId", newJString(TemplateId))
  add(query_600979, "max-results", newJInt(maxResults))
  add(query_600979, "next-token", newJString(nextToken))
  add(query_600979, "MaxResults", newJString(MaxResults))
  result = call_600977.call(path_600978, query_600979, nil, nil, nil)

var listTemplateVersions* = Call_ListTemplateVersions_600960(
    name: "listTemplateVersions", meth: HttpMethod.HttpGet,
    host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates/{TemplateId}/versions",
    validator: validate_ListTemplateVersions_600961, base: "/",
    url: url_ListTemplateVersions_600962, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTemplates_600980 = ref object of OpenApiRestCall_599368
proc url_ListTemplates_600982(protocol: Scheme; host: string; base: string;
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

proc validate_ListTemplates_600981(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Lists all the templates in the QuickSight account.</p> <p>CLI syntax:</p> <p> <code>aws quicksight list-templates --aws-account-id 111122223333 --max-results 1 —next-token AYADeJuxwOypAndSoOn</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : AWS account ID that contains the templates you are listing.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_600983 = path.getOrDefault("AwsAccountId")
  valid_600983 = validateParameter(valid_600983, JString, required = true,
                                 default = nil)
  if valid_600983 != nil:
    section.add "AwsAccountId", valid_600983
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   max-result: JInt
  ##             : The maximum number of results to be returned per request.
  ##   next-token: JString
  ##             : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_600984 = query.getOrDefault("NextToken")
  valid_600984 = validateParameter(valid_600984, JString, required = false,
                                 default = nil)
  if valid_600984 != nil:
    section.add "NextToken", valid_600984
  var valid_600985 = query.getOrDefault("max-result")
  valid_600985 = validateParameter(valid_600985, JInt, required = false, default = nil)
  if valid_600985 != nil:
    section.add "max-result", valid_600985
  var valid_600986 = query.getOrDefault("next-token")
  valid_600986 = validateParameter(valid_600986, JString, required = false,
                                 default = nil)
  if valid_600986 != nil:
    section.add "next-token", valid_600986
  var valid_600987 = query.getOrDefault("MaxResults")
  valid_600987 = validateParameter(valid_600987, JString, required = false,
                                 default = nil)
  if valid_600987 != nil:
    section.add "MaxResults", valid_600987
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
  var valid_600988 = header.getOrDefault("X-Amz-Date")
  valid_600988 = validateParameter(valid_600988, JString, required = false,
                                 default = nil)
  if valid_600988 != nil:
    section.add "X-Amz-Date", valid_600988
  var valid_600989 = header.getOrDefault("X-Amz-Security-Token")
  valid_600989 = validateParameter(valid_600989, JString, required = false,
                                 default = nil)
  if valid_600989 != nil:
    section.add "X-Amz-Security-Token", valid_600989
  var valid_600990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600990 = validateParameter(valid_600990, JString, required = false,
                                 default = nil)
  if valid_600990 != nil:
    section.add "X-Amz-Content-Sha256", valid_600990
  var valid_600991 = header.getOrDefault("X-Amz-Algorithm")
  valid_600991 = validateParameter(valid_600991, JString, required = false,
                                 default = nil)
  if valid_600991 != nil:
    section.add "X-Amz-Algorithm", valid_600991
  var valid_600992 = header.getOrDefault("X-Amz-Signature")
  valid_600992 = validateParameter(valid_600992, JString, required = false,
                                 default = nil)
  if valid_600992 != nil:
    section.add "X-Amz-Signature", valid_600992
  var valid_600993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600993 = validateParameter(valid_600993, JString, required = false,
                                 default = nil)
  if valid_600993 != nil:
    section.add "X-Amz-SignedHeaders", valid_600993
  var valid_600994 = header.getOrDefault("X-Amz-Credential")
  valid_600994 = validateParameter(valid_600994, JString, required = false,
                                 default = nil)
  if valid_600994 != nil:
    section.add "X-Amz-Credential", valid_600994
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600995: Call_ListTemplates_600980; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all the templates in the QuickSight account.</p> <p>CLI syntax:</p> <p> <code>aws quicksight list-templates --aws-account-id 111122223333 --max-results 1 —next-token AYADeJuxwOypAndSoOn</code> </p>
  ## 
  let valid = call_600995.validator(path, query, header, formData, body)
  let scheme = call_600995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600995.url(scheme.get, call_600995.host, call_600995.base,
                         call_600995.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600995, url, valid)

proc call*(call_600996: Call_ListTemplates_600980; AwsAccountId: string;
          NextToken: string = ""; maxResult: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listTemplates
  ## <p>Lists all the templates in the QuickSight account.</p> <p>CLI syntax:</p> <p> <code>aws quicksight list-templates --aws-account-id 111122223333 --max-results 1 —next-token AYADeJuxwOypAndSoOn</code> </p>
  ##   AwsAccountId: string (required)
  ##               : AWS account ID that contains the templates you are listing.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResult: int
  ##            : The maximum number of results to be returned per request.
  ##   nextToken: string
  ##            : The token for the next set of results, or null if there are no more results.
  ##   MaxResults: string
  ##             : Pagination limit
  var path_600997 = newJObject()
  var query_600998 = newJObject()
  add(path_600997, "AwsAccountId", newJString(AwsAccountId))
  add(query_600998, "NextToken", newJString(NextToken))
  add(query_600998, "max-result", newJInt(maxResult))
  add(query_600998, "next-token", newJString(nextToken))
  add(query_600998, "MaxResults", newJString(MaxResults))
  result = call_600996.call(path_600997, query_600998, nil, nil, nil)

var listTemplates* = Call_ListTemplates_600980(name: "listTemplates",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/templates",
    validator: validate_ListTemplates_600981, base: "/", url: url_ListTemplates_600982,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUserGroups_600999 = ref object of OpenApiRestCall_599368
proc url_ListUserGroups_601001(protocol: Scheme; host: string; base: string;
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

proc validate_ListUserGroups_601000(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Lists the Amazon QuickSight groups that an Amazon QuickSight user is a member of.</p> <p>The response is a one or more group objects. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight list-user-groups -\-user-name=Pat -\-aws-account-id=111122223333 -\-namespace=default -\-region=us-east-1 </code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : The AWS Account ID that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   UserName: JString (required)
  ##           : The Amazon QuickSight user name that you want to list group memberships for.
  ##   Namespace: JString (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_601002 = path.getOrDefault("AwsAccountId")
  valid_601002 = validateParameter(valid_601002, JString, required = true,
                                 default = nil)
  if valid_601002 != nil:
    section.add "AwsAccountId", valid_601002
  var valid_601003 = path.getOrDefault("UserName")
  valid_601003 = validateParameter(valid_601003, JString, required = true,
                                 default = nil)
  if valid_601003 != nil:
    section.add "UserName", valid_601003
  var valid_601004 = path.getOrDefault("Namespace")
  valid_601004 = validateParameter(valid_601004, JString, required = true,
                                 default = nil)
  if valid_601004 != nil:
    section.add "Namespace", valid_601004
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return from this request.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_601005 = query.getOrDefault("max-results")
  valid_601005 = validateParameter(valid_601005, JInt, required = false, default = nil)
  if valid_601005 != nil:
    section.add "max-results", valid_601005
  var valid_601006 = query.getOrDefault("next-token")
  valid_601006 = validateParameter(valid_601006, JString, required = false,
                                 default = nil)
  if valid_601006 != nil:
    section.add "next-token", valid_601006
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
  var valid_601007 = header.getOrDefault("X-Amz-Date")
  valid_601007 = validateParameter(valid_601007, JString, required = false,
                                 default = nil)
  if valid_601007 != nil:
    section.add "X-Amz-Date", valid_601007
  var valid_601008 = header.getOrDefault("X-Amz-Security-Token")
  valid_601008 = validateParameter(valid_601008, JString, required = false,
                                 default = nil)
  if valid_601008 != nil:
    section.add "X-Amz-Security-Token", valid_601008
  var valid_601009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601009 = validateParameter(valid_601009, JString, required = false,
                                 default = nil)
  if valid_601009 != nil:
    section.add "X-Amz-Content-Sha256", valid_601009
  var valid_601010 = header.getOrDefault("X-Amz-Algorithm")
  valid_601010 = validateParameter(valid_601010, JString, required = false,
                                 default = nil)
  if valid_601010 != nil:
    section.add "X-Amz-Algorithm", valid_601010
  var valid_601011 = header.getOrDefault("X-Amz-Signature")
  valid_601011 = validateParameter(valid_601011, JString, required = false,
                                 default = nil)
  if valid_601011 != nil:
    section.add "X-Amz-Signature", valid_601011
  var valid_601012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601012 = validateParameter(valid_601012, JString, required = false,
                                 default = nil)
  if valid_601012 != nil:
    section.add "X-Amz-SignedHeaders", valid_601012
  var valid_601013 = header.getOrDefault("X-Amz-Credential")
  valid_601013 = validateParameter(valid_601013, JString, required = false,
                                 default = nil)
  if valid_601013 != nil:
    section.add "X-Amz-Credential", valid_601013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601014: Call_ListUserGroups_600999; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists the Amazon QuickSight groups that an Amazon QuickSight user is a member of.</p> <p>The response is a one or more group objects. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight list-user-groups -\-user-name=Pat -\-aws-account-id=111122223333 -\-namespace=default -\-region=us-east-1 </code> </p>
  ## 
  let valid = call_601014.validator(path, query, header, formData, body)
  let scheme = call_601014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601014.url(scheme.get, call_601014.host, call_601014.base,
                         call_601014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601014, url, valid)

proc call*(call_601015: Call_ListUserGroups_600999; AwsAccountId: string;
          UserName: string; Namespace: string; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listUserGroups
  ## <p>Lists the Amazon QuickSight groups that an Amazon QuickSight user is a member of.</p> <p>The response is a one or more group objects. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight list-user-groups -\-user-name=Pat -\-aws-account-id=111122223333 -\-namespace=default -\-region=us-east-1 </code> </p>
  ##   AwsAccountId: string (required)
  ##               : The AWS Account ID that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   maxResults: int
  ##             : The maximum number of results to return from this request.
  ##   nextToken: string
  ##            : A pagination token that can be used in a subsequent request.
  ##   UserName: string (required)
  ##           : The Amazon QuickSight user name that you want to list group memberships for.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_601016 = newJObject()
  var query_601017 = newJObject()
  add(path_601016, "AwsAccountId", newJString(AwsAccountId))
  add(query_601017, "max-results", newJInt(maxResults))
  add(query_601017, "next-token", newJString(nextToken))
  add(path_601016, "UserName", newJString(UserName))
  add(path_601016, "Namespace", newJString(Namespace))
  result = call_601015.call(path_601016, query_601017, nil, nil, nil)

var listUserGroups* = Call_ListUserGroups_600999(name: "listUserGroups",
    meth: HttpMethod.HttpGet, host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users/{UserName}/groups",
    validator: validate_ListUserGroups_601000, base: "/", url: url_ListUserGroups_601001,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterUser_601036 = ref object of OpenApiRestCall_599368
proc url_RegisterUser_601038(protocol: Scheme; host: string; base: string;
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

proc validate_RegisterUser_601037(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an Amazon QuickSight user, whose identity is associated with the AWS Identity and Access Management (IAM) identity or role specified in the request. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight register-user -\-aws-account-id=111122223333 -\-namespace=default -\-email=pat@example.com -\-identity-type=IAM -\-user-role=AUTHOR -\-iam-arn=arn:aws:iam::111122223333:user/Pat </code> </p>
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
  var valid_601039 = path.getOrDefault("AwsAccountId")
  valid_601039 = validateParameter(valid_601039, JString, required = true,
                                 default = nil)
  if valid_601039 != nil:
    section.add "AwsAccountId", valid_601039
  var valid_601040 = path.getOrDefault("Namespace")
  valid_601040 = validateParameter(valid_601040, JString, required = true,
                                 default = nil)
  if valid_601040 != nil:
    section.add "Namespace", valid_601040
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
  var valid_601041 = header.getOrDefault("X-Amz-Date")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Date", valid_601041
  var valid_601042 = header.getOrDefault("X-Amz-Security-Token")
  valid_601042 = validateParameter(valid_601042, JString, required = false,
                                 default = nil)
  if valid_601042 != nil:
    section.add "X-Amz-Security-Token", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Content-Sha256", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Algorithm")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Algorithm", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Signature")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Signature", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-SignedHeaders", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Credential")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Credential", valid_601047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601049: Call_RegisterUser_601036; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon QuickSight user, whose identity is associated with the AWS Identity and Access Management (IAM) identity or role specified in the request. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight register-user -\-aws-account-id=111122223333 -\-namespace=default -\-email=pat@example.com -\-identity-type=IAM -\-user-role=AUTHOR -\-iam-arn=arn:aws:iam::111122223333:user/Pat </code> </p>
  ## 
  let valid = call_601049.validator(path, query, header, formData, body)
  let scheme = call_601049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601049.url(scheme.get, call_601049.host, call_601049.base,
                         call_601049.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601049, url, valid)

proc call*(call_601050: Call_RegisterUser_601036; AwsAccountId: string;
          body: JsonNode; Namespace: string): Recallable =
  ## registerUser
  ## <p>Creates an Amazon QuickSight user, whose identity is associated with the AWS Identity and Access Management (IAM) identity or role specified in the request. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight register-user -\-aws-account-id=111122223333 -\-namespace=default -\-email=pat@example.com -\-identity-type=IAM -\-user-role=AUTHOR -\-iam-arn=arn:aws:iam::111122223333:user/Pat </code> </p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   body: JObject (required)
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_601051 = newJObject()
  var body_601052 = newJObject()
  add(path_601051, "AwsAccountId", newJString(AwsAccountId))
  if body != nil:
    body_601052 = body
  add(path_601051, "Namespace", newJString(Namespace))
  result = call_601050.call(path_601051, nil, nil, nil, body_601052)

var registerUser* = Call_RegisterUser_601036(name: "registerUser",
    meth: HttpMethod.HttpPost, host: "quicksight.amazonaws.com",
    route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users",
    validator: validate_RegisterUser_601037, base: "/", url: url_RegisterUser_601038,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUsers_601018 = ref object of OpenApiRestCall_599368
proc url_ListUsers_601020(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListUsers_601019(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns a list of all of the Amazon QuickSight users belonging to this account. </p> <p>The response is a list of user objects, containing each user's Amazon Resource Name (ARN), AWS Identity and Access Management (IAM) role, and email address. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight list-users --aws-account-id=111122223333 --namespace=default </code> </p>
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
  var valid_601021 = path.getOrDefault("AwsAccountId")
  valid_601021 = validateParameter(valid_601021, JString, required = true,
                                 default = nil)
  if valid_601021 != nil:
    section.add "AwsAccountId", valid_601021
  var valid_601022 = path.getOrDefault("Namespace")
  valid_601022 = validateParameter(valid_601022, JString, required = true,
                                 default = nil)
  if valid_601022 != nil:
    section.add "Namespace", valid_601022
  result.add "path", section
  ## parameters in `query` object:
  ##   max-results: JInt
  ##              : The maximum number of results to return from this request.
  ##   next-token: JString
  ##             : A pagination token that can be used in a subsequent request.
  section = newJObject()
  var valid_601023 = query.getOrDefault("max-results")
  valid_601023 = validateParameter(valid_601023, JInt, required = false, default = nil)
  if valid_601023 != nil:
    section.add "max-results", valid_601023
  var valid_601024 = query.getOrDefault("next-token")
  valid_601024 = validateParameter(valid_601024, JString, required = false,
                                 default = nil)
  if valid_601024 != nil:
    section.add "next-token", valid_601024
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
  var valid_601025 = header.getOrDefault("X-Amz-Date")
  valid_601025 = validateParameter(valid_601025, JString, required = false,
                                 default = nil)
  if valid_601025 != nil:
    section.add "X-Amz-Date", valid_601025
  var valid_601026 = header.getOrDefault("X-Amz-Security-Token")
  valid_601026 = validateParameter(valid_601026, JString, required = false,
                                 default = nil)
  if valid_601026 != nil:
    section.add "X-Amz-Security-Token", valid_601026
  var valid_601027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601027 = validateParameter(valid_601027, JString, required = false,
                                 default = nil)
  if valid_601027 != nil:
    section.add "X-Amz-Content-Sha256", valid_601027
  var valid_601028 = header.getOrDefault("X-Amz-Algorithm")
  valid_601028 = validateParameter(valid_601028, JString, required = false,
                                 default = nil)
  if valid_601028 != nil:
    section.add "X-Amz-Algorithm", valid_601028
  var valid_601029 = header.getOrDefault("X-Amz-Signature")
  valid_601029 = validateParameter(valid_601029, JString, required = false,
                                 default = nil)
  if valid_601029 != nil:
    section.add "X-Amz-Signature", valid_601029
  var valid_601030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601030 = validateParameter(valid_601030, JString, required = false,
                                 default = nil)
  if valid_601030 != nil:
    section.add "X-Amz-SignedHeaders", valid_601030
  var valid_601031 = header.getOrDefault("X-Amz-Credential")
  valid_601031 = validateParameter(valid_601031, JString, required = false,
                                 default = nil)
  if valid_601031 != nil:
    section.add "X-Amz-Credential", valid_601031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601032: Call_ListUsers_601018; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of all of the Amazon QuickSight users belonging to this account. </p> <p>The response is a list of user objects, containing each user's Amazon Resource Name (ARN), AWS Identity and Access Management (IAM) role, and email address. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight list-users --aws-account-id=111122223333 --namespace=default </code> </p>
  ## 
  let valid = call_601032.validator(path, query, header, formData, body)
  let scheme = call_601032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601032.url(scheme.get, call_601032.host, call_601032.base,
                         call_601032.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601032, url, valid)

proc call*(call_601033: Call_ListUsers_601018; AwsAccountId: string;
          Namespace: string; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listUsers
  ## <p>Returns a list of all of the Amazon QuickSight users belonging to this account. </p> <p>The response is a list of user objects, containing each user's Amazon Resource Name (ARN), AWS Identity and Access Management (IAM) role, and email address. </p> <p> <b>CLI Sample:</b> </p> <p> <code>aws quicksight list-users --aws-account-id=111122223333 --namespace=default </code> </p>
  ##   AwsAccountId: string (required)
  ##               : The ID for the AWS account that the user is in. Currently, you use the ID for the AWS account that contains your Amazon QuickSight account.
  ##   maxResults: int
  ##             : The maximum number of results to return from this request.
  ##   nextToken: string
  ##            : A pagination token that can be used in a subsequent request.
  ##   Namespace: string (required)
  ##            : The namespace. Currently, you should set this to <code>default</code>.
  var path_601034 = newJObject()
  var query_601035 = newJObject()
  add(path_601034, "AwsAccountId", newJString(AwsAccountId))
  add(query_601035, "max-results", newJInt(maxResults))
  add(query_601035, "next-token", newJString(nextToken))
  add(path_601034, "Namespace", newJString(Namespace))
  result = call_601033.call(path_601034, query_601035, nil, nil, nil)

var listUsers* = Call_ListUsers_601018(name: "listUsers", meth: HttpMethod.HttpGet,
                                    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/namespaces/{Namespace}/users",
                                    validator: validate_ListUsers_601019,
                                    base: "/", url: url_ListUsers_601020,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_601053 = ref object of OpenApiRestCall_599368
proc url_UntagResource_601055(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_601054(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes a tag or tags from a resource.</p> <p>CLI syntax:</p> <ul> <li> <p> <code>aws quicksight untag-resource --resource-arn arn:aws:quicksight:us-east-1:111111111111:dataset/dataset1 --tag-keys K1 K2 --region us-east-1</code> </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ResourceArn: JString (required)
  ##              : The ARN of the resource you to untag.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ResourceArn` field"
  var valid_601056 = path.getOrDefault("ResourceArn")
  valid_601056 = validateParameter(valid_601056, JString, required = true,
                                 default = nil)
  if valid_601056 != nil:
    section.add "ResourceArn", valid_601056
  result.add "path", section
  ## parameters in `query` object:
  ##   keys: JArray (required)
  ##       : The keys of the key-value pairs for the resource tag or tags assigned to the resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `keys` field"
  var valid_601057 = query.getOrDefault("keys")
  valid_601057 = validateParameter(valid_601057, JArray, required = true, default = nil)
  if valid_601057 != nil:
    section.add "keys", valid_601057
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
  var valid_601058 = header.getOrDefault("X-Amz-Date")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Date", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Security-Token")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Security-Token", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Content-Sha256", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-Algorithm")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Algorithm", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Signature")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Signature", valid_601062
  var valid_601063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-SignedHeaders", valid_601063
  var valid_601064 = header.getOrDefault("X-Amz-Credential")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-Credential", valid_601064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601065: Call_UntagResource_601053; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes a tag or tags from a resource.</p> <p>CLI syntax:</p> <ul> <li> <p> <code>aws quicksight untag-resource --resource-arn arn:aws:quicksight:us-east-1:111111111111:dataset/dataset1 --tag-keys K1 K2 --region us-east-1</code> </p> </li> </ul>
  ## 
  let valid = call_601065.validator(path, query, header, formData, body)
  let scheme = call_601065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601065.url(scheme.get, call_601065.host, call_601065.base,
                         call_601065.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601065, url, valid)

proc call*(call_601066: Call_UntagResource_601053; keys: JsonNode;
          ResourceArn: string): Recallable =
  ## untagResource
  ## <p>Removes a tag or tags from a resource.</p> <p>CLI syntax:</p> <ul> <li> <p> <code>aws quicksight untag-resource --resource-arn arn:aws:quicksight:us-east-1:111111111111:dataset/dataset1 --tag-keys K1 K2 --region us-east-1</code> </p> </li> </ul>
  ##   keys: JArray (required)
  ##       : The keys of the key-value pairs for the resource tag or tags assigned to the resource.
  ##   ResourceArn: string (required)
  ##              : The ARN of the resource you to untag.
  var path_601067 = newJObject()
  var query_601068 = newJObject()
  if keys != nil:
    query_601068.add "keys", keys
  add(path_601067, "ResourceArn", newJString(ResourceArn))
  result = call_601066.call(path_601067, query_601068, nil, nil, nil)

var untagResource* = Call_UntagResource_601053(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "quicksight.amazonaws.com",
    route: "/resources/{ResourceArn}/tags#keys",
    validator: validate_UntagResource_601054, base: "/", url: url_UntagResource_601055,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDashboardPublishedVersion_601069 = ref object of OpenApiRestCall_599368
proc url_UpdateDashboardPublishedVersion_601071(protocol: Scheme; host: string;
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

proc validate_UpdateDashboardPublishedVersion_601070(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the published version of a dashboard.</p> <p>CLI syntax:</p> <p> <code>aws quicksight update-dashboard-published-version --aws-account-id 111122223333 --dashboard-id dashboard-w1 ---version-number 2</code> </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   AwsAccountId: JString (required)
  ##               : AWS account ID that contains the dashboard you are updating.
  ##   DashboardId: JString (required)
  ##              : The ID for the dashboard.
  ##   VersionNumber: JInt (required)
  ##                : The version number of the dashboard.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `AwsAccountId` field"
  var valid_601072 = path.getOrDefault("AwsAccountId")
  valid_601072 = validateParameter(valid_601072, JString, required = true,
                                 default = nil)
  if valid_601072 != nil:
    section.add "AwsAccountId", valid_601072
  var valid_601073 = path.getOrDefault("DashboardId")
  valid_601073 = validateParameter(valid_601073, JString, required = true,
                                 default = nil)
  if valid_601073 != nil:
    section.add "DashboardId", valid_601073
  var valid_601074 = path.getOrDefault("VersionNumber")
  valid_601074 = validateParameter(valid_601074, JInt, required = true, default = nil)
  if valid_601074 != nil:
    section.add "VersionNumber", valid_601074
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
  var valid_601075 = header.getOrDefault("X-Amz-Date")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Date", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-Security-Token")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Security-Token", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Content-Sha256", valid_601077
  var valid_601078 = header.getOrDefault("X-Amz-Algorithm")
  valid_601078 = validateParameter(valid_601078, JString, required = false,
                                 default = nil)
  if valid_601078 != nil:
    section.add "X-Amz-Algorithm", valid_601078
  var valid_601079 = header.getOrDefault("X-Amz-Signature")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "X-Amz-Signature", valid_601079
  var valid_601080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "X-Amz-SignedHeaders", valid_601080
  var valid_601081 = header.getOrDefault("X-Amz-Credential")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-Credential", valid_601081
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601082: Call_UpdateDashboardPublishedVersion_601069;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## <p>Updates the published version of a dashboard.</p> <p>CLI syntax:</p> <p> <code>aws quicksight update-dashboard-published-version --aws-account-id 111122223333 --dashboard-id dashboard-w1 ---version-number 2</code> </p>
  ## 
  let valid = call_601082.validator(path, query, header, formData, body)
  let scheme = call_601082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601082.url(scheme.get, call_601082.host, call_601082.base,
                         call_601082.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601082, url, valid)

proc call*(call_601083: Call_UpdateDashboardPublishedVersion_601069;
          AwsAccountId: string; DashboardId: string; VersionNumber: int): Recallable =
  ## updateDashboardPublishedVersion
  ## <p>Updates the published version of a dashboard.</p> <p>CLI syntax:</p> <p> <code>aws quicksight update-dashboard-published-version --aws-account-id 111122223333 --dashboard-id dashboard-w1 ---version-number 2</code> </p>
  ##   AwsAccountId: string (required)
  ##               : AWS account ID that contains the dashboard you are updating.
  ##   DashboardId: string (required)
  ##              : The ID for the dashboard.
  ##   VersionNumber: int (required)
  ##                : The version number of the dashboard.
  var path_601084 = newJObject()
  add(path_601084, "AwsAccountId", newJString(AwsAccountId))
  add(path_601084, "DashboardId", newJString(DashboardId))
  add(path_601084, "VersionNumber", newJInt(VersionNumber))
  result = call_601083.call(path_601084, nil, nil, nil, nil)

var updateDashboardPublishedVersion* = Call_UpdateDashboardPublishedVersion_601069(
    name: "updateDashboardPublishedVersion", meth: HttpMethod.HttpPut,
    host: "quicksight.amazonaws.com", route: "/accounts/{AwsAccountId}/dashboards/{DashboardId}/versions/{VersionNumber}",
    validator: validate_UpdateDashboardPublishedVersion_601070, base: "/",
    url: url_UpdateDashboardPublishedVersion_601071,
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
